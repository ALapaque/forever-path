"""Read QuestieDB Forever data files as plain data and pickle them."""
import os, pickle, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from luadata import parse_return_table, extract_assigned_string

D = sys.argv[1]  # .../QuestieDB/data/Forever/
out = {}
for kind, var in [("Quest", "QuestieDB.questData"), ("Npc", "QuestieDB.npcData"),
                  ("Object", "QuestieDB.objectData"), ("Item", "QuestieDB.itemData")]:
    t0 = time.time()
    text = open(D + "forever%sDB.lua" % kind, encoding="utf-8").read()
    out[kind] = parse_return_table(extract_assigned_string(text, var))
    print(kind, len(out[kind]), "%.1fs" % (time.time() - t0))
pickle.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "db.pkl"), "wb"))

# Support data
from luadata import extract_assigned_table
S = D + "../../support/Forever/"
z = open(S + "Zones/areaIdToUiMapId.lua", encoding="utf-8").read()
area = parse_return_table(extract_assigned_string(z, "ZoneDB.private.areaIdToUiMapId"))
over = parse_return_table(extract_assigned_string(z, "ZoneDB.private.areaIdToUiMapIdOverride"))
area.update(over)
xp = extract_assigned_table(open(S + "QuestXP/xpDB-classic.lua", encoding="utf-8").read(), "QuestXP.db")
out["area2map"] = area
out["xp"] = xp
print("area", len(area), "xp", len(xp))
pickle.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "db.pkl"), "wb"))

# French NPC / quest names
L10 = D + "../../l10n/Forever/"
for kind, var in [("npcFR", 'l10n.npcNameLookup["frFR"] = loadstring('), ("questFR", 'l10n.questLookup["frFR"] = loadstring(')]:
    sub = "lookupNpcs" if kind == "npcFR" else "lookupQuests"
    txt = open(L10 + sub + "/frFR.lua", encoding="utf-8").read()
    i = txt.find(var)
    if i < 0:
        import re as _re
        m = _re.search(r"l10n\.\w+\[\"frFR\"\]\s*=\s*loadstring\(", txt)
        i = m.start(); var = m.group(0)
    rest = txt[i + len(var):]
    from luadata import Parser
    p = Parser(rest); inner = p.long_string()
    out[kind] = parse_return_table(inner)
    print(kind, len(out[kind]))
pickle.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "db.pkl"), "wb"))
