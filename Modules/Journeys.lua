local _, ns = ...
local Nav = ns.Nav

-- Itinéraires : le chemin le plus rapide vers l'étape (marche sur les chemins appris, vols,
-- bateaux, zeppelins, tram, pierre de foyer), guidé virage par virage : le waypoint du jeu
-- est déplacé de virage en virage, donc la flèche et le guidage 3D suivent le chemin.
local M = ns.RegisterModule({
    id = "journeys", category = "nav", default = true,
    name = ns.Tr("Itinéraires (chemin le plus rapide)"),
    desc = ns.Tr("Calcule le trajet le plus rapide vers l'étape : chemins déjà parcourus, vols, bateaux, zeppelins, tram, pierre de foyer. Guidage virage par virage (la flèche et la 3D suivent), tracé sur la carte et la minimap."),
    options = {
        { key = "learn", label = ns.Tr("Apprendre les chemins en jouant"), type = "check", default = true },
        { key = "corners", label = "Guider virage par virage", type = "check", default = true },
        { key = "terrain", label = ns.Tr("Contourner falaises et lacs (données de terrain)"), type = "check", default = true },
        { key = "flights", label = ns.Tr("Utiliser les vols connus"), type = "check", default = true },
        { key = "boats", label = ns.Tr("Utiliser bateaux, zeppelins et tram"), type = "check", default = true },
        { key = "hearth", label = ns.Tr("Utiliser la pierre de foyer"), type = "check", default = true },
        { key = "card", label = ns.Tr("Détail du trajet dans le guide"), type = "check", default = true },
        { key = "minimap", label = ns.Tr("Tracé sur la minimap"), type = "check", default = true },
        { key = "yield", label = ns.Tr("Laisser un autre addon guider s'il pose son point (Naowh...)"), type = "check", default = true },
        { key = "overDaylight", label = ns.Tr("Avec Daylight UI : reprendre son point pour qu'il suive notre itinéraire"), type = "check", default = true },
    },
})
ns.Journeys = M

local ARRIVE = 12          -- yards : virage atteint
local DEVIATE = 60         -- yards : trop loin du chemin -> nouveau calcul
local DEVIATE_RISKY = 150  -- yards : idem sur une ligne droite « à risque » (on suit les routes)
local CHUNK = 1200         -- yards : longueur max d'un tronçon affiné par le terrain
local MAX_CHUNKS = 12      -- au-delà (14 km environ), le reste de la ligne droite n'est pas affiné
local ARRIVE_TRANSPORT = 30

M.COLORS = {
    known = { 0.3, 0.9, 0.35 }, terrain = { 0.45, 0.95, 0.75 }, risky = { 1, 0.55, 0.15 }, flight = { 0.35, 0.7, 1 },
    boat = { 0.3, 0.9, 0.9 }, zeppelin = { 0.85, 0.45, 1 }, tram = { 0.8, 0.8, 0.8 }, hearth = { 1, 0.5, 0.8 },
}
local LABEL = {
    walk = ns.Tr("Marcher"), flight = ns.Tr("Vol"), boat = ns.Tr("Bateau"), zeppelin = "Zeppelin", tram = "Tram", hearth = ns.Tr("Pierre de foyer"),
}

local journey, leg, corner, target
local external = false
local lastPlan = 0

---------------------------------------------------------------------------
-- API publique (pour Naowh Forever, Daylight UI, ou tout autre addon)
---------------------------------------------------------------------------
local callbacks = { DestinationChanged = {}, JourneyChanged = {} }
local function fire(event, ...)
    for _, fn in ipairs(callbacks[event]) do pcall(fn, ...) end
    if EventRegistry and EventRegistry.TriggerEvent then
        pcall(EventRegistry.TriggerEvent, EventRegistry, "Questweaver." .. event, ...)
    end
end

