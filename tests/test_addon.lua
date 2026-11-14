local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end

check(#ns.ModuleOrder >= 16, "modules enregistrés: "..#ns.ModuleOrder)
check(#ns.GuideOrder > 150, "segments de route: "..#ns.GuideOrder)

-- parse de toutes les routes, vérif des cartes
local nsteps, bad = 0, 0
for _, id in ipairs(ns.GuideOrder) do
  local g = ns.Guides[id]
  for _, s in ipairs(g.steps) do
    nsteps = nsteps + 1
    if s.x and not ns.MapFor(s.map) then bad = bad + 1 end
  end
  if g.next and not ns.Guides[g.next] then error("next manquant "..g.next) end
end
print("étapes totales", nsteps, "sans carte", bad)
check(bad == 0, "toutes les étapes ont une carte connue")

FireEvent("ADDON_LOADED", "ForeverPath")
FireEvent("PLAYER_LOGIN")
check(ns.cdb.guideId == "alliance-human-01-elwynn", "humain niveau 1 -> Elwynn ("..tostring(ns.cdb.guideId)..")")
local g, step = ns.Engine.Current()
check(step.type == "goto" or step.type == "accept", "première étape")
-- le G initial est à 48.2,42.9 et le joueur aussi -> validé
RunTimers(); ns.Engine.Refresh()
g, step = ns.Engine.Current()
check(step.type == "accept" and step.quest == 783, "accept 783 (Une menace intérieure)")
check(ns.NpcName(step.npcID) == "Adjoint Willem" or print(ns.NpcName(step.npcID)), "nom FR du PNJ")
local t = ns.Engine.Targets()
check(t.ids[823] == "npc", "cible PNJ 823")

-- modules activés par défaut
for _, id in ipairs({"guide","arrow","nameplates","automation","zones","waypoint"}) do
  check(ns.IsEnabled(id), "module actif "..id)
end
check(not ns.IsEnabled("danger") and not ns.IsEnabled("npcmodel"), "modules optionnels désactivés")
ns.SetModuleEnabled("danger", true); check(ns.IsEnabled("danger"), "activation à chaud")
ns.SetModuleEnabled("arrow", false); check(not ns.IsEnabled("arrow"), "désactivation à chaud")
ns.Modules.guide:SetOpt("upcoming", 3); check(ns.Modules.guide:Opt("upcoming") == 3, "option module")

-- options : construction des cartes + aperçus
ns.Options:Open()
check(ns.Options.built, "panneau d'options construit")

-- quête acceptée -> turnin
QLOG[783] = {complete = true}
FireEvent("QUEST_ACCEPTED", 783); RunTimers()
g, step = ns.Engine.Current()
check(step.type == "turnin" and step.quest == 783, "avance au rendu")
QLOG[783] = nil; DONE[783] = true
FireEvent("QUEST_TURNED_IN", 783); RunTimers()
g, step = ns.Engine.Current()
check(step.quest == 7 and step.type == "accept", "suivant : accept 7")

-- turnin d'une quête jamais prise : sauté
ns.Engine.Next()  -- saute accept 7
RunTimers(); ns.Engine.Refresh()
g, step = ns.Engine.Current()
print("après skip:", step.type, step.quest)

-- montée de niveau : changement de segment
PLAYER.level = 20
ns.Engine.CheckLevel()
print("segment à 20 :", ns.cdb.guideId)
check(ns.cdb.guideId:find("alliance%-human"), "reste sur le parcours humain")

-- Horde
PLAYER.faction, PLAYER.race, PLAYER.level = "Horde", "Orc", 1
ns.cdb.guideId = nil
local id = ns.Engine.PickDefault()
check(id == "horde-orc-01-durotar", "orc niveau 1 -> Durotar ("..tostring(id)..")")
PLAYER.race = "Skyborne"; local id2 = ns.Engine.PickDefault()
print("éolide horde niveau 1 hors île ->", id2)
PLAYER.race, PLAYER.level = "Scourge", 35; print("mort-vivant 35 ->", ns.Engine.PickDefault())
PLAYER.faction, PLAYER.race, PLAYER.level = "Alliance", "NightElf", 48; print("elfe 48 ->", ns.Engine.PickDefault())

-- slash
SlashCmdList.FOREVERPATH("where"); SlashCmdList.FOREVERPATH("config"); SlashCmdList.FOREVERPATH("zones")
TICK()
local miss = {} for k in pairs(MISSING) do miss[#miss+1]=k end table.sort(miss)
print("GLOBALS STUBBÉS:", table.concat(miss, " "))
print("ALL TESTS PASSED")
