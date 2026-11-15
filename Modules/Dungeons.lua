local _, ns = ...
local Places = ns.Nav.Places

-- Donjons : quand ton niveau colle à un donjon, liste ses quêtes à prendre avant d'y aller
-- (données QuestieDB) et propose un détour vers le donneur le plus proche.
local M = ns.RegisterModule({
    id = "dungeons", category = "guide", default = true,
    name = "Quêtes de donjon",
    desc = "Quand ton niveau colle à un donjon, le guide indique combien de ses quêtes tu peux prendre avant d'y aller, et un bouton t'amène au donneur le plus proche. /qw donjons pour la liste complète.",
    options = {
        { key = "section", label = "Rappel dans le guide", type = "check", default = true },
    },
})

local function faction(f) return f == "both" or f == ns.PlayerFaction() end

-- donjons à ton niveau : { name, min, max, quests = { ... } } (quêtes prenables, pas faites)
function M.ForLevel(lvl)
    lvl = lvl or ns.PlayerLevel()
    local out = {}
    for _, d in ipairs(ns.World and ns.World.dungeons or {}) do
        if lvl >= d[3] - 2 and lvl <= d[4] then
            local qs = {}
            for _, q in ipairs(d[5]) do
                local id, qlvl, req, fac = q[1], q[2], q[3], q[4]
                if faction(fac) and req <= lvl and qlvl + 6 > lvl and not C_QuestLog.IsQuestFlaggedCompleted(id)
                    and not C_QuestLog.GetLogIndexForQuestID(id) then
                    qs[#qs + 1] = { id = id, level = qlvl, npc = q[5], map = q[6], x = q[7], y = q[8],
                        name = ns.isFrench and q[9] or q[10] }
                end
            end
            if #qs > 0 then out[#out + 1] = { name = ns.isFrench and d[1] or d[2], min = d[3], max = d[4], quests = qs } end
        end
    end
    return out
end

local btn
function M:Update()
    if not ns.Guide then return end
    local list = (self.enabled and self:Opt("section")) and M.ForLevel() or {}
    local d = list[1]
    if d then
        ns.Guide:SetSection("dungeons", 85, ns.Tr("|cffcc66ffDonjon|r %s (%d-%d) : %d quête(s) à prendre avant"):format(d.name, d.min, d.max, #d.quests))
    else
        ns.Guide:SetSection("dungeons", 85, nil)
    end
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("dungeons", nil, 22, function() M:GoNearest() end, function(tt)
            local dd = M.ForLevel()[1]
            if not dd then return end
            tt:AddLine(dd.name)
            for k = 1, math.min(8, #dd.quests) do tt:AddLine(("%d. %s (%d)"):format(k, dd.quests[k].name, dd.quests[k].level), 1, 1, 1) end
            tt:AddLine(ns.Tr("Clic : aller au donneur le plus proche"), 0.6, 0.6, 0.6)
        end, "Interface\\Icons\\INV_Misc_Key_03")
    end
    if btn then btn:SetShown(d ~= nil); ns.Guide:Layout() end
end

function M:GoNearest()
    local d = M.ForLevel()[1]
    if not d then return end
    local q = Places.Nearest(d.quests)
    if q then Places.Go(q, ns.Tr("Quête de donjon : %s"):format(q.name), "Interface\\Icons\\INV_Misc_Key_03", "dungeon") end
end

function M.List()
    local lines = {}
    for _, d in ipairs(M.ForLevel()) do
        lines[#lines + 1] = ("%s (%d-%d)"):format(d.name, d.min, d.max)
        for _, q in ipairs(d.quests) do
            lines[#lines + 1] = ("  [%d] %s — %s %.0f,%.0f"):format(q.level, q.name, Places.ZoneName(q.map), q.x, q.y)
        end
        lines[#lines + 1] = ""
    end
    return #lines > 0 and table.concat(lines, "\n") or ns.Tr("Aucun donjon à ton niveau pour le moment.")
end
ns.SlashExt.donjons = function() ns.ShowExport(M.List(), ns.Tr("Quêtes de donjon à ton niveau")) end
ns.SlashExt.dungeons = ns.SlashExt.donjons

M:On("PLAYER_LEVEL_UP", function() C_Timer.After(1, function() M:Update() end) end)
M:On("QUEST_ACCEPTED", function() M:Update() end)
M:On("FP_READY", function() M:Update() end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cffcc66ffDonjon|r Les Mortemines (17-26)\n4 quête(s) à prendre avant")
end
