local _, ns = ...

-- Socle de navigation : coordonnées « monde » (yards, par continent) et outils communs.
-- Les itinéraires sont calculés en coordonnées monde (indépendantes des cartes de zone),
-- puis reconvertis en positions de carte pour le waypoint et l'affichage.
local Nav = {}
ns.Nav = Nav

-- Vitesses (yards / seconde)
Nav.SPEED = { run = 7, mount = 11.2, flight = 30 }

local sqrt = math.sqrt

function Nav.Dist(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return sqrt(dx * dx + dy * dy)
end

-- carte (uiMapID, x/y 0..1) -> continent, x, y monde
function Nav.ToWorld(mapID, x, y)
    if not (mapID and x and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
    local cont, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    if not (cont and pos) then return end
    local wx, wy = pos:GetXY()
    return cont, wx, wy
end

-- monde -> position sur une carte donnée (x/y peuvent sortir de 0..1 hors de la carte)
function Nav.ToMap(cont, wx, wy, mapID)
    if not (C_Map.GetMapPosFromWorldPos and CreateVector2D) then return end
    local ok, m, pos = pcall(C_Map.GetMapPosFromWorldPos, cont, CreateVector2D(wx, wy), mapID)
    if not ok or not pos then return end
    local x, y = pos:GetXY()
    return m or mapID, x, y
end

-- Position monde du joueur (nil en instance ou si le jeu la masque)
function Nav.Player()
    local mapID, x, y = ns.PlayerMapPos()
    if not (mapID and x) or ns.IsSecret(x) then return end
    local cont, wx, wy = Nav.ToWorld(mapID, x, y)
    if not cont then return end
    return { c = cont, x = wx, y = wy, map = mapID, mx = x, my = y }
end

-- Point monde d'une étape de guide
function Nav.StepPoint(step)
    local map = step and ns.Geo.StepMap(step)
    if not (map and step.x) then return end
    local cont, wx, wy = Nav.ToWorld(map, step.x / 100, step.y / 100)
    if not cont then return end
    return { c = cont, x = wx, y = wy, map = map, mx = step.x / 100, my = step.y / 100 }
end

function Nav.RunSpeed()
    return (IsMounted and IsMounted()) and Nav.SPEED.mount or Nav.SPEED.run
end

---------------------------------------------------------------------------
-- Tas binaire (file de priorité pour A*)
---------------------------------------------------------------------------
local Heap = {}
Heap.__index = Heap
function Nav.Heap() return setmetatable({ n = 0, k = {}, v = {} }, Heap) end

function Heap:push(key, value)
    local n = self.n + 1
    self.n = n
    local k, v = self.k, self.v
    k[n], v[n] = key, value
    while n > 1 do
        local p = math.floor(n / 2)
        if k[p] <= k[n] then break end
        k[p], k[n] = k[n], k[p]
        v[p], v[n] = v[n], v[p]
        n = p
    end
end

function Heap:pop()
    local n = self.n
    if n == 0 then return end
    local k, v = self.k, self.v
    local rk, rv = k[1], v[1]
    k[1], v[1] = k[n], v[n]
    k[n], v[n] = nil, nil
    n = n - 1
    self.n = n
    local i = 1
    while true do
        local l, r, s = i * 2, i * 2 + 1, i
        if l <= n and k[l] < k[s] then s = l end
        if r <= n and k[r] < k[s] then s = r end
        if s == i then break end
        k[s], k[i] = k[i], k[s]
        v[s], v[i] = v[i], v[s]
        i = s
    end
    return rv, rk
end

---------------------------------------------------------------------------
-- Simplification de polyligne (Douglas-Peucker), points {x, y}
---------------------------------------------------------------------------
local function segDist(p, a, b)
    local dx, dy = b.x - a.x, b.y - a.y
    local len2 = dx * dx + dy * dy
    if len2 == 0 then return Nav.Dist(p, a) end
    local t = math.max(0, math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2))
    local qx, qy = a.x + t * dx, a.y + t * dy
    return sqrt((p.x - qx) ^ 2 + (p.y - qy) ^ 2)
end
Nav.SegDist = segDist

function Nav.Simplify(pts, tol)
    if #pts <= 2 then return pts end
    local keep = { [1] = true, [#pts] = true }
    local stack = { { 1, #pts } }
    while #stack > 0 do
        local s = table.remove(stack)
        local i0, i1 = s[1], s[2]
        local maxd, idx = 0, nil
        for i = i0 + 1, i1 - 1 do
            local d = segDist(pts[i], pts[i0], pts[i1])
            if d > maxd then maxd, idx = d, i end
        end
        if idx and maxd > tol then
            keep[idx] = true
            stack[#stack + 1] = { i0, idx }
            stack[#stack + 1] = { idx, i1 }
        end
    end
    local out = {}
    for i = 1, #pts do if keep[i] then out[#out + 1] = pts[i] end end
    return out
end

-- Stockage partagé (compte) : chemins appris, vols connus, foyer
ns.On("FP_INIT", function()
    QuestweaverNavDB = QuestweaverNavDB or {}
    local db = QuestweaverNavDB
    db.version = db.version or 1
    db.paths = db.paths or {}       -- [continent] = { nodes = {...}, edges = {...} }
    db.flights = db.flights or {}   -- [faction] = { [nodeKey] = {...} }
    db.chars = db.chars or {}       -- [nom-royaume] = { hearth = {...}, known = { [nodeKey]=true } }
    Nav.db = db
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "?")
    db.chars[key] = db.chars[key] or {}
    Nav.char = db.chars[key]
    Nav.char.known = Nav.char.known or {}
    ns.Fire("FP_NAV_READY")
end)
