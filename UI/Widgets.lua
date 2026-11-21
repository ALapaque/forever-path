local _, ns = ...

---------------------------------------------------------------------------
-- Thèmes
---------------------------------------------------------------------------
local FLAT = "Interface\\Buttons\\WHITE8x8"
-- Un thème peut porter :
--   header = { r, g, b, a } : bandeau derrière le titre de la fenêtre du guide ;
--   guide  = { bg, text, dim, accent, track, ink } : couleurs propres à la fenêtre du guide (fond
--            clair du thème Classic). ink = true : les codes couleur des textes sont assombris
--            pour rester lisibles sur le parchemin (voir ns.Ink) ;
--   custom = true : thème réglable par le joueur (Modern, voir ns.BuildModern).
ns.Themes = {
    -- Modern : plat, une couleur d'accent ; préréglages et réglages dans Apparence (ns.db.modern)
    { key = "modern", name = "Modern", custom = true,
      bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, inset = 0,
      bg = { 0.07, 0.08, 0.095, 0.94 }, border = { 1, 1, 1, 0.10 },
      accent = { 0.35, 0.66, 1 }, text = { 0.95, 0.96, 0.97 },
      button = { bg = { 1, 1, 1, 0.06 }, border = { 1, 1, 1, 0.10 }, hover = { 0.35, 0.66, 1, 0.25 } } },
    -- Classic : l'allure Vanilla. Cadre doré, bandeau sombre, boutons rouges, parchemin pour le guide.
    { key = "classic", name = "Classic",
      bgFile = FLAT, edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 16, inset = 4,
      bg = { 0.14, 0.09, 0.04, 0.96 }, border = { 1, 1, 1, 1 },
      accent = { 1, 0.82, 0 }, text = { 1, 0.96, 0.86 },
      button = { bg = { 0.43, 0.08, 0.07, 1 }, border = { 0.79, 0.64, 0.15, 0.9 }, hover = { 0.6, 0.12, 0.1, 1 } },
      header = { 0.10, 0.06, 0.03, 1 },
      guide = { bg = { 0.91, 0.86, 0.72, 1 }, text = { 0.16, 0.10, 0.04 }, dim = { 0.29, 0.21, 0.13 },
                accent = { 0.42, 0.08, 0.06 }, track = { 0.14, 0.09, 0.04, 1 }, ink = true } },
    -- Classic Forever : l'allure de l'interface native de Forever (panneaux sombres, bord métallique, titres dorés)
    { key = "forever", name = "Classic Forever",
      bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, inset = 0,
      bg = { 0.10, 0.105, 0.12, 0.95 }, border = { 0.49, 0.47, 0.41, 1 },
      accent = { 1, 0.82, 0 }, text = { 0.96, 0.95, 0.90 },
      button = { bg = { 0.23, 0.23, 0.26, 1 }, border = { 0.49, 0.47, 0.41, 0.9 }, hover = { 0.33, 0.33, 0.37, 1 } },
      header = { 0.165, 0.17, 0.19, 1 } },
    { key = "dark", name = "Sombre doré",
      bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, inset = 0,
      bg = { 0.05, 0.05, 0.07, 0.88 }, border = { 0.83, 0.69, 0.22, 0.9 },
      accent = { 0.83, 0.69, 0.22 }, text = { 1, 1, 1 },
      button = { bg = { 0.14, 0.12, 0.08, 0.95 }, border = { 0.83, 0.69, 0.22, 0.7 }, hover = { 0.3, 0.25, 0.1, 1 } } },
    { key = "soft", name = "Doux (style Daylight UI)",
      bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, inset = 0,
      bg = { 0.08, 0.09, 0.12, 0.80 }, border = { 1, 1, 1, 0.08 },
      accent = { 0.72, 0.68, 1 }, text = { 0.92, 0.93, 0.96 },
      button = { bg = { 1, 1, 1, 0.06 }, border = { 1, 1, 1, 0.10 }, hover = { 0.72, 0.68, 1, 0.25 } } },
    { key = "blizzard", name = "Blizzard",
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 14, inset = 3,
      bg = { 0, 0, 0, 0.85 }, border = { 0.9, 0.9, 0.9, 1 },
      accent = { 1, 0.82, 0 }, text = { 1, 1, 1 },
      button = { bg = { 0.35, 0.05, 0.05, 1 }, border = { 1, 0.82, 0, 0.8 }, hover = { 0.55, 0.1, 0.1, 1 } } },
    -- Néon : contraste fort, textes en majuscules avec contour, lignes surlignées pour prendre,
    -- faire et rendre, mots-clés en couleur, barre de progression en dégradé.
    { key = "neon", name = "Néon (contraste)",
      bgFile = FLAT, edgeFile = FLAT, edgeSize = 2, inset = 0,
      bg = { 0.11, 0.11, 0.12, 0.94 }, border = { 0, 0, 0, 0.95 },
      accent = { 0.25, 0.95, 0.6 }, text = { 1, 1, 1 },
      button = { bg = { 1, 1, 1, 0.06 }, border = { 0, 0, 0, 0.9 }, hover = { 0.42, 0.22, 0.72, 0.9 } },
      caps = true, outline = true, keywords = true, barBottom = true,
      gradient = { { 1, 0.45, 0.1 }, { 0.25, 0.45, 1 } },
      rows = { accept = { 0.40, 0.20, 0.68, 0.85 }, turnin = { 0.40, 0.20, 0.68, 0.85 },
               complete = { 0.40, 0.20, 0.68, 0.55 } } },
    { key = "minimal", name = "Minimal",
      bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, inset = 0,
      bg = { 0, 0, 0, 0.35 }, border = { 0, 0, 0, 0 },
      accent = { 0.95, 0.95, 0.95 }, text = { 0.9, 0.9, 0.9 },
      button = { bg = { 0, 0, 0, 0.4 }, border = { 1, 1, 1, 0.15 }, hover = { 1, 1, 1, 0.15 } } },
}
ns.ThemeByKey = {}
for _, t in ipairs(ns.Themes) do ns.ThemeByKey[t.key] = t end

