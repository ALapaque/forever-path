"""Génère les routes de leveling ForeverPath à partir de QuestieDB (Forever).

Simulation d'un personnage : niveau/XP, journal de 20 quêtes, prérequis, et choix glouton
de l'action la plus proche (prendre / faire / rendre) pour minimiser les trajets.
Usage : python3 -I gen_routes.py <QuestieDB/data/Forever/> <sortie Guides/>
"""
import json, math, os, pickle, sys
from collections import defaultdict

DATA_DIR, OUT = sys.argv[1], sys.argv[2]
DRY = "--dry" in sys.argv            # mesure seulement, n'écrit pas les guides
SETS = [a.split("=", 1) for a in sys.argv[3:] if "=" in a and not a.startswith("--")]
db = pickle.load(open(os.environ.get("FP_DB") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "db.pkl"), "rb"))
Q, N, O, I = db["Quest"], db["Npc"], db["Object"], db["Item"]
A2M, XPDB, NPCFR, QFR = db["area2map"], db["xp"], db["npcFR"], db["questFR"]

# --- taille des cartes (yards) depuis le manifeste de conversion Forever
conv = json.load(open(os.path.join(DATA_DIR, "conversion.json"), encoding="utf-8"))
MAPSIZE = {}
for t in conv["geometry"]["transforms"]:
    b = t.get("target_bounds") or t.get("source_bounds")
    if b:
        MAPSIZE[t["ui_map_id"]] = (abs(b["left"] - b["right"]), abs(b["top"] - b["bottom"]))

ZONES = {  # clé -> uiMapID (identique à Data/Zones.lua)
    "elwynn": 1429, "dunmorogh": 1426, "teldrassil": 1438, "durotar": 1411, "mulgore": 1412, "tirisfal": 1420,
    "westfall": 1436, "lochmodan": 1432, "darkshore": 1439, "barrens": 1413, "silverpine": 1421, "redridge": 1433,
    "stonetalon": 1442, "ashenvale": 1440, "duskwood": 1431, "wetlands": 1437, "hillsbrad": 1424, "needles": 1441,
    "alterac": 1416, "arathi": 1417, "desolace": 1443, "stv": 1434, "dustwallow": 1445, "badlands": 1418,
    "swamp": 1435, "feralas": 1444, "tanaris": 1446, "hinterlands": 1425, "searing": 1427, "azshara": 1447,
    "blasted": 1419, "ungoro": 1449, "felwood": 1448, "burning": 1428, "wpl": 1422, "epl": 1423,
    "winterspring": 1452, "silithus": 1451,
}
ZONE_FR = {
    "elwynn": "Forêt d'Elwynn", "dunmorogh": "Dun Morogh", "teldrassil": "Teldrassil", "durotar": "Durotar",
    "mulgore": "Mulgore", "tirisfal": "Clairières de Tirisfal", "westfall": "Marche de l'Ouest",
    "lochmodan": "Loch Modan", "darkshore": "Sombrivage", "barrens": "Les Tarides", "silverpine": "Forêt des Pins-Argentés",
    "redridge": "Les Carmines", "stonetalon": "Les Serres-Rocheuses", "ashenvale": "Orneval", "duskwood": "Bois de la Pénombre",
    "wetlands": "Les Paluns", "hillsbrad": "Contreforts de Hautebrande", "needles": "Mille pointes",
    "alterac": "Montagnes d'Alterac", "arathi": "Hautes-terres d'Arathi", "desolace": "Désolace",
    "stv": "Vallée de Strangleronce", "dustwallow": "Marécage d'Âprefange", "badlands": "Terres ingrates",
    "swamp": "Marais des Chagrins", "feralas": "Féralas", "tanaris": "Tanaris", "hinterlands": "Les Hinterlands",
    "searing": "Gorge des Vents brûlants", "azshara": "Azshara", "blasted": "Terres foudroyées",
    "ungoro": "Cratère d'Un'Goro", "felwood": "Gangrebois", "burning": "Steppes ardentes",
    "wpl": "Maleterres de l'Ouest", "epl": "Maleterres de l'Est", "winterspring": "Berceau-de-l'Hiver",
    "silithus": "Silithus",
}

