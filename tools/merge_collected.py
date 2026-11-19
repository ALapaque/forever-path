"""Fusionne les collectes des joueurs (/qw collecte export, format FPC1) en tools/collected.json,
que gen_routes.py ajoute aux quêtes de QuestieDB (nouveau contenu de WoW Forever).

Usage : python3 -I tools/merge_collected.py Collected/*.txt [--questie <db.pkl>] [--out tools/collected.json]
Les quêtes déjà connues de QuestieDB sont ignorées si --questie est donné (ou FP_DB).
"""
import json, os, pickle, statistics, sys
from collections import Counter, defaultdict

args = sys.argv[1:]
out_path = "tools/collected.json"
qdb = os.environ.get("FP_DB")
files = []
i = 0
while i < len(args):
    if args[i] == "--out":
        out_path = args[i + 1]; i += 2
    elif args[i] == "--questie":
        qdb = args[i + 1]; i += 2
    else:
        files.append(args[i]); i += 1

known = set()
if qdb and os.path.exists(qdb):
    known = set(pickle.load(open(qdb, "rb"))["Quest"].keys())


def num(s, cast=float):
    try:
        return cast(s)
    except (TypeError, ValueError):
        return None


def point(s):
    """« carte,x,y » -> (carte, x, y)"""
    parts = (s or "").split(",")
    if len(parts) != 3:
        return None
    m, x, y = num(parts[0], int), num(parts[1]), num(parts[2])
    return (m, x, y) if m and x is not None and y is not None else None


def median_point(pts):
    """Point médian sur la carte la plus fréquente (résiste aux positions aberrantes)."""
    pts = [p for p in pts if p]
    if not pts:
        return None
    m = Counter(p[0] for p in pts).most_common(1)[0][0]
    on = [p for p in pts if p[0] == m]
    return {"map": m, "x": round(statistics.median(p[1] for p in on), 1), "y": round(statistics.median(p[2] for p in on), 1)}


Q = defaultdict(lambda: {"titles": Counter(), "lvl": [], "lvlAcc": [], "xp": [], "fac": Counter(), "givers": [],
                         "giverNpc": Counter(), "enders": [], "enderNpc": Counter(), "obj": [], "mobs": Counter(),
                         "elite": 0, "group": 0, "reports": 0})
NPCS = {}
SEEN = set()                    # toutes les quêtes vues en jeu (confirme les IDs 9666-89999 partagés avec d'autres versions)
ACC = {}                        # quête -> plus bas niveau auquel un joueur l'a prise (niveau requis <= ce niveau)
PRE = defaultdict(Counter)      # quête -> quêtes rendues juste avant qu'elle n'apparaisse chez le même PNJ
runs = 0
for f in files:
    for line in open(f, encoding="utf-8", errors="replace"):
        p = line.rstrip("\n").split(";")
        if p[0] == "FPC1":
            runs += 1
        elif p[0] == "Q" and len(p) >= 13:
            q = num(p[1], int)
            if q:
                SEEN.add(q)             # vue dans Forever, même si QuestieDB la connaît déjà
            if not q or q in known:
                continue
            e = Q[q]
            e["reports"] += 1
            if p[2].strip():
                e["titles"][p[2].strip()] += 1
            for key, idx in (("lvl", 3), ("lvlAcc", 4)):
                v = num(p[idx], int)
                if v:
                    e[key].append(v)
            xp, xpl, lvl = num(p[5], int), num(p[6], int), num(p[3], int)
            # XP réduite si le joueur avait trop de niveaux d'avance : on ne garde que les rendus « pleins »
            if xp and (not lvl or not xpl or xpl - lvl <= 5):
                e["xp"].append(xp)
            if p[7]:
                e["fac"][p[7]] += 1
            if p[8]:
                e["giverNpc"][p[8]] += 1
            e["givers"].append(point(p[9]))
            if p[10]:
                e["enderNpc"][p[10]] += 1
            e["enders"].append(point(p[11]))
            for m in p[12].split(","):
                if m.strip().isdigit():
                    e["mobs"][int(m)] += 1
            flags = p[13] if len(p) > 13 else ""
            if "E" in flags:
                e["elite"] += 1
            if "G" in flags:
                e["group"] = max(e["group"], num(flags.split("G", 1)[1], int) or 2)
        elif p[0] == "O" and len(p) >= 3:
            q = num(p[1], int)
            if q and q not in known:
                Q[q]["obj"].append(point(p[2]))
        elif p[0] == "P" and len(p) >= 3:
            q, prev = num(p[1], int), num(p[2], int)
            if q and prev:
                PRE[q][prev] += 1
        elif p[0] == "R" and len(p) >= 3:
            q, lvl = num(p[1], int), num(p[2], int)
            if q and lvl and 0 < lvl <= 60:
                ACC[q] = min(ACC.get(q, 99), lvl)
        elif p[0] == "N" and len(p) >= 4:
            nid = num(p[1], int)
            if nid:
                NPCS[nid] = {"name": p[2], **(median_point([point(p[3])]) or {})}

out = {}
for q, e in sorted(Q.items()):
    fac = [f for f, _ in e["fac"].most_common()]
    out[q] = {
        "title": e["titles"].most_common(1)[0][0] if e["titles"] else "",
        "lvl": max(e["lvl"]) if e["lvl"] else (min(e["lvlAcc"]) if e["lvlAcc"] else None),
        "xp": max(e["xp"]) if e["xp"] else None,
        "faction": fac[0] if len(fac) == 1 else "both",
        "giverNpc": int(e["giverNpc"].most_common(1)[0][0]) if e["giverNpc"] else None,
        "giver": median_point(e["givers"]),
        "enderNpc": int(e["enderNpc"].most_common(1)[0][0]) if e["enderNpc"] else None,
        "ender": median_point(e["enders"]),
        "objective": median_point(e["obj"]),
        "mobs": [m for m, _ in e["mobs"].most_common(5)],
        "elite": e["elite"] > 0, "group": e["group"], "reports": e["reports"],
    }
pre = {str(q): [c.most_common(1)[0][0]] for q, c in sorted(PRE.items())}
acc = {str(q): v for q, v in sorted(ACC.items())}
json.dump({"runs": runs, "quests": out, "npcs": NPCS, "pre": pre, "acc": acc, "seen": sorted(SEEN | set(ACC))}, open(out_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
complete = sum(1 for v in out.values() if v["giver"] and v["ender"] and v["lvl"])
print("collectes : %d, quêtes nouvelles : %d (dont %d complètes : donneur, rendu, niveau), PNJ : %d"
      % (runs, len(out), complete, len(NPCS)))
