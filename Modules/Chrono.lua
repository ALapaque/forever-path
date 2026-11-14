local _, ns = ...

-- Chrono et rapport de parcours : temps de jeu par niveau (records entre tes personnages) et
-- rapport anonyme à partager (/fp rapport) pour améliorer la route avec de vraies parties.
local M = ns.RegisterModule({
    id = "chrono", category = "community", default = true,
    name = ns.Tr("Chrono et rapport de parcours"),
    desc = ns.Tr("Mesure ton temps de jeu par niveau et le compare à ton record (tous personnages). /fp chrono pour le tableau à partager, /fp rapport pour envoyer un rapport anonyme qui aide à améliorer la route."),
    options = {
        { key = "show", label = ns.Tr("Afficher le chrono dans le guide"), type = "check", default = true },
    },
})

local function stats()
    local s = ns.cdb.stats
    if not s then
        s = { played = 0, levels = {}, deaths = 0, segs = {}, segDeaths = {} }
        ns.cdb.stats = s
    end
    return s
end
M.Stats = stats

local function records()
    ns.db.records = ns.db.records or {}
    local key = ns.cdb.path or "any"
    ns.db.records[key] = ns.db.records[key] or {}
    return ns.db.records[key]
end

function M.Fmt(sec)
    sec = math.floor(sec or 0)
    if sec >= 3600 then return ("%dh%02d"):format(math.floor(sec / 3600), math.floor(sec % 3600 / 60)) end
    return ("%d min"):format(math.floor(sec / 60))
end

-- temps de jeu : compté en direct (pas de /played imposé) ; recalé si le jeu donne le vrai total
local acc = 0
local clock = CreateFrame("Frame")
clock:SetScript("OnUpdate", function(_, dt)
    if not (M.enabled and ns.cdb) then return end
    dt = math.min(dt, 1)
    local s = stats()
    s.played = s.played + dt
    local gid = ns.cdb.guideId
    if gid then s.segs[gid] = (s.segs[gid] or 0) + dt end
    acc = acc + dt
    if acc > 30 then acc = 0; M:Update() end
end)

M:On("TIME_PLAYED_MSG", function(total)
    if type(total) == "number" and not ns.IsSecret(total) and total > 0 then stats().played = total end
end)

M:On("PLAYER_LEVEL_UP", function(lvl)
    local s = stats()
    s.levels[lvl] = s.played
    local rec = records()
    local best = rec[lvl]
    if not best or s.played < best then
        rec[lvl] = s.played
        if best and lvl % 5 == 0 then
            ns.Toast((ns.Tr("Record : niveau %d en %s (%s de mieux)")):format(lvl, M.Fmt(s.played), M.Fmt(best - s.played)),
                "Interface\\Icons\\INV_Misc_PocketWatch_02", 1, 0.82, 0.1, 5)
        end
    end
    M:Update()
end)

M:On("PLAYER_DEAD", function()
    local s = stats()
    s.deaths = s.deaths + 1
    local gid = ns.cdb.guideId
    if gid then s.segDeaths[gid] = (s.segDeaths[gid] or 0) + 1 end
end)

function M:Update()
    if not ns.Guide then return end
    if not (self.enabled and self:Opt("show")) then ns.Guide:SetSection("chrono", 91, nil) return end
    local s = stats()
    local lvl = ns.PlayerLevel()
    local text = (ns.Tr("|cffd4af37Chrono|r %s de jeu")):format(M.Fmt(s.played))
    local best = records()[lvl + 1]
    if best then
        local diff = best - s.played
        if diff >= 0 then
            text = text .. (ns.Tr("  •  record du niv. %d dans %s")):format(lvl + 1, M.Fmt(diff))
        else
            text = text .. (ns.Tr("  •  |cffff7f3f%s de retard|r sur le record")):format(M.Fmt(-diff))
        end
    end
    ns.Guide:SetSection("chrono", 91, text)
end

-- Tableau des temps par tranche de 10 niveaux
function M.Table()
    local s, rec = stats(), records()
    local lines = { ("ForeverPath %s : %s %s, niveau %d, %s de jeu, %d mort(s)"):format(ns.VERSION or "",
        UnitRace("player") or "", UnitClass("player") or "", ns.PlayerLevel(), M.Fmt(s.played), s.deaths), "" }
    lines[#lines + 1] = "Niveaux    Temps     Record"
    for a = 1, 51, 10 do
        local b = math.min(a + 10, 60)
        local t0 = a == 1 and 0 or s.levels[a]
        local t1 = s.levels[b]
        local r0 = a == 1 and 0 or rec[a]
        local r1 = rec[b]
        if t1 and t0 then
            lines[#lines + 1] = ("%2d-%-2d      %-9s %s"):format(a, b, M.Fmt(t1 - t0), (r1 and r0) and M.Fmt(r1 - r0) or "-")
        end
    end
    return table.concat(lines, "\n")
end

-- Rapport de parcours (anonyme : ni nom, ni royaume)
function M.Report()
    local s = stats()
    local _, race = UnitRace("player")
    local _, class = UnitClass("player")
    local out = { ("FPR1;%s;%s;%s;%s;%d;%d;%d"):format(ns.VERSION or "?", ns.cdb.path or "auto", race or "?", class or "?",
        ns.PlayerLevel(), math.floor(s.played), s.deaths) }
    for lvl = 2, 60 do
        if s.levels[lvl] then out[#out + 1] = ("L;%d;%d"):format(lvl, math.floor(s.levels[lvl])) end
    end
    for gid, sec in pairs(s.segs) do
        local skipped = 0
        for _ in pairs(ns.cdb.skipped[gid] or {}) do skipped = skipped + 1 end
        out[#out + 1] = ("S;%s;%d;%d;%d"):format(gid, math.floor(sec), s.segDeaths[gid] or 0, skipped)
        for idx in pairs(ns.cdb.skipped[gid] or {}) do
            local g = ns.Guides[gid]
            local st = g and g.steps[idx]
            out[#out + 1] = ("K;%s;%d;%s;%s"):format(gid, idx, st and st.type or "?", st and st.quest or "")
        end
    end
    table.sort(out, function(a, b)
        local ha, hb = a:sub(1, 4) == "FPR1", b:sub(1, 4) == "FPR1"
        if ha ~= hb then return ha end
        return a < b
    end)
    return table.concat(out, "\n")
end

ns.SlashExt.chrono = function() ns.ShowExport(M.Table(), ns.Tr("Chrono ForeverPath")) end
ns.SlashExt.rapport = function()
    ns.ShowExport(M.Report(), ns.Tr("Rapport de parcours (Ctrl+C puis colle-le sur GitHub ou Discord)"))
end
ns.SlashExt.report = ns.SlashExt.rapport

M:On("FP_STEP_CHANGED", function() M:Update() end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("|cffd4af37Chrono|r 6h12 de jeu\nrecord du niv. 21 dans 14 min\n\n/fp rapport"))
end
