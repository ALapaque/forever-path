"""Garde-fous sur les routes générées (Guides/Route_*.lua) et leurs mesures (tools/route_metrics.json).
Sans base de données : ne lit que les fichiers du dépôt. Lancé par la CI."""
import glob, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
fail = []

def check(ok, msg):
    print(("ok - " if ok else "FAIL - ") + msg)
    if not ok:
        fail.append(msg)

overrides = json.load(open(os.path.join(ROOT, "tools", "overrides.json"), encoding="utf-8"))["quests"]
confirmed = {int(k) for k, o in overrides.items() if o.get("confirm")}
excluded = {int(k) for k, o in overrides.items() if o.get("exclude")}
collected_path = os.path.join(ROOT, "tools", "collected.json")
if os.path.exists(collected_path):
    doc = json.load(open(collected_path, encoding="utf-8"))
    confirmed |= set(doc.get("seen", [])) | {int(k) for k in doc.get("quests", {})}

# recoupement avec les autres bases (tools/cross.json) : quêtes qui ne sont pas dans le jeu, niveau requis
# selon le serveur, prérequis connus de Polestar
cross = {int(k): v for k, v in json.load(open(os.path.join(ROOT, "tools", "cross.json"), encoding="utf-8"))["quests"].items()}

files = sorted(glob.glob(os.path.join(ROOT, "Guides", "Route_*.lua")))
check(len(files) == 8, "8 parcours générés")
for f in files:
    name = os.path.basename(f)[6:-4]
    s = open(f, encoding="utf-8").read()
    acc, turned, order_bad, foreign, banned = set(), set(), 0, 0, 0
    # chaque prise d'une quête de Forever (au-delà du niveau 1) dit son niveau requis : l'addon la met de côté en dessous
    # (sauf si le serveur dit qu'elle se prend dès le niveau 1)
    no_req = [l for l in re.findall(r"^A \d+[^\n]*$", s, re.M) if int(l.split()[1]) >= 90000 and " req=" not in l and " lvl=1 " not in l + " "
              and (cross.get(int(l.split()[1]), {}).get("m") or cross.get(int(l.split()[1]), {}).get("pm")) != 1]
    bad_req = [(r, l) for l, r in re.findall(r"^A \d+[^\n]* lvl=(\d+) req=(\d+)", s, re.M) if int(r) > int(l)]
    check(not no_req, "%s : niveau requis indiqué pour chaque prise de quête Forever (%d sans)" % (name, len(no_req)))
    check(not bad_req, "%s : niveau requis jamais au-dessus du niveau de la quête" % name)
    for kind, q in re.findall(r"^([ACT]) (\d+)", s, re.M):
        q = int(q)
        if 9665 < q < 90000 and q not in confirmed:
            foreign += 1
        if q in excluded:
            banned += 1
        if kind == "A":
            order_bad += q in acc
            acc.add(q)
        else:
            order_bad += q not in acc
            if kind == "T":
                turned.add(q)
    check(order_bad == 0, "%s : chaque quête est prise une fois, avant d'être faite et rendue" % name)
    gone, low, pre_bad, done = [], [], [], set()
    for line in re.findall(r"^[AT] \d+[^\n]*$", s, re.M):
        q = int(line.split()[1])
        if line[0] == "T":
            done.add(q)
            continue
        c = cross.get(q, {})
        if c.get("x") and q not in confirmed:
            gone.append(q)
        m = re.search(r" req=(\d+)", line)
        if c.get("m") and (int(m.group(1)) if m else 1) < min(c["m"], c.get("l") or 60):
            low.append(q)
        if not set(c.get("pa", ())) <= done or (c.get("pn") and not set(c["pn"]) & done):
            pre_bad.append(q)
    check(not gone, "%s : aucune quête absente du jeu selon Questie, le serveur ou Polestar %s" % (name, gone[:5]))
    check(not low, "%s : niveau requis jamais sous celui du serveur %s" % (name, low[:5]))
    check(not pre_bad, "%s : prérequis connus rendus avant chaque prise %s" % (name, pre_bad[:5]))
    check(acc == turned, "%s : toute quête prise est rendue (%d prises, %d rendues)" % (name, len(acc), len(turned)))
    check(foreign == 0, "%s : aucune quête d'une autre version du jeu (IDs 9666-89999 non confirmés)" % name)
    check(banned == 0, "%s : aucune quête exclue à la main" % name)
    check(len(acc) >= 450, "%s : au moins 450 quêtes (%d)" % (name, len(acc)))
    segs = re.findall(r'minLevel = (\d+), maxLevel = (\d+)', s)
    check(segs and segs[0][0] == "1", "%s : commence au niveau 1" % name)
    check(all(int(a) < int(b) for a, b in segs), "%s : segments aux niveaux cohérents" % name)
    ids = re.findall(r'^    id = "([^"]+)"', s, re.M)
    nexts = re.findall(r'^    next = "([^"]+)"', s, re.M)
    check(len(set(ids)) == len(ids) and nexts == ids[1:], "%s : segments uniques et enchaînés" % name)
    empty = [i for i, t in zip(ids, re.findall(r"text = \[\[\n(.*?)\n\]\]", s, re.S)) if not re.search(r"^[ACT] ", t, re.M)]
    check(not empty, "%s : aucun segment vide" % name)

metrics = json.load(open(os.path.join(ROOT, "tools", "route_metrics.json"), encoding="utf-8"))
check(len(metrics) == 8, "mesures pour les 8 parcours")
for m in metrics:
    p = m["path"]
    check(m["level"] == 60, "%s : la route mène au niveau 60" % p)
    check(m.get("max_ahead", 9) <= 2, "%s : aucune quête prise à plus de 2 niveaux au-dessus (max +%s)" % (p, m.get("max_ahead")))
    check(m["grind_share"] <= 0.32, "%s : part du farm %.0f %% (plafond 32 %%)" % (p, 100 * m["grind_share"]))
    check(m.get("cross_continent", 99) <= 18, "%s : %s changements de continent (plafond 18)" % (p, m.get("cross_continent")))
avg = sum(m["grind_share"] for m in metrics) / len(metrics)
check(avg <= 0.27, "part moyenne du farm %.0f %% (plafond 27 %%)" % (100 * avg))
if fail:
    print("%d échec(s)" % len(fail))
    sys.exit(1)
print("ALL TESTS PASSED")
