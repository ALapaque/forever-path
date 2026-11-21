local _, ns = ...
local Nav = ns.Nav

-- Transports : vols (appris chez les maîtres de vol), bateaux / zeppelins / tram (table statique,
-- positions estimées sur les quais), pierre de foyer (position apprise à l'arrivée).
local T = {}
Nav.Transport = T

---------------------------------------------------------------------------
-- Bateaux, zeppelins, tram — positions approximatives des quais (cartes Classic).
-- faction : nil = tout le monde. wait = attente moyenne, ride = durée du trajet (s).
---------------------------------------------------------------------------
T.LINKS = {
    { kind = "boat", a = { "wetlands", 4.9, 57.2, "Menethil" }, b = { "dustwallow", 71.6, 56.4, "Theramore" }, wait = 60, ride = 80 },
    { kind = "boat", a = { "wetlands", 4.6, 63.4, "Menethil" }, b = { "darkshore", 32.4, 43.8, "Auberdine" }, wait = 60, ride = 80 },
    { kind = "boat", a = { "darkshore", 33.2, 40.0, "Auberdine" }, b = { "teldrassil", 54.9, 96.8, "Rut'theran" }, wait = 50, ride = 50, faction = "Alliance" },
    { kind = "boat", a = { "stv", 25.9, 73.1, ns.Tr("Baie-du-Butin") }, b = { "barrens", 63.6, 38.6, "Cabestan" }, wait = 60, ride = 80 },
    { kind = "zeppelin", a = { "durotar", 50.8, 13.7, "Orgrimmar" }, b = { "tirisfal", 60.7, 58.8, "Fossoyeuse" }, wait = 60, ride = 90, faction = "Horde" },
    { kind = "zeppelin", a = { "durotar", 50.6, 12.6, "Orgrimmar" }, b = { "stv", 31.6, 29.1, "Grom'gol" }, wait = 60, ride = 90, faction = "Horde" },
    { kind = "zeppelin", a = { "tirisfal", 61.9, 59.0, "Fossoyeuse" }, b = { "stv", 31.4, 30.2, "Grom'gol" }, wait = 60, ride = 90, faction = "Horde" },
    -- WoW Forever : bateau gobelin neutre Tanaris <-> Rives Claires (quais relevés en jeu)
    { kind = "boat", a = { "tanaris", 68.6, 23.0, ns.Tr("Port de Gentepression") }, b = { "riverglades", 80.6, 54.6, ns.Tr("Port de Poudremèche") }, wait = 60, ride = 90 },
    { kind = "tram", a = { "stormwind", 69.9, 31.0, "Hurlevent" }, b = { "ironforge", 76.6, 51.2, "Forgefer" }, wait = 20, ride = 60, faction = "Alliance" },
}

local resolved
local function endpoint(e)
    local map = ns.MapFor(e[1])
    if not map then return end
    local cont, wx, wy = Nav.ToWorld(map, e[2] / 100, e[3] / 100)
    if not cont then return end
    return { c = cont, x = wx, y = wy, map = map, mx = e[2] / 100, my = e[3] / 100, name = e[4] }
end

function T.Links()
    if resolved then return resolved end
    resolved = {}
    local faction = ns.PlayerFaction()
    for _, l in ipairs(T.LINKS) do
        if not l.faction or l.faction == faction then
            local a, b = endpoint(l.a), endpoint(l.b)
            if a and b then
                resolved[#resolved + 1] = { kind = l.kind, a = a, b = b, cost = l.wait + l.ride }
            end
        end
    end
    return resolved
end
function T.Invalidate() resolved = nil end

---------------------------------------------------------------------------
-- Vols : appris en ouvrant la carte d'un maître de vol
---------------------------------------------------------------------------
local function faction() return ns.PlayerFaction() or "?" end

function T.Flights()
    local f = Nav.db and Nav.db.flights[faction()]
    local out = {}
    if not f then return out end
    for key, node in pairs(f) do
        if Nav.char.known[key] then out[#out + 1] = node end
    end
    return out
end

-- carte du continent du joueur (repli si la carte des vols n'a pas de position monde)
local function playerContinentMap()
    local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local info = mapID and C_Map.GetMapInfo(mapID)
    local guard = 10
    while info and guard > 0 do
        if info.mapType == (Enum.UIMapType and Enum.UIMapType.Continent or 2) then return mapID end
        if not info.parentMapID or info.parentMapID == 0 then return end
        mapID = info.parentMapID
        info = C_Map.GetMapInfo(mapID)
        guard = guard - 1
    end
end

local function learnTaxi()
    if not (C_TaxiMap and C_TaxiMap.GetAllTaxiNodes) then return end
    local mapID = (GetTaxiMapID and GetTaxiMapID()) or playerContinentMap()
    if not mapID then return end
    local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, mapID)
    if not ok or type(nodes) ~= "table" then return end
    Nav.db.flights[faction()] = Nav.db.flights[faction()] or {}
    local store = Nav.db.flights[faction()]
    local learned = 0
    local fallback = playerContinentMap()
    local current = (Enum.FlightPathState and Enum.FlightPathState.Current) or 0
    local here = Nav.Player()
    for _, n in ipairs(nodes) do
        local pos = n.position
        if pos and n.nodeID then
            local px, py
            if pos.GetXY then px, py = pos:GetXY() else px, py = pos.x, pos.y end
            local cont, wx, wy = Nav.ToWorld(mapID, px, py)
            if not cont and fallback and fallback ~= mapID then cont, wx, wy = Nav.ToWorld(fallback, px, py) end
            -- le point où l'on se trouve : la position du joueur est la plus sûre
            if n.state == current and here then cont, wx, wy = here.c, here.x, here.y end
            if cont then
                local key = tostring(n.nodeID)
                store[key] = { key = key, c = cont, x = wx, y = wy, name = n.name }
                -- état « Current » ou « Reachable » : ce point de vol est connu de ce personnage
                -- Enum.FlightPathState : Current = 0, Reachable = 1, Unreachable = 2
                local unreachable = (Enum.FlightPathState and Enum.FlightPathState.Unreachable) or 2
                if n.state ~= unreachable then
                    if not Nav.char.known[key] then learned = learned + 1 end
                    Nav.char.known[key] = true
                end
            end
        end
    end
    if learned > 0 then ns.Fire("FP_NAV_CHANGED") end
end
ns.On("TAXIMAP_OPENED", learnTaxi)

---------------------------------------------------------------------------
-- Pierre de foyer : on note où elle mène en l'utilisant
---------------------------------------------------------------------------
local HEARTH_ITEM, HEARTH_SPELL = 6948, 8690
local castAt

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
    if unit == "player" and spellID == HEARTH_SPELL then castAt = GetTime() end
end)

local function recordHearth()
    if not (castAt and GetTime() - castAt < 60) then return end
    castAt = nil
    C_Timer.After(2, function()
        local p = Nav.Player()
        if p and Nav.char then
            Nav.char.hearth = { c = p.c, x = p.x, y = p.y, bind = GetBindLocation and GetBindLocation() }
            ns.Fire("FP_NAV_CHANGED")
        end
    end)
end
ns.On("PLAYER_ENTERING_WORLD", recordHearth)
ns.On("ZONE_CHANGED_NEW_AREA", recordHearth)
ns.On("HEARTHSTONE_BOUND", function()
    if Nav.char then Nav.char.hearth = nil end      -- nouvelle auberge : position à réapprendre
end)

function T.Hearth()
    local h = Nav.char and Nav.char.hearth
    if not h then return end
    if h.bind and GetBindLocation and GetBindLocation() ~= h.bind then return end
    if C_Item and C_Item.GetItemCount and C_Item.GetItemCount(HEARTH_ITEM) == 0 then return end
    if C_Container and C_Container.GetItemCooldown then
        local start, dur = C_Container.GetItemCooldown(HEARTH_ITEM)
        if start and dur and start > 0 and dur > 2 then return end
    end
    return h
end

ns.On("PLAYER_ENTERING_WORLD", function() T.Invalidate() end)
