local _, ns = ...

local M = ns.RegisterModule({
    id = "automation", category = "comfort", default = true,
    name = "Prise et rendu automatiques",
    desc = "Accepte et rend tout seul les quêtes de la route. Ne choisit jamais une récompense à ta place. Maintiens Maj pour désactiver.",
    options = {
        { key = "accept", label = "Accepter automatiquement", type = "check", default = true },
        { key = "turnin", label = "Rendre automatiquement", type = "check", default = true },
        { key = "onlyGuide", label = "Seulement les quêtes de la route", type = "check", default = true },
    },
})

local function wants(questID, kind)
    if not questID or questID == 0 then return false end
    if not M:Opt("onlyGuide") then return true end
    local q = ns.Engine.GuideQuests()[questID]
    return q and q[kind]
end
local function on(key) return M:Opt(key) and not IsShiftKeyDown() end

M:On("GOSSIP_SHOW", function()
    if on("turnin") then
        for _, q in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
            if q.isComplete and wants(q.questID, "turnin") then C_GossipInfo.SelectActiveQuest(q.questID) return end
        end
    end
    if on("accept") then
        for _, q in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
            if wants(q.questID, "accept") then C_GossipInfo.SelectAvailableQuest(q.questID) return end
        end
    end
end)

M:On("QUEST_GREETING", function()
    if on("turnin") then
        for i = 1, GetNumActiveQuests() do
            local _, isComplete = GetActiveTitle(i)
            local qid = GetActiveQuestID and GetActiveQuestID(i)
            if isComplete and wants(qid, "turnin") then SelectActiveQuest(i) return end
        end
    end
    if on("accept") then
        for i = 1, GetNumAvailableQuests() do
            local qid = select(5, GetAvailableQuestInfo(i))
            if wants(qid, "accept") then SelectAvailableQuest(i) return end
        end
    end
end)

M:On("QUEST_DETAIL", function()
    if on("accept") and wants(GetQuestID(), "accept") then AcceptQuest() end
end)
M:On("QUEST_PROGRESS", function()
    if on("turnin") and wants(GetQuestID(), "turnin") and IsQuestCompletable() then CompleteQuest() end
end)
M:On("QUEST_COMPLETE", function()
    if on("turnin") and wants(GetQuestID(), "turnin") and GetNumQuestChoices() <= 1 then GetQuestReward(1) end
end)

function M.preview(p)
    local i1 = p:CreateTexture(nil, "ARTWORK")
    i1:SetSize(24, 24); i1:SetPoint("CENTER", -26, 8)
    i1:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    local i2 = p:CreateTexture(nil, "ARTWORK")
    i2:SetSize(24, 24); i2:SetPoint("CENTER", 26, 8)
    i2:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
    local a = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    a:SetPoint("CENTER", 0, 8); a:SetText("→")
    local t = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    t:SetPoint("TOP", 0, -50); t:SetText("Maj = manuel")
end
