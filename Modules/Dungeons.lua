local _, ns = ...
local Places = ns.Nav.Places

-- Donjons : quand ton niveau colle à un donjon, liste ses quêtes à prendre avant d'y aller
-- (données QuestieDB), dit ce qu'elles rapportent, et propose une tournée : toutes les quêtes dans
-- l'ordre le plus court, puis l'entrée du donjon.
local M = ns.RegisterModule({
    id = "dungeons", category = "guide", default = true,
    name = "Quêtes de donjon",
    desc = "Quand ton niveau colle à un donjon, le guide indique combien de ses quêtes tu peux prendre avant d'y aller et ce qu'elles rapportent. Un bouton lance la tournée : chaque quête dans l'ordre le plus court, puis l'entrée du donjon. /qw donjons pour la liste complète.",
    options = {
        { key = "section", label = "Rappel dans le guide", type = "check", default = true },
        { key = "grouponly", label = "Seulement quand tu es en groupe", type = "check", default = false },
        { key = "alert", label = "Alerte quand un donjon arrive à ton niveau", type = "check", default = true },
    },
})
local ICON = "Interface\\Icons\\INV_Misc_Key_03"

local function faction(f) return f == "both" or f == ns.PlayerFaction() end
local function done(q) return C_QuestLog.IsQuestFlaggedCompleted(q) end

-- prérequis rendus (listes « tous » et « au moins un » de la base)
local function unlocked(all, any)
    for v in (all or ""):gmatch("%d+") do if not done(tonumber(v)) then return false end end
    if not any or any == "" then return true end
    for v in any:gmatch("%d+") do if done(tonumber(v)) then return true end end
    return false
end

-- donjons à ton niveau : { key, name, min, max, quests = { ... }, xp, entrance } (quêtes prenables, pas faites)
function M.ForLevel(lvl)
    lvl = lvl or ns.PlayerLevel()
    local out = {}
    for k, d in ipairs(ns.World and ns.World.dungeons or {}) do
        if lvl >= d[3] - 2 and lvl <= d[4] then
            local qs, xp = {}, 0
            for _, q in ipairs(d[5]) do
                local id, qlvl, req, fac = q[1], q[2], q[3], q[4]
                if faction(fac) and req <= lvl and qlvl + 6 > lvl and not done(id)
                    and not C_QuestLog.GetLogIndexForQuestID(id) and unlocked(q[12], q[13]) then
                    qs[#qs + 1] = { id = id, level = qlvl, req = req, npc = q[5], map = q[6], x = q[7], y = q[8],
                        name = ns.isFrench and q[9] or q[10], xp = q[11] or 0 }
                    xp = xp + (q[11] or 0)
                end
            end
            if #qs > 0 then
                local e = d[6]
                out[#out + 1] = { key = k, name = ns.isFrench and d[1] or d[2], min = d[3], max = d[4], quests = qs, xp = xp,
                    entrance = e and { map = e[1], x = e[2], y = e[3] } or nil }
            end
        end
    end
    return out
end

-- part d'un niveau que rapportent les quêtes (XP de base de la quête, sans l'XP des monstres)
function M.Share(d)
    local max = UnitXPMax and UnitXPMax("player") or 0
    if not (d and d.xp and d.xp > 0 and type(max) == "number" and not ns.IsSecret(max) and max > 0) then return end
    return math.floor(d.xp / max * 100 + 0.5)
end

local function active()
    if not M.enabled then return false end
    if M:Opt("grouponly") and not (IsInGroup and IsInGroup()) then return false end
    return true
end

