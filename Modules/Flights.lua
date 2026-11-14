local _, ns = ...
local Nav = ns.Nav

-- Vols automatiques : chez un maître de vol, choisit tout seul le point de vol le plus proche de
-- l'étape si le vol fait gagner du temps. Maj pour choisir soi-même.
local M = ns.RegisterModule({
    id = "flights", category = "nav", default = true,
    name = "Vols automatiques",
    desc = "Chez un maître de vol, prend tout seul le vol qui rapproche le plus de l'étape (si ça fait gagner du temps). Ouvre aussi la carte des vols quand tu parles au maître. Maintiens Maj pour choisir toi-même.",
    options = {
        { key = "take", label = "Prendre le vol tout seul", type = "check", default = true },
        { key = "open", label = "Ouvrir la carte des vols en parlant au maître", type = "check", default = true },
        { key = "gain", label = "Gain minimum (yards)", type = "slider", min = 100, max = 1500, step = 100, default = 400 },
    },
})

-- meilleur point de vol vers la cible (point monde) parmi les nœuds accessibles
function M.Best(nodes, taxiMap, target, here)
    local best, bestD
    for _, n in ipairs(nodes or {}) do
        -- state : 0 = ici, 1 = accessible, 2 = inaccessible
        if n.state == 1 and n.position then
            local c, wx, wy = Nav.ToWorld(taxiMap, n.position.x, n.position.y)
            if c and c == target.c then
                local d = Nav.Dist({ x = wx, y = wy }, target)
                if not bestD or d < bestD then best, bestD = n, d end
            end
        end
    end
    if not best then return end
    local walk = here and Nav.Dist(here, target) or math.huge
    return best, bestD, walk - bestD
end

M:On("TAXIMAP_OPENED", function()
    if not (M:Opt("take") and not IsShiftKeyDown()) then return end
    C_Timer.After(0.2, function()
        local step = ns.Engine.NavStep()
        local target = step and Nav.StepPoint(step)
        local taxiMap = GetTaxiMapID and GetTaxiMapID()
        if not (target and taxiMap and C_TaxiMap and C_TaxiMap.GetAllTaxiNodes) then return end
        local node, _, gain = M.Best(C_TaxiMap.GetAllTaxiNodes(taxiMap), taxiMap, target, Nav.Player())
        if node and gain and gain >= (M:Opt("gain") or 400) and node.slotIndex then
            ns.Print(("Vol vers %s"):format(node.name or "?"))
            TakeTaxiNode(node.slotIndex)
        end
    end)
end)

-- maître de vol : ouvrir la carte des vols directement (pas de quête à gérer)
M:On("GOSSIP_SHOW", function()
    if not M:Opt("open") or IsShiftKeyDown() then return end
    if #(C_GossipInfo.GetAvailableQuests() or {}) > 0 or #(C_GossipInfo.GetActiveQuests() or {}) > 0 then return end
    local o = ns.GossipOption("taxi")
    if o then C_GossipInfo.SelectOption(o.gossipOptionID) end
end)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|TInterface\\Icons\\Ability_Mount_Wyvern_01:16|t Vol vers\nLa Croisée")
end
