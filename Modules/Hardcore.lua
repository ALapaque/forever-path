local _, ns = ...

-- Mode Hardcore : route prudente. Les quêtes dont les monstres sont nettement plus hauts que toi
-- (repérées à la génération) sont sautées, et l'entrée dans une zone trop haute est signalée.
local M = ns.RegisterModule({
    id = "hardcore", category = "safety", default = false,
    name = "Route prudente",
    desc = "Saute les quêtes dont les monstres sont nettement plus hauts que toi (prise, objectif et rendu) et prévient quand tu entres dans une zone trop haute. À combiner avec les alertes de danger.",
    options = {
        { key = "skip", label = "Sauter les quêtes dangereuses", type = "check", default = true },
        { key = "zone", label = "Prévenir dans une zone trop haute", type = "check", default = true },
        { key = "gap", label = "Zone trop haute à partir de (niveaux)", type = "slider", min = 1, max = 6, step = 1, default = 3 },
    },
})

-- nombre de quêtes dangereuses sautées dans le segment en cours
function M.Skipped()
    local g = ns.Engine.Current()
    if not g then return 0 end
    local n, seen = 0, {}
    for _, st in ipairs(g.steps) do
        if st.danger and st.quest and not seen[st.quest] then seen[st.quest] = true; n = n + 1 end
    end
    return n
end

M:On("ZONE_CHANGED_NEW_AREA", function()
    if not (M.enabled and M:Opt("zone")) then return end
    local z = ns.CurrentZone and ns.CurrentZone()
    if z and z.min and z.min - ns.PlayerLevel() >= (M:Opt("gap") or 3) then
        ns.Toast(("Zone dangereuse : %s (niveau %d+)"):format(ns.isFrench and z.fr or z.en, z.min),
            "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", 1, 0.25, 0.2, 6)
        if PlaySound then PlaySound(SOUNDKIT.RAID_WARNING) end
    end
end)

function M:OnEnable() ns.Engine.Refresh() end
function M:OnDisable() ns.Engine.Refresh() end
function M:OnOptionChanged() ns.Engine.Refresh() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14|t Route prudente\n|cff999999Quête dangereuse sautée|r")
end
