-- Scénario : bibliothèque, éditeur, rares, métiers d'appoint, monture, talents, bouton minimap
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
NOW = 200000
time = function() return NOW end
date = function() return "14/11 22:00" end
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local E = ns.Engine

-- bibliothèque : import d'une route
local L = ns.Modules.library
local text = [[
# nom: Rives Claires 36-40
# niveaux: 36-40
# faction: Horde
M elwynn
A 9001 @40,60 id=1
C 9001 @45,62
T 9001 @40,60 id=1
]]
local id = L.Import(text)
check(id and ns.Guides[id] and #ns.Guides[id].steps == 3, "route importée (3 étapes)")
check(ns.Guides[id].faction == "Horde" and ns.Guides[id].minLevel == 36, "en-têtes lus")
check(ns.db.library[id].name == "Rives Claires 36-40", "gardée dans la bibliothèque")
check(L.Parse("pas une route") == nil, "texte invalide refusé")
L.Delete(id)
check(ns.Guides[id] == nil, "route supprimée")

-- éditeur
local Ed = ns.Modules.editor
ns.Guides["test-edit"] = { id = "test-edit", name = "Edit", minLevel = 1, maxLevel = 5, steps = ns.ParseGuide([[
M elwynn
G "Va au camp" @40,60 r=5
N "Parle au garde"
G "Va à la tour" @70,20 r=5
]]) }
PLAYER.map, PLAYER.x, PLAYER.y = 1429, 0.10, 0.10
E.Load("test-edit")
PLAYER.x, PLAYER.y = 0.333, 0.444
Ed.SetPos()
local st = ns.Guides["test-edit"].steps[1]
check(st.x == 33.3 and st.y == 44.4, "position corrigée sur la mienne")
check(ns.db.edits["test-edit"].pos[1].x == 33.3, "correction enregistrée")
E.Refresh()
check(select(3, E.Current()) == 2, "étape validée à la nouvelle position")
Ed.Remove()
check(select(3, E.Current()) == 3, "étape retirée")
Ed.AddNote("Attention aux murlocs")
check(ns.Guides["test-edit"].steps[4].text == "Attention aux murlocs", "note ajoutée")
local out = Ed.Export(ns.Guides["test-edit"])
check(out:find("@33.3,44.4") and not out:find("Parle au garde") and out:find("Attention aux murlocs"), "export de la route corrigée")
-- ré-application au chargement (nouvelle session)
ns.Guides["test-edit2"] = { id = "test-edit2", steps = ns.ParseGuide("M elwynn\nG \"A\" @1,1\nN \"B\"\n") }
ns.db.edits["test-edit2"] = { pos = { [1] = { map = 1429, x = 5, y = 6 } }, removed = { [2] = true }, notes = { { after = 1, text = "C" } } }
ns.ApplyEdits(ns.Guides["test-edit2"])
local s2 = ns.Guides["test-edit2"].steps
check(s2[1].x == 5 and s2[2].text == "C" and s2[3].removed, "corrections réappliquées au chargement")
check(L.Parse(out) ~= nil, "la route exportée se réimporte")

-- rares
PLAYER.level = 10
local rares = ns.Modules.rares.ForMap(1429)
check(#rares > 0, "rares d'Elwynn autour du niveau 10 ("..#rares..")")
local okLvl = true
for _, r in ipairs(rares) do if r.max < 0 or r.min > 20 then okLvl = false end end
check(okLvl, "filtrés autour de mon niveau")

-- métiers d'appoint
PLAYER.faction = "Alliance"
GetProfessions = function() return nil, nil, nil, nil, nil end
PLAYER.map = 1429
check(ns.Nav.Places.NearestTrainerOf("FIRSTAID"), "maîtres de secourisme dans les données")
table.insert(ns.Nav.Places.Trainers(), { class = "FIRSTAID", npc = 1, map = 1429, x = 42, y = 64, faction = "Alliance", name = "Infirmier" })
local t = ns.Nav.Places.NearestTrainerOf("FIRSTAID")
PLAYER.x, PLAYER.y = t.x / 100, t.y / 100
local kind = ns.Modules.secondary.Suggest()
check(kind == "FIRSTAID", "secourisme proposé tout près")
GetProfessions = function() return 1 end
GetProfessionInfo = function() return "Secourisme", nil, 1, 75, nil, nil, 129 end
check(ns.Modules.secondary.Suggest() == nil, "rien si déjà appris")

-- monture
GetMoney = function() return 340000 end
local money, goal = ns.Modules.gold.State()
check(money == 340000 and goal == 900000, "or et objectif (34 / 90 po)")

-- talents
GetUnspentTalentPoints = function() return 2 end
check(ns.Modules.talents.Unspent() == 2, "points de talent à dépenser")

-- bouton minimap
check(ns.Modules.minimapbutton.button ~= nil, "bouton de la minimap créé")
print("ALL TESTS PASSED")
