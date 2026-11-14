local _, ns = ...
local Nav = ns.Nav

-- Réseau de chemins appris : pendant que tu marches / montes / nages (hors combat, hors instance,
-- hors vol), ta position est notée tous les ~18 yards. Les points proches fusionnent, les
-- croisements et routes partagées se rejoignent : un graphe des chemins réellement praticables.
local Net = {}
Nav.Net = Net

local MERGE = 10        -- yards : un point plus proche qu'un nœud existant le réutilise
local STEP = 18         -- yards entre deux points enregistrés
local JUMP = 70         -- au-delà : téléportation / chute / vol -> pas de lien
local CELL = 50         -- grille spatiale
local MAX_NODES = 20000 -- par continent

local graphs = {}       -- [cont] = { nodes, adj, grid }

local function cellKey(x, y) return math.floor(x / CELL) .. ":" .. math.floor(y / CELL) end

local function store(cont)
    local p = Nav.db.paths
    p[cont] = p[cont] or { nodes = {}, edges = {} }
    return p[cont]
end

-- Graphe en mémoire (adjacence + grille) construit depuis la sauvegarde
function Net.Graph(cont)
    local g = graphs[cont]
    if g then return g end
    local s = store(cont)
    g = { nodes = s.nodes, edges = s.edges, adj = {}, grid = {} }
    for i, n in ipairs(s.nodes) do
        local k = cellKey(n[1], n[2])
        g.grid[k] = g.grid[k] or {}
        table.insert(g.grid[k], i)
        g.adj[i] = {}
    end
    for key, uses in pairs(s.edges) do
        local a, b = key:match("^(%d+):(%d+)$")
        a, b = tonumber(a), tonumber(b)
        if a and b and g.adj[a] and g.adj[b] then
            g.adj[a][b] = uses
            g.adj[b][a] = uses
        end
    end
    graphs[cont] = g
    return g
end

function Net.Reset(cont)
    if cont then Nav.db.paths[cont] = nil; graphs[cont] = nil
    else wipe(Nav.db.paths); wipe(graphs) end
end

-- Nœuds dans un rayon (yards) autour de (x, y)
function Net.Near(cont, x, y, radius)
    local g = Net.Graph(cont)
    local out = {}
    local r = math.ceil(radius / CELL)
    local cx, cy = math.floor(x / CELL), math.floor(y / CELL)
    for i = cx - r, cx + r do
        for j = cy - r, cy + r do
            local list = g.grid[i .. ":" .. j]
            if list then
                for _, id in ipairs(list) do
                    local n = g.nodes[id]
                    local d = math.sqrt((n[1] - x) ^ 2 + (n[2] - y) ^ 2)
                    if d <= radius then out[#out + 1] = { id = id, d = d } end
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.d < b.d end)
    return out
end

-- Ajoute (ou réutilise) un nœud ; retourne son id
function Net.AddPoint(cont, x, y)
    local g = Net.Graph(cont)
    local near = Net.Near(cont, x, y, MERGE)
    if near[1] then
        local n = g.nodes[near[1].id]
        n[3] = (n[3] or 1) + 1
        return near[1].id
    end
    if #g.nodes >= MAX_NODES then return end
    local id = #g.nodes + 1
    g.nodes[id] = { math.floor(x * 2 + 0.5) / 2, math.floor(y * 2 + 0.5) / 2, 1 }
    local k = cellKey(x, y)
    g.grid[k] = g.grid[k] or {}
    table.insert(g.grid[k], id)
    g.adj[id] = {}
    return id
end

function Net.Link(cont, a, b)
    if not (a and b) or a == b then return end
    local g = Net.Graph(cont)
    local key = a < b and (a .. ":" .. b) or (b .. ":" .. a)
    local uses = (g.edges[key] or 0) + 1
    g.edges[key] = uses
    g.adj[a][b] = uses
    g.adj[b][a] = uses
end

-- Oublie les liaisons autour d'un point (ex. une falaise sautée qu'on ne peut pas remonter)
function Net.Forget(cont, x, y, radius)
    local g = Net.Graph(cont)
    local n = 0
    for _, near in ipairs(Net.Near(cont, x, y, radius)) do
        local a = near.id
        for b in pairs(g.adj[a] or {}) do
            local key = a < b and (a .. ":" .. b) or (b .. ":" .. a)
            if g.edges[key] then g.edges[key] = nil; n = n + 1 end
            if g.adj[b] then g.adj[b][a] = nil end
        end
        g.adj[a] = {}
    end
    return n
end

function Net.Stats()
    local nodes, edges, conts = 0, 0, 0
    for _, s in pairs(Nav.db and Nav.db.paths or {}) do
        conts = conts + 1
        nodes = nodes + #s.nodes
        for _ in pairs(s.edges) do edges = edges + 1 end
    end
    return nodes, edges, conts
end

---------------------------------------------------------------------------
-- Apprentissage
---------------------------------------------------------------------------
local last          -- { c, x, y, id }
Net.learning = true

local function canLearn()
    if not Net.learning then return false end
    if InCombatLockdown() or IsInInstance() then return false end
    if UnitOnTaxi("player") or UnitIsDeadOrGhost("player") then return false end
    if IsFlying and IsFlying() then return false end
    if IsFalling and IsFalling() then return false end
    return true
end

function Net.Sample()
    if not (Nav.db and canLearn()) then last = nil return end
    local p = Nav.Player()
    if not p then last = nil return end
    if last and last.c == p.c then
        local d = Nav.Dist(last, p)
        if d < STEP then return end
        if d > JUMP then last = nil end
    else
        last = nil
    end
    local id = Net.AddPoint(p.c, p.x, p.y)
    if last and id then Net.Link(p.c, last.id, id) end
    last = id and { c = p.c, x = p.x, y = p.y, id = id } or nil
end

-- coupure (téléportation, chargement, mort...) : pas de lien avec le point suivant
function Net.Break() last = nil end

---------------------------------------------------------------------------
-- Partage : export / import texte (fusion)
---------------------------------------------------------------------------
function Net.Export()
    local out = { "FPN1" }
    for cont, s in pairs(Nav.db.paths) do
        local nodes, edges = {}, {}
        for _, n in ipairs(s.nodes) do nodes[#nodes + 1] = ("%g,%g"):format(n[1], n[2]) end
        for key in pairs(s.edges) do edges[#edges + 1] = key end
        out[#out + 1] = ("C%d;%s;%s"):format(cont, table.concat(nodes, "|"), table.concat(edges, "|"))
    end
    return table.concat(out, "\n")
end

function Net.Import(text)
    if not text or not text:find("^FPN1") then return false, ns.Tr("format inconnu") end
    local added = 0
    for line in text:gmatch("[^\n]+") do
        local cont, nodes, edges = line:match("^C(%d+);([^;]*);(.*)$")
        cont = tonumber(cont)
        if cont then
            local map = {}
            local i = 0
            for xy in nodes:gmatch("[^|]+") do
                i = i + 1
                local x, y = xy:match("^([%-%d%.]+),([%-%d%.]+)$")
                if x then
                    local before = #Net.Graph(cont).nodes
                    map[i] = Net.AddPoint(cont, tonumber(x), tonumber(y))
                    if #Net.Graph(cont).nodes > before then added = added + 1 end
                end
            end
            for e in edges:gmatch("[^|]+") do
                local a, b = e:match("^(%d+):(%d+)$")
                Net.Link(cont, map[tonumber(a)], map[tonumber(b)])
            end
        end
    end
    return true, added
end
