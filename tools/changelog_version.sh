#!/usr/bin/env bash
# Affiche la version en tête du CHANGELOG (première ligne "## vX.Y.Z[-suffixe]").
# Usage : tools/changelog_version.sh [CHANGELOG.md]
set -euo pipefail
file="${1:-CHANGELOG.md}"
version="$(grep -m1 -E '^## v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)?[[:space:]]*$' "$file" | sed -E 's/^## //; s/[[:space:]]+$//')" || true
if [[ -z "${version}" ]]; then
  echo "Aucune version « ## vX.Y.Z » trouvée en tête de ${file}" >&2
  exit 1
fi
echo "${version}"
