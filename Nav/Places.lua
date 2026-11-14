local _, ns = ...
local Nav = ns.Nav

-- Lieux utiles tirés de Data/World.lua (maîtres de classe, aubergistes) : recherche du plus proche
-- et détour vers lui (la flèche, le guidage 3D et l'itinéraire suivent le détour).
local P = {}
Nav.Places = P

local function faction(f)
    return f == "both" or f == ns.PlayerFaction()
end

-- list : entrées { map, x, y, name, ... } ; renvoie l'entrée la plus proche et sa distance (yards)
function P.Nearest(list, accept)
    local me = Nav.Player()
    local best, bestD
    for _, e in ipairs(list) do
        if not accept or accept(e) then
            local d
            local c, wx, wy = Nav.ToWorld(e.map, e.x / 100, e.y / 100)
            if me and c then
                d = c == me.c and Nav.Dist(me, { x = wx, y = wy }) or 1e6 + Nav.Dist(me, { x = 0, y = 0 })
            else
                d = (me and e.map == me.map) and 0 or 1e7
            end
            if not bestD or d < bestD then best, bestD = e, d end
        end
    end
    return best, bestD
end

local trainers, inns
function P.Trainers()
    if not trainers then
        trainers = {}
        for _, t in ipairs(ns.World and ns.World.trainers or {}) do
            trainers[#trainers + 1] = { class = t[1], npc = t[2], map = t[3], x = t[4], y = t[5], faction = t[6], name = t[7] }
        end
    end
    return trainers
end
function P.Inns()
    if not inns then
        inns = {}
        for _, t in ipairs(ns.World and ns.World.inns or {}) do
            inns[#inns + 1] = { npc = t[1], map = t[2], x = t[3], y = t[4], faction = t[5], name = t[6] }
        end
    end
    return inns
end

function P.NearestTrainer()
    local _, cls = UnitClass("player")
    return P.Nearest(P.Trainers(), function(e) return e.class == cls and faction(e.faction) end)
end
function P.NearestInn()
    return P.Nearest(P.Inns(), function(e) return faction(e.faction) end)
end

function P.ZoneName(map)
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(map)
    return info and info.name or ""
end

-- Détour vers une entrée (texte affiché dans le guide)
function P.Go(e, text, icon, kind)
    if not e then return end
    ns.Engine.SetDetour({ map = e.map, x = e.x, y = e.y, text = text or e.name, icon = icon, npcID = e.npc, radius = 10, kind = kind })
end
