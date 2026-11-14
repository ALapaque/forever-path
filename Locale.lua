local _, ns = ...

-- Français par défaut, anglais pour les clients enUS/enGB.
local fr = {
    ADDON = "ForeverPath",
    NO_GUIDE = "Aucun guide chargé. Tape /fp guides pour en choisir un.",
    GUIDE_DONE = "Guide terminé ! Ouvre les zones recommandées (bouton Zones).",
    STEP = "Étape %d / %d",
    ACCEPT = "Prendre",
    COMPLETE = "Faire",
    TURNIN = "Rendre",
    GOTO = "Aller à",
    LEVEL = "Monter niveau %d",
    NOTE = "Note",
    HEARTH = "Pierre de foyer",
    BIND = "Lier la pierre",
    FLY = "Prendre le vol",
    ZONES = "Zones",
    ZONES_TITLE = "Zones recommandées (niv. %d)",
    DUNGEONS_TITLE = "Donjons à ton niveau",
    UNCONFIRMED = "(niveaux non confirmés)",
    YOU_ARE_HERE = "tu es ici",
    TOO_HIGH = "Tu dépasses le niveau de %s. Zones conseillées : %s",
    REC_ON = "Enregistreur ACTIVÉ — tes quêtes sont notées pour créer un guide.",
    REC_OFF = "Enregistreur désactivé.",
    REC_CLEARED = "Enregistrement effacé.",
    EXPORT_TITLE = "Export du guide (Ctrl+A, Ctrl+C)",
    LOADED = "Guide chargé : %s",
    NEXT_SEGMENT = "Segment suivant : %s",
    ARRIVED = "Arrivé",
    ACCEPT_VERB = "Prendre",
    FLIGHTPATH = "Point de vol",
    UNKNOWN_GUIDE = "Guide inconnu : %s",
    HELP = {
        "/fp — afficher/masquer",
        "/fp next | prev | skip — naviguer",
        "/fp zones — zones recommandées",
        "/fp guides — liste des guides",
        "/fp load <id> — charger un guide",
        "/fp rec on|off|clear — enregistreur de quêtes",
        "/fp export — exporter l'enregistrement",
        "/fp auto — activer/désactiver l'auto-accept/rendu",
        "/fp config — panneau d'options (modules, aperçus)",
        "/fp lock — verrouiller les fenêtres",
        "/fp paths [export|import|reset] — chemins appris (itinéraires)",
        "/fp session [minutes|stop] — session de jeu",
        "/fp chrono — temps par niveau",
        "/fp rapport — rapport de parcours anonyme",
        "/fp profil [nom|export|import] — profils de réglages",
        "/fp bug — rapport de bug à copier",
        "/fp importer | routes — bibliothèque de routes",
        "/fp edit pos|suppr|note|export — corriger la route",
        "/fp donjons — quêtes de donjon à ton niveau",
        "/fp collecte [export] — quêtes de Forever collectées",
        "/fp where — infos de position (debug)",
    },
}

local en = {
    NO_GUIDE = "No guide loaded. Type /fp guides to pick one.",
    GUIDE_DONE = "Guide complete! Open recommended zones (Zones button).",
    STEP = "Step %d / %d",
    ACCEPT = "Accept", COMPLETE = "Complete", TURNIN = "Turn in", GOTO = "Go to",
    LEVEL = "Reach level %d", NOTE = "Note", HEARTH = "Hearthstone", FLY = "Fly", BIND = "Set hearth",
    ZONES = "Zones", ZONES_TITLE = "Recommended zones (lvl %d)",
    DUNGEONS_TITLE = "Dungeons for your level", UNCONFIRMED = "(levels unconfirmed)",
    YOU_ARE_HERE = "you are here",
    TOO_HIGH = "You outlevel %s. Suggested zones: %s",
    REC_ON = "Recorder ON — your quests are logged to build a guide.",
    REC_OFF = "Recorder off.", REC_CLEARED = "Recording cleared.",
    EXPORT_TITLE = "Guide export (Ctrl+A, Ctrl+C)",
    LOADED = "Guide loaded: %s", UNKNOWN_GUIDE = "Unknown guide: %s",
    NEXT_SEGMENT = "Next segment: %s", ARRIVED = "Arrived", FLIGHTPATH = "Flight path", ACCEPT_VERB = "Accept",
    HELP = {
        "/fp — show/hide",
        "/fp next | prev | skip — navigate",
        "/fp zones — recommended zones",
        "/fp guides — list guides",
        "/fp load <id> — load a guide",
        "/fp rec on|off|clear — quest recorder",
        "/fp export — export the recording",
        "/fp auto — toggle auto accept/turn-in",
        "/fp config — options panel (modules, previews)",
        "/fp lock — lock windows",
        "/fp paths [export|import|reset] — learned paths (journeys)",
        "/fp session [minutes|stop] — play session",
        "/fp chrono — time per level",
        "/fp rapport — anonymous run report",
        "/fp profil [name|export|import] — settings profiles",
        "/fp bug — bug report to copy",
        "/fp importer | routes — route library",
        "/fp edit pos|suppr|note|export — fix the route",
        "/fp donjons — dungeon quests for your level",
        "/fp collecte [export] — collected Forever quests",
        "/fp where — position info (debug)",
    },
}

