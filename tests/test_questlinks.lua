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
PLAYER.level = 26
ns.cdb.notOffered = {}
E.Load(E.PickDefault())
local start = ns.cdb.guideId
local R = ns.Recommend
local segs = R.Segments()
check(#segs >= 2, "plusieurs zones proposées au niveau 26 (" .. #segs .. ")")
local zsegs = R.ZoneSegments("duskwood")
check(#zsegs >= 2, "Bois de la Pénombre : " .. #zsegs .. " passages de la route à ce niveau")
local zg = R.Choose("duskwood")
check(zg and ns.cdb.guideId == zg.id and ns.cdb.pinned == zg.id, "zone choisie : guide « zone » chargé (" .. tostring(zg and zg.name) .. ")")
local total = 0
for _, sg in ipairs(zsegs) do total = total + #sg.steps end
check(#zg.steps == total, "il enchaîne tous les passages de la zone (" .. total .. " étapes)")
-- le premier passage terminé : on reste dans la zone (avant : on partait vers la suite de la route, ex. Orneval)
local firstLen = #zsegs[1].steps
ns.cdb.stepIndex = firstLen
for k = 1, firstLen do ns.cdb.skipped[zg.id][k] = true end
E.Refresh()
check(ns.cdb.guideId == zg.id and select(3, E.Current()) > firstLen, "premier passage fini : toujours dans Bois de la Pénombre (étape " .. select(3, E.Current()) .. ")")
-- niveau qui monte : la zone choisie reste
PLAYER.level = 40
E.CheckLevel()
check(ns.cdb.guideId == zg.id, "zone choisie gardée malgré le niveau")
PLAYER.level = 26
-- /reload : le guide « zone » est reconstruit à l'identique
local savedId, savedIdx = zg.id, select(3, E.Current())
ns.Guides[savedId] = nil
FireEvent("PLAYER_LOGIN")
ns.Fire("FP_READY")
check(ns.Guides[savedId] and ns.cdb.guideId == savedId and select(3, E.Current()) == savedIdx, "après /reload : même zone, même étape")
-- tout fait dans la zone : retour à la route conseillée
for k = 1, #ns.Guides[savedId].steps do ns.cdb.skipped[savedId][k] = true end
E.Refresh()
check(ns.cdb.guideId ~= savedId and not ns.cdb.pinned and not ns.cdb.zoneChoice, "zone finie : retour à la route conseillée (" .. tostring(ns.cdb.guideId) .. ")")
ns.ZonePanel:Refresh()
SlashCmdList.QUESTWEAVER("zone duskwood")
check(ns.Guides[ns.cdb.guideId].zoneKey == "duskwood", "/qw zone duskwood")
E.Load(start, true)
check(not ns.cdb.pinned and not ns.cdb.zoneChoice, "chargement d'un segment : plus de zone choisie")
print("zones OK")

-- 5) quête en plusieurs parties (La légende de Stalvan) : la route ne fait que la partie 1
QLOG = {}; DONE = {}
PLAYER.level = 26
ns.QuestLinks[801] = "e=267;c=1/3;n=802"
ns.QuestLinks[802] = "c=2/3;n=803"
ns.QuestLinks[803] = "c=3/3"
ns.QuestLinks[811] = "c=1/2;n=812"
ns.QuestLinks[812] = "c=2/2"
ns.RegisterGuide({ id = "test-chain", name = "Chaîne", faction = "Alliance", minLevel = 1, maxLevel = 60, text = [[
M elwynn
A 801 @40.0,60.0 id=265 lvl=28
T 801 @41.0,61.0 id=267
A 811 @41.0,61.0 id=267
T 811 @41.0,61.0 id=267
A 812 @41.0,61.0 id=267
T 812 @41.0,61.0 id=267
]] })
E.Load("test-chain")
local gc = ns.Guides["test-chain"]
check(ns.Guide.StepLabel(gc.steps[1]):find("(1/3)", 1, true), "partie de la chaîne dans le libellé : " .. ns.Guide.StepLabel(gc.steps[1]))
local QL = ns.Modules.questlinks
check((QL.ChainLine(gc.steps[1]) or ""):find("parties 1 à 1", 1, true), "à la prise : la route ne fait que la partie 1 sur 3")
check((QL.ChainLine(gc.steps[2]) or ""):find("2/3", 1, true), "au rendu : la partie 2/3 n'est pas dans la route")
check((QL.ChainLine(gc.steps[3]) or ""):find("toutes", 1, true), "chaîne complète dans la route : dit")
check(QL.ChainLine(gc.steps[4]) == nil, "rendu d'une partie suivie de la suivante : rien à dire")
DONE[802] = true
check(QL.ChainLine(gc.steps[2]) == nil, "suite déjà faite : rien à dire")
print("chaînes OK")

-- 6) objet lâché qui lance une quête (Goldtooth -> « Le collectionneur ») : bouton, puis où la rendre
QLOG = {}; DONE = {}
PLAYER.level = 10; PLAYER.map = 1429; PLAYER.x = 0.45; PLAYER.y = 0.60
local QLM = ns.Modules.questlinks
local BAG = { [0] = { [1] = 1307 } }
C_Container = { GetContainerNumSlots = function(b) return b == 0 and 4 or 0 end,
    GetContainerItemID = function(b, s) return BAG[b] and BAG[b][s] end }
local st = QLM.Starters()
check(#st == 1 and st[1].quest == 123 and st[1].xp > 0, "objet 1307 dans le sac : lance la quête 123 (+" .. tostring(st[1] and st[1].xp) .. " XP)")
QLM:Update()
local sbtn = _G.QuestweaverStarterButton
check(sbtn.itemID == 1307, "bouton « lancer la quête » prêt")
-- quête prise et terminée (simple livraison) : où la rendre
BAG[0][1] = nil
QLOG[123] = { complete = true }
local ti = QLM.TurnIns()
check(#ti == 1 and ti[1].quest == 123 and ti[1].dist, "quête lancée par l'objet : lieu de rendu connu (" .. tostring(ti[1] and ti[1].dist) .. " yards)")
QLM:Update()
check(QLM.detourTarget and QLM.detourTarget.quest == 123, "assez près : détour proposé")
QLM.Detour(QLM.detourTarget)
check(E.Detour() and E.Detour().kind == "questlinks", "détour vers le PNJ qui reçoit la quête")
E.SetDetour(nil)
QLM:SetOpt("detour", 0)
QLM:Update()
check(QLM.detourTarget == nil, "détour max à 0 : plus proposé")
QLM:SetOpt("detour", 600)
QLOG = {}
print("objets de quête OK")

-- 7) routes : quêtes lancées par l'objet d'un monstre nommé (étape « prendre » sur le monstre)
local found
for _, id in ipairs(ns.GuideOrder) do
    for _, s in ipairs(ns.Guides[id].steps) do
        if s.type == "accept" and s.text and s.text:find("son butin", 1, true) then found = s break end
    end
    if found then break end
end
check(found and found.mobs and next(found.mobs) and not found.npcID and found.quest, "étape « tue ce monstre : son butin lance la quête » dans les routes (quête " .. tostring(found and found.quest) .. ")")
print("butin OK")
