local _, ns = ...
local L = ns.L

SLASH_QUESTWEAVER1 = "/qw"
SLASH_QUESTWEAVER2 = "/questweaver"

-- Raccourcis clavier (Bindings.xml)
BINDING_HEADER_QUESTWEAVER = "Questweaver"
BINDING_NAME_QUESTWEAVER_NEXT = ns.Tr("Étape suivante")
BINDING_NAME_QUESTWEAVER_PREV = ns.Tr("Étape précédente")
BINDING_NAME_QUESTWEAVER_TOGGLE = ns.Tr("Afficher / masquer le guide")
BINDING_NAME_CLICK_QuestweaverTargetButton_LeftButton = ns.Tr("Cibler le PNJ / monstre de l'étape")
BINDING_NAME_CLICK_QuestweaverQuestItemButton_LeftButton = ns.Tr("Utiliser l'objet de quête")

SlashCmdList.QUESTWEAVER = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    local ext = ns.SlashExt and ns.SlashExt[cmd]
    if ext then return ext(arg) end
    if cmd == "" then
        if ns.Guide.enabled then ns.Guide:Toggle() else ns.SetModuleEnabled("guide", true) end
    elseif cmd == "config" or cmd == "options" then
        ns.Options:Toggle()
    elseif cmd == "next" or cmd == "skip" then
        ns.Engine.Next()
    elseif cmd == "prev" then
        ns.Engine.Prev()
    elseif cmd == "zones" or (cmd == "zone" and (arg or "") == "") then
        ns.ZonePanel:Toggle()
    elseif cmd == "zone" then
        -- /qw zone <nom ou clé> : suivre la route dans cette zone
        local want = arg:lower()
        for _, sg in ipairs(ns.Recommend.Segments(nil)) do
            local name = sg.zone and ns.ZoneName(sg.zone):lower() or ""
            if sg.key == want or name:find(want, 1, true) then ns.Recommend.Choose(sg.guide) return end
        end
        ns.Print(ns.Tr("Pas de segment de ta route dans « %s » à ton niveau. /qw zones pour la liste."), arg)
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
        ns.Print(ns.Tr("Fenêtres %s"), ns.db.locked and ns.Tr("verrouillées") or ns.Tr("déverrouillées"))
    elseif cmd == "reset" then
        local id = ns.cdb.guideId
        if id then ns.cdb.skipped[id] = {}; ns.Engine.Load(id) end
    elseif cmd == "paths" then
        local Net = ns.Nav and ns.Nav.Net
        if not (Net and ns.Nav.db) then return end
        if arg == "export" then
            ns.ShowExport(Net.Export(), ns.Tr("Chemins appris (Ctrl+A, Ctrl+C) — à partager"))
        elseif arg == "import" then
            ns.ShowImport(ns.Tr("Colle des chemins partagés (FPN1...) puis Importer"), function(text)
                local ok, res = Net.Import(text)
                if ok then ns.Print(ns.Tr("%d nouveaux points de chemin importés."), res)
                else ns.Print(ns.Tr("Import impossible : %s"), tostring(res)) end
                if ns.Journeys then ns.Journeys:Replan("import") end
            end)
        elseif arg == "reset" then
            Net.Reset()
            ns.Print(ns.Tr("Chemins appris effacés."))
        elseif arg == "here" then
            local p = ns.Nav.Player()
            if p then
                ns.Print(ns.Tr("%d liaisons oubliées autour de toi (40 m)."), Net.Forget(p.c, p.x, p.y, 40))
                if ns.Journeys then ns.Journeys:Replan("oubli") end
            end
        else
            local nodes, edges, conts = Net.Stats()
            local flights = #ns.Nav.Transport.Flights()
            ns.Print(ns.Tr("Chemins appris : %d points, %d liaisons, %d continent(s). Vols connus : %d. Foyer : %s."),
                nodes, edges, conts, flights, ns.Nav.char and ns.Nav.char.hearth and "connu" or ns.Tr("à apprendre"))
            ns.Print(ns.Tr("/qw paths export | import | here (oublier autour de moi) | reset"))
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
                ns.Daylight.registered and ns.Tr("enregistré") or ns.Tr("non enregistré"),
                ns.Daylight.lastError and (" (" .. tostring(ns.Daylight.lastError) .. ")") or "")
        end
        local id = ns.NpcIDFromUnit("target")
        if id then ns.Print("cible npcID=%d", id) end
    else
        for _, line in ipairs(L.HELP) do ns.Print(line) end
    end
end

function Questweaver_Next() ns.Engine.Next() end
function Questweaver_Prev() ns.Engine.Prev() end
function Questweaver_Toggle() SlashCmdList.QUESTWEAVER("") end
