-- Scénario : objets de quête dans les sacs (infobulle + /qw sac)
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end

-- infobulle : on capture le rappel de TooltipDataProcessor
local tipCallback
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) tipCallback = fn end }
Enum = Enum or {}
Enum.TooltipDataType = { Item = 0 }
local lines = {}
GameTooltip = { AddLine = function(self, t) lines[#lines + 1] = t end }

-- sacs : Viande de loup coriace (750), Sharptalon's Claw (16305), un objet sans quête (6948)
local BAGS = { [0] = { 750, 16305, 6948 } }
C_Container = {
  GetContainerNumSlots = function(bag) return BAGS[bag] and #BAGS[bag] or 0 end,
  GetContainerItemID = function(bag, slot) return BAGS[bag] and BAGS[bag][slot] end,
  GetContainerItemLink = function(bag, slot) return "[objet " .. tostring(BAGS[bag][slot]) .. "]" end,
}

-- classe des objets : 12 = Quête, 7 = artisanat (tissu)
C_Item = C_Item or {}
C_Item.GetItemInfoInstant = function(id)
  local class = (id == 2589) and 7 or 12
  return id, "", "", "", 0, class, 0
end
BAGS[0][4] = 2589
PLAYER.faction = "Alliance"
PLAYER.level = 5
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()

local M = ns.Modules.questitems
check(M and M.enabled, "module actif par défaut")
check(tipCallback ~= nil, "infobulle branchée")
check(ns.QuestItems[750] ~= nil and ns.QuestInfo[33] ~= nil, "données générées chargées")

-- quête 33 (Les loups derrière la frontière) : pas encore prise, niveau 2 -> à garder
local a = M.Analyze(750)
check(a.verdict == M.KEEP and a.quests[1].quest == 33, "viande de loup : à garder pour la quête 33")
check(#a.quests == 2, "deux quêtes Alliance utilisent la viande de loup (33 et 179)")
PLAYER.faction = "Horde"
check(M.Analyze(750).otherFaction, "pour un Horde : objet de l'autre faction")
PLAYER.faction = "Alliance"

-- quête faite -> inutile
DONE[33] = true
a = M.Analyze(750)
check(a.verdict == M.KEEP, "33 rendue mais 179 encore à faire : toujours utile")
DONE[179] = true
a = M.Analyze(750)
check(a.verdict == M.USELESS, "les deux quêtes rendues : objet inutile")
DONE[179] = nil
DONE[33] = nil

-- niveau 20 : la quête niveau 2 est grise -> peu utile
PLAYER.level = 20
a = M.Analyze(750)
check(a.verdict == M.LOW and a.quests[1].factor <= 0.2, "quêtes grises : peu utile")
-- sauf si elle est dans le journal
QLOG[33] = { complete = false }
a = M.Analyze(750)
check(a.verdict == M.KEEP and a.quests[1].inLog and a.quests[1].quest == 33, "quête en cours : à garder même grise, en premier")
QLOG[33] = nil
PLAYER.level = 5

-- infobulle
tipCallback(GameTooltip, { id = 750 })
local all = table.concat(lines, " / ")
check(all:find("À garder") and all:find("Sert à %[2%]") and all:find("dans ta route"), "infobulle : verdict + quêtes : " .. all)
lines = {}
tipCallback(GameTooltip, { id = 6948 })
check(#lines == 0, "objet sans quête : infobulle inchangée")

-- /qw sac
local printed = {}
local oldPrint = ns.Print
ns.Print = function(fmt, ...) printed[#printed + 1] = select("#", ...) > 0 and fmt:format(...) or fmt end
ns.SlashExt.sac("")
ns.Print = oldPrint
local txt = table.concat(printed, "\n")
check(txt:find("objet 750") and txt:find("garder"), "/qw sac liste les objets de quête : " .. txt)
check(not txt:find("objet 6948"), "/qw sac ignore les objets sans quête")
check(not txt:find("objet 2589"), "/qw sac ignore le tissu (objet ordinaire demandé par des quêtes)")
lines = {}
tipCallback(GameTooltip, { id = 2589 })
local tl = table.concat(lines, " / ")
check(not tl:find("débarrasser") and not tl:find("Inutile"), "tissu : jamais « inutile » : " .. tl)
check(not tl:find("Quest1644"), "quête de paladin cachée pour un guerrier")

-- butin des rares dans l'infobulle de la carte
do
  local R = ns.Modules.rares
  ITEM_QUALITY_COLORS = { [1] = { hex = "|cffffffff" }, [2] = { hex = "|cff1eff00" }, [3] = { hex = "|cff0070dd" } }
  local loot = R.Loot(5822)
  check(#loot >= 2 and loot[1].unique, "butin du rare 5822 : objet propre en premier")
  local cache = { [3290] = { "Bottes de test", 2, 132539 } }
  C_Item.GetItemInfo = function(id) local c = cache[id]; if c then return c[1], nil, c[2], nil, nil, nil, nil, nil, nil, c[3] end end
  local requested = {}
  C_Item.RequestLoadItemDataByID = function(id) requested[#requested + 1] = id end
  local tl = {}
  local tip = { AddLine = function(_, t) tl[#tl + 1] = t end }
  local pending = R.AddLootLines(tip, 5822)
  local all = table.concat(tl, " / ")
  check(all:find("Butin possible") and all:find("Bottes de test") and all:find("propre à ce rare"), "infobulle du rare : " .. all)
  check(pending > 0 and #requested == pending and all:find("Chargement"), "objets pas en cache demandés au jeu")
  check(#R.Loot(999999) == 0, "rare sans butin connu : rien")
end
print("ALL TESTS PASSED")
