-- Scénario : mode Hardcore, rattrapage, quêtes de donjon, écran de splits
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
FireEvent("ADDON_LOADED", "ForeverPath")
FireEvent("PLAYER_LOGIN")
RunTimers()
local E = ns.Engine

ns.Guides["test-hc"] = { id = "test-hc", name = "HC", steps = ns.ParseGuide([[
M elwynn
A 100 @40,60 lvl=5 danger=1
C 100 @45,62 danger=1
T 100 @40,60 danger=1
A 101 @40,60 lvl=4
A 102 @41,61 lvl=12
]]) }
PLAYER.level = 5
E.Load("test-hc")
check(select(3, E.Current()) == 1, "sans Hardcore : quête dangereuse proposée")
ns.SetModuleEnabled("hardcore", true)
E.Refresh()
check(select(3, E.Current()) == 4, "Hardcore : prise, objectif et rendu sautés")
QLOG[100] = { complete = false }
E.Load("test-hc")
check(E.IsDone(ns.Guides["test-hc"].steps[2], 2) == false, "quête déjà prise : on la termine quand même")
QLOG[100] = nil
ns.SetModuleEnabled("hardcore", false)

-- rattrapage : quête grise non prise sautée
PLAYER.level = 14
E.Load("test-hc")
local _, st, i = E.Current()
check(st.quest == 102, "rattrapage : quêtes niv. 4-5 sautées au niveau 14 (étape "..i..")")
ns.Modules.catchup:SetOpt("gap", 12)
E.Load("test-hc")
check(select(2, E.Current()).quest == 100, "écart réglable")
ns.Modules.catchup:SetOpt("gap", 9)

-- donjons
PLAYER.level, PLAYER.faction = 20, "Alliance"
local list = ns.Modules.dungeons.ForLevel(20)
local names = {}
for _, d in ipairs(list) do names[#names + 1] = d.name end
check(#list > 0, "donjons au niveau 20 : "..table.concat(names, ", "))
local dm
for _, d in ipairs(list) do if d.name == "Les Mortemines" then dm = d end end
check(dm and #dm.quests > 0, "quêtes des Mortemines ("..(dm and #dm.quests or 0)..")")
PLAYER.faction = "Horde"
local hasDM = false
for _, d in ipairs(ns.Modules.dungeons.ForLevel(20)) do
  if d.name == "Les Mortemines" then for _, q in ipairs(d.quests) do if q.id == dm.quests[1].id then hasDM = true end end end
end
check(not hasDM, "quêtes de faction filtrées")
PLAYER.faction = "Alliance"
check(ns.Modules.dungeons.List():find("Mortemines"), "/fp donjons")

-- splits
local S = ns.Modules.splits
S.Finish("seg-a", 1200)
S.Finish("seg-a", 1100)
check(ns.db.segRecords["seg-a"] == 1100, "record de segment")
check(ns.cdb.splits[1].delta == -100, "écart avec le record (-1:40)")
check(S.Fmt(3725) == "1:02:05", "format des temps")
print("ALL TESTS PASSED")
