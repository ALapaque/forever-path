local _, ns = ...

-- Bouton sécurisé « Cibler » :
--  clic gauche : /targetexact sur le PNJ ou le monstre de l'étape ;
--  clic droit  : pose un symbole sur ta cible (action sécurisée « raidtarget »).
-- Depuis le patch 12.0 (repris par Forever), SetRaidTarget est protégé : un addon ne peut
-- plus marquer tout seul, seul un clic du joueur sur un bouton sécurisé le peut.
-- Raccourci clavier dans Options > Raccourcis > Questweaver.
local ICONS = { ns.Tr("Étoile"), ns.Tr("Cercle"), ns.Tr("Losange"), ns.Tr("Triangle"), ns.Tr("Lune"), ns.Tr("Carré"), ns.Tr("Croix"), ns.Tr("Crâne") }

local M = ns.RegisterModule({
    id = "targetbutton", category = "targets", default = true,
    name = "Bouton « Cibler »",
    desc = ns.Tr("Clic gauche : cible le PNJ ou le monstre de l'étape, même dans la foule. Clic droit : pose un symbole au-dessus de lui."),
    options = {
        { key = "icon", label = "Symbole (clic droit)", type = "select", values = ICONS, default = 1 },
    },
})

local b = CreateFrame("Button", "QuestweaverTargetButton", UIParent, "SecureActionButtonTemplate")
b:SetSize(32, 32)
b:RegisterForClicks("AnyUp", "AnyDown")
b:SetAttribute("type1", "macro")
b:SetAttribute("type2", "raidtarget")
b:SetAttribute("action2", "set")
b:SetAttribute("unit2", "target")
b:Hide()
ns.ActionBar:Register(b, 10)
b.icon = b:CreateTexture(nil, "ARTWORK")
b.icon:SetAllPoints()
b.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Cibler")
    for _, n in ipairs(self.names or {}) do GameTooltip:AddLine(n, 1, 1, 1) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ns.Tr("Clic gauche : cibler"), 0.7, 0.7, 0.7)
    GameTooltip:AddLine((ns.Tr("Clic droit : poser %s sur la cible")):format(ICONS[M:Opt("icon") or 1]):lower(), 0.7, 0.7, 0.7)
    GameTooltip:AddLine(ns.Tr("Glisser : déplacer"), 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
b:SetScript("OnLeave", function() GameTooltip:Hide() end)

local dirty = false
function M:Update()
    if InCombatLockdown() then dirty = true return end
    dirty = false
    b:SetAttribute("marker2", self:Opt("icon") or 1)
    local t = ns.Engine.Targets()
    local npcs, mobs = {}, {}
    for name, kind in pairs(t.names) do
        if kind == "npc" then npcs[#npcs + 1] = name else mobs[#mobs + 1] = name end
    end
    local names = #npcs > 0 and npcs or mobs
    table.sort(names)
    if #names == 0 then
        b.names = nil
        b:SetAttribute("macrotext1", nil)
        b:Hide()
        ns.ActionBar:Layout()
        return
    end
    local lines = {}
    for i = 1, math.min(#names, 4) do lines[#lines + 1] = "/targetexact " .. names[i] end
    b.names = names
    b:SetAttribute("macrotext1", table.concat(lines, "\n"))
    b:Show()
    ns.ActionBar:Layout()
end

function M:OnEnable() self:Update() end
function M:OnDisable() if not InCombatLockdown() then b:Hide(); ns.ActionBar:Layout() end end
function M:OnOptionChanged() self:Update() end
M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("PLAYER_REGEN_ENABLED", function() if dirty then M:Update() end end)

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(32, 32)
    t:SetPoint("CENTER", -14, 8)
    t:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
    local mk = p:CreateTexture(nil, "ARTWORK")
    mk:SetSize(22, 22)
    mk:SetPoint("LEFT", t, "RIGHT", 6, 0)
    mk:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    local k = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
    k:SetPoint("TOP", 0, -56)
    k:SetText("Gauche : cibler · Droit : marquer")
end
