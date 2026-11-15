local _, ns = ...
local L = ns.L

local M = ns.RegisterModule({
    id = "arrow", category = "nav", default = true,
    name = ns.Tr("Flèche de direction"),
    desc = ns.Tr("Une flèche qui pointe vers l'étape, avec la distance : posée au sol en 3D (ou plate, au choix), verte quand tu vas dans la bonne direction."),
    options = {
        { key = "style", label = ns.Tr("Style"), type = "select", values = { ns.Tr("3D (posée au sol)"), ns.Tr("Plate") }, default = 1, width = 120 },
        { key = "size", label = ns.Tr("Taille"), type = "slider", min = 32, max = 96, step = 4, default = 56 },
        { key = "hideClose", label = ns.Tr("Masquer à l'arrivée"), type = "check", default = true },
    },
})

local f = CreateFrame("Frame", "QuestweaverArrow", UIParent)
f:SetSize(70, 90)
f:SetFrameStrata("MEDIUM")
f:Hide()
ns.MakeMovable(f, "arrow", { "TOP", "TOP", 0, -180 })

f.tex = f:CreateTexture(nil, "ARTWORK")
f.tex:SetPoint("TOP", 0, 0)
f.tex:SetTexture(ns.MEDIA .. "arrow")

---------------------------------------------------------------------------
-- Flèche 3D : la flèche est posée sur un sol vu en perspective (caméra derrière le personnage,
-- inclinée vers le bas). Chaque coin de la texture est projeté à l'écran (SetVertexOffset) :
-- quand l'étape est devant, la flèche s'enfonce dans l'écran ; sur le côté, elle s'allonge
-- vers la gauche ou la droite. Quelques couches décalées vers le bas lui donnent une épaisseur,
-- et une ombre floue la pose au sol.
---------------------------------------------------------------------------
local CAM_DIST, CAM_PITCH = 2.6, math.rad(38)
local LAYERS = 5                               -- couches d'épaisseur (dessous -> dessus)
local holder3d = CreateFrame("Frame", nil, f)
holder3d:SetPoint("TOP", 0, 0)
holder3d:Hide()
local shadow = holder3d:CreateTexture(nil, "BACKGROUND")
shadow:SetTexture(ns.MEDIA .. "arrow")
shadow:SetPoint("CENTER", 0, -4)
local layers = {}
for i = 1, LAYERS do
    local t = holder3d:CreateTexture(nil, "ARTWORK", nil, i - 1)
    t:SetTexture(ns.MEDIA .. "arrow")
    t:SetPoint("CENTER", 0, (i - LAYERS) * 2)     -- dessous plus bas : l'épaisseur
    layers[i] = t
end
local CORNERS = { { -1, 1 }, { -1, -1 }, { 1, 1 }, { 1, -1 } }   -- UL, LL, UR, LR (indices de SetVertexOffset)

local function project(u, v, r, half)
    local c, sn = math.cos(r), math.sin(r)
    local x = u * c - v * sn
    local z = u * sn + v * c                      -- z > 0 : vers l'avant (au loin)
    local k = CAM_DIST / (CAM_DIST + z * math.cos(CAM_PITCH))
    return x * k * half, z * math.sin(CAM_PITCH) * k * half
end

local function warp(t, r, half, grow)
    for i, cn in ipairs(CORNERS) do
        local px, py = project(cn[1] * grow, cn[2] * grow, r, half)
        t:SetVertexOffset(i, px - cn[1] * half, py - cn[2] * half)
    end
end

local supports3d = f.tex.SetVertexOffset ~= nil
local shown = nil                                  -- angle affiché, lissé

local function draw3d(rel, r, g, b, dt)
    -- lissage de la rotation (en passant par le plus court chemin)
    if not shown then shown = rel end
    local diff = (rel - shown + math.pi) % (2 * math.pi) - math.pi
    shown = shown + diff * math.min(1, (dt or 0.03) * 10)
    local size = M:Opt("size") or 56
    local half = size * 0.75
    holder3d:SetSize(size * 1.6, size * 1.2)
    shadow:SetSize(half * 2, half * 2)
    warp(shadow, shown, half, 1.12)
    shadow:SetVertexColor(0, 0, 0, 0.45)
    for i, t in ipairs(layers) do
        t:SetSize(half * 2, half * 2)
        warp(t, shown, half, 1)
        local top = i == LAYERS
        local shade = top and 1 or (0.35 + 0.1 * i)
        t:SetVertexColor(r * shade, g * shade, b * shade, 1)
    end
