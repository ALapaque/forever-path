local _, ns = ...

-- Français par défaut, anglais pour les clients enUS/enGB.
local fr = {
    ADDON = "Questweaver",
    NO_GUIDE = "Aucun guide chargé. Tape /qw guides pour en choisir un.",
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
        "/qw — afficher/masquer",
        "/qw next | prev | skip — naviguer",
        "/qw zones — zones recommandées",
        "/qw guides — liste des guides",
        "/qw load <id> — charger un guide",
        "/qw rec on|off|clear — enregistreur de quêtes",
        "/qw export — exporter l'enregistrement",
        "/qw auto — activer/désactiver l'auto-accept/rendu",
        "/qw config — panneau d'options (modules, aperçus)",
        "/qw lock — verrouiller les fenêtres",
        "/qw paths [export|import|reset] — chemins appris (itinéraires)",
        "/qw session [minutes|stop] — session de jeu",
        "/qw chrono — temps par niveau",
        "/qw rapport — rapport de parcours anonyme",
        "/qw profil [nom|export|import] — profils de réglages",
        "/qw bug — rapport de bug à copier",
        "/qw importer | routes — bibliothèque de routes",
        "/qw edit pos|suppr|note|export — corriger la route",
        "/qw donjons — quêtes de donjon à ton niveau",
        "/qw collecte [export] — quêtes de Forever collectées",
        "/qw where — infos de position (debug)",
    },
}

local en = {
    NO_GUIDE = "No guide loaded. Type /qw guides to pick one.",
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
        "/qw — show/hide",
        "/qw next | prev | skip — navigate",
        "/qw zones — recommended zones",
        "/qw guides — list guides",
        "/qw load <id> — load a guide",
        "/qw rec on|off|clear — quest recorder",
        "/qw export — export the recording",
        "/qw auto — toggle auto accept/turn-in",
        "/qw config — options panel (modules, previews)",
        "/qw lock — lock windows",
        "/qw paths [export|import|reset] — learned paths (journeys)",
        "/qw session [minutes|stop] — play session",
        "/qw chrono — time per level",
        "/qw rapport — anonymous run report",
        "/qw profil [name|export|import] — settings profiles",
        "/qw bug — bug report to copy",
        "/qw importer | routes — route library",
        "/qw edit pos|suppr|note|export — fix the route",
        "/qw donjons — dungeon quests for your level",
        "/qw collecte [export] — collected Forever quests",
        "/qw where — position info (debug)",
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