# --- parcours : (zone, niveau de sortie). Une zone peut revenir plus tard (2e passage).
COMMON_A = [("redridge", 22), ("duskwood", 25), ("wetlands", 27), ("ashenvale", 28), ("duskwood", 30),
            ("hillsbrad", 31), ("stv", 34), ("arathi", 36), ("desolace", 38), ("dustwallow", 40),
            ("badlands", 41), ("swamp", 42), ("stv", 44), ("tanaris", 46), ("feralas", 47), ("hinterlands", 49),
            ("searing", 50), ("ungoro", 52), ("azshara", 53), ("felwood", 54), ("burning", 55),
            ("winterspring", 56), ("wpl", 57), ("epl", 59), ("silithus", 60), ("winterspring", 60), ("epl", 60)]
COMMON_H = [("stonetalon", 23), ("ashenvale", 26), ("barrens", 27), ("hillsbrad", 29), ("needles", 31),
            ("stv", 34), ("arathi", 36), ("desolace", 38), ("dustwallow", 40), ("badlands", 41), ("swamp", 42),
            ("stv", 44), ("tanaris", 46), ("feralas", 47), ("hinterlands", 49), ("searing", 50), ("ungoro", 52),
            ("azshara", 53), ("felwood", 54), ("burning", 55), ("winterspring", 56), ("wpl", 57), ("epl", 59),
            ("silithus", 60), ("winterspring", 60), ("epl", 60)]
PATHS = {
    "alliance-human":    ("Alliance", ["Human"], [("elwynn", 10), ("westfall", 14), ("lochmodan", 16), ("westfall", 18)] + COMMON_A),
    "alliance-dwarf":    ("Alliance", ["Dwarf", "Gnome"], [("dunmorogh", 10), ("lochmodan", 14), ("westfall", 18)] + COMMON_A),
    "alliance-nightelf": ("Alliance", ["NightElf"], [("teldrassil", 11), ("darkshore", 18), ("ashenvale", 21), ("westfall", 22)] + COMMON_A),
    "horde-orc":         ("Horde", ["Orc", "Troll"], [("durotar", 11), ("barrens", 16), ("silverpine", 18), ("barrens", 21)] + COMMON_H),
    "horde-tauren":      ("Horde", ["Tauren"], [("mulgore", 11), ("barrens", 16), ("silverpine", 18), ("barrens", 21)] + COMMON_H),
    "horde-undead":      ("Horde", ["Scourge"], [("tirisfal", 11), ("silverpine", 16), ("barrens", 21)] + COMMON_H),
}

RACE_BITS = {1: "Human", 2: "Orc", 4: "Dwarf", 8: "NightElf", 16: "Scourge", 32: "Tauren", 64: "Gnome", 128: "Troll"}
FACTION_MASK = {"Alliance": 1 | 4 | 8 | 64, "Horde": 2 | 16 | 32 | 128}
RACE_BIT = {v: k for k, v in RACE_BITS.items()}
CLASS_BITS = {1: "WARRIOR", 2: "PALADIN", 4: "HUNTER", 8: "ROGUE", 16: "PRIEST", 64: "SHAMAN", 128: "MAGE",
              256: "WARLOCK", 1024: "DRUID"}

XP_TO_LEVEL = [0, 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900, 14400,
               16000, 17700, 19400, 21300, 23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300,
               47400, 50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700, 95800, 101000,
               106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500, 153900, 160400, 167100, 173900,
               180800, 187900, 195000, 202300, 209800]

HUB = 100           # yards : rayon "même endroit" (réglé par mesure)
MAX_LOG = 20
# Réglages de la recherche (balayés par --tune) : poids des candidats et anticipation
W_TURNIN, W_ACCEPT = 0.95, 0.9
LOOKAHEAD = 0           # 0 = glouton ; >0 : tient compte des actions voisines du candidat
GREY = 9                # quête ignorée à partir de niveau + GREY

# --- modèle de temps (secondes) pour la mesure de qualité
T_TALK = 8              # prendre / rendre une quête
T_KILL, T_OTHER = 170, 70   # objectif à tuer / autre (ramasser, utiliser, explorer)
T_ZONE = 150            # changement de zone (trajet inter-zones moyen)
T_MOB = 28              # par monstre en farm
def speed(level):
    return 11.2 if level >= 40 else 7.0

def g(t, k, d=None):
    return t.get(k, d) if isinstance(t, dict) else d

def lst(t):
    return [t[k] for k in sorted(t)] if isinstance(t, dict) else []

# ---------------------------------------------------------------- géométrie
def spawns_in(entity_spawns, mapid):
    pts = []
    for area, coords in (entity_spawns or {}).items():
        if A2M.get(area) == mapid:
            for c in lst(coords):
                x, y = g(c, 1), g(c, 2)
                if isinstance(x, (int, float)) and isinstance(y, (int, float)) and x > 0 and y > 0:
                    pts.append((x, y))
    return pts

