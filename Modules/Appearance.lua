local _, ns = ...

-- Apparence : thème des fenêtres et police, appliqués en direct à tout l'addon.
local function themeNames()
    local out = {}
    for _, t in ipairs(ns.Themes) do out[#out + 1] = t.name end
    return out
end

local M = ns.RegisterModule({
    id = "appearance", category = "look", default = true, locked = true,
    name = "Apparence",
    desc = "Le style des fenêtres et la police. Avec Daylight UI installé, le thème « Daylight UI » reprend ses couleurs et sa police en direct. Les polices LibSharedMedia sont proposées aussi.",
    options = {
        { key = "theme", label = "Thème", type = "select", values = themeNames, store = "value", width = 150 },
        { key = "font", label = "Police", type = "select", values = function() return ns.FontList() end, store = "value", width = 150 },
        { key = "fontScale", label = "Taille du texte", type = "slider", min = 0.8, max = 1.4, step = 0.05, default = 1 },
        { key = "locked", label = "Verrouiller les fenêtres (pas de déplacement)", type = "check", default = false },
    },
})

-- Ces réglages vivent à la racine de la base (lus très tôt par UI/Widgets.lua)
function M:Opt(key)
    if key == "theme" then return ns.Theme().name end
    if key == "font" then return ns.db.font end
    if key == "fontScale" then return ns.db.fontScale end
    if key == "locked" then return ns.db.locked end
end

function M:SetOpt(key, value)
    if key == "theme" then
        for _, t in ipairs(ns.Themes) do if t.name == value then ns.db.theme = t.key end end
    elseif key == "font" then
        ns.db.font = value
    elseif key == "fontScale" then
        ns.db.fontScale = value
    elseif key == "locked" then
        ns.db.locked = value
        return
    end
    ns.ApplyLook()
end

function M.preview(p)
    local x = -48
    for _, key in ipairs({ "dark", "soft", "blizzard", "minimal" }) do
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
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("BOTTOM", 0, 6)
    fs:SetText("Aa — police au choix")
end
