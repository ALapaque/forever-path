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
        "/fp where — infos de position (debug)",
    },
}

local en = {
    NO_GUIDE = "No guide loaded. Type /fp guides to pick one.",
    GUIDE_DONE = "Guide complete! Open recommended zones (Zones button).",
    STEP = "Step %d / %d",
    ACCEPT = "Accept", COMPLETE = "Complete", TURNIN = "Turn in", GOTO = "Go to",
    LEVEL = "Reach level %d", NOTE = "Note", HEARTH = "Hearthstone", FLY = "Fly",
    ZONES = "Zones", ZONES_TITLE = "Recommended zones (lvl %d)",
    DUNGEONS_TITLE = "Dungeons for your level", UNCONFIRMED = "(levels unconfirmed)",
    YOU_ARE_HERE = "you are here",
    TOO_HIGH = "You outlevel %s. Suggested zones: %s",
    REC_ON = "Recorder ON — your quests are logged to build a guide.",
    REC_OFF = "Recorder off.", REC_CLEARED = "Recording cleared.",
    EXPORT_TITLE = "Guide export (Ctrl+A, Ctrl+C)",
    LOADED = "Guide loaded: %s", UNKNOWN_GUIDE = "Unknown guide: %s",
    NEXT_SEGMENT = "Next segment: %s", ARRIVED = "Arrived", FLIGHTPATH = "Flight path",
}

local locale = GetLocale and GetLocale() or "frFR"
local L = setmetatable({}, { __index = function(_, k) return fr[k] or k end })
if locale == "enUS" or locale == "enGB" then
    for k, v in pairs(en) do rawset(L, k, v) end
end
ns.L = L
ns.isFrench = (locale == "frFR")
