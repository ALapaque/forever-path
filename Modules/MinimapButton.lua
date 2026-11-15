local _, ns = ...

-- Bouton autour de la minimap (déplaçable) + objet LibDataBroker s'il est présent (Titan, ElvUI,
-- Bazooka…) : étape en cours, clic gauche = guide, clic droit = options.
local M = ns.RegisterModule({
    id = "minimapbutton", category = "look", default = true,
    name = "Bouton de la minimap",
    desc = "Un bouton Questweaver autour de la minimap (glisse-le pour le placer) : clic gauche pour afficher le guide, clic droit pour les options. L'étape en cours s'affiche aussi dans les barres d'infos (Titan, ElvUI…) via LibDataBroker.",
    options = {},
})

local ICON = "Interface\\Icons\\INV_Misc_Map_01"

local function onClick(_, mouse)
    if mouse == "RightButton" then ns.Options:Toggle()
    elseif ns.Guide.enabled then ns.Guide:Toggle() else ns.SetModuleEnabled("guide", true) end
end
local function tooltip(tt)
    tt:AddLine("Questweaver")
    local _, st = ns.Engine.Current()
    if st and ns.Guide then tt:AddLine((ns.Guide.StepLabel(st)), 1, 1, 1, true) end
    tt:AddLine(ns.Tr("Clic gauche : guide  •  Clic droit : options"), 0.6, 0.6, 0.6)
end

-- bouton maison (pas besoin de bibliothèque)
local b = CreateFrame("Button", "QuestweaverMinimapButton", Minimap)
b:SetSize(31, 31)
b:SetFrameStrata("MEDIUM")
b:SetFrameLevel(8)
b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
b:RegisterForDrag("LeftButton")
b.icon = b:CreateTexture(nil, "BACKGROUND")
b.icon:SetSize(20, 20)
b.icon:SetPoint("CENTER")
b.icon:SetTexture(ICON)
b.border = b:CreateTexture(nil, "OVERLAY")
b.border:SetSize(53, 53)
b.border:SetPoint("TOPLEFT")
b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
b:Hide()

local function place()
    local a = math.rad(ns.db and ns.db.minimapAngle or 215)
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end
M.Place = place
b:SetScript("OnClick", onClick)
b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    tooltip(GameTooltip)
    GameTooltip:Show()
end)
b:SetScript("OnLeave", function() GameTooltip:Hide() end)
b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        ns.db.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
        place()
    end)
end)
b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

-- LibDataBroker (facultatif)
local ldb
local function initLDB()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    if not LDB or ldb then return end
    ldb = LDB:NewDataObject("Questweaver", { type = "launcher", icon = ICON, label = "Questweaver", text = "Questweaver",
        OnClick = onClick, OnTooltipShow = tooltip })
end

function M:Update()
    if ldb then
        local g, _, i = ns.Engine.Current()
        ldb.text = g and ("%d/%d"):format(i, #g.steps) or "Questweaver"
    end
end

function M:OnEnable() place(); b:Show(); initLDB(); self:Update() end
function M:OnDisable() b:Hide() end
M:On("FP_STEP_CHANGED", function() M:Update() end)
M.button = b

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK"); t:SetSize(28, 28); t:SetPoint("CENTER"); t:SetTexture(ICON)
    local r = p:CreateTexture(nil, "OVERLAY"); r:SetSize(48, 48); r:SetPoint("TOPLEFT", t, "TOPLEFT", -5, 5)
    r:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
end
