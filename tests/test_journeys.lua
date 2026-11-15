-- Scénario : itinéraires (réseau appris, transports, A*, guidage virage par virage, minimap, API)
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
local Nav = ns.Nav

FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
check(Nav.db and Nav.char, "base de navigation initialisée")
check(ns.IsEnabled("journeys"), "module itinéraires actif par défaut")

-- conversions monde <-> carte
local c, wx, wy = Nav.ToWorld(1429, 0.5, 0.5)
local m, x, y = Nav.ToMap(c, wx, wy, 1429)
check(m == 1429 and math.abs(x - 0.5) < 1e-9 and math.abs(y - 0.5) < 1e-9, "conversion monde/carte réversible")

-- 1) ligne droite quand rien n'est connu
local A = { c = 0, x = 0, y = 0 }
local B = { c = 0, x = 0, y = -700 }          -- 700 yards à l'est
local j = Nav.Planner.Plan(A, B, { speed = 7 })
check(j and #j.legs == 1 and j.legs[1].mode == "walk", "itinéraire direct à pied")
check(j.legs[1].pts[#j.legs[1].pts].risky, "ligne droite marquée « terrain inconnu »")

-- 2) apprentissage d'un chemin : on marche de A vers B en faisant un petit détour
PLAYER.map = 1429
local function goTo(wxx, wyy)
  local _, mx, my = Nav.ToMap(0, wxx, wyy, 1429)
  PLAYER.x, PLAYER.y = mx, my
  Nav.Net.Sample()
end
for i = 0, 35 do goTo(math.sin(i / 35 * math.pi) * 40, -i * 20) end
local nodes, edges = Nav.Net.Stats()
check(nodes >= 30 and edges >= 29, "chemin appris ("..nodes.." points, "..edges.." liaisons)")
-- repasser au même endroit ne crée pas de doublons
for i = 0, 35 do goTo(math.sin(i / 35 * math.pi) * 40, -i * 20) end
local nodes2 = Nav.Net.Stats()
check(nodes2 == nodes, "points fusionnés au 2e passage")

local j2 = Nav.Planner.Plan(A, B, { speed = 7 })
local known = 0
for _, p in ipairs(j2.legs[1].pts) do if not p.risky then known = known + 1 end end
check(known >= 2, "l'itinéraire emprunte le chemin appris")

-- 3) vol : deux points de vol connus, destination lointaine
Nav.db.flights[ns.PlayerFaction()] = {
  ["10"] = { key = "10", c = 0, x = 0, y = -50, name = "Comté-de-l'Or" },
  ["11"] = { key = "11", c = 0, x = -100, y = -6000, name = "Colline des Sentinelles" },
}
Nav.char.known["10"], Nav.char.known["11"] = true, true
local far = { c = 0, x = -120, y = -6050 }
local j3 = Nav.Planner.Plan(A, far, { speed = 7, flights = true })
local modes = {}
for _, l in ipairs(j3.legs) do modes[#modes + 1] = l.mode end
print("modes :", table.concat(modes, " > "), "durée", math.floor(j3.total))
check(table.concat(modes, ","):find("flight"), "le vol est choisi pour un long trajet")
check(j3.total < 6050 / 7, "plus rapide qu'à pied")

-- 4) bateaux : continent différent atteint via un transport statique
local links = Nav.Transport.Links()
print("liaisons de transport résolues :", #links)

-- 5) pierre de foyer
Nav.char.hearth = { c = 0, x = -110, y = -6040 }
local j5 = Nav.Planner.Plan(A, far, { speed = 7, hearth = true })
check(j5.legs[1].mode == "hearth", "la pierre de foyer est utilisée quand elle est la plus rapide")
Nav.char.hearth = nil

-- 6) guidage virage par virage : le waypoint suit les virages
local placed = {}
ns.Waypoint.PlaceAt = function(self, map, px, py) placed[#placed + 1] = { map, px, py } end
-- étape cible : à l'est sur la carte 1429
local _, tx, ty = Nav.ToMap(0, 0, -700, 1429)
ns.cdb.guideId = nil
ns.Guides["test-journey"] = { id = "test-journey", name = "Test", steps = { { type = "goto", map = 1429, x = tx * 100, y = ty * 100, radius = 5 } } }
ns.Engine.Load("test-journey")
goTo(0, 0)
ns.Journeys:Replan("test")
local jj = ns.Journeys:Journey()
check(jj ~= nil, "itinéraire calculé vers l'étape")
check(#placed >= 1, "premier virage posé comme waypoint")
local before = #placed
local _, l, cidx = ns.Journeys:Journey()
local first = jj.legs[l].pts[cidx]
goTo(first.x, first.y)
ns.Journeys:Tick()
check(#placed > before, "virage atteint : le waypoint passe au suivant")

-- 7) tracé minimap : un point 100 yards au nord apparaît au-dessus du centre
local ox, oy = ns.Journeys.MinimapOffset({ x = 100, y = 0 }, { x = 0, y = 0 }, 0, false, false, nil, 70)
check(math.abs(ox) < 1e-6 and oy > 0, "minimap : nord vers le haut")
local ex = ns.Journeys.MinimapOffset({ x = 0, y = -100 }, { x = 0, y = 0 }, 0, false, false, nil, 70)
check(ex > 0, "minimap : est vers la droite")
local rx, ry = ns.Journeys.MinimapOffset({ x = 100, y = 0 }, { x = 0, y = 0 }, 0, false, true, math.pi / 2, 70)
check(math.abs(ry) < 1e-6 and math.abs(rx) > 1, "minimap tournante : rotation appliquée")
ns.Journeys:DrawMinimap()
check(true, "dessin minimap sans erreur")

-- 8) export / import des chemins
local beforeExport = Nav.Net.Stats()
local text = Nav.Net.Export()
check(text:find("^FPN1"), "export des chemins")
Nav.Net.Reset()
check(Nav.Net.Stats() == 0, "réinitialisation")
local ok, added = Nav.Net.Import(text)
check(ok and added == beforeExport, "import : "..tostring(added).." points restaurés")
check(Nav.Net.Forget(0, 31, -200, 30) > 0, "oubli des liaisons autour d'un point")

-- 9) API publique
local dest = QuestweaverAPI.GetDestination()
check(dest and dest.mapID == 1429, "API : destination")
local got
QuestweaverAPI.RegisterCallback("JourneyChanged", function(j) got = j end)
ns.Journeys:Replan("api")
check(got and got.total and got.legs, "API : événement JourneyChanged")

-- 10) un autre addon pose son point -> on lui laisse la main
FireEvent("USER_WAYPOINT_UPDATED")
check(not ns.Journeys:Driving(), "cohabitation : un autre addon guide le point")

-- slash
SlashCmdList.QUESTWEAVER("paths")
print("ALL TESTS PASSED")
