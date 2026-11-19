local _, ns = ...
local L = ns.L

ns.Guides = {}
ns.GuideOrder = {}

-- guide = { id, name, faction, race = {...}, minLevel, maxLevel, next = "id", text = DSL }
-- noms de zones français -> anglais (clients non francophones)
local zoneList
function ns.TrZones(text)
    if ns.isFrench or type(text) ~= "string" then return text end
    if not zoneList then
        zoneList = {}
        for _, z in ipairs(ns.Zones or {}) do
            if z.fr and z.en and z.fr ~= z.en then zoneList[#zoneList + 1] = z end
        end
        table.sort(zoneList, function(a, b) return #a.fr > #b.fr end)
    end
    for _, z in ipairs(zoneList) do
        local i, j = text:find(z.fr, 1, true)
        while i do
            text = text:sub(1, i - 1) .. z.en .. text:sub(j + 1)
            i, j = text:find(z.fr, i + #z.en, true)
        end
    end
    return text
end

function ns.RegisterGuide(g)
    assert(g.id and g.text, "guide sans id/text")
    g.steps = ns.ParseGuide(g.text)
    if ns.isEnglish then
        g.name = ns.TrZones(g.name)
        for _, st in ipairs(g.steps) do
            if st.text then st.text = ns.TrZones(ns.Tr(st.text)) end
        end
    end
    ns.Guides[g.id] = g
    table.insert(ns.GuideOrder, g.id)
end

local E = {}
ns.Engine = E

function E.Applies(step)
    if step.class and not step.class[ns.PlayerClass()] then return false end
    if step.race and not step.race[ns.PlayerRace()] then return false end
    return true
end

local function questInLog(q) return C_QuestLog.GetLogIndexForQuestID(q) ~= nil end
local function questDone(q) return C_QuestLog.IsQuestFlaggedCompleted(q) end

function E.Distance(step)
    local d = ns.Geo.Vector(step)
    return d
end

-- Prise d'une quête au-dessus du niveau du joueur : le PNJ ne la propose pas encore (point
-- d'exclamation gris). Le niveau requis vient de la route (req=) ; une quête déjà prise ou faite
-- n'est jamais concernée.
function E.TooLow(step)
    return step.type == "accept" and step.req ~= nil and step.quest ~= nil and ns.PlayerLevel() < step.req
        and not questInLog(step.quest) and not questDone(step.quest)
end

function E.IsDone(step, idx, guideId)
    if step.removed then return true end          -- retirée avec l'éditeur
    local skipped = ns.cdb.skipped[guideId or ns.cdb.guideId]
    if skipped and skipped[idx] then return true end
    if not E.Applies(step) then return true end
    if step.upto and ns.PlayerLevel() >= step.upto then return true end
    -- mode Hardcore : quêtes dangereuses sautées (prise, objectif et rendu)
    local hc = ns.Modules.hardcore
    if step.danger and hc and hc.enabled and hc:Opt("skip") and step.quest and not questInLog(step.quest) then return true end
    -- quêtes de groupe (élites) : hors route sauf si on les demande ou si la quête est déjà prise
    if step.group and step.quest and not questInLog(step.quest) then
        local gh = ns.Modules.grouphint
        if not (gh and gh.enabled and gh:Opt("include")) then return true end
    end
    -- quête de métier (ex. Cuisine 50) que le personnage ne peut pas faire : passée, sauf si déjà prise
    local pq = ns.Modules.profquests
    if step.quest and pq and pq.Skip and not questInLog(step.quest) and pq.Skip(step) then return true end
    -- niveau requis pas atteint (point d'exclamation gris) : prise mise de côté, reprise au bon niveau
    if E.TooLow(step) then
        ns.cdb.levelWait = ns.cdb.levelWait or {}
        ns.cdb.levelWait[step.quest] = step.req
        return true
    end
    -- quête que son PNJ ne proposait pas (prérequis manquant, donnée fausse) : prise passée
    if step.type == "accept" and step.quest and ns.cdb.notOffered and ns.cdb.notOffered[step.quest] then return true end
    -- rattrapage : quête devenue grise et pas encore prise
    local cu = ns.Modules.catchup
    if step.type == "accept" and step.qlvl and cu and cu.enabled
        and ns.PlayerLevel() >= step.qlvl + (cu:Opt("gap") or 9) and not questInLog(step.quest) then return true end
    local t = step.type
    if t == "accept" then
        return questInLog(step.quest) or questDone(step.quest)
    elseif t == "complete" then
        -- quête absente du journal (pas prise / abandonnée) : rien à faire ici
        return not questInLog(step.quest) or C_QuestLog.IsComplete(step.quest)
    elseif t == "turnin" then
        return questDone(step.quest) or not questInLog(step.quest)
    elseif t == "level" then
        return ns.PlayerLevel() >= (step.level or 0)
    elseif t == "goto" then
        local d = E.Distance(step)
        return d ~= nil and d <= (step.radius or 15)
    elseif t == "hearth" then
        -- arrivé à l'auberge (pierre utilisée, ou venu à pied)
        local d = step.x and E.Distance(step)
        return d ~= nil and d <= 60
    end
    return false -- note / bind / fly / flightpath : validées par un événement ou le bouton >
end

-- Garde-fou : on parle au PNJ de l'étape « prendre », sa fenêtre de dialogue liste ses quêtes, et la
-- nôtre n'y est pas. La base de quêtes de Forever a encore des prérequis manquants : plutôt que de
-- bloquer le joueur, on passe la prise (les étapes « faire » et « rendre » suivent d'elles-mêmes)
-- et on le note pour les signalements.
-- Prise de l'étape en cours marquée « pas proposée » (le PNJ ne la donne pas) : étape passée.
function E.MarkNotOffered(silentReport)
    local g, step, i = E.Current()
    if not (g and step and step.type == "accept" and step.quest) then return end
    ns.cdb.notOffered = ns.cdb.notOffered or {}
    ns.cdb.notOffered[step.quest] = ns.PlayerLevel()
    if ns.StepReport and silentReport ~= false then ns.StepReport.Add("notoffered", g, step, i, true) end
    ns.Toast(ns.Tr("Ce PNJ ne propose pas cette quête pour l'instant : étape passée."), "Interface\\Icons\\INV_Misc_QuestionMark", 1, 0.8, 0.3, 4)
    E.Refresh()
    return true
end

-- Juste après un rendu, le PNJ met parfois un instant à proposer la suite (la fenêtre qui se rouvre
-- ne la liste pas encore) : pendant quelques secondes, on ne conclut pas qu'elle n'est pas proposée.
-- Sinon la suite d'une chaîne (ex. « Les Veilleurs » 2/3) était passée à tort.
local turnedInAt = -1000
ns.On("QUEST_TURNED_IN", function() turnedInAt = GetTime() end)
E.SETTLE = 4

-- l'étape en cours est une prise chez ce PNJ (celui avec qui on parle) ?
local function offerStep()
    local g, step = E.Current()
    if not (g and step and step.type == "accept" and step.quest and step.npcID) then return end
    if ns.NpcIDFromUnit("npc") ~= step.npcID then return end
    if GetTime() - turnedInAt < E.SETTLE then return end
    return step
end

-- Quête passée plus tôt parce qu'elle n'était pas proposée, et que ce PNJ propose maintenant
-- (niveau atteint, prérequis fait, ou fausse alerte) : on revient à sa prise.
function E.Reoffered(ids)
    local g, _, cur = E.Current()
    local no, lw = ns.cdb.notOffered or {}, ns.cdb.levelWait or {}
    if not (g and (next(no) or next(lw))) then return end
    for _, q in ipairs(ids) do
        if no[q] or lw[q] then
            for j = 1, (cur or 1) - 1 do
                local s = g.steps[j]
                if s.type == "accept" and s.quest == q and E.Applies(s) and not E.TooLow(s) then
                    no[q], lw[q] = nil, nil
                    E.KeepPassed(g, j, cur)
                    ns.cdb.stepIndex = j
                    ns.Toast(ns.Tr("Quête maintenant proposée : retour à sa prise."), "Interface\\GossipFrame\\AvailableQuestIcon", 0.4, 0.9, 0.5, 4)
                    E.Refresh()
                    ns.Fire("FP_STEP_CHANGED", true)
                    return true
                end
            end
        end
    end
end

-- Retour en arrière vers une prise : les étapes sans quête déjà passées entre les deux (aller à,
-- notes, vols...) restent passées, sinon le guide renverrait le joueur sur ses pas.
function E.KeepPassed(g, from, to)
    ns.cdb.skipped[g.id] = ns.cdb.skipped[g.id] or {}
    to = to or from
    for k = from + 1, to - 1 do
        local s = g.steps[k]
        if s and not s.quest then
            ns.cdb.skipped[g.id][k] = true
        elseif s and s.type == "accept" and not questInLog(s.quest) then
            -- autre prise passée dont le rendu est déjà derrière : on ne la reprend pas en chemin
            local ahead = false
            for m = to, #g.steps do
                local t = g.steps[m]
                if t.quest == s.quest and t.type ~= "accept" then ahead = true break end
            end
            if not ahead then ns.cdb.skipped[g.id][k] = true end
        end
    end
end

-- Niveau atteint : une prise mise de côté plus tôt dans ce guide, dont la quête est encore à faire
-- plus loin (son rendu n'est pas encore passé), redevient l'étape en cours.
function E.ResumeLevelWait()
    local g, _, cur = E.Current()
    local lw = ns.cdb.levelWait
    if not (g and cur and lw and next(lw)) then return end
    for j = 1, cur - 1 do
        local s = g.steps[j]
        if s.type == "accept" and s.quest and lw[s.quest] and E.Applies(s) and not E.TooLow(s)
            and not questInLog(s.quest) and not questDone(s.quest) then
            local ahead = false
            for k = cur, #g.steps do
                local t = g.steps[k]
                if t.quest == s.quest and (t.type == "turnin" or t.type == "complete") then ahead = true break end
            end
            lw[s.quest] = nil
            if ahead then
                E.KeepPassed(g, j, cur)
                ns.cdb.stepIndex = j
                ns.Toast(ns.Tr("Niveau atteint : retour à une quête mise de côté."), "Interface\\GossipFrame\\AvailableQuestIcon", 0.4, 0.9, 0.5, 4)
                E.Refresh()
                ns.Fire("FP_STEP_CHANGED", true)
                return true
            end
        end
    end
end
ns.On("PLAYER_LEVEL_UP", function() C_Timer.After(1.5, E.ResumeLevelWait) end)

function E.CheckOffered()
    if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
        local ids = {}
        for _, info in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do ids[#ids + 1] = info.questID end
        if E.Reoffered(ids) then return end
    end
    local step = offerStep()
    if not step then return end
    if not (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then return end
    for _, list in ipairs({ C_GossipInfo.GetAvailableQuests() or {}, C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {} }) do
        for _, info in ipairs(list) do
            if info.questID == step.quest then return end
        end
    end
    return E.MarkNotOffered()
end

-- PNJ sans dialogue, avec seulement des quêtes : fenêtre « quêtes » (plusieurs) ou directement le
-- détail d'une autre quête (une seule proposée). Dans les deux cas, on sait si la nôtre y est.
function E.CheckGreeting()
    if GetNumAvailableQuests and GetAvailableQuestInfo then
        local ids = {}
        for k = 1, GetNumAvailableQuests() or 0 do ids[#ids + 1] = select(5, GetAvailableQuestInfo(k)) end
        if E.Reoffered(ids) then return end
    end
    local step = offerStep()
    if not (step and GetNumAvailableQuests and GetAvailableQuestInfo) then return end
    for k = 1, GetNumAvailableQuests() or 0 do
        local id = select(5, GetAvailableQuestInfo(k))
        if id == nil then return end                 -- client sans identifiant : on ne conclut rien
        if id == step.quest then return end
    end
    for k = 1, (GetNumActiveQuests and GetNumActiveQuests() or 0) do
        if GetActiveQuestID and GetActiveQuestID(k) == step.quest then return end
    end
    return E.MarkNotOffered()
end
local listedAt = -1000          -- dernière liste de quêtes (dialogue ou fenêtre « quêtes ») vue
ns.On("GOSSIP_SHOW", function() listedAt = GetTime() end)
ns.On("QUEST_GREETING", function() listedAt = GetTime() end)
function E.CheckDetail()
    if GetQuestID and E.Reoffered({ GetQuestID() }) then return end
    local step = offerStep()
    -- détail ouvert depuis une liste : c'est le joueur qui a choisi une autre quête, on ne conclut rien
    if not (step and GetQuestID) or GetTime() - listedAt < 60 then return end
    local id = GetQuestID()
    if id and id ~= 0 and not ns.IsSecret(id) and id ~= step.quest and not (QuestGetAutoAccept and QuestGetAutoAccept()) then
        return E.MarkNotOffered()
    end
end

-- Étapes validées par un événement du jeu : on les marque comme faites
local function markCurrent(kind)
    local g, step, i = E.Current()
    if g and step and step.type == kind then
        ns.cdb.skipped[g.id] = ns.cdb.skipped[g.id] or {}
        ns.cdb.skipped[g.id][i] = true
        E.Refresh()
    end
end
E.MarkCurrent = markCurrent
ns.On("HEARTHSTONE_BOUND", function() markCurrent("bind") end)
ns.On("GOSSIP_SHOW", function() E.CheckOffered() end)
ns.On("QUEST_GREETING", function() E.CheckGreeting() end)
ns.On("QUEST_DETAIL", function() E.CheckDetail() end)
ns.On("PLAYER_CONTROL_LOST", function()
    C_Timer.After(1, function() if UnitOnTaxi and UnitOnTaxi("player") then markCurrent("fly") end end)
end)
ns.On("TAXIMAP_OPENED", function() markCurrent("flightpath") end)

function E.Current()
    local g = ns.Guides[ns.cdb.guideId or ""]
    if not g then return end
    return g, g.steps[ns.cdb.stepIndex], ns.cdb.stepIndex
end

function E.Refresh()
    local g = ns.Guides[ns.cdb.guideId or ""]
    if not g then ns.Fire("FP_STEP_CHANGED", false) return end
    local start = math.max(1, ns.cdb.stepIndex or 1)
    local i = start
    local waiting
    while g.steps[i] and E.IsDone(g.steps[i], i) do
        local s = g.steps[i]
        if E.TooLow(s) and E.Applies(s) and not (ns.cdb.skipped[g.id] or {})[i] then waiting = waiting or s end
        i = i + 1
    end
    local changed = i ~= start
    if waiting and changed and waiting.quest ~= E.lastWaitToast then
        E.lastWaitToast = waiting.quest
        ns.Toast(ns.Tr("Quête de niveau %d requis : mise de côté, le guide y reviendra à ce niveau."):format(waiting.req),
            "Interface\\GossipFrame\\AvailableQuestIcon", 0.7, 0.7, 0.7, 4)
    end
    ns.cdb.stepIndex = i
    if not g.steps[i] and changed then
        local nextId = g.next
        if g.chosen then
            -- zone choisie à la main, terminée : retour à la route conseillée
            ns.cdb.pinned, ns.cdb.zoneChoice = nil, nil
            ns.Toast(ns.Tr("Plus rien à faire dans cette zone à ton niveau : retour à la route conseillée."), "Interface\\Icons\\INV_Misc_Map_01", 1, 0.85, 0.3)
            nextId = E.PickDefault()
        elseif not (nextId and ns.Guides[nextId]) then
            local pick = E.PickDefault()
            if pick ~= g.id then nextId = pick end
        end
        if nextId and ns.Guides[nextId] then
            ns.Toast(L.NEXT_SEGMENT:format(ns.Guides[nextId].name), "Interface\\Icons\\INV_Misc_Map_01", 1, 0.85, 0.3)
            E.Load(nextId, true)
            return
        end
        ns.Print(L.GUIDE_DONE)
    end
    ns.Fire("FP_STEP_CHANGED", changed)
end

function E.Load(id, silent)
    if not ns.Guides[id] and ns.RebuildGuide then ns.RebuildGuide(id) end
    if not ns.Guides[id] then ns.Print(L.UNKNOWN_GUIDE, tostring(id)) return end
    if ns.cdb.pinned ~= id then ns.cdb.pinned = nil end
    if not ns.Guides[id].chosen then ns.cdb.zoneChoice = nil end
    ns.cdb.guideId = id
    ns.cdb.stepIndex = 1
    ns.cdb.skipped[id] = ns.cdb.skipped[id] or {}
    if not silent then ns.Print(L.LOADED, ns.Guides[id].name) end
    E.Refresh()
    ns.Fire("FP_STEP_CHANGED", true)
end

function E.Next()
    local g, step, i = E.Current()
    if not step then return end
    ns.cdb.skipped[g.id][i] = true
    ns.cdb.stepIndex = i + 1
    E.Refresh()
    ns.Fire("FP_STEP_CHANGED", true)
end

function E.Prev()
    local g, _, i = E.Current()
    if not g then return end
    local j = i - 1
    while j >= 1 and not E.Applies(g.steps[j]) do j = j - 1 end
    if j >= 1 then ns.cdb.skipped[g.id][j] = nil end
    ns.cdb.stepIndex = math.max(1, j)
    ns.Fire("FP_STEP_CHANGED", true)
end

-- Étape à viser pour la navigation : l'étape en cours si elle a une position,
-- sinon la prochaine étape applicable qui en a une (notes, paliers de niveau...).
-- Détour : destination temporaire (maître de classe, auberge...) qui passe avant l'étape du guide.
-- d = { map = uiMapID, x = 0..100, y = 0..100, text = "...", icon = "...", radius = yards }
local detour
function E.SetDetour(d)
    if d then d.type, d.detour = "goto", true end
    detour = d
    ns.Fire("FP_DETOUR", d)
    ns.Fire("FP_STEP_CHANGED", true)
end
function E.Detour() return detour end

function E.NavStep()
    if detour then return detour end
    local g, step, i = E.Current()
    if not step then return end
    if step.x then return step end
    for j = i + 1, math.min(#g.steps, i + 15) do
        local s = g.steps[j]
        if s.x and E.Applies(s) and not E.IsDone(s, j) then return s end
    end
end

-- Prochaines étapes applicables (aperçu)
function E.Upcoming(n)
    local g, _, i = E.Current()
    local out = {}
    if not g then return out end
    for j = i + 1, #g.steps do
        local s = g.steps[j]
        if E.Applies(s) and not E.IsDone(s, j) then out[#out + 1] = s end
        if #out >= n then break end
    end
    return out
end

function E.GuideQuests()
    local g = ns.Guides[ns.cdb.guideId or ""]
    local set = {}
    if not g then return set end
    for _, s in ipairs(g.steps) do
        if s.quest and E.Applies(s) then
            set[s.quest] = set[s.quest] or {}
            set[s.quest][s.type] = true
        end
    end
    return set
end

-- Cibles de l'étape courante : PNJ (npcID/nom) + mobs
function E.Targets()
    local _, step = E.Current()
    local t = { ids = {}, names = {}, step = step }
    if not step then return t end
    if step.npcID then
        t.ids[step.npcID] = "npc"
        local n = ns.NpcName(step.npcID)
        if n then t.names[n] = "npc" end
    end
    if step.npc then t.names[step.npc] = "npc" end
    if step.mobs then
        for id in pairs(step.mobs) do
            t.ids[id] = "mob"
            local n = ns.NpcName(id)
            if n then t.names[n] = "mob" end
        end
    end
    if step.target then t.names[step.target] = "mob" end
    return t
end

-- Guide par défaut : faction + race (parcours) + niveau
function E.PickDefault(lvl)
    local race, faction = ns.PlayerRace(), ns.PlayerFaction()
    lvl = lvl or ns.PlayerLevel()
    local byRace, anyFaction
    -- zone de départ spéciale (ex. Île de Zéphras pour les Éolides)
    local here = ns.CurrentZone and ns.CurrentZone()
    if here and lvl < 13 then
        for _, id in ipairs(ns.GuideOrder) do
            local g = ns.Guides[id]
            if g.startZone == here.key and (not g.faction or g.faction == faction) then return id end
        end
    end
    for _, id in ipairs(ns.GuideOrder) do
        local g = ns.Guides[id]
        local okFaction = not g.faction or g.faction == faction
        local okLvl = lvl >= (g.minLevel or 1) and lvl < (g.maxLevel or 61)
        local okPath = not ns.cdb.path or g.path == ns.cdb.path
        if okFaction and okLvl and okPath then
            if ns.cdb.path then return id end
            if g.race and g.race[race] then byRace = byRace or id end
            if not g.race or not anyFaction then anyFaction = anyFaction or id end
        end
    end
    -- race inconnue (ex. Éolides) : premier parcours de la faction
    if byRace or anyFaction then return byRace or anyFaction end
    -- niveau au-delà du dernier segment : on prend le dernier segment de la faction
    local last
    for _, id in ipairs(ns.GuideOrder) do
        local g = ns.Guides[id]
        if (not g.faction or g.faction == faction) and (not ns.cdb.path or g.path == ns.cdb.path)
            and (g.minLevel or 1) <= lvl then last = id end
    end
    return last
end

-- Le joueur a-t-il dépassé le segment actuel ? -> propose le bon segment
function E.CheckLevel()
    local g = ns.Guides[ns.cdb.guideId or ""]
    if not g then return end
    if ns.cdb.pinned == g.id then return end     -- zone choisie à la main (panneau Zones)
    local lvl = ns.PlayerLevel()
    if g.maxLevel and lvl >= g.maxLevel + 2 then
        local id = E.PickDefault(lvl)
        if id and id ~= g.id then E.Load(id) end
    end
end
ns.On("PLAYER_LEVEL_UP", function() C_Timer.After(1, E.CheckLevel) end)

local pending = false
local function queueRefresh()
    if pending then return end
    pending = true
    C_Timer.After(0.2, function() pending = false; E.Refresh() end)
end
for _, ev in ipairs({ "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE", "PLAYER_LEVEL_UP",
                      "ZONE_CHANGED_NEW_AREA", "QUEST_REMOVED" }) do
    ns.On(ev, queueRefresh)
end

ns.On("FP_READY", function()
    -- personnage transféré / changé de faction, ou guide d'un autre parcours : on repart du bon segment
    -- zone choisie à la main avant un /reload : son guide est reconstruit
    if ns.cdb.guideId and not ns.Guides[ns.cdb.guideId] and ns.RebuildGuide then ns.RebuildGuide(ns.cdb.guideId) end
    local cur = ns.cdb.guideId and ns.Guides[ns.cdb.guideId]
    if cur and cur.faction and cur.faction ~= ns.PlayerFaction() then ns.cdb.guideId = nil end
    if not ns.cdb.guideId or not ns.Guides[ns.cdb.guideId] then
        local id = E.PickDefault()
        if id then E.Load(id) end
    else
        E.CheckLevel()
        E.Refresh()
    end
    C_Timer.NewTicker(0.5, function()
        local _, step = E.Current()
        if step and step.type == "goto" then E.Refresh() end
        if detour then
            local d = E.Distance(detour)
            if d and d < (detour.radius or 12) then
                local done = detour
                E.SetDetour(nil)
                ns.Fire("FP_DETOUR_ARRIVED", done)
            end
        end
        ns.Fire("FP_TICK")
    end)
end)
