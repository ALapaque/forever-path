# Intégrations

## API publique : `QuestweaverAPI`

Disponible dès le chargement de Questweaver (dépendance optionnelle : `## OptionalDeps: Questweaver`).

```lua
if QuestweaverAPI and QuestweaverAPI.version >= 1 then
    -- Destination de l'étape en cours du guide
    local d = QuestweaverAPI.GetDestination()
    -- d = { mapID = 1429, x = 0.482, y = 0.429, title = "Prendre : Une menace intérieure",
    --       questID = 783, type = "accept" }   (nil si l'étape n'a pas de position)

    -- Itinéraire calculé par Questweaver (si le module Itinéraires est actif)
    local j = QuestweaverAPI.GetJourney()
    -- j = { total = 312, legs = { { mode = "walk", time = 40 }, { mode = "flight", time = 210, toName = "..." }, ... } }

    -- Être prévenu des changements
    QuestweaverAPI.RegisterCallback("DestinationChanged", function(dest) ... end)
    QuestweaverAPI.RegisterCallback("JourneyChanged", function(journey) ... end)
end

-- Ou via EventRegistry (sans dépendre de l'ordre de chargement) :
EventRegistry:RegisterCallback("Questweaver.DestinationChanged", function(_, dest) ... end, owner)
```

Modes d'étape : `walk`, `flight`, `boat`, `zeppelin`, `tram`, `hearth`.

## Naowh Forever (Journeys)

Questweaver cohabite avec Journeys. Si un autre addon pose son propre waypoint, Questweaver arrête de déplacer le point jusqu'à l'étape suivante (option « Laisser un autre addon guider »). La flèche et le guidage 3D de Questweaver suivent alors le point posé par Naowh.

Pour que Journeys trace la route vers les étapes de Questweaver comme il le fait pour RestedXP, il faut une option « Suivre Questweaver » côté Naowh. Message à proposer à l'équipe (Discord ou ticket GitHub) :

> Bonjour ! Questweaver est un guide de leveling 1-60 gratuit et open source (GPLv3) pour WoW Forever : https://github.com/ALapaque/quest-weaver.
> Journeys suit déjà les étapes de RestedXP. Serait-il possible d'ajouter « Follow Questweaver » dans le groupe Guides du Waypoint Pin ?
> Questweaver expose une API stable, `QuestweaverAPI` (version 1) :
> - `QuestweaverAPI.GetDestination()` → `{ mapID, x, y, title, questID, type }` ;
> - `QuestweaverAPI.RegisterCallback("DestinationChanged", fn)`, ou `EventRegistry` « Questweaver.DestinationChanged ».
>
> Quand l'option est active, nous laissons Journeys poser le waypoint : Questweaver ne le déplace plus tant que Journeys guide.
> Merci pour tout le travail sur Naowh Forever !

## Daylight UI

Questweaver s'enregistre comme plugin (API 1.4) et propose un thème « Daylight UI » qui suit les couleurs et la police de DUI en direct. `/dui path` ouvre les options. Voir `UI/DaylightUI.lua`.

## TomTom

Le module « Point sur la carte » pose aussi un point TomTom si TomTom est installé (option).
