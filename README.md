# ForeverPath — guide de leveling 1-60 gratuit et modulaire pour WoW Forever

ForeverPath te donne un chemin rapide et simple de 1 à 60, Horde et Alliance : quelle quête prendre, où aller, quoi tuer, où rendre. Chaque fonction est un module que tu actives ou non depuis un panneau d'options avec aperçu.

## Installation
1. Copie le dossier `ForeverPath` dans le dossier `Interface/AddOns` de ton installation **Forever**.
2. Lance le jeu : le panneau d'options s'ouvre la première fois. Ensuite : `/fp config`.

## Routes
| Parcours | Départ | Quêtes |
|---|---|---|
| Humain | Elwynn → Marche de l'Ouest → Loch Modan → Carmines… | ~373 |
| Nain / Gnome | Dun Morogh → Loch Modan → Marche de l'Ouest… | ~367 |
| Elfe de la nuit | Teldrassil → Sombrivage → Orneval… | ~372 |
| Orc / Troll | Durotar → Tarides → Pins-Argentés… | ~357 |
| Tauren | Mulgore → Tarides → Pins-Argentés… | ~354 |
| Mort-vivant | Tirisfal → Pins-Argentés → Tarides… | ~363 |
| Éolide | Île de Zéphras (route minimale) puis parcours de la faction | — |

Les routes sont générées à partir de **QuestieDB (données Forever)** par `tools/gen_routes.py`. Le script simule un personnage (niveau, XP, journal de 20 quêtes, prérequis) et enchaîne à chaque fois l'action la plus proche : prendre, faire, rendre. Il écarte les quêtes élites, de classe, de métier et de réputation, ainsi que les objets de quête. La route s'adapte : les étapes déjà dépassées par ton niveau sont sautées, et le bon segment se charge tout seul si tu montes plus vite. Les paliers « Monte au niveau X » se valident d'eux-mêmes si tu as déjà le niveau.

**Limite :** les quêtes ajoutées par Forever (nouvelles zones, nouveaux donjons) ne sont pas encore dans QuestieDB. Utilise l'enregistreur pour les ajouter.

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
| Flèche de direction | ✔ |
| Repérage sur les barres de nom (PNJ, monstres de l'étape, monstres de quête) | ✔ |
| Bouton « Cibler » (clic droit : poser un symbole) + raccourci | ✔ |
| Bouton d'objet de quête (+ raccourci) | ✔ |
| Prise et rendu automatiques (Maj = manuel, jamais de choix de récompense) | ✔ |
| Conseil de récompense (amélioration / meilleure revente) | ✔ |
| Compteur d'XP (XP/h, temps avant le niveau) | ✔ |
| Rappels (sorts, réparation, sacs) | ✔ |
| Progression du groupe | ✔ |
| Aperçu 3D du PNJ | — |
| Alertes de danger (Hardcore) | — |
| Enregistreur de route | — |

## Commandes
`/fp` afficher/masquer · `/fp config` options · `/fp next` / `/fp prev` · `/fp zones` · `/fp guides` · `/fp load <id>` · `/fp auto` (route automatique) · `/fp rec on|off|clear` · `/fp note <texte>` · `/fp export` · `/fp lock` · `/fp reset` · `/fp where` (debug : carte, coordonnées, npcID de la cible).

Raccourcis clavier : Options > Raccourcis > ForeverPath (étape suivante/précédente, Cibler, Objet de quête).

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
python3 -I gen_routes.py <QuestieDB>/data/Forever/ ../Guides
```
Les données sont lues comme de simples données : aucun code Lua téléchargé n'est exécuté.

## Contribuer
Bugs, routes des nouvelles zones, nouveaux modules : voir [CONTRIBUTING.md](CONTRIBUTING.md). Chaque push lance luacheck et les tests. Une nouvelle section `## vX.Y.Z` en tête du `CHANGELOG.md` publie automatiquement la version.

## Licence
GPLv3 (voir `LICENSE.md`). Les routes sont dérivées de [QuestieDB](https://github.com/Questie/QuestieDB), dont l'équipe autorise la réutilisation sous GPLv3. Merci à elle.
