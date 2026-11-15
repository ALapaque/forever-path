local _, ns = ...

-- Éditeur de route en jeu : corriger la position d'une étape, la supprimer ou ajouter une note,
-- sans toucher au code. Les corrections sont gardées par route et exportables pour être partagées.
local M = ns.RegisterModule({
    id = "editor", category = "community", default = true,
    name = "Éditeur de route",
    desc = "Corrige la route en jouant : /qw edit pos (l'étape prend ta position), /qw edit suppr (retire l'étape), /qw edit note <texte> (ajoute une note après l'étape), /qw edit annuler, /qw edit export (route corrigée à partager).",
    options = {},
})

local function edits(gid)
    ns.db.edits = ns.db.edits or {}
    ns.db.edits[gid] = ns.db.edits[gid] or { pos = {}, removed = {}, notes = {} }
    return ns.db.edits[gid]
end

-- applique les corrections enregistrées à un guide (au chargement)
function ns.ApplyEdits(g)
    local e = g and ns.db and ns.db.edits and ns.db.edits[g.id]
    if not e or g.editsApplied then return end
    g.editsApplied = true
    for idx, p in pairs(e.pos) do
        local st = g.steps[idx]
        if st then st.map, st.x, st.y = p.map, p.x, p.y end
    end
    for idx in pairs(e.removed) do
        if g.steps[idx] then g.steps[idx].removed = true end
    end
    -- notes : insérées de la fin vers le début pour garder les index des autres corrections
    local list = {}
    for _, n in ipairs(e.notes) do list[#list + 1] = n end
    table.sort(list, function(a, b) return a.after > b.after end)
    for _, n in ipairs(list) do
        table.insert(g.steps, math.min(n.after + 1, #g.steps + 1),
            { type = "note", text = n.text, map = n.map, x = n.x, y = n.y, edited = true })
    end
end

local function current()
    local g, st, i = ns.Engine.Current()
    if not st then ns.Print(ns.Tr("Aucune étape en cours.")) end
    return g, st, i
end

function M.SetPos()
    local g, st, i = current()
    if not st then return end
    local map, x, y = ns.PlayerMapPos()
    if not (map and x) then ns.Print(ns.Tr("Position indisponible ici.")) return end
    local p = { map = map, x = math.floor(x * 1000 + 0.5) / 10, y = math.floor(y * 1000 + 0.5) / 10 }
    edits(g.id).pos[i] = p
    st.map, st.x, st.y = p.map, p.x, p.y
    ns.Print(ns.Tr("Étape %d : position corrigée (%.1f, %.1f)."):format(i, p.x, p.y))
    ns.Fire("FP_STEP_CHANGED", true)
end

function M.Remove()
    local g, st, i = current()
    if not st then return end
    edits(g.id).removed[i] = true
    st.removed = true
    ns.Print(ns.Tr("Étape %d retirée de la route."):format(i))
    ns.Engine.Refresh()
end

function M.AddNote(text)
    local g, st, i = current()
    if not st or not text or text == "" then return end
    local map, x, y = ns.PlayerMapPos()
    local n = { after = i, text = text, map = map, x = x and math.floor(x * 1000 + 0.5) / 10, y = y and math.floor(y * 1000 + 0.5) / 10 }
    table.insert(edits(g.id).notes, n)
    table.insert(g.steps, i + 1, { type = "note", text = text, map = n.map, x = n.x, y = n.y, edited = true })
    ns.Print(ns.Tr("Note ajoutée après l'étape %d."):format(i))
    ns.Fire("FP_STEP_CHANGED", true)
end

function M.Reset()
    local g = ns.Engine.Current()
    if not g then return end
    ns.db.edits[g.id] = nil
    ns.Print(ns.Tr("Corrections effacées : /reload pour retrouver la route d'origine."))
end

-- route corrigée au format DSL (pour la partager ou proposer une correction sur GitHub)
local CODE = {}
for code, t in pairs(ns.STEP_TYPES) do CODE[t] = code end
function M.Export(g)
    g = g or ns.Engine.Current()
    if not g then return "" end
    local out = { "# nom: " .. (g.name or g.id), ("# niveaux: %d-%d"):format(g.minLevel or 1, g.maxLevel or 60) }
    if g.faction then out[#out + 1] = "# faction: " .. g.faction end
    local lastMap
    for _, st in ipairs(g.steps) do
        if not st.removed then
            if st.map and st.map ~= lastMap then out[#out + 1] = "M " .. tostring(st.map); lastMap = st.map end
            local parts = { CODE[st.type] or "N" }
            if st.quest then parts[#parts + 1] = tostring(st.quest) end
            if st.level and st.type == "level" then parts[#parts + 1] = tostring(st.level) end
            if st.text then parts[#parts + 1] = '"' .. st.text:gsub('"', "'") .. '"' end
            if st.x then parts[#parts + 1] = ("@%.1f,%.1f"):format(st.x, st.y) end
            if st.npcID then parts[#parts + 1] = "id=" .. st.npcID end
            if st.mobs then
                local m = {}
                for id in pairs(st.mobs) do m[#m + 1] = id end
                table.sort(m)
                parts[#parts + 1] = "mobs=" .. table.concat(m, ",")
            end
            if st.radius then parts[#parts + 1] = "r=" .. st.radius end
            if st.upto then parts[#parts + 1] = "upto=" .. st.upto end
            if st.qlvl then parts[#parts + 1] = "lvl=" .. st.qlvl end
            if st.danger then parts[#parts + 1] = "danger=1" end
            out[#out + 1] = table.concat(parts, " ")
        end
    end
    return table.concat(out, "\n")
end

M:On("FP_INIT", function()
    for _, id in ipairs(ns.GuideOrder) do ns.ApplyEdits(ns.Guides[id]) end
end)

ns.SlashExt.edit = function(arg)
    local cmd, rest = (arg or ""):match("^(%S*)%s*(.-)$")
    if cmd == "pos" then M.SetPos()
    elseif cmd == "suppr" or cmd == "del" then M.Remove()
    elseif cmd == "note" then M.AddNote(rest)
    elseif cmd == "annuler" or cmd == "reset" then M.Reset()
    elseif cmd == "export" then ns.ShowExport(M.Export(), ns.Tr("Route corrigée (Ctrl+A, Ctrl+C) — à partager"))
    else ns.Print("/qw edit pos | suppr | note <texte> | annuler | export") end
end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("/qw edit pos\n|cff3fbf3fÉtape 12 : position corrigée|r\n/fp edit export")
end
