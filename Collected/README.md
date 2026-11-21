# Quêtes collectées en jeu

QuestieDB intègre déjà une bonne partie du nouveau contenu de WoW Forever (environ 1 650 quêtes, via ses corrections et les traces QuestieTrace), mais pas tout. Le module **Collecteur** de Questweaver le note pendant que tu joues : donneur, rendu, objectifs, niveau, XP, monstres. Rien n'est envoyé automatiquement.

**Partager ta collecte** : en jeu, `/qw collecte export`, copie le texte, puis propose-le ici dans un fichier `pseudo-date.txt` (pull request) ou dans une issue GitHub.

**Quêtes pas proposées** : l'export contient aussi les quêtes de ta route que leur PNJ ne proposait pas (lignes `X` : quête, PNJ, niveau, race, classe, et ce qui a fini par la débloquer). Trois joueurs qui signalent la même quête la font retirer des routes ; deux suffisent pour relever son niveau requis ou ajouter un prérequis.

**Fusion automatique** : chaque semaine, une tâche planifiée fusionne les fichiers de ce dossier, met à jour les sources et régénère les routes (`tools/update_data.sh`).

**Fusionner** (mainteneurs) :
```
FP_DB=<db.pkl> python3 -I tools/merge_collected.py Collected/*.txt --out tools/collected.json
python3 -I tools/gen_routes.py <QuestieDB>/data/Forever/ Guides
```
Les quêtes déjà connues de QuestieDB sont ignorées. Les positions sont médianes sur tous les joueurs, et l'XP n'est gardée que pour les rendus faits au bon niveau. Les quêtes élites ou de groupe restent hors des routes solo. Le générateur affiche les quêtes collectées sur des cartes qui ne sont pas encore dans les parcours (nouvelles zones à ajouter).
