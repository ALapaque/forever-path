local _, ns = ...

-- Quêtes de groupe / élites : prévient dès l'étape de prise, avec le nombre de joueurs conseillé.
local M = ns.RegisterModule({
    id = "grouphint", category = "safety", default = true,
    name = ns.Tr("Quêtes de groupe"),
    desc = ns.Tr("Signale dans le guide les quêtes de groupe ou élites (nombre de joueurs conseillé), pour chercher de l'aide ou les passer."),
    options = {},
})

function M.Info(q)
    if not q then return end
    local size = C_QuestLog.GetSuggestedGroupSize and C_QuestLog.GetSuggestedGroupSize(q) or 0
    local tag = C_QuestLog.GetQuestTagInfo and C_QuestLog.GetQuestTagInfo(q)
    local elite = tag and (tag.isElite or tag.tagName == "Elite" or tag.tagName == ns.Tr("Élite"))
    if ns.IsSecret(size) then size = 0 end
    if (size or 0) > 1 or elite then return size or 0, elite end
end

function M:Update()
    if not ns.Guide then return end
    local _, step = ns.Engine.Current()
    local size, elite = M.Info(self.enabled and step and step.quest)
    if size then
        local txt = size > 1 and (ns.Tr("%d joueurs conseillés")):format(size) or ns.Tr("élite")
        ns.Guide:SetSection("grouphint", 6, (ns.Tr("|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:12|t |cffff7f3fQuête de groupe|r : %s%s")):format(
            txt, elite and size > 1 and ns.Tr(", élite") or ""))
    else
        ns.Guide:SetSection("grouphint", 6, nil)
    end
end
M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("QUEST_DATA_LOAD_RESULT", function() M:Update() end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:12|t |cffff7f3fQuête de groupe|r\n3 joueurs conseillés"))
end
