-- Scénario : garde-fous des routes en jeu — quêtes de groupe optionnelles, quête pas proposée par
-- le PNJ, signalement d'une étape, ordre de déblocage noté par le collecteur
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
time = function() return 300000 end
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local E = ns.Engine

ns.RegisterGuide({ id = "test-care", name = "Soin", faction = "Alliance", minLevel = 1, maxLevel = 5, text = [[
M elwynn
A 601 @40.0,60.0 id=88 group=1 lvl=5
C 601 @45.0,62.0 group=1
T 601 @40.0,60.0 id=88 group=1
A 602 @40.0,60.0 id=88 lvl=3
C 602 @45.0,62.0
T 602 @40.0,60.0 id=88
A 603 @41.0,61.0 id=89 lvl=3
]] })
E.Load("test-care")
local g = ns.Guides["test-care"]
check(g.steps[1].group and g.steps[2].group, "group=1 lu par l'analyseur")

-- 1) quêtes de groupe : hors route par défaut
check(select(3, E.Current()) == 4, "quête de groupe passée par défaut (étape " .. tostring(select(3, E.Current())) .. ")")
ns.Modules.grouphint:SetOpt("include", true)
E.Load("test-care")
check(select(3, E.Current()) == 1, "option cochée : la quête de groupe est dans la route")
ns.Modules.grouphint:SetOpt("include", false)
QLOG[601] = { complete = false }
E.Load("test-care")
check(select(3, E.Current()) == 2, "quête de groupe déjà prise : on la suit quand même")
QLOG[601] = nil
E.Load("test-care")
check(select(3, E.Current()) == 4, "retour à la route sans la quête de groupe")

-- 2) le PNJ de l'étape ne propose pas la quête : prise passée, signalement automatique
UnitGUID = function(u) if u == "npc" then return "Creature-0-1-2-3-88-0000" end end
C_GossipInfo.GetAvailableQuests = function() return { { questID = 602, title = "Voulue" } } end
C_GossipInfo.GetActiveQuests = function() return {} end
C_GossipInfo.GetOptions = function() return {} end
C_GossipInfo.SelectAvailableQuest = function() end
C_GossipInfo.SelectActiveQuest = function() end
ns.SetModuleEnabled("automation", false)
FireEvent("GOSSIP_SHOW")
check(select(3, E.Current()) == 4 and not (ns.cdb.notOffered or {})[602], "quête proposée : l'étape reste")
C_GossipInfo.GetAvailableQuests = function() return { { questID = 999, title = "Autre" } } end
FireEvent("GOSSIP_SHOW")
check(ns.cdb.notOffered[602] ~= nil, "quête pas proposée : notée")
check(select(3, E.Current()) == 7, "prise passée, et « faire » / « rendre » avec (étape " .. tostring(select(3, E.Current())) .. ")")
-- un autre PNJ que celui de l'étape : on ne conclut rien
FireEvent("GOSSIP_SHOW")
check(not ns.cdb.notOffered[603], "PNJ différent de celui de l'étape : rien n'est passé")

