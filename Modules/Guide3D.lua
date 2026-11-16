local _, ns = ...

-- Guidage 3D : le moteur du jeu place un « cadre de navigation » (C_Navigation.GetFrame) à l'écran,
-- exactement sur la position 3D du point suivi. On s'y accroche pour dessiner notre marqueur :
-- faisceau lumineux posé sur l'objectif, icône de l'étape, distance ; et, hors champ, une flèche
-- au bord de l'écran qui indique de quel côté tourner.

local M = ns.RegisterModule({
    id = "guide3d", category = "nav", default = true,
    name = ns.Tr("Guidage 3D dans le monde"),
    desc = ns.Tr("Un faisceau lumineux posé sur l'objectif, avec l'icône de l'étape et la distance. Hors champ : une flèche au bord de l'écran."),
    options = {
        { key = "beam", label = "Faisceau lumineux", type = "check", default = true },
        { key = "label", label = ns.Tr("Nom de l'étape sous le marqueur"), type = "check", default = true },
        { key = "trail", label = ns.Tr("Points au sol jusqu'à l'objectif"), type = "check", default = true },
        { key = "hideBlizzard", label = ns.Tr("Masquer le marqueur de Blizzard"), type = "check", default = true },
        { key = "snap", label = ns.Tr("De près, se placer sur le PNJ (barre de nom)"), type = "check", default = true },
        { key = "yieldDaylight", label = ns.Tr("Laisser la place au marqueur de Daylight UI"), type = "check", default = true },
        { key = "scale", label = ns.Tr("Taille"), type = "slider", min = 0.6, max = 1.6, step = 0.05, default = 1 },
    },
})

local ICONS = {
    accept = "Interface\\GossipFrame\\AvailableQuestIcon",
    turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
    complete = "Interface\\Icons\\Ability_DualWield",
}

local f = CreateFrame("Frame", "QuestweaverGuide3D", UIParent)
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

f.dist = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
f.dist:SetPoint("TOP", f.disc, "BOTTOM", 0, -2)
f.label = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
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

