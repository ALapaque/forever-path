"""Génère Data/QuestItems.lua à partir de QuestieDB (Forever) : pour chaque objet lié à une
quête, les quêtes qui le demandent (objectif), qu'il lance, ou qui le fournissent ; et pour ces
quêtes : niveau, niveau requis, XP de base, faction et nom (anglais et français).

Usage : FP_DB=<db_full.pkl> python3 -I tools/gen_items.py <sortie Data/QuestItems.lua> [Data/World.lua Data/RareLoot.lua]
Avec les deux derniers arguments : génère aussi la table de butin des monstres rares listés dans
Data/World.lua (équipement, sacs et recettes ; « * » = objet que seuls 1 ou 2 monstres lâchent).
Lit la base comme de simples données (aucun code exécuté).
"""
import os, pickle, sys
from collections import defaultdict

db = pickle.load(open(os.environ.get("FP_DB") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "db.pkl"), "rb"))
Q, XP, QFR = db["Quest"], db["xp"], db["questFR"]

# bits de race (QuestieDB) : Alliance / Horde (Éolides : 2^32 Alliance, 2^33 Horde)
ALLI = 1 | 4 | 8 | 64 | (1 << 32)
HORDE = 2 | 16 | 32 | 128 | (1 << 33)


def g(t, k, d=None):
    return t.get(k, d) if isinstance(t, dict) else d


def vals(t):
    return list(t.values()) if isinstance(t, dict) else (list(t) if isinstance(t, (list, tuple)) else [])


def faction(q):
    r = g(q, 6, 0) or 0
    a, h = bool(r & ALLI), bool(r & HORDE)
    if r == 0 or (a and h):
        return "B"
    return "A" if a else "H"


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


obj, start, prov = defaultdict(set), defaultdict(set), defaultdict(set)
for qid, q in Q.items():
    for it in vals(g(g(q, 10, {}), 3, {})):
        iid = g(it, 1) if isinstance(it, dict) else it
        if isinstance(iid, int) and iid > 0:
            obj[iid].add(qid)
    for iid in vals(g(g(q, 2, {}), 3, {})):
        if isinstance(iid, int) and iid > 0:
            start[iid].add(qid)
    src = g(q, 11)
    if isinstance(src, int) and src > 0:
        prov[src].add(qid)
    for iid in vals(g(q, 21, {})):
        if isinstance(iid, int) and iid > 0:
            prov[iid].add(qid)

items = sorted(set(obj) | set(start) | set(prov))
quests = sorted(set().union(*obj.values(), *start.values(), *prov.values()))

out = ["local _, ns = ...", "",
       "-- Généré par tools/gen_items.py depuis QuestieDB (GPLv3). Ne pas modifier à la main.",
       "-- ns.QuestItems[objet] = \"o=quêtes qui le demandent;s=quêtes qu'il lance;p=quêtes qui le fournissent\"",
       "-- ns.QuestInfo[quête] = { niveau, niveau requis, XP de base, faction (A/H/B), nom anglais, nom français, classes (masque, 0 = toutes) }",
       "ns.QuestItems = {"]
for iid in items:
    parts = []
    for key, src in (("o", obj), ("s", start), ("p", prov)):
        if src.get(iid):
            parts.append(key + "=" + ",".join(str(x) for x in sorted(src[iid])))
    out.append("[%d]=%s," % (iid, lua_str(";".join(parts))))
out.append("}")
out.append("ns.QuestInfo = {")
for qid in quests:
    q = Q.get(qid, {})
    name = g(q, 1, "") or ""
    fr = g(g(QFR, qid, {}), 1, "") or ""
    xp = g(XP.get(qid), 2, 0) or 0
    out.append("[%d]={%d,%d,%d,%s,%s,%s,%d}," % (qid, g(q, 5, 1) or 1, g(q, 4, 1) or 1, xp, lua_str(faction(q)),
                                                 lua_str(name), lua_str(fr if fr != name else ""), g(q, 7, 0) or 0))
out.append("}")
open(sys.argv[1], "w", encoding="utf-8").write("\n".join(out) + "\n")
print("objets : %d, quêtes : %d" % (len(items), len(quests)))

if len(sys.argv) >= 4:
    import re
    I = db["Item"]
    drops = defaultdict(list)
    for iid, it in I.items():
        for n in vals(g(it, 2, {})):
            if isinstance(n, int):
                drops[n].append(iid)
    count = defaultdict(int)
    for n, lst in drops.items():
        for i in lst:
            count[i] += 1
    world = open(sys.argv[2], encoding="utf-8").read()
    block = world[world.find("ns.World.rares"):]
    rares = [int(m) for m in re.findall(r"\{ (\d+), \d+,", block)]
    KEEP = {1, 2, 4, 9}            # sacs, armes, armures, recettes
    lines = ["local _, ns = ...", "",
             "-- Généré par tools/gen_items.py depuis QuestieDB (GPLv3). Ne pas modifier à la main.",
             "-- ns.RareLoot[monstre rare] = \"objet,objet*,...\" (* : objet que seuls 1 ou 2 monstres lâchent)",
             "ns.RareLoot = {"]
    n_items = 0
    for npc in rares:
        items = [i for i in drops.get(npc, []) if g(I[i], 12) in KEEP]
        if not items:
            continue
        items.sort(key=lambda i: (count[i] > 2, i))
        n_items += len(items)
        lines.append("[%d]=\"%s\"," % (npc, ",".join(str(i) + ("*" if count[i] <= 2 else "") for i in items)))
    lines.append("}")
    open(sys.argv[3], "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("butin des rares : %d monstres, %d objets" % (len(lines) - 5, n_items))
