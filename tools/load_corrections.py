"""Applique les corrections Forever de QuestieDB (nouveau contenu de WoW Forever) à db.pkl.

QuestieDB garde les quêtes, PNJ et objets propres à Forever hors de data/Forever, dans
src/corrections/Forever : la base générée (generated/), les corrections écrites à la main
(forever*Fixes.lua) et les traces QuestieTrace (traces/). Ces fichiers sont du code Lua ; on ne
l'exécute pas : on lit le tableau renvoyé par Load() comme une donnée, en résolvant seulement les
symboles connus (questKeys.x, raceIDs.x, zoneIDs.x...) et les sommes « a + b ».

Usage : python3 -I tools/load_corrections.py <QuestieDB> [db.pkl d'entrée] [db.pkl de sortie]
"""
import os, pickle, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from luadata import Parser, NIL, _num  # noqa: E402

ROOT = sys.argv[1].rstrip("/")
SRC = ROOT + "/src"
IN = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "db.pkl")
OUT = sys.argv[3] if len(sys.argv) > 3 else IN

# ------------------------------------------------------------------ symboles
SYM = {}          # "questKeys.name" -> 1 ; "zoneIDs.DUROTAR" -> 14 ...
FLAT = {}         # "DUROTAR" -> 14 (repli quand le préfixe est un alias local)

for ent, prefix in (("quest", "questKeys"), ("npc", "npcKeys"), ("object", "objectKeys"), ("item", "itemKeys")):
    text = open("%s/meta/%sMeta.lua" % (SRC, ent), encoding="utf-8").read()
    block = text[text.index("keys = {"):]
    block = block[:block.index("\n  },")]
    for name, idx in re.findall(r"\['(\w+)'\]\s*=\s*(\d+)", block):
        idx = int(idx)
        SYM["%s.%s" % (prefix, name)] = idx
        SYM["%s.%s_add" % (prefix, name)] = idx + 1000
        SYM["%s.%s_remove" % (prefix, name)] = idx - 1000

ENUM_DIR = SRC + "/corrections/enum"
for fn in os.listdir(ENUM_DIR):
    stack = []
    for line in open(os.path.join(ENUM_DIR, fn), encoding="utf-8"):
        line = line.split("--")[0]
        m = re.match(r"\s*constants\.(\w+)\s*=\s*\{", line) or re.match(r"\s*(\w+)\s*=\s*\{", line)
        if m:
            stack.append(m.group(1))
        for name, val in re.findall(r"\b([A-Z][A-Z0-9_]*)\s*=\s*(-?\d+)\b", line):
            FLAT.setdefault(name, int(val))
            if stack:
                SYM["%s.%s" % (stack[-1], name)] = int(val)
        if re.match(r"\s*\},?\s*$", line) and stack:
            stack.pop()

# masques de races Forever (bits 32/33 pour les Skyborne)
RACE = {"NONE": 0, "HUMAN": 1, "ORC": 2, "DWARF": 4, "NIGHT_ELF": 8, "UNDEAD": 16, "TAUREN": 32, "GNOME": 64,
        "TROLL": 128, "GOBLIN": 256, "SKYBORNE_ALLIANCE": 2 ** 32, "SKYBORNE_HORDE": 2 ** 33}
RACE["ALL_ALLIANCE"] = 1 + 4 + 8 + 64 + RACE["SKYBORNE_ALLIANCE"]
RACE["ALL_HORDE"] = 2 + 16 + 32 + 128 + RACE["SKYBORNE_HORDE"]
for k, v in RACE.items():
    SYM["raceIDs." + k] = SYM["raceKeys." + k] = v
ALIAS = {"raceIDs": "raceKeys", "classIDs": "classKeys", "zoneIDs": "zoneIDs", "sortKeys": "sortKeys",
         "factionIDs": "factionIDs", "profKeys": "professionKeys", "specialFlags": "specialFlags",
         "questFlags": "questFlags"}

unknown = {}


def resolve(name):
    if name in SYM:
        return SYM[name]
    head, _, tail = name.partition(".")
    if head in ALIAS and "%s.%s" % (ALIAS[head], tail) in SYM:
        return SYM["%s.%s" % (ALIAS[head], tail)]
    last = name.rsplit(".", 1)[-1]
    if last in FLAT:
        return FLAT[last]
    unknown[name] = unknown.get(name, 0) + 1
    raise KeyError(name)


_dotted = re.compile(r"[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*")


