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
assert d["pre"]["20002"] == [20001], "ordre de déblocage relevé en jeu"
assert 79192 in d["seen"] and 20001 in d["seen"], "quêtes vues en jeu (confirme les IDs partagés avec d'autres versions)"
no = d["notOffered"]
assert no["30001"]["reports"] == 2 and not no["30001"]["offered"] and no["30001"]["maxLvl"] == 25, no["30001"]
assert no["30001"]["races"] == ["Orc", "Troll"], "races des personnages à qui la quête n'était pas proposée"
assert no["30002"]["offeredAt"] == 33, "niveau auquel la quête a fini par être proposée"
assert no["30003"]["after"] == 30004 and no["30003"]["afterReports"] == 2, "quête rendue juste avant : prérequis probable"
if len(files) == 3:
    assert d["acc"]["95141"] == 37, "plus bas niveau de prise relevé en jeu"
    assert q["reports"] == 3, "l'export du jeu est relu par l'outil"
    assert "20010" in d["quests"]
print("ok - fusion des collectes (%d fichiers)" % len(files))
print("ALL TESTS PASSED")
