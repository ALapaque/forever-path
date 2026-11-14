-- Scénario : pierre de foyer (lier / utiliser), vols automatiques, dialogues, achats, journal plein
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
FireEvent("ADDON_LOADED", "ForeverPath")
FireEvent("PLAYER_LOGIN")
RunTimers()
local E = ns.Engine

-- routes générées : étapes « lier » et « utiliser la pierre »
local binds, hearths = 0, 0
for _, id in ipairs(ns.GuideOrder) do
  for _, st in ipairs(ns.Guides[id].steps) do
    if st.type == "bind" then binds = binds + 1 end
    if st.type == "hearth" then hearths = hearths + 1 end
  end
end
check(binds > 10 and hearths > 10, ("routes : %d étapes lier, %d étapes foyer"):format(binds, hearths))

ns.Guides["test-hearth"] = { id = "test-hearth", name = "H", steps = {
  { type = "bind", map = 1429, x = 43.7, y = 65.9, npcID = 295 },
  { type = "hearth", map = 1429, x = 43.7, y = 65.9 },
  { type = "goto", map = 1429, x = 60, y = 60, radius = 5 },
} }
PLAYER.map, PLAYER.x, PLAYER.y = 1429, 0.20, 0.20
E.Load("test-hearth")
check(select(3, E.Current()) == 1, "étape « lier »")
FireEvent("HEARTHSTONE_BOUND")
check(select(3, E.Current()) == 2, "lier validé par le jeu")
PLAYER.x, PLAYER.y = 0.437, 0.659
E.Refresh()
check(select(3, E.Current()) == 3, "foyer validé à l'arrivée à l'auberge")

-- vols : meilleur nœud vers la cible
local nodes = {
  { name = "Ici", state = 0, position = { x = 0.2, y = 0.2 }, slotIndex = 1 },
  { name = "Proche", state = 1, position = { x = 0.58, y = 0.6 }, slotIndex = 2 },
  { name = "Loin", state = 1, position = { x = 0.9, y = 0.1 }, slotIndex = 3 },
  { name = "Inconnu", state = 2, position = { x = 0.6, y = 0.6 }, slotIndex = 4 },
}
local target = ns.Nav.StepPoint({ map = 1429, x = 60, y = 60 })
local here = select(1, ns.Nav.Player())
PLAYER.x, PLAYER.y = 0.2, 0.2
local best, d, gain = ns.Modules.flights.Best(nodes, 1429, target, ns.Nav.Player())
check(best and best.name == "Proche", "vol vers le nœud le plus proche de l'étape")
check(gain > 1000, "gain de trajet important ("..math.floor(gain).." yd)")
local taken
TakeTaxiNode = function(i) taken = i end
GetTaxiMapID = function() return 1429 end
C_TaxiMap = { GetAllTaxiNodes = function() return nodes end }
FireEvent("TAXIMAP_OPENED")
RunTimers()
check(taken == 2, "vol pris tout seul")

-- dialogues : option auberge pendant une étape « lier »
ns.Guides["test-bind"] = { id = "test-bind", name = "B", steps = { { type = "bind", map = 1429, x = 43.7, y = 65.9, npcID = 295 } } }
E.Load("test-bind")
local picked
C_GossipInfo.GetAvailableQuests = function() return {} end
C_GossipInfo.GetActiveQuests = function() return {} end
C_GossipInfo.GetOptions = function() return { { name = "Je voudrais regarder vos marchandises.", gossipOptionID = 10, icon = 1 },
  { name = "Faites de cette auberge votre foyer.", gossipOptionID = 11, icon = 2 } } end
C_GossipInfo.SelectOption = function(id) picked = id end
FireEvent("GOSSIP_SHOW")
check(picked == 11, "option « auberge » choisie")
check(ns.GossipOption("taxi", { { name = "Montrez-moi où je peux voler.", gossipOptionID = 5 } }).gossipOptionID == 5, "option de vol reconnue")

-- achats : meilleur article de mon niveau, quantité complétée
PLAYER.level, PLAYER.class = 20, "MAGE"
ns.SetModuleEnabled("supplies", true)
local ITEMS = {
  { id = 4540, kind = "food", req = 1, price = 25 }, { id = 4541, kind = "food", req = 5, price = 125 },
  { id = 4542, kind = "food", req = 25, price = 500 }, { id = 1179, kind = "drink", req = 15, price = 125 },
}
GetMerchantNumItems = function() return #ITEMS end
GetMerchantItemID = function(i) return ITEMS[i].id end
GetMerchantItemInfo = function(i) return "x", nil, ITEMS[i].price, 1 end
local byId = {} for _, it in ipairs(ITEMS) do byId[it.id] = it end
C_Item.GetItemInfoInstant = function(id) return id, nil, nil, nil, nil, 0, 5 end
C_Item.GetItemSpell = function(id) return byId[id] and (byId[id].kind == "food" and "Nourriture" or "Boisson") end
C_Spell = { GetSpellName = function(s) return s == 433 and "Nourriture" or s == 430 and "Boisson" end }
C_Item.GetItemInfo = function(id) return "x", nil, nil, nil, byId[id] and byId[id].req or 0 end
C_Item.GetItemCount = function(id) return id == 4541 and 5 or 0 end
local plan = ns.Modules.supplies.Plan()
local got = {}
for _, p in ipairs(plan) do got[p.kind] = p end
check(got.food and ITEMS[got.food.index].id == 4541 and got.food.qty == 15, "nourriture : meilleur article du niveau, 15 à acheter")
check(got.drink and got.drink.qty == 20, "boisson pour un mage")
PLAYER.class = "WARRIOR"
got = {} for _, p in ipairs(ns.Modules.supplies.Plan()) do got[p.kind] = p end
check(got.drink == nil, "pas de boisson pour un guerrier")

-- journal plein : suggestions hors route, la plus basse d'abord
for k in pairs(QLOG) do QLOG[k] = nil end
for q = 1, 19 do QLOG[7000 + q] = { complete = false } end
C_QuestLog.GetMaxNumQuestsCanAccept = function() return 20 end
local oldInfo = C_QuestLog.GetInfo
C_QuestLog.GetInfo = function(i) local n = 0 for q in pairs(QLOG) do n = n + 1 if n == i then return { questID = q, isHeader = false, title = "Q"..q, level = q - 7000 } end end end
local QL = ns.Modules.questlog
local n, max = QL.Count()
check(n == 19 and max == 20, "journal : 19/20")
local s = QL.Suggestions()
check(#s == 19 and s[1].level == 1, "suggestion : la plus basse hors route")
local abandoned
C_QuestLog.SetSelectedQuest = function(q) abandoned = q end
C_QuestLog.SetAbandonQuest = function() end
C_QuestLog.AbandonQuest = function() end
QL:AbandonFirst()
check(abandoned == 7001, "abandon de la première suggestion")
C_QuestLog.GetInfo = oldInfo
print("ALL TESTS PASSED")
