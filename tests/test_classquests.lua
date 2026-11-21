-- Scénario : quêtes de classe proposées selon la classe, la race, le niveau et les prérequis
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
PLAYER.class, PLAYER.race, PLAYER.faction, PLAYER.level = "SHAMAN", "Orc", "Horde", 4
PLAYER.map, PLAYER.x, PLAYER.y = 1411, 0.42, 0.68
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local M = ns.Modules.classquests
check(M and M.enabled, "module actif par défaut")
check(#M.Entries() > 40, "quêtes de chaman chargées (" .. #M.Entries() .. ")")
check(M.RaceOK(0) and M.RaceOK(2) and not M.RaceOK(128) and M.RaceOK(8589934770) and not M.RaceOK(4294967373),
    "races : masque de la base, Éolides compris")

local function has(list, id) for _, e in ipairs(list) do if e.id == id then return e end end end
local open, ready, soon = M.Status()
check(has(open, 1516) and has(open, 792), "niveau 4 : quêtes sans prérequis proposées")
check(not has(open, 3089), "prérequis pas rendu : pas proposée")
check(not has(open, 3084), "quête d'une autre race : pas proposée")
check(not has(open, 1517), "suite de chaîne : attend la première partie")
DONE[788] = true
open = M.Status()
check(has(open, 3089), "prérequis rendu : proposée")
PLAYER.level = 3
open, ready, soon = M.Status()
check(not has(open, 1516) and has(soon, 1516), "niveau requis pas atteint : annoncée pour bientôt")
PLAYER.level = 4

-- section du guide et détour
local shown
local oldSet = ns.Guide.SetSection
ns.Guide.SetSection = function(self, key, order, text) if key == "classquests" then shown = text end return oldSet(self, key, order, text) end
M:Update()
check(shown and shown:find("Quête de classe"), "rappel dans le guide : " .. tostring(shown))
local e = M:Go()
local d = ns.Engine.Detour()
check(e and d and d.kind == "classquest" and d.map == e.map, "bouton : détour vers le PNJ de la quête")
M:Update()
check(shown == nil, "détour en cours : rappel masqué")

-- le PNJ ne la propose pas : mise de côté jusqu'au niveau suivant, et relevée pour la collecte
UnitGUID = function(u) if u == "npc" then return "Creature-0-1-2-3-" .. e.npc .. "-0000" end end
C_GossipInfo.GetAvailableQuests = function() return { { questID = 999 } } end
C_GossipInfo.GetActiveQuests = function() return {} end
FireEvent("GOSSIP_SHOW")
check(not has(M.Status(), e.id) and not ns.Engine.Detour(), "pas proposée par le PNJ : mise de côté, détour retiré")
check(ns.db.collect.no and ns.db.collect.no[e.id], "relevée pour /qw collecte export")
PLAYER.level = 5
check(has(M.Status(), e.id), "niveau suivant : proposée à nouveau")

-- quête de classe finie : le guide dit où la rendre
QLOG[1516] = { complete = true }
local q, turnin = M.Next()
check(q and q.id == 1516 and turnin, "quête de classe finie : à rendre d'abord")
M:Update()
check(shown and shown:find("rendre"), "rappel « à rendre » dans le guide")
check(M.List():find("L'appel de la terre") or M.List():find("Call of Earth"), "/qw classe : liste")

-- autre classe : ses propres quêtes
PLAYER.class = "WARRIOR"
check(not has(M.Status(), 1516), "guerrier : pas de quête de chaman")
ns.Guide.SetSection = oldSet
print("ALL TESTS PASSED")
