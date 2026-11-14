"""Fusion des collectes : fichiers d'exemple + export produit par le test Lua (si présent)."""
import json, os, subprocess, sys
files = ["tests/fixtures/collect_a.txt", "tests/fixtures/collect_b.txt"]
if os.path.exists("/tmp/fp_collect_export.txt"):
    files.append("/tmp/fp_collect_export.txt")
subprocess.run([sys.executable, "-I", "tools/merge_collected.py", *files, "--out", "/tmp/fp_collected.json"], check=True)
d = json.load(open("/tmp/fp_collected.json", encoding="utf-8"))
q = d["quests"]["20001"]
assert q["lvl"] == 8 and q["giverNpc"] == 99001, q
assert q["xp"] == 650, "l'XP d'un rendu trop haut niveau est ignorée"
assert q["giver"]["map"] == 1411 and 52 <= q["giver"]["x"] <= 52.3, q["giver"]
assert q["objective"]["x"] < 60, "position aberrante écartée par la médiane"
assert q["mobs"][0] == 3098
assert d["quests"]["20002"]["elite"] is True
if len(files) == 3:
    assert q["reports"] == 3, "l'export du jeu est relu par l'outil"
    assert "20010" in d["quests"]
print("ok - fusion des collectes (%d fichiers)" % len(files))
print("ALL TESTS PASSED")
