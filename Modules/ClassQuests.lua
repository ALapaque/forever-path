local _, ns = ...
local Places = ns.Nav.Places

-- Quêtes de classe : sorts, familiers, totems, formes, objets de classe. Les routes sont les mêmes
-- pour toutes les classes et les laissent de côté ; ce module propose celles que ton personnage peut
-- prendre (niveau, race, prérequis faits), avec un détour vers le PNJ, et rappelle où les rendre.
local M = ns.RegisterModule({
    id = "classquests", category = "guide", default = true,
    name = "Quêtes de classe",
    desc = "Propose les quêtes de ta classe (sorts, familiers, totems, formes) dès que tu peux les prendre : le guide indique la quête et un bouton t'amène au PNJ, puis là où la rendre. /qw classe pour la liste complète.",
    options = {
        { key = "section", label = "Rappel dans le guide", type = "check", default = true },
        { key = "alert", label = "Alerte quand une quête de classe se débloque", type = "check", default = true },
        { key = "far", label = "Proposer aussi celles d'un autre continent", type = "check", default = true },
    },
})
local ICON = "Interface\\Icons\\INV_Misc_Book_11"

local RACE_BIT = { Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Scourge = 16, Tauren = 32, Gnome = 64, Troll = 128 }
-- masque de races de la base (0 = toutes) ; les bits 32 et 33 sont les Éolides de l'Alliance et de la Horde
function M.RaceOK(mask)
    if not mask or mask == 0 then return true end
    local b = RACE_BIT[ns.PlayerRace() or ""]
    if b then return math.floor((mask % 4294967296) / b) % 2 == 1 end
    local sky = ns.PlayerFaction() == "Alliance" and 1 or 2
    return math.floor(math.floor(mask / 4294967296) / sky) % 2 == 1
end

