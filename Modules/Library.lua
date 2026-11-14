local _, ns = ...

-- Bibliothèque de routes : importe des routes partagées (texte de l'enregistreur ou fichiers du
-- dossier Routes/ du dépôt GitHub), les garde pour tous tes personnages et les charge comme les autres.
local M = ns.RegisterModule({
    id = "library", category = "community", default = true,
    name = "Bibliothèque de routes",
    desc = "Importe une route partagée (/fp importer, puis colle le texte) : routes des nouvelles zones de Forever enregistrées par d'autres joueurs, routes corrigées… Elle est gardée pour tous tes personnages. /fp routes pour la liste.",
    options = {},
})

-- en-têtes reconnus : « # nom: … », « # niveaux: 10-20 », « # faction: Horde »
function M.Parse(text)
    if type(text) ~= "string" or not text:find("%S") then return nil, ns.Tr("texte vide") end
    local meta = {}
    for line in text:gmatch("[^\n]+") do
        local k, v = line:match("^#%s*(%a+)%s*:%s*(.-)%s*$")
        if k then meta[k:lower()] = v end
    end
    local ok, steps = pcall(ns.ParseGuide, text)
    if not ok then return nil, tostring(steps) end
    if #steps == 0 then return nil, ns.Tr("aucune étape reconnue") end
    local lo, hi = (meta.niveaux or meta.levels or ""):match("(%d+)%s*%-%s*(%d+)")
    local name = meta.nom or meta.name or (ns.Tr("Route importée") .. " " .. date("%d/%m %H:%M"))
    local fac = meta.faction
    if fac ~= "Alliance" and fac ~= "Horde" then fac = nil end
    return { name = name, text = text, faction = fac, minLevel = tonumber(lo) or 1, maxLevel = tonumber(hi) or 60, n = #steps }
end

local function register(id, r)
    if ns.Guides[id] then return end
    ns.RegisterGuide({ id = id, name = r.name, text = r.text, faction = r.faction,
        minLevel = r.minLevel, maxLevel = r.maxLevel, custom = true })
end

function M.Import(text)
    local r, err = M.Parse(text)
    if not r then ns.Print(ns.Tr("Import impossible : %s"):format(err or "?")) return end
    ns.db.library = ns.db.library or {}
    local id = "custom-" .. time()
    ns.db.library[id] = r
    register(id, r)
    if ns.ApplyEdits then ns.ApplyEdits(ns.Guides[id]) end
    ns.Print(ns.Tr("Route importée : %s (%d étapes). /fp load %s pour la suivre."):format(r.name, r.n, id))
    return id
end

function M.Delete(id)
    if ns.db.library and ns.db.library[id] then
        ns.db.library[id] = nil
        ns.Guides[id] = nil
        for i, gid in ipairs(ns.GuideOrder) do if gid == id then table.remove(ns.GuideOrder, i) break end end
        ns.Print(ns.Tr("Route supprimée."))
    end
end

M:On("FP_INIT", function()
    for id, r in pairs(ns.db.library or {}) do register(id, r) end
end)

ns.SlashExt.importer = function()
    ns.ShowImport(ns.Tr("Colle la route à importer puis Importer"), function(text) M.Import(text) end)
end
ns.SlashExt.import = ns.SlashExt.importer
ns.SlashExt.routes = function(arg)
    local cmd, id = (arg or ""):match("^(%S*)%s*(%S*)$")
    if cmd == "suppr" or cmd == "delete" then M.Delete(id) return end
    local n = 0
    for gid, r in pairs(ns.db.library or {}) do
        n = n + 1
        ns.Print(("%s — %s (%d-%d, %d)"):format(gid, r.name, r.minLevel or 1, r.maxLevel or 60, r.n or 0))
    end
    if n == 0 then ns.Print(ns.Tr("Aucune route importée. /fp importer pour en ajouter une.")) end
end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("# nom: Rives Claires 36-40\nM 2210\nA 90012 @41.2,55.0 id=..\n|cff3fbf3fRoute importée|r")
end
