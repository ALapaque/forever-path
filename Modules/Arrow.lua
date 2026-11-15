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
-- Flèche 3D : la flèche est posée sur un sol vu en biais (comme la caméra derrière le
-- personnage). On ne déforme pas la texture coin par coin (le jeu la coupe en deux triangles,
-- ce qui la tordait) : on tourne puis on aplatit ses coordonnées de texture, une transformation
-- exacte. Droit devant, la flèche « s'enfonce » (écrasée) ; sur le côté, elle s'allonge.
-- Trois couches décalées vers le bas lui donnent une épaisseur, une ombre la pose au sol.
---------------------------------------------------------------------------
local FLAT = 0.55                                  -- écrasement vertical du sol vu en biais
local LAYERS = 3
local holder3d = CreateFrame("Frame", nil, f)
holder3d:SetPoint("TOP", 0, 0)
holder3d:Hide()
local shadow = holder3d:CreateTexture(nil, "BACKGROUND")
shadow:SetTexture(ns.MEDIA .. "arrow")
local layers = {}
for i = 1, LAYERS do
    local t = holder3d:CreateTexture(nil, "ARTWORK", nil, i - 1)
    t:SetTexture(ns.MEDIA .. "arrow")
    layers[i] = t
end

-- Coordonnées de texture pour une flèche tournée de r (sens trigo) puis aplatie au sol.
-- Coins de l'écran (y vers le haut) -> point du sol -> point de la texture.
local SCREEN = { { -1, 1 }, { -1, -1 }, { 1, 1 }, { 1, -1 } }    -- UL, LL, UR, LR
local function groundCoords(t, r)
    local c, sn = math.cos(r), math.sin(r)
    local out = {}
    for _, p in ipairs(SCREEN) do
        local gx, gy = p[1], p[2] / FLAT
        local u = gx * c + gy * sn
        local v = -gx * sn + gy * c
        out[#out + 1] = 0.5 + u * 0.5
        out[#out + 1] = 0.5 - v * 0.5
    end
    t:SetTexCoord(unpack(out))
end

local supports3d = true
local shown = nil                                  -- angle affiché, lissé

local function layout3d(size)
    holder3d:SetSize(size, size * (FLAT + 0.25))
    shadow:SetSize(size * 1.08, size * 1.08)
    shadow:ClearAllPoints(); shadow:SetPoint("CENTER", 0, -size * 0.07)
    for i, t in ipairs(layers) do
        t:SetSize(size, size)
        t:ClearAllPoints(); t:SetPoint("CENTER", 0, (i - LAYERS) * math.max(1, size / 40))
    end
end

local function draw3d(rel, r, g, b, dt)
    -- lissage de la rotation (par le plus court chemin)
    if not shown then shown = rel end
    local diff = (rel - shown + math.pi) % (2 * math.pi) - math.pi
    shown = shown + diff * math.min(1, (dt or 0.03) * 10)
    groundCoords(shadow, shown)
    shadow:SetVertexColor(0, 0, 0, 0.4)
    for i, t in ipairs(layers) do
        groundCoords(t, shown)
        local k = i == LAYERS and 1 or (0.35 + 0.15 * i)
        t:SetVertexColor(r * k, g * k, b * k, 1)
    end
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
    layout3d(s * 1.25)
    f.dist:ClearAllPoints()
    if use3d() then
        f.dist:SetPoint("TOP", holder3d, "BOTTOM", 0, -2)
    else
        f.dist:SetPoint("TOP", f.tex, "BOTTOM", 0, -2)
    end
end
function M:OnEnable() self:Apply(); f:Show() end
function M:OnDisable() f:Hide() end
function M:OnOptionChanged() self:Apply() end

function M.preview(p)
    local size = 64
    local sh = p:CreateTexture(nil, "BACKGROUND")
    sh:SetTexture(ns.MEDIA .. "arrow"); sh:SetSize(size * 1.08, size * 1.08); sh:SetPoint("CENTER", 0, 6)
    local ls = {}
    for i = 1, LAYERS do
        local t = p:CreateTexture(nil, "ARTWORK", nil, i - 1)
        t:SetTexture(ns.MEDIA .. "arrow"); t:SetSize(size, size)
        t:SetPoint("CENTER", 0, 10 + (i - LAYERS) * 1.5)
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
        groundCoords(sh, rr)
        sh:SetVertexColor(0, 0, 0, 0.4)
        for i, t in ipairs(ls) do
            groundCoords(t, rr)
            local k = i == LAYERS and 1 or (0.35 + 0.15 * i)
            t:SetVertexColor(r * k, g * k, b * k)
        end
    end)
end
