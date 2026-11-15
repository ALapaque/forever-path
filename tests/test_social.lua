-- Scénario : groupe (étapes, quêtes manquantes, partage), quêtes de groupe, chrono et rapport
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end

FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local E = ns.Engine
local G = ns.Modules.groupsync

ns.Guides["test-group"] = { id = "test-group", name = "G", steps = {
  { type = "accept", quest = 501, map = 1429, x = 40, y = 60 },
  { type = "complete", quest = 501, map = 1429, x = 45, y = 62 },
  { type = "turnin", quest = 501, map = 1429, x = 40, y = 60 },
  { type = "accept", quest = 502, map = 1429, x = 40, y = 60 },
} }
E.Load("test-group")
QLOG[501] = { complete = false }
E.Refresh()
check(select(3, E.Current()) == 2, "étape 2 (faire la quête 501)")

-- encodage / décodage
local msg = G.Encode()
check(msg and msg:match("^2:test%-group:2:4:1:"), "message de groupe v2 ("..tostring(msg)..")")
check(msg:find("501"), "quêtes de la route incluses")
local d = G.Decode("2:test-group:3:4:12:501,77")
check(d.index == 3 and d.level == 12 and d.quests[501] and d.quests[77], "décodage v2")
check(G.Decode("test-group:3:4").index == 3, "compatible avec l'ancienne version")

-- réception : un membre en avance qui n'a pas la quête
IsInGroup = function() return true end
IsInRaid = function() return false end
Ambiguate = function(n) return n end
UnitInParty = function() return true end
FireEvent("CHAT_MSG_ADDON", "QWVR1", "2:test-group:3:4:5:", "PARTY", "Jaina")
local q, missing = G.Missing()
check(q == 501 and missing[1] == "Jaina", "Jaina n'a pas la quête de l'étape")
FireEvent("CHAT_MSG_ADDON", "QWVR1", "2:test-group:2:4:5:501", "PARTY", "Jaina")
q, missing = G.Missing()
check(#missing == 0, "plus rien à partager quand elle l'a")
local pushed
C_QuestLog.SetSelectedQuest = function(id) pushed = id end
QuestLogPushQuest = function() end
FireEvent("CHAT_MSG_ADDON", "QWVR1", "2:test-group:1:4:5:", "PARTY", "Jaina")
G:Update()
G:Share()
check(pushed == 501, "partage de la quête de l'étape")

-- quête de groupe
C_QuestLog.GetSuggestedGroupSize = function(id) return id == 501 and 3 or 0 end
C_QuestLog.GetQuestTagInfo = function() return nil end
local size = ns.Modules.grouphint.Info(501)
check(size == 3, "quête de groupe détectée (3 joueurs)")
check(ns.Modules.grouphint.Info(502) == nil, "quête solo : rien")

-- chrono
local C = ns.Modules.chrono
local s = C.Stats()
s.played = 3600
FireEvent("PLAYER_LEVEL_UP", 2)
check(s.levels[2] == 3600, "temps du niveau 2 enregistré")
check(ns.db.records[ns.cdb.path or "any"][2] == 3600, "record enregistré")
s.played = 5000
FireEvent("PLAYER_LEVEL_UP", 2)
check(ns.db.records[ns.cdb.path or "any"][2] == 3600, "record conservé (plus lent)")
FireEvent("PLAYER_DEAD")
check(s.deaths == 1 and s.segDeaths["test-group"] == 1, "mort comptée par segment")
s.segs["test-group"] = 1234
E.Next()
local rep = C.Report()
check(rep:match("^FPR1;") and rep:find("S;test%-group;1234;1;1") and rep:find("K;test%-group;2;complete;501"), "rapport de parcours")
check(not rep:find("Tester"), "rapport anonyme (pas de nom)")
check(C.Table():find("Niveaux"), "tableau du chrono")
print("ALL TESTS PASSED")
