"""Construit tools/cross.json : ce que d'autres bases libres savent des quêtes de WoW Forever, pour
recouper QuestieDB dans gen_routes.py (quêtes qui ne sont pas dans le jeu, niveau requis, races,
prérequis). Les trois sources sont lues comme de simples données, rien n'est exécuté.

  1. Questie (GPLv3) : sa liste de quêtes masquées (Database/Corrections/QuestieQuestBlacklist.lua),
     évaluée pour Forever. QuestieDB ne la contient pas : c'est Questie qui l'applique en jeu.
  2. EG Link (Efficient Games, CC BY 4.0) : ce que le serveur du jeu répond pour chaque quête
     (niveau, niveau requis, races) et les quêtes pour lesquelles il ne répond rien.
  3. Polestar forever-db (GPL-3.0) : prérequis, classes, quêtes retirées après vérification en jeu.

Usage : python3 -I tools/load_cross.py <Questie> <eg-link-output-wowf> <polestar/forever-db> [sortie]
"""
import json, os, re, subprocess, sys

QUESTIE, EG, POLESTAR = (a.rstrip("/") for a in sys.argv[1:4])
OUT = sys.argv[4] if len(sys.argv) > 4 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "cross.json")
LIVE_BUILD = 70790          # premier build du jeu sorti (4 novembre 2026) ; avant : bêta
KNOWN_RACES = 0xFF | 2 ** 32 | 2 ** 33
ALL_RACES = (1 << 64) - 1

