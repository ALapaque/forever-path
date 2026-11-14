# Bibliothèque de routes partagées

Routes enregistrées par les joueurs (nouvelles zones de WoW Forever, variantes, corrections). Chaque fichier `.txt` est une route au format DSL de ForeverPath, avec des en-têtes :

```
# nom: Rives Claires 36-40
# niveaux: 36-40
# faction: Horde
M 2210
A 90012 @41.2,55.0 id=123456
...
```

**Utiliser une route** : ouvre le fichier, copie tout son contenu, puis en jeu tape `/fp importer`, colle et clique sur Importer. `/fp routes` liste tes routes importées, `/fp load <id>` en charge une.

**Partager une route** : enregistre-la en jouant (module Enregistreur, `/fp rec on` puis `/fp export`) ou corrige une route existante (`/fp edit …` puis `/fp edit export`). Ensuite, propose le fichier ici (pull request) ou dans une issue.
