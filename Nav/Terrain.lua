local _, ns = ...
local Nav = ns.Nav

-- Terrain : zones praticables précalculées (tools/bake_terrain.py) dans l'addon de données
-- Questweaver_Terrain, chargé à la demande. Recherche de chemin A* sur une grille de 8,33 yards
-- (falaises, trous et lave infranchissables, eau plus lente), étalée sur plusieurs images.
local T = {}
Nav.Terrain = T

local TILE = 51200 / 3 / 32
local CELL = TILE / 64
local ORIGIN = 32 * TILE
local CELLS = 64
local B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local B62V = {}
for i = 1, #B62 do B62V[B62:byte(i)] = i - 1 end
local VAL = { [97] = "0", [98] = "1", [99] = "2" }       -- a / b / c

T.COST = { [1] = 1, [2] = 2.2 }                           -- sol, eau
-- Budget par image : en millisecondes (debugprofilestop), avec un plafond en nœuds.
-- Un nœud coûte environ 20 microsecondes en Lua : 2 500 nœuds prenaient environ 50 ms par image.
T.BUDGET = 2500                                            -- nœuds explorés par image (plafond)
T.BUDGET_MS = 3                                            -- ms par image (1,5 en mode Économie)
T.MAX_EXPAND = 40000                                       -- par tronçon (les longs trajets sont découpés)

---------------------------------------------------------------------------
-- Données
---------------------------------------------------------------------------
local loaded, tried = false, false
function T.Load()
    if loaded or QuestweaverTerrainData then loaded = true return true end
    if tried or InCombatLockdown() then return false end
    tried = true
    local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    if load then
        local ok = pcall(load, "Questweaver_Terrain")
        loaded = ok and QuestweaverTerrainData ~= nil
    end
    return loaded
end

function T.Has(cont)
    T.Load()
    return QuestweaverTerrainData and QuestweaverTerrainData[cont] ~= nil
end

local cache, cacheOrder = {}, {}
local CACHE_TILES = 256
local function decode(enc)
    local parts, n = {}, 0
    for i = 1, #enc, 3 do
        local v = VAL[enc:byte(i)]
        local len = B62V[enc:byte(i + 1)] * 62 + B62V[enc:byte(i + 2)]
        n = n + 1
        parts[n] = v:rep(len)
    end
    return table.concat(parts)
end