-- 3) signalements
local R = ns.StepReport
check(#ns.db.stepReports == 1 and ns.db.stepReports[1].reason == "notoffered", "signalement automatique enregistré")
local gg, step, i = E.Current()
R.Add("high", gg, step, i)
R.Add("high", gg, step, i)
check(#ns.db.stepReports == 2, "pas de doublon pour la même étape et la même raison")
local txt = R.Export()
check(txt:match("^QWS1;") and txt:find("S;test%-care;4;accept;602;3;%d+;notoffered") and txt:find("S;test%-care;7;accept;603;3;%d+;high"), "export des signalements\n" .. txt)
R.OpenMenu()
check(QuestweaverStepReportMenu ~= nil, "menu des raisons")
ns.SlashExt.signalements("reset")
check(ns.db.stepReports == nil, "signalements effacés")

-- 4) collecteur : une quête qui apparaît chez le PNJ juste après un rendu est notée comme sa suite
local C = ns.Modules.collector
C_GossipInfo.GetAvailableQuests = function() return { { questID = 602 } } end
FireEvent("GOSSIP_SHOW")
FireEvent("QUEST_TURNED_IN", 602, 100)
C_GossipInfo.GetAvailableQuests = function() return { { questID = 95001, title = "La suite", questLevel = 4 } } end
FireEvent("GOSSIP_SHOW")
check(ns.db.collect.pre and ns.db.collect.pre[95001] == 602, "déblocage noté : 95001 après 602")
check(C.Export():find("P;95001;602"), "déblocage exporté")

-- 5) PNJ sans dialogue : fenêtre « quêtes », détail direct d'une autre quête, ou rien du tout
ns.RegisterGuide({ id = "test-offer", name = "Offre", faction = "Alliance", minLevel = 1, maxLevel = 5, text = [[
M elwynn
A 611 @40.0,60.0 id=88 lvl=3
A 612 @40.0,60.0 id=88 lvl=3
A 613 @40.0,60.0 id=88 lvl=3
N "Fin"
]] })
QLOG = {}; ns.cdb.notOffered = {}
E.Load("test-offer")
local oldTime = GetTime
local now = 5000
GetTime = function() return now end
GetNumAvailableQuests = function() return 1 end
GetAvailableQuestInfo = function() return false, 0, false, false, 611 end
GetNumActiveQuests = function() return 0 end
FireEvent("QUEST_GREETING")
check(select(3, E.Current()) == 1, "fenêtre « quêtes » avec la nôtre : l'étape reste")
GetAvailableQuestInfo = function() return false, 0, false, false, 999 end
FireEvent("QUEST_GREETING")
check(ns.cdb.notOffered[611] and select(3, E.Current()) == 2, "fenêtre « quêtes » sans la nôtre : prise passée")
-- détail d'une autre quête juste après une liste : choix du joueur, on ne conclut rien
GetQuestID = function() return 999 end
FireEvent("QUEST_DETAIL")
check(select(3, E.Current()) == 2, "détail choisi dans une liste : l'étape reste")
now = now + 120
FireEvent("QUEST_DETAIL")
check(ns.cdb.notOffered[612] and select(3, E.Current()) == 3, "détail direct d'une autre quête : prise passée")
-- rien ne s'ouvre : « Quête pas disponible » dans le menu de signalement passe l'étape
local g3, st3, i3 = E.Current()
ns.StepReport.Add("unavailable", g3, st3, i3, true)
check(ns.cdb.notOffered[613] and select(3, E.Current()) == 4, "signalée « pas disponible » : prise passée")
GetTime = oldTime

-- 6) suite d'une chaîne juste après un rendu (« Les Veilleurs ») : pas de fausse alerte, et retour
ns.RegisterGuide({ id = "test-chain2", name = "Veilleurs", faction = "Alliance", minLevel = 1, maxLevel = 5, text = [[
M elwynn
A 621 @40.0,60.0 id=88 lvl=3
T 621 @40.0,60.0 id=88
A 622 @40.0,60.0 id=88 lvl=3
C 622 @45.0,62.0
T 622 @40.0,60.0 id=88
N "Fin"
]] })
local oldT = GetTime
local t0 = 9000
GetTime = function() return t0 end
QLOG = {}; DONE = { [621] = true }; ns.cdb.notOffered = {}
E.Load("test-chain2")
check(select(3, E.Current()) == 3, "après le rendu de la partie 1 : prendre la partie 2")
FireEvent("QUEST_TURNED_IN", 621, 100)
C_GossipInfo.GetAvailableQuests = function() return {} end          -- le PNJ ne la liste pas encore
FireEvent("GOSSIP_SHOW")
check(not ns.cdb.notOffered[622] and select(3, E.Current()) == 3, "fenêtre rouverte juste après le rendu : pas de conclusion hâtive")
t0 = t0 + 10
FireEvent("GOSSIP_SHOW")
check(ns.cdb.notOffered[622] and select(3, E.Current()) == 6, "toujours pas proposée 10 s après : passée")
-- plus tard, le PNJ la propose : retour à sa prise
C_GossipInfo.GetAvailableQuests = function() return { { questID = 622 } } end
FireEvent("GOSSIP_SHOW")
check(not ns.cdb.notOffered[622] and select(3, E.Current()) == 3, "proposée plus tard : retour à la prise de la partie 2")
GetTime = oldT