local locale = GetLocale and GetLocale()
if type(locale) ~= "string" then locale = "frFR" end
local L = setmetatable({}, { __index = function(_, k) return fr[k] or k end })
-- Français pour frFR ; allemand et espagnol (textes courts, le reste en anglais) ; anglais ailleurs
ns.isFrench = (locale == "frFR")
ns.isEnglish = not ns.isFrench
ns.locale = locale
local verbs = {
    deDE = { ACCEPT = "Annehmen", COMPLETE = "Erledigen", TURNIN = "Abgeben", GOTO = "Gehe zu", LEVEL = "Stufe %d erreichen",
             NOTE = "Notiz", HEARTH = "Ruhestein", FLY = "Fliegen", BIND = "Ruhestein binden", STEP = "Schritt %d / %d",
             ZONES = "Zonen", ARRIVED = "Angekommen", FLIGHTPATH = "Flugpunkt", LOADED = "Guide geladen: %s",
             NEXT_SEGMENT = "Nächster Abschnitt: %s" },
    esES = { ACCEPT = "Aceptar", COMPLETE = "Completar", TURNIN = "Entregar", GOTO = "Ir a", LEVEL = "Llegar al nivel %d",
             NOTE = "Nota", HEARTH = "Piedra de hogar", FLY = "Volar", BIND = "Vincular piedra", STEP = "Paso %d / %d",
             ZONES = "Zonas", ARRIVED = "Has llegado", FLIGHTPATH = "Punto de vuelo", LOADED = "Guía cargada: %s",
             NEXT_SEGMENT = "Siguiente segmento: %s" },
}
verbs.esMX = verbs.esES
if ns.isEnglish then
    for k, v in pairs(en) do rawset(L, k, v) end
    for k, v in pairs(verbs[locale] or {}) do rawset(L, k, v) end
end
ns.L = L

---------------------------------------------------------------------------
-- ns.Tr(texte) : traduction des textes de l'interface (dictionnaire ns.EN, Locale_enUS.lua).
-- 1) correspondance exacte ; 2) texte déjà formaté : on le reconnaît grâce aux modèles
--    (« Session de %d min lancée. ») et on recompose la phrase anglaise avec les mêmes valeurs.
---------------------------------------------------------------------------
local patterns
local function toPattern(fmt)
    local out, i, n = { "^" }, 1, #fmt
    while i <= n do
        local c = fmt:sub(i, i)
        if c == "%" then
            if fmt:sub(i + 1, i + 1) == "%" then
                out[#out + 1] = "%%"; i = i + 2
            else
                local spec = fmt:match("^%%[%-%d%.]*[dsfx]", i)
                if spec then out[#out + 1] = "(.-)"; i = i + #spec
                else out[#out + 1] = "%%"; i = i + 1 end
            end
        elseif c:find("[%^%$%(%)%.%[%]%*%+%-%?]") then
            out[#out + 1] = "%" .. c; i = i + 1
        else
            out[#out + 1] = c; i = i + 1
        end
    end
    out[#out + 1] = "$"
    return table.concat(out)
end
ns.ToPattern = toPattern

-- remplit le modèle anglais avec les valeurs capturées (dans l'ordre)
local function fill(tpl, caps)
    local k = 0
    return (tpl:gsub("%%([%%%-%d%.]*[dsfx%%]?)", function(spec)
        if spec == "%" then return "%" end
        k = k + 1
        return caps[k] or ""
    end))
end

-- dictionnaire de la langue du client (allemand, espagnol), complété par l'anglais
local function dict()
    local d = (ns.locale == "deDE" and ns.DE) or ((ns.locale == "esES" or ns.locale == "esMX") and ns.ES)
    return d
end

function ns.Tr(s)
    if ns.isFrench or type(s) ~= "string" or s == "" or not ns.EN then return s end
    local d = dict()
    local e = d and d[s] or ns.EN[s]
    if e then return e end
    if not s:find("%d") and not s:find(" ", 1, true) then return s end
    if not patterns then
        patterns = {}
        for frText, enText in pairs(ns.EN) do
            if frText:find("%%[%-%d%.]*[dsfx]") then
                patterns[#patterns + 1] = { toPattern(frText), d and d[frText] or enText }
            end
        end
        table.sort(patterns, function(a, b) return #a[1] > #b[1] end)   -- le plus précis d'abord
    end
    for _, p in ipairs(patterns) do
        local caps = { s:match(p[1]) }
        if caps[1] then
            -- les valeurs capturées peuvent elles-mêmes être des textes à traduire
            for i, c in ipairs(caps) do caps[i] = (d and d[c]) or ns.EN[c] or c end
            return fill(p[2], caps)
        end
    end
    return s
end