class SymParser(Parser):
    """Tableaux Lua + symboles connus + sommes. Un symbole inconnu rend la valeur nulle."""

    def primary(self):
        c = self.peek()
        if c == "(":
            self.i += 1
            v = self.expr()
            self.expect(")")
            return v
        if c == "-" and not _num.match(self.s, self.i):
            self.i += 1
            v = self.primary()
            return -v if isinstance(v, (int, float)) else None
        m = _dotted.match(self.s, self.i)
        if m and m.group(0) not in ("nil", "true", "false"):
            self.i = m.end()
            try:
                return resolve(m.group(0))
            except KeyError:
                return None
        return Parser.value(self)

    def expr(self):
        v = self.primary()
        while True:
            c = self.peek()
            if c in "+-" and self.s[self.i:self.i + 2] != "--":
                self.i += 1
                w = self.primary()
                v = (v + w if c == "+" else v - w) if isinstance(v, (int, float)) and isinstance(w, (int, float)) else None
            else:
                return v

    value = expr


def load_return(path):
    text = open(path, encoding="utf-8").read()
    m = re.search(r"function\s+[\w.:]+Load\s*\(\s*\)", text)
    if not m:
        return {}
    i = text.index("return", m.end())
    p = SymParser(text)
    p.i = i + len("return")
    return p.value() or {}


# ------------------------------------------------------------------ fusion
def is_list(t):
    return isinstance(t, dict) and all(isinstance(k, int) for k in t)


def add_into(a, b):
    """Opération _add : listes d'identifiants unies, tables fusionnées."""
    if not isinstance(a, dict):
        return b
    if not isinstance(b, dict):
        return a
    if is_list(a) and is_list(b) and all(not isinstance(v, dict) for v in list(a.values()) + list(b.values())):
        vals = list(a.values())
        for v in b.values():
            if v not in vals:
                vals.append(v)
        return {k + 1: v for k, v in enumerate(vals)}
    out = dict(a)
    for k, v in b.items():
        out[k] = add_into(out[k], v) if k in out else v
    return out


def apply(base, patch, stats):
    for eid, fields in patch.items():
        if not isinstance(eid, int) or not isinstance(fields, dict):
            continue
        new = eid not in base
        cur = base.setdefault(eid, {})
        for k, v in fields.items():
            if not isinstance(k, int) or v is NIL:
                continue
            if k > 1000:
                f = k - 1000
                cur[f] = add_into(cur.get(f), v) if f in cur else v
            elif k < 0:
                continue          # _remove : rare, ignoré
            else:
                cur[k] = v
        stats["new" if new else "patched"] += 1


db = pickle.load(open(IN, "rb"))
FOR = SRC + "/corrections/Forever"
ORDER = [
    ("Quest", "generated/foreverBaseQuest.lua"), ("Npc", "generated/foreverBaseNpc.lua"),
    ("Object", "generated/foreverBaseObject.lua"), ("Item", "generated/foreverBaseItem.lua"),
    ("Quest", "foreverQuestFixes.lua"), ("Npc", "foreverNPCFixes.lua"),
    ("Object", "foreverObjectFixes.lua"), ("Item", "foreverItemFixes.lua"),
    ("Quest", "traces/foreverQuestTraces.lua"), ("Quest", "traces/foreverQuestRelationTraces.lua"),
    ("Npc", "traces/foreverNpcTraces.lua"), ("Object", "traces/foreverObjectTraces.lua"),
    ("Item", "traces/foreverItemTraces.lua"),
]
for kind, rel in ORDER:
    path = os.path.join(FOR, rel)
    if not os.path.exists(path):
        print("absent :", rel)
        continue
    stats = {"new": 0, "patched": 0}
    apply(db[kind], load_return(path), stats)
    print("%-40s %s : %5d nouveaux, %5d corrigés" % (rel, kind, stats["new"], stats["patched"]))

# zones des nouvelles cartes (areaId -> uiMapID) : traces de zones si présentes
qmax = max(db["Quest"])
print("quêtes : %d (dont %d au-delà de Classic), PNJ : %d, objets : %d, max id %d"
      % (len(db["Quest"]), sum(1 for q in db["Quest"] if q > 9665), len(db["Npc"]), len(db["Object"]), qmax))
if unknown:
    print("symboles inconnus :", ", ".join("%s×%d" % kv for kv in sorted(unknown.items(), key=lambda kv: -kv[1])[:12]))
pickle.dump(db, open(OUT, "wb"))
