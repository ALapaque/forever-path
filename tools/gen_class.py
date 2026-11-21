"""Génère Data/ClassQuests.lua à partir de QuestieDB (Forever) : les quêtes de classe (sorts, familiers,
totems, formes, objets de classe), que les routes laissent de côté parce qu'elles sont les mêmes
pour toutes les classes.

Par classe : quête, niveau, niveau requis, races (masque), donneur et PNJ de rendu avec leur
position, prérequis, titres. En jeu, le module « Quêtes de classe » propose celles que ton
personnage peut prendre.

Usage : FP_DB=<db_full.pkl> python3 -I tools/gen_class.py <sortie Data/ClassQuests.lua>
Lit la base comme de simples données (aucun code exécuté).
"""
import json, os, pickle, sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
db = pickle.load(open(os.environ.get("FP_DB") or os.path.join(HERE, "db.pkl"), "rb"))
Q, N, O, A2M, QFR = db["Quest"], db["Npc"], db["Object"], db["area2map"], db["questFR"]
OVERRIDES = json.load(open(os.path.join(HERE, "overrides.json"), encoding="utf-8")).get("quests", {})
# quêtes qui ne sont pas dans le jeu, niveaux requis et classes : recoupés avec tools/cross.json
sys.path.insert(0, HERE)
import crosscheck  # noqa: E402
crosscheck.apply(Q, crosscheck.load(os.environ.get("FP_CROSS"), optional="--no-cross" in sys.argv))

CLASS_BITS = {1: "WARRIOR", 2: "PALADIN", 4: "HUNTER", 8: "ROGUE", 16: "PRIEST", 64: "SHAMAN", 128: "MAGE",
              256: "WARLOCK", 1024: "DRUID"}
ALL_CLASSES = sum(CLASS_BITS)
ERA_MAX, FOREVER_MIN = 9665, 90000
KNOWN_RACES = 0xFF | 2 ** 32 | 2 ** 33

g, lst = crosscheck.g, crosscheck.lst


def keep(m):
    return isinstance(m, int) and (1411 <= m <= 1458 or m in (2482, 2521, 2524, 2548, 2652))


def position(kind, ids):
    """Première position connue d'un PNJ (1) ou d'un objet (2) de la liste : (id, carte, x, y)."""
    for i in ids:
        ent = N.get(i) if kind == 1 else O.get(i)
        sp = g(ent, 7 if kind == 1 else 4) or {}
        best = None
        for area, coords in sorted(sp.items(), key=lambda kv: str(kv[0])):
            m = A2M.get(area)
            if not keep(m):
                continue
            pts = [(g(c, 1), g(c, 2)) for c in (coords.values() if isinstance(coords, dict) else [])]
            pts = [(x, y) for x, y in pts if isinstance(x, (int, float)) and isinstance(y, (int, float)) and 0 < x < 100 and 0 < y < 100]
            if pts and (best is None or len(pts) > best[0]):
                best = (len(pts), m, pts[0][0], pts[0][1])
        if best:
            return (i if kind == 1 else 0, best[1], best[2], best[3])
    return None


def where(rel):
    return position(1, lst(g(rel, 1))) or position(2, lst(g(rel, 2)))


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


by_class = defaultdict(list)
skipped = defaultdict(int)
for qid, q in Q.items():
    mask = g(q, 7) or 0
    if not mask or mask & ALL_CLASSES == ALL_CLASSES:
        continue
    o = OVERRIDES.get(str(qid), {})
    if o.get("exclude") or (ERA_MAX < qid < FOREVER_MIN and not o.get("confirm")):
        skipped["exclue ou autre version"] += 1
        continue
    lvl = g(q, 5)
    if not isinstance(lvl, int) or lvl < 1:
        skipped["niveau inconnu"] += 1
        continue
    if (g(q, 24, 0) or 0) & 3:
        skipped["répétable"] += 1
        continue
    if g(q, 18) or g(q, 25):
        skipped["métier ou sous-quête"] += 1
        continue
    giver = where(g(q, 2, {}))
    if not giver:
        skipped["donneur sans position (objet du sac, donjon)"] += 1
        continue
    ender = where(g(q, 3, {})) or (0, 0, 0, 0)
    req = min(g(q, 4, 1) or 1, lvl)
    races = (g(q, 6) or 0) & KNOWN_RACES
    title_en = g(q, 1) or ""
    title_fr = g(QFR.get(qid), 1) or title_en
    row = (lvl, req, qid, races, giver, ender, lst(g(q, 12)), lst(g(q, 13)), title_fr, title_en)
    for bit, name in CLASS_BITS.items():
        if mask & bit:
            by_class[name].append(row)

out = ["local _, ns = ...", "",
       "-- Généré par tools/gen_class.py depuis QuestieDB (GPLv3), recoupé avec tools/cross.json. Ne pas modifier à la main.",
       "-- [classe] = { { quête, niveau, niveau requis, races (masque, 0 = toutes), PNJ donneur, carte, x, y,",
       "--               PNJ de rendu, carte, x, y, \"prérequis tous\", \"prérequis au moins un\", titre fr, titre en } }",
       "ns.ClassQuests = {"]
total = 0
for name in sorted(by_class):
    out.append("    %s = {" % name)
    for lvl, req, qid, races, gv, en, pa, pn, fr, en_title in sorted(by_class[name]):
        total += 1
        out.append("        { %d, %d, %d, %d, %d, %d, %.1f, %.1f, %d, %d, %.1f, %.1f, %s, %s, %s, %s }," % (
            qid, lvl, req, races, gv[0], gv[1], gv[2], gv[3], en[0], en[1], en[2], en[3],
            lua_str(",".join(str(p) for p in pa)), lua_str(",".join(str(p) for p in pn)), lua_str(fr), lua_str(en_title)))
    out.append("    },")
out.append("}")
with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
print("quêtes de classe : %d (%s) ; écartées : %s" % (
    total, ", ".join("%s %d" % (k, len(v)) for k, v in sorted(by_class.items())),
    ", ".join("%s %d" % kv for kv in sorted(skipped.items())) or "aucune"))