def rev(path):
    try:
        return subprocess.run(["git", "-C", path, "log", "-1", "--format=%h %ad", "--date=short"],
                              capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        return "?"

quests = {}
def rec(qid):
    return quests.setdefault(int(qid), {})

# ------------------------------------------------------------------ 1. liste noire de Questie
src = open(QUESTIE + "/Database/Corrections/QuestieQuestBlacklist.lua", encoding="utf-8").read()
body = src[src.index("local questsToBlacklist = {"):src.index("if Questie.IsSoD then")]
EXP = {"Era": 1, "Tbc": 2, "Wotlk": 3, "Cata": 4, "MoP": 5}

def blacklisted(expr):
    """Valeur de l'expression pour Forever (contenu Classic Era, Questie.IsForever vrai)."""
    e = re.sub(r"Expansions\.Current", "1", expr)
    e = re.sub(r"Expansions\.(\w+)", lambda m: str(EXP[m.group(1)]), e)
    e = e.replace("~=", "!=")
    e = re.sub(r"Questie\.IsForever", "True", e)
    e = re.sub(r"Questie\.Is\w+", "False", e)
    e = re.sub(r"ContentPhases\.activePhases\.\w+", "99", e)
    e = e.replace("HIDE_ON_MAP", "True").replace("true", "True").replace("false", "False")
    if not re.fullmatch(r"(True|False|and|or|not|\d+|[<>=!()\s])+", e):
        raise ValueError("expression de liste noire non comprise : " + expr)
    return bool(eval(e, {"__builtins__": {}}, {}))

n_bl = 0
for line in body.splitlines():
    m = re.match(r"\s*\[(\d+)\]\s*=\s*(.*?),?\s*(--.*)?$", line)
    if m and blacklisted(m.group(2)):
        rec(m.group(1))["x"] = "questie"
        n_bl += 1

# ------------------------------------------------------------------ 2. EG Link (réponses du serveur)
base = EG + "/data/wowf/"
builds = sorted((b for b in os.listdir(base) if int(b.split(".")[-1]) >= LIVE_BUILD), key=lambda b: int(b.split(".")[-1]))
described, nodata, n_srv = set(), set(), 0
for b in builds:                      # du plus ancien au plus récent : la dernière réponse l'emporte
    p = "%s%s/quests.enUS.json" % (base, b)
    if os.path.exists(p):
        for k, v in json.load(open(p, encoding="utf-8"))["quests"].items():
            r = rec(k)
            if isinstance(v.get("minLevel"), int) and v["minLevel"] > 0:
                r["m"] = v["minLevel"]
            if isinstance(v.get("level"), int) and v["level"] > 0:
                r["l"] = v["level"]
            mask = int(v["raceMask"], 16) if v.get("raceMask") else ALL_RACES
            if mask != ALL_RACES and mask & KNOWN_RACES:
                r["r"] = mask & KNOWN_RACES
            else:
                r.pop("r", None)
            described.add(int(k))
    p = "%s%s/quest_scan.json" % (base, b)
    if os.path.exists(p):
        j = json.load(open(p, encoding="utf-8"))
        for k in j["described"]:
            described.add(int(k)); nodata.discard(int(k))
        nodata |= set(int(k) for k in j["noData"])
for k in nodata - described:
    rec(k).setdefault("x", "serveur")
n_srv = len(described)

# ------------------------------------------------------------------ 3. Polestar forever-db
def rows(table):
    with open("%s/data/%s.jsonl" % (POLESTAR, table), encoding="utf-8") as f:
        return [json.loads(l) for l in f if l.strip()]

pre_all, pre_any, classes, pmin, praces = {}, {}, {}, {}, {}
for r in rows("quest"):
    if r.get("classes"):
        classes[r["id"]] = r["classes"]
    if r.get("races"):
        praces[r["id"]] = r["races"]
    if r.get("min_level"):
        pmin[r["id"]] = r["min_level"]
for r in rows("quest_prereq"):
    if r.get("breadcrumb"):
        continue                      # quête d'introduction : facultative, n'empêche pas la suite
    (pre_all if r["mode"] == "all" else pre_any).setdefault(r["quest"], set()).add(r["pre"])
n_rm = 0
for k, v in json.load(open(POLESTAR + "/corrections/quests.json", encoding="utf-8")).items():
    k = int(k)
    if v.get("remove"):
        rec(k)["x"] = "polestar"
        n_rm += 1
        continue
    s = v.get("set") or {}
    if "minLevel" in s: pmin[k] = s["minLevel"]
    if "classes" in s: classes[k] = s["classes"]
    if "races" in s: praces[k] = s["races"]
    if "pre" in s: pre_any[k] = set(s["pre"] or []); pre_all.pop(k, None)
    if "preAny" in s: pre_any[k] = set(s["preAny"] or [])
    if "preAll" in s: pre_all[k] = set(s["preAll"] or [])
# un prérequis qui n'est pas dans le jeu ne peut pas être exigé : les bases se contredisent, il est ignoré
gone = set(k for k, v in quests.items() if v.get("x"))
for table in (pre_all, pre_any):
    for k in list(table):
        table[k] = table[k] - gone
for k, v in pmin.items():
    rec(k)["pm"] = v
for k, v in praces.items():
    if v and v & KNOWN_RACES:
        rec(k)["pr"] = v & KNOWN_RACES
for k, v in classes.items():
    if v:
        rec(k)["c"] = v
for k, v in pre_all.items():
    if v:
        rec(k)["pa"] = sorted(v)
for k, v in pre_any.items():
    if v:
        rec(k)["pn"] = sorted(v)

doc = {
    "_doc": "Recoupement des quêtes de WoW Forever, écrit par tools/load_cross.py et lu par tools/gen_routes.py. "
            "Par quête : x (quête qui n'est pas dans le jeu, avec la source qui le dit), m et l (niveau requis et "
            "niveau de la quête selon le serveur), r (masque des races selon le serveur), pm et pr (niveau requis et "
            "masque des races selon Polestar), c (masque des classes), pa et pn (prérequis : tous / au moins un).",
    "_sources": {
        "questie": {"url": "https://github.com/Questie/Questie", "licence": "GPL-3.0", "version": rev(QUESTIE),
                    "quetes_masquees": n_bl},
        "eg_link": {"url": "https://github.com/JIVESCORP/eg-link-output-wowf", "licence": "CC BY 4.0",
                    "credit": "Data from Efficient Games (https://efficient.games), licensed under CC BY 4.0 "
                              "(https://creativecommons.org/licenses/by/4.0/); reduced to quest facts.",
                    "version": rev(EG), "builds": builds, "quetes_decrites": n_srv,
                    "sans_reponse": len(nodata - described)},
        "polestar": {"url": "https://github.com/fitzforge/polestar/tree/next/forever-db", "licence": "GPL-3.0",
                     "version": rev(POLESTAR), "retirees": n_rm},
    },
    "quests": {str(k): quests[k] for k in sorted(quests)},
}
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    f.write("\n")
print("%d quêtes recoupées -> %s (%d Ko)" % (len(quests), OUT, os.path.getsize(OUT) // 1024))
print("  Questie : %d quêtes masquées ; serveur : %d décrites, %d sans réponse ; Polestar : %d retirées, "
      "%d avec prérequis" % (n_bl, n_srv, len(nodata - described), n_rm, len(set(pre_all) | set(pre_any))))