end

f.dist = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
f.dist:SetPoint("TOP", f.tex, "BOTTOM", 0, -2)
f.label = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
f.label:SetPoint("TOP", f.dist, "BOTTOM", 0, -1)
f.label:SetWidth(160)
f.label:SetWordWrap(false)

local function color(rel)
    -- 0 = droit devant ; vert -> jaune -> rouge selon l'écart
    local off = rel > math.pi and (2 * math.pi - rel) or rel
    local t = off / math.pi
    if t < 0.5 then return t * 2, 1, 0.2 end
    return 1, 1 - (t - 0.5) * 2, 0.2
end

local function use3d() return supports3d and (M:Opt("style") or 1) == 1 end

local acc = 0
f:SetScript("OnUpdate", function(self, dt)
    acc = acc + dt
    if acc < 0.03 then return end
    local elapsed = acc
    acc = 0
    local step = ns.Engine.NavStep()
    if not step or not step.x then self.tex:Hide(); holder3d:Hide(); self.dist:SetText(""); self.label:SetText(""); return end
    local d, bearing = ns.Geo.Vector(step)
    if not d then
        self.tex:Hide(); holder3d:Hide(); self.dist:SetText(""); self.label:SetText("")
        return
    end
    local radius = step.radius or 15
    if d <= radius and M:Opt("hideClose") then
        if use3d() then
            self.tex:Hide(); holder3d:Show()
            draw3d(0, 0.3, 1, 0.3, elapsed)
        else
            holder3d:Hide(); self.tex:Show()
            self.tex:SetRotation(0)
            self.tex:SetVertexColor(0.3, 1, 0.3)
        end
        self.dist:SetText(L.ARRIVED or ns.Tr("Arrivé"))
        return
    end
    local rel = ns.Geo.RelativeAngle(bearing)
    if not rel then self.tex:Hide(); holder3d:Hide(); return end
    if use3d() then
        self.tex:Hide(); holder3d:Show()
        local r, g, b = color(rel)
        draw3d(rel, r, g, b, elapsed)
    else
        holder3d:Hide(); self.tex:Show()
        self.tex:SetRotation(rel)
        self.tex:SetVertexColor(color(rel))
    end
    self.dist:SetText(ns.FormatDistance(d))
    local label = ns.Guide and ns.Guide.StepLabel(step) or ""
    self.label:SetText(label)
end)

function M:Apply()
    local s = self:Opt("size") or 56
    f.tex:SetSize(s, s)
    f.dist:ClearAllPoints()
    if use3d() then
        f.dist:SetPoint("TOP", f.tex, "TOP", 0, -s * 1.15)
    else
        f.dist:SetPoint("TOP", f.tex, "BOTTOM", 0, -2)
    end
end
function M:OnEnable() self:Apply(); f:Show() end
function M:OnDisable() f:Hide() end
function M:OnOptionChanged() self:Apply() end

function M.preview(p)
    local half = 26
    local sh = p:CreateTexture(nil, "BACKGROUND")
    sh:SetTexture(ns.MEDIA .. "arrow"); sh:SetSize(half * 2, half * 2); sh:SetPoint("CENTER", 0, 4)
    local ls = {}
    for i = 1, LAYERS do
        local t = p:CreateTexture(nil, "ARTWORK", nil, i - 1)
        t:SetTexture(ns.MEDIA .. "arrow"); t:SetSize(half * 2, half * 2)
        t:SetPoint("CENTER", 0, 8 + (i - LAYERS) * 1.2)
        ls[i] = t
    end
    local d = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
    d:SetPoint("BOTTOM", 0, 6)
    d:SetText("86 m")
    -- la flèche tourne doucement sur le sol
    local a = 0
    p:SetScript("OnUpdate", function(_, dt)
        a = a + dt
        local rr = math.sin(a * 1.2) * 1.3
        local r, g, b = color(rr < 0 and 2 * math.pi + rr or rr)
        if sh.SetVertexOffset then
            warp(sh, rr, half, 1.12)
            for _, t in ipairs(ls) do warp(t, rr, half, 1) end
        end
        sh:SetVertexColor(0, 0, 0, 0.45)
        for i, t in ipairs(ls) do
            local k = i == LAYERS and 1 or (0.35 + 0.1 * i)
            t:SetVertexColor(r * k, g * k, b * k)
        end
    end)
end
