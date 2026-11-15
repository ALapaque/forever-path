local _, ns = ...

-- Rattrapage : si tu as pris de l'avance (groupe, donjons), les quêtes de la route devenues grises
-- ne sont plus proposées. Les paliers « upto » des routes font le reste.
local M = ns.RegisterModule({
    id = "catchup", category = "guide", default = true,
    name = "Rattrapage",
    desc = "Si tu as pris de l'avance (groupe, donjons), le guide saute les quêtes devenues trop basses pour rapporter de l'XP, et charge le bon segment.",
    options = {
        { key = "gap", label = "Quête sautée à partir de N niveaux d'écart", type = "slider", min = 5, max = 12, step = 1, default = 9 },
    },
})

M:On("PLAYER_LEVEL_UP", function()
    if not M.enabled then return end
    C_Timer.After(1, function() ns.Engine.Refresh() end)
end)
function M:OnEnable() ns.Engine.Refresh() end
function M:OnDisable() ns.Engine.Refresh() end
function M:OnOptionChanged() ns.Engine.Refresh() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cff999999Prendre : Les loups affamés (niv. 4)|r\n|cff3fbf3fsautée : trop basse|r")
end
