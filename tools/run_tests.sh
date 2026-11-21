#!/usr/bin/env bash
# Lance en local les mêmes étapes que .github/workflows/ci.yml (sauf luacheck, vérifié par la CI).
# À garder identique à la liste de ci.yml. Usage : tools/run_tests.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 -c "import lupa" 2>/dev/null || pip install --quiet --break-system-packages lupa 2>/dev/null || pip install --quiet lupa
python3 tests/harness.py
python3 tests/harness.py . tests/test_daylight.lua
python3 tests/harness.py . tests/test_journeys.lua
mkdir -p /tmp/fakeadt/Kalimdor
python3 tests/make_fake_adt.py /tmp/fakeadt/Kalimdor/Kalimdor_32_32.adt
python3 tools/bake_terrain.py --out /tmp/fp_terrain --map Kalimdor=1 /tmp/fakeadt/Kalimdor
for t in terrain comfort social travel hardcore library profiles collector questitems stepcare questlinks perf classquests; do
  python3 tests/harness.py . "tests/test_$t.lua"
done
python3 tests/test_routes.py
python3 tests/test_merge.py
FP_LOCALE=deDE python3 tests/harness.py . tests/test_locale_de.lua
FP_LOCALE=enUS python3 tests/harness.py . tests/test_locale.lua
python3 tools/check_locale.py .
python3 tools/check_glyphs.py
echo "TOUS LES TESTS PASSENT"
