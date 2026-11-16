local _, ns = ...
local L = ns.L

local M = ns.RegisterModule({
    id = "arrow", category = "nav", default = true,
    name = ns.Tr("Flèche de direction"),
    desc = ns.Tr("Une flèche qui pointe vers l'étape : pointe à deux facettes avec l'étape, la distance et le temps restant, flèche 3D posée au sol ou flèche plate. Elle change de couleur selon que tu vas dans la bonne direction."),
    options = {
        { key = "style", label = ns.Tr("Style"), type = "select", values = { ns.Tr("3D (posée au sol)"), ns.Tr("Plate"), ns.Tr("Pointe (étapes dessous)") }, default = 3, width = 150 },
        { key = "caps", label = ns.Tr("Texte en majuscules (style Pointe)"), type = "check", default = true },
        { key = "next", label = ns.Tr("Étape suivante sous la flèche (style Pointe)"), type = "check", default = true },
        { key = "font", label = ns.Tr("Police du texte"), type = "select", store = "value", width = 160,
          values = function()
              local list = { ns.GENERAL_FONT }
              for _, n in ipairs(ns.FontList()) do list[#list + 1] = n end
              return list
          end },
        { key = "textSize", label = ns.Tr("Taille du texte"), type = "slider", min = 10, max = 24, step = 1, default = 14 },
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
local out = {}           -- réutilisée (pas de nouvelle table à chaque image)
local function groundCoords(t, r, flat)
    local c, sn = math.cos(r), math.sin(r)
    wipe(out)
    for _, p in ipairs(SCREEN) do
        local gx, gy = p[1], p[2] / (flat or FLAT)
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

---------------------------------------------------------------------------
-- Style « Pointe » : une pointe de flèche à deux facettes (une éclairée, une dans l'ombre),
-- à peine inclinée vers le sol, avec dessous l'étape en cours, la suivante, puis la distance
-- et le temps de trajet estimé.
---------------------------------------------------------------------------
local POINTE_FLAT = 0.78
local holderP = CreateFrame("Frame", nil, f)
holderP:SetPoint("TOP", 0, 0)
holderP:Hide()
local pShadow = holderP:CreateTexture(nil, "BACKGROUND")
pShadow:SetTexture(ns.MEDIA .. "pointe")
local pTex = holderP:CreateTexture(nil, "ARTWORK")
pTex:SetTexture(ns.MEDIA .. "pointe")
f.next = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontArrow")
f.next:SetWidth(300)
f.next:SetWordWrap(false)

-- couleur de la pointe : vert d'eau dans la bonne direction, ambre de côté, rouge à l'opposé
local function pointeColor(rel)
    local off = rel > math.pi and (2 * math.pi - rel) or rel
    local t = off / math.pi
    if t < 0.5 then
        local k = t * 2
        return 0.12 + 0.88 * k, 0.80 - 0.05 * k, 0.55 - 0.40 * k
    end
    local k = (t - 0.5) * 2
    return 1 - 0.05 * k, 0.75 - 0.50 * k, 0.15 + 0.05 * k
end

local pShown
local function drawPointe(rel, dt)
    if not pShown then pShown = rel end
    local diff = (rel - pShown + math.pi) % (2 * math.pi) - math.pi
    pShown = pShown + diff * math.min(1, (dt or 0.03) * 10)
    groundCoords(pShadow, pShown, POINTE_FLAT)
    groundCoords(pTex, pShown, POINTE_FLAT)
    pShadow:SetVertexColor(0, 0, 0, 0.45)
    local r, g, b = pointeColor(pShown % (2 * math.pi))
    pTex:SetVertexColor(r, g, b, 1)
end

local function plain(s)
    return (s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end
local function eta(d)
    local speed = ns.Nav and ns.Nav.RunSpeed and ns.Nav.RunSpeed()
    if not (speed and speed > 0) then return "" end
    local secs = math.floor(d / speed + 0.5)
    if secs >= 3600 then return ("%d:%02d:%02d"):format(secs / 3600, (secs % 3600) / 60, secs % 60) end
    return ("%d:%02d"):format(secs / 60, secs % 60)
end

local function style() return M:Opt("style") or 3 end
local function use3d() return supports3d and style() == 1 end
local function usePointe() return style() == 3 end

local function showOnly(which)
    f.tex:SetShown(which == "flat")
    holder3d:SetShown(which == "3d")
    holderP:SetShown(which == "pointe")
end

-- Textes de l'étape (libellé, étape suivante) : refaits quand l'étape ou le journal change, plus
-- 33 fois par seconde (ça recréait des chaînes de caractères et parcourait le guide à chaque fois).
local texts = { dirty = true }
local function markTexts() texts.dirty = true end
for _, ev in ipairs({ "FP_STEP_CHANGED", "QUEST_LOG_UPDATE", "FP_THEME_CHANGED", "FP_OPTION_CHANGED", "SKILL_LINES_CHANGED",
                       "QUEST_DATA_LOAD_RESULT", "FP_DETOUR" }) do
    ns.On(ev, markTexts)
end
local function refreshTexts(self, step)
    if not texts.dirty and texts.step == step then return end
    texts.dirty, texts.step = false, step
    local label = ns.Guide and ns.Guide.StepLabel(step) or ""
    if usePointe() then
        local caps = M:Opt("caps")
        local function fmt(x) x = plain(x); return caps and ns.Upper(x) or x end
        self.label:SetText(fmt(label))
        local nxt = M:Opt("next") and ns.Engine.Upcoming and ns.Engine.Upcoming(1)[1]
        self.next:SetText(nxt and fmt(ns.Guide.StepLabel(nxt)) or "")
    else
        self.label:SetText(label)
        self.next:SetText("")
    end
end

local acc, lastDistText = 0, nil
f:SetScript("OnUpdate", function(self, dt)
    acc = acc + dt
    -- 33 images/s, 15 en économie
    if acc < ((ns.Eco and ns.Eco()) and 0.066 or 0.03) then return end
    local elapsed = acc
    acc = 0
    local step = ns.Engine.NavStep()
    if not step or not step.x then
        if texts.step then showOnly(); self.dist:SetText(""); self.label:SetText(""); self.next:SetText(""); texts.step = nil; lastDistText = nil end
        return
    end
    local d, bearing = ns.Geo.Vector(step)
    if not d then
        showOnly(); self.dist:SetText(""); self.label:SetText(""); self.next:SetText("")
        texts.step, lastDistText = nil, nil
        return
    end
    local pointe = usePointe()
    refreshTexts(self, step)
    local radius = step.radius or 15
    if d <= radius and M:Opt("hideClose") then
        if pointe then
            showOnly("pointe")
            drawPointe(0, elapsed)
        elseif use3d() then
            showOnly("3d")
            draw3d(0, 0.3, 1, 0.3, elapsed)
        else
            showOnly("flat")
            self.tex:SetRotation(0)
            self.tex:SetVertexColor(0.3, 1, 0.3)
        end
        local arrived = L.ARRIVED or ns.Tr("Arrivé")
        local txt = pointe and M:Opt("caps") and ns.Upper(arrived) or arrived
        if txt ~= lastDistText then lastDistText = txt; self.dist:SetText(txt) end
        return
    end
    local rel = ns.Geo.RelativeAngle(bearing)
    if not rel then showOnly(); return end
    if pointe then
        showOnly("pointe")
        drawPointe(rel, elapsed)
    elseif use3d() then
        showOnly("3d")
        local r, g, b = color(rel)
        draw3d(rel, r, g, b, elapsed)
    else
        showOnly("flat")
        self.tex:SetRotation(rel)
        self.tex:SetVertexColor(color(rel))
    end
    local txt
    if pointe then
        txt = ns.FormatDistance(d)
        local t = eta(d)
        if t ~= "" then txt = txt .. "   " .. t end
        if M:Opt("caps") then txt = ns.Upper(txt) end
    else
        txt = ns.FormatDistance(d)
    end
    if txt ~= lastDistText then lastDistText = txt; self.dist:SetText(txt) end
end)

local function applyTextFont()
    local name, size = M:Opt("font"), M:Opt("textSize") or 14
    ns.SetFontOverride("QuestweaverFontArrow", name, size)
    ns.SetFontOverride("QuestweaverFontArrowGold", name, size)
end
ns.On("PLAYER_LOGIN", function() C_Timer.After(3.5, applyTextFont) end)

function M:Apply()
    applyTextFont()
    local s = self:Opt("size") or 56
    f.tex:SetSize(s, s)
    layout3d(s * 1.25)
    holderP:SetSize(s * 1.1, s * 0.95)
    pTex:SetSize(s * 1.1, s * 1.1); pTex:ClearAllPoints(); pTex:SetPoint("CENTER", 0, 2)
    pShadow:SetSize(s * 1.15, s * 1.15); pShadow:ClearAllPoints(); pShadow:SetPoint("CENTER", 1, -2)
    f.dist:ClearAllPoints(); f.label:ClearAllPoints(); f.next:ClearAllPoints()
    if usePointe() then
        f.label:SetFontObject("QuestweaverFontArrow")
        f.dist:SetFontObject("QuestweaverFontArrowGold")
        f.label:SetWidth(300)
        f.label:SetPoint("TOP", holderP, "BOTTOM", 0, -4)
        f.next:SetPoint("TOP", f.label, "BOTTOM", 0, -2)
        f.dist:SetPoint("TOP", f.next, "BOTTOM", 0, -4)
    else
        f.label:SetFontObject("QuestweaverFontSmall")
        f.dist:SetFontObject("QuestweaverFontNormal")
        f.label:SetWidth(160)
        f.dist:SetPoint("TOP", use3d() and holder3d or f.tex, "BOTTOM", 0, -2)
        f.label:SetPoint("TOP", f.dist, "BOTTOM", 0, -1)
    end
end
function M:OnEnable() self:Apply(); f:Show() end
function M:OnDisable() f:Hide() end
function M:OnOptionChanged() self:Apply(); markTexts(); lastDistText = nil end

function M.preview(p)
    local sh = p:CreateTexture(nil, "BACKGROUND")
    sh:SetTexture(ns.MEDIA .. "pointe"); sh:SetSize(52, 52); sh:SetPoint("TOP", 1, -6)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetTexture(ns.MEDIA .. "pointe"); t:SetSize(50, 50); t:SetPoint("TOP", 0, -2)
    local l1 = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontArrow")
    l1:SetPoint("TOP", t, "BOTTOM", 0, 6); l1:SetText(ns.Upper(ns.Tr("Rendre : La menace kobold"))); l1:SetScale(0.7)
    local l2 = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontArrowGold")
    l2:SetPoint("TOP", l1, "BOTTOM", 0, -2); l2:SetText("30 M   0:04"); l2:SetScale(0.7)
    local a = 0
    p:SetScript("OnUpdate", function(_, dt)
        a = a + dt
        local rr = math.sin(a * 1.2) * 1.2
        groundCoords(sh, rr, POINTE_FLAT); groundCoords(t, rr, POINTE_FLAT)
        sh:SetVertexColor(0, 0, 0, 0.45)
        t:SetVertexColor(pointeColor(rr < 0 and 2 * math.pi + rr or rr))
    end)
end
