local _, ns = ...

-- Guidage 3D : le moteur du jeu place un « cadre de navigation » (C_Navigation.GetFrame) à l'écran,
-- exactement sur la position 3D du point suivi. On s'y accroche pour dessiner notre marqueur :
-- faisceau lumineux posé sur l'objectif, icône de l'étape, distance ; et, hors champ, une flèche
-- au bord de l'écran qui indique de quel côté tourner.

local M = ns.RegisterModule({
    id = "guide3d", category = "nav", default = true,
    name = "Guidage 3D dans le monde",
    desc = "Un faisceau lumineux posé sur l'objectif, avec l'icône de l'étape et la distance. Hors champ : une flèche au bord de l'écran.",
    options = {
        { key = "beam", label = "Faisceau lumineux", type = "check", default = true },
        { key = "label", label = "Nom de l'étape sous le marqueur", type = "check", default = true },
        { key = "hideBlizzard", label = "Masquer le marqueur de Blizzard", type = "check", default = true },
        { key = "scale", label = "Taille", type = "slider", min = 0.6, max = 1.6, step = 0.05, default = 1 },
    },
})

local ICONS = {
    accept = "Interface\\GossipFrame\\AvailableQuestIcon",
    turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
    complete = "Interface\\Icons\\Ability_DualWield",
}

local f = CreateFrame("Frame", "ForeverPathGuide3D", UIParent)
f:SetSize(64, 64)
f:SetFrameStrata("BACKGROUND")
f:SetFrameLevel(1)
f:Hide()

-- faisceau : colonne de lumière qui monte du point
f.beam = f:CreateTexture(nil, "BACKGROUND")
f.beam:SetTexture(ns.MEDIA .. "beam")
f.beam:SetBlendMode("ADD")
f.beam:SetSize(34, 220)
f.beam:SetPoint("BOTTOM", f, "CENTER", 0, -6)
f.beamGlow = f:CreateTexture(nil, "BACKGROUND")
f.beamGlow:SetTexture(ns.MEDIA .. "glow")
f.beamGlow:SetBlendMode("ADD")
f.beamGlow:SetSize(90, 30)
f.beamGlow:SetPoint("CENTER", f, "CENTER", 0, -4)

-- disque + icône de l'étape
f.disc = f:CreateTexture(nil, "ARTWORK")
f.disc:SetTexture(ns.MEDIA .. "dot")
f.disc:SetSize(30, 30)
f.disc:SetPoint("CENTER", 0, 14)
f.icon = f:CreateTexture(nil, "OVERLAY")
f.icon:SetSize(20, 20)
f.icon:SetPoint("CENTER", f.disc, "CENTER")

f.dist = f:CreateFontString(nil, "OVERLAY", "ForeverPathFontNormal")
f.dist:SetPoint("TOP", f.disc, "BOTTOM", 0, -2)
f.label = f:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
f.label:SetPoint("TOP", f.dist, "BOTTOM", 0, -1)
f.label:SetWidth(220)
f.label:SetWordWrap(false)

-- flèche de bord d'écran (cible hors champ)
f.edge = f:CreateTexture(nil, "OVERLAY")
f.edge:SetTexture(ns.MEDIA .. "arrow")
f.edge:SetSize(38, 38)
f.edge:SetPoint("CENTER")

local navFrame
local function getNav()
    if C_Navigation and C_Navigation.GetFrame then navFrame = C_Navigation.GetFrame() end
    return navFrame
end

local function ourWaypoint()
    return C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.IsSuperTrackingUserWaypoint()
end

local function setBlizzardHidden(hide)
    if SuperTrackedFrame and SuperTrackedFrame.SetAlpha then
        SuperTrackedFrame:SetAlpha(hide and 0 or 1)
    end
end

