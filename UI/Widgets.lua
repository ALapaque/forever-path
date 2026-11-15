local _, ns = ...

---------------------------------------------------------------------------
-- Thèmes
---------------------------------------------------------------------------
local FLAT = "Interface\\Buttons\\WHITE8x8"
ns.Themes = {
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
    local a = frame.fpAlpha or opts.alpha or t.bg[4]
    frame:SetBackdropColor(t.bg[1], t.bg[2], t.bg[3], a)
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
        ns.db.theme = type(DaylightUI) == "table" and "soft" or "dark"
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
