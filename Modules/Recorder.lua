local _, ns = ...
local L = ns.L

-- Enregistreur : joue normalement, l'addon note chaque quête prise / terminée / rendue
-- (avec position et npcID), puis /fp export génère une route au format DSL.
-- Indispensable pour les nouvelles zones de Forever, absentes des bases de données.
local M = ns.RegisterModule({
    id = "recorder", category = "community", default = false,
    name = "Enregistreur de route",
    desc = "Enregistre tes quêtes pendant que tu joues et exporte une route prête à partager. Parfait pour les nouvelles zones (Rives Claires, Shen'dralas, Hyjal...).",
    options = {},
})
ns.Recorder = M

local lastMap, lastNpcID
local completedSeen = {}

local function fmt(n) return ("%.1f"):format(n * 100) end
local function push(line) table.insert(ns.cdb.recorded, line) end

local function posPart()
    local mapID, x, y = ns.PlayerMapPos()
    if not mapID then return "" end
    if mapID ~= lastMap then
        lastMap = mapID
        local info = C_Map.GetMapInfo(mapID)
        local z = ns.ZoneByMap[mapID]
        push(("# --- %s (niv. %d)"):format(info and info.name or "?", ns.PlayerLevel()))
        push("M " .. (z and z.key or tostring(mapID)))
    end
    if x then return (" @%s,%s"):format(fmt(x), fmt(y)) end
    return ""
end

local function npcPart()
    return lastNpcID and (" id=%d"):format(lastNpcID) or ""
end

local function snapshot()
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and info.questID and C_QuestLog.IsComplete(info.questID) then completedSeen[info.questID] = true end
    end
end

function M.IsOn() return M.enabled and ns.cdb and ns.cdb.recording end
function M.Set(on)
    if on and not M.enabled then ns.SetModuleEnabled("recorder", true) end
    ns.cdb.recording = on
    lastMap = nil
    snapshot()
    ns.Print(on and L.REC_ON or L.REC_OFF)
end
function M.Clear()
    wipe(ns.cdb.recorded); wipe(completedSeen); lastMap = nil
    ns.Print(L.REC_CLEARED)
end
function M.Note(text)
    if M.IsOn() then push(('N "%s"%s'):format((text:gsub('"', "'")), posPart())) end
end
function M.Export()
    local header = {
        "# Route enregistrée avec ForeverPath " .. ns.VERSION,
        ("# %s %s, faction %s"):format(ns.PlayerRace() or "?", ns.PlayerClass() or "?", ns.PlayerFaction() or "?"),
        "",
    }
    return table.concat(header, "\n") .. table.concat(ns.cdb.recorded, "\n")
end

local function remember()
    lastNpcID = ns.NpcIDFromUnit("questnpc") or ns.NpcIDFromUnit("npc")
end
M:On("QUEST_DETAIL", remember)
M:On("QUEST_PROGRESS", remember)
M:On("QUEST_COMPLETE", remember)
M:On("GOSSIP_SHOW", remember)

M:On("QUEST_ACCEPTED", function(questID)
    if M.IsOn() then local pos = posPart(); push(("A %d%s%s"):format(questID, pos, npcPart())) end
end)
M:On("QUEST_TURNED_IN", function(questID)
    if M.IsOn() then local pos = posPart(); push(("T %d%s%s"):format(questID, pos, npcPart())) end
end)
M:On("QUEST_LOG_UPDATE", function()
    if not M.IsOn() then return end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and not completedSeen[info.questID]
            and C_QuestLog.IsComplete(info.questID) then
            completedSeen[info.questID] = true
            local pos = posPart()
            push(("C %d%s"):format(info.questID, pos))
        end
    end
end)
M:On("PLAYER_LEVEL_UP", function(lvl) if M.IsOn() then push(("# niveau %d"):format(lvl)) end end)

local btn
function M:OnEnable()
    snapshot()
    if ns.Guide and not btn then
        btn = ns.Guide:AddButton("rec", nil, 22, function() M.Set(not M.IsOn()); M:Paint() end, function(tt)
            tt:SetText("Enregistreur de route", 1, 1, 1)
            tt:AddLine(M.IsOn() and "|cffff4040Enregistrement en cours|r — clic pour arrêter" or "Clic pour enregistrer tes quêtes", 0.8, 0.8, 0.8, true)
            tt:AddLine("/fp export pour copier la route", 0.6, 0.6, 0.6)
        end, ns.MEDIA .. "dot")
    end
    if btn then btn:Show(); ns.Guide:Layout(); self:Paint() end
end
function M:OnDisable() if btn then btn:Hide(); ns.Guide:Layout() end end
function M:Paint()
    if not btn then return end
    if M.IsOn() then btn.icon:SetVertexColor(1, 0.15, 0.15) else btn.icon:SetVertexColor(0.55, 0.55, 0.55) end
end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetJustifyH("LEFT")
    fs:SetText("|T" .. ns.MEDIA .. "dot:12:12:0:0:32:32:0:32:0:32:255:50:50|t REC\nA 9601 @42.1,55.3 id=...\nC 9601 @45.0,61.2")
end
