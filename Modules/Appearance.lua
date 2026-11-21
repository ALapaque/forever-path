local _, ns = ...

-- Apparence : thème des fenêtres et police, appliqués en direct à tout l'addon.
local function themeNames()
    local out = {}
    for _, t in ipairs(ns.Themes) do out[#out + 1] = t.name end
    return out
end

local function names(list)
    local out = {}
    for _, e in ipairs(list) do out[#out + 1] = e.name end
    return out
end
local function presetName()
    local key = ns.ModernSettings().preset
    for _, p in ipairs(ns.MODERN_PRESETS) do if p.key == key then return p.name end end
    return ns.MODERN_PRESETS[1].name
end

local M = ns.RegisterModule({
    id = "appearance", category = "look", default = true, locked = true,
    name = ns.Tr("Apparence"),
    desc = ns.Tr("Trois thèmes : Modern (réglable : préréglages dont Néon, couleur d'accent, lignes surlignées, dégradé, majuscules), Classic (l'allure Vanilla) et Classic Forever (l'allure de l'interface du jeu). Les anciens thèmes restent disponibles. Le style des fenêtres et la police. Avec Daylight UI installé, le thème « Daylight UI » reprend ses couleurs et sa police en direct. Les polices LibSharedMedia sont proposées aussi."),
    options = {
        { key = "theme", label = ns.Tr("Thème"), type = "select", values = themeNames, store = "value", width = 150 },
        -- réglages du thème Modern (sans effet sur les autres thèmes)
        { key = "modernPreset", label = ns.Tr("Modern : préréglage"), type = "select", values = function() return names(ns.MODERN_PRESETS) end, store = "value", width = 150 },
        { key = "modernAccent", label = ns.Tr("Modern : couleur d'accent"), type = "select", values = function() return names(ns.MODERN_ACCENTS) end, store = "value", width = 150 },
        { key = "modernRows", label = ns.Tr("Modern : lignes surlignées (prendre, faire, rendre)"), type = "check", default = false },
        { key = "modernGradient", label = ns.Tr("Modern : barre de progression en dégradé"), type = "check", default = false },
        { key = "modernCaps", label = ns.Tr("Modern : texte en majuscules"), type = "check", default = false },
        { key = "font", label = ns.Tr("Police"), type = "select", values = function() return ns.FontList() end, store = "value", width = 150 },
        { key = "fontScale", label = ns.Tr("Taille du texte"), type = "slider", min = 0.8, max = 1.8, step = 0.05, default = 1 },
        { key = "colorblind", label = ns.Tr("Couleurs adaptées aux daltoniens"), type = "check", default = false },
        { key = "locked", label = ns.Tr("Verrouiller les fenêtres (pas de déplacement)"), type = "check", default = false },
    },
})

-- Ces réglages vivent à la racine de la base (lus très tôt par UI/Widgets.lua)
function M:Opt(key)
    if key == "theme" then return ns.Theme().name end
    if key == "modernPreset" then return presetName() end
    if key == "modernAccent" then return ns.ModernSettings().accent end
    if key == "modernRows" then return ns.ModernSettings().rows and true or false end
    if key == "modernGradient" then return ns.ModernSettings().gradient and true or false end
    if key == "modernCaps" then return ns.ModernSettings().caps and true or false end
    if key == "font" then return ns.db.font end
    if key == "fontScale" then return ns.db.fontScale end
    if key == "locked" then return ns.db.locked end
    if key == "colorblind" then return ns.db.colorblind end
end

function M:SetOpt(key, value)
    if key == "theme" then
        for _, t in ipairs(ns.Themes) do if t.name == value then ns.db.theme = t.key end end
    elseif key == "modernPreset" then
        for _, p in ipairs(ns.MODERN_PRESETS) do if p.name == value then ns.ModernPreset(p.key) end end
    elseif key == "modernAccent" then
        ns.ModernSettings().accent = value
    elseif key == "modernRows" then
        ns.ModernSettings().rows = value and true or false
    elseif key == "modernGradient" then
        ns.ModernSettings().gradient = value and true or false
    elseif key == "modernCaps" then
        ns.ModernSettings().caps = value and true or false
    elseif key == "font" then
        ns.db.font = value
    elseif key == "fontScale" then
        ns.db.fontScale = value
    elseif key == "locked" then
        ns.db.locked = value
        return
    elseif key == "colorblind" then
        ns.db.colorblind = value
        ns.ApplyPalette()
        ns.Fire("FP_STEP_CHANGED", true)
        return
    end
    ns.ApplyLook()
end

function M.preview(p)
    local x = -48
    for _, key in ipairs({ "modern", "classic", "forever", "neon" }) do
        local t = ns.ThemeByKey[key]
        local sw = CreateFrame("Frame", nil, p, "BackdropTemplate")
        sw:SetSize(30, 44)
        sw:SetPoint("CENTER", x, 6)
        sw:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        sw:SetBackdropColor(t.bg[1], t.bg[2], t.bg[3], math.max(t.bg[4], 0.6))
        sw:SetBackdropBorderColor(t.accent[1], t.accent[2], t.accent[3], 0.9)
        local bar = sw:CreateTexture(nil, "ARTWORK")
        bar:SetColorTexture(t.accent[1], t.accent[2], t.accent[3], 1)
        bar:SetSize(20, 3)
        bar:SetPoint("TOP", 0, -6)
        x = x + 32
    end
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("BOTTOM", 0, 6)
    fs:SetText(ns.Tr("Aa — police au choix"))
end

---------------------------------------------------------------------------
-- Palette daltonien (Okabe-Ito) : couleurs des étapes, du tracé de la route et des itinéraires.
-- Les tables d'origine sont modifiées sur place ; la palette normale est gardée pour revenir.
---------------------------------------------------------------------------
local CB_STEP = { accept = "fff0e442", complete = "ffe69f00", turnin = "ff56b4e9", ["goto"] = "ffcccccc" }
local CB_RGB = {
    accept = { 0.94, 0.89, 0.26 }, complete = { 0.9, 0.62, 0 }, turnin = { 0.34, 0.71, 0.91 }, ["goto"] = { 0.8, 0.8, 0.8 },
    known = { 0.34, 0.71, 0.91 }, terrain = { 0, 0.62, 0.45 }, risky = { 0.84, 0.37, 0 }, flight = { 0.8, 0.47, 0.65 },
}
local saved
local function swap(tbl, key, value)
    if not tbl or tbl[key] == nil then return end
    saved[tbl] = saved[tbl] or {}
    if saved[tbl][key] == nil then saved[tbl][key] = tbl[key] end
    tbl[key] = value
end
function ns.ApplyPalette()
    saved = saved or {}
    -- retour à la palette normale
    for tbl, keys in pairs(saved) do for k, v in pairs(keys) do tbl[k] = v end end
    if not (ns.db and ns.db.colorblind) then return end
    local style = ns.Guide and ns.Guide.STYLE
    for k, c in pairs(CB_STEP) do
        if style and style[k] then
            saved[style[k]] = saved[style[k]] or { color = style[k].color }
            style[k].color = c
        end
    end
    local mr = ns.Modules.maproute and ns.Modules.maproute.COLORS
    local jr = ns.Modules.journeys and ns.Modules.journeys.COLORS
    for k, c in pairs(CB_RGB) do swap(mr, k, c); swap(jr, k, c) end
end
ns.On("FP_INIT", function() C_Timer.After(0, ns.ApplyPalette) end)
