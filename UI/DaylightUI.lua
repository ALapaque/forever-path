local _, ns = ...

-- Pont Daylight UI (https://daylightui.com/plugins/guide) :
--  - ForeverPath s'enregistre comme plugin (DaylightUI:RegisterPlugin) ;
--  - un thème « Daylight UI » reprend en direct sa couleur d'accent (API.Accent),
--    ses couleurs de texte (API.Colors) et sa police (API.FontFile("general")) ;
--  - il suit les changements de style de DUI (StyleChanged / SettingChanged) ;
--  - /dui path ouvre les options de ForeverPath.
-- Seule DaylightUI.API est promise stable par DUI : tout appel est protégé.
local B = {}
ns.Daylight = B

local NEEDS = { 1, 4 }      -- version d'API décrite par le guide des plugins
local FLAT = "Interface\\Buttons\\WHITE8x8"
local BG = { 0.078, 0.078, 0.09 }   -- #141417, la teinte sombre de Daylight UI

local function api()
    local a = type(DaylightUI) == "table" and DaylightUI.API
    return type(a) == "table" and a or nil
end

-- accepte {r,g,b}, {r=,g=,b=} ou r, g, b
local function rgb(v, g, b)
    if type(v) == "table" then return v.r or v[1], v.g or v[2], v.b or v[3] end
    return v, g, b
end

function B.Available()
    local a = api()
    if not a then return false end
    -- même version majeure (les majeures cassent la compatibilité), mineure suffisante
    local major, minor = a.major or 0, a.minor or 0
    return major == NEEDS[1] and minor >= NEEDS[2]
end

function B.FontPath()
    local a = api()
    if not (a and a.FontFile) then return end
    local ok, path = pcall(a.FontFile, "general")
    if ok and type(path) == "string" and path ~= "" then return path end
end

-- (Re)construit le thème à partir des couleurs actuelles de DUI
function B.BuildTheme()
    local a = api()
    if not a then return end
    local ar, ag, ab = 0.72, 0.68, 1
    if a.Accent then
        local ok, r, g, b = pcall(a.Accent)
        if ok and r then ar, ag, ab = rgb(r, g, b) end
    end
    local tr, tg, tb = 0.92, 0.93, 0.96
    if a.Colors then
        local ok, colors = pcall(a.Colors)
        if ok and type(colors) == "table" and colors.TEXT then
            local r, g, b = rgb(colors.TEXT)
            if r then tr, tg, tb = r, g, b end
        end
    end
    local t = ns.ThemeByKey.daylight
    if not t then
        t = { key = "daylight", name = "Daylight UI", bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, inset = 0 }
        table.insert(ns.Themes, 1, t)
        ns.ThemeByKey.daylight = t
    end
    t.bg = { BG[1], BG[2], BG[3], 0.86 }
    t.border = { 1, 1, 1, 0.07 }
    t.accent = { ar, ag, ab }
    t.text = { tr, tg, tb }
    t.button = { bg = { 1, 1, 1, 0.06 }, border = { 1, 1, 1, 0.10 }, hover = { ar, ag, ab, 0.25 } }
    return t
end

local function refresh()
    B.BuildTheme()
    if ns.db and (ns.db.theme == "daylight" or ns.db.font == B.FONT_NAME) then ns.ApplyLook() end
end

B.FONT_NAME = "Police de Daylight UI"

function B.Register()
    if B.registered or type(DaylightUI) ~= "table" then return end
    local a = api()
    if not a then return end
    if not B.Available() then
        ns.Print("Daylight UI détecté, mais sa version d'API (%s.%s) n'est pas encore prise en charge : thème « Doux » utilisé.",
            tostring(a.major), tostring(a.minor))
        return
    end
    B.registered = true
    B.BuildTheme()
    if DaylightUI.RegisterPlugin then
        local ok, err = pcall(DaylightUI.RegisterPlugin, DaylightUI, "ForeverPath", {
            needs = NEEDS, icon = "Interface\\Icons\\INV_Misc_Map_01", color = "d4af37", short = "Path",
        })
        if not ok then B.lastError = err end
    end
    local my = a.For and select(2, pcall(a.For, "ForeverPath"))
    if type(my) == "table" then
        B.handle = my
        if my.On then
            for _, ev in ipairs({ "StyleChanged", "SettingChanged", "Login" }) do
                pcall(my.On, ev, refresh)
            end
        end
        if my.RegisterCommand then
            pcall(my.RegisterCommand, "path", function() ns.Options:Open() end, "Ouvrir les options de ForeverPath")
        end
    end
end

ns.On("FP_INIT", function()
    B.Register()
    if B.registered then
        -- première fois que DUI est détecté : on adopte son thème et sa police (une seule fois,
        -- ensuite le choix du joueur est respecté)
        if not ns.db.daylightAdopted then
            ns.db.theme = "daylight"
            if B.FontPath() and (ns.db.font == nil or ns.db.font == ns.FONTS[1].name) then ns.db.font = B.FONT_NAME end
            ns.db.daylightAdopted = true
        end
        ns.ApplyLook()
    end
end)
