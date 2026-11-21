local _, ns = ...
local Nav = ns.Nav

-- Planificateur d'itinéraire : A* sur un graphe qui combine
--   - les chemins appris (marche « connue ») ;
--   - des lignes droites entre points clés (marche « à risque », pénalisée) ;
--   - les vols connus, bateaux, zeppelins, tram, et la pierre de foyer.
-- Le résultat est découpé en étapes (marcher, voler, prendre le bateau...) avec leur durée.
local P = {}
Nav.Planner = P

local LINK = 80         -- yards : raccord entre un point clé et le réseau appris
local RISK = 1.25       -- pénalité d'une ligne droite sur terrain inconnu
local FLIGHT_OVERHEAD = 25
local HEARTH_COST = 10 + 15
local MAX_EXPAND = 60000

local function d2(a, b) local dx, dy = a.x - b.x, a.y - b.y; return math.sqrt(dx * dx + dy * dy) end

-- Construit le contexte : points clés + transports
local function buildContext(start, goal, opts)
    local ctx = { pos = {}, key = {}, keyByCont = {}, extra = {}, goal = goal, opts = opts }
    local function addKey(id, p, kind, data)
        ctx.pos[id] = p
        ctx.key[id] = { kind = kind, data = data }
        ctx.keyByCont[p.c] = ctx.keyByCont[p.c] or {}
        table.insert(ctx.keyByCont[p.c], id)
    end
    addKey("S", start, "start")
    addKey("G", goal, "goal")
    ctx.extra.S = {}
    if opts.flights then
        local list = Nav.Transport.Flights()
        for _, f in ipairs(list) do addKey("F:" .. f.key, f, "flight", f) end
        ctx.flights = list
    end
    if opts.boats then
        for i, l in ipairs(Nav.Transport.Links()) do
            addKey("L:" .. i .. ":a", l.a, "dock", l)
            addKey("L:" .. i .. ":b", l.b, "dock", l)
        end
    end
    if opts.hearth then
        local h = Nav.Transport.Hearth()
        if h then
            addKey("H", h, "hearth")
            table.insert(ctx.extra.S, { to = "H", cost = HEARTH_COST, mode = "hearth" })
        end
    end
    return ctx
end

local function nodePos(ctx, id)
    local p = ctx.pos[id]
    if p then return p end
    local c, n = id:match("^N:(%-?%d+):(%d+)$")
    if c then
        c, n = tonumber(c), tonumber(n)
        local node = Nav.Net.Graph(c).nodes[n]
        if node then
            p = { c = c, x = node[1], y = node[2] }
            ctx.pos[id] = p
            return p
        end
    end
end

