local _, ns = ...

-- Collecteur : note automatiquement, pendant que tu joues, les quêtes que QuestieDB ne connaît pas
-- encore (nouveau contenu de Forever) : donneur, rendu, objectifs, niveau, XP, monstres, et les
-- quêtes disponibles affichées par le jeu sur la carte. Rien n'est envoyé : /qw collecte export
-- produit un texte à partager, que tools/merge_collected.py fusionne pour le générateur de routes.
local M = ns.RegisterModule({
    id = "collector", category = "community", default = true,
    name = "Collecteur de quêtes",
    desc = "Note tout seul les quêtes de Forever absentes des données publiques (donneur, rendu, objectifs, niveau, XP, monstres) pour améliorer les routes. Rien n'est envoyé : /qw collecte export pour partager ce que tu as collecté.",
    options = {
        { key = "all", label = "Collecter aussi les quêtes déjà connues", type = "check", default = false },
        { key = "chat", label = "Message à chaque nouvelle quête notée", type = "check", default = false },
    },
})

local MAX_OBJ = 25           -- points d'objectif gardés par quête
local KNOWN_MAX = 9665       -- plus grand ID de quête de QuestieDB Classic (au-delà : nouveau contenu)

local function db()
    ns.db.collect = ns.db.collect or { v = 1, quests = {}, npcs = {} }
    return ns.db.collect
end

-- quête utile à collecter : nouvelle (inconnue des routes et de QuestieDB) ou option « tout »
function M.Wanted(q)
    if not q or q == 0 then return false end
    if M:Opt("all") then return true end
    -- les quêtes Classic (QuestieDB) ont des identifiants <= KNOWN_MAX ; le contenu de Forever est au-delà
    return q > KNOWN_MAX and not (ns.KnownQuests and ns.KnownQuests[q])
end

local function round(v) return v and math.floor(v * 1000 + 0.5) / 10 end    -- 0..1 -> 0..100, 1 décimale
local function here()
    local map, x, y = ns.PlayerMapPos()
    if not (map and x) or ns.IsSecret(x) then return end
    return { map = map, x = round(x), y = round(y) }
end

local function quest(q)
    local d = db()
    local e = d.quests[q]
    if not e then
        e = { obj = {}, mobs = {}, fac = ns.PlayerFaction(), seen = time() }
        d.quests[q] = e
        M.new = (M.new or 0) + 1
        if M:Opt("chat") then ns.Print(ns.Tr("Nouvelle quête collectée : %s"):format(tostring(q))) end
    end
    return e
end

local function npcHere(unit)
    local id = ns.NpcIDFromUnit(unit or "npc")
    if not id then return end
    local p = here()
    local name = UnitName(unit or "npc")
    if ns.IsSecret(name) then name = nil end
    local n = db().npcs[id] or {}
    n.name = name or n.name
    if p then n.map, n.x, n.y = p.map, p.x, p.y end
    db().npcs[id] = n
    return id, p
end

-- Ordre de déblocage : une quête qui apparaît chez un PNJ juste après qu'on lui en a rendu une
-- autre est très probablement sa suite. La base de Forever manque de ces prérequis.
local offeredBy, lastTurnin = {}, nil
local function noteUnlocks(npc)
    if not (npc and C_GossipInfo.GetAvailableQuests) then return end
    local cur = {}
    for _, info in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
        if info.questID and not ns.IsSecret(info.questID) then cur[info.questID] = true end
    end
    local prev = offeredBy[npc]
    if prev and lastTurnin and lastTurnin.npc == npc and GetTime() - lastTurnin.time < 90 then
        local d = db()
        d.pre = d.pre or {}
        for q in pairs(cur) do
            if not prev[q] and q ~= lastTurnin.quest and q > KNOWN_MAX then d.pre[q] = lastTurnin.quest end
        end
    end
    offeredBy[npc] = cur
end
M.NoteUnlocks = noteUnlocks

-- quêtes proposées / à rendre chez un PNJ (fenêtre de dialogue)
local function fromGossip()
    if not M.enabled then return end
    local npc, p = npcHere("npc")
    noteUnlocks(npc)
    for _, info in ipairs(C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or {}) do
        if M.Wanted(info.questID) then
            local e = quest(info.questID)
            e.title = info.title or e.title
            e.lvl = info.questLevel or e.lvl
            if npc then e.giver = { npc = npc, map = p and p.map, x = p and p.x, y = p and p.y } end
        end
    end
    for _, info in ipairs(C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {}) do
        if M.Wanted(info.questID) and info.isComplete then
            local e = quest(info.questID)
            e.title = info.title or e.title
            if npc then e.ender = { npc = npc, map = p and p.map, x = p and p.x, y = p and p.y } end
        end
    end