function ns.Theme()
    local key = ns.db and ns.db.theme
    return ns.ThemeByKey[key or ""] or ns.ThemeByKey.dark
end

-- compat : ancien nom
ns.GOLD = ns.ThemeByKey.dark.accent

---------------------------------------------------------------------------
-- Thème Modern : préréglages et réglages du joueur (ns.db.modern)
---------------------------------------------------------------------------
ns.MODERN_PRESETS = {
    { key = "default", name = "Défaut", accent = "Bleu" },
    -- les couleurs du thème Néon : vert, lignes violettes, barre en dégradé, majuscules
    { key = "neon", name = "Néon", accent = "Vert néon", rows = true, gradient = true, caps = true },
    { key = "gold", name = "Doré", accent = "Doré" },
    { key = "soft", name = "Pastel", accent = "Lavande" },
    { key = "class", name = "Couleur de classe", accent = "Couleur de classe" },
}
ns.MODERN_ACCENTS = {
    { name = "Bleu", c = { 0.35, 0.66, 1 } },
    { name = "Vert néon", c = { 0.25, 0.95, 0.6 } },
    { name = "Doré", c = { 0.83, 0.69, 0.22 } },
    { name = "Orange", c = { 1, 0.49, 0.04 } },
    { name = "Lavande", c = { 0.72, 0.68, 1 } },
    { name = "Rouge", c = { 0.95, 0.33, 0.33 } },
    { name = "Blanc", c = { 0.95, 0.95, 0.95 } },
    { name = "Couleur de classe", class = true },
}
local MODERN_BG, MODERN_BORDER = { 0.07, 0.08, 0.095, 0.94 }, { 1, 1, 1, 0.10 }

local function accentColor(name)
    for _, a in ipairs(ns.MODERN_ACCENTS) do
        if a.name == name then
            if a.class then
                local _, class = UnitClass("player")
                local cc = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
                if cc then return { cc.r, cc.g, cc.b } end
                return ns.MODERN_ACCENTS[1].c
            end
            return a.c
        end
    end
    return ns.MODERN_ACCENTS[1].c
end

