local _, ns = ...

-- Géométrie : distance (yards) et angle relatif vers une étape, même si elle est sur une autre carte
-- du même continent. Retourne nil en instance (position non fournie par le jeu).
local Geo = {}
ns.Geo = Geo

local atan2, sqrt, pi = math.atan2 or function(y, x) return math.atan(y, x) end, math.sqrt, math.pi

local function worldPos(mapID, x, y)
    if not (C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
    local cont, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    if not cont or not pos then return end
    local wx, wy = pos:GetXY()   -- wx = nord, wy = ouest
    return cont, wx, wy
end

function Geo.StepMap(step)
    return step and ns.MapFor(step.map)
end

-- Retourne dist (yards), bearing (radians, 0 = nord, sens antihoraire) du joueur vers l'étape
function Geo.Vector(step)
    local map = Geo.StepMap(step)
    if not (map and step.x) then return end
    local pMap, px, py = ns.PlayerMapPos()
    if not (pMap and px) then return end
    local tx, ty = step.x / 100, step.y / 100

    -- 1) coordonnées monde (fonctionne entre cartes)
    local pc, pwx, pwy = worldPos(pMap, px, py)
    local tc, twx, twy = worldPos(map, tx, ty)
    if pc and tc and pc == tc then
        local north, west = twx - pwx, twy - pwy
        return sqrt(north * north + west * west), atan2(west, north)
    end

    -- 2) repli : même carte, via la taille de la carte
    if pMap == map and C_Map.GetMapWorldSize then
        local w, h = C_Map.GetMapWorldSize(map)
        if w and w > 0 then
            local east, north = (tx - px) * w, (py - ty) * h
            return sqrt(east * east + north * north), atan2(-east, north)
        end
    end
end

-- Angle de la flèche à l'écran (0 = droit devant)
function Geo.RelativeAngle(bearing)
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not facing or ns.IsSecret(facing) then return end
    local a = bearing - facing
    while a < 0 do a = a + 2 * pi end
    while a >= 2 * pi do a = a - 2 * pi end
    return a
end
