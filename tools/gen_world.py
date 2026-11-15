"""Génère Data/World.lua à partir de QuestieDB (Forever) : maîtres de classe, aubergistes et
points de récolte (filons, herbes) par carte. Lu comme des données (python -I), jamais exécuté.
Usage : FP_DB=<db.pkl> python3 -I tools/gen_world.py <sortie Data/World.lua>
"""
import os, pickle, sys
from collections import defaultdict

OUT = sys.argv[1]
db = pickle.load(open(os.environ.get("FP_DB") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "db.pkl"), "rb"))
N, O, A2M, NPCFR = db["Npc"], db["Object"], db["area2map"], db["npcFR"]

# Cartes gardées : continents classiques (uiMapID 1411..1458)
def keep(m):
    return isinstance(m, int) and (1411 <= m <= 1458 or m in (2482, 2521, 2524, 2548, 2652))

CLASSES = {"Warrior": "WARRIOR", "Paladin": "PALADIN", "Hunter": "HUNTER", "Rogue": "ROGUE", "Priest": "PRIEST",
           "Shaman": "SHAMAN", "Mage": "MAGE", "Warlock": "WARLOCK", "Druid": "DRUID"}

# compétence requise (Classic)
MINING = {"Copper Vein": 1, "Tin Vein": 65, "Incendicite Mineral Vein": 65, "Silver Vein": 75,
          "Lesser Bloodstone Deposit": 75, "Iron Deposit": 125, "Indurium Mineral Vein": 150, "Gold Vein": 155,
          "Mithril Deposit": 175, "Truesilver Deposit": 230, "Dark Iron Deposit": 230,
          "Small Thorium Vein": 245, "Rich Thorium Vein": 275, "Ooze Covered Silver Vein": 75,
          "Ooze Covered Gold Vein": 155, "Ooze Covered Mithril Deposit": 175, "Ooze Covered Truesilver Deposit": 230,
          "Ooze Covered Thorium Vein": 245, "Ooze Covered Rich Thorium Vein": 275}
HERBS = {"Peacebloom": 1, "Silverleaf": 1, "Earthroot": 15, "Mageroyal": 50, "Briarthorn": 70, "Stranglekelp": 85,
         "Bruiseweed": 100, "Wild Steelbloom": 115, "Grave Moss": 120, "Kingsblood": 125, "Liferoot": 150,
         "Fadeleaf": 160, "Goldthorn": 170, "Khadgar's Whisker": 185, "Wintersbite": 195, "Firebloom": 205,
         "Purple Lotus": 210, "Arthas' Tears": 220, "Sungrass": 230, "Blindweed": 235, "Ghost Mushroom": 245,
         "Gromsblood": 250, "Golden Sansam": 260, "Dreamfoil": 270, "Mountain Silversage": 280, "Plaguebloom": 285,
         "Icecap": 290, "Black Lotus": 300}

def g(t, k, d=None):
    return t.get(k, d) if isinstance(t, dict) else d

def spawns(sp):
    out = defaultdict(list)
    for area, coords in (sp or {}).items():
        m = A2M.get(area)
        if not keep(m):
            continue
        for c in (coords.values() if isinstance(coords, dict) else []):
            x, y = g(c, 1), g(c, 2)
            if isinstance(x, (int, float)) and isinstance(y, (int, float)) and 0 < x < 100 and 0 < y < 100:
                out[m].append((x, y))
    return out

def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

def faction(n):
    f = g(n, 13) or ""
    return {"A": "Alliance", "H": "Horde"}.get(f, "both" if f == "AH" else None)