end
M:On("GOSSIP_SHOW", fromGossip)

-- fenêtre de quête directe (PNJ sans dialogue) : proposition et rendu
M:On("QUEST_DETAIL", function()
    if not M.enabled then return end
    local q = GetQuestID and GetQuestID()
    if not M.Wanted(q) then return end
    local npc, p = npcHere("npc")
    local e = quest(q)
    e.title = GetTitleText and GetTitleText() or e.title
    if npc then e.giver = { npc = npc, map = p and p.map, x = p and p.x, y = p and p.y } end
end)
M:On("QUEST_COMPLETE", function()
    if not M.enabled then return end
    local q = GetQuestID and GetQuestID()
    if not M.Wanted(q) then return end
    local npc, p = npcHere("npc")
    local e = quest(q)
    if npc then e.ender = { npc = npc, map = p and p.map, x = p and p.x, y = p and p.y } end
end)

-- Niveau auquel une quête de Forever a été prise (même connue des routes) : le niveau requis vaut
-- au plus ce niveau. La base n'en donne pas pour beaucoup de quêtes : le générateur les estime au
-- niveau de la quête (prudent), et ces relevés lui permettent de les proposer plus tôt sans risque.
M:On("QUEST_ACCEPTED", function(q)
    if not (M.enabled and type(q) == "number" and not ns.IsSecret(q) and q > KNOWN_MAX) then return end
    local d = db()
    d.acc = d.acc or {}
    local lvl = ns.PlayerLevel()
    if not d.acc[q] or lvl < d.acc[q] then d.acc[q] = lvl end
end)

M:On("QUEST_ACCEPTED", function(q)
    if not (M.enabled and M.Wanted(q)) then return end
    local e = quest(q)
    e.title = e.title or C_QuestLog.GetTitleForQuestID(q)
    local tag = C_QuestLog.GetQuestTagInfo and C_QuestLog.GetQuestTagInfo(q)
    if tag and tag.isElite then e.elite = true end
    local size = C_QuestLog.GetSuggestedGroupSize and C_QuestLog.GetSuggestedGroupSize(q)
    if type(size) == "number" and not ns.IsSecret(size) and size > 1 then e.group = size end
    e.lvlAccepted = ns.PlayerLevel()
    if not e.giver then local p = here(); if p then e.giver = p end end
end)

M:On("QUEST_TURNED_IN", function(q)
    if M.enabled and q and not ns.IsSecret(q) then
        lastTurnin = { quest = q, npc = ns.NpcIDFromUnit("npc"), time = GetTime() }
    end
end)

M:On("QUEST_TURNED_IN", function(q, xp)
    if not (M.enabled and M.Wanted(q)) then return end
    local e = quest(q)
    if type(xp) == "number" and not ns.IsSecret(xp) and xp > 0 then
        e.xp = xp
        e.xpLevel = ns.PlayerLevel()
    end
    if not e.ender then local p = here(); if p then e.ender = p end end
    e.done = true
end)

-- objectifs : à chaque progression, on note la position (et le monstre ciblé juste avant)
local progress, lastTarget, lastTargetTime = {}, nil, 0
M:On("PLAYER_TARGET_CHANGED", function()
    local id = ns.NpcIDFromUnit("target")
    local ok, hostile = pcall(UnitCanAttack, "player", "target")
    if id and ok and hostile and not ns.IsSecret(hostile) then lastTarget, lastTargetTime = id, GetTime() end
end)
local function scanObjectives()
    if not M.enabled then return end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local q = info and not info.isHeader and info.questID
        if q and M.Wanted(q) then
            local total = 0
            for _, o in ipairs(C_QuestLog.GetQuestObjectives(q) or {}) do
                local f = o.numFulfilled
                if type(f) == "number" and not ns.IsSecret(f) then total = total + f end
            end
            local before = progress[q]
            progress[q] = total
            if before and total > before then
                local e = quest(q)
                local p = here()
                if p and #e.obj < MAX_OBJ then e.obj[#e.obj + 1] = p end
                if lastTarget and GetTime() - lastTargetTime < 20 then e.mobs[lastTarget] = (e.mobs[lastTarget] or 0) + 1 end
            end
        end
    end
end
M.ScanObjectives = scanObjectives
M:On("QUEST_LOG_UPDATE", scanObjectives)

