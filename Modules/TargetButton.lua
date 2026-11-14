local _, ns = ...

-- Bouton sécurisé « Cibler » : /targetexact sur le PNJ ou le monstre de l'étape.
-- Raccourci clavier dans Options > Raccourcis > ForeverPath.
local M = ns.RegisterModule({
    id = "targetbutton", category = "targets", default = true,
    name = "Bouton « Cibler »",
    desc = "Un clic (ou une touche) cible le PNJ ou le monstre de l'étape, même dans la foule.",
    options = {},
})

local b = CreateFrame("Button", "ForeverPathTargetButton", UIParent, "SecureActionButtonTemplate")
b:SetSize(32, 32)
b:RegisterForClicks("AnyUp", "AnyDown")
b:SetAttribute("type", "macro")
b:Hide()
ns.MakeMovable(b, "targetbutton", { "CENTER", "CENTER", 40, -160 })
b.icon = b:CreateTexture(nil, "ARTWORK")
b.icon:SetAllPoints()
b.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Cibler")
    for _, n in ipairs(self.names or {}) do GameTooltip:AddLine(n, 1, 1, 1) end
    GameTooltip:Show()
end)
b:SetScript("OnLeave", function() GameTooltip:Hide() end)

local dirty = false
function M:Update()
    if InCombatLockdown() then dirty = true return end
    dirty = false
    local t = ns.Engine.Targets()
    local npcs, mobs = {}, {}
    for name, kind in pairs(t.names) do
        if kind == "npc" then npcs[#npcs + 1] = name else mobs[#mobs + 1] = name end
    end
    local names = #npcs > 0 and npcs or mobs
    table.sort(names)
    if #names == 0 then
        b.names = nil
        b:SetAttribute("macrotext", nil)
        b:Hide()
        return
    end
    local lines = {}
    for i = 1, math.min(#names, 4) do lines[#lines + 1] = "/targetexact " .. names[i] end
    b.names = names
    b:SetAttribute("macrotext", table.concat(lines, "\n"))
    b:Show()
end

function M:OnEnable() self:Update() end
function M:OnDisable() if not InCombatLockdown() then b:Hide() end end
M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("PLAYER_REGEN_ENABLED", function() if dirty then M:Update() end end)

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(32, 32)
    t:SetPoint("CENTER", 0, 8)
    t:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
    local k = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    k:SetPoint("TOP", t, "BOTTOM", 0, -3)
    k:SetText("Cibler : Adjoint Willem")
end
