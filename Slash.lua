local _, ns = ...
local L = ns.L

SLASH_FOREVERPATH1 = "/fp"
SLASH_FOREVERPATH2 = "/foreverpath"

-- Raccourcis clavier (Bindings.xml)
BINDING_HEADER_FOREVERPATH = "ForeverPath"
BINDING_NAME_FOREVERPATH_NEXT = "Étape suivante"
BINDING_NAME_FOREVERPATH_PREV = "Étape précédente"
BINDING_NAME_FOREVERPATH_TOGGLE = "Afficher / masquer le guide"
BINDING_NAME_CLICK_ForeverPathTargetButton_LeftButton = "Cibler le PNJ / monstre de l'étape"
BINDING_NAME_CLICK_ForeverPathQuestItemButton_LeftButton = "Utiliser l'objet de quête"

SlashCmdList.FOREVERPATH = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" then
        if ns.Guide.enabled then ns.Guide:Toggle() else ns.SetModuleEnabled("guide", true) end
    elseif cmd == "config" or cmd == "options" then
        ns.Options:Toggle()
    elseif cmd == "next" or cmd == "skip" then
        ns.Engine.Next()
    elseif cmd == "prev" then
        ns.Engine.Prev()
    elseif cmd == "zones" then
        ns.ZonePanel:Toggle()
    elseif cmd == "guides" then
        for _, id in ipairs(ns.GuideOrder) do
            local g = ns.Guides[id]
            if not g.faction or g.faction == ns.PlayerFaction() then
                ns.Print("|cffffd100%s|r — %s", id, g.name)
            end
        end
    elseif cmd == "load" then
        ns.Engine.Load(arg)
    elseif cmd == "auto" then
        ns.cdb.path = nil
        local id = ns.Engine.PickDefault()
        if id then ns.Engine.Load(id) end
    elseif cmd == "rec" then
        if arg == "on" then ns.Recorder.Set(true)
        elseif arg == "off" then ns.Recorder.Set(false)
        elseif arg == "clear" then ns.Recorder.Clear()
        else ns.Recorder.Set(not ns.Recorder.IsOn()) end
        ns.Recorder:Paint()
    elseif cmd == "note" then
        ns.Recorder.Note(arg)
    elseif cmd == "export" then
        ns.ShowExport(ns.Recorder.Export())
    elseif cmd == "lock" then
        ns.db.locked = not ns.db.locked
        ns.Print("Fenêtres %s", ns.db.locked and "verrouillées" or "déverrouillées")
    elseif cmd == "reset" then
        local id = ns.cdb.guideId
        if id then ns.cdb.skipped[id] = {}; ns.Engine.Load(id) end
    elseif cmd == "paths" then
        local Net = ns.Nav and ns.Nav.Net
        if not (Net and ns.Nav.db) then return end
        if arg == "export" then
            ns.ShowExport(Net.Export(), "Chemins appris (Ctrl+A, Ctrl+C) — à partager")
        elseif arg == "import" then
            ns.ShowImport("Colle des chemins partagés (FPN1...) puis Importer", function(text)
                local ok, res = Net.Import(text)
                if ok then ns.Print("%d nouveaux points de chemin importés.", res)
                else ns.Print("Import impossible : %s", tostring(res)) end
                if ns.Journeys then ns.Journeys:Replan("import") end
            end)
        elseif arg == "reset" then
            Net.Reset()
            ns.Print("Chemins appris effacés.")
        elseif arg == "here" then
            local p = ns.Nav.Player()
            if p then
                ns.Print("%d liaisons oubliées autour de toi (40 m).", Net.Forget(p.c, p.x, p.y, 40))
                if ns.Journeys then ns.Journeys:Replan("oubli") end
            end
        else
            local nodes, edges, conts = Net.Stats()
            local flights = #ns.Nav.Transport.Flights()
            ns.Print("Chemins appris : %d points, %d liaisons, %d continent(s). Vols connus : %d. Foyer : %s.",
                nodes, edges, conts, flights, ns.Nav.char and ns.Nav.char.hearth and "connu" or "à apprendre")
            ns.Print("/fp paths export | import | here (oublier autour de moi) | reset")
        end
    elseif cmd == "where" then
        local mapID, x, y = ns.PlayerMapPos()
        local info = mapID and C_Map.GetMapInfo(mapID)
        local z = ns.CurrentZone()
        ns.Print("mapID=%s (%s) x=%.1f y=%.1f zone=%s interface=%s cartes=%s", tostring(mapID),
            info and info.name or "?", (x or 0) * 100, (y or 0) * 100, z and z.key or "?",
            tostring((select(4, GetBuildInfo()))), tostring(ns.resolvedMaps))
        if type(DaylightUI) == "table" then
            local a = type(DaylightUI.API) == "table" and DaylightUI.API
            ns.Print("Daylight UI : API %s.%s, plugin %s%s", tostring(a and a.major), tostring(a and a.minor),
                ns.Daylight.registered and "enregistré" or "non enregistré",
                ns.Daylight.lastError and (" (" .. tostring(ns.Daylight.lastError) .. ")") or "")
        end
        local id = ns.NpcIDFromUnit("target")
        if id then ns.Print("cible npcID=%d", id) end
    else
        for _, line in ipairs(L.HELP) do ns.Print(line) end
    end
end

function ForeverPath_Next() ns.Engine.Next() end
function ForeverPath_Prev() ns.Engine.Prev() end
function ForeverPath_Toggle() SlashCmdList.FOREVERPATH("") end