local function ids(s)
    local out = {}
    for v in (s or ""):gmatch("%d+") do out[#out + 1] = tonumber(v) end
    return out
end

local cache = {}
-- quêtes de ta classe : { id, level, req, races, npc, map, x, y, ender = { npc, map, x, y }, all, any, name }
function M.Entries(class)
    class = class or ns.PlayerClass()
    if cache[class] then return cache[class] end
    local list = {}
    for _, q in ipairs(ns.ClassQuests and ns.ClassQuests[class] or {}) do
        list[#list + 1] = { id = q[1], level = q[2], req = q[3], races = q[4], npc = q[5] ~= 0 and q[5] or nil,
            map = q[6], x = q[7], y = q[8],
            ender = q[10] ~= 0 and { npc = q[9] ~= 0 and q[9] or nil, map = q[10], x = q[11], y = q[12] } or nil,
            all = ids(q[13]), any = ids(q[14]), name = ns.isFrench and q[15] or q[16] }
    end
    cache[class] = list
    return list
end

local function done(q) return C_QuestLog.IsQuestFlaggedCompleted(q) end
local function inLog(q) return C_QuestLog.GetLogIndexForQuestID(q) ~= nil end

local function unlocked(e)
    for _, p in ipairs(e.all) do if not done(p) then return false end end
    if #e.any == 0 then return true end
    for _, p in ipairs(e.any) do if done(p) then return true end end
    return false
end

-- quête mise de côté : son PNJ ne la proposait pas à ce niveau (elle revient au niveau suivant)
local function setAside(e, lvl)
    local s = ns.cdb.classSkip
    return s and s[e.id] and s[e.id] >= lvl
end

-- open : quêtes à prendre maintenant ; ready : quêtes de classe finies, à rendre ; soon : bientôt
function M.Status(lvl)
    lvl = lvl or ns.PlayerLevel()
    local open, ready, soon = {}, {}, {}
    for _, e in ipairs(M.Entries()) do
        -- lettres d'introduction des zones de départ, devenues grises : plus proposées
        local stale = e.level < 6 and lvl >= e.level + 8 and not inLog(e.id)
        if not stale and not done(e.id) and M.RaceOK(e.races) then
            if inLog(e.id) then
                if e.ender and C_QuestLog.IsComplete(e.id) then ready[#ready + 1] = e end
            elseif unlocked(e) then
                if e.req <= lvl then
                    if not setAside(e, lvl) then open[#open + 1] = e end
                elseif e.req <= lvl + 4 then
                    soon[#soon + 1] = e
                end
            end
        end
    end
    local function byLevel(a, b) if a.req ~= b.req then return a.req < b.req end return a.id < b.id end
    table.sort(open, byLevel); table.sort(soon, byLevel)
    return open, ready, soon
end

-- la plus proche d'abord ; sans l'option « autre continent », celles du continent seulement
local function nearest(list)
    local e, d = Places.Nearest(list)
    if e and d and d >= 1e6 and M:Opt("far") == false then return end
    return e
end

function M.Next()
    local open, ready = M.Status()
    local r = nearest(ready)
    if r then return r, true, #ready + #open end
    return nearest(open), false, #open
end

local btn
function M:Update()
    if not ns.Guide then return end
    local e, turnin, n
    if self.enabled and self:Opt("section") ~= false and not (ns.Engine.Detour() and ns.Engine.Detour().kind == "classquest") then
        e, turnin, n = M.Next()
    end
    if e then
        local where = Places.ZoneName(turnin and e.ender.map or e.map)
        local text
        if turnin then
            text = ns.Tr("|cff69ccf0Quête de classe à rendre|r %s — %s"):format(e.name, where)
        else
            text = ns.Tr("|cff69ccf0Quête de classe|r %s (niv. %d) — %s"):format(e.name, e.level, where)
        end
        if n > 1 then text = text .. ns.Tr(" (+%d autre(s))"):format(n - 1) end
        ns.Guide:SetSection("classquests", 84, text)
    else
        ns.Guide:SetSection("classquests", 84, nil)
    end
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("classquests", nil, 22, function() M:Go() end, function(tt)
            local q, back = M.Next()
            if not q then return end
            tt:AddLine(ns.Tr("Quêtes de classe"))
            tt:AddLine(q.name, 1, 1, 1)
            tt:AddLine(back and ns.Tr("Clic : aller la rendre (détour)") or ns.Tr("Clic : aller la prendre (détour)"), 0.6, 0.6, 0.6)
        end, ICON)
    end
    if btn then btn:SetShown(e ~= nil); ns.Guide:Layout() end
end

local going
function M:Go()
    local e, turnin = M.Next()
    if not e then return end
    going = { quest = e.id, npc = turnin and e.ender.npc or e.npc, turnin = turnin }
    local at = turnin and { map = e.ender.map, x = e.ender.x, y = e.ender.y, npc = e.ender.npc } or e
    Places.Go(at, (turnin and ns.Tr("Rendre la quête de classe : %s") or ns.Tr("Quête de classe : %s")):format(e.name), ICON, "classquest")
    self:Update()
    return e
end

-- au PNJ du détour : s'il ne propose pas la quête, on la met de côté jusqu'au niveau suivant
function M.CheckOffered()
    if not (M.enabled and going and not going.turnin and going.npc) then return end
    if ns.NpcIDFromUnit("npc") ~= going.npc then return end
    if not (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then return end
    for _, info in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
        if info.questID == going.quest then return end
    end
    ns.cdb.classSkip = ns.cdb.classSkip or {}
    ns.cdb.classSkip[going.quest] = ns.PlayerLevel()
    local col = ns.Modules.collector
    if col and col.NoteNotOffered then col.NoteNotOffered(going.quest, going.npc) end
    ns.Toast(ns.Tr("Ce PNJ ne propose pas cette quête de classe pour l'instant : mise de côté jusqu'au niveau suivant."), ICON, 1, 0.8, 0.3, 5)
    going = nil
    if ns.Engine.Detour() and ns.Engine.Detour().kind == "classquest" then ns.Engine.SetDetour(nil) end
    M:Update()
end
M:On("GOSSIP_SHOW", function() M.CheckOffered() end)

function M.List()
    local open, ready, soon = M.Status()
    local lines = {}
    local function add(title, list, turnin)
        if #list == 0 then return end
        lines[#lines + 1] = title
        for _, e in ipairs(list) do
            local map, x, y = e.map, e.x, e.y
            if turnin then map, x, y = e.ender.map, e.ender.x, e.ender.y end
            lines[#lines + 1] = ("  [%d] %s — %s %.0f,%.0f"):format(turnin and e.level or e.req, e.name, Places.ZoneName(map), x, y)
        end
        lines[#lines + 1] = ""
    end
    add(ns.Tr("À rendre :"), ready, true)
    add(ns.Tr("À prendre maintenant :"), open)
    add(ns.Tr("Bientôt (niveau requis entre crochets) :"), soon)
    return #lines > 0 and table.concat(lines, "\n") or ns.Tr("Aucune quête de classe à prendre pour le moment.")
end
ns.SlashExt.classe = function() ns.ShowExport(M.List(), ns.Tr("Quêtes de ta classe")) end
ns.SlashExt.class = ns.SlashExt.classe

M:On("PLAYER_LEVEL_UP", function()
    C_Timer.After(1.5, function()
        if M.enabled and M:Opt("alert") ~= false then
            local lvl = ns.PlayerLevel()
            for _, e in ipairs((M.Status(lvl))) do
                if e.req == lvl then
                    ns.Toast(ns.Tr("Nouvelle quête de classe : %s"):format(e.name), ICON, 0.41, 0.8, 0.94, 6)
                    break
                end
            end
        end
        M:Update()
    end)
end)
local queued
local function queue()
    if queued then return end
    queued = true
    C_Timer.After(0.5, function() queued = false; M:Update() end)
end
M:On("QUEST_ACCEPTED", function(q)
    if going and q == going.quest then going = nil end
    queue()
end)
M:On("QUEST_TURNED_IN", queue)
M:On("QUEST_LOG_UPDATE", queue)
M:On("FP_DETOUR", queue)
M:On("FP_READY", function() M:Update() end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cff69ccf0Quête de classe|r L'appel du feu (niv. 10)\nDurotar")
end
