# Questweaver — guide de leveling 1-60 gratuit et modulaire pour WoW Forever

**Site et documentation des modules (FR/EN) : https://alapaque.github.io/quest-weaver/**

Questweaver te donne un chemin rapide et simple de 1 à 60, Horde et Alliance : quelle quête prendre, où aller, quoi tuer, où rendre. Chaque fonction est un module que tu actives ou non depuis un panneau d'options avec aperçu.

## Installation
1. Copie le dossier `Questweaver` dans le dossier `Interface/AddOns` de ton installation **Forever**.
2. Lance le jeu : le panneau d'options s'ouvre la première fois. Ensuite : `/qw config`.

## Routes
| Parcours | Départ | Quêtes |
|---|---|---|
| Humain | Elwynn → Marche de l'Ouest → Loch Modan → Carmines… | ~674 |
| Nain / Gnome | Dun Morogh → Loch Modan → Marche de l'Ouest… | ~678 |
| Elfe de la nuit | Teldrassil → Sombrivage → Orneval… | ~671 |
| Orc / Troll | Durotar → Tarides → Pins-Argentés… | ~585 |
| Tauren | Mulgore → Tarides → Pins-Argentés… | ~589 |
| Mort-vivant | Tirisfal → Pins-Argentés → Tarides… | ~586 |
| Éolide Alliance / Horde | Île de Zéphras → parcours de la faction | ~663 / ~565 |

Les nouvelles zones de Forever font partie des parcours : Shen'dralas (40-45), Rives Claires (38-44) et Mont Hyjal (56-60).

Les routes sont générées à partir de **QuestieDB (données Forever, nouveau contenu compris : base générée, corrections et traces QuestieTrace)** par `tools/gen_routes.py`. Le script simule un personnage (niveau, XP, journal de 20 quêtes, prérequis) :

- **Choix de la zone** : à chaque fois, la zone qui rapporte le plus d'XP par heure à ce niveau (quêtes prenables, quêtes du journal à y faire ou y rendre, trajet compris). Il revient dans une zone quand de nouvelles quêtes s'y débloquent au lieu de farmer sur place, passe par les capitales, et ne change de continent que si ça rapporte nettement plus.
- **Choix des quêtes** : jamais plus d'un niveau au-dessus du joueur pour une quête à objectif (deux pour une quête à livrer), monstres au plus deux niveaux au-dessus, quêtes jusqu'à six niveaux en dessous. Les quêtes de classe, de métier et de réputation sont écartées ; les quêtes élites sont marquées `group=1` et restent hors de la route sauf option « Inclure les quêtes de groupe ».
- **Données assainies** : la base Forever de Questie est une base Classic convertie, encore incomplète. Le script écarte les quêtes d'autres versions du jeu (IDs 9666-89999 non confirmés en jeu), estime les niveaux requis provisoires, complète les chaînes (suite de chaîne, ordre relevé par le collecteur) et applique les corrections manuelles de `tools/overrides.json`.
- **Bases recoupées** (`tools/cross.json`, écrit par `tools/load_cross.py`) : QuestieDB est comparée à trois autres sources libres, et en cas de désaccord la valeur la plus prudente gagne. La liste de quêtes masquées de Questie et les réponses du serveur du jeu relevées par EG Link retirent les quêtes qui ne sont pas dans Forever ; le niveau requis et la faction viennent du serveur ; les prérequis et les quêtes de classe sont complétés par la base de Polestar. Les mêmes corrections servent aux données en jeu (objets qui lancent une quête, quêtes de donjon).
- **En jeu** : si le PNJ d'une étape ne propose pas la quête, l'étape est passée et signalée ; le bouton drapeau du guide (`/qw signalements`) permet de signaler une étape à corriger.

La route s'adapte : les étapes déjà dépassées par ton niveau sont sautées, et le bon segment se charge tout seul si tu montes plus vite. Les paliers « Monte au niveau X » se valident d'eux-mêmes si tu as déjà le niveau. `tests/test_routes.py` bloque toute régression (quête prise trop haut, part de farm, quêtes d'autres versions, quête absente du jeu, niveau requis sous celui du serveur, prérequis pas encore rendu).

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
git clone https://github.com/Questie/Questie                     # liste des quêtes masquées
git clone https://github.com/JIVESCORP/eg-link-output-wowf       # réponses du serveur (EG Link)
git clone https://github.com/fitzforge/polestar                  # base forever-db de Polestar
cd tools
python3 -I load.py <QuestieDB>/data/Forever/
python3 -I load_corrections.py <QuestieDB> db.pkl db.pkl          # nouveau contenu de Forever
python3 -I load_cross.py <Questie> <eg-link-output-wowf> <polestar>/forever-db   # écrit cross.json
python3 -I gen_routes.py <QuestieDB>/data/Forever/ ../Guides     # --dry : mesure seulement
python3 -I gen_world.py ../Data/World.lua                        # maîtres, auberges, récolte
python3 -I gen_items.py ../Data/QuestItems.lua ../Data/World.lua ../Data/RareLoot.lua
python3 -I gen_links.py ../Data/QuestLinks.lua
```
Chaque génération affiche ses mesures (temps estimé jusqu'au 60, XP/h, distance, farm) et l'écart avec `tools/route_metrics.json`. Des réglages peuvent être testés sans rien écrire : `gen_routes.py … --dry GREY=7 FAR_EDGE=2`. Diagnostics : `--order` (ordre des zones), `--unused` (quêtes non faites par zone), `--why` (quêtes écartées et pourquoi).

Les rapports des joueurs (`/qw rapport`) s'analysent avec `python3 -I tools/analyze_reports.py rapports/*.txt`.
Les données sont lues comme de simples données : aucun code Lua téléchargé n'est exécuté.

## Intégrations
API publique `QuestweaverAPI`, Naowh Forever, Daylight UI, TomTom : voir [INTEGRATIONS.md](INTEGRATIONS.md).

## Contribuer
Bugs, routes des nouvelles zones, nouveaux modules : voir [CONTRIBUTING.md](CONTRIBUTING.md). Chaque push lance luacheck et les tests. Une nouvelle section `## vX.Y.Z` en tête du `CHANGELOG.md` publie automatiquement la version.

## Licence
GPLv3 (voir `LICENSE.md`). Les routes sont dérivées de [QuestieDB](https://github.com/Questie/QuestieDB), dont l'équipe autorise la réutilisation sous GPLv3. Merci à elle.

Les routes sont recoupées avec trois autres sources (`tools/cross.json`, réduit à des faits sur les quêtes : présence dans le jeu, niveaux, races, classes, prérequis) :
- [Questie](https://github.com/Questie/Questie) (GPLv3) : la liste des quêtes masquées ;
- EG Link : Data from [Efficient Games](https://efficient.games), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) ([eg-link-output-wowf](https://github.com/JIVESCORP/eg-link-output-wowf)), réduites aux niveaux, aux races et à la liste des quêtes que le serveur décrit ;
- [Polestar forever-db](https://github.com/fitzforge/polestar/tree/next/forever-db) (GPL-3.0), dont les sources sont créditées dans son fichier `NOTICE.md` (pfQuest, CMaNGOS, VMaNGOS, ForeverTDB, EG Link, QuestieDB).

Merci à ces équipes.
