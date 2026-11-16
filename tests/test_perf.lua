-- Scénario : performances — mode Économie (auto selon les images/s), guidage 3D et flèche sans
-- travail inutile à chaque image, /qw perf
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local P = ns.Perf
check(P and P.enabled, "module Performances toujours actif")

-- 1) mode automatique : entre en économie sous 40 i/s pendant 3 s, en sort après 10 s au-dessus de 55
check(not ns.Eco(), "pas d'économie au départ")
local fired
ns.On("FP_PERF_CHANGED", function(v) fired = v end)
for _ = 1, 5 do P.Sample(30) end
check(not ns.Eco(), "2,5 s de jeu lent : pas encore")
P.Sample(30)
check(ns.Eco() and fired == true, "3 s sous 40 i/s : économie")
for _ = 1, 19 do P.Sample(60) end
check(ns.Eco(), "moins de 10 s rapides : économie gardée")
P.Sample(60)
check(not ns.Eco() and fired == false, "10 s au-dessus de 55 i/s : retour au mode complet")
P:SetOpt("mode", 3)
check(ns.Eco(), "« Toujours en économie »")
P:SetOpt("mode", 2)
for _ = 1, 10 do P.Sample(10) end
check(not ns.Eco(), "« Toujours complet » : jamais d'économie")
P:SetOpt("mode", 1)

-- 2) guidage 3D : la liste des éléments du marqueur de Blizzard n'est plus refaite à chaque image
local regionsCalls = 0
SuperTrackedFrame = { Icon = mockobj(), DistanceText = mockobj(), Arrow = mockobj(), Glow = mockobj(),
    GetRegions = function() regionsCalls = regionsCalls + 1 return mockobj() end,
    GetChildren = function() return end }
local nav = mockobj()
rawset(nav, "GetCenter", function() return 400, 300 end)
rawset(nav, "GetEffectiveScale", function() return 1 end)
C_Navigation = { GetFrame = function() return nav end, HasValidScreenPosition = function() return true end,
    GetTargetState = function() return 0 end, WasClampedToScreen = function() return false end,
    GetDistance = function() return 123.4 end }
C_SuperTrack = { IsSuperTrackingUserWaypoint = function() return true end, SetSuperTrackedUserWaypoint = function() end }
Enum.NavigationState = { Disabled = 3, Occluded = 1, InRange = 2 }
UIParent.GetEffectiveScale = function() return 1 end
UIParent.GetWidth = function() return 1920 end
UIParent.GetHeight = function() return 1080 end
ns.SetModuleEnabled("guide3d", true)
ns.Modules.guide3d:Refresh()
local g3 = _G.QuestweaverGuide3D
local onUpdate = g3._scripts.OnUpdate
regionsCalls = 0
for _ = 1, 240 do onUpdate(g3, 1 / 120) end         -- 2 s à 120 i/s
check(regionsCalls <= 1, "2 s à 120 i/s : éléments de Blizzard lus " .. regionsCalls .. " fois (avant : 240)")
check(#LUA_ERRORS == 0, "guidage 3D sans erreur")
check((ns.Modules.guide3d.trailDots or 0) > 0, "mode complet : points au sol dessinés")
P:SetOpt("mode", 3)
for _ = 1, 60 do onUpdate(g3, 1 / 60) end
check((ns.Modules.guide3d.trailDots or 0) == 0, "économie : pas de points au sol")
P:SetOpt("mode", 1)

-- 3) flèche : le libellé de l'étape n'est recalculé que si l'étape change
local labelCalls, orig = 0, ns.Guide.StepLabel
ns.Guide.StepLabel = function(...) labelCalls = labelCalls + 1 return orig(...) end
local arrow = _G.QuestweaverArrow
if arrow and arrow._scripts.OnUpdate and ns.Engine.NavStep() then
    for _ = 1, 100 do arrow._scripts.OnUpdate(arrow, 0.05) end
    check(labelCalls <= 2, "100 images de flèche : libellé calculé " .. labelCalls .. " fois (avant : 100+)")
    ns.Fire("FP_STEP_CHANGED", true)
    labelCalls = 0
    arrow._scripts.OnUpdate(arrow, 0.05)
    check(labelCalls >= 1, "étape changée : libellé recalculé")
end
ns.Guide.StepLabel = orig

-- 4) métiers : plus lus à chaque appel, seulement après un changement
local profCalls = 0
GetProfessions = function() profCalls = profCalls + 1 return nil end
FireEvent("SKILL_LINES_CHANGED")
profCalls = 0
for _ = 1, 50 do ns.SkillRanks() end
check(profCalls <= 2, "50 lectures des métiers : " .. profCalls .. " appel(s) au jeu")

-- 5) /qw perf
UpdateAddOnMemoryUsage = function() end
local memv = 1000
GetAddOnMemoryUsage = function() memv = memv + 50 return memv end
GetFramerate = function() return 72 end
local res
P.Measure(10, function(r) res = r end)
RunTimers()
check(res and res.fps == 72 and res.kbps and res.kbps > 0, "/qw perf : images/s et mémoire mesurées")
print("perf OK")
