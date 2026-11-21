-- Scénario : données de terrain cuites (crête avec passage à l'est), A* sur grille, intégration aux itinéraires.
-- Prérequis (fait par la CI) : tests/make_fake_adt.py + tools/bake_terrain.py --out /tmp/fp_terrain
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
dofile("/tmp/fp_terrain/Data_1.lua")

FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local Nav, T = ns.Nav, ns.Nav.Terrain
check(T.Has(1), "données de terrain chargées (continent 1)")
check(not T.Has(0), "pas de données pour le continent 0")

local base = 32 * 64
local ax, ay = T.ToWorld(base + 40, base + 10)    -- au sud de la crête, côté ouest
local bx, by = T.ToWorld(base + 20, base + 10)    -- au nord de la crête, côté ouest
check(T.Cell(1, base + 31, base + 10) == 0, "crête infranchissable")
check(T.Cell(1, base + 31, base + 55) == 1, "passage à l'est praticable")
check(T.Cell(1, base + 60, base + 60) == 2, "lac (eau)")
check(not T.LineOfSight(1, base + 40, base + 10, base + 20, base + 10), "pas de ligne de vue à travers la crête")

local pts, n = T.Path(1, { c = 1, x = ax, y = ay }, { c = 1, x = bx, y = by })
check(pts and #pts >= 3, "chemin trouvé ("..(pts and #pts or 0).." points, "..tostring(n).." cases explorées)")
local around = false
for _, p in ipairs(pts) do
  local _, gc = T.ToCell(p.x, p.y)
  -- passage à l'est, ou par l'ouest hors de la tuile (sans données = supposé praticable)
  if gc >= base + 47 or gc < base then around = true end
end
check(around, "le chemin contourne la crête")
for k = 2, #pts do
  local r0, c0 = T.ToCell(pts[k - 1].x, pts[k - 1].y)
  local r1, c1 = T.ToCell(pts[k].x, pts[k].y)
  check(T.LineOfSight(1, r0, c0, r1, c1), "segment "..(k - 1).." sans obstacle")
end

-- calcul asynchrone (étalé sur plusieurs images)
local got
T.BUDGET = 50
T.PathAsync(1, { c = 1, x = ax, y = ay }, { c = 1, x = bx, y = by }, function(p) got = p end)
local frames = 0
while not got and frames < 5000 do T._runner._scripts.OnUpdate(T._runner); frames = frames + 1 end
check(got and #got == #pts, "calcul asynchrone sur "..frames.." images")
T.BUDGET = 2500

-- intégration : la ligne droite « à risque » de l'itinéraire est remplacée par le chemin du terrain
PLAYER.map = 1411
local function setPlayer(wx, wy)
  local _, mx, my = Nav.ToMap(1, wx, wy, 1411)
  PLAYER.x, PLAYER.y = mx, my
end
setPlayer(ax, ay)
local _, tx, ty = Nav.ToMap(1, bx, by, 1411)
ns.Guides["test-terrain"] = { id = "test-terrain", name = "Terrain", steps = { { type = "goto", map = 1411, x = tx * 100, y = ty * 100, radius = 5 } } }
ns.Engine.Load("test-terrain")
ns.Journeys:Replan("test")
local j = ns.Journeys:Journey()
check(j and j.legs[1].mode == "walk", "itinéraire à pied calculé")
frames = 0
while T._runner._scripts and frames < 5000 and #j.legs[1].pts <= 2 do T._runner._scripts.OnUpdate(T._runner); frames = frames + 1 end
check(#j.legs[1].pts > 2, "itinéraire affiné par le terrain ("..#j.legs[1].pts.." points)")
local terrainPts = 0
for _, p in ipairs(j.legs[1].pts) do if p.terrain then terrainPts = terrainPts + 1 end end
check(terrainPts > 0, "points marqués « terrain » (tracé vert d'eau)")
-- budget en temps : une recherche rend la main dès que le budget (ms) de l'image est dépassé,
-- même sous le plafond de nœuds (l'ancien budget de 2 500 nœuds prenait environ 50 ms par image)
local fakeClock = 0
debugprofilestop = function() fakeClock = fakeClock + 2; return fakeClock end   -- 2 ms entre deux contrôles
T.Cancel()
local a2x, a2y = T.ToWorld(base + 45, base + 5)
local b2x, b2y = T.ToWorld(base + 15, base + 20)
local got2, frames2 = nil, 0
T.PathAsync(1, { c = 1, x = a2x, y = a2y }, { c = 1, x = b2x, y = b2y }, function(p) got2 = p end)
while not got2 and frames2 < 5000 do T._runner._scripts.OnUpdate(T._runner); frames2 = frames2 + 1 end
check(got2 and frames2 > 1, "budget en millisecondes respecté ("..frames2.." images)")
debugprofilestop = nil
-- même tronçon redemandé (nouveau calcul d'itinéraire) : réponse immédiate, sans nouvelle recherche
local got3, frames3 = nil, 0
T.PathAsync(1, { c = 1, x = a2x, y = a2y }, { c = 1, x = b2x, y = b2y }, function(p, n) got3 = p; check(n == 0, "tronçon repris du cache") end)
while not got3 and frames3 < 10 do T._runner._scripts.OnUpdate(T._runner); frames3 = frames3 + 1 end
check(got3 and frames3 == 1 and #got3 == #got2, "tronçon déjà calculé rendu en une image")

-- destination lointaine : la ligne droite est découpée en tronçons courts (calculés un par un)
local fx, fy = T.ToWorld(base + 40 - 600, base + 10)     -- 5 000 yards au nord environ
local _, gx, gy = Nav.ToMap(1, fx, fy, 1411)
ns.Guides["test-far"] = { id = "test-far", name = "Loin", steps = { { type = "goto", map = 1411, x = gx * 100, y = gy * 100, radius = 5 } } }
ns.Engine.Load("test-far")
ns.Journeys:Replan("test")
local jf = ns.Journeys:Journey()
check(jf and jf.legs[1].mode == "walk", "itinéraire lointain calculé")
local longest = 0
for k = 2, #jf.legs[1].pts do longest = math.max(longest, Nav.Dist(jf.legs[1].pts[k - 1], jf.legs[1].pts[k])) end
check(#jf.legs[1].pts >= 5 and longest <= 1201, "ligne droite découpée ("..#jf.legs[1].pts.." points, tronçon max "..math.floor(longest).." yards)")
print("ALL TESTS PASSED")
