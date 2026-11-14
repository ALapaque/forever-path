local _, ns = ...

-- Zones de leveling WoW Forever.
-- faction : "Alliance" | "Horde" | "Contested"
-- mapID   : uiMapID Classic, à vérifier en jeu avec /fp where (remplacer si différent).
-- start   : races (raceFile) dont c'est la zone de départ.
-- unconfirmed : niveaux non annoncés officiellement par Blizzard.
ns.Zones = {
    -- 1-10 : zones de départ
    { key = "elwynn",     fr = "Forêt d'Elwynn",            en = "Elwynn Forest",          min = 1,  max = 10, faction = "Alliance",  cont = "EK", mapID = 1429, start = { Human = true } },
    { key = "dunmorogh",  fr = "Dun Morogh",                en = "Dun Morogh",             min = 1,  max = 10, faction = "Alliance",  cont = "EK", mapID = 1426, start = { Dwarf = true, Gnome = true } },
    { key = "teldrassil", fr = "Teldrassil",                en = "Teldrassil",             min = 1,  max = 10, faction = "Alliance",  cont = "KA", mapID = 1438, start = { NightElf = true } },
    { key = "durotar",    fr = "Durotar",                   en = "Durotar",                min = 1,  max = 10, faction = "Horde",     cont = "KA", mapID = 1411, start = { Orc = true, Troll = true } },
    { key = "mulgore",    fr = "Mulgore",                   en = "Mulgore",                min = 1,  max = 10, faction = "Horde",     cont = "KA", mapID = 1412, start = { Tauren = true } },
    { key = "tirisfal",   fr = "Clairières de Tirisfal",    en = "Tirisfal Glades",        min = 1,  max = 10, faction = "Horde",     cont = "EK", mapID = 1420, start = { Scourge = true } },
    { key = "zephras",    fr = "Île de Zéphras",            en = "Zephras Isle",           min = 1,  max = 12, faction = "Contested", cont = "IS", mapID = nil,  start = { Skyborne = true }, new = true, note = "Éolides uniquement" },

    -- 10-20
    { key = "westfall",   fr = "Marche de l'Ouest",         en = "Westfall",               min = 10, max = 20, faction = "Alliance",  cont = "EK", mapID = 1436 },
    { key = "lochmodan",  fr = "Loch Modan",                en = "Loch Modan",             min = 10, max = 20, faction = "Alliance",  cont = "EK", mapID = 1432 },
    { key = "darkshore",  fr = "Sombrivage",                en = "Darkshore",              min = 11, max = 19, faction = "Alliance",  cont = "KA", mapID = 1439 },
    { key = "barrens",    fr = "Les Tarides",               en = "The Barrens",            min = 10, max = 25, faction = "Horde",     cont = "KA", mapID = 1413 },
    { key = "silverpine", fr = "Forêt des Pins-Argentés",   en = "Silverpine Forest",      min = 10, max = 20, faction = "Horde",     cont = "EK", mapID = 1421 },
    { key = "redridge",   fr = "Les Carmines",              en = "Redridge Mountains",     min = 15, max = 25, faction = "Contested", cont = "EK", mapID = 1433 },
    { key = "stonetalon", fr = "Les Serres-Rocheuses",      en = "Stonetalon Mountains",   min = 15, max = 25, faction = "Contested", cont = "KA", mapID = 1442 },

    -- 20-30
    { key = "ashenvale",  fr = "Orneval",                   en = "Ashenvale",              min = 19, max = 30, faction = "Contested", cont = "KA", mapID = 1440 },
    { key = "duskwood",   fr = "Bois de la Pénombre",       en = "Duskwood",               min = 18, max = 30, faction = "Alliance",  cont = "EK", mapID = 1431 },
    { key = "wetlands",   fr = "Les Paluns",                en = "Wetlands",               min = 20, max = 30, faction = "Alliance",  cont = "EK", mapID = 1437 },
    { key = "hillsbrad",  fr = "Contreforts de Hautebrande", en = "Hillsbrad Foothills",   min = 20, max = 30, faction = "Contested", cont = "EK", mapID = 1424 },
    { key = "needles",    fr = "Mille pointes",             en = "Thousand Needles",       min = 24, max = 35, faction = "Contested", cont = "KA", mapID = 1441 },

    -- 30-40
    { key = "alterac",    fr = "Montagnes d'Alterac",       en = "Alterac Mountains",      min = 30, max = 40, faction = "Contested", cont = "EK", mapID = 1416 },
    { key = "arathi",     fr = "Hautes-terres d'Arathi",    en = "Arathi Highlands",       min = 30, max = 40, faction = "Contested", cont = "EK", mapID = 1417 },
    { key = "desolace",   fr = "Désolace",                  en = "Desolace",               min = 30, max = 40, faction = "Contested", cont = "KA", mapID = 1443 },
    { key = "stv",        fr = "Vallée de Strangleronce",   en = "Stranglethorn Vale",     min = 30, max = 45, faction = "Contested", cont = "EK", mapID = 1434 },
    { key = "dustwallow", fr = "Marécage d'Âprefange",      en = "Dustwallow Marsh",       min = 35, max = 45, faction = "Contested", cont = "KA", mapID = 1445 },
    { key = "badlands",   fr = "Terres ingrates",           en = "Badlands",               min = 35, max = 45, faction = "Contested", cont = "EK", mapID = 1418 },
    { key = "swamp",      fr = "Marais des Chagrins",       en = "Swamp of Sorrows",       min = 35, max = 45, faction = "Contested", cont = "EK", mapID = 1435 },
    { key = "riverglades", fr = "Rives Claires",            en = "The Riverglades",        min = 36, max = 44, faction = "Contested", cont = "EK", mapID = nil, new = true, note = "Accès : Col de Rochenoire (Carmines) ou bateau Tanaris → Port-Poudrefuse" },
    { key = "shendralas", fr = "Shen'dralas",               en = "Shen'dralas",            min = 30, max = 42, faction = "Contested", cont = "KA", mapID = nil, new = true, unconfirmed = true, note = "Accès : Vallée des Ossements, sud de Désolace" },

    -- 40-50
    { key = "feralas",    fr = "Féralas",                   en = "Feralas",                min = 40, max = 50, faction = "Contested", cont = "KA", mapID = 1444 },
    { key = "tanaris",    fr = "Tanaris",                   en = "Tanaris",                min = 40, max = 50, faction = "Contested", cont = "KA", mapID = 1446 },
    { key = "hinterlands", fr = "Les Hinterlands",          en = "The Hinterlands",        min = 40, max = 50, faction = "Contested", cont = "EK", mapID = 1425 },
    { key = "searing",    fr = "Gorge des Vents brûlants",  en = "Searing Gorge",          min = 43, max = 50, faction = "Contested", cont = "EK", mapID = 1427 },

    -- 45-60
    { key = "azshara",    fr = "Azshara",                   en = "Azshara",                min = 45, max = 55, faction = "Contested", cont = "KA", mapID = 1447 },
    { key = "blasted",    fr = "Terres foudroyées",         en = "Blasted Lands",          min = 45, max = 55, faction = "Contested", cont = "EK", mapID = 1419 },
    { key = "ungoro",     fr = "Cratère d'Un'Goro",         en = "Un'Goro Crater",         min = 48, max = 55, faction = "Contested", cont = "KA", mapID = 1449 },
    { key = "felwood",    fr = "Gangrebois",                en = "Felwood",                min = 48, max = 55, faction = "Contested", cont = "KA", mapID = 1448 },
    { key = "burning",    fr = "Steppes ardentes",          en = "Burning Steppes",        min = 50, max = 58, faction = "Contested", cont = "EK", mapID = 1428 },
    { key = "wpl",        fr = "Maleterres de l'Ouest",     en = "Western Plaguelands",    min = 51, max = 58, faction = "Contested", cont = "EK", mapID = 1422 },
    { key = "epl",        fr = "Maleterres de l'Est",       en = "Eastern Plaguelands",    min = 53, max = 60, faction = "Contested", cont = "EK", mapID = 1423 },
    { key = "winterspring", fr = "Berceau-de-l'Hiver",      en = "Winterspring",           min = 53, max = 60, faction = "Contested", cont = "KA", mapID = 1452 },
    { key = "silithus",   fr = "Silithus",                  en = "Silithus",               min = 55, max = 60, faction = "Contested", cont = "KA", mapID = 1451 },
    { key = "hyjal",      fr = "Mont Hyjal",                en = "Mount Hyjal",            min = 55, max = 60, faction = "Contested", cont = "KA", mapID = nil, new = true, unconfirmed = true, note = "Zone de leveling de fin de parcours" },
}