trainers, inns = [], []
for nid, n in N.items():
    sub = g(n, 14) or ""
    fac = faction(n)
    if not fac:
        continue
    sp = spawns(g(n, 7))
    if not sp:
        continue
    m, pts = max(sp.items(), key=lambda kv: len(kv[1]))
    x, y = pts[0]
    name = g(NPCFR.get(nid), 1) or g(n, 1)
    SECONDARY = {"First Aid Trainer": "FIRSTAID", "Cooking Trainer": "COOKING", "Fishing Trainer": "FISHING",
                 "Fishing Trainer & Supplies": "FISHING"}
    if sub.endswith(" Trainer") and sub[:-8] in CLASSES:
        trainers.append((CLASSES[sub[:-8]], nid, m, x, y, fac, name))
    elif sub in SECONDARY:
        trainers.append((SECONDARY[sub], nid, m, x, y, fac, name))
    elif sub == "Innkeeper":
        inns.append((nid, m, x, y, fac, name))

B = 1000
def enc(x, y):
    # 3 chiffres par coordonnée (précision 0,1 %), points séparés implicitement (6 caractères)
    return "%03d%03d" % (min(999, int(x * 10)), min(999, int(y * 10)))

nodes = defaultdict(lambda: defaultdict(list))   # map -> (kind, skill, name) -> pts
for oid, o in O.items():
    name = g(o, 1)
    kind = "mine" if name in MINING else "herb" if name in HERBS else None
    if not kind:
        continue
    skill = (MINING if kind == "mine" else HERBS)[name]
    for m, pts in spawns(g(o, 4)).items():
        nodes[m][(kind, skill, name)].extend(pts)

out = ["local _, ns = ...", "",
       "-- GÉNÉRÉ par tools/gen_world.py à partir de QuestieDB (Forever, GPLv3). Ne pas modifier à la main.",
       "ns.World = ns.World or {}", "",
       "-- { classe, idPNJ, carte, x, y, faction, nom }", "ns.World.trainers = {"]
for t in sorted(trainers):
    out.append("    { %s, %d, %d, %.1f, %.1f, %s, %s }," % (lua_str(t[0]), t[1], t[2], t[3], t[4], lua_str(t[5]), lua_str(t[6])))
out += ["}", "", "-- { idPNJ, carte, x, y, faction, nom }", "ns.World.inns = {"]
for t in sorted(inns):
    out.append("    { %d, %d, %.1f, %.1f, %s, %s }," % (t[0], t[1], t[2], t[3], lua_str(t[4]), lua_str(t[5])))
out += ["}", "", "-- [carte] = { { type, compétence, nom, \"xxxyyy...\" (6 chiffres par point, x et y en ‰) } }",
        "ns.World.nodes = {"]
total = 0
for m in sorted(nodes):
    out.append("    [%d] = {" % m)
    for (kind, skill, name), pts in sorted(nodes[m].items(), key=lambda kv: (kv[0][0], kv[0][1], kv[0][2])):
        seen, s = set(), []
        for x, y in pts:
            e = enc(x, y)
            if e not in seen:
                seen.add(e)
                s.append(e)
        total += len(s)
        out.append("        { %s, %d, %s, \"%s\" }," % (lua_str(kind), skill, lua_str(name), "".join(s)))
    out.append("    },")
out.append("}")

