# Intégrations

## API publique : `ForeverPathAPI`

Disponible dès le chargement de ForeverPath (dépendance optionnelle : `## OptionalDeps: ForeverPath`).

```lua
if ForeverPathAPI and ForeverPathAPI.version >= 1 then
    -- Destination de l'étape en cours du guide
    local d = ForeverPathAPI.GetDestination()
    -- d = { mapID = 1429, x = 0.482, y = 0.429, title = "Prendre : Une menace intérieure",
    --       questID = 783, type = "accept" }   (nil si l'étape n'a pas de position)

    -- Itinéraire calculé par ForeverPath (si le module Itinéraires est actif)
    local j = ForeverPathAPI.GetJourney()
    -- j = { total = 312, legs = { { mode = "walk", time = 40 }, { mode = "flight", time = 210, toName = "..." }, ... } }

    -- Être prévenu des changements
    ForeverPathAPI.RegisterCallback("DestinationChanged", function(dest) ... end)
    ForeverPathAPI.RegisterCallback("JourneyChanged", function(journey) ... end)
end

-- Ou via EventRegistry (sans dépendre de l'ordre de chargement) :
EventRegistry:RegisterCallback("ForeverPath.DestinationChanged", function(_, dest) ... end, owner)
```

Modes d'étape : `walk`, `flight`, `boat`, `zeppelin`, `tram`, `hearth`.

## Naowh Forever (Journeys)

ForeverPath cohabite avec Journeys. Si un autre addon pose son propre waypoint, ForeverPath arrête de déplacer le point jusqu'à l'étape suivante (option « Laisser un autre addon guider »). La flèche et le guidage 3D de ForeverPath suivent alors le point posé par Naowh.

Pour que Journeys trace la route vers les étapes de ForeverPath comme il le fait pour RestedXP, il faut une option « Suivre ForeverPath » côté Naowh. Message à proposer à l'équipe (Discord ou ticket GitHub) :

> Bonjour ! ForeverPath est un guide de leveling 1-60 gratuit et open source (GPLv3) pour WoW Forever : https://github.com/ALapaque/forever-path.
> Journeys suit déjà les étapes de RestedXP. Serait-il possible d'ajouter « Follow ForeverPath » dans le groupe Guides du Waypoint Pin ?
> ForeverPath expose une API stable, `ForeverPathAPI` (version 1) :
> - `ForeverPathAPI.GetDestination()` → `{ mapID, x, y, title, questID, type }` ;
> - `ForeverPathAPI.RegisterCallback("DestinationChanged", fn)`, ou `EventRegistry` « ForeverPath.DestinationChanged ».
>
> Quand l'option est active, nous laissons Journeys poser le waypoint : ForeverPath ne le déplace plus tant que Journeys guide.
> Merci pour tout le travail sur Naowh Forever !

## Daylight UI

ForeverPath s'enregistre comme plugin (API 1.4) et propose un thème « Daylight UI » qui suit les couleurs et la police de DUI en direct. `/dui path` ouvre les options. Voir `UI/DaylightUI.lua`.

## TomTom

Le module « Point sur la carte » pose aussi un point TomTom si TomTom est installé (option).