-- Le marqueur de Blizzard (SuperTrackedFrame) recalcule sa propre transparence à chaque image :
-- un SetAlpha(0) unique ne tenait pas, et sa distance (« 65 mètres ») venait se superposer à la nôtre.
-- On masque donc ses éléments (icône, distance, flèche), qu'il ne retouche pas, et on le revérifie.
-- Performances : la liste de ses éléments est construite une fois (et refaite si le jeu recrée le
-- cadre), plus à chaque image : ça créait plusieurs tables par image, que le ramasse-miettes de Lua
-- devait ensuite nettoyer — coûteux quand beaucoup d'addons sont chargés.
local blizzHidden = false
local partsCache, partsOf
local function blizzParts()
    local s = SuperTrackedFrame
    if type(s) ~= "table" then return {} end
    if partsCache and partsOf == s then return partsCache end
    local parts = { s.Icon, s.DistanceText, s.Arrow, s.Glow }
    if s.GetRegions then for _, r in ipairs({ s:GetRegions() }) do parts[#parts + 1] = r end end
    if s.GetChildren then for _, c in ipairs({ s:GetChildren() }) do parts[#parts + 1] = c end end
    partsCache, partsOf = parts, s
    return parts
end
local function setBlizzardHidden(hide)
    blizzHidden = hide and true or false
    partsCache = nil
    for _, part in ipairs(blizzParts()) do
        if type(part) == "table" and part.SetAlpha then part:SetAlpha(hide and 0 or 1) end
    end
end
local function keepBlizzardHidden()
    if not blizzHidden then return end
    for _, part in ipairs(blizzParts()) do
        if type(part) == "table" and part.GetAlpha then
            local a = part:GetAlpha()
            if type(a) == "number" and not ns.IsSecret(a) and a > 0 then part:SetAlpha(0) end
        end
    end
end

---------------------------------------------------------------------------
-- Points au sol : une traînée de points entre le personnage et l'objectif. Le jeu ne donne pas la
-- position du personnage à l'écran ; la caméra le garde au centre, un peu sous le milieu. Les points
-- se resserrent et rapetissent en s'éloignant (effet de perspective) et avancent doucement vers
-- l'objectif.
---------------------------------------------------------------------------
local trail = CreateFrame("Frame", nil, UIParent)
trail:SetAllPoints(UIParent)
trail:SetFrameStrata("BACKGROUND")
trail:SetFrameLevel(0)
trail:Hide()
local trailDots = {}
local FEET_Y = 0.40          -- hauteur des pieds du personnage, en fraction de l'écran (depuis le bas)

local function trailDot(i)
    local d = trailDots[i]
    if not d then
        d = trail:CreateTexture(nil, "BACKGROUND")
        d:SetTexture(ns.MEDIA .. "dot")
        d:SetBlendMode("ADD")
        trailDots[i] = d
    end
    return d
end

local function hideTrail(from)
    if (from or 1) == 1 then M.trailDots = 0 end
    for i = from or 1, #trailDots do trailDots[i]:Hide() end
    if (from or 1) == 1 then trail:Hide() end
end

local function drawTrail(tx, ty, dist, accent, phase)
    if not M:Opt("trail") or (dist and not ns.IsSecret(dist) and dist < 10) then hideTrail() return end
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    local px, py = w / 2, h * FEET_Y
    ty = ty - 8                                     -- pied du faisceau, sous l'icône
    local dx, dy = tx - px, ty - py
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 70 then hideTrail() return end
    -- léger arc : le chemin part droit devant le personnage puis tourne vers l'objectif
    local cx, cy = px + dx * 0.2, py + dy * 0.65
    local n = math.max(6, math.min(24, math.floor(len / 40)))
    trail:Show()
    local used = 0
    for i = 1, n do
        local u = (i - 1 + phase) / n
        -- répartition en perspective : espacés près du personnage, serrés au loin
        local p = 1 - (1 - math.max(u, 0)) ^ 1.7
        if u > 0 and p > 0.08 and p < 0.96 then
            used = used + 1
            local d = trailDot(used)
            local q = 1 - p
            local x = q * q * px + 2 * q * p * cx + p * p * tx
            local y = q * q * py + 2 * q * p * cy + p * p * ty
            local size = 14 - 9 * p
            d:SetSize(size, size * 0.7)            -- un peu écrasés : posés au sol
            d:ClearAllPoints()
            d:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            local fade = math.min(1, (p - 0.08) / 0.12, (0.96 - p) / 0.1)
            d:SetVertexColor(accent[1], accent[2], accent[3], (0.35 + 0.45 * q) * fade)
            d:Show()
        end
    end
    hideTrail(used + 1)
    M.trailDots = used
end

-- Daylight UI (module Quêtes) a son propre marqueur : on évite d'en afficher deux l'un sur l'autre.
local function daylightMarkerShown()
    local d = _G.DaylightUIQuestMarker
    if type(d) ~= "table" or not d.IsVisible then return false end
    local ok, vis = pcall(d.IsVisible, d)
    if not ok or not vis or ns.IsSecret(vis) then return false end
    local ok2, a = pcall(d.GetEffectiveAlpha or d.GetAlpha, d)
    return ok2 and type(a) == "number" and not ns.IsSecret(a) and a > 0.05
end

local function off(self)
    if self.visible ~= false then self:SetAlpha(0); hideTrail(); self.visible = false end
end

-- Ce qui suit l'objectif (position du marqueur) est fait à chaque image ; le reste est limité :
-- points au sol 30 fois/s (10 en économie, ou coupés), vérifications lentes 4 fois/s.
local t, slowAcc, trailAcc = 0, 1, 1
local daylightOn, lastDist, lastX, lastY, eco = false, nil, nil, nil, false
ns.On("FP_PERF_CHANGED", function(v) eco = v and true or false; hideTrail() end)
f:SetScript("OnUpdate", function(self, dt)
    t = t + dt
    slowAcc, trailAcc = slowAcc + dt, trailAcc + dt
    local nav = getNav()
    if not (nav and M.enabled and ourWaypoint()) then off(self) return end
    if slowAcc >= 0.25 then
        slowAcc = 0
        daylightOn = M:Opt("yieldDaylight") and daylightMarkerShown()
        eco = ns.Eco and ns.Eco() or false
        keepBlizzardHidden()
        M.snapPlate = nil
        local np = ns.Modules.nameplates
        local d = C_Navigation.GetDistance and C_Navigation.GetDistance()
        if np and np.NpcPlate and M.navNpc and d and not ns.IsSecret(d) and d < 40 then M.snapPlate = np.NpcPlate() end
    end
    if daylightOn then off(self) return end
    if C_Navigation.HasValidScreenPosition and not C_Navigation.HasValidScreenPosition() then off(self) return end
    local state = C_Navigation.GetTargetState and C_Navigation.GetTargetState()
    if state == (Enum.NavigationState and Enum.NavigationState.Disabled or 3) then off(self) return end

    -- position : centre du cadre de navigation (en coordonnées d'UIParent)
    local cx, cy = nav:GetCenter()
    if not cx or ns.IsSecret(cx) then off(self) return end
    local ns_ = nav:GetEffectiveScale() / UIParent:GetEffectiveScale()
    cx, cy = cx * ns_, cy * ns_
    -- de près, le PNJ de l'étape a sa barre de nom à l'écran : on s'accroche à lui plutôt qu'au point
    -- de la base de données (souvent décalé de quelques mètres dans Forever)
    local snapped = false
    if M:Opt("snap") and M.snapPlate then
        local ok, px, py = pcall(M.snapPlate.GetCenter, M.snapPlate)
        local ok2, sc = pcall(M.snapPlate.GetEffectiveScale, M.snapPlate)
        if ok and ok2 and px and not ns.IsSecret(px) and not ns.IsSecret(sc) then
            local k = sc / UIParent:GetEffectiveScale()
            cx, cy, snapped = px * k, py * k + 20, true      -- juste au-dessus de la barre de nom
        end
    end
    if not lastX or math.abs(cx - lastX) > 0.5 or math.abs(cy - lastY) > 0.5 or self.visible == false then
        lastX, lastY = cx, cy
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
    end
    if self.visible == false then self:SetAlpha(1) end
    self.visible = true

    local a = ns.Theme().accent
    local clamped = C_Navigation.WasClampedToScreen and C_Navigation.WasClampedToScreen()
    local dist = C_Navigation.GetDistance and C_Navigation.GetDistance()
    local shownDist = dist and not ns.IsSecret(dist) and blizzHidden and math.floor(dist + 0.5) or nil
    if shownDist ~= lastDist then
        lastDist = shownDist
        self.dist:SetText(shownDist and ns.FormatDistance(shownDist) or "")
    end

    if clamped then
        -- hors champ : flèche orientée du centre de l'écran vers le point
        local sx, sy = UIParent:GetWidth() / 2, UIParent:GetHeight() / 2
        local ang = math.atan2(cy - sy, cx - sx) - math.pi / 2
        self.edge:SetRotation(ang)
        if not self.edge:IsShown() then
            self.edge:SetVertexColor(a[1], a[2], a[3])
            self.edge:Show()
            self.beam:Hide(); self.beamGlow:Hide(); self.disc:Hide(); self.icon:Hide(); self.label:Hide()
            hideTrail()
        end
        return
    end

    if self.edge:IsShown() or not self.disc:IsShown() then
        self.edge:Hide()
        local showBeam = M:Opt("beam") and not M.snapped
        self.beam:SetShown(showBeam)
        self.beamGlow:SetShown(showBeam)
        self.disc:Show()
        self.disc:SetVertexColor(0.05, 0.05, 0.07, 0.85)
        self.icon:Show()
        self.label:SetShown(M:Opt("label"))
    end
    if snapped ~= M.snapped then
        M.snapped = snapped
        local showBeam = not snapped and M:Opt("beam")
        self.beam:SetShown(showBeam); self.beamGlow:SetShown(showBeam)
    end
    -- points au sol : coupés en économie ou accroché au PNJ, sinon 30 fois/s
    if eco or snapped then
        if M.trailDots and M.trailDots > 0 then hideTrail() end
    elseif trailAcc >= 1 / 30 then
        trailAcc = 0
        drawTrail(cx, cy, dist, a, (t * 0.6) % 1)
    end
    local occluded = state == (Enum.NavigationState and Enum.NavigationState.Occluded or 1)
    local pulse = eco and 1 or (0.75 + math.sin(t * 2.4) * 0.25)
    if self.beam:IsShown() then
        self.beam:SetVertexColor(a[1], a[2], a[3], (occluded and 0.35 or 0.7) * pulse)
        self.beamGlow:SetVertexColor(a[1], a[2], a[3], 0.8 * pulse)
    end
    -- à portée : petit rebond de l'icône (pas en économie)
    local inRange = not eco and state == (Enum.NavigationState and Enum.NavigationState.InRange or 2)
    if inRange or self.bounced then
        self.bounced = inRange
        self.disc:SetPoint("CENTER", 0, 14 + (inRange and math.abs(math.sin(t * 5)) * 8 or 0))
    end
end)

function M:Refresh()
    local step = ns.Engine.NavStep()
    M.navNpc = step and (step.npcID or step.npc) and (step.type == "accept" or step.type == "turnin" or step.detour) or nil
    ns.SetStepIcon(f.icon, step, step and ICONS[step.type] or (ns.MEDIA .. "pin"))
    if step and not ICONS[step.type] then
        local a = ns.Theme().accent
        f.icon:SetVertexColor(a[1], a[2], a[3])
    else
        f.icon:SetVertexColor(1, 1, 1)
    end
    f.label:SetText(step and ns.Guide and ns.Guide.StepLabel(step) or "")
    f:SetScale(self:Opt("scale") or 1)
    setBlizzardHidden(self.enabled and self:Opt("hideBlizzard"))
    f.label:ClearAllPoints()
    if blizzHidden then
        f.label:SetPoint("TOP", f.dist, "BOTTOM", 0, -1)
    else
        f.label:SetPoint("TOP", f.disc, "BOTTOM", 0, -22)  -- sous la distance affichée par le jeu
    end
    -- options (faisceau, nom) et textes : réappliqués à la prochaine image
    f.disc:Hide(); lastDist = -1
end

function M:OnEnable() f:Show(); self:Refresh() end
function M:OnDisable() f:Hide(); hideTrail(); setBlizzardHidden(false) end
function M:OnOptionChanged() self:Refresh() end
M:On("FP_STEP_CHANGED", function() M:Refresh() end)
M:On("SUPER_TRACKING_CHANGED", function() M:Refresh() end)
M:On("QUEST_LOG_UPDATE", function() if M.enabled then M:Refresh() end end)
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
    local d = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
    d:SetPoint("TOP", disc, "BOTTOM", 0, -1)
    d:SetText("42 m")
    -- points au sol, du bas de l'aperçu jusqu'au faisceau
    for i = 1, 6 do
        local k = i / 7
        local dot = p:CreateTexture(nil, "ARTWORK")
        dot:SetTexture(ns.MEDIA .. "dot")
        dot:SetBlendMode("ADD")
        local sz = 9 - 5 * k
        dot:SetSize(sz, sz * 0.7)
        dot:SetPoint("CENTER", p, "BOTTOM", 30 - 50 * k, 4 + 22 * k)
        dot:SetVertexColor(a[1], a[2], a[3], 0.8 - 0.4 * k)
    end
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
