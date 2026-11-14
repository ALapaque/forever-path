"""Signale les caractères absents des polices du jeu (affichés en carrés vides en jeu).
Autorisés : Latin-1 + ponctuation française courante. Usage : python3 tools/check_glyphs.py"""
import glob, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OK = set("—–’«»œŒ•·…")  # présents dans les polices FR du jeu
bad = 0
for f in sorted(glob.glob(os.path.join(ROOT, "**", "*.lua"), recursive=True)):
    rel = os.path.relpath(f, ROOT)
    if rel.startswith(("tests", "tools", ".release")):
        continue
    for i, line in enumerate(open(f, encoding="utf-8"), 1):
        if line.lstrip().startswith("--"):
            continue
        chars = {c for c in line if ord(c) > 255 and c not in OK}
        if chars:
            bad += 1
            print("%s:%d: caractères sans glyphe : %s" % (rel, i, " ".join(sorted(chars))))
sys.exit(1 if bad else 0)