-- réglages du thème Modern (créés au besoin, avec le préréglage par défaut)
function ns.ModernSettings()
    if not ns.db then return { preset = "default", accent = "Bleu" } end
    if type(ns.db.modern) ~= "table" then ns.db.modern = { preset = "default", accent = "Bleu" } end
    return ns.db.modern
end

-- applique un préréglage : il remplace tous les réglages, que le joueur peut ensuite changer un à un
function ns.ModernPreset(key)
    for _, p in ipairs(ns.MODERN_PRESETS) do
        if p.key == key then
            local m = ns.ModernSettings()
            m.preset, m.accent = p.key, p.accent
            m.rows, m.gradient, m.caps = p.rows or false, p.gradient or false, p.caps or false
            ns.BuildModern()
            return true
        end
    end
end

-- reconstruit la table du thème Modern, sur place (les modules gardent la même table)
function ns.BuildModern()
    local t, neon, m = ns.ThemeByKey.modern, ns.ThemeByKey.neon, ns.ModernSettings()
    local a = accentColor(m.accent)
    t.accent = { a[1], a[2], a[3] }
    t.button.hover = { a[1], a[2], a[3], 0.25 }
    t.rows = m.rows and neon.rows or nil
    t.gradient = m.gradient and neon.gradient or nil
    t.caps = m.caps or nil
    t.outline = m.caps or nil
    -- préréglage Néon : aussi son fond, sa bordure noire et ses mots-clés en couleur
    local isNeon = m.preset == "neon"
    t.bg = isNeon and neon.bg or MODERN_BG
    t.border = isNeon and neon.border or MODERN_BORDER
    t.edgeSize = isNeon and neon.edgeSize or 1
    t.keywords = isNeon and m.rows or nil
    t.button.border = isNeon and neon.button.border or { 1, 1, 1, 0.10 }
end

---------------------------------------------------------------------------
-- Encre : sur le parchemin du thème Classic, les couleurs claires des textes (jaune, blanc,
-- bleu ciel) sont illisibles. Chaque code couleur est assombri ; le blanc et les gris prennent
-- la couleur du texte du thème.
---------------------------------------------------------------------------
function ns.Ink(text)
    local g = ns.Theme().guide
    if not (g and g.ink and type(text) == "string") then return text end
    return (text:gsub("|c%x%x(%x%x)(%x%x)(%x%x)", function(r, gg, b)
        local R, G, B = tonumber(r, 16) / 255, tonumber(gg, 16) / 255, tonumber(b, 16) / 255
        local mx, mn = math.max(R, G, B), math.min(R, G, B)
        if mx - mn < 0.15 then
            local c = mx > 0.75 and g.text or g.dim
            R, G, B = c[1], c[2], c[3]
        elseif mx > 0.45 then
            local k = 0.45 / mx
            R, G, B = R * k, G * k, B * k
        end
        return ("|cff%02x%02x%02x"):format(math.floor(R * 255 + 0.5), math.floor(G * 255 + 0.5), math.floor(B * 255 + 0.5))
    end))
end

-- couleur d'un texte de la fenêtre du guide : "text", "dim" ou "accent"
function ns.GuideColor(kind)
    local t = ns.Theme()
    local g = t.guide
    if kind == "text" then return unpack(g and g.text or t.text) end
    if kind == "accent" then return unpack(g and g.accent or t.accent) end
    if g and g.dim then return unpack(g.dim) end
    return 0.55, 0.55, 0.58
end