QuestweaverAPI = {
    version = 1,
    -- Destination de l'étape en cours : { mapID, x, y (0..1), title, questID, type }
    GetDestination = function()
        local step = ns.Engine.NavStep()
        local map = step and ns.Geo.StepMap(step)
        if not (map and step.x) then return end
        local label = ns.Guide and ns.Guide.StepLabel(step) or ""
        return { mapID = map, x = step.x / 100, y = step.y / 100, title = (label:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")),
                 questID = step.quest, type = step.type }
    end,
    -- Itinéraire calculé : { total = secondes, legs = { { mode, time, toName } ... } }
    GetJourney = function()
        if not journey then return end
        local legs = {}
        for _, l in ipairs(journey.legs) do legs[#legs + 1] = { mode = l.mode, time = l.time, toName = l.toName } end
        return { total = journey.total, legs = legs }
    end,
    -- Événements : "DestinationChanged", "JourneyChanged". Aussi via EventRegistry ("Questweaver.<event>").
    RegisterCallback = function(event, fn)
        if callbacks[event] and type(fn) == "function" then table.insert(callbacks[event], fn) return true end
    end,
}

---------------------------------------------------------------------------
-- Waypoint sur un point monde
---------------------------------------------------------------------------
local function placeWorld(p)
    if not (p and ns.Waypoint) then return end
    local candidates = { (ns.PlayerMapPos()), target and target.map, p.map }
    for _, map in ipairs(candidates) do
        if map then
            local m, x, y = Nav.ToMap(p.c, p.x, p.y, map)
            if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                ns.Waypoint:PlaceAt(m, x, y)
                return
            end
        end
    end
end

local function currentPoint()
    if not journey then return end
    local l = journey.legs[leg]
    if not l then return end
    if l.mode == "walk" then return l.pts[corner] or l.pts[#l.pts] end
    return l.from
end

local function drive()
    if not (M:Opt("corners") and journey) then return end
    if external and M:Opt("yield") then return end
    placeWorld(currentPoint())
end

function M:Driving()
    return self.enabled and self:Opt("corners") and journey ~= nil and not (external and self:Opt("yield"))
end

---------------------------------------------------------------------------
-- Affinage par le terrain (falaises, trous, eau) : les lignes droites « à risque »
-- sont remplacées par un chemin sur la grille du terrain, calculé en arrière-plan.
---------------------------------------------------------------------------
local refineToken = 0
local function refine(j)
    local Terrain = Nav.Terrain
    if not (Terrain and j and M:Opt("terrain")) then return end
    refineToken = refineToken + 1
    local token = refineToken
    Terrain.Cancel()
    local queued = 0
    for li, l in ipairs(j.legs) do
        if l.mode == "walk" then
            -- les longues lignes droites sont découpées en tronçons de CHUNK yards, comptés depuis
            -- l'arrivée : un nouveau calcul (le joueur a bougé) retrouve les mêmes tronçons, déjà
            -- calculés, et seul le premier est refait. Un seul calcul géant gelait le jeu.
            local si = 2
            while si <= #l.pts do
                local a, b = l.pts[si - 1], l.pts[si]
                local d = a.c == b.c and Nav.Dist(a, b) or 0
                if b.risky and d > CHUNK then
                    local k = math.floor(d / CHUNK)
                    for n = k, 1, -1 do
                        local f = 1 - n * CHUNK / d
                        if f * d > 25 then
                            table.insert(l.pts, si, { c = b.c, x = a.x + (b.x - a.x) * f, y = a.y + (b.y - a.y) * f, risky = true })
                            si = si + 1
                        end
                    end
                end
                si = si + 1
            end
            for si2 = 2, #l.pts do
                local a, b = l.pts[si2 - 1], l.pts[si2]
                if b.risky and a.c == b.c and Nav.Dist(a, b) > 25 and queued < MAX_CHUNKS and Terrain.Has(b.c) then
                    queued = queued + 1
                    Terrain.PathAsync(b.c, a, b, function(pts)
                        if token ~= refineToken or journey ~= j or not pts then return end
                        -- retrouve le segment (les indices ont pu bouger)
                        local idx
                        for k = 2, #l.pts do if l.pts[k] == b and l.pts[k - 1] == a then idx = k end end
                        if not idx then return end
                        local before = Nav.Dist(a, b)
                        local len, inserted = 0, 0
                        for k = 2, #pts do len = len + Nav.Dist(pts[k - 1], pts[k]) end
                        for k = 2, #pts - 1 do
                            local p = pts[k]
                            p.terrain = true
                            table.insert(l.pts, idx + inserted, p)
                            inserted = inserted + 1
                        end
                        b.risky, b.terrain = false, true
                        l.time = l.time + (len - before * 1.25) / Nav.RunSpeed()
                        if li == leg then
                            if idx + inserted <= corner then corner = corner + inserted
                            elseif idx <= corner then corner = idx end
                            drive()
                        end
                        M:Render()
                        fire("JourneyChanged", QuestweaverAPI.GetJourney())
                    end)
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Calcul
---------------------------------------------------------------------------
function M:Replan(reason)
    lastPlan = GetTime()
    local step = ns.Engine.NavStep()
    local goal = Nav.StepPoint(step)
    local start = Nav.Player()
    target = goal
    if not (self.enabled and goal and start and Nav.db) then
        journey = nil
        if self.enabled and ns.Waypoint and ns.Waypoint.enabled then ns.Waypoint:Place(false, true) end
        self:Render()
        return
    end
    journey = Nav.Planner.Plan(start, goal, {
        flights = self:Opt("flights"), boats = self:Opt("boats"), hearth = self:Opt("hearth"),
        speed = Nav.RunSpeed(),
    })
    leg, corner = 1, 2
    self.reason = reason
    if journey then
        refine(journey)     -- (peut insérer des points de découpe : le virage est posé après)
        drive()
    elseif ns.Waypoint and ns.Waypoint.enabled then
        ns.Waypoint:Place(false)     -- pas d'itinéraire : point directement sur l'étape
    end
    self:Render()
    fire("JourneyChanged", QuestweaverAPI.GetJourney())
end

---------------------------------------------------------------------------
-- Suivi de la progression
---------------------------------------------------------------------------
local function advance(p)
    local l = journey and journey.legs[leg]
    if not l then return end
    if l.mode == "walk" then
        local c = l.pts[corner]
        if not c then leg, corner = leg + 1, 2; drive(); M:Render(); return end
        if c.c == p.c and Nav.Dist(c, p) <= ARRIVE then
            corner = corner + 1
            if corner > #l.pts then leg, corner = leg + 1, 2 end
            drive()
            M:Render()
            return
        end
        -- trop loin du segment en cours : on recalcule
        local a = l.pts[corner - 1]
        local tol = c.risky and DEVIATE_RISKY or DEVIATE
        if a and a.c == p.c and Nav.SegDist(p, a, c) > tol and GetTime() - lastPlan > 4 then
            M:Replan(ns.Tr("écart"))
        end
    else
        -- transport : arrivé à destination (ou changement de continent) -> étape suivante
        if (l.to.c == p.c and Nav.Dist(l.to, p) <= ARRIVE_TRANSPORT) or (l.from.c ~= p.c and l.to.c == p.c) then
            leg, corner = leg + 1, 2
            drive()
            M:Render()
        end
    end
end

function M:Tick()
    if not self.enabled then return end
    if self:Opt("learn") then Nav.Net.Sample() end
    if not journey or UnitOnTaxi("player") then return end
    local p = Nav.Player()
    if not p then return end
    advance(p)
    if not journey.legs[leg] then journey = nil; self:Render() end
end

---------------------------------------------------------------------------
-- Affichage : détail du trajet dans le guide
---------------------------------------------------------------------------
local function fmtTime(s)
    if s < 60 then return ("%d s"):format(math.max(1, math.floor(s))) end
    return ("%d min"):format(math.floor(s / 60 + 0.5))
end
local function dot(c)
    return ("|T%sdot:10:10:0:0:32:32:0:32:0:32:%d:%d:%d|t"):format(ns.MEDIA,
        math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255))
end

function M:Render()
    -- version du trajet : la carte ne recalcule son tracé que quand elle change
    self.version = (self.version or 0) + 1
    ns.Fire("FP_JOURNEY_CHANGED")
    if not ns.Guide then return end
    if not (self.enabled and self:Opt("card") and journey) then
        ns.Guide:SetSection("journey", 5, nil)
        return
    end
    local lines = { (ns.Tr("|cffffd100Itinéraire|r  ~%s")):format(fmtTime(journey.total)) }
    if external and self:Opt("yield") then
        lines[#lines + 1] = ns.Tr("|cff888888Un autre addon guide le point (Naowh ?)|r")
    end
    -- long trajet à pied sans aucun vol enregistré : les vols ne sont connus qu'après avoir
    -- ouvert la carte d'un maître de vol avec ce personnage
    if self:Opt("flights") and journey.total > 300 and #Nav.Transport.Flights() == 0 then
        lines[#lines + 1] = ns.Tr("|cff888888Aucun vol enregistré : ouvre la carte d'un maître de vol pour que l'itinéraire les utilise.|r")
    end
    for i = leg, math.min(#journey.legs, leg + 3) do
        local l = journey.legs[i]
        local col, text
        if l.mode == "walk" then
            local risky = false
            for _, p in ipairs(l.pts) do if p.risky then risky = true end end
            col = risky and M.COLORS.risky or M.COLORS.known
            text = LABEL.walk .. (risky and ns.Tr(" |cff999999(en partie inconnu)|r") or "")
        else
            col = M.COLORS[l.mode] or M.COLORS.known
            text = LABEL[l.mode] .. (l.toName and (" vers " .. l.toName) or "")
        end
        local cur = i == leg and "|cffffffff" or "|cffaaaaaa"
        lines[#lines + 1] = ("%s %s%s|r  |cff888888%s|r"):format(dot(col), cur, text, fmtTime(l.time))
    end
    ns.Guide:SetSection("journey", 5, table.concat(lines, "\n"))
end

-- Polylignes à dessiner (monde) : { pts = { {c,x,y} }, color }
function M:Polylines()
    if not (self.enabled and journey) then return {} end
    local out = {}
    local p = Nav.Player()
    for i = leg, #journey.legs do
        local l = journey.legs[i]
        if l.mode == "walk" then
            local startIdx = i == leg and corner or 2
            local prev = (i == leg and p) or l.pts[startIdx - 1]
            for j = startIdx, #l.pts do
                local q = l.pts[j]
                if prev then
                    out[#out + 1] = { pts = { prev, q }, head = prev == p or nil,
                        color = q.risky and M.COLORS.risky or q.terrain and M.COLORS.terrain or M.COLORS.known }
                end
                prev = q
            end
        elseif l.mode ~= "hearth" then
            out[#out + 1] = { pts = { l.from, l.to }, color = M.COLORS[l.mode] or M.COLORS.known }
        end
    end
    return out
end

function M:Journey() return journey, leg, corner end

---------------------------------------------------------------------------
-- Tracé sur la minimap
---------------------------------------------------------------------------
local MINIMAP_YARDS = {
    outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
    indoor = { [0] = 300, 240, 180, 120, 80, 50 },
}
local mm = { dots = {} }

local function minimapDot(i)
    local d = mm.dots[i]
    if not d then
        d = Minimap:CreateTexture(nil, "OVERLAY")
        d:SetTexture(ns.MEDIA .. "dot")
        d:SetSize(5, 5)
        mm.dots[i] = d
    end
    return d
end

-- Position (px) sur la minimap d'un point monde, relativement au joueur
function M.MinimapOffset(p, player, zoom, indoor, rotate, facing, radiusPx)
    local yards = (indoor and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor)[zoom or 0] or 466
    local scale = radiusPx * 2 / yards
    -- monde : x = nord, y = ouest -> écran : droite = est, haut = nord
    local east, north = -(p.y - player.y), p.x - player.x
    if rotate and facing then
        local s, c = math.sin(facing), math.cos(facing)
        east, north = east * c - north * s, east * s + north * c
    end
    return east * scale, north * scale
end

local mmPt = {}         -- point courant du tracé (réutilisé : pas de table par point)
function M:DrawMinimap()
    for _, d in ipairs(mm.dots) do d:Hide() end
    if not (self.enabled and self:Opt("minimap") and journey and Minimap and Minimap:IsShown()) then return end
    local player = Nav.Player()
    if not player then return end
    local radius = Minimap:GetWidth() / 2
    local zoom = Minimap:GetZoom()
    local indoor = IsIndoors and IsIndoors() or false
    local rotate = GetCVar and GetCVar("rotateMinimap") == "1"
    local facing = rotate and GetPlayerFacing and GetPlayerFacing() or nil
    if facing and ns.IsSecret(facing) then return end
    local n = 0
    -- rayon visible de la minimap (en yards) : les tronçons plus loin sont ignorés d'emblée
    local yards = (indoor and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor)[zoom] or 466
    local reach = yards / 2 + 20
    for _, seg in ipairs(self:Polylines()) do
        local a, b = seg.pts[1], seg.pts[2]
        if a.c == player.c and b.c == player.c and Nav.SegDist(player, a, b) <= reach then
            local len = Nav.Dist(a, b)
            -- seulement la portion du tronçon proche du joueur
            local t0, t1 = 0, 1
            if len > reach * 2 then
                local proj = ((player.x - a.x) * (b.x - a.x) + (player.y - a.y) * (b.y - a.y)) / (len * len)
                t0, t1 = math.max(0, proj - reach / len), math.min(1, proj + reach / len)
            end
            local steps = math.max(1, math.floor(len * (t1 - t0) / 14))
            for k = 0, steps do
                local t = t0 + (t1 - t0) * k / steps
                mmPt.x, mmPt.y = a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t
                local ox, oy = M.MinimapOffset(mmPt, player, zoom, indoor, rotate, facing, radius)
                if ox * ox + oy * oy < (radius - 4) ^ 2 then
                    n = n + 1
                    if n > 250 then return end
                    local d = minimapDot(n)
                    d:ClearAllPoints()
                    d:SetPoint("CENTER", Minimap, "CENTER", ox, oy)
                    d:SetVertexColor(seg.color[1], seg.color[2], seg.color[3], 0.95)
                    d:Show()
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Événements
---------------------------------------------------------------------------
-- Tracé de la minimap : 10 fois/s (4 en économie), et seulement si le personnage a bougé, tourné
-- ou changé le zoom (jusqu'à 250 points à replacer à chaque fois).
local mmTicker = CreateFrame("Frame")
local acc, lastKey = 0, nil
mmTicker:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc < ((ns.Eco and ns.Eco()) and 0.25 or 0.1) then return end
    acc = 0
    if not (M.enabled and journey) then lastKey = nil return end
    local pl = Nav.Player()
    local facing = GetPlayerFacing and GetPlayerFacing()
    if facing and ns.IsSecret(facing) then facing = nil end
    local key = pl and ("%d:%d:%d:%s:%s:%d:%d"):format(pl.x or 0, pl.y or 0, pl.c or 0, Minimap and Minimap:GetZoom() or 0,
        facing and math.floor(facing * 50) or "-", leg or 0, corner or 0) or nil
    if key and key == lastKey and journey == M.drawnJourney then return end
    lastKey, M.drawnJourney = key, journey
    M:DrawMinimap()
end)

function M:OnEnable()
    Nav.Net.learning = self:Opt("learn")
    C_Timer.After(1, function() M:Replan(ns.Tr("début")) end)
end
function M:OnDisable()
    journey = nil
    self:Render()
    self:DrawMinimap()
    ns.Fire("FP_STEP_CHANGED", true)    -- le module Waypoint reprend la main
end
function M:OnOptionChanged(key)
    Nav.Net.learning = self:Opt("learn")
    if key ~= "learn" and key ~= "card" and key ~= "minimap" then self:Replan("option") else self:Render() end
end

local lastTargetKey
M:On("FP_STEP_CHANGED", function()
    local step = ns.Engine.NavStep()
    local key = step and (tostring(step.map) .. step.x .. ":" .. step.y) or "none"
    if key ~= lastTargetKey then
        lastTargetKey = key
        external = false
        M:Replan(ns.Tr("étape"))
        fire("DestinationChanged", QuestweaverAPI.GetDestination())
    end
end)
M:On("FP_TICK", function() M:Tick() end)
M:On("PLAYER_ENTERING_WORLD", function() Nav.Net.Break(); C_Timer.After(2, function() M:Replan("chargement") end) end)
M:On("PLAYER_REGEN_ENABLED", function() if GetTime() - lastPlan > 3 then M:Replan(ns.Tr("fin de combat")) end end)
M:On("PLAYER_CONTROL_GAINED", function() Nav.Net.Break(); C_Timer.After(1, function() M:Replan("atterrissage") end) end)
M:On("PLAYER_DEAD", function() Nav.Net.Break() end)
M:On("FP_NAV_CHANGED", function() if GetTime() - lastPlan > 2 then M:Replan(ns.Tr("nouveau transport")) end end)
-- Daylight UI (module Quêtes, « Route ») épingle le point de la quête suivie et dessine ses
-- points bleus vers lui, en ligne droite. On reprend le point pour le poser virage par virage :
-- ses points bleus suivent alors notre itinéraire. Daylight UI laisse ensuite le point tranquille
-- (il ne touche pas aux points posés par d'autres). Garde-fou : si le point nous est repris plus
-- de 3 fois en 30 s, on laisse faire pour ne pas se le disputer.
local function daylightPins()
    if not M:Opt("overDaylight") then return false end
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
    if not (loaded and loaded("DaylightUI_Quests")) then return false end
    -- avec un autre guide installé, on ne sait pas qui a posé le point : on garde la règle normale
    for _, other in ipairs({ "NaowhForever_Utilities", "Zygor Guides Viewer" }) do
        if loaded(other) then return false end
    end
    return true
end
local retakes = {}
local function mayRetake()
    local now = GetTime()
    while retakes[1] and now - retakes[1] > 30 do table.remove(retakes, 1) end
    if #retakes >= 3 then return false end
    retakes[#retakes + 1] = now
    return true
end
M.daylightRetakes = retakes

M:On("USER_WAYPOINT_UPDATED", function()
    if ns.Waypoint and ns.Waypoint.placing then return end
    if not C_Map.HasUserWaypoint() then return end
    if journey and M:Opt("corners") and daylightPins() and mayRetake() then
        -- on remet notre virage au prochain affichage (pas dans l'événement lui-même)
        C_Timer.After(0.2, function() external = false; drive(); M:Render() end)
        return
    end
    -- un autre addon a posé son propre point (ex. Naowh Journeys)
    external = true; M:Render()
end)

function M.preview(p)
    local bg = p:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.33, 0.27, 0.16, 1)
    local pts = { { 18, 72 }, { 40, 60 }, { 52, 38 }, { 80, 30 }, { 132, 20 } }
    local cols = { M.COLORS.known, M.COLORS.known, M.COLORS.risky, M.COLORS.flight }
    for k = 2, #pts do
        local a, b, c = pts[k - 1], pts[k], cols[k - 1]
        for t = 1, 6 do
            local d = p:CreateTexture(nil, "ARTWORK")
            d:SetTexture(ns.MEDIA .. "dot")
            d:SetSize(4, 4)
            local f = t / 7
            d:SetPoint("CENTER", p, "TOPLEFT", a[1] + (b[1] - a[1]) * f, -(a[2] + (b[2] - a[2]) * f))
            d:SetVertexColor(c[1], c[2], c[3])
        end
    end
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("BOTTOMRIGHT", -4, 4)
    fs:SetJustifyH("RIGHT")
    fs:SetText("|cff4de65aconnu|r  |cffff8c26inconnu|r  |cff59b3ffvol|r")
end
