local _, ns = ...
local Places = ns.Nav.Places

-- Métiers d'appoint : secourisme, cuisine, pêche. Rappel quand un maître est tout près et que tu
-- n'as pas encore appris le métier, avec un détour en un clic.
local M = ns.RegisterModule({
    id = "secondary", category = "comfort", default = true,
    name = "Métiers d'appoint",
    desc = "Secourisme (bandages : moins de repos entre les combats), cuisine et pêche. Quand un maître est près de toi et que tu n'as pas le métier, le guide le signale et propose le détour.",
    options = {
        { key = "FIRSTAID", label = "Secourisme", type = "check", default = true },
        { key = "COOKING", label = "Cuisine", type = "check", default = false },
        { key = "FISHING", label = "Pêche", type = "check", default = false },
        { key = "dist", label = "Distance max (yards)", type = "slider", min = 100, max = 1500, step = 100, default = 400 },
    },
})

local SKILL = { FIRSTAID = 129, COOKING = 185, FISHING = 356 }
local LABEL = { FIRSTAID = ns.Tr("Secourisme"), COOKING = ns.Tr("Cuisine"), FISHING = ns.Tr("Pêche") }

-- métiers secondaires connus (lignes de compétence)
function M.Known()
    local known = {}
    if GetProfessions then
        for _, idx in pairs({ GetProfessions() }) do
            if idx then
                local line = select(7, GetProfessionInfo(idx))
                for k, v in pairs(SKILL) do if v == line then known[k] = true end end
            end
        end
    end
    return known
end

-- métier à apprendre près d'ici : kind, maître, distance
function M.Suggest()
    if ns.PlayerLevel() < 5 then return end
    local known = M.Known()
    local maxD = M:Opt("dist") or 400
    for _, kind in ipairs({ "FIRSTAID", "COOKING", "FISHING" }) do
        if M:Opt(kind) and not known[kind] then
            local t, d = Places.NearestTrainerOf(kind)
            if t and d and d <= maxD then return kind, t, d end
        end
    end
end

local btn, lastCheck = nil, 0
function M:Update()
    if not ns.Guide then return end
    local kind, t = nil, nil
    if self.enabled then kind, t = M.Suggest() end
    if kind and not (ns.cdb.secondaryDismissed or {})[kind] then
        ns.Guide:SetSection("secondary", 86, ns.Tr("|cff66ccff%s|r à apprendre tout près : %s"):format(LABEL[kind], t.name))
    else
        kind = nil
        ns.Guide:SetSection("secondary", 86, nil)
    end
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("secondary", nil, 22, function(_, mouse)
            local k, tt = M.Suggest()
            if not k then return end
            if mouse == "RightButton" then
                ns.cdb.secondaryDismissed = ns.cdb.secondaryDismissed or {}
                ns.cdb.secondaryDismissed[k] = true
                M:Update()
            else
                Places.Go(tt, ns.Tr("Maître (%s) : %s"):format(LABEL[k], tt.name), "Interface\\Icons\\Spell_Holy_SealOfSacrifice", "secondary")
            end
        end, ns.Tr("Clic : y aller (détour)\nClic droit : ne plus proposer ce métier"), "Interface\\Icons\\Spell_Holy_SealOfSacrifice")
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
    if btn then btn:SetShown(kind ~= nil); ns.Guide:Layout() end
end

M:On("FP_TICK", function()
    if GetTime() - lastCheck > 10 then lastCheck = GetTime(); M:Update() end
end)
M:On("SKILL_LINES_CHANGED", function() M:Update() end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|TInterface\\Icons\\Spell_Holy_SealOfSacrifice:16|t |cff66ccffSecourisme|r\nà apprendre tout près")
end
