# Quêtes collectées en jeu

Le nouveau contenu de WoW Forever (plus de 1 000 nouvelles quêtes) n'est pas encore dans QuestieDB. Le module **Collecteur** de ForeverPath le note pendant que tu joues : donneur, rendu, objectifs, niveau, XP, monstres. Rien n'est envoyé automatiquement.

**Partager ta collecte** : en jeu, `/fp collecte export`, copie le texte, puis propose-le ici dans un fichier `pseudo-date.txt` (pull request) ou dans une issue GitHub.

**Fusionner** (mainteneurs) :
```
FP_DB=<db.pkl> python3 -I tools/merge_collected.py Collected/*.txt --out tools/collected.json
python3 -I tools/gen_routes.py <QuestieDB>/data/Forever/ Guides
```
Les quêtes déjà connues de QuestieDB sont ignorées. Les positions sont médianes sur tous les joueurs, et l'XP n'est gardée que pour les rendus faits au bon niveau. Les quêtes élites ou de groupe restent hors des routes solo. Le générateur affiche les quêtes collectées sur des cartes qui ne sont pas encore dans les parcours (nouvelles zones à ajouter).