-- clé numérique (pas de chaîne créée à chaque case : c'était des dizaines de milliers
-- de chaînes par image pendant une recherche)
local function tile(cont, tr, tc)
    local key = (cont + 1) * 1048576 + tr * 1024 + tc
    local t = cache[key]
    if t ~= nil then return t end
    local data = QuestweaverTerrainData and QuestweaverTerrainData[cont]
    local enc = data and data[tr .. ":" .. tc]
    t = enc and decode(enc) or false
    cache[key] = t
    cacheOrder[#cacheOrder + 1] = key
    if #cacheOrder > CACHE_TILES then cache[table.remove(cacheOrder, 1)] = nil end
    return t
end

-- valeur d'une case : 0 bloqué, 1 sol, 2 eau, nil inconnu (pas de données)
function T.Cell(cont, gr, gc)
    local t = tile(cont, math.floor(gr / CELLS), math.floor(gc / CELLS))
    if not t then return nil end
    local i = (gr % CELLS) * CELLS + (gc % CELLS) + 1
    return t:byte(i) - 48
end

function T.ToCell(x, y) return math.floor((ORIGIN - x) / CELL), math.floor((ORIGIN - y) / CELL) end
function T.ToWorld(gr, gc) return ORIGIN - (gr + 0.5) * CELL, ORIGIN - (gc + 0.5) * CELL end

local function passable(cont, gr, gc)
    local v = T.Cell(cont, gr, gc)
    return v == nil or v > 0, v
end

-- ligne de vue entre deux cases (toutes les cases traversées praticables)
function T.LineOfSight(cont, r0, c0, r1, c1)
    local dr, dc = math.abs(r1 - r0), math.abs(c1 - c0)
    local sr, sc = r0 < r1 and 1 or -1, c0 < c1 and 1 or -1
    local err = dr - dc
    local r, c = r0, c0
    local guard = dr + dc + 2
    while guard > 0 do
        guard = guard - 1
        if not passable(cont, r, c) then return false end
        if r == r1 and c == c1 then return true end
        local e2 = 2 * err
        if e2 > -dc then err = err - dc; r = r + sr end
        if e2 < dr then err = err + dr; c = c + sc end
    end
    return true
end

local function nearestPassable(cont, gr, gc)
    if passable(cont, gr, gc) then return gr, gc end
    for rad = 1, 5 do
        for dr = -rad, rad do
            for dc = -rad, rad do
                if math.abs(dr) == rad or math.abs(dc) == rad then
                    if passable(cont, gr + dr, gc + dc) then return gr + dr, gc + dc end
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- A* (coroutine) : renvoie une liste de points monde lissée, ou nil
---------------------------------------------------------------------------
local SQ2 = math.sqrt(2)
local DIRS = { { 1, 0, 1 }, { -1, 0, 1 }, { 0, 1, 1 }, { 0, -1, 1 }, { 1, 1, SQ2 }, { 1, -1, SQ2 }, { -1, 1, SQ2 }, { -1, -1, SQ2 } }
local KEY = 100000

local function clock() return debugprofilestop and debugprofilestop() end
local function budgetMs()
    return (ns.Eco and ns.Eco()) and T.BUDGET_MS / 2 or T.BUDGET_MS
end

local function search(cont, a, b, yieldEvery)
    local sr, sc = T.ToCell(a.x, a.y)
    local gr, gc = T.ToCell(b.x, b.y)
    sr, sc = nearestPassable(cont, sr, sc)
    gr, gc = nearestPassable(cont, gr, gc)
    if not (sr and gr) then return end
    -- fenêtre de recherche : boîte englobante + marge
    local span = math.max(math.abs(gr - sr), math.abs(gc - sc))
    local margin = math.max(40, math.floor(span * 0.4))
    local rmin, rmax = math.min(sr, gr) - margin, math.max(sr, gr) + margin
    local cmin, cmax = math.min(sc, gc) - margin, math.max(sc, gc) + margin
    local function h(r, c)
        local dr, dc = math.abs(r - gr), math.abs(c - gc)
        return (dr + dc) + (SQ2 - 2) * math.min(dr, dc)
    end
    local heap = Nav.Heap()
    local start = sr * KEY + sc
    local goal = gr * KEY + gc
    local g, prev, closed = { [start] = 0 }, {}, {}
    heap:push(h(sr, sc), start)
    local expanded, sinceYield = 0, 0
    local t0 = yieldEvery and clock()
    local ms = yieldEvery and budgetMs()
    while heap.n > 0 do
        local k = heap:pop()
        if k == goal then break end
        if not closed[k] then
            closed[k] = true
            expanded = expanded + 1
            if expanded > T.MAX_EXPAND then return end
            sinceYield = sinceYield + 1
            if yieldEvery then
                -- rend la main à l'image suivante : budget de temps dépassé (vérifié tous les
                -- 64 nœuds) ou plafond de nœuds atteint
                local over = sinceYield >= yieldEvery
                if not over and t0 and sinceYield % 64 == 0 and clock() - t0 >= ms then over = true end
                if over then
                    sinceYield = 0
                    coroutine.yield()
                    if t0 then t0, ms = clock(), budgetMs() end
                end
            end
            local r, c = math.floor(k / KEY), k % KEY
            local base = g[k]
            for _, d in ipairs(DIRS) do
                local nr, nc = r + d[1], c + d[2]
                if nr >= rmin and nr <= rmax and nc >= cmin and nc <= cmax then
                    local ok, v = passable(cont, nr, nc)
                    -- diagonale : pas de coupe de coin entre deux cases bloquées
                    if ok and d[3] > 1 then ok = passable(cont, r + d[1], c) and passable(cont, r, c + d[2]) end
                    if ok then
                        local nk = nr * KEY + nc
                        if not closed[nk] then
                            local cost = base + d[3] * (T.COST[v or 1] or 1)
                            if not g[nk] or cost < g[nk] then
                                g[nk] = cost
                                prev[nk] = k
                                heap:push(cost + h(nr, nc), nk)
                            end
                        end
                    end
                end
            end
        end
    end
    if not g[goal] then return end
    -- reconstruction
    local cells, k = {}, goal
    while k do table.insert(cells, 1, k); k = prev[k] end
    -- lissage : on saute jusqu'au point le plus loin encore visible
    local out, i = { cells[1] }, 1
    while i < #cells do
        local j = #cells
        local r0, c0 = math.floor(cells[i] / KEY), cells[i] % KEY
        while j > i + 1 do
            local r1, c1 = math.floor(cells[j] / KEY), cells[j] % KEY
            if T.LineOfSight(cont, r0, c0, r1, c1) then break end
            j = j - 1
        end
        out[#out + 1] = cells[j]
        i = j
    end
    local pts = {}
    for idx, ck in ipairs(out) do
        local x, y = T.ToWorld(math.floor(ck / KEY), ck % KEY)
        pts[idx] = { c = cont, x = x, y = y }
    end
    -- extrémités exactes
    pts[1] = { c = cont, x = a.x, y = a.y }
    pts[#pts] = { c = cont, x = b.x, y = b.y }
    return pts, expanded
end

-- Résultats déjà calculés (un nouveau calcul d'itinéraire redemande souvent les mêmes tronçons)
local results, resultOrder = {}, {}
local function resultKey(cont, a, b)
    local ar, ac = T.ToCell(a.x, a.y)
    local br, bc = T.ToCell(b.x, b.y)
    return cont .. ":" .. ar .. ":" .. ac .. ":" .. br .. ":" .. bc
end
local function remember(key, pts)
    if results[key] == nil then
        resultOrder[#resultOrder + 1] = key
        if #resultOrder > 64 then results[table.remove(resultOrder, 1)] = nil end
    end
    results[key] = pts or false
end
local function copyPts(pts, a, b)
    if not pts then return end
    local out = {}
    for i, p in ipairs(pts) do out[i] = { c = p.c, x = p.x, y = p.y } end
    out[1].x, out[1].y = a.x, a.y
    out[#out].x, out[#out].y = b.x, b.y
    return out
end

-- Synchrone (tests, petits trajets)
function T.Path(cont, a, b) return search(cont, a, b, nil) end

-- Asynchrone : file de calculs, T.BUDGET nœuds par image
local jobs = {}
local runner = CreateFrame("Frame")
runner:Hide()
T._runner = runner      -- (tests)
runner:SetScript("OnUpdate", function(self)
    local job = jobs[1]
    if not job then self:Hide() return end
    local ok, done = coroutine.resume(job.co)
    if not ok or coroutine.status(job.co) == "dead" then
        table.remove(jobs, 1)
        if not ok then geterrorhandler()(done) end
    end
end)

function T.PathAsync(cont, a, b, callback)
    local job = {}
    local key = resultKey(cont, a, b)
    job.co = coroutine.create(function()
        local known = results[key]
        if known ~= nil then
            callback(copyPts(known or nil, a, b), 0)
            return
        end
        local pts, n = search(cont, a, b, T.BUDGET)
        remember(key, pts)
        callback(copyPts(pts, a, b), n)
    end)
    jobs[#jobs + 1] = job
    runner:Show()
    return job
end

function T.Cancel()
    wipe(jobs)
    runner:Hide()
end
