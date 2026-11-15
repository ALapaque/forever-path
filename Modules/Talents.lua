local _, ns = ...

-- Talents : rappel quand des points sont à dépenser, avec un bouton pour ouvrir la fenêtre des talents.
-- Pas de conseil de répartition : les arbres de WoW Forever ne sont pas encore documentés.
local M = ns.RegisterModule({
    id = "talents", category = "comfort", default = true,
    name = "Rappel de talents",
    desc = "Signale dans le guide les points de talent à dépenser, avec un bouton pour ouvrir la fenêtre des talents.",
    options = {},
})

function M.Unspent()
    local n = 0
    if GetUnspentTalentPoints then
        local ok, v = pcall(GetUnspentTalentPoints)
        if ok and type(v) == "number" then n = v end
    elseif UnitCharacterPoints then
        local ok, v = pcall(UnitCharacterPoints, "player")
        if ok and type(v) == "number" then n = v end
    end
    if ns.IsSecret(n) then return 0 end
    return n
end

local btn
function M:Update()
    if not ns.Guide then return end
    local n = self.enabled and M.Unspent() or 0
    ns.Guide:SetSection("talents", 87, n > 0 and ns.Tr("|cff66ccffTalents|r : %d point(s) à dépenser"):format(n) or nil)
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("talents", nil, 22, function()
            if PlayerSpellsUtil and PlayerSpellsUtil.ToggleClassTalentOrSpecFrame then pcall(PlayerSpellsUtil.ToggleClassTalentOrSpecFrame)
            elseif ToggleTalentFrame then pcall(ToggleTalentFrame) end
        end, ns.Tr("Ouvrir les talents"), "Interface\\Icons\\Ability_Marksmanship")
    end
    if btn then btn:SetShown(n > 0); ns.Guide:Layout() end
end
for _, ev in ipairs({ "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "FP_READY" }) do
    M:On(ev, function() C_Timer.After(0.5, function() M:Update() end) end)
end
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|TInterface\\Icons\\Ability_Marksmanship:16|t |cff66ccffTalents|r\n2 point(s) à dépenser")
end