local function summary(d)
    local pct = M.Share(d)
    if pct then
        return ns.Tr("|cffcc66ffDonjon|r %s (%d-%d) : %d quête(s) à prendre avant, environ %d %% d'un niveau"):format(d.name, d.min, d.max, #d.quests, pct)
    end
    return ns.Tr("|cffcc66ffDonjon|r %s (%d-%d) : %d quête(s) à prendre avant"):format(d.name, d.min, d.max, #d.quests)
end

local btn
function M:Update()
    if not ns.Guide then return end
    local cur = ns.Guides[ns.cdb.guideId or ""]
    local list = (active() and self:Opt("section") and not (cur and cur.dungeon)) and M.ForLevel() or {}
    local d = list[1]
    ns.Guide:SetSection("dungeons", 85, d and summary(d) or nil)
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("dungeons", nil, 22, function() M:Tour() end, function(tt)
            local dd = M.ForLevel()[1]
            if not dd then return end
            tt:AddLine(dd.name)
            for k = 1, math.min(8, #dd.quests) do tt:AddLine(("%d. %s (%d)"):format(k, dd.quests[k].name, dd.quests[k].level), 1, 1, 1) end
            tt:AddLine(ns.Tr("Clic : tournée des quêtes, puis l'entrée du donjon"), 0.6, 0.6, 0.6)
        end, ICON)
    end
    if btn then btn:SetShown(d ~= nil); ns.Guide:Layout() end
end

function M:GoNearest()
    local d = M.ForLevel()[1]
    if not d then return end
    local q = Places.Nearest(d.quests)
    if q then Places.Go(q, ns.Tr("Quête de donjon : %s"):format(q.name), ICON, "dungeon") end
end

---------------------------------------------------------------------------
-- Tournée : un guide qui prend toutes les quêtes du donjon, la plus proche d'abord, puis mène à
-- l'entrée. Comme une zone choisie à la main : il passe avant la route, et la route reprend après.
---------------------------------------------------------------------------
local TPREFIX = "donjon:"

-- ordre : toujours le donneur le plus proche du précédent (les autres continents à la fin)
local function ordered(quests)
    local Nav = ns.Nav
    local left, out = {}, {}
    for _, q in ipairs(quests) do left[#left + 1] = q end
    local here = Nav.Player and Nav.Player()
    while #left > 0 do
        local best, bestD
        for i, q in ipairs(left) do
            local c, wx, wy = Nav.ToWorld(q.map, q.x / 100, q.y / 100)
            local d2
            if here and c then
                d2 = c == here.c and Nav.Dist(here, { x = wx, y = wy }) or 1e6
            else
                d2 = 1e7
            end
            if not bestD or d2 < bestD or (d2 == bestD and q.id < left[best].id) then best, bestD = i, d2 end
        end
        local q = table.remove(left, best)
        out[#out + 1] = q
        local c, wx, wy = Nav.ToWorld(q.map, q.x / 100, q.y / 100)
        if c then here = { c = c, x = wx, y = wy } end
    end
    return out
end

local function build(key, ids)
    local d = ns.World and ns.World.dungeons and ns.World.dungeons[key]
    if not d then return end
    local byId = {}
    for _, q in ipairs(d[5]) do byId[q[1]] = q end
    local steps = {}
    for _, id in ipairs(ids) do
        local q = byId[id]
        if q then
            steps[#steps + 1] = { type = "accept", quest = id, map = q[6], x = q[7], y = q[8], npcID = q[5], qlvl = q[2], req = q[3] }
        end
    end
    if #steps == 0 then return end
    local name = ns.isFrench and d[1] or d[2]
    if d[6] then
        steps[#steps + 1] = { type = "goto", map = d[6][1], x = d[6][2], y = d[6][3], radius = 40,
            text = ns.Tr("Entrée du donjon : %s"):format(name) }
    end
    local g = { id = TPREFIX .. key, name = ns.Tr("Quêtes de donjon : %s"):format(name), steps = steps,
        minLevel = d[3], maxLevel = d[4], chosen = true, dungeon = key,
        doneText = ns.Tr("Quêtes du donjon prises : retour à la route conseillée.") }
    ns.Guides[g.id] = g              -- pas dans GuideOrder : jamais choisi automatiquement
    return g
end

function M:Tour()
    local d = M.ForLevel()[1]
    if not d then return end
    local ids = {}
    for _, q in ipairs(ordered(d.quests)) do ids[#ids + 1] = q.id end
    local g = build(d.key, ids)
    if not g then return end
    ns.cdb.dungeonTour = { key = d.key, quests = ids }
    ns.cdb.skipped[g.id] = {}
    ns.Engine.Load(g.id)
    ns.cdb.pinned = g.id
    self:Update()
    return g
end

-- après un /reload : la tournée enregistrée est reconstruite à l'identique
local rebuildZone = ns.RebuildGuide
function ns.RebuildGuide(id)
    local key = tonumber((id or ""):match("^" .. TPREFIX .. "(%d+)$"))
    local saved = ns.cdb.dungeonTour
    if key and saved and saved.key == key then return build(key, saved.quests) end
    return rebuildZone and rebuildZone(id)
end

-- alerte : un donjon arrive à ton niveau, une seule fois par donjon
local function announce()
    if not (active() and M:Opt("alert") ~= false) then return end
    ns.cdb.dungeonSeen = ns.cdb.dungeonSeen or {}
    for _, d in ipairs(M.ForLevel()) do
        if not ns.cdb.dungeonSeen[d.key] and #d.quests >= 2 then
            ns.cdb.dungeonSeen[d.key] = true
            ns.Toast(summary(d), ICON, 0.8, 0.4, 1, 7)
            return
        end
    end
end
M.Announce = announce

function M.List()
    local lines = {}
    for _, d in ipairs(M.ForLevel()) do
        lines[#lines + 1] = ("%s (%d-%d)"):format(d.name, d.min, d.max)
        for _, q in ipairs(d.quests) do
            lines[#lines + 1] = ("  [%d] %s — %s %.0f,%.0f"):format(q.level, q.name, Places.ZoneName(q.map), q.x, q.y)
        end
        lines[#lines + 1] = ""
    end
    return #lines > 0 and table.concat(lines, "\n") or ns.Tr("Aucun donjon à ton niveau pour le moment.")
end
ns.SlashExt.donjons = function() ns.ShowExport(M.List(), ns.Tr("Quêtes de donjon à ton niveau")) end
ns.SlashExt.dungeons = ns.SlashExt.donjons

M:On("PLAYER_LEVEL_UP", function() C_Timer.After(1, function() announce(); M:Update() end) end)
M:On("GROUP_ROSTER_UPDATE", function() M:Update() end)
local queued
M:On("FP_STEP_CHANGED", function()
    if queued then return end
    queued = true
    C_Timer.After(0.5, function() queued = false; M:Update() end)
end)
M:On("QUEST_ACCEPTED", function() M:Update() end)
M:On("FP_READY", function() M:Update() end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cffcc66ffDonjon|r Les Mortemines (17-26)\n4 quête(s) à prendre avant")
end
