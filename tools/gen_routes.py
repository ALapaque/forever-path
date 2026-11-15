"""Génère les routes de leveling Questweaver à partir de QuestieDB (Forever).

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

# ---------------------------------------------------------------- assainissement des données
# QuestieDB « Forever » est une base Classic Era convertie, complétée par des quêtes relevées en
# jeu. Défauts connus (tickets Questie #7999, #8264, #8266 ; QuestieDB #78) et parades :
#   - quêtes d'autres versions (Season of Discovery) qui fuient : IDs 9666-89999, écartées sauf si
#     le collecteur les a vues dans Forever ;
#   - niveau requis provisoire (1 ou absent) sur des quêtes Forever : estimé depuis le niveau de quête ;
#   - chaînes sans prérequis : complétées par nextQuestInChain, puis par un ordre « souple »
#     (suite donnée par le PNJ à qui on vient de rendre la quête d'ID voisin) ;
#   - corrections manuelles : tools/overrides.json (niveau, niveau requis, prérequis, exclusion).
from collections import Counter
HERE = os.path.dirname(os.path.abspath(__file__))
COLLECTED_PATH = os.environ.get("FP_COLLECTED") or os.path.join(HERE, "collected.json")
_collected_doc = json.load(open(COLLECTED_PATH, encoding="utf-8")) if os.path.exists(COLLECTED_PATH) else {}
COLLECTED = _collected_doc.get("quests", {})
COLLECTED_PRE = _collected_doc.get("pre", {})        # { "quête": [quêtes rendues juste avant, vues en jeu] }
OVERRIDES_PATH = os.path.join(HERE, "overrides.json")
OVERRIDES = json.load(open(OVERRIDES_PATH, encoding="utf-8")).get("quests", {}) if os.path.exists(OVERRIDES_PATH) else {}
SAN = Counter()
FOREVER_MIN = 90000         # premiers IDs de quêtes propres à Forever
ERA_MAX = 9665              # dernier ID de quête Classic Era

def sanitize():
    seen = (set(int(k) for k in COLLECTED) | set(_collected_doc.get("seen", []))
            | set(int(k) for k, o in OVERRIDES.items() if o.get("confirm")))
    for qid in list(Q):
        if ERA_MAX < qid < FOREVER_MIN and qid not in seen:
            del Q[qid]
            SAN["autres versions (écartées)"] += 1
    for key, o in OVERRIDES.items():
        qid = int(key)
        q = Q.get(qid)
        if not q:
            continue
        if o.get("exclude"):
            del Q[qid]
            SAN["exclues à la main"] += 1
            continue
        if "lvl" in o: q[5] = o["lvl"]
        if "req" in o: q[4] = o["req"]
        if "pre" in o: q[13] = {i + 1: v for i, v in enumerate(o["pre"])}; q[12] = None
        q["fixed"] = True
        SAN["corrigées à la main"] += 1
    for qid, q in Q.items():
        nxt = g(q, 22)
        if isinstance(nxt, int) and nxt in Q and nxt != qid and (qid >= FOREVER_MIN or nxt >= FOREVER_MIN):
            t = Q[nxt]
            if not lst(g(t, 12)) and not lst(g(t, 13)):
                t[13] = {1: qid}
                SAN["prérequis déduits (suite de chaîne)"] += 1
    for key, pres in COLLECTED_PRE.items():
        t = Q.get(int(key))
        if t and not lst(g(t, 12)) and not lst(g(t, 13)) and pres and all(p in Q for p in pres):
            t[13] = {i + 1: v for i, v in enumerate(pres)}
            SAN["prérequis vus en jeu"] += 1
    for qid, q in Q.items():
        lvl, req = g(q, 5), g(q, 4)
        if qid >= FOREVER_MIN and isinstance(lvl, int) and lvl > 1 and (not req or req <= 1) and not q.get("fixed"):
            q[4] = max(1, lvl - 3)
            q["estimated"] = True
            SAN["niveau requis estimé"] += 1
    # ordre souple : suite donnée par le PNJ à qui on rend la quête d'ID voisin (1 à 3 avant)
    enders = defaultdict(set)
    for qid, q in Q.items():
        if qid >= FOREVER_MIN:
            for n in lst(g(g(q, 3, {}), 1)):
                enders[n].add(qid)
    for qid, q in Q.items():
        if qid < FOREVER_MIN or lst(g(q, 12)) or lst(g(q, 13)):
            continue
        lvl = g(q, 5) or 0
        best = None
        for n in lst(g(g(q, 2, {}), 1)):
            for a in enders.get(n, ()):
                if 1 <= qid - a <= 3 and (g(Q[a], 5) or 0) <= lvl and g(Q[a], 6) == g(q, 6):
                    if best is None or a > best:
                        best = a
        if best:
            q["soft"] = best
            SAN["ordre souple (même PNJ)"] += 1

# --- taille des cartes (yards) depuis le manifeste de conversion Forever
conv = json.load(open(os.path.join(DATA_DIR, "conversion.json"), encoding="utf-8"))
MAPSIZE = {}
for t in conv["geometry"]["transforms"]:
    b = t.get("target_bounds") or t.get("source_bounds")
    if b:
        MAPSIZE[t["ui_map_id"]] = (abs(b["left"] - b["right"]), abs(b["top"] - b["bottom"]))

ZONES = {  # clé -> uiMapID (identique à Data/Zones.lua)
    "zephras": 2521, "riverglades": 2548, "shendralas": 2652, "hyjal": 2482,
    "elwynn": 1429, "dunmorogh": 1426, "teldrassil": 1438, "durotar": 1411, "mulgore": 1412, "tirisfal": 1420,
    "westfall": 1436, "lochmodan": 1432, "darkshore": 1439, "barrens": 1413, "silverpine": 1421, "redridge": 1433,
    "stonetalon": 1442, "ashenvale": 1440, "duskwood": 1431, "wetlands": 1437, "hillsbrad": 1424, "needles": 1441,
    "alterac": 1416, "arathi": 1417, "desolace": 1443, "stv": 1434, "dustwallow": 1445, "badlands": 1418,
    "swamp": 1435, "feralas": 1444, "tanaris": 1446, "hinterlands": 1425, "searing": 1427, "azshara": 1447,
    "blasted": 1419, "ungoro": 1449, "felwood": 1448, "burning": 1428, "wpl": 1422, "epl": 1423,
    "winterspring": 1452, "silithus": 1451,
    # capitales : beaucoup de quêtes y commencent ou s'y rendent
    "stormwind": 1453, "ironforge": 1455, "darnassus": 1457, "orgrimmar": 1454, "thunderbluff": 1456, "undercity": 1458,
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
    "silithus": "Silithus", "zephras": "Île de Zéphras", "riverglades": "Rives Claires", "shendralas": "Shen'dralas",
    "hyjal": "Mont Hyjal", "stormwind": "Hurlevent", "ironforge": "Forgefer", "darnassus": "Darnassus",
    "orgrimmar": "Orgrimmar", "thunderbluff": "Les Pitons-du-Tonnerre", "undercity": "Fossoyeuse",
}

# --- parcours : la race fixe la zone de départ ; ensuite l'ordre des zones n'est plus écrit à la main.
# Le planificateur choisit à chaque fois la zone qui rapporte le plus d'XP par heure à ce niveau
# (quêtes prenables + quêtes du journal à y faire ou y rendre, trajet compris), d'après les niveaux
# des quêtes de Forever. Il revient dans une zone quand de nouvelles quêtes s'y débloquent, au lieu
# de farmer sur place.
PATHS = {
    "alliance-human":    ("Alliance", ["Human"], "elwynn"),
    "alliance-dwarf":    ("Alliance", ["Dwarf", "Gnome"], "dunmorogh"),
    "alliance-nightelf": ("Alliance", ["NightElf"], "teldrassil"),
    "horde-orc":         ("Horde", ["Orc", "Troll"], "durotar"),
    "horde-tauren":      ("Horde", ["Tauren"], "mulgore"),
    "horde-undead":      ("Horde", ["Scourge"], "tirisfal"),
    # Skyborne : Île de Zéphras, puis l'aéronef vers les terres de la faction
    "alliance-skyborne": ("Alliance", ["SkyborneAlliance"], "zephras"),
    "horde-skyborne":    ("Horde", ["SkyborneHorde"], "zephras"),
}
KAL = {"teldrassil", "durotar", "mulgore", "darkshore", "barrens", "stonetalon", "ashenvale", "needles", "desolace",
       "dustwallow", "feralas", "tanaris", "azshara", "ungoro", "felwood", "winterspring", "silithus", "shendralas",
       "hyjal", "darnassus", "orgrimmar", "thunderbluff"}
def continent(zone):
    return "IS" if zone == "zephras" else "KA" if zone in KAL else "EK"
# zones où l'on n'envoie pas l'autre faction (départs, capitales et zones 10-20 adverses)
ONLY = {"Alliance": {"elwynn", "dunmorogh", "teldrassil", "westfall", "lochmodan", "darkshore", "stormwind", "ironforge", "darnassus"},
        "Horde": {"durotar", "mulgore", "tirisfal", "silverpine", "orgrimmar", "thunderbluff", "undercity"}}
# niveau d'entrée habituel d'une zone : sert seulement à départager les lieux d'un PNJ présent sur plusieurs cartes
ZLVL = {"elwynn": 1, "dunmorogh": 1, "teldrassil": 1, "durotar": 1, "mulgore": 1, "tirisfal": 1, "zephras": 1,
        "westfall": 10, "lochmodan": 10, "darkshore": 11, "barrens": 10, "silverpine": 10, "redridge": 15, "stonetalon": 16,
        "ashenvale": 19, "duskwood": 20, "wetlands": 21, "hillsbrad": 22, "needles": 26, "alterac": 30, "arathi": 30,
        "desolace": 31, "stv": 31, "dustwallow": 35, "badlands": 36, "swamp": 36, "riverglades": 36, "shendralas": 38,
        "feralas": 41, "tanaris": 41, "hinterlands": 42, "searing": 44, "azshara": 46, "blasted": 46, "ungoro": 48,
        "felwood": 48, "burning": 50, "wpl": 51, "epl": 54, "winterspring": 54, "hyjal": 54, "silithus": 55,
        "stormwind": 5, "ironforge": 5, "darnassus": 5, "orgrimmar": 5, "thunderbluff": 5, "undercity": 5}
STARTS = {"elwynn", "dunmorogh", "teldrassil", "durotar", "mulgore", "tirisfal", "zephras"}
FAR_EDGE = 2            # changer de continent seulement si ça rapporte nettement plus (divise le rendement)
MIN_STEPS = 3           # en dessous, une zone ne vaut pas le déplacement (sauf si rien d'autre)
T_NEAR, T_FAR = 600, 1500   # trajet vers une zone du même continent / de l'autre continent (secondes)
GRIND_PREF = 0.6        # on part quêter ailleurs tant que ça rapporte au moins cette part du farm sur place
SMALL_PEN = 0.3         # un passage de moins de MIN_STEPS actions ne compte qu'à moitié
STALE = 10              # quête abandonnée si elle traîne dans le journal depuis ce nombre de zones

RACE_BITS = {1: "Human", 2: "Orc", 4: "Dwarf", 8: "NightElf", 16: "Scourge", 32: "Tauren", 64: "Gnome", 128: "Troll",
             2 ** 32: "SkyborneAlliance", 2 ** 33: "SkyborneHorde"}
FACTION_MASK = {"Alliance": 1 | 4 | 8 | 64, "Horde": 2 | 16 | 32 | 128}
SKY_BIT = {"Alliance": 2 ** 32, "Horde": 2 ** 33}
SKY_RACES = {"SkyborneAlliance", "SkyborneHorde"}
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
GREY = 7                # quête ignorée à partir de niveau + GREY
MAX_AHEAD = 2           # quête sans objectif sur le terrain (parler, livrer) : prise au plus tôt à niveau de quête - 2
OBJ_AHEAD = 1           # quête avec objectif sur le terrain : au plus tôt à niveau de quête - 1
CHAIN_W = 0.6           # poids, dans le choix d'une zone, des suites de chaîne qui se débloqueront sur place
GROUP_NEAR = 400        # yards : objectif d'une quête de groupe proposé si la route passe à cette distance
MOB_AHEAD = 2           # monstres de l'objectif : au plus 2 niveaux au-dessus (signalés danger à +2)
UNUSED = []
ORDER = []
DROP = Counter()        # pourquoi une quête de la base n'entre pas dans un parcours (diagnostic)

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
    """Races de la faction autorisées par le masque. Un masque « toutes les races Classic de la
    faction » vaut aussi pour les Skyborne de cette faction (données héritées de Classic)."""
    fm, sky = FACTION_MASK[faction], SKY_BIT[faction]
    if not mask:
        return True, None
    classic, has_sky = mask & fm, bool(mask & sky)
    if not classic and not has_sky:
        return False, None
    if classic == fm:
        return True, None
    names = [RACE_BITS[b] for b in RACE_BITS if b <= 128 and classic & b]
    if has_sky:
        names.append(RACE_BITS[sky])
    return True, names

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
    lvl = g(q, 5)
    if not isinstance(lvl, int) or lvl == 0 or lvl < -1:
        DROP["niveau inconnu"] += 1
        return None
    if (g(q, 17) or 0) < 0 or g(q, 18) or g(q, 19) or g(q, 30) or g(q, 31):
        DROP["métier, réputation, événement ou classe"] += 1
        return None
    if (g(q, 24, 0) or 0) & 3:
        DROP["répétable"] += 1
        return None
    if g(q, 7):
        DROP["métier, réputation, événement ou classe"] += 1
        return None                       # quêtes de classe : hors route générique
    start, finish = g(q, 2, {}), g(q, 3, {})
    gc = [(("npc", n), all_pts(g(N.get(n), 7))) for n in lst(g(start, 1))] + \
         [(("obj", o), all_pts(g(O.get(o), 4))) for o in lst(g(start, 2))]
    ec = [(("npc", n), all_pts(g(N.get(n), 7))) for n in lst(g(finish, 1))] + \
         [(("obj", o), all_pts(g(O.get(o), 4))) for o in lst(g(finish, 2))]
    gv, en = pick(gc, maps_order), pick(ec, maps_order)
    if not gv or not en:
        DROP["donneur ou receveur hors du parcours" if (gc and ec and any(by for _, by in gc) and any(by for _, by in ec))
             else "donneur ou receveur sans position"] += 1
        return None
    # PNJ réservé à l'autre faction (données de faction parfois fausses sur les quêtes Forever)
    for who in (gv[0], en[0]):
        if who[0] == "npc":
            fr = g(N.get(who[1]), 13)
            if isinstance(fr, str) and fr and faction[0] not in fr:
                DROP["PNJ de l'autre faction"] += 1
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
    group = any(el for _, _, el in groups)     # objectif élite : quête de groupe, optionnelle
    omap, opos, mobs = None, None, []
    if groups:
        # carte d'objectif : celle du donneur si possible, sinon la 1re de la route
        maps = set.intersection(*[set(m for m in by if by[m]) for by, _, _ in groups]) if groups else set()
        maps = [m for m in maps if m in maps_order]
        if not maps:
            DROP["objectif hors du parcours (donjon, autre zone)"] += 1
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
    req = g(q, 4, 1) or 1
    scales = lvl == -1                    # quête au niveau du joueur
    if scales:
        lvl = req
    if not xp:
        xp = estimate_xp(lvl)
    return {
        "id": qid, "giver": gv[0], "gmap": gv[1], "gpos": gv[2], "ender": en[0], "emap": en[1], "epos": en[2],
        "omap": omap, "opos": opos, "mobs": mobs,
        "req": req, "lvl": lvl, "xp": xp, "races": races, "scales": scales,
        "preSingle": lst(g(q, 13)), "preGroup": lst(g(q, 12)), "exclusive": lst(g(q, 16)),
        "kill": bool(mobs), "group": group, "soft": q.get("soft"), "estimated": bool(q.get("estimated")),
        "moblvl": max([g(N.get(m), 5, 0) or 0 for m in mobs] or [0]),
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
        self.infos = {}
        self.grindat = []
        self.logage = {}
        self.cross = 0
        self.glog = {}          # quêtes de groupe (optionnelles) : qid -> 'todo' | 'ready' | 'done'
        self.ahead = Counter()  # écart (niveau de quête - niveau du joueur) à la prise
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
    if info.get("scales"):
        return info["xp"]
    d = lvl - info["lvl"]
    f = 1 if d <= 5 else {6: 0.8, 7: 0.6, 8: 0.4, 9: 0.2}.get(d, 0.1)
    return int(info["xp"] * f)

def mob_xp(lvl):
    return 45 + 5 * lvl

def available(info, ch, inlog, ignore_pre=False):
    qid = info["id"]
    if qid in ch.done or qid in inlog or qid in ch.blocked:
        return False
    if info["req"] > ch.level:
        return False
    if not info.get("scales"):
        if info["lvl"] > ch.level + (MAX_AHEAD if not info["opos"] else OBJ_AHEAD):
            return False                  # quête trop haute : on attend
        if info["lvl"] + GREY <= ch.level:
            return False                  # quête grise : pas rentable
    if info["moblvl"] > ch.level + MOB_AHEAD:
        return False                      # monstres trop hauts : on attend
    if not ignore_pre and info.get("soft") and info["soft"] in ch.infos and info["soft"] not in ch.done:
        return False                      # suite probable d'une quête pas encore rendue (même PNJ)
    if ignore_pre:
        return True
    if info["preGroup"] and not all(p in ch.done for p in info["preGroup"]):
        return False
    if info["preSingle"] and not any(p in ch.done for p in info["preSingle"]):
        return False
    return True

def visit(zone, ch, infos, remaining_maps, travel_time, long_stay, grind_to=None):
    """Une visite de zone. ch.log persiste entre zones : qid -> 'todo' | 'ready'."""
    mapid = ZONES[zone]
    log = ch.log
    steps, pos = [], None
    start_level = ch.level

    def reachable(info):
        need = [info["gmap"], info["emap"]] + ([info["omap"]] if info["omap"] else [])
        return all(m in remaining_maps for m in need)

    def can_accept(info):
        return (info["gmap"] == mapid and not info["group"] and len(log) < MAX_LOG and available(info, ch, log)
                and reachable(info))

    group_here = [i for i in infos.values() if i["group"] and mapid in (i["gmap"], i["omap"], i["emap"])]

    ch.zones += 1
    arrive_by_hearth = ch.bind and ch.bind["map"] == mapid and ch.time >= ch.hearth_cd
    if arrive_by_hearth:
        steps.append(("H", ch.bind))
        ch.time += 15
        ch.hearth_cd = ch.time + HEARTH_CD
        ch.hearths += 1
        pos = ch.bind["pos"]
    else:
        ch.time += travel_time
    if grind_to:
        steps.append(("L", grind_to))

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
        ch.ahead[0 if info.get("scales") else info["lvl"] - ch.level] += 1
        ch.time += T_TALK
        log[info["id"]] = "ready" if not info["opos"] else "todo"
        ch.logage[info["id"]] = ch.zones
        for e in info["exclusive"]:
            ch.blocked.add(e)

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
        if not (ch.bind and ch.bind["map"] == mapid) and long_stay:
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
                    if info["moblvl"] >= ch.level + 2:
                        ch.danger.add(info["id"])
                    ch.time += T_KILL if info["kill"] else T_OTHER
                    # XP des monstres tués pendant l'objectif (estimation)
                    ch.add_xp(mob_xp(min(info["lvl"], ch.level + 2)) * (22 if info["kill"] else 3), 'kills')
                    changed = True
            # quêtes de groupe : proposées au passage (option en jeu), sans compter dans la simulation
            for info in group_here:
                qid, st = info["id"], ch.glog.get(info["id"])
                if (st is None and qid not in ch.done and info["gmap"] == mapid and dist(mapid, pos, info["gpos"]) <= HUB
                        and available(info, ch, ch.glog) and reachable(info)):
                    steps.append(("A", info)); ch.glog[qid] = "todo" if info["opos"] else "ready"
                elif st == "todo" and info["omap"] == mapid and dist(mapid, pos, info["opos"]) <= GROUP_NEAR:
                    steps.append(("C", info)); ch.glog[qid] = "ready"
                elif st == "ready" and info["emap"] == mapid and dist(mapid, pos, info["epos"]) <= HUB:
                    steps.append(("T", info)); ch.glog[qid] = "done"
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

SKY_PATH = [False]

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
        # parcours Skyborne : pas de filtre de race sur les étapes (le jeton de race du client est inconnu,
        # et la route est déjà filtrée pour cette race) ; ailleurs : races Classic seulement
        shown = [r for r in (info["races"] or []) if r not in SKY_RACES]
        if shown and not SKY_PATH[0]:
            opts.append("race=" + ",".join(shown))
        if info.get("group"):
            opts.append("group=1")
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
            "group": False, "soft": None, "scales": False, "estimated": False, "moblvl": 0,
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
            "grind_share": round(ch.src.get("grind", 0) / max(1, total_xp), 3),
            "cross_continent": ch.cross, "max_ahead": max(ch.ahead or [0]), "at_plus2": ch.ahead.get(2, 0), "at_plus1": ch.ahead.get(1, 0),
            "estimated_req": sum(1 for q in ch.done if ch.infos.get(q, {}).get("estimated")),
            "group_quests": sum(1 for v in ch.glog.values() if v == "done")}

def main():
    apply_sets()
    sanitize()
    os.makedirs(OUT, exist_ok=True)
    metrics = []
    all_npcs = set()
    index = []
    stats = []
    for pid, (faction, races, start) in PATHS.items():
        SKY_PATH[0] = any(r in SKY_RACES for r in races)
        ch = Char(faction, races)
        DROP.clear()
        guides = []
        visits = defaultdict(int)
        # zones de départ des autres races : on n'y envoie personne (quêtes trop basses, détour étrange)
        allowed = [z for z in ZONES if z not in ONLY["Horde" if faction == "Alliance" else "Alliance"]
                   and (z == start or z not in STARTS)]
        allowed.sort(key=lambda z: (z != start, ZLVL.get(z, 30)))
        maps_order = {ZONES[z]: k for k, z in enumerate(allowed)}
        all_maps = set(maps_order)
        infos = {}
        for qid in Q:
            info = analyse(qid, faction, maps_order)
            if info and not (info["races"] and not set(info["races"]) & set(races)):
                infos[qid] = info
        ch.infos = infos
        # nouveau contenu de Forever collecté en jeu (tools/collected.json)
        added, outside = collected_infos(faction, maps_order, infos)
        collected_stats.append((pid, added, outside))
        by_giver = defaultdict(list)
        for i in infos.values():
            if not i["group"]:
                by_giver[i["gmap"]].append(i)

        def kills(i):
            return mob_xp(min(i["lvl"], ch.level + 2)) * (22 if i["kill"] else 3)

        def zone_value(zone):
            """(XP attendue, temps estimé, nombre d'actions) d'un passage dans la zone maintenant."""
            m = ZONES[zone]
            gain = t = n = 0.0
            for qid, st in ch.log.items():
                i = infos[qid]
                if st == "ready" and i["emap"] == m:
                    gain += quest_xp(i, ch.level); t += 60; n += 1
                elif st == "todo" and i["omap"] == m:
                    here = i["emap"] == m
                    gain += kills(i) + quest_xp(i, ch.level) * (1 if here else 0.5)
                    t += (T_KILL if i["kill"] else T_OTHER) + (90 if here else 30); n += 1
            cands = []
            memo = {}

            def startable(qid, depth=0):
                """La quête pourra être prise pendant ce passage : ses prérequis se font dans la zone."""
                if qid in ch.done or qid in ch.log:
                    return True
                if qid in memo:
                    return memo[qid]
                memo[qid] = False
                j = infos.get(qid)
                if (j and depth < 6 and not j["group"] and j["gmap"] == m and j["emap"] == m and j["omap"] in (None, m)
                        and available(j, ch, ch.log, True)
                        and all(startable(p, depth + 1) for p in j["preGroup"])
                        and (not j["preSingle"] or any(startable(p, depth + 1) for p in j["preSingle"]))):
                    memo[qid] = True
                return memo[qid]

            for i in by_giver.get(m, ()):
                w = 1.0
                if not available(i, ch, ch.log):
                    # suite d'une chaîne qui se fait sur place : comptée en partie
                    if not (CHAIN_W and (i["preGroup"] or i["preSingle"]) and available(i, ch, ch.log, True)
                            and all(startable(p) for p in i["preGroup"])
                            and (not i["preSingle"] or any(startable(p) for p in i["preSingle"]))):
                        continue
                    w = CHAIN_W
                local_obj, local_end = i["omap"] in (None, m), i["emap"] == m
                if local_obj and local_end:
                    cands.append((w * (quest_xp(i, ch.level) + (kills(i) if i["omap"] else 0)),
                                  w * (T_TALK * 2 + ((T_KILL if i["kill"] else T_OTHER) if i["omap"] else 0) + 120), w, w == 1.0))
                elif local_obj:
                    cands.append((w * (quest_xp(i, ch.level) * 0.5 + (kills(i) if i["omap"] else 0)),
                                  w * (T_TALK + ((T_KILL if i["kill"] else T_OTHER) if i["omap"] else 0) + 90), 0.7 * w, w == 1.0))
                else:
                    cands.append((w * quest_xp(i, ch.level) * 0.3, w * (T_TALK + 40), 0.4 * w, w == 1.0))
            cands.sort(key=lambda c: -c[0] / c[1])
            now = n + sum(1 for c in cands if c[3])
            for g_, t_, n_, _now in cands[:max(0, MAX_LOG - len(ch.log))]:
                gain += g_; t += t_; n += n_
            if now < 1:
                return 0, 1, 0            # rien à faire tout de suite : les quêtes « bientôt » ne suffisent pas
            return gain, t, n

        def trip(a, b):
            if a == b:
                return 60
            if a is None:
                return 0
            return T_NEAR if continent(a) == continent(b) else T_FAR

        cur, pending_grind, stuck, empty = None, None, 0, {}
        for _round in range(400):
            if ch.level >= 60:
                break
            # quêtes qui traînent dans le journal : abandon (leur zone ne vaut plus le détour)
            for qid in [q for q, age in ch.logage.items() if q in ch.log and ch.zones - age > STALE]:
                del ch.log[qid]
                ch.blocked.add(qid)        # abandonnée pour de bon (sa prise est retirée de la route)
            best = None
            grind_rate = mob_xp(ch.level) / T_MOB
            for zone in allowed:
                if (cur is None and zone != start) or empty.get(zone) == ch.level:
                    continue
                gain, t, n = zone_value(zone)
                if n < 1:
                    continue
                rate = gain / (t + trip(cur, zone))
                if n < MIN_STEPS and cur is not None:
                    rate *= SMALL_PEN
                if cur is not None and continent(cur) != continent(zone):
                    rate /= FAR_EDGE
                if best is None or rate > best[0]:
                    best = (rate, zone, n)
            if not best or (cur is not None and best[0] < grind_rate * GRIND_PREF):
                # rien d'intéressant à ce niveau : un niveau de farm, puis on regarde à nouveau
                if ch.level >= 60:
                    break
                ch.grindat.append(ch.level + 1)
                ch.grind += 1
                ch.add_xp(XP_TO_LEVEL[ch.level] - ch.xp)
                pending_grind = ch.level
                stuck += 1
                if stuck > 12:
                    break
                continue
            stuck = 0
            zone = best[1]
            visits[zone] += 1
            if cur is not None and continent(cur) != continent(zone):
                ch.cross += 1
            steps, l0, l1 = visit(zone, ch, infos, all_maps, trip(cur, zone), best[2] >= 8, pending_grind)
            if pending_grind:
                l0 = min(l0, pending_grind - 1)
            pending_grind = None
            cur = zone
            if not [x for x in steps if x[0] in "ACT"]:
                empty[zone] = ch.level     # passage à vide : on n'y revient pas avant d'avoir monté
                continue
            gid = "%s-%02d-%s%s" % (pid, l0, zone, "" if visits[zone] == 1 else "-%d" % visits[zone])
            text, used = render(zone, steps, l1)
            all_npcs |= used
            guides.append({"id": gid, "zone": zone, "min": l0, "max": max(l1, l0 + 1), "text": text,
                           "n": len(steps)})
        if pending_grind and guides:
            guides[-1]["text"] += '\nL %d "Tue des monstres autour de toi jusqu\'au niveau %d"' % (pending_grind, pending_grind)
            guides[-1]["max"] = max(guides[-1]["max"], pending_grind)
        # quêtes prises mais jamais rendues sur ce parcours : on ne les prend pas
        import re as _re
        turned = set()
        for gd in guides:
            turned |= set(_re.findall(r"^T (\d+)", gd["text"], _re.M))
        for gd in guides:
            gd["text"] = "\n".join(l for l in gd["text"].split("\n")
                                   if not (_re.match(r"^[AC] (\d+)", l) and _re.match(r"^[AC] (\d+)", l).group(1) not in turned))
        # segments vidés par ce nettoyage : supprimés ; deux passages d'affilée dans la même zone : fusionnés
        merged = []
        for gd in guides:
            if not _re.search(r"^[ACT] ", gd["text"], _re.M):
                continue
            if merged and merged[-1]["zone"] == gd["zone"]:
                body = [l for l in gd["text"].split("\n") if not l.startswith(("M ", "G "))]
                merged[-1]["text"] += "\n" + "\n".join(body)
                merged[-1]["max"] = max(merged[-1]["max"], gd["max"])
                merged[-1]["n"] += gd["n"]
            else:
                merged.append(gd)
        guides = merged
        # quêtes dangereuses (monstres de 2 niveaux ou plus au-dessus du personnage) : danger=1
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
        for _t in [int(x) for x in os.environ.get("FP_TRACE", "").split(",") if x]:
            _i = infos.get(_t)
            print("TRACE", pid, _t, g(Q.get(_t), 1), "absente des données du parcours" if not _i else
                  ("faite" if _t in ch.done else "pas faite"), _i and (_i["gmap"], _i["omap"], _i["emap"], "req", _i["req"], "lvl", _i["lvl"], "groupe", _i["group"], "mob", _i["moblvl"], "pre", _i["preSingle"], _i["preGroup"]))
        UNUSED.append((pid, ch, [(z, 0) for z in set(gd["zone"] for gd in guides)], faction))
        ORDER.append((pid, [(gd["zone"], gd["min"], len(_re.findall(r"^[ACT] ", gd["text"], _re.M))) for gd in guides]))
        stats.append((pid, ch.level, len(guides), sum(gd["n"] for gd in guides), ch.grind, dict(ch.src)))
        metrics.append(metrics_of(pid, ch))
        if DRY:
            continue
        # fichier par parcours
        out = ["local _, ns = ...", "",
               "-- GÉNÉRÉ AUTOMATIQUEMENT par tools/gen_routes.py à partir de QuestieDB (Forever).",
               "-- Ne pas modifier à la main : régénérer. Parcours : " + pid, ""]
        for gd in guides:
            sky = any(r in SKY_RACES for r in races)
            race_tbl = "Skyborne = true, SkyborneElf = true, Eolid = true" if sky else ", ".join("%s = true" % r for r in races)
            out.append("ns.RegisterGuide({")
            out.append('    id = "%s",' % gd["id"])
            out.append('    name = %s,' % lua_str("%s %d-%d" % (ZONE_FR[gd["zone"]], gd["min"], gd["max"])))
            out.append('    faction = "%s", race = { %s }, path = "%s",' % (faction, race_tbl, pid))
            if gd["zone"] == "zephras":
                out.append('    startZone = "zephras",')
            out.append('    minLevel = %d, maxLevel = %d,' % (gd["min"], gd["max"]))
            if gd["next"]:
                out.append('    next = "%s",' % gd["next"])
            out.append("    text = [[\n" + gd["text"] + "\n]],")
            out.append("})")
            out.append("")
        fn = "Route_%s.lua" % pid.replace("-", "_")
        open(os.path.join(OUT, fn), "w", encoding="utf-8").write("\n".join(out))
        index.append(fn)
    if "--unused" in sys.argv:
        inv = {v: k for k, v in ZONES.items()}
        for pid, ch, path, faction in UNUSED:
            print("==", pid, "paliers de farm :", " ".join("%d" % l for l in ch.grindat))
            by = defaultdict(list)
            for qid, q in Q.items():
                if qid in ch.done:
                    continue
                ok, _ = races_for(g(q, 6), faction)
                lvl = g(q, 5)
                if not ok or not isinstance(lvl, int) or lvl < 1 or g(q, 7) or (g(q, 17) or 0) < 0 or g(q, 18) or g(q, 19) or g(q, 30) or g(q, 31) or (g(q, 24, 0) or 0) & 3:
                    continue
                ms = set()
                for n in lst(g(g(q, 2, {}), 1)):
                    ms |= set(all_pts(g(N.get(n), 7)))
                for m in ms:
                    by[m].append(lvl)
            onpath = set(ZONES[z] for z, _ in path)
            for m, lv in sorted(by.items(), key=lambda kv: -len(kv[1]))[:40]:
                lv.sort()
                print("  %-14s %s  %3d quêtes non faites, niveaux %d-%d (médiane %d)" % (inv.get(m, m), "sur le parcours" if m in onpath else "HORS parcours  ", len(lv), lv[len(lv)//10], lv[-len(lv)//10 or -1], lv[len(lv)//2]))
    if "--order" in sys.argv:
        for pid, order in ORDER:
            print("==", pid, "(%d segments)" % len(order))
            print("  " + " > ".join("%s %d (%d)" % o for o in order))
    report_metrics(metrics)
    print("assainissement :", ", ".join("%s %d" % kv for kv in sorted(SAN.items())))
    if "--why" in sys.argv:
        print("quêtes écartées (dernier parcours) :", ", ".join("%s %d" % kv for kv in DROP.most_common()))
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
    print("moyenne : %.2f h jusqu'au 60 ; changements de continent %.0f ; segments %.0f ; niveaux de farm %.1f ; part du farm %.0f %% ; quêtes %.0f ; prises à +2 : %.0f, au-delà : %d ; quêtes de groupe %.0f" % (
        avg, sum(m["cross_continent"] for m in metrics) / len(metrics), sum(m["zones"] for m in metrics) / len(metrics), sum(m["grind_levels"] for m in metrics) / len(metrics),
        100 * sum(m["grind_share"] for m in metrics) / len(metrics), sum(m["quests"] for m in metrics) / len(metrics),
        sum(m["at_plus2"] for m in metrics) / len(metrics), sum(1 for m in metrics if m["max_ahead"] > MAX_AHEAD),
        sum(m["group_quests"] for m in metrics) / len(metrics)))
    if not DRY:
        json.dump(metrics, open(path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    return avg

main()
