# Bibliothèque de routes partagées

Routes enregistrées par les joueurs (nouvelles zones de WoW Forever, variantes, corrections). Chaque fichier `.txt` est une route au format DSL de Questweaver, avec des en-têtes :

```
# nom: Rives Claires 36-40
# niveaux: 36-40
# faction: Horde
M 2210
A 90012 @41.2,55.0 id=123456
...
```

**Utiliser une route** : ouvre le fichier, copie tout son contenu, puis en jeu tape `/qw importer`, colle et clique sur Importer. `/qw routes` liste tes routes importées, `/qw load <id>` en charge une.

**Partager une route** : enregistre-la en jouant (module Enregistreur, `/qw rec on` puis `/qw export`) ou corrige une route existante (`/qw edit …` puis `/qw edit export`). Ensuite, propose le fichier ici (pull request) ou dans une issue.
