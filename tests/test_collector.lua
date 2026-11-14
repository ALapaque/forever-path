-- Scénario : le Collecteur note une nouvelle quête (dialogue, prise, objectifs, rendu, carte) et l'exporte
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
time = function() return 300000 end
FireEvent("ADDON_LOADED", "ForeverPath")
FireEvent("PLAYER_LOGIN")
RunTimers()
local C = ns.Modules.collector
check(C.enabled, "collecteur actif par défaut")
check(not C.Wanted(783) and C.Wanted(20001), "seules les quêtes inconnues sont collectées")

PLAYER.map, PLAYER.x, PLAYER.y, PLAYER.faction = 1411, 0.521, 0.432, "Horde"
UnitGUID = function(u) if u == "npc" then return "Creature-0-1-2-3-99001-0000" end if u == "target" then return "Creature-0-1-2-3-3098-0001" end end
UnitName = function(u) return u == "npc" and "Garde de Forever" or "Tester" end
UnitCanAttack = function() return true end
C_GossipInfo.GetAvailableQuests = function() return { { questID = 20001, title = "Les sangliers", questLevel = 8 }, { questID = 783, title = "Connue" } } end
C_GossipInfo.GetActiveQuests = function() return {} end
C_GossipInfo.GetOptions = function() return {} end
C_GossipInfo.SelectAvailableQuest = function() end
C_GossipInfo.SelectActiveQuest = function() end
FireEvent("GOSSIP_SHOW")
local e = ns.db.collect.quests[20001]
check(e and e.lvl == 8 and e.giver.npc == 99001 and e.giver.x == 52.1, "donneur noté (PNJ 99001 à 52.1, 43.2)")
check(ns.db.collect.quests[783] == nil, "quête connue ignorée")
check(ns.db.collect.npcs[99001].name == "Garde de Forever", "PNJ noté")

-- prise puis objectifs
QLOG[20001] = { complete = false }
local filled = 0
C_QuestLog.GetQuestObjectives = function(q) return { { numFulfilled = filled, numRequired = 6 } } end
FireEvent("QUEST_ACCEPTED", 20001)
check(e.lvlAccepted ~= nil, "prise notée")
C.ScanObjectives()
FireEvent("PLAYER_TARGET_CHANGED")
PLAYER.x, PLAYER.y = 0.55, 0.48
filled = 1
C.ScanObjectives()
filled = 2
PLAYER.x = 0.56
C.ScanObjectives()
check(#e.obj == 2 and e.obj[1].x == 55, "positions d'objectif notées")
check(e.mobs[3098] == 2, "monstre de l'objectif noté")

-- rendu
PLAYER.x, PLAYER.y = 0.52, 0.43
QLOG[20001] = nil
FireEvent("QUEST_TURNED_IN", 20001, 650, 0)
check(e.done and e.xp == 650 and e.ender.map == 1411, "rendu et XP notés")

-- carte : quêtes disponibles affichées par le jeu
C_QuestLine = { RequestQuestLinesForMap = function() end,
  GetAvailableQuestLines = function(m) return { { questID = 20010, questName = "Nouvelle histoire", questLineName = "Durotar", x = 0.4, y = 0.6 } } end }
check(C.ScanMap(1411) == 1 and ns.db.collect.quests[20010].giver.x == 40, "quête disponible relevée sur la carte")

-- export puis relecture par l'outil de fusion
local out = C.Export()
check(out:match("^FPC1;") and out:find("Q;20001;Les sangliers;8;") and out:find("O;20001;1411,55,48"), "export FPC1")
local n, done = C.Count()
check(n == 2 and done == 1, "compteur : 2 quêtes, 1 rendue")
local f = io.open("/tmp/fp_collect_export.txt", "w"); f:write(out); f:close()
print("ALL TESTS PASSED")