-- Les 9 nouveaux donjons de Forever (niveaux annoncés).
ns.Dungeons = {
    { fr = "La salle des Thanes",       en = "Hall of Thanes",          min = 13, max = 18 },
    { fr = "Ruines de Lordaeron",       en = "Ruins of Lordaeron",      min = 15, max = 20 },
    { fr = "Excavations : les Paluns",  en = "Excavation Site: Wetlands", min = 24, max = 29 },
    { fr = "Cité de Dalaran",           en = "City of Dalaran",         min = 28, max = 33, note = "Horde attaquée à vue dans Dalaran, donjon accessible" },
    { fr = "La Cité engloutie",         en = "The Drowned City",        min = 35, max = 40 },
    { fr = "Bastion de Krol'dok",       en = "Krol'dok Stronghold",     min = 40, max = 45 },
    { fr = "Prison d'Alcaz",            en = "Alcaz Prison",            min = 48, max = 53 },
    { fr = "Fort de Gueule-Noire",      en = "Blackmaw Hold",           min = 55, max = 60 },
    { fr = "Terrasse du Façonneur",     en = "Shaper's Terrace",        min = 58, max = 60 },
}

-- Capitales (pour les étapes de route, pas recommandées comme zones de leveling)
ns.Cities = {
    { key = "stormwind",   fr = "Hurlevent",       en = "Stormwind City", mapID = 1453, faction = "Alliance", city = true },
    { key = "ironforge",   fr = "Forgefer",        en = "Ironforge",      mapID = 1455, faction = "Alliance", city = true },
    { key = "darnassus",   fr = "Darnassus",       en = "Darnassus",      mapID = 1457, faction = "Alliance", city = true },
    { key = "orgrimmar",   fr = "Orgrimmar",       en = "Orgrimmar",      mapID = 1454, faction = "Horde",    city = true },
    { key = "thunderbluff", fr = "Les Pitons-du-Tonnerre", en = "Thunder Bluff", mapID = 1456, faction = "Horde", city = true },
    { key = "undercity",   fr = "Fossoyeuse",      en = "Undercity",      mapID = 1458, faction = "Horde",    city = true },
}