def dist(mapid, a, b):
    w, h = MAPSIZE.get(mapid, (3000, 2000))
    return math.hypot((a[0] - b[0]) / 100 * w, (a[1] - b[1]) / 100 * h)

def cluster(mapid, pts):
    """Centre du plus gros regroupement de points (le spot où farmer)."""
    if not pts:
        return None
    if len(pts) > 300:
        pts = pts[:: len(pts) // 300 + 1]
    best, bestn = pts[0], -1
    for p in pts:
        n = sum(1 for q in pts if dist(mapid, p, q) < 120)
        if n > bestn:
            best, bestn = p, n
    near = [q for q in pts if dist(mapid, best, q) < 120]
    return (sum(q[0] for q in near) / len(near), sum(q[1] for q in near) / len(near))

def npc_pts(nid, mapid):
    return spawns_in(g(N.get(nid), 7), mapid)

def obj_pts(oid, mapid):
    return spawns_in(g(O.get(oid), 4), mapid)

# ---------------------------------------------------------------- analyse d'une quête
def races_for(mask, faction):
    fm = FACTION_MASK[faction]
    if not mask:
        return True, None
    if mask & fm == 0:
        return False, None
    if mask & fm == fm:
        return True, None
    return True, [RACE_BITS[b] for b in RACE_BITS if mask & b and fm & b]

def all_pts(spawns):
    """{mapid: [pts]} pour un dict de spawns."""
    out = defaultdict(list)
    for area, coords in (spawns or {}).items():
        m = A2M.get(area)
        if not m:
            continue
        for c in lst(coords):
            x, y = g(c, 1), g(c, 2)
            if isinstance(x, (int, float)) and isinstance(y, (int, float)) and x > 0 and y > 0:
                out[m].append((x, y))
    return out

def pick(cands, maps_order):
    """cands: liste de (ref, {map: pts}) -> (ref, map, pos) sur la 1re carte de la route."""
    best = None
    for ref, by in cands:
        for m, pts in by.items():
            if m in maps_order and pts:
                k = maps_order[m]
                if best is None or k < best[0]:
                    best = (k, ref, m, pts[0])
    return best[1:] if best else None

def analyse(qid, faction, maps_order):
    q = Q[qid]
    ok, races = races_for(g(q, 6), faction)
    if not ok:
        return None
    if g(q, 17, 0) < 0 or g(q, 18) or g(q, 19) or g(q, 30) or g(q, 31):
        return None
    if (g(q, 24, 0) or 0) & 3:
        return None
    if g(q, 7):
        return None                       # quêtes de classe : hors route générique
    start, finish = g(q, 2, {}), g(q, 3, {})
    gc = [(("npc", n), all_pts(g(N.get(n), 7))) for n in lst(g(start, 1))] + \
         [(("obj", o), all_pts(g(O.get(o), 4))) for o in lst(g(start, 2))]
    ec = [(("npc", n), all_pts(g(N.get(n), 7))) for n in lst(g(finish, 1))] + \
         [(("obj", o), all_pts(g(O.get(o), 4))) for o in lst(g(finish, 2))]
    gv, en = pick(gc, maps_order), pick(ec, maps_order)
    if not gv or not en:
        return None
    objs = g(q, 10, {})
    groups = []          # chaque objectif : ({map: pts}, mobs, elite)
    def npc_group(nids):
        by, mobs, elites, total = defaultdict(list), {}, 0, 0
        for nid in nids:
            n = N.get(nid)
            if not n:
                continue
            total += 1
            if (g(n, 6, 0) or 0) in (1, 2, 3):
                elites += 1
                continue
            for m, pts in all_pts(g(n, 7)).items():
                by[m].extend(pts)
                mobs[nid] = mobs.get(nid, 0) + len(pts)
        return by, mobs, total > 0 and elites == total
    for o in lst(g(objs, 1)):
        groups.append(npc_group([g(o, 1)]))
    for o in lst(g(objs, 5)):
        groups.append(npc_group(lst(g(o, 1))))
    for o in lst(g(objs, 2)):
        groups.append((all_pts(g(O.get(g(o, 1)), 4)), {}, False))
    for o in lst(g(objs, 3)):
        it = I.get(g(o, 1))
        by, mobs, el = npc_group(lst(g(it, 2)))
        for oid in lst(g(it, 3)):
            for m, pts in all_pts(g(O.get(oid), 4)).items():
                by[m].extend(pts)
                el = False
        if not by and lst(g(it, 14)):
            continue                      # objet acheté chez un marchand : pas de lieu d'objectif
        groups.append((by, mobs, el))
    trig = g(q, 9)
    if trig:
        groups.append((all_pts(g(trig, 2)), {}, False))
    if any(el for _, _, el in groups):
        return None                       # route solo : objectifs élites exclus
    omap, opos, mobs = None, None, []
    if groups:
        # carte d'objectif : celle du donneur si possible, sinon la 1re de la route
        maps = set.intersection(*[set(m for m in by if by[m]) for by, _, _ in groups]) if groups else set()
        maps = [m for m in maps if m in maps_order]
        if not maps:
            return None
        omap = gv[1] if gv[1] in maps else min(maps, key=lambda m: maps_order[m])
        pts = [p for by, _, _ in groups for p in by[omap]]
        opos = cluster(omap, pts)
        mm = defaultdict(int)
        for _, mo, _ in groups:
            for k, v in mo.items():
                mm[k] += v
        mobs = [m for m, _ in sorted(mm.items(), key=lambda kv: -kv[1])[:5]]
    xp = g(XPDB.get(qid), 2, 0) or 0
    return {
        "id": qid, "giver": gv[0], "gmap": gv[1], "gpos": gv[2], "ender": en[0], "emap": en[1], "epos": en[2],
        "omap": omap, "opos": opos, "mobs": mobs,
        "req": g(q, 4, 1) or 1, "lvl": g(q, 5, 1) or 1, "xp": xp, "races": races,
        "preSingle": lst(g(q, 13)), "preGroup": lst(g(q, 12)), "exclusive": lst(g(q, 16)),
        "kill": bool(mobs),
    }

# ---------------------------------------------------------------- simulation
class Char:
    def __init__(self, faction, races):
        self.faction, self.races = faction, races
        self.xp, self.level = 0, 1
        self.done, self.blocked = set(), set()
        self.npcs = set()
        self.grind = 0
        self.log = {}
        self.src = defaultdict(int)
        self.time = 0.0
        self.bind, self.hearth_cd, self.hearths = None, 0.0, 0
        self.danger = set()
        self.dist = 0.0
        self.zones = 0
        self.quests = 0

    def walk(self, d):
        self.dist += d
        self.time += d / speed(self.level)

    def add_xp(self, amount, src="grind"):
        if src == "grind":
            self.time += amount / mob_xp(self.level) * T_MOB
        self.src[src] += amount
        self.xp += amount
        while self.level < 60 and self.xp >= XP_TO_LEVEL[self.level]:
            self.xp -= XP_TO_LEVEL[self.level]
            self.level += 1

def quest_xp(info, lvl):
    d = lvl - info["lvl"]
    f = 1 if d <= 5 else {6: 0.8, 7: 0.6, 8: 0.4, 9: 0.2}.get(d, 0.1)
    return int(info["xp"] * f)

def mob_xp(lvl):
    return 45 + 5 * lvl

def available(info, ch, inlog):
    qid = info["id"]
    if qid in ch.done or qid in inlog or qid in ch.blocked:
        return False
    if info["req"] > ch.level:
        return False
    if info["lvl"] > ch.level + 3:
        return False                      # quête rouge : on attend
    if info["lvl"] + GREY <= ch.level:
        return False                      # quête grise : pas rentable
    if info["preGroup"] and not all(p in ch.done for p in info["preGroup"]):
        return False
    if info["preSingle"] and not any(p in ch.done for p in info["preSingle"]):
        return False
    return True

def visit(zone, stop, ch, infos, remaining_maps):
    """Une visite de zone. ch.log persiste entre zones : qid -> 'todo' | 'ready'."""
    mapid = ZONES[zone]
    log = ch.log
    steps, pos = [], None
    start_level = ch.level

    def reachable(info):
        need = [info["gmap"], info["emap"]] + ([info["omap"]] if info["omap"] else [])
        return all(m in remaining_maps for m in need)

    def can_accept(info):
        return (info["gmap"] == mapid and len(log) < MAX_LOG and available(info, ch, log)
                and reachable(info))

    ch.zones += 1
    arrive_by_hearth = ch.bind and ch.bind["map"] == mapid and ch.time >= ch.hearth_cd
    if arrive_by_hearth:
        steps.append(("H", ch.bind))
        ch.time += 15
        ch.hearth_cd = ch.time + HEARTH_CD
        ch.hearths += 1
        pos = ch.bind["pos"]
    else:
        ch.time += T_ZONE

    def T(info):
        steps.append(("T", info))
        ch.time += T_TALK
        ch.quests += 1
        ch.done.add(info["id"])
        ch.add_xp(quest_xp(info, ch.level), 'quest')
        for e in info["exclusive"]:
            ch.blocked.add(e)
        del log[info["id"]]

    def Aq(info):
        steps.append(("A", info))
        ch.time += T_TALK
        log[info["id"]] = "ready" if not info["opos"] else "todo"
        for e in info["exclusive"]:
            ch.blocked.add(e)

    # trop bas pour cette zone ? petite session de farm avant d'y entrer
    pending = [i for i in infos.values() if i["gmap"] == mapid and i["id"] not in ch.done and i["id"] not in ch.blocked
               and reachable(i) and i["lvl"] + 7 > ch.level]
    if pending and not any(available(i, ch, log) for i in pending):
        need = min(max(i["req"], i["lvl"] - 3) for i in pending)
        if ch.level < need <= ch.level + 3 and need <= 60:
            steps.append(("L", need))
            ch.grind += need - ch.level
            ch.add_xp(sum(XP_TO_LEVEL[l] for l in range(ch.level, need)) - ch.xp)

    guard = 0
    while guard < 3000:
        guard += 1
        if pos is None:
            targets = [i["gpos"] for i in infos.values() if can_accept(i)]
            targets += [infos[q]["opos"] for q, st in log.items() if st == "todo" and infos[q]["omap"] == mapid]
            targets += [infos[q]["epos"] for q, st in log.items() if st == "ready" and infos[q]["emap"] == mapid]
            if not targets:
                break
            pos = max(targets, key=lambda p: sum(1 for t in targets if dist(mapid, p, t) < 150))
            steps.append(("G", pos))
            ch.walk(250)        # arrivée dans la zone jusqu'au premier hub (moyenne)
        # lier la pierre à l'auberge du hub (si on va rester dans la zone)
        if not (ch.bind and ch.bind["map"] == mapid) and stop - ch.level >= 2:
            inn = inn_near(mapid, pos, ch.faction, 120)
            if inn:
                steps.append(("B", inn))
                ch.time += 15
                ch.bind = inn
        changed = True
        while changed:
            changed = False
            for qid in list(log):
                info = infos[qid]
                if log[qid] == "ready" and info["emap"] == mapid and dist(mapid, pos, info["epos"]) <= HUB:
                    T(info); changed = True
            for info in sorted(infos.values(), key=lambda i: i["id"]):
                if can_accept(info) and dist(mapid, pos, info["gpos"]) <= HUB:
                    Aq(info); changed = True
            for qid in list(log):
                info = infos[qid]
                if log[qid] == "todo" and info["omap"] == mapid and dist(mapid, pos, info["opos"]) <= HUB:
                    steps.append(("C", info)); log[qid] = "ready"
                    top = max([g(N.get(m), 5, 0) or 0 for m in info["mobs"]] or [0])
                    if top >= ch.level + 3:
                        ch.danger.add(info["id"])
                    ch.time += T_KILL if info["kill"] else T_OTHER
                    # XP des monstres tués pendant l'objectif (estimation)
                    ch.add_xp(mob_xp(min(info["lvl"], ch.level + 2)) * (22 if info["kill"] else 3), 'kills')
                    changed = True
        cands = []
        for qid, st in log.items():
            info = infos[qid]
            if st == "todo" and info["omap"] == mapid:
                cands.append((dist(mapid, pos, info["opos"]), info["opos"]))
            elif st == "ready" and info["emap"] == mapid:
                cands.append((dist(mapid, pos, info["epos"]) * W_TURNIN, info["epos"]))
        for info in infos.values():
            if can_accept(info):
                cands.append((dist(mapid, pos, info["gpos"]) * W_ACCEPT, info["gpos"]))
        if LOOKAHEAD and len(cands) > 1:
            # un candidat entouré d'autres actions vaut plus : on retranche une part de leur proximité
            pts_all = [c[1] for c in cands]
            cands = [(c[0] - LOOKAHEAD * sum(1 for q in pts_all if q is not c[1] and dist(mapid, c[1], q) < 150), c[1])
                     for c in cands]
        if not cands:
            soon = [i for i in infos.values() if i["gmap"] == mapid and i["id"] not in ch.done
                    and i["id"] not in ch.blocked and i["id"] not in log and reachable(i)
                    and i["req"] <= ch.level + 2 and i["lvl"] <= ch.level + 5]
            if len(soon) >= 3 and ch.level < min(stop + 3, 60):
                steps.append(("L", ch.level + 1))
                ch.grind += 1
                ch.add_xp(XP_TO_LEVEL[ch.level] - ch.xp)
                continue
            break
        cands.sort(key=lambda c: c[0])
        target = cands[0][1]
        far = dist(mapid, pos, target)
        b = ch.bind
        if (b and b["map"] == mapid and far > HEARTH_MIN and ch.time >= ch.hearth_cd
                and dist(mapid, b["pos"], target) < 150):
            steps.append(("H", b))
            ch.time += 15
            ch.hearth_cd = ch.time + HEARTH_CD
            ch.hearths += 1
            pos = b["pos"]
            continue
        ch.walk(far)
        pos = target
    return steps, start_level, ch.level

# ---------------------------------------------------------------- sortie DSL
# ---------------------------------------------------------------- auberges (pierre de foyer)
HEARTH_CD = 3600        # secondes de jeu entre deux pierres
HEARTH_MIN = 700        # yards : en dessous, on marche
INNS = defaultdict(list)    # map -> [(npc, pos, faction)]
for _nid, _n in N.items():
    if g(_n, 14) == "Innkeeper":
        _f = g(_n, 13) or ""
        for _m, _pts in all_pts(g(_n, 7)).items():
            if _pts:
                INNS[_m].append((_nid, _pts[0], _f))

def inn_near(mapid, pos, faction, radius):
    best = None
    for nid, p, f in INNS.get(mapid, []):
        if faction[0] in f:
            d = dist(mapid, pos, p)
            if d <= radius and (not best or d < best[0]):
                best = (d, nid, p)
    return best and {"map": mapid, "npc": best[1], "pos": best[2]}

def npc_name(nid):
    fr = g(NPCFR.get(nid), 1)
    en = g(N.get(nid), 1)
    return fr, en

def fmt(p):
    return "@%.1f,%.1f" % (p[0], p[1])

def render(zone, steps, stop):
    lines = ["M " + zone]
    used_npcs = set()
    for kind, x in steps:
        if kind == "G":
            lines.append('G "Rejoins %s" %s r=40 upto=%d' % (ZONE_FR[zone], fmt(x), stop + 2))
            continue
        if kind in ("B", "H"):
            used_npcs.add(x["npc"])
            if kind == "B":
                lines.append('B "Lie ta pierre de foyer à l\'auberge" %s id=%d' % (fmt(x["pos"]), x["npc"]))
            else:
                lines.append('H "Utilise ta pierre de foyer" %s id=%d' % (fmt(x["pos"]), x["npc"]))
            continue
        if kind == "L":
            if lines and lines[-1].startswith("L "):
                lines.pop()       # deux paliers d'affilée : on garde le plus haut
            lines.append('L %d "Tue des monstres autour de toi jusqu\'au niveau %d"' % (x, x))
            continue
        info = x
        opts = []
        if info["races"]:
            opts.append("race=" + ",".join(info["races"]))
        if kind in ("A", "T"):
            who = info["giver"] if kind == "A" else info["ender"]
            p = info["gpos"] if kind == "A" else info["epos"]
            if who[0] == "npc":
                opts.append("id=%d" % who[1])
                used_npcs.add(who[1])
            if kind == "A":
                opts.append("lvl=%d" % info["lvl"])
            lines.append("%s %d %s %s" % (kind, info["id"], fmt(p), " ".join(opts)))
        elif kind == "C":
            if info["mobs"]:
                opts.append("mobs=" + ",".join(str(m) for m in info["mobs"]))
                used_npcs.update(info["mobs"])
            lines.append("C %d %s %s" % (info["id"], fmt(info["opos"]), " ".join(opts)))
    return "\n".join(l.rstrip() for l in lines), used_npcs

def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

# ---------------------------------------------------------------- quêtes collectées en jeu
COLLECTED_PATH = os.environ.get("FP_COLLECTED") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "collected.json")
COLLECTED = json.load(open(COLLECTED_PATH, encoding="utf-8"))["quests"] if os.path.exists(COLLECTED_PATH) else {}
collected_stats = []
_xp_by_lvl = None