local t = 0
f:SetScript("OnUpdate", function(self, dt)
    t = t + dt
    local nav = getNav()
    if not (nav and ourWaypoint() and M.enabled) then self:SetAlpha(0) return end
    if C_Navigation.HasValidScreenPosition and not C_Navigation.HasValidScreenPosition() then self:SetAlpha(0) return end
    local state = C_Navigation.GetTargetState and C_Navigation.GetTargetState()
    if state == (Enum.NavigationState and Enum.NavigationState.Disabled or 3) then self:SetAlpha(0) return end

    -- position : centre du cadre de navigation (en coordonnées d'UIParent)
    local cx, cy = nav:GetCenter()
    if not cx or ns.IsSecret(cx) then self:SetAlpha(0) return end
    local ns_ = nav:GetEffectiveScale() / UIParent:GetEffectiveScale()
    cx, cy = cx * ns_, cy * ns_
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
    self:SetAlpha(1)

    local a = ns.Theme().accent
    local clamped = C_Navigation.WasClampedToScreen and C_Navigation.WasClampedToScreen()
    local dist = C_Navigation.GetDistance and C_Navigation.GetDistance()
    if dist and not ns.IsSecret(dist) then
        self.dist:SetText(("%d m"):format(math.floor(dist * 0.9144)))
    else
        self.dist:SetText("")
    end

    if clamped then
        -- hors champ : flèche orientée du centre de l'écran vers le point
        local sx, sy = UIParent:GetWidth() / 2, UIParent:GetHeight() / 2
        local ang = math.atan2(cy - sy, cx - sx) - math.pi / 2
        self.edge:SetRotation(ang)
        self.edge:SetVertexColor(a[1], a[2], a[3])
        self.edge:Show()
        self.beam:Hide(); self.beamGlow:Hide(); self.disc:Hide(); self.icon:Hide(); self.label:Hide()
        return
    end

    self.edge:Hide()
    local occluded = state == (Enum.NavigationState and Enum.NavigationState.Occluded or 1)
    local pulse = 0.75 + math.sin(t * 2.4) * 0.25
    local showBeam = M:Opt("beam")
    self.beam:SetShown(showBeam)
    self.beamGlow:SetShown(showBeam)
    self.beam:SetVertexColor(a[1], a[2], a[3], (occluded and 0.35 or 0.7) * pulse)
    self.beamGlow:SetVertexColor(a[1], a[2], a[3], 0.8 * pulse)
    self.disc:Show()
    self.disc:SetVertexColor(0.05, 0.05, 0.07, 0.85)
    self.icon:Show()
    self.label:SetShown(M:Opt("label"))
    -- à portée : petit rebond de l'icône
    local inRange = state == (Enum.NavigationState and Enum.NavigationState.InRange or 2)
    self.disc:SetPoint("CENTER", 0, 14 + (inRange and math.abs(math.sin(t * 5)) * 8 or 0))
end)

function M:Refresh()
    local step = ns.Engine.NavStep()
    f.icon:SetTexture(step and ICONS[step.type] or (ns.MEDIA .. "pin"))
    if step and not ICONS[step.type] then
        local a = ns.Theme().accent
        f.icon:SetVertexColor(a[1], a[2], a[3])
    else
        f.icon:SetVertexColor(1, 1, 1)
    end
    f.label:SetText(step and ns.Guide and ns.Guide.StepLabel(step) or "")
    f:SetScale(self:Opt("scale") or 1)
    setBlizzardHidden(self.enabled and self:Opt("hideBlizzard"))
end

function M:OnEnable() f:Show(); self:Refresh() end
function M:OnDisable() f:Hide(); setBlizzardHidden(false) end
function M:OnOptionChanged() self:Refresh() end
M:On("FP_STEP_CHANGED", function() M:Refresh() end)
M:On("SUPER_TRACKING_CHANGED", function() M:Refresh() end)
M:On("NAVIGATION_FRAME_CREATED", function() navFrame = nil; M:Refresh() end)
M:On("NAVIGATION_FRAME_DESTROYED", function() navFrame = nil end)
ns.On("FP_THEME_CHANGED", function() if M.enabled then M:Refresh() end end)

function M.preview(p)
    local bg = p:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.16, 0.12, 1)
    local a = ns.ThemeByKey.dark.accent
    local beam = p:CreateTexture(nil, "ARTWORK")
    beam:SetTexture(ns.MEDIA .. "beam")
    beam:SetBlendMode("ADD")
    beam:SetSize(22, 70)
    beam:SetPoint("BOTTOM", p, "BOTTOM", -20, 26)
    beam:SetVertexColor(a[1], a[2], a[3], 0.8)
    local disc = p:CreateTexture(nil, "OVERLAY")
    disc:SetTexture(ns.MEDIA .. "dot")
    disc:SetSize(20, 20)
    disc:SetPoint("CENTER", beam, "BOTTOM", 0, 10)
    disc:SetVertexColor(0.05, 0.05, 0.07, 0.9)
    local ic = p:CreateTexture(nil, "OVERLAY", nil, 2)
    ic:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    ic:SetSize(14, 14)
    ic:SetPoint("CENTER", disc)
    local d = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallGold")
    d:SetPoint("TOP", disc, "BOTTOM", 0, -1)
    d:SetText("42 m")
    local edge = p:CreateTexture(nil, "OVERLAY")
    edge:SetTexture(ns.MEDIA .. "arrow")
    edge:SetSize(22, 22)
    edge:SetPoint("RIGHT", -6, 0)
    edge:SetRotation(-math.pi / 2)
    edge:SetVertexColor(a[1], a[2], a[3])
    local tt = 0
    p:SetScript("OnUpdate", function(_, dt)
        tt = tt + dt
        beam:SetAlpha(0.6 + math.sin(tt * 2.4) * 0.3)
    end)
end
