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

-- alertes de danger : GUID et nom de la cible « secrets » (Midnight) -> pas de comparaison, nom générique
do
  local SECRET = setmetatable({}, { __eq = function() error("comparaison d'une valeur secrète") end })
  local oldSecret = issecretvalue
  issecretvalue = function(v) return v == nil and false or rawequal(v, SECRET) end
  local oldGUID, oldName, oldExists, oldAttack, oldDead, oldClassif, oldLvl = UnitGUID, UnitName, UnitExists, UnitCanAttack, UnitIsDead, UnitClassification, UnitLevel
  UnitGUID = function() return SECRET end
  UnitName = function(u) if u == "target" then return SECRET end return "Tester" end
  UnitExists = function() return true end
  UnitCanAttack = function() return true end
  UnitIsDead = function() return false end
  UnitClassification = function() return "elite" end
  UnitLevel = function(u) if u == "target" then return 30 end return PLAYER.level end
  ns.SetModuleEnabled("danger", true)
  local toasts = {}
  local oldToast = ns.Toast
  ns.Toast = function(msg) toasts[#toasts + 1] = msg end
  FireEvent("PLAYER_TARGET_CHANGED")
  FireEvent("PLAYER_TARGET_CHANGED")
  ns.Toast = oldToast
  check(#toasts == 1 and toasts[1]:find("ta cible"), "danger avec GUID secret : une alerte, nom générique ("..#toasts..")")
  UnitGUID, UnitName, UnitExists, UnitCanAttack, UnitIsDead, UnitClassification, UnitLevel = oldGUID, oldName, oldExists, oldAttack, oldDead, oldClassif, oldLvl
  issecretvalue = oldSecret
end

-- v1.12 : thèmes Modern / Classic / Classic Forever, objectifs en barres, zone cliquable, rappels groupés
do
  local A, G = ns.Modules.appearance, ns.Guide
  local f = G.frame
  -- le banc de test ne retient pas l'état des cadres : on l'observe ici
  local function spy(o)
    rawset(o, "Show", function(self) rawset(self, "_shown", true) end)
    rawset(o, "Hide", function(self) rawset(self, "_shown", false) end)
    rawset(o, "SetText", function(self, t) rawset(self, "_text", t) end)
    return o
  end
  spy(f.hSide); spy(f.hNext); spy(f.header)
  -- trois nouveaux thèmes en tête de liste, les anciens toujours là
  local names = {}
  for _, t in ipairs(ns.Themes) do names[t.key] = t.name end
  check(names.modern == "Modern" and names.classic == "Classic" and names.forever == "Classic Forever", "thèmes Modern, Classic et Classic Forever")
  check(names.dark and names.neon and names.minimal, "anciens thèmes toujours disponibles")

  -- Modern : préréglage Néon = les couleurs du thème Néon
  A:SetOpt("theme", "Modern")
  check(ns.db.theme == "modern", "thème Modern choisi")
  local t, neon = ns.Theme(), ns.ThemeByKey.neon
  check(not t.rows and not t.gradient and not t.caps, "Modern par défaut : sobre")
  A:SetOpt("modernPreset", "Néon")
  check(A:Opt("modernPreset") == "Néon" and ns.db.modern.preset == "neon", "préréglage Néon enregistré")
  check(t == ns.Theme(), "le thème Modern garde la même table (reconstruite sur place)")
  check(t.accent[1] == neon.accent[1] and t.accent[2] == neon.accent[2] and t.rows == neon.rows and t.gradient == neon.gradient and t.caps,
    "préréglage Néon : accent vert, lignes violettes, dégradé, majuscules")
  check(t.bg == neon.bg and t.edgeSize == neon.edgeSize, "préréglage Néon : fond et bordure du thème Néon")
  -- réglages un par un
  A:SetOpt("modernCaps", false)
  A:SetOpt("modernAccent", "Orange")
  check(not ns.Theme().caps and ns.Theme().rows and math.abs(ns.Theme().accent[1] - 1) < 0.01, "réglages changés un par un (majuscules, accent)")
  A:SetOpt("modernPreset", "Défaut")
  check(not ns.Theme().rows and A:Opt("modernAccent") == "Bleu", "retour au préréglage par défaut")
  PLAYER.class = "SHAMAN"
  RAID_CLASS_COLORS = { SHAMAN = { r = 0, g = 0.44, b = 0.87 } }
  A:SetOpt("modernAccent", "Couleur de classe")
  check(math.abs(ns.Theme().accent[3] - 0.87) < 0.01, "accent : couleur de la classe")
  A:SetOpt("modernPreset", "Défaut")

  -- objectifs : une barre par objectif, libellé sans le compteur
  local g = ns.Guides[ns.cdb.guideId]
  local idx, step
  for k, st in ipairs(g.steps) do if st.type == "complete" and st.quest then idx, step = k, st break end end
  check(step ~= nil, "une étape « faire » dans le guide")
  local oldObj, oldIdx, oldLog = C_QuestLog.GetQuestObjectives, ns.cdb.stepIndex, QLOG[step.quest]
  QLOG[step.quest] = { complete = false }
  C_QuestLog.GetQuestObjectives = function(q)
    if q ~= step.quest then return {} end
    return { { text = "Sangliers tachetés tués : 3/8", numFulfilled = 3, numRequired = 8, finished = false },
             { text = "4/4 Peaux ramassées", numFulfilled = 4, numRequired = 4, finished = true },
             { text = "Parler au chef", finished = false } }
  end
  local rows = ns.Modules.objectives.Rows(step.quest)
  check(#rows == 3 and rows[1].label == "Sangliers tachetés tués" and rows[1].have == 3 and rows[1].need == 8, "objectif : libellé sans compteur, 3 sur 8 (" .. tostring(rows[1].label) .. ")")
  check(rows[2].label == "Peaux ramassées" and rows[2].done, "compteur en tête de texte retiré aussi, objectif fini")
  check(rows[3].label == "Parler au chef" and rows[3].need == nil, "objectif sans compteur : texte seul")
  ns.cdb.stepIndex = idx
  for k = 1, idx do (ns.cdb.skipped[g.id] or {})[k] = nil end
  ns.Modules.objectives:Update()
  check(#G.objData == 3 and #f.objRows == 3, "fenêtre du guide : une ligne par objectif")
  local values = {}
  for k = 1, 3 do
    spy(f.objRows[k].bar); spy(f.objRows[k].count); spy(f.objRows[k].label)
    rawset(f.objRows[k].bar, "SetValue", function(self, v) values[k] = v end)
  end
  G:Layout()
  check(f.objRows[1].bar._shown and f.objRows[1].count._text == "3 / 8" and values[1] == 3, "une barre par objectif, compteur « 3 / 8 »")
  check(f.objRows[2].bar._shown and values[2] == 4 and f.objRows[3].bar._shown == false, "barre pour l'objectif compté, pas pour l'objectif sans compteur")
  check(f.objRows[1].label._text == "Sangliers tachetés tués", "libellé de l'objectif affiché")
  ns.SetModuleEnabled("objectives", false)
  check(#G.objData == 0 and f.objRows[1].bar._shown == false, "module Objectifs désactivé : plus de barres")
  ns.SetModuleEnabled("objectives", true)
  C_QuestLog.GetQuestObjectives, QLOG[step.quest] = oldObj, oldLog
  ns.cdb.stepIndex = oldIdx
  ns.Engine.Refresh()

  -- rappels groupés sous « À côté de la route », étapes suivantes sous « Ensuite »
  ns.Modules.guide:SetOpt("upcoming", 2)
  G:SetSection("testside", 85, "Rappel de test")
  G:Update()
  check(f.hSide._shown and f.hSide._text == ns.Upper("À côté de la route"), "titre « À côté de la route » au-dessus des rappels")
  check(#G.upData >= 1 and f.hNext._shown and f.hNext._text == ns.Upper("Ensuite"), "titre « Ensuite » au-dessus des étapes suivantes")
  G:SetSection("testside", 85, nil)

  -- le titre est un bouton qui ouvre la liste des zones
  check(f.zone and f.zone._scripts.OnClick ~= nil and f.zoneArrow ~= nil, "titre cliquable avec sa flèche")
  local toggled = 0
  local oldToggle = ns.ZonePanel.Toggle
  ns.ZonePanel.Toggle = function() toggled = toggled + 1 end
  f.zone._scripts.OnClick(f.zone)
  check(toggled == 1, "clic sur le titre : la liste des zones s'ouvre")
  ns.ZonePanel.Toggle = oldToggle

  -- Classic : parchemin pour le guide, texte sombre, codes couleur assombris
  A:SetOpt("theme", "Classic")
  check(ns.db.theme == "classic" and ns.Theme().guide and ns.Theme().header, "thème Classic : fond propre au guide et bandeau")
  local r = ns.GuideColor("text")
  check(r < 0.3, "Classic : texte sombre sur le parchemin")
  local inked = ns.Ink("|cffffd100Prendre|r : |cffffffffSarkoth|r")
  check(not inked:find("ffd100") and not inked:find("ffffff") and inked:find("Prendre"), "Classic : jaune et blanc assombris (" .. inked .. ")")
  check(f.header._shown, "Classic : bandeau du titre affiché")
  A:SetOpt("theme", "Classic Forever")
  check(ns.db.theme == "forever" and f.header._shown and not ns.Theme().guide, "thème Classic Forever : bandeau, pas de parchemin")
  check(ns.Ink("|cffffd100x|r") == "|cffffd100x|r", "hors Classic : couleurs inchangées")
  A:SetOpt("theme", "Sombre doré")
  check(f.header._shown == false, "retour à un ancien thème : pas de bandeau")
end

print("ALL TESTS PASSED")
