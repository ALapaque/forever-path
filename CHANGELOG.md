# ForeverPath

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
