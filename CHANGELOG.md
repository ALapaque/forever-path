# ForeverPath

## v0.2.0-beta13

- **Bibliothèque de routes** : `/fp importer` pour coller une route partagée (nouvelles zones de Forever, variantes). Elle est gardée pour tous tes personnages. `/fp routes` pour la liste. Les routes partagées vivent dans le dossier `Routes/` du dépôt.
- **Éditeur de route en jeu** : `/fp edit pos` (l'étape prend ta position), `suppr`, `note <texte>`, `annuler`, `export` (route corrigée à partager). Les corrections sont réappliquées à chaque connexion.
- **Rares sur la carte** : 327 monstres rares (QuestieDB) avec leur niveau, filtrés autour du tien.
- **Métiers d'appoint** : secourisme (activé par défaut), cuisine et pêche. Quand un maître est tout près et que tu n'as pas le métier, un détour est proposé.
- **Bouton de la minimap** (déplaçable) et données pour les barres d'infos (LibDataBroker).
- **Objectif monture** : à partir du niveau 30, ton or comparé au prix de la monture (réglable), avec ton gain d'or par heure.
- **Rappel de talents** : points à dépenser, bouton vers la fenêtre des talents. Pas de conseil de répartition tant que les arbres de Forever ne sont pas documentés.

## v0.2.0-beta12

- **Mode Hardcore** (route prudente, désactivé par défaut) : les quêtes dont les monstres ont 3 niveaux ou plus au-dessus de toi au moment de les faire (environ 100 à 140 étapes par parcours, repérées à la génération) sont sautées : prise, objectif et rendu. Alerte en entrant dans une zone trop haute.
- **Rattrapage** : si tu as pris de l'avance, les quêtes devenues trop basses ne sont plus proposées (écart réglable).
- **Quêtes de donjon** : quand ton niveau colle à un donjon, le guide indique ses quêtes à prendre avant d'y aller, avec un bouton vers le donneur le plus proche. `/fp donjons` affiche la liste. Données QuestieDB : 153 quêtes de donjons Classic. Les nouveaux donjons de Forever viendront par l'enregistreur.
- **Écran de splits** (speedrun, désactivé par défaut) : chrono du segment, écart avec ton meilleur temps et derniers segments, façon LiveSplit.

## v0.2.0-beta11

### Gagner du temps sur la route
- **Pierre de foyer planifiée** : les routes lient ta pierre à l'auberge des grands relais (par exemple La Croisée pour la Horde), puis l'utilisent quand elle fait gagner du temps, par exemple pour revenir rendre des quêtes. L'étape « Lier » se valide toute seule, et l'étape « Foyer » à l'arrivée.
- **Vols automatiques** : chez le maître de vol, la carte des vols s'ouvre, et le vol qui rapproche le plus de l'étape est pris tout seul s'il fait gagner du temps. Maj pour choisir toi-même.
- **Dialogues accélérés** : option de dialogue choisie toute seule avec le PNJ de l'étape (option unique, auberge pour lier la pierre, confirmation comprise).
- **Achats automatiques** (désactivé par défaut) : nourriture, boisson (classes à mana) et munitions (chasseurs), meilleur article de ton niveau, avec un budget.
- **Journal de quêtes plein** : alerte avant la limite, suggestions de quêtes à abandonner (hors route, les plus basses d'abord) et bouton pour le faire.

## v0.2.0-beta10

- **Anglais** : toute l'interface (modules, réglages, messages, guides et noms de zones) est traduite pour les clients non francophones. Une vérification automatique bloque toute version avec un texte non traduit.
- **Multi-personnages** : un personnage transféré ou qui a changé de faction repart automatiquement du bon segment.
- Fiche CurseForge / Wago prête (LISTING.md), README à jour.

## v0.2.0-beta9

### Groupe et communauté
- **Progression du groupe** : chaque membre est affiché avec son niveau et son avance ou son retard en étapes. Le guide signale qui n'a pas la quête de l'étape, avec un bouton pour la partager.
- **Quêtes de groupe** : les quêtes de groupe ou élites sont signalées dans le guide, avec le nombre de joueurs conseillé.
- **Chrono** : temps de jeu par niveau, comparé à ton record (tous personnages du même parcours). `/fp chrono` affiche le tableau par tranche de 10 niveaux, à partager.
- **Rapport de parcours** : `/fp rapport` produit un rapport anonyme (temps par segment, morts, étapes passées) à coller sur GitHub ou Discord. `tools/analyze_reports.py` en tire les segments les plus lents ou mortels et les étapes souvent passées, pour corriger la route avec de vraies parties.

## v0.2.0-beta8

### Confort de jeu
- **Maître de classe** : quand de nouveaux sorts t'attendent, un bouton (livre) dans le guide t'amène au maître de ta classe le plus proche. La flèche, le guidage 3D et l'itinéraire font le détour, puis reprennent le guide.
- **Session de jeu** : bouton horloge ou `/fp session 45`. ForeverPath estime jusqu'où tu iras et propose de t'arrêter juste après un rendu de quête. À la fin, il te guide vers l'auberge la plus proche.
- **Marchand automatique** : vend la camelote (objets gris) et répare l'équipement. Maj pour ne rien faire.
- **Récolte sur la route** : pour les mineurs et herboristes, la carte du monde montre les filons et les herbes accessibles à ton niveau de métier, seulement le long du trajet des prochaines étapes.
- **Conseil de récompense** : utilise Pawn s'il est installé (tes poids de statistiques). Option pour choisir tout seul quand le choix est évident.
- **Détours** : tout détour (maître, auberge) s'affiche dans le guide avec un bouton pour l'annuler.

### Route
- Générateur mesuré (`tools/route_metrics.json`) : temps estimé jusqu'au 60, XP/h, distance, farm. Les réglages ont été optimisés à partir de ces mesures : environ 2 h de moins estimées par parcours, plus de quêtes, moins de farm.
- Données du monde (maîtres de classe, aubergistes, filons, herbes) générées depuis QuestieDB (`tools/gen_world.py`).

## v0.2.0-beta7

- **Carte plus lisible** : les étapes au même endroit (ou qui se chevauchent à ce niveau de zoom) sont regroupées en une seule pastille, par exemple « 2-4 ». Le survol liste toutes les étapes regroupées avec leur numéro et leur couleur. L'étape en cours est plus grande, entourée de blanc et toujours au-dessus des autres.

## v0.2.0-beta6

- **Correctif** : la fenêtre du guide pouvait s'afficher sans aucun texte (erreur « Invalid font height »). Les polices de l'addon partent maintenant des polices Blizzard, avec une taille de secours si une interface renvoie une taille nulle.

## v0.2.0-beta5

- **Terrain (moteur)** : les itinéraires savent contourner les falaises, trous et lacs grâce à une grille des zones praticables, chargée à la demande depuis l'addon `ForeverPath_Terrain`. Le calcul est étalé sur plusieurs images pour ne jamais figer le jeu. Les données des continents arrivent dans une prochaine version : d'ici là, rien ne change en jeu (lignes droites en orange, chemins appris en vert). Voir TERRAIN.md.

## v0.2.0-beta4

### Nouveau : Itinéraires
Le chemin le plus rapide vers l'étape, guidé virage par virage.
- **Chemins appris** : en marchant, à cheval ou à la nage (hors combat, hors instance, hors vol), ForeverPath note les chemins que tu empruntes réellement et les relie en réseau. Les chemins souvent pris sont préférés.
- **Transports** : vols (appris en ouvrant la carte d'un maître de vol), bateaux, zeppelins et tram (positions des quais estimées), pierre de foyer (destination apprise en l'utilisant).
- **Calcul** du trajet le plus rapide (A*) en combinant marche, vols, bateaux et foyer. Sur un terrain encore inconnu, le trajet passe en ligne droite et l'affiche en orange.
- **Guidage virage par virage** : le waypoint du jeu avance de virage en virage, donc la flèche et le guidage 3D suivent le chemin.
- **Affichage** : détail du trajet dans le guide (étapes et durées), tracé coloré sur la carte du monde et sur la minimap (vert : connu, orange : inconnu, bleu : vol...).
- **Partage** : `/fp paths export` / `import` pour échanger des chemins, `/fp paths here` pour oublier un passage impraticable, `/fp paths reset`.
- **Cohabitation** avec Naowh Forever : si un autre addon pose son propre point, ForeverPath lui laisse la main.
- **API publique** `ForeverPathAPI` (destination, itinéraire, événements) pour Naowh, Daylight UI et les autres addons : voir INTEGRATIONS.md.

## v0.2.0-beta3

### Nouveau
- **Guidage 3D dans le monde** : un faisceau lumineux posé sur l'objectif, avec l'icône de l'étape (prendre / faire / rendre) et la distance. Quand l'objectif est hors champ, une flèche au bord de l'écran indique de quel côté tourner. Il s'appuie sur le cadre de navigation du jeu (`C_Navigation`), le même que le marqueur de Blizzard, qu'on peut masquer.
- **Plugin Daylight UI** : ForeverPath s'enregistre auprès de Daylight UI. Le thème « Daylight UI » reprend en direct sa couleur d'accent, ses couleurs de texte et sa police, et suit tes changements de style. Il est adopté automatiquement la première fois que Daylight UI est détecté. `/dui path` ouvre les options de ForeverPath.
- `/fp where` affiche aussi l'état du pont Daylight UI.

## v0.2.0-beta2

Retours du premier test en jeu (merci Hazghard).

### Corrigé
- **« ForeverPath a été bloqué »** en prenant une quête : le marqueur automatique utilisait `SetRaidTarget`, devenu une action réservée à l'interface de Blizzard. Le marquage passe désormais par un **clic droit sur le bouton « Cibler »**.
- **Petits carrés vides** (bouton d'enregistrement, flèche devant les étapes suivantes) : ces symboles n'existent pas dans la police du jeu. Ils sont remplacés par des icônes, et la CI vérifie maintenant les caractères.
- La **tête de mort restait affichée** sur un monstre dont l'objectif était déjà rempli (ex. 8/8) : chaque monstre est maintenant vérifié séparément.
- La flèche et le point sur la carte **ne disparaissent plus** sur les étapes sans position (notes, paliers de niveau) : ils visent la prochaine étape positionnée.

### Nouveau
- **Apparence** : 4 thèmes (Sombre doré, Doux façon Daylight UI, Blizzard, Minimal), choix de la police (polices du jeu et LibSharedMedia) et de la taille du texte. Le thème « Doux » est choisi d'office si Daylight UI est installé.
- **Barre d'actions** : les boutons « Cibler » et « Objet de quête » sont regroupés dans un seul cadre déplaçable (orientation, taille, espacement réglables).
- **Fenêtre du guide redimensionnable** par le coin en bas à droite.
- **Bouton épingle** dans le guide : replace le point sur la carte et la minimap (clic droit : ouvre aussi la carte).
- **Tracé de la route sur la carte du monde** : pointillés depuis ta position et prochaines étapes numérotées.
- Infobulles sur tous les boutons.

## v0.2.0-beta1

Première bêta publique.

- 6 routes de leveling 1-60 (Humain, Nain/Gnome, Elfe de la nuit, Orc/Troll, Tauren, Mort-vivant), générées à partir de QuestieDB (Forever). Route de départ minimale pour les Éolides.
- La route s'adapte : quêtes déjà faites ou dépassées sautées automatiquement, bonne portion de route chargée selon le niveau.
- 17 modules activables depuis le panneau d'options (`/fp config`), avec aperçu : fenêtre du guide, objectifs en direct, flèche, waypoint, repérage sur les barres de nom, marqueur automatique, bouton Cibler, objet de quête, prise et rendu automatiques, conseil de récompense, compteur d'XP, rappels, progression du groupe, alertes Hardcore, aperçu 3D du PNJ, enregistreur de route.
- Zones et donjons conseillés, y compris les nouveautés de Forever.

### Limites connues
- Les quêtes ajoutées par Forever (nouvelles zones, nouveaux donjons, Île de Zéphras) ne sont pas encore dans les routes.
- Le nom de race interne des Éolides est supposé. Signale-le si la route Éolide ne se charge pas.