ns.ZoneByKey, ns.ZoneByMap = {}, {}
local function index(z)
    ns.ZoneByKey[z.key] = z
    if z.mapID then ns.ZoneByMap[z.mapID] = z end
end
for _, z in ipairs(ns.Zones) do index(z) end
for _, z in ipairs(ns.Cities) do index(z) end

function ns.ZoneName(z)
    return ns.isFrench and z.fr or z.en
end

local function norm(s) return s and s:lower():gsub("^%s+", ""):gsub("%s+$", "") end

-- Les uiMapID du client Forever ne sont pas garantis identiques à Classic :
-- au login, on parcourt les cartes du client et on associe chaque zone par son nom.
function ns.ResolveMaps()
    if not (C_Map and C_Map.GetMapInfo) then return end
    local byName = {}
    for _, list in ipairs({ ns.Zones, ns.Cities }) do
        for _, z in ipairs(list) do
            byName[norm(z.fr)] = z
            byName[norm(z.en)] = z
        end
    end
    local found = 0
    for id = 1, 3000 do
        local info = C_Map.GetMapInfo(id)
        if info and info.name and info.mapType == Enum.UIMapType.Zone then
            local z = byName[norm(info.name)]
            if z and not z._resolved then
                z.mapID, z._resolved = id, true
                ns.ZoneByMap[id] = z
                found = found + 1
            end
        end
    end
    ns.resolvedMaps = found
end

-- "elwynn" ou 1429 -> uiMapID
function ns.MapFor(keyOrID)
    if type(keyOrID) == "number" then return keyOrID end
    local z = keyOrID and ns.ZoneByKey[keyOrID]
    return z and z.mapID
end

-- Zone actuelle du joueur (remonte des sous-zones vers la zone)
function ns.CurrentZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local info = C_Map.GetMapInfo(mapID)
    while info and info.mapType and info.mapType > Enum.UIMapType.Zone and info.parentMapID do
        mapID = info.parentMapID
        info = C_Map.GetMapInfo(mapID)
    end
    if ns.ZoneByMap[mapID] then return ns.ZoneByMap[mapID], mapID end
    local name = info and norm(info.name)
    if name then
        for _, list in ipairs({ ns.Zones, ns.Cities }) do
            for _, z in ipairs(list) do
                if norm(z.fr) == name or norm(z.en) == name then
                    z.mapID = mapID
                    ns.ZoneByMap[mapID] = z
                    return z, mapID
                end
            end
        end
    end
    return nil, mapID
end
