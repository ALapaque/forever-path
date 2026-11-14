-- Scénario : confort de jeu (détours, maître de classe, session, marchand, récolte, récompenses)
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
NOW = 100000
time = function() return NOW end

FireEvent("ADDON_LOADED", "ForeverPath")
FireEvent("PLAYER_LOGIN")
RunTimers()
local E, Places = ns.Engine, ns.Nav.Places

-- données du monde
check(#Places.Trainers() > 100, "maîtres de classe chargés ("..#Places.Trainers()..")")
check(#Places.Inns() > 20, "aubergistes chargés ("..#Places.Inns()..")")

-- maître le plus proche (guerrier, Alliance, Elwynn)
PLAYER.map, PLAYER.x, PLAYER.y, PLAYER.class = 1429, 0.40, 0.64, "WARRIOR"
local t = Places.NearestTrainer()
check(t and t.class == "WARRIOR" and t.map == 1429, "maître guerrier trouvé en Elwynn ("..(t and t.name or "?")..")")
check(t.name == "Lyria Du Lac", "le plus proche de la position (Comté-de-l'Or)")
PLAYER.x, PLAYER.y = 0.50, 0.42
check(Places.NearestTrainer().name == "Llane Beshere", "le plus proche change avec la position")
PLAYER.class = "MAGE"
check(Places.NearestTrainer().class == "MAGE", "classe respectée")
PLAYER.class = "WARRIOR"
local inn = Places.NearestInn()
check(inn and (inn.faction == "Alliance" or inn.faction == "both"), "auberge de la bonne faction ("..(inn and inn.name or "?")..")")

-- détour : passe avant le guide, se termine à l'arrivée
local before = E.NavStep()
local arrived
ns.On("FP_DETOUR_ARRIVED", function(d) arrived = d end)
ns.Modules.trainer:Go()
local d = E.NavStep()
check(d and d.detour and d.map == 1429, "le détour devient la destination")
check(d ~= before, "l'étape du guide est mise de côté")
PLAYER.x, PLAYER.y = d.x / 100, d.y / 100
TICK()
check(arrived and E.Detour() == nil, "détour terminé à l'arrivée")
check(E.NavStep() == before, "retour à l'étape du guide")

-- maître : rappel selon les niveaux manqués
ns.cdb.trainedAt = 10
PLAYER.level = 11
ns.Modules.trainer:Update()
PLAYER.level = 12
FireEvent("TRAINER_SHOW")
check(ns.cdb.trainedAt == 12, "ouvrir le maître remet le compteur à zéro")

-- session : plan et point d'arrêt sur un rendu
PLAYER.level = 1
ns.Guides["test-session"] = { id = "test-session", name = "S", steps = {} }
local steps = {}
for k = 1, 12 do
  steps[#steps + 1] = { type = ({ "accept", "complete", "turnin" })[(k - 1) % 3 + 1], quest = 9000 + math.floor((k - 1) / 3),
    map = 1429, x = 40 + k, y = 60, mobs = { [1] = true } }
end
ns.Guides["test-session"].steps = steps
E.Load("test-session")
local S = ns.Modules.session
local idx, cum = S.Plan(6 * 60)
check(idx and steps[idx].type == "turnin", "arrêt sur un rendu (étape "..tostring(idx)..")")
check(cum <= 6 * 60, "dans le temps imparti ("..math.floor(cum).." s)")
local idx2 = S.Plan(60 * 60)
check(idx2 > idx, "plus de temps, plus loin ("..idx2..")")
S:Start(6)
check(ns.cdb.session and ns.cdb.session.stopIdx == idx, "session démarrée")
NOW = NOW + 7 * 60
S:Update()
check(ns.cdb.session.finished and E.Detour() and E.Detour().text:find("Auberge"), "fin de session : détour vers l'auberge")
E.SetDetour(nil)
SlashCmdList.FOREVERPATH("session stop")
check(ns.cdb.session == nil, "/fp session stop")

-- marchand : camelote
BAGS = { [0] = { { quality = 0, itemID = 1, stackCount = 3 }, { quality = 2, itemID = 2 }, { quality = 0, itemID = 3, hasNoValue = true } } }
C_Container.GetContainerNumSlots = function(b) return BAGS[b] and #BAGS[b] or 0 end
C_Container.GetContainerItemInfo = function(b, s) return BAGS[b] and BAGS[b][s] end
C_Item.GetItemInfo = function(id) return "x", nil, nil, nil, nil, nil, nil, nil, nil, nil, 25 end
local junk = ns.Modules.merchant.Junk()
check(#junk == 1 and junk[1].value == 75, "camelote détectée (1 pile, 75 pc)")

-- récolte : décodage et couloir le long de la route
local nodes = ns.Modules.gather.Nodes(1429)
check(#nodes > 50, "points de récolte décodés pour Elwynn ("..#nodes..")")
local okRange = true
for _, nd in ipairs(nodes) do if nd.x <= 0 or nd.x >= 1 or nd.y <= 0 or nd.y >= 1 then okRange = false end end
check(okRange, "coordonnées dans la carte")
GetProfessions = function() return 1, nil end
GetProfessionInfo = function() return "Minage", nil, 50, 75, nil, nil, 186 end
check(ns.Modules.gather.Skills().mine == 50, "métier de minage détecté")
PLAYER.x, PLAYER.y = 0.41, 0.60
local vis = ns.Modules.gather.Visible(1429)
local onlyMine = true
for _, nd in ipairs(vis) do if nd.kind ~= "mine" or nd.skill > 50 then onlyMine = false end end
check(onlyMine, "seulement les filons accessibles ("..#vis.." le long de la route)")
GetProfessionInfo = function() return "Couture", nil, 50, 75, nil, nil, 197 end
check(#ns.Modules.gather.Visible(1429) == 0, "rien sans métier de récolte")

-- récompenses : Pawn
PawnShouldItemLinkHaveUpgradeArrow = function(link) return link == "up" end
check(ns.Modules.rewards.PawnUpgrade("up") == true and ns.Modules.rewards.PawnUpgrade("no") == false, "Pawn consulté")
PawnShouldItemLinkHaveUpgradeArrow = nil
check(ns.Modules.rewards.PawnUpgrade("up") == nil, "sans Pawn : niveau d'objet")
print("ALL TESTS PASSED")
