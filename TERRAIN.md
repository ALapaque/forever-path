# Données de terrain (itinéraires qui contournent falaises et lacs)

ForeverPath peut charger une grille des zones praticables : pentes trop raides, trous dans le terrain et lave sont infranchissables, l'eau est plus lente. Les itinéraires remplacent alors leurs lignes droites « à risque » par un chemin qui contourne les obstacles.

Les données vivent dans un second addon, `ForeverPath_Terrain`, chargé à la demande (hors combat) au premier itinéraire. Il est livré dans le même zip que ForeverPath.

Depuis la v1.0.0, Kalimdor (continent 1) et les Royaumes de l'Est (continent 0) sont inclus. Aperçus : `media/preview_Kalimdor.png`, `media/preview_Azeroth.png` (vert praticable, rouge bloqué, bleu eau).

## Produire les données

1. **Export** avec [wow.export](https://github.com/Kruithne/wow.export) (MIT) :
   - Open Local Installation → dossier `World of Warcraft` → **World of Warcraft Forever** ;
   - onglet **Maps** → choisir la carte (Kalimdor, puis Eastern Kingdoms / Azeroth) ;
   - survoler la carte, **Ctrl+A** (toutes les tuiles), menu d'export → **Export Raw**.
2. **Cuisson** : seuls les fichiers « racine » `Carte_xx_yy.adt` sont lus (pas `_obj`, `_tex` ni `_lod`).
   ```
   python3 tools/bake_terrain.py --out ForeverPath_Terrain --preview \
       --map Kalimdor=1 <export>/maps/Kalimdor \
       --map Azeroth=0  <export>/maps/Azeroth
   ```
   `--map Nom=continent` : le numéro est l'identifiant de continent du jeu (0 = Royaumes de l'Est, 1 = Kalimdor). `--preview` écrit une image de contrôle par continent (vert = sol, bleu = eau, rouge = infranchissable).
3. Vérifier les images, puis publier : les fichiers `ForeverPath_Terrain/Data_<continent>.lua` sont versionnés dans le dépôt.

## Format

Grille de 8,33 yards (4 × 4 cases par morceau de terrain, 64 × 64 par tuile ADT). Chaque tuile est une chaîne RLE : une lettre par série (`a` bloqué, `b` sol, `c` eau) suivie de la longueur sur 2 caractères en base 62.

Une case est bloquée si au moins 2 de ses 4 « quads » de terrain dépassent 50° de pente, sont troués, ou couverts de lave ou de slime. Elle est en eau si au moins 2 quads ont plus de 1,5 yard d'eau. Les bâtiments et le décor (arbres, rochers) ne sont pas encore pris en compte.

## Limites connues
- Les bâtiments (WMO) et le décor (M2) ne sont pas lus : un chemin peut passer à travers une maison. Les chemins appris en jouant compensent.
- Les cases sans données (tuile non exportée) sont considérées praticables.
