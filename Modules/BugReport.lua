local _, ns = ...

-- /fp bug : rapport prêt à coller (GitHub, Discord) avec la version, le client, le personnage,
-- l'étape, les modules et les dernières erreurs (ForeverPath et BugSack s'il est installé).
local M = {}
ns.BugReport = M

function M.Text()
    local lines = {}
    local function add(s) lines[#lines + 1] = s end
    local ver, build, _, iface = GetBuildInfo()
    local _, race = UnitRace("player")
    local _, class = UnitClass("player")
    add("ForeverPath " .. tostring(ns.VERSION))
    add(("Client %s (%s), interface %s, %s"):format(tostring(ver), tostring(build), tostring(iface), GetLocale and GetLocale() or "?"))
    add(("Perso : %s %s %s, niveau %d"):format(ns.PlayerFaction() or "?", race or "?", class or "?", ns.PlayerLevel()))
    local g, st, i = ns.Engine.Current()
    if g then
        add(("Guide : %s, étape %d/%d (%s%s)"):format(g.id, i, #g.steps, st and st.type or "?", st and st.quest and (" " .. st.quest) or ""))
    end
    local map, x, y = ns.PlayerMapPos()
    if map then add(("Position : carte %s, %.1f %.1f"):format(map, (x or 0) * 100, (y or 0) * 100)) end
    local on, off = {}, {}
    for _, id in ipairs(ns.ModuleOrder) do
        if ns.Modules[id].enabled then on[#on + 1] = id else off[#off + 1] = id end
    end
    add("Modules actifs : " .. table.concat(on, ", "))
    add("Modules coupés : " .. table.concat(off, ", "))
    add("Profil : " .. tostring(ns.db.profile or "-") .. ", thème : " .. tostring(ns.db.theme))
    local others = {}
    for _, name in ipairs({ "DaylightUI", "NaowhForever", "TomTom", "Pawn", "RXPGuides", "Questie", "ElvUI", "EllesmereUI" }) do
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(name)
        if loaded then others[#others + 1] = name end
    end
    add("Autres addons : " .. (#others > 0 and table.concat(others, ", ") or "-"))
    add("")
    add("Erreurs récentes :")
    local n = 0
    for _, e in ipairs(ns.errors or {}) do
        n = n + 1
        add(("[%s] %s"):format(e.time, e.msg))
        if e.stack ~= "" then add(e.stack) end
    end
    -- BugGrabber (BugSack)
    local db = BugGrabber and BugGrabber.GetDB and BugGrabber:GetDB()
    for k = #(db or {}), 1, -1 do
        local e = db[k]
        if n >= 8 then break end
        if e and type(e.message) == "string" and (e.message:find("ForeverPath") or (e.stack or ""):find("ForeverPath")) then
            n = n + 1
            add(("[BugSack x%d] %s"):format(e.counter or 1, e.message))
            if e.stack and e.stack ~= "" then add(e.stack) end
        end
    end
    if n == 0 then add("(aucune)") end
    return table.concat(lines, "\n")
end

ns.SlashExt.bug = function()
    ns.ShowExport(M.Text(), ns.Tr("Rapport de bug (Ctrl+A, Ctrl+C) — colle-le sur GitHub ou Discord"))
end
