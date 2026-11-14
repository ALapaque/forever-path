local _, ns = ...

-- Bouton sécurisé pour utiliser l'objet de la quête en cours (ex. une fiole à verser).
-- Les attributs d'un bouton sécurisé ne peuvent changer qu'hors combat.
local M = ns.RegisterModule({
    id = "questitem", category = "guide", default = true,
    name = "Bouton d'objet de quête",
    desc = "Un bouton cliquable (et un raccourci clavier) pour utiliser l'objet de la quête en cours.",
    options = {},
})

local b = CreateFrame("Button", "ForeverPathQuestItemButton", UIParent, "SecureActionButtonTemplate")
b:SetSize(36, 36)
b:RegisterForClicks("AnyUp", "AnyDown")
b:SetAttribute("type", "item")
b:Hide()
ns.MakeMovable(b, "questitem", { "CENTER", "CENTER", 0, -160 })
b.icon = b:CreateTexture(nil, "ARTWORK")
b.icon:SetAllPoints()
b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
b.count:SetPoint("BOTTOMRIGHT", -2, 2)
b:SetScript("OnEnter", function(self)
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end
end)
b:SetScript("OnLeave", function() GameTooltip:Hide() end)

local dirty = false
function M:Update()
    if InCombatLockdown() then dirty = true return end
    dirty = false
    local _, step = ns.Engine.Current()
    local link, tex, charges
    local function from(questID)
        local idx = questID and C_QuestLog.GetLogIndexForQuestID(questID)
        if idx then return GetQuestLogSpecialItemInfo(idx) end
    end
    if step and step.quest then link, tex, charges = from(step.quest) end
    if not link then
        -- sinon : premier objet utilisable du journal
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader then
                link, tex, charges = GetQuestLogSpecialItemInfo(i)
                if link then break end
            end
        end
    end
    if link then
        b.link = link
        b:SetAttribute("item", link)
        b.icon:SetTexture(tex)
        b.count:SetText(charges and charges > 1 and charges or "")
        b:Show()
    else
        b.link = nil
        b:SetAttribute("item", nil)
        b:Hide()
    end
end

function M:OnEnable() self:Update() end
function M:OnDisable() if not InCombatLockdown() then b:Hide() end end
M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("QUEST_LOG_UPDATE", function() M:Update() end)
M:On("BAG_UPDATE_DELAYED", function() M:Update() end)
M:On("PLAYER_REGEN_ENABLED", function() if dirty then M:Update() end end)

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(36, 36)
    t:SetPoint("CENTER", 0, 6)
    t:SetTexture("Interface\\Icons\\INV_Potion_51")
    local k = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    k:SetPoint("TOP", t, "BOTTOM", 0, -3)
    k:SetText("Raccourci : à définir")
end
