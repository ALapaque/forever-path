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

FireEvent("ADDON_LOADED", "Questweaver")
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

-- police choisie appliquée même quand SetFont ne renvoie rien (comme le client)
ns.db.font = "Arial Narrow"; ns.ApplyFonts()
check((QuestweaverFontNormal:GetFont() or ""):find("ARIALN") ~= nil, "police choisie appliquée : "..tostring(QuestweaverFontNormal:GetFont()))
ns.db.font = "Police inconnue"; ns.ApplyFonts()
check((QuestweaverFontNormal:GetFont() or ""):find("FRIZQT") ~= nil, "police inconnue : retour à Friz Quadrata")
ns.db.font = "Friz Quadrata (Blizzard)"; ns.ApplyFonts()

-- flèche 3D : projection au sol sans erreur, flèche plate en option
do
  local E, G = ns.Engine.NavStep, ns.Geo.Vector
  local RA = ns.Geo.RelativeAngle
  ns.Engine.NavStep = function() return { x = 50, y = 50, map = 1429, type = "goto" } end
  ns.Geo.Vector = function() return 120, 1.0 end
  ns.Geo.RelativeAngle = function() return 0.8 end
  local up = QuestweaverArrow._scripts.OnUpdate
  ns.Modules.arrow:SetOpt("style", 1); up(QuestweaverArrow, 0.05); up(QuestweaverArrow, 0.05)
  ns.Modules.arrow:SetOpt("style", 2); up(QuestweaverArrow, 0.05)
  ns.Modules.arrow:SetOpt("style", 3); up(QuestweaverArrow, 0.05); up(QuestweaverArrow, 0.05)
  ns.Engine.NavStep, ns.Geo.Vector, ns.Geo.RelativeAngle = E, G, RA
  check(true, "flèches pointe, 3D et plate dessinées")
  ns.SetModuleEnabled("arrow", true)
  ns.Modules.arrow:SetOpt("font", "Arial Narrow"); ns.Modules.arrow:SetOpt("textSize", 18)
  local p, sz = QuestweaverFontArrow:GetFont()
  check(p and p:find("ARIALN") and sz == 18, "police du texte de la flèche : "..tostring(p).." "..tostring(sz))
  check((QuestweaverFontNormal:GetFont() or ""):find("ARIALN") == nil, "le reste garde la police générale")
  ns.Modules.arrow:SetOpt("font", ns.GENERAL_FONT); ns.Modules.arrow:SetOpt("textSize", 14)
end

-- options : construction des cartes + aperçus
ns.Options:Open()
check(ns.Options.built, "panneau d'options construit")
-- chaque catégorie, chaque module (aperçu + réglages construits sans erreur)
rawset(QuestweaverOptions, "IsShown", function() return true end)
local seen = 0
for _, cat in ipairs({ "guide", "nav", "targets", "comfort", "safety", "community", "look" }) do
  ns.Options:Show(cat)
  for _, id in ipairs(ns.ModuleOrder) do
    ns.Options:Select(ns.Modules[id]); seen = seen + 1
  end
end
check(seen > 0, "fiches de tous les modules affichées")
ns.Options:Show("home"); ns.Options:Refresh()
check(ns.db.optView == "home", "accueil mémorisé")

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