---------------------------------------------------------------------------
-- Polices (objets de police propres à l'addon, modifiables en direct)
---------------------------------------------------------------------------
ns.FONTS = {
    { name = "Friz Quadrata (Blizzard)", path = "Fonts\\FRIZQT__.TTF" },
    { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { name = "Skurri", path = "Fonts\\SKURRI.TTF" },
}

local FONT_OBJECTS = {
    -- nom                         modèle Blizzard             couleur   taille par défaut
    { "QuestweaverFontNormal",     "GameFontNormal",           "accent", 12 },
    { "QuestweaverFontHighlight",  "GameFontHighlight",        "text",   12 },
    { "QuestweaverFontSmall",      "GameFontHighlightSmall",   "text",   10 },
    { "QuestweaverFontSmallDim",   "GameFontDisableSmall",     "dim",    10 },
    { "QuestweaverFontSmallGold",  "GameFontNormalSmall",      "accent", 10 },
    { "QuestweaverFontLarge",      "GameFontNormalLarge",      "accent", 16 },
    { "QuestweaverFontHuge",       "GameFontNormalHuge",       "accent", 20 },
    -- textes sous la flèche « pointe » : contour épais, lisibles sur n'importe quel décor
    { "QuestweaverFontArrow",      "GameFontNormalLarge",      "white",  14, "THICKOUTLINE" },
    { "QuestweaverFontArrowGold",  "GameFontNormalLarge",      "gold",   14, "THICKOUTLINE" },
    -- textes du guide quand le thème demande un contour (thème Néon)
    { "QuestweaverFontOutline",    "GameFontHighlight",        "text",   12, "OUTLINE" },
    { "QuestweaverFontOutlineSmall", "GameFontHighlightSmall", "text",   10, "OUTLINE" },
}
local baseSize = {}
for _, def in ipairs(FONT_OBJECTS) do
    local fo = _G[def[1]] or CreateFont(def[1])
    local model = _G[def[2]]
    local size, flags
    if model and model.GetFont then
        local ok, _, s, f = pcall(model.GetFont, model)
        if ok then size, flags = s, f end
    end
    -- certaines interfaces (ou un modèle pas encore chargé) renvoient 0 : on garde une taille sûre
    if type(size) ~= "number" or size < 6 then size = def[4] end
    if def[5] then size, flags = math.max(size, def[4]), def[5] end
    baseSize[def[1]] = { size = size, flags = flags or "" }
    fo:SetFont(ns.FONTS[1].path, size, flags or "")
end

local function lsm() return LibStub and LibStub("LibSharedMedia-3.0", true) end

-- Liste des polices proposées (Blizzard + LibSharedMedia si présent, ex. polices de packs d'interface)
function ns.FontList()
    local list, seen = {}, {}
    if ns.Daylight and ns.Daylight.registered and ns.Daylight.FontPath() then
        list[#list + 1] = ns.Daylight.FONT_NAME; seen[ns.Daylight.FONT_NAME] = true
        if ns.Daylight.QuestFontPath() then
            list[#list + 1] = ns.Daylight.QUEST_FONT_NAME; seen[ns.Daylight.QUEST_FONT_NAME] = true
        end
    end
    for _, f in ipairs(ns.FONTS) do list[#list + 1] = f.name; seen[f.name] = true end
    local media = lsm()
    if media then
        for _, name in ipairs(media:List("font") or {}) do
            if not seen[name] then list[#list + 1] = name; seen[name] = true end
        end
    end
    return list
end

local function fontPath(name)
    if ns.Daylight and name == ns.Daylight.FONT_NAME then
        local p = ns.Daylight.FontPath()
        if p then return p end
    end
    if ns.Daylight and name == ns.Daylight.QUEST_FONT_NAME then
        local p = ns.Daylight.QuestFontPath() or ns.Daylight.FontPath()
        if p then return p end
    end
    for _, f in ipairs(ns.FONTS) do if f.name == name then return f.path end end
    local media = lsm()
    local p = media and name and media:Fetch("font", name, true)
    return p or ns.FONTS[1].path
end

-- Distance affichée comme le marqueur du jeu (même nombre, même unité que le client :
-- « 65 mètres » en français, « 65 yds » en anglais), pour ne jamais montrer deux valeurs différentes.
function ns.FormatDistance(yards)
    if type(yards) ~= "number" or ns.IsSecret and ns.IsSecret(yards) then return "" end
    local n = math.floor(yards + 0.5)
    local fmt = type(IN_GAME_NAVIGATION_RANGE) == "string" and IN_GAME_NAVIGATION_RANGE
    if fmt then
        local ok, txt = pcall(string.format, fmt, n)
        if ok and txt then return txt end
    end
    return ("%d m"):format(n)
end

-- Majuscules en UTF-8 (accents français, allemands, espagnols compris), sans toucher aux codes
-- de l'interface (|cffxxxxxx, |r, |T...|t, |A...|a) ni aux liens.
local UPPER = { ["à"]="À", ["â"]="Â", ["ä"]="Ä", ["á"]="Á", ["ç"]="Ç", ["é"]="É", ["è"]="È", ["ê"]="Ê",
    ["ë"]="Ë", ["í"]="Í", ["î"]="Î", ["ï"]="Ï", ["ñ"]="Ñ", ["ó"]="Ó", ["ô"]="Ô", ["ö"]="Ö", ["ú"]="Ú",
    ["ù"]="Ù", ["û"]="Û", ["ü"]="Ü", ["œ"]="Œ", ["æ"]="Æ" }
local function upperPlain(s)
    s = s:gsub("[\195\197][\128-\191]", function(ch) return UPPER[ch] or ch end)
    return (s:upper())
end
function ns.Upper(s)
    if type(s) ~= "string" or s == "" then return s end
    local out, i, n = {}, 1, #s
    while i <= n do
        local j = s:find("|", i, true)
        if not j then out[#out + 1] = upperPlain(s:sub(i)); break end
        out[#out + 1] = upperPlain(s:sub(i, j - 1))
        local c = s:sub(j + 1, j + 1)
        local e
        if c == "c" then e = j + 9
        elseif c == "r" or c == "n" or c == "|" then e = j + 1
        elseif c == "T" then e = (s:find("|t", j + 2, true) or n) + 1
        elseif c == "A" then e = (s:find("|a", j + 2, true) or n) + 1
        elseif c == "H" then e = (s:find("|h", j + 2, true) or n) + 1
        else e = j end
        out[#out + 1] = s:sub(j, e)
        i = e + 1
    end
    return table.concat(out)
end

-- SetFont ne renvoie rien sur certains clients (et true / false sur d'autres) : on ne se fie pas à
-- son retour. On vérifie avec GetFont que le fichier demandé est bien celui en place.
local function baseName(p)
    return type(p) == "string" and (p:lower():gsub("/", "\\"):match("([^\\]+)$")) or nil
end
local function setFont(fo, path, size, flags)
    local ok, res = pcall(fo.SetFont, fo, path, size, flags)
    if not ok or res == false then return false end
    local cur = fo:GetFont()
    return cur ~= nil and baseName(cur) == baseName(path)
end
ns._setFont = setFont

-- Icônes de quête du jeu (atlas) : « ! » jaune pour prendre, « ? » jaune pour rendre (gris tant
-- que la quête n'est pas terminée). Les anciens fichiers GossipFrame\*QuestIcon ne correspondent
-- plus aux icônes affichées au-dessus des PNJ sur ce client.
ns.QUEST_ATLAS = { accept = "QuestNormal", turnin = "QuestTurnin" }
local function atlasExists(name)
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    return ok and info ~= nil
end
function ns.SetStepIcon(tex, step, fallback)
    local kind = step and step.type
    local atlas = kind and ns.QUEST_ATLAS[kind]
    if atlas and tex.SetAtlas and atlasExists(atlas) then
        tex:SetAtlas(atlas)
        local waiting = false
        if kind == "turnin" and step.quest and C_QuestLog and C_QuestLog.IsComplete then
            local inLog = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(step.quest)
            waiting = inLog ~= nil and not C_QuestLog.IsComplete(step.quest)
        end
        if tex.SetDesaturated then tex:SetDesaturated(waiting) end
        return true
    end
    if tex.SetDesaturated then tex:SetDesaturated(false) end
    tex:SetTexture(fallback)
    return false
end

ns.GENERAL_FONT = ns.Tr("Police générale (Apparence)")
ns.FontPath = function(name) return fontPath(name) end

-- Police propre à un groupe d'objets (ex. textes de la flèche) : name = nil ou "" -> police générale
local overrides = {}       -- [objet] = { name = ..., size = ... }
function ns.SetFontOverride(objName, fontName, size)
    overrides[objName] = { name = fontName, size = size }
    ns.ApplyFonts()
end

function ns.ApplyFonts()
    local t = ns.Theme()
    local path = fontPath(ns.db and ns.db.font)
    local scale = (ns.db and ns.db.fontScale) or 1
    for _, def in ipairs(FONT_OBJECTS) do
        local fo = _G[def[1]]
        local b = baseSize[def[1]]
        local ov = overrides[def[1]]
        local size = math.max(6, math.floor(((ov and ov.size) or b.size) * scale + 0.5))
        local p = (ov and ov.name and ov.name ~= "" and ov.name ~= ns.GENERAL_FONT and ov.name ~= "Police générale (Apparence)") and fontPath(ov.name) or path
        if not setFont(fo, p, size, b.flags) then fo:SetFont(ns.FONTS[1].path, size, b.flags) end
        local c = def[3] == "accent" and t.accent or def[3] == "text" and t.text
            or def[3] == "white" and { 1, 1, 1 } or def[3] == "gold" and { 1, 0.82, 0.1 } or { 0.55, 0.55, 0.58 }
        fo:SetTextColor(c[1], c[2], c[3])
    end
    -- changer un objet de police peut remettre sa couleur aux textes qui en héritent : la fenêtre
    -- du guide repose alors les siennes (thème Classic)
    if ns.Fire then ns.Fire("FP_FONTS_APPLIED") end
end

---------------------------------------------------------------------------
-- Habillage des cadres
---------------------------------------------------------------------------
local skinned = setmetatable({}, { __mode = "k" })   -- [frame] = { alpha, borderAlpha }

local function applySkin(frame, opts)
    local t = ns.Theme()
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    local i = t.inset or 0
    frame:SetBackdrop({ bgFile = t.bgFile, edgeFile = t.edgeFile, edgeSize = t.edgeSize,
        insets = { left = i, right = i, top = i, bottom = i } })
    -- la fenêtre du guide peut avoir son propre fond (parchemin du thème Classic)
    local bg = frame.fpGuide and t.guide and t.guide.bg or t.bg
    local a = frame.fpAlpha or opts.alpha or bg[4]
    frame:SetBackdropColor(bg[1], bg[2], bg[3], a)
    local ba = opts.borderAlpha and math.min(t.border[4], opts.borderAlpha) or t.border[4]
    frame:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], ba)
end

-- alpha / borderAlpha : valeurs « préférées » (bornées par le thème pour la bordure)
function ns.Skin(frame, alpha, borderAlpha)
    local opts = { alpha = alpha, borderAlpha = borderAlpha }
    skinned[frame] = opts
    applySkin(frame, opts)
end

function ns.ReSkin(frame)
    if skinned[frame] then applySkin(frame, skinned[frame]) end
end

---------------------------------------------------------------------------
-- Boutons plats, aux couleurs du thème
---------------------------------------------------------------------------
local buttons = setmetatable({}, { __mode = "k" })

local function paintButton(b)
    local t = ns.Theme().button
    local c = b.fpHover and t.hover or t.bg
    b:SetBackdropColor(c[1], c[2], c[3], c[4])
    b:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], t.border[4])
end

-- ns.Button(parent, label, w, h, onClick [, tooltip [, icon]])
function ns.Button(parent, label, w, h, onClick, tooltip, icon)
    label, tooltip = ns.Tr(label), type(tooltip) == "string" and ns.Tr(tooltip) or tooltip
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, h or 20)
    b:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 })
    b:SetNormalFontObject("QuestweaverFontSmallGold")
    b:SetHighlightFontObject("QuestweaverFontSmall")
    b:SetDisabledFontObject("QuestweaverFontSmallDim")
    if label and label ~= "" then b:SetText(label) end
    if icon then
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize((h or 20) - 6, (h or 20) - 6)
        b.icon:SetPoint("CENTER")
        b.icon:SetTexture(icon)
    end
    b.tooltip = tooltip
    b:SetScript("OnEnter", function(self)
        self.fpHover = true
        paintButton(self)
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            if type(self.tooltip) == "function" then self.tooltip(GameTooltip)
            else GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.fpHover = false
        paintButton(self)
        GameTooltip:Hide()
    end)
    if onClick then b:SetScript("OnClick", onClick) end
    buttons[b] = true
    paintButton(b)
    return b
end

-- Applique thème + polices à tout ce qui est déjà créé
function ns.ApplyLook()
    ns.BuildModern()
    ns.ApplyFonts()
    for frame, opts in pairs(skinned) do applySkin(frame, opts) end
    for b in pairs(buttons) do paintButton(b) end
    ns.Fire("FP_THEME_CHANGED")
end

---------------------------------------------------------------------------
-- Toast : message temporaire en haut de l'écran
---------------------------------------------------------------------------
local toast = CreateFrame("Frame", "QuestweaverToast", UIParent, "BackdropTemplate")
toast:SetSize(420, 40)
toast:SetPoint("TOP", 0, -140)
toast:SetFrameStrata("HIGH")
toast:Hide()
ns.Skin(toast, 0.9)
toast.icon = toast:CreateTexture(nil, "ARTWORK")
toast.icon:SetSize(24, 24)
toast.icon:SetPoint("LEFT", 8, 0)
toast.text = toast:CreateFontString(nil, "OVERLAY", "QuestweaverFontHighlight")
toast.text:SetPoint("LEFT", toast.icon, "RIGHT", 8, 0)
toast.text:SetPoint("RIGHT", -8, 0)
toast.text:SetJustifyH("LEFT")
toast.elapsed = 0
toast:SetScript("OnUpdate", function(self, dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed > self.duration then
        local a = 1 - (self.elapsed - self.duration) / 0.6
        if a <= 0 then self:Hide() else self:SetAlpha(a) end
    end
end)

function ns.Toast(msg, icon, r, g, b, duration)
    toast.text:SetText(ns.Tr(msg))
    toast.text:SetTextColor(r or 1, g or 1, b or 1)
    toast.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Map_01")
    toast.elapsed, toast.duration = 0, duration or 4
    toast:SetAlpha(1)
    toast:Show()
end

ns.On("FP_INIT", function()
    -- thème par défaut : « Doux » si Daylight UI est installé (remplacé par le thème
    -- « Daylight UI » si son API est prise en charge, voir UI/DaylightUI.lua)
    if ns.db.theme == nil then
        ns.db.theme = type(DaylightUI) == "table" and "soft" or "modern"
    end
    ns.db.font = ns.db.font or ns.FONTS[1].name
    ns.db.fontScale = ns.db.fontScale or 1
    ns.ApplyLook()
end)

-- La police choisie peut venir d'un autre addon (pack LibSharedMedia, Daylight UI) chargé après
-- Questweaver : au démarrage elle n'existe pas encore et on retombait sur Friz Quadrata pour de bon.
-- On réapplique donc à la connexion, un peu après, et à chaque police enregistrée plus tard.
local pendingFonts
local function reapplyFonts()
    if pendingFonts or not ns.db then return end
    pendingFonts = true
    C_Timer.After(0.5, function() pendingFonts = false; ns.ApplyFonts() end)
end
ns.On("PLAYER_LOGIN", function()
    ns.ApplyFonts()
    C_Timer.After(3, ns.ApplyFonts)
    local media = lsm()
    if media and media.RegisterCallback then
        pcall(media.RegisterCallback, ns, "LibSharedMedia_Registered", function(_, kind)
            if kind == "font" then reapplyFonts() end
        end)
    end
end)
ns.On("PLAYER_ENTERING_WORLD", reapplyFonts)

-- /qw police : quelle police est choisie, quel fichier elle donne, et ce que le jeu affiche vraiment
ns.SlashExt.police = function()
    local want = ns.db and ns.db.font or "?"
    local cur = QuestweaverFontNormal and QuestweaverFontNormal:GetFont()
    ns.Print(ns.Tr("Police choisie : %s"):format(tostring(want)))
    ns.Print(ns.Tr("Fichier attendu : %s"):format(tostring(fontPath(want))))
    ns.Print(ns.Tr("Fichier affiché : %s"):format(tostring(cur)))
end
ns.SlashExt.font = ns.SlashExt.police
