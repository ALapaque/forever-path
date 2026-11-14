local _, ns = ...
local L = ns.L

ns.Guides = {}
ns.GuideOrder = {}

-- guide = { id, name, faction, race = {...}, minLevel, maxLevel, next = "id", text = DSL }
function ns.RegisterGuide(g)
    assert(g.id and g.text, "guide sans id/text")
    g.steps = ns.ParseGuide(g.text)
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

function E.IsDone(step, idx)
    local skipped = ns.cdb.skipped[ns.cdb.guideId]
    if skipped and skipped[idx] then return true end
    if not E.Applies(step) then return true end
    if step.upto and ns.PlayerLevel() >= step.upto then return true end
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
    end
    return false -- note / hearth / fly / flightpath : validation manuelle (bouton >)
end

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
    while g.steps[i] and E.IsDone(g.steps[i], i) do i = i + 1 end
    local changed = i ~= start
    ns.cdb.stepIndex = i
    if not g.steps[i] and changed then
        local nextId = g.next
        if not (nextId and ns.Guides[nextId]) then
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
    if not ns.Guides[id] then ns.Print(L.UNKNOWN_GUIDE, tostring(id)) return end
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
function E.NavStep()
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
        ns.Fire("FP_TICK")
    end)
end)
