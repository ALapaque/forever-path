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
A2M = db.get("area2map", {})            # zone (areaID) -> carte (uiMapID) ; absent d'un db_full partiel
OVERRIDES = json.load(open(os.path.join(HERE, "overrides.json"), encoding="utf-8")).get("quests", {})
# quêtes qui ne sont pas dans le jeu, niveaux requis et factions : recoupés avec tools/cross.json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crosscheck  # noqa: E402
crosscheck.apply(Q, crosscheck.load(os.environ.get("FP_CROSS"), optional="--no-cross" in sys.argv))

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


# chaînes de quêtes (nextQuestInChain) : position et longueur, pour « La légende de Stalvan (2/13) »
NEXT = {}
for qid, q in Q.items():
    nx = g(q, 22)
    if isinstance(nx, int) and nx in Q and nx != qid:
        NEXT[qid] = nx
HAS_PREV = set(NEXT.values())
CHAIN = {}
for root in Q:
    if root in HAS_PREV or root not in NEXT:
        continue
    chain, seen, q = [], set(), root
    while q is not None and q not in seen:
        seen.add(q)
        chain.append(q)
        q = NEXT.get(q)
    if len(chain) >= 2:
        for i, c in enumerate(chain):
            CHAIN[c] = (i + 1, len(chain))

def ender_pos(enders):
    for e in enders:
        for area, coords in sorted((g(N.get(e), 7) or {}).items()):
            m = A2M.get(area)
            pts = [c for c in lst(coords) if isinstance(c, dict) or isinstance(c, (list, tuple))]
            if isinstance(m, int) and m > 0 and pts:
                c = pts[0]
                x, y = (g(c, 1), g(c, 2)) if isinstance(c, dict) else (c[0], c[1])
                if isinstance(x, (int, float)) and x >= 0:
                    return (m, x, y)
    return None


n_item = 0
lines = ["local _, ns = ...", "",
         "-- Généré par tools/gen_links.py depuis QuestieDB (GPLv3). Ne pas modifier à la main.",
         "-- ns.QuestLinks[quête] = \"m=monstres;e=PNJ qui la reçoivent;s=métier:niveau;c=partie/parties de la chaîne;n=quête suivante;p=carte:x:y (où la rendre, quêtes lancées par un objet)\"",
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
    # quête lancée par un objet (lâché par un monstre) : où la rendre, pour guider en jeu
    if ints(g(g(q, 2, {}), 3)) and enders:
        pos = ender_pos(enders)
        if pos:
            parts.append("p=%d:%.1f:%.1f" % pos)
            n_item += 1
    if qid in CHAIN:
        parts.append("c=%d/%d" % CHAIN[qid])
        if qid in NEXT:
            parts.append("n=%d" % NEXT[qid])
    if parts:
        lines.append('[%d]="%s",' % (qid, ";".join(parts)))
lines.append("}")
open(sys.argv[1], "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("quêtes avec monstres : %d, avec métier : %d, dans une chaîne : %d, lancées par un objet (avec lieu de rendu) : %d"
      % (n_mobs, n_skill, len(CHAIN), n_item))
