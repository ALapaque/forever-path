-- Scénario : quêtes liées — quêtes du journal (même hors route) sur les mêmes monstres que l'étape,
-- quêtes à rendre au même PNJ, et quêtes de métier marquées / passées faute de métier
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local E = ns.Engine

-- données de test (remplacent celles de Data/QuestLinks.lua)
ns.QuestLinks[701] = "m=500,501;e=88"
ns.QuestLinks[702] = "m=501,502;e=88"          -- hors route, mêmes monstres (501)
ns.QuestLinks[703] = "m=900;e=88"              -- hors route, autres monstres, à rendre au PNJ 88
ns.QuestLinks[704] = "m=600;e=90;s=185:50"     -- quête de métier : Cuisine 50
ns.QuestLinks[705] = "m=600"                   -- hors route, mêmes monstres qu'une étape plus loin

ns.RegisterGuide({ id = "test-links", name = "Liens", faction = "Alliance", minLevel = 1, maxLevel = 5, text = [[
M elwynn
A 701 @40.0,60.0 id=88 lvl=3
C 701 @45.0,62.0 mobs=500
T 701 @40.0,60.0 id=88
A 704 @41.0,61.0 id=90 lvl=3
C 704 @46.0,63.0 mobs=600
T 704 @41.0,61.0 id=90
A 706 @42.0,61.0 id=91 skill=FISHING:25
N "Fin"
]] })
local g = ns.Guides["test-links"]
check(g.steps[7].skill == 356 and g.steps[7].skillRank == 25, "skill=FISHING:25 lu par l'analyseur")

local L = ns.QuestLink(704)
check(L and L.skill == 185 and L.rank == 50 and L.mobs[600] and L.enders[90], "données de liens lues")

-- 1) pas de métier : la quête de cuisine est passée (prise, objectif, rendu)
GetProfessions = function() return nil end
GetProfessionInfo = function() end
FireEvent("SKILL_LINES_CHANGED")
QLOG[701] = { complete = false }
E.Load("test-links")
check(select(3, E.Current()) == 2, "étape « faire 701 »")
QLOG[701] = nil; DONE[701] = true
E.Refresh()
check(select(3, E.Current()) == 8, "sans Cuisine 50 ni Pêche 25 : quêtes de métier passées (étape " .. tostring(select(3, E.Current())) .. ")")
local label = ns.Guide.StepLabel(g.steps[4])
check(label:find("Cuisine 50", 1, true) and label:find("ffff7f3f", 1, true), "étape marquée « Cuisine 50 » en orange : " .. label)

-- 2) Cuisine 60 : la quête revient dans la route
GetProfessions = function() return nil, nil, nil, nil, 5 end
GetProfessionInfo = function(i) if i == 5 then return "Cuisine", nil, 60, 75, nil, nil, 185 end end
FireEvent("SKILL_LINES_CHANGED")
E.Load("test-links")
check(select(3, E.Current()) == 4, "avec Cuisine 60 : la quête de métier est dans la route")
check(ns.Guide.StepLabel(g.steps[4]):find("ffaaaaaa", 1, true), "marque en gris quand le métier suffit")
-- option décochée : jamais passée
GetProfessions = function() return nil end
FireEvent("SKILL_LINES_CHANGED")
ns.Modules.profquests:SetOpt("skip", false)
E.Load("test-links")
check(select(3, E.Current()) == 4, "option « passer » décochée : la quête reste")
ns.Modules.profquests:SetOpt("skip", true)
-- déjà prise : on la suit même sans le métier
QLOG[704] = { complete = false }
E.Load("test-links")
check(select(3, E.Current()) == 5, "quête de métier déjà prise : on la suit")
QLOG[704] = nil

GetProfessions = function() return nil, nil, nil, nil, 5 end
FireEvent("SKILL_LINES_CHANGED")
-- 3) mêmes monstres : quête hors route du journal regroupée avec l'étape
DONE[701] = nil
QLOG[701] = { complete = false }
QLOG[702] = { complete = false }
QLOG[703] = { complete = true }
QLOG[705] = { complete = false }
E.Load("test-links")
local _, step = E.Current()
check(step.type == "complete" and step.quest == 701, "étape « faire 701 »")
local M = ns.Modules.questlinks
local r = M.Related(step)
check(#r.mobs == 1 and r.mobs[1].quest == 702 and r.mobs[1].offRoute, "702 (hors route) a les mêmes monstres que l'étape")
M:Update()
local t = E.Targets()
check(t.ids[500] == "mob" and t.ids[502] == "mob", "les monstres de 702 deviennent aussi des cibles")
-- l'étape de rendu au PNJ 88 : 703 terminée est à rendre là aussi
QLOG[701] = { complete = true }
E.Refresh()
_, step = E.Current()
r = M.Related(step)
check(step.type == "turnin" and #r.turnin == 1 and r.turnin[1].quest == 703, "703 terminée : à rendre au même PNJ")
-- panneau des quêtes : 705 (hors route) a les mêmes monstres qu'une étape plus loin
local s, ahead = M.RouteStepFor(705)
check(s and s.quest == 704 and ahead and ahead > 0, "705 : mêmes monstres que l'étape « faire 704 » (dans " .. tostring(ahead) .. " étapes)")
local text = ns.Modules.questpanel and ns.Modules.questpanel.RenderMe and ns.Modules.questpanel.RenderMe() or ""
check(text:find("mêmes monstres qu'une étape de ta route", 1, true), "panneau : quête hors route reliée à la route")
-- module désactivé : plus rien
ns.SetModuleEnabled("questlinks", false)
RunTimers()
check(not M.ExtraMobs(), "module désactivé : pas de cibles en plus")
print("questlinks OK")

-- 4) changer de zone à la main (panneau Zones / /qw zone)
ns.SetModuleEnabled("questlinks", true)
QLOG = {}; DONE = {}
PLAYER.level = 22
E.Load(E.PickDefault())
local start = ns.cdb.guideId
local R = ns.Recommend
local segs = R.Segments()
check(#segs >= 2, "plusieurs zones proposées au niveau 22 (" .. #segs .. ")")
local curKey = R.SegmentZone(ns.Guides[start])
local other
for _, sg in ipairs(segs) do if sg.key ~= curKey then other = sg break end end
check(other, "une autre zone que " .. tostring(curKey))
R.Choose(other.guide)
check(ns.cdb.guideId == other.guide and ns.cdb.pinned == other.guide, "zone choisie chargée : " .. other.guide)
PLAYER.level = 40
E.CheckLevel()
check(ns.cdb.guideId == other.guide, "zone choisie gardée malgré le niveau")
ns.ZonePanel:Refresh()
PLAYER.level = 22
SlashCmdList.QUESTWEAVER("zone " .. curKey)
check(R.SegmentZone(ns.Guides[ns.cdb.guideId]) == curKey, "/qw zone " .. curKey .. " : retour dans cette zone")
E.Load(other.guide, true)
check(not ns.cdb.pinned, "chargement automatique : plus de zone épinglée")
print("zones OK")