-- Voisins d'un nœud : liste de { to, cost, mode }
local function neighbors(ctx, id, speed)
    local out = {}
    local p = nodePos(ctx, id)
    if not p then return out end
    local keys = ctx.keyByCont[p.c] or {}
    local kinfo = ctx.key[id]

    if kinfo then
        -- point clé -> autres points clés du même continent (ligne droite)
        for _, other in ipairs(keys) do
            if other ~= id and other ~= "S" then
                local q = ctx.pos[other]
                out[#out + 1] = { to = other, cost = d2(p, q) / speed * RISK, mode = "straight" }
            end
        end
        -- point clé -> réseau appris proche
        for _, n in ipairs(Nav.Net.Near(p.c, p.x, p.y, LINK)) do
            out[#out + 1] = { to = "N:" .. p.c .. ":" .. n.id, cost = n.d / speed, mode = "walk" }
        end
        -- vols
        if kinfo.kind == "flight" and ctx.flights then
            for _, f in ipairs(ctx.flights) do
                local fid = "F:" .. f.key
                if fid ~= id and f.c == p.c then
                    out[#out + 1] = { to = fid, cost = d2(p, f) * 1.25 / Nav.SPEED.flight + FLIGHT_OVERHEAD, mode = "flight" }
                end
            end
        end
        -- bateau / zeppelin / tram
        if kinfo.kind == "dock" then
            local l = kinfo.data
            local other = id:sub(-1) == "a" and id:sub(1, -2) .. "b" or id:sub(1, -2) .. "a"
            out[#out + 1] = { to = other, cost = l.cost, mode = l.kind }
        end
        for _, e in ipairs(ctx.extra[id] or {}) do out[#out + 1] = e end
        return out
    end

    -- nœud du réseau appris
    local c, n = id:match("^N:(%-?%d+):(%d+)$")
    c, n = tonumber(c), tonumber(n)
    local g = Nav.Net.Graph(c)
    for nb, uses in pairs(g.adj[n] or {}) do
        local q = nodePos(ctx, "N:" .. c .. ":" .. nb)
        if q then
            local bonus = 1 - math.min(uses, 10) * 0.01     -- chemins souvent pris : légèrement préférés
            out[#out + 1] = { to = "N:" .. c .. ":" .. nb, cost = d2(p, q) / speed * bonus, mode = "walk" }
        end
    end
    for _, k in ipairs(keys) do
        if k ~= "S" then
            local q = ctx.pos[k]
            local d = d2(p, q)
            if d <= LINK then out[#out + 1] = { to = k, cost = d / speed, mode = "walk" } end
        end
    end
    return out
end

-- Heuristique : borne basse (cohérente) du temps restant. Un trajet vers le but est :
--   1) une marche directe (au mieux 0,9 fois la distance / vitesse : bonus des chemins souvent pris) ;
--   2) ou se termine par un saut « téléport » (bateau, zeppelin, tram, foyer) vers t, puis marche ;
--   3) ou se termine par un vol qui pose en f, atteint d'une traite depuis ici (marche + vols :
--      au mieux KF s/yard) ;
--   4) ou un téléport vers t, puis d'une traite jusqu'au vol qui pose en f.
-- Seules comptent les sorties du continent du but. L'ancienne borne (distance / vitesse de vol,
-- même sans aucun vol connu) était si faible que l'A* explorait tout le réseau appris avant de
-- conclure (0,2 s d'image gelée à chaque nouveau calcul).
local WALK_BONUS = 0.9
local function prepareHeuristic(ctx, speed)
    local g = ctx.goal
    local walkK = WALK_BONUS / speed
    local KF = math.min(walkK, 1.25 / Nav.SPEED.flight)
    local tele, fl = {}, {}
    for id, k in pairs(ctx.key) do
        local q = ctx.pos[id]
        if q.c == g.c then
            if k.kind == "flight" then
                fl[#fl + 1] = { q = q, rest = FLIGHT_OVERHEAD + d2(q, g) * walkK }
            elseif k.kind == "dock" then
                tele[#tele + 1] = { q = q, jmin = k.data.cost }
            elseif k.kind == "hearth" then
                tele[#tele + 1] = { q = q, jmin = HEARTH_COST }
            end
        end
    end
    local const = math.huge
    for _, t in ipairs(tele) do
        const = math.min(const, t.jmin + d2(t.q, g) * walkK)                       -- cas 2
        for _, f in ipairs(fl) do const = math.min(const, t.jmin + d2(t.q, f.q) * KF + f.rest) end  -- cas 4
    end
    ctx.h = { walkK = walkK, KF = KF, fl = fl, const = const }
end

local function heuristic(ctx, id)
    local p = nodePos(ctx, id)
    local g = ctx.goal
    if not (p and p.c == g.c) then return 0 end
    local H = ctx.h
    local best = d2(p, g) * H.walkK                                                 -- cas 1
    if H.const < best then best = H.const end
    for _, f in ipairs(H.fl) do                                                     -- cas 3
        local v = d2(p, f.q) * H.KF + f.rest
        if v < best then best = v end
    end
    return best
end

-- Découpe le chemin trouvé en étapes lisibles
local function toLegs(ctx, path)
    local legs, cur = {}, nil
    local function flush() if cur then legs[#legs + 1] = cur; cur = nil end end
    for i = 2, #path do
        local e = path[i]
        local from, to = nodePos(ctx, path[i - 1].id), nodePos(ctx, e.id)
        if e.mode == "walk" or e.mode == "straight" then
            if not cur or cur.mode ~= "walk" then
                flush()
                cur = { mode = "walk", pts = { { c = from.c, x = from.x, y = from.y } }, time = 0 }
            end
            cur.pts[#cur.pts + 1] = { c = to.c, x = to.x, y = to.y, risky = e.mode == "straight" }
            cur.time = cur.time + e.cost
        else
            flush()
            local leg = { mode = e.mode, from = from, to = to, time = e.cost }
            local k1, k2 = ctx.key[path[i - 1].id], ctx.key[e.id]
            leg.fromName = k1 and k1.data and (k1.data.name or (k1.data.a and k1.data.a.name)) or nil
            leg.toName = (k2 and k2.data and k2.data.name) or (e.mode ~= "hearth" and to and to.name) or nil
            if e.mode == "hearth" then leg.toName = GetBindLocation and GetBindLocation() or nil end
            if k2 and k2.kind == "dock" then leg.toName = to.name end
            legs[#legs + 1] = leg
        end
    end
    flush()
    -- simplification des marches (garde les virages), en conservant le caractère « à risque »
    for _, leg in ipairs(legs) do
        if leg.mode == "walk" and #leg.pts > 2 then
            local simp = Nav.Simplify(leg.pts, 8)
            local idx = {}
            for j, p in ipairs(leg.pts) do idx[p] = j end
            local out = { simp[1] }
            for j = 2, #simp do
                local a, b = idx[simp[j - 1]], idx[simp[j]]
                local risky = false
                for k = a + 1, b do if leg.pts[k].risky then risky = true end end
                local q = simp[j]
                out[#out + 1] = { c = q.c, x = q.x, y = q.y, risky = risky }
            end
            leg.pts = out
        end
    end
    return legs
end

-- start, goal : { c, x, y } (monde). opts : { flights, boats, hearth, speed }
function P.Plan(start, goal, opts)
    opts = opts or {}
    if not (start and goal) then return end
    local speed = opts.speed or Nav.SPEED.run
    local ctx = buildContext(start, goal, opts)
    prepareHeuristic(ctx, speed)
    local heap = Nav.Heap()
    local best, prev, closed = { S = 0 }, {}, {}
    heap:push(heuristic(ctx, "S"), "S")
    local expanded = 0
    while heap.n > 0 do
        local id = heap:pop()
        if id == "G" then break end
        if not closed[id] then
            closed[id] = true
            expanded = expanded + 1
            if expanded > MAX_EXPAND then return end
            local base = best[id]
            for _, e in ipairs(neighbors(ctx, id, speed)) do
                local nc = base + e.cost
                if not closed[e.to] and (not best[e.to] or nc < best[e.to]) then
                    best[e.to] = nc
                    prev[e.to] = { from = id, mode = e.mode, cost = e.cost }
                    heap:push(nc + heuristic(ctx, e.to), e.to)
                end
            end
        end
    end
    if not best.G then return end
    local path, id = {}, "G"
    while id do
        local pr = prev[id]
        table.insert(path, 1, { id = id, mode = pr and pr.mode, cost = pr and pr.cost })
        id = pr and pr.from
    end
    return { legs = toLegs(ctx, path), total = best.G, goal = goal, expanded = expanded }
end
