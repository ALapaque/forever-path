"""Génère Data/QuestLinks.lua à partir de QuestieDB (Forever) : pour chaque quête, les monstres
liés à ses objectifs (à tuer, ou qui lâchent un objet demandé), les PNJ qui la reçoivent, et le
métier requis (lu dans la base, ou ajouté à la main dans tools/overrides.json avec « skill »).

Sert en jeu à regrouper les quêtes du journal qui portent sur les mêmes monstres (y compris les
quêtes hors de la route) et à passer les quêtes de métier quand le personnage n'a pas le niveau.

Usage : FP_DB=<db_full.pkl> python3 -I tools/gen_links.py <sortie Data/QuestLinks.lua>
Lit la base comme de simples données (aucun code exécuté).
"""
import json, os, pickle, sys

HERE = os.path.dirname(os.path.abspath(__file__))
db = pickle.load(open(os.environ.get("FP_DB") or os.path.join(HERE, "db.pkl"), "rb"))
Q, N, I = db["Quest"], db["Npc"], db["Item"]
OVERRIDES = json.load(open(os.path.join(HERE, "overrides.json"), encoding="utf-8")).get("quests", {})

ERA_MAX, FOREVER_MIN = 9665, 90000     # mêmes bornes que gen_routes.py (IDs d'autres versions écartés)
MAX_MOBS = 12


def g(t, k, d=None):
    if isinstance(t, dict):
        v = t.get(k, d)
        return d if v is None else v
    return d


def lst(t):
    if isinstance(t, dict):
        return [t[k] for k in sorted(t) if isinstance(k, int)]
    return list(t) if isinstance(t, (list, tuple)) else []


def ints(t):
    return [v for v in lst(t) if isinstance(v, int) and v > 0]


def mobs_of(q):
    out = []
    objs = g(q, 10, {})
    for o in lst(g(objs, 1)):                    # monstres à tuer
        out.extend(ints({1: g(o, 1)}))
    for o in lst(g(objs, 5)):                    # crédit de mort (plusieurs monstres)
        out.extend(ints(g(o, 1)))
    for o in lst(g(objs, 3)):                    # objets : monstres qui les lâchent
        out.extend(ints(g(I.get(g(o, 1)), 2)))
    seen, res = set(), []
    for m in out:
        if m not in seen and m in N:
            seen.add(m)
            res.append(m)
    return res[:MAX_MOBS]


def skill_of(qid, q):
    o = OVERRIDES.get(str(qid), {})
    if "skill" in o:
        return o["skill"] or None
    s = g(q, 18)
    if isinstance(s, dict):
        s = [g(s, 1), g(s, 2, 1)]
    if isinstance(s, (list, tuple)) and len(s) >= 1 and isinstance(s[0], int) and s[0] > 0:
        return [s[0], s[1] if len(s) > 1 and isinstance(s[1], int) else 1]
    return None


lines = ["local _, ns = ...", "",
         "-- Généré par tools/gen_links.py depuis QuestieDB (GPLv3). Ne pas modifier à la main.",
         "-- ns.QuestLinks[quête] = \"m=monstres de l'objectif;e=PNJ qui la reçoivent;s=métier:niveau\"",
         "ns.QuestLinks = {"]
n_mobs = n_skill = 0
for qid in sorted(Q):
    if ERA_MAX < qid < FOREVER_MIN and not OVERRIDES.get(str(qid), {}).get("confirm"):
        continue
    q = Q[qid]
    if OVERRIDES.get(str(qid), {}).get("exclude"):
        continue
    parts = []
    mobs = mobs_of(q)
    if mobs:
        parts.append("m=" + ",".join(map(str, mobs)))
        n_mobs += 1
    enders = ints(g(g(q, 3, {}), 1))[:3]
    if enders:
        parts.append("e=" + ",".join(map(str, enders)))
    sk = skill_of(qid, q)
    if sk:
        parts.append("s=%d:%d" % (sk[0], sk[1]))
        n_skill += 1
    if parts:
        lines.append('[%d]="%s",' % (qid, ";".join(parts)))
lines.append("}")
open(sys.argv[1], "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("quêtes avec monstres : %d, avec métier : %d" % (n_mobs, n_skill))