-- 7) quête au-dessus du niveau du joueur (point d'exclamation gris, « Rapport à Rog'mar » à 35
-- alors qu'il faut 36) : prise mise de côté, puis reprise dès que le niveau est atteint
ns.RegisterGuide({ id = "test-req", name = "Niveau requis", faction = "Alliance", minLevel = 1, maxLevel = 40, text = [[
M elwynn
A 631 @40.0,60.0 id=88 lvl=36
A 632 @40.0,60.0 id=88 lvl=38 req=36
G "Va plus loin" @60.0,60.0 r=10
A 633 @50.0,60.0 id=89 lvl=36 req=34
C 633 @52.0,62.0
C 632 @55.0,62.0
T 633 @50.0,60.0 id=89
T 632 @40.0,60.0 id=88
A 634 @40.0,60.0 id=88 lvl=40 req=39
N "Fin"
]] })
check(ns.Guides["test-req"].steps[2].req == 36, "req= lu par l'analyseur")
GetMoney = function() return 0 end   -- module Monture (actif à partir du niveau 30)
local toasts = {}
local oldToast = ns.Toast
ns.Toast = function(msg) toasts[#toasts + 1] = msg end
PLAYER.level = 35
QLOG = { [631] = { complete = false } }; DONE = {}; ns.cdb.notOffered = {}; ns.cdb.levelWait = {}
E.Load("test-req")
check(select(3, E.Current()) == 3, "niveau 35, quête de niveau 36 requis : prise mise de côté (étape " .. tostring(select(3, E.Current())) .. ")")
check(ns.cdb.levelWait[632] == 36, "mise de côté notée avec son niveau requis")
check(toasts[1] and toasts[1]:find("36"), "le joueur est prévenu (niveau requis affiché)")
-- il avance : aller plus loin (validé), prend la quête suivante
ns.cdb.skipped["test-req"][3] = true
QLOG[633] = { complete = false }
E.Refresh()
check(select(3, E.Current()) == 5, "il avance dans la route sans la quête mise de côté")
-- niveau 36 : retour à la prise, et l'étape « aller à » déjà faite n'est pas redemandée
PLAYER.level = 36
FireEvent("PLAYER_LEVEL_UP", 36)
RunTimers()
check(select(3, E.Current()) == 2 and not ns.cdb.levelWait[632], "niveau atteint : retour à la prise mise de côté")
local told = false
for _, m in ipairs(toasts) do if m:find("Niveau atteint") then told = true end end
check(told, "le joueur est prévenu du retour")
QLOG[632] = { complete = false }
E.Refresh()
check(select(3, E.Current()) == 5, "quête prise : la route reprend là où il en était (étape " .. tostring(select(3, E.Current())) .. ")")
-- déjà prise ou faite : jamais mise de côté, même sous le niveau
PLAYER.level = 30
E.Refresh()
check(not ns.cdb.levelWait[632], "quête déjà dans le journal : pas concernée par le niveau requis")
-- rendu déjà derrière : pas de retour en arrière pour rien
PLAYER.level = 38
QLOG = {}; DONE = { [631] = true, [632] = true, [633] = true }
ns.cdb.stepIndex = 9; E.Refresh()
check(select(3, E.Current()) == 10 and ns.cdb.levelWait[634] == 39, "fin de segment : quête de niveau 39 requis mise de côté")
-- le PNJ la propose quand même (niveau requis surestimé) : on y revient
UnitGUID = function(u) if u == "npc" then return "Creature-0-1-2-3-88-0000" end end
C_GossipInfo.GetAvailableQuests = function() return { { questID = 634 } } end
FireEvent("GOSSIP_SHOW")
check(select(3, E.Current()) == 10, "toujours sous le niveau requis indiqué : pas de retour (la route dit 39)")
ns.Toast = oldToast
PLAYER.level = 1
print("ALL TESTS PASSED")
