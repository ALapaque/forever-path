local _, ns = ...

-- Journal de quêtes : prévient avant qu'il soit plein et propose quoi abandonner (quêtes hors de la
-- route, les plus basses d'abord). Un clic sur le bouton abandonne la première suggestion.
local M = ns.RegisterModule({
    id = "questlog", category = "comfort", default = true,
    name = "Journal de quêtes plein",
    desc = "Prévient quand ton journal de quêtes est presque plein et propose les quêtes à abandonner (hors de la route, les plus basses d'abord). Un bouton dans le guide abandonne la première suggestion.",
    options = {
        { key = "margin", label = "Prévenir à N places de la limite", type = "slider", min = 1, max = 6, step = 1, default = 2 },
    },
})

function M.Count()
    local n = 0
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and not info.isHidden and info.questID then n = n + 1 end
    end
    local max = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 20
    return n, max
end

-- quêtes à abandonner en priorité : hors route, niveau le plus bas
function M.Suggestions()
    local route = ns.Engine.GuideQuests()
    local out = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local q = info and not info.isHeader and info.questID
        if q and not route[q] and not C_QuestLog.IsComplete(q) then
            out[#out + 1] = { id = q, title = info.title or C_QuestLog.GetTitleForQuestID(q) or ("#" .. q), level = info.level or 0 }
        end
    end
    table.sort(out, function(a, b) return a.level < b.level end)
    return out
end

local btn
function M:Update()
    if not ns.Guide then return end
    local n, max = M.Count()
    local full = self.enabled and max - n <= (M:Opt("margin") or 2)
    local sugg = full and M.Suggestions() or {}
    if full then
        local names = {}
        for k = 1, math.min(3, #sugg) do names[k] = sugg[k].title end
        local text = ns.Tr("|cffff7f3fJournal presque plein|r (%d/%d)"):format(n, max)
        if #names > 0 then text = text .. "\n" .. ns.Tr("À abandonner : %s"):format(table.concat(names, ", ")) end
        ns.Guide:SetSection("questlog", 7, text)
    else
        ns.Guide:SetSection("questlog", 7, nil)
    end
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("questlog", nil, 22, function() M:AbandonFirst() end, function(tt)
            local s = M.Suggestions()[1]
            tt:AddLine(ns.Tr("Abandonner une quête hors de la route"))
            if s then tt:AddLine(s.title, 1, 1, 1) end
        end, "Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    end
    if btn then btn:SetShown(full and #sugg > 0 or false); ns.Guide:Layout() end
end

function M:AbandonFirst()
    local s = M.Suggestions()[1]
    if not s then return end
    C_QuestLog.SetSelectedQuest(s.id)
    C_QuestLog.SetAbandonQuest()
    C_QuestLog.AbandonQuest()
    ns.Print(("Quête abandonnée : %s"):format(s.title))
end

local queued
local function queue()
    if queued then return end
    queued = true
    C_Timer.After(0.5, function() queued = false; M:Update() end)
end
M:On("QUEST_ACCEPTED", queue)
M:On("QUEST_REMOVED", queue)
M:On("QUEST_LOG_UPDATE", queue)
M:On("QUEST_DETAIL", function()
    local n, max = M.Count()
    if n >= max then ns.Toast("Journal de quêtes plein : abandonne une quête hors de la route.", nil, 1, 0.5, 0.25) end
end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cffff7f3fJournal presque plein|r (19/20)\nÀ abandonner : Le vieux puits")
end