-- carte : quêtes disponibles affichées par le jeu (points d'exclamation), avec leur position
function M.ScanMap(mapID)
    if not (M.enabled and mapID and C_QuestLine and C_QuestLine.GetAvailableQuestLines) then return 0 end
    if C_QuestLine.RequestQuestLinesForMap then pcall(C_QuestLine.RequestQuestLinesForMap, mapID) end
    local ok, lines = pcall(C_QuestLine.GetAvailableQuestLines, mapID)
    if not ok or type(lines) ~= "table" then return 0 end
    local n = 0
    for _, l in ipairs(lines) do
        if l.questID and M.Wanted(l.questID) and l.x and not ns.IsSecret(l.x) then
            local e = quest(l.questID)
            e.title = e.title or l.questName
            e.line = l.questLineName or e.line
            if not (e.giver and e.giver.npc) then e.giver = { map = mapID, x = round(l.x), y = round(l.y) } end
            n = n + 1
        end
    end
    return n
end
local lastScan = {}
local function scanHere()
    local map = C_Map.GetBestMapForUnit("player")
    if map and (not lastScan[map] or GetTime() - lastScan[map] > 120) then
        lastScan[map] = GetTime()
        M.ScanMap(map)
    end
end
M:On("ZONE_CHANGED_NEW_AREA", function() C_Timer.After(2, scanHere) end)
M:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(5, scanHere) end)
M:On("QUESTLINE_UPDATE", function() scanHere() end)

---------------------------------------------------------------------------
-- Export (FPC1) : une ligne par quête, par point d'objectif et par PNJ
---------------------------------------------------------------------------
local function clean(s) return tostring(s or ""):gsub("[;\n|]", " ") end
local function pt(p) return p and ("%s,%s,%s"):format(p.map or "", p.x or "", p.y or "") or ",," end
function M.Export()
    local d = db()
    local out = { ("FPC1;%s;%s;%s"):format(ns.VERSION or "?", GetLocale and GetLocale() or "?", ns.PlayerFaction() or "?") }
    local ids = {}
    for q in pairs(d.quests) do ids[#ids + 1] = q end
    table.sort(ids)
    for _, q in ipairs(ids) do
        local e = d.quests[q]
        local mobs = {}
        for id in pairs(e.mobs or {}) do mobs[#mobs + 1] = id end
        table.sort(mobs)
        out[#out + 1] = ("Q;%d;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s"):format(q, clean(e.title), e.lvl or "", e.lvlAccepted or "",
            e.xp or "", e.xpLevel or "", e.fac or "", e.giver and e.giver.npc or "", pt(e.giver), e.ender and e.ender.npc or "",
            pt(e.ender), table.concat(mobs, ","), (e.elite and "E" or "") .. (e.group and ("G" .. e.group) or ""))
        for _, p in ipairs(e.obj or {}) do out[#out + 1] = ("O;%d;%s"):format(q, pt(p)) end
    end
    for id, n in pairs(d.npcs) do out[#out + 1] = ("N;%d;%s;%s"):format(id, clean(n.name), pt(n)) end
    for q, prev in pairs(d.pre or {}) do out[#out + 1] = ("P;%d;%d"):format(q, prev) end
    for q, lvl in pairs(d.acc or {}) do out[#out + 1] = ("R;%d;%d"):format(q, lvl) end
    return table.concat(out, "\n")
end

function M.Count()
    local n, done = 0, 0
    for _, e in pairs(db().quests) do n = n + 1; if e.done then done = done + 1 end end
    return n, done
end

ns.SlashExt.collecte = function(arg)
    if arg == "export" then
        ns.ShowExport(M.Export(), ns.Tr("Quêtes collectées (Ctrl+A, Ctrl+C) — à envoyer sur GitHub ou Discord"))
    elseif arg == "reset" then
        ns.db.collect = nil
        ns.Print(ns.Tr("Collecte effacée."))
    else
        local n, done = M.Count()
        ns.Print(ns.Tr("Collecte : %d quête(s) notée(s), dont %d rendue(s). /qw collecte export pour partager."):format(n, done))
    end
end
ns.SlashExt.collect = ns.SlashExt.collecte

-- quêtes connues (routes générées) : construites au chargement
M:On("FP_INIT", function()
    ns.KnownQuests = ns.KnownQuests or {}
    for _, id in ipairs(ns.GuideOrder) do
        for _, st in ipairs(ns.Guides[id].steps) do if st.quest then ns.KnownQuests[st.quest] = true end end
    end
end)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cff66ccffCollecte|r : 37 quêtes notées\ndont 22 rendues\n/fp collecte export")
end