def estimate_xp(lvl):
    """XP médiane des quêtes Classic de ce niveau (quand la collecte n'a pas vu l'XP)."""
    global _xp_by_lvl
    if _xp_by_lvl is None:
        by = defaultdict(list)
        for qid, q in Q.items():
            x = g(XPDB.get(qid), 2, 0) or 0
            if x:
                by[g(q, 5, 1) or 1].append(x)
        _xp_by_lvl = {l: sorted(v)[len(v) // 2] for l, v in by.items()}
    return _xp_by_lvl.get(lvl) or 80 * lvl

def collected_infos(faction, maps_order, infos):
    added, outside = 0, defaultdict(int)
    for key, c in COLLECTED.items():
        qid = int(key)
        if qid in infos or qid in Q:
            continue
        if c.get("faction") not in ("both", faction) or c.get("elite") or (c.get("group") or 0) > 1:
            continue
        gv, en, lvl = c.get("giver"), c.get("ender"), c.get("lvl")
        if not (gv and en and lvl):
            continue
        maps = [gv["map"], en["map"]] + ([c["objective"]["map"]] if c.get("objective") else [])
        if not all(m in maps_order for m in maps):
            for m in maps:
                if m not in maps_order:
                    outside[m] += 1
            continue
        obj = c.get("objective")
        infos[qid] = {
            "id": qid, "giver": ("npc", c["giverNpc"]) if c.get("giverNpc") else ("pos", 0),
            "gmap": gv["map"], "gpos": (gv["x"], gv["y"]),
            "ender": ("npc", c["enderNpc"]) if c.get("enderNpc") else ("pos", 0),
            "emap": en["map"], "epos": (en["x"], en["y"]),
            "omap": obj and obj["map"], "opos": obj and (obj["x"], obj["y"]), "mobs": c.get("mobs") or [],
            "req": max(1, lvl - 4), "lvl": lvl, "xp": c.get("xp") or estimate_xp(lvl), "races": [],
            "preSingle": [], "preGroup": [], "exclusive": [], "kill": bool(c.get("mobs")), "collected": True,
        }
        added += 1
    return added, dict(outside)

def apply_sets():
    for k, v in SETS:
        globals()[k] = type(globals()[k])(float(v)) if isinstance(globals()[k], (int, float)) else v

def metrics_of(pid, ch):
    # temps restant jusqu'au 60 en farm si la route s'arrête avant
    rest = 0.0
    if ch.level < 60:
        need = sum(XP_TO_LEVEL[l] for l in range(ch.level, 60)) - ch.xp
        rest = need / mob_xp(ch.level) * T_MOB
    hours = (ch.time + rest) / 3600
    total_xp = sum(ch.src.values())
    return {"path": pid, "level": ch.level, "hours_to_60": round(hours, 1),
            "xp_per_hour": int(total_xp / max(1, ch.time) * 3600), "walk_km": round(ch.dist * 0.9144 / 1000, 1),
            "danger_quests": len(ch.danger), "grind_levels": ch.grind, "quests": ch.quests, "zones": ch.zones, "hearths": ch.hearths,
            "grind_share": round(ch.src.get("grind", 0) / max(1, total_xp), 3)}

def main():
    apply_sets()
    os.makedirs(OUT, exist_ok=True)
    metrics = []
    all_npcs = set()
    index = []
    stats = []
    for pid, (faction, races, path) in PATHS.items():
        ch = Char(faction, races)
        guides = []
        visits = defaultdict(int)
        maps_order = {}
        for k, (zone, _) in enumerate(path):
            maps_order.setdefault(ZONES[zone], k)
        infos = {}
        for qid in Q:
            info = analyse(qid, faction, maps_order)
            if info and not (info["races"] and not set(info["races"]) & set(races)):
                infos[qid] = info
        # nouveau contenu de Forever collecté en jeu (tools/collected.json)
        added, outside = collected_infos(faction, maps_order, infos)
        collected_stats.append((pid, added, outside))
        for k, (zone, stop) in enumerate(path):
            remaining = set(ZONES[z] for z, _ in path[k:])
            # quêtes devenues impossibles (zone déjà quittée pour de bon) : abandon
            for qid in list(ch.log):
                i = infos[qid]
                st = ch.log[qid]
                need = [i["emap"]] + ([i["omap"]] if st == "todo" and i["omap"] else [])
                if not all(m in remaining for m in need):
                    del ch.log[qid]
            visits[zone] += 1
            steps, l0, l1 = visit(zone, stop, ch, infos, remaining)
            if len([s for s in steps if s[0] in "ACT"]) < 4:
                continue
            gid = "%s-%02d-%s%s" % (pid, l0, zone, "" if visits[zone] == 1 else "-%d" % visits[zone])
            text, used = render(zone, steps, l1)
            all_npcs |= used
            guides.append({"id": gid, "zone": zone, "min": l0, "max": max(l1, l0 + 1), "text": text,
                           "n": len(steps)})
        # quêtes prises mais jamais rendues sur ce parcours : on ne les prend pas
        import re as _re
        turned = set()
        for gd in guides:
            turned |= set(_re.findall(r"^T (\d+)", gd["text"], _re.M))
        for gd in guides:
            gd["text"] = "\n".join(l for l in gd["text"].split("\n")
                                   if not (_re.match(r"^[AC] (\d+)", l) and _re.match(r"^[AC] (\d+)", l).group(1) not in turned))
        # quêtes dangereuses (monstres de 3 niveaux ou plus au-dessus du personnage) : danger=1
        if ch.danger:
            for gd in guides:
                out_lines = []
                for l in gd["text"].split("\n"):
                    mq = _re.match(r"^[ACT] (\d+)", l)
                    if mq and int(mq.group(1)) in ch.danger:
                        l += " danger=1"
                    out_lines.append(l)
                gd["text"] = "\n".join(out_lines)
        for i, gd in enumerate(guides):
            gd["next"] = guides[i + 1]["id"] if i + 1 < len(guides) else None
        stats.append((pid, ch.level, len(guides), sum(gd["n"] for gd in guides), ch.grind, dict(ch.src)))
        metrics.append(metrics_of(pid, ch))
        if DRY:
            continue
        # fichier par parcours
        out = ["local _, ns = ...", "",
               "-- GÉNÉRÉ AUTOMATIQUEMENT par tools/gen_routes.py à partir de QuestieDB (Forever).",
               "-- Ne pas modifier à la main : régénérer. Parcours : " + pid, ""]
        for gd in guides:
            race_tbl = ", ".join("%s = true" % r for r in races)
            out.append("ns.RegisterGuide({")
            out.append('    id = "%s",' % gd["id"])
            out.append('    name = %s,' % lua_str("%s %d-%d" % (ZONE_FR[gd["zone"]], gd["min"], gd["max"])))
            out.append('    faction = "%s", race = { %s }, path = "%s",' % (faction, race_tbl, pid))
            out.append('    minLevel = %d, maxLevel = %d,' % (gd["min"], gd["max"]))
            if gd["next"]:
                out.append('    next = "%s",' % gd["next"])
            out.append("    text = [[\n" + gd["text"] + "\n]],")
            out.append("})")
            out.append("")
        fn = "Route_%s.lua" % pid.replace("-", "_")
        open(os.path.join(OUT, fn), "w", encoding="utf-8").write("\n".join(out))
        index.append(fn)
    report_metrics(metrics)
    if COLLECTED:
        for pid, added, outside in collected_stats:
            print("%-20s quêtes collectées ajoutées : %d%s" % (pid, added,
                  ("  (hors parcours, cartes : %s)" % ", ".join("%s×%d" % kv for kv in sorted(outside.items()))) if outside else ""))
    if DRY:
        return
    # noms de PNJ localisés
    names = ["local _, ns = ...", "", "-- GÉNÉRÉ : noms des PNJ utilisés par les routes (fr / en).", "ns.NpcNames = {"]
    for nid in sorted(all_npcs):
        fr, en = npc_name(nid)
        if en:
            names.append("    [%d] = { %s, %s }," % (nid, lua_str(fr or en), lua_str(en)))
    names.append("}")
    open(os.path.join(OUT, "_NpcNames.lua"), "w", encoding="utf-8").write("\n".join(names) + "\n")
    print("files:", index)
    for s in stats:
        print("%-20s niveau final %d, %d segments, %d étapes, %d niveaux de farm" % s[:5], {k: v//1000 for k, v in s[5].items()})

def report_metrics(metrics):
    """Affiche les mesures et l'écart avec la dernière version enregistrée (tools/route_metrics.json)."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "route_metrics.json")
    old = {}
    if os.path.exists(path):
        old = {m["path"]: m for m in json.load(open(path, encoding="utf-8"))}
    print("%-20s %6s %8s %7s %6s %6s %6s" % ("parcours", "h->60", "XP/h", "km", "farm", "quêtes", "zones"))
    for m in metrics:
        o = old.get(m["path"], {})
        def d(k):
            return "" if k not in o else " (%+g)" % round(m[k] - o[k], 1)
        print("%-20s %6s%s %8d%s %7s %6d %6d %6d" % (m["path"], m["hours_to_60"], d("hours_to_60"),
              m["xp_per_hour"], d("xp_per_hour"), m["walk_km"], m["grind_levels"], m["quests"], m["zones"]))
    avg = sum(m["hours_to_60"] for m in metrics) / len(metrics)
    print("moyenne : %.2f h jusqu'au 60" % avg)
    if not DRY:
        json.dump(metrics, open(path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    return avg

main()