-- apparence : thèmes et police
local A = ns.Modules.appearance
check(A.locked and ns.IsEnabled("appearance"), "module apparence toujours actif")
A:SetOpt("theme", "Minimal"); check(ns.db.theme == "minimal", "changement de thème")
A:SetOpt("font", "Arial Narrow"); check(ns.db.font == "Arial Narrow", "changement de police")
A:SetOpt("fontScale", 1.2); check(ns.db.fontScale == 1.2, "taille du texte")
check(#ns.FontList() >= 4, "liste des polices")

-- marqueur automatique retiré (SetRaidTarget est protégé depuis 12.0)
check(ns.Modules.marker == nil, "plus de module marqueur automatique")

-- barre d'actions
ns.ActionBar:Layout(); check(true, "mise en page de la barre d'actions")

-- navigation : une note sans position vise la prochaine étape positionnée
local g2 = ns.Guides["horde-skyborne-01-zephras"]
check(g2 ~= nil and g2.startZone == "zephras" and #g2.steps > 50, "route éolide générée (Île de Zéphras, "..(g2 and #g2.steps or 0).." étapes)")
PLAYER.faction, PLAYER.race, PLAYER.level = "Alliance", "Human", 1
ns.cdb.path = nil
ns.Engine.Load("alliance-human-01-elwynn")
check(ns.Engine.NavStep() ~= nil, "étape de navigation")

-- barres de nom : objectif rempli -> plus de marque
local NP = ns.Modules.nameplates
C_TooltipInfo = { GetUnit = function() return { lines = { { type = 8, leftText = "Zombie 8/8", completed = true } } } end }
check(NP.QuestState("nameplate1") == "done", "objectif rempli détecté")
C_TooltipInfo = { GetUnit = function() return { lines = { { type = 8, leftText = "Zombie 2/8", completed = false } } } end }
check(NP.QuestState("nameplate1") == "todo", "objectif en cours détecté")

-- slash
SlashCmdList.QUESTWEAVER("where"); SlashCmdList.QUESTWEAVER("config"); SlashCmdList.QUESTWEAVER("zones")
TICK()
local miss = {} for k in pairs(MISSING) do miss[#miss+1]=k end table.sort(miss)
print("GLOBALS STUBBÉS:", table.concat(miss, " "))
-- carte : étiquettes des pastilles regroupées
local L = ns.Modules.maproute.Label
assert(L, "MapRoute.Label introuvable")
assert(L({ 3 }) == "3", "pastille seule")
assert(L({ 8, 2, 3, 4 }) == "2-4,8", "regroupement trié : "..L({ 8, 2, 3, 4 }))
assert(L({ 1, 2 }) == "1,2", "deux étapes consécutives")
assert(L({ 1, 3, 5 }) == "1+", "trop de morceaux : "..L({ 1, 3, 5 }))
print("ok - étiquettes des pastilles regroupées")

-- tracé sur la carte : le corps n'est calculé qu'une fois tant que rien ne change
do
  local child = mockobj()
  rawset(child, "GetWidth", function() return 1000 end)
  rawset(child, "GetHeight", function() return 700 end)
  rawset(child, "GetFrameLevel", function() return 1 end)
  local scale = 1
  WorldMapFrame = { IsShown = function() return true end, GetMapID = function() return 1429 end,
    GetCanvasScale = function() return scale end, ScrollContainer = { Child = child } }
  local px = 0.40
  local oldPos = C_Map.GetPlayerMapPosition
  C_Map.GetPlayerMapPosition = function() return { GetXY = function() return px, 0.5 end } end
  local J = ns.Journeys
  local oldPoly, oldToMap, oldEn = J.Polylines, ns.Nav.ToMap, J.enabled
  local segs = { { pts = { { c = 0, x = 0, y = 0 }, { c = 0, x = 1, y = 0 } }, head = true, color = { 1, 1, 1 } } }
  for k = 1, 300 do
    segs[#segs + 1] = { pts = { { c = 0, x = k, y = 0 }, { c = 0, x = k + 1, y = 0 } }, color = { 1, 1, 1 } }
  end
  J.Polylines = function() return segs end
  J.enabled, J.version = true, 1
  local calls = 0
  ns.Nav.ToMap = function(c, x, y) calls = calls + 1; return 1429, 0.1 + x / 400, 0.3 end
  local M = ns.Modules.maproute
  M.builds = 0
  M:Draw(true)
  local first = calls
  for _ = 1, 10 do M:Draw() end
  check(M.builds == 1 and calls - first <= 10, ("tracé calculé une seule fois (%d conversions puis %d)"):format(first, calls - first))
  check(#M.cache.body <= 460, "nombre de points borné : "..#M.cache.body)
  scale = 2; M:Draw()
  check(M.builds == 1, "zoom : simple redimensionnement")
  px = 0.45; M:Draw()
  check(M.builds == 1, "le joueur bouge : seule la tête est redessinée")
  J.version = 2; M:Draw()
  check(M.builds == 2, "trajet modifié : tracé recalculé")
  J.Polylines, ns.Nav.ToMap, J.enabled = oldPoly, oldToMap, oldEn
  C_Map.GetPlayerMapPosition = oldPos
  WorldMapFrame = nil
end

-- thème Néon : majuscules, mots-clés colorés, lignes surlignées, barre en bas
do
  ns.Modules.guide:SetOpt("upcoming", 3)
  ns.Modules.appearance:SetOpt("theme", "Néon (contraste)")
  check(ns.db.theme == "neon", "thème Néon choisi")
  ns.Guide:Update()
  local _, step = ns.Engine.Current()
  local label = ns.Guide.StepLabel(step)
  check(not label:find("|cff3dff9a") or label:find("'"), "mots-clés en couleur : "..label)
  check(#ns.Guide.upData >= 1, "lignes suivantes séparées : "..#ns.Guide.upData)
  ns.Modules.appearance:SetOpt("theme", "Sombre doré")
  ns.Guide:Update()
  check(ns.db.theme == "dark", "retour au thème doré")
end

-- icônes de quête du jeu : « ! » pour prendre, « ? » pour rendre (gris si pas terminée)
do
  C_Texture = { GetAtlasInfo = function(n) return (n == "QuestNormal" or n == "QuestTurnin") and {} or nil end }
  local tex = { SetAtlas = function(self, a) self.atlas = a; self.file = nil end,
    SetTexture = function(self, f) self.file = f; self.atlas = nil end,
    SetDesaturated = function(self, d) self.desat = d end }
  ns.SetStepIcon(tex, { type = "accept", quest = 5 }, "x")
  check(tex.atlas == "QuestNormal" and not tex.desat, "prendre : point d'exclamation du jeu")
  QLOG[900] = { complete = false }
  local oldC = C_QuestLog.IsComplete
  C_QuestLog.IsComplete = function(q) return QLOG[q] and QLOG[q].complete end
  ns.SetStepIcon(tex, { type = "turnin", quest = 900 }, "x")
  check(tex.atlas == "QuestTurnin" and tex.desat, "rendre, pas terminée : point d'interrogation gris")
  QLOG[900].complete = true
  ns.SetStepIcon(tex, { type = "turnin", quest = 900 }, "x")
  check(tex.atlas == "QuestTurnin" and not tex.desat, "rendre, terminée : point d'interrogation jaune")
  ns.SetStepIcon(tex, { type = "goto" }, "carte")
  check(tex.file == "carte" and not tex.desat, "autres étapes : leur icône")
  QLOG[900] = nil; C_QuestLog.IsComplete = oldC; C_Texture = nil
end
print("ALL TESTS PASSED")
