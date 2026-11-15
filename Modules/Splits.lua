local _, ns = ...

-- Écran « speedrun » : temps du segment en cours comparé à ton meilleur temps sur ce segment,
-- et écarts des derniers segments terminés (vert : plus rapide, rouge : plus lent).
local M = ns.RegisterModule({
    id = "splits", category = "community", default = false,
    name = "Écran de splits (speedrun)",
    desc = "Petit cadre façon LiveSplit : chrono du segment en cours, écart avec ton meilleur temps sur ce segment, et résultats des derniers segments. Glisse le cadre pour le déplacer.",
    options = {
        { key = "rows", label = "Segments affichés", type = "slider", min = 1, max = 8, step = 1, default = 4 },
    },
})

local f = CreateFrame("Frame", "QuestweaverSplits", UIParent, "BackdropTemplate")
f:SetSize(220, 70)
f:SetPoint("TOPRIGHT", -260, -220)
f:Hide()
ns.Skin(f, 0.85)
ns.MakeMovable(f, "splits", { "TOPRIGHT", "TOPRIGHT", -260, -220 })
f.title = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
f.title:SetPoint("TOPLEFT", 8, -6)
f.time = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontLarge")
f.time:SetPoint("TOPRIGHT", -8, -4)
f.rows = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
f.rows:SetPoint("TOPLEFT", 8, -28)
f.rows:SetPoint("RIGHT", -8, 0)
f.rows:SetJustifyH("LEFT")

local function best()
    ns.db.segRecords = ns.db.segRecords or {}
    return ns.db.segRecords
end
local function fmt(sec)
    sec = math.floor(math.abs(sec or 0))
    if sec >= 3600 then return ("%d:%02d:%02d"):format(math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60) end
    return ("%d:%02d"):format(math.floor(sec / 60), sec % 60)
end
M.Fmt = fmt
local function delta(d)
    if not d then return "" end
    return d <= 0 and ("|cff3fbf3f-%s|r"):format(fmt(d)) or ("|cffff5040+%s|r"):format(fmt(d))
end

-- fin d'un segment : enregistre le temps et le record
function M.Finish(gid, sec)
    if not (gid and sec and sec > 30) then return end
    local rec = best()
    local prev = rec[gid]
    ns.cdb.splits = ns.cdb.splits or {}
    table.insert(ns.cdb.splits, 1, { gid = gid, sec = sec, delta = prev and sec - prev })
    while #ns.cdb.splits > 20 do table.remove(ns.cdb.splits) end
    if not prev or sec < prev then rec[gid] = sec end
end

local current
local function segTime()
    local s = ns.Modules.chrono and ns.Modules.chrono.Stats and ns.Modules.chrono.Stats()
    return s and current and s.segs[current] or 0
end

function M:Update()
    if not (self.enabled and ns.cdb) then f:Hide() return end
    local g = ns.Engine.Current()
    if not g then f:Hide() return end
    if current and current ~= g.id then M.Finish(current, segTime()) end
    current = g.id
    local t = segTime()
    local rec = best()[g.id]
    f.title:SetText(g.name or g.id)
    f.time:SetText(fmt(t) .. (rec and "  " .. delta(t - rec) or ""))
    local lines = {}
    for k, sp in ipairs(ns.cdb.splits or {}) do
        if k > (self:Opt("rows") or 4) then break end
        local gg = ns.Guides[sp.gid]
        lines[#lines + 1] = ("%s  %s  %s"):format(gg and gg.name or sp.gid, fmt(sp.sec), delta(sp.delta))
    end
    f.rows:SetText(table.concat(lines, "\n"))
    f:SetHeight(34 + (f.rows:GetStringHeight() or 0))
    f:Show()
end

local acc = 0
f:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc >= 1 then acc = 0; M:Update() end
end)
M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("FP_READY", function() current = ns.cdb.guideId; M:Update() end)
function M:OnEnable() self:Update() end
function M:OnDisable() f:Hide() end
M.frame = f

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cffd4af37Les Tarides 16-21|r   42:10 |cff3fbf3f-1:32|r\nDurotar 1-11  1:12:40 |cffff5040+3:05|r")
end
