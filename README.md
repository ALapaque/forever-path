# Questweaver — guide de leveling 1-60 gratuit et modulaire pour WoW Forever

**Site et documentation des modules (FR/EN) : https://alapaque.github.io/quest-weaver/**

Questweaver te donne un chemin rapide et simple de 1 à 60, Horde et Alliance : quelle quête prendre, où aller, quoi tuer, où rendre. Chaque fonction est un module que tu actives ou non depuis un panneau d'options avec aperçu.

## Installation
1. Copie le dossier `Questweaver` dans le dossier `Interface/AddOns` de ton installation **Forever**.
2. Lance le jeu : le panneau d'options s'ouvre la première fois. Ensuite : `/qw config`.

## Routes
| Parcours | Départ | Quêtes |
|---|---|---|
| Humain | Elwynn → Marche de l'Ouest → Loch Modan → Carmines… | ~598 |
| Nain / Gnome | Dun Morogh → Loch Modan → Marche de l'Ouest… | ~599 |
| Elfe de la nuit | Teldrassil → Sombrivage → Orneval… | ~595 |
| Orc / Troll | Durotar → Tarides → Pins-Argentés… | ~463 |
| Tauren | Mulgore → Tarides → Pins-Argentés… | ~458 |
| Mort-vivant | Tirisfal → Pins-Argentés → Tarides… | ~487 |
| Éolide Alliance / Horde | Île de Zéphras → parcours de la faction | ~602 / ~488 |

Les nouvelles zones de Forever font partie des parcours : Shen'dralas (40-45), Rives Claires (38-44) et Mont Hyjal (56-60).

Les routes sont générées à partir de **QuestieDB (données Forever, nouveau contenu compris : base générée, corrections et traces QuestieTrace)** par `tools/gen_routes.py`. Le script simule un personnage (niveau, XP, journal de 20 quêtes, prérequis) et enchaîne à chaque fois l'action la plus proche : prendre, faire, rendre. Il écarte les quêtes élites, de classe, de métier et de réputation, ainsi que les objets de quête. La route s'adapte : les étapes déjà dépassées par ton niveau sont sautées, et le bon segment se charge tout seul si tu montes plus vite. Les paliers « Monte au niveau X » se valident d'eux-mêmes si tu as déjà le niveau.

Les quêtes que QuestieDB n'a pas encore sont notées en jeu par le Collecteur (`/qw collecte`, dossier `Collected/`).

## Apparence
Thèmes Sombre doré, Doux, Blizzard, Minimal, et **Daylight UI** (plugin officiel : couleurs et police de Daylight UI en direct, si installé), choix de la police (y compris LibSharedMedia) et de la taille du texte. Fenêtre du guide redimensionnable, boutons d'action regroupés dans une barre déplaçable.

## Modules (tous désactivables)
| Module | Par défaut |
|---|---|
| Fenêtre du guide (étape, suivantes, progression) | ✔ |
| Objectifs en direct | ✔ |
| Zones et donjons conseillés + alerte de niveau | ✔ |
| Point sur la carte et la minimap, bouton épingle (+ TomTom) | ✔ |
| Tracé de la route sur la carte du monde | ✔ |
| Guidage 3D dans le monde (faisceau, distance, flèche de bord d'écran) | ✔ |
| Itinéraires : chemin le plus rapide (chemins appris, vols, bateaux, foyer), virage par virage, carte et minimap | ✔ |
| Flèche de direction | ✔ |
| Repérage sur les barres de nom (PNJ, monstres de l'étape, monstres de quête) | ✔ |
| Bouton « Cibler » (clic droit : poser un symbole) + raccourci | ✔ |
| Bouton d'objet de quête (+ raccourci) | ✔ |
| Prise et rendu automatiques (Maj = manuel) | ✔ |
| Conseil de récompense (amélioration via Pawn ou niveau d'objet, meilleure revente, choix automatique en option) | ✔ |
| Compteur d'XP (XP/h, temps avant le niveau) | ✔ |
| Maître de classe : rappel et détour vers le plus proche | ✔ |
| Session de jeu : point d'arrêt conseillé, puis auberge la plus proche | ✔ |
| Marchand automatique (camelote, réparation) | ✔ |
| Récolte sur la route (mineurs, herboristes) | ✔ |
| Rappels (réparation, sacs) | ✔ |
| Progression du groupe (avance / retard, quêtes manquantes, partage) | ✔ |
| Quêtes de groupe signalées | ✔ |
| Chrono par niveau, records, rapport de parcours anonyme | ✔ |
| Aperçu 3D du PNJ | — |
| Alertes de danger | — |
| Enregistreur de route | — |

## Commandes
`/qw` afficher/masquer · `/qw config` options · `/qw next` / `/qw prev` · `/qw zones` · `/qw guides` · `/qw load <id>` · `/qw auto` (route automatique) · `/qw session [minutes|stop]` · `/qw chrono` · `/qw rapport` · `/qw rec on|off|clear` · `/qw note <texte>` · `/qw export` · `/qw lock` · `/qw reset` · `/qw paths …` · `/qw where` (debug : carte, coordonnées, npcID de la cible).

L'interface est en français, et en anglais sur tous les autres clients (`Locale_enUS.lua`, vérifié en CI par `tools/check_locale.py`).

Raccourcis clavier : Options > Raccourcis > Questweaver (étape suivante/précédente, Cibler, Objet de quête).

## Format des routes (DSL)
```
M elwynn                                  carte (clé de zone ou uiMapID)
A 783 @48.2,42.9 id=823                    prendre la quête 783 chez le PNJ 823
C 7 @49.2,36.3 mobs=6                      objectifs (monstres 6 surlignés)
T 7 @48.9,41.6 id=197                      rendre
G "Rejoins la Marche de l'Ouest" @56,47 r=40 upto=15
L 12 "Monte au niveau 12"     N "Note"     H "Foyer"     F "Vol"
Options : race=  class=  r=  upto=  danger=1  npc=  target=
```

## Régénérer les routes
```
git clone https://github.com/Questie/QuestieDB
cd tools
python3 -I load.py <QuestieDB>/data/Forever/
python3 -I load_corrections.py <QuestieDB> db.pkl db.pkl          # nouveau contenu de Forever
python3 -I gen_routes.py <QuestieDB>/data/Forever/ ../Guides     # --dry : mesure seulement
python3 -I gen_world.py ../Data/World.lua                        # maîtres, auberges, récolte
```
Chaque génération affiche ses mesures (temps estimé jusqu'au 60, XP/h, distance, farm) et l'écart avec `tools/route_metrics.json`. Des réglages peuvent être testés sans rien écrire : `gen_routes.py … --dry GREY=9 HUB=100`.

Les rapports des joueurs (`/qw rapport`) s'analysent avec `python3 -I tools/analyze_reports.py rapports/*.txt`.
Les données sont lues comme de simples données : aucun code Lua téléchargé n'est exécuté.

## Intégrations
API publique `QuestweaverAPI`, Naowh Forever, Daylight UI, TomTom : voir [INTEGRATIONS.md](INTEGRATIONS.md).

## Contribuer
Bugs, routes des nouvelles zones, nouveaux modules : voir [CONTRIBUTING.md](CONTRIBUTING.md). Chaque push lance luacheck et les tests. Une nouvelle section `## vX.Y.Z` en tête du `CHANGELOG.md` publie automatiquement la version.

## Licence
GPLv3 (voir `LICENSE.md`). Les routes sont dérivées de [QuestieDB](https://github.com/Questie/QuestieDB), dont l'équipe autorise la réutilisation sous GPLv3. Merci à elle.
