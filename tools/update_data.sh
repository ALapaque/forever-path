#!/usr/bin/env bash
# Met à jour toutes les données de quêtes et régénère les routes et les fichiers Data/.
#
# Récupère (ou met à jour) les quatre sources dans un dossier de cache, puis lance la chaîne
# complète : QuestieDB -> recoupement (Questie, EG Link, Polestar) -> collectes des joueurs ->
# routes, monde, objets, liens, quêtes de classe.
#
# Usage : tools/update_data.sh [dossier de cache]     (par défaut : .sources/ à la racine du dépôt)
# Ensuite : tools/run_tests.sh puis python3 -I tools/data_release.py
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="${1:-${FP_SOURCES:-$ROOT/.sources}}"
mkdir -p "$CACHE"

fetch() {   # fetch <dossier> <url>
  local dir="$CACHE/$1"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" fetch --quiet --depth 1 origin HEAD
    git -C "$dir" reset --quiet --hard FETCH_HEAD
  else
    git clone --quiet --depth 1 "$2" "$dir"
  fi
  echo "$1 : $(git -C "$dir" log -1 --format='%h %ad' --date=short)"
}
fetch QuestieDB https://github.com/Questie/QuestieDB.git
fetch Questie https://github.com/Questie/Questie.git
fetch eg-link-output-wowf https://github.com/JIVESCORP/eg-link-output-wowf.git
fetch polestar https://github.com/fitzforge/polestar.git

cd "$ROOT/tools"
export FP_DB="$CACHE/db_full.pkl"
export FP_QUESTIEDB="$CACHE/QuestieDB"
python3 -I load.py "$CACHE/QuestieDB/data/Forever/"
python3 -I load_corrections.py "$CACHE/QuestieDB" db.pkl "$FP_DB"
python3 -I load_cross.py "$CACHE/Questie" "$CACHE/eg-link-output-wowf" "$CACHE/polestar/forever-db"

# collectes des joueurs déposées dans Collected/ (quêtes nouvelles, niveaux de prise, quêtes pas proposées)
cd "$ROOT"
if compgen -G "Collected/*.txt" > /dev/null; then
  python3 -I tools/merge_collected.py Collected/*.txt --out tools/collected.json
fi

python3 -I tools/gen_routes.py "$CACHE/QuestieDB/data/Forever/" Guides
python3 -I tools/gen_world.py Data/World.lua
python3 -I tools/gen_items.py Data/QuestItems.lua Data/World.lua Data/RareLoot.lua
python3 -I tools/gen_links.py Data/QuestLinks.lua
python3 -I tools/gen_class.py Data/ClassQuests.lua
echo "Données régénérées."