# --- quêtes de donjon (donjons Classic présents dans QuestieDB) : à prendre avant d'y aller
Q, QFR = db["Quest"], db["questFR"]
DUNGEONS = {  # zone Questie : (fr, en, min, max)
    1581: ("Les Mortemines", "The Deadmines", 17, 26), 718: ("Cavernes des Lamentations", "Wailing Caverns", 17, 24),
    209: ("Donjon d'Ombrecroc", "Shadowfang Keep", 22, 30), 717: ("La Prison", "The Stockade", 24, 32),
    719: ("Profondeurs de Brassenoire", "Blackfathom Deeps", 24, 32), 133: ("Gnomeregan", "Gnomeregan", 29, 38),
    1717: ("Kraal de Tranchebauge", "Razorfen Kraul", 29, 38), 796: ("Monastère écarlate", "Scarlet Monastery", 34, 45),
    722: ("Souilles de Tranchebauge", "Razorfen Downs", 37, 46), 1417: ("Temple englouti", "Sunken Temple", 45, 54),
    2100: ("Maraudon", "Maraudon", 46, 55), 1977: ("Zul'Gurub", "Zul'Gurub", 58, 60),
    1584: ("Profondeurs de Rochenoire", "Blackrock Depths", 52, 60), 1583: ("Pic Rochenoire", "Blackrock Spire", 55, 60),
    2557: ("Hache-Tripes", "Dire Maul", 55, 60), 2057: ("Scholomance", "Scholomance", 58, 60),
    2017: ("Stratholme", "Stratholme", 58, 60), 2437: ("Gouffre de Ragefeu", "Ragefire Chasm", 13, 18),
    # nouveaux donjons de Forever (zones reconnues à l'emplacement de leurs donneurs de quêtes)
    16611: ("Ruines de Lordaeron", "Ruins of Lordaeron", 15, 22),
    16732: ("Excavations : les Paluns", "Excavation Site: Wetlands", 24, 31),
    16544: ("Cité de Dalaran", "City of Dalaran", 28, 35),
}
ALLI, HORDE = 1 | 4 | 8 | 64, 2 | 16 | 32 | 128
dq = defaultdict(list)
for qid, q in Q.items():
    z = g(q, 17)
    if z not in DUNGEONS or g(q, 7):
        continue
    races = g(q, 6) or 0
    fac = "both" if races == 0 or (races & ALLI and races & HORDE) else "Alliance" if races & ALLI else "Horde"
    starters = list((g(g(q, 2), 1) or {}).values())
    if not starters:
        continue
    giver = N.get(starters[0])
    sp = spawns(g(giver, 7))
    if not sp:
        continue
    m, pts = max(sp.items(), key=lambda kv: len(kv[1]))
    title = g(QFR.get(qid), 1) or g(q, 1) or ""
    dq[z].append((qid, g(q, 5, 0) or 0, g(q, 4, 1) or 1, fac, starters[0], m, pts[0][0], pts[0][1], title, g(q, 1) or title))
out2 = ["", "-- [zone] = { fr, en, min, max, quêtes = { { id, niveau, niveau requis, faction, PNJ, carte, x, y, titre fr, titre en } } }",
        "ns.World.dungeons = {"]
nq = 0
for z, (fr, en, lo, hi) in sorted(DUNGEONS.items(), key=lambda kv: kv[1][2]):
    qs = sorted(dq.get(z, []), key=lambda t: t[1])
    if not qs:
        continue
    out2.append("    { %s, %s, %d, %d, {" % (lua_str(fr), lua_str(en), lo, hi))
    for t in qs:
        nq += 1
        out2.append("        { %d, %d, %d, %s, %d, %d, %.1f, %.1f, %s, %s }," % (t[0], t[1], t[2], lua_str(t[3]), t[4], t[5], t[6], t[7], lua_str(t[8]), lua_str(t[9])))
    out2.append("    } },")
out2.append("}")
out += out2

# --- rares (rang 2 = rare élite, 4 = rare) : { idPNJ, carte, x, y, niv min, niv max, rang, nom }
rares = []
for nid, n in N.items():
    rank = g(n, 6, 0)
    if rank not in (2, 4):
        continue
    sp = spawns(g(n, 7))
    if not sp:
        continue
    m, pts = max(sp.items(), key=lambda kv: len(kv[1]))
    rares.append((nid, m, pts[0][0], pts[0][1], g(n, 4, 0) or 0, g(n, 5, 0) or 0, rank, g(NPCFR.get(nid), 1) or g(n, 1) or "?"))
out.append("")
out.append("ns.World.rares = {")
for r in sorted(rares, key=lambda t: (t[1], t[0])):
    out.append("    { %d, %d, %.1f, %.1f, %d, %d, %d, %s }," % (r[0], r[1], r[2], r[3], r[4], r[5], r[6], lua_str(r[7])))
out.append("}")
print("rares : %d" % len(rares))
open(OUT, "w", encoding="utf-8").write("\n".join(out) + "\n")
print("quêtes de donjon : %d" % nq)
print("maîtres : %d, aubergistes : %d, points de récolte : %d, %d Ko" % (len(trainers), len(inns), total,
      os.path.getsize(OUT) // 1024))
