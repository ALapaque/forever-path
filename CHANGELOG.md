# ForeverPath

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
