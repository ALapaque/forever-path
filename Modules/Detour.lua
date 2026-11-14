local _, ns = ...

-- Affichage d'un détour en cours dans la fenêtre du guide, avec un bouton pour l'annuler.
local btn
local function update(d)
    if not ns.Guide then return end
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("detour", nil, 22, function() ns.Engine.SetDetour(nil) end,
            ns.Tr("Annuler le détour\n|cffaaaaaaReprend le guidage vers l'étape du guide|r"), "Interface\\Buttons\\UI-StopButton")
    end
    if d then
        local icon = d.icon and ("|T%s:14|t "):format(d.icon) or ""
        ns.Guide:SetSection("detour", 5, (ns.Tr("%s|cff66ccffDétour :|r %s")):format(icon, d.text or ""))
    else
        ns.Guide:SetSection("detour", 5, nil)
    end
    if btn then btn:SetShown(d ~= nil); ns.Guide:Layout() end
end
ns.On("FP_DETOUR", update)
ns.On("FP_DETOUR_ARRIVED", function(d)
    ns.Toast((ns.Tr("Arrivé : %s")):format(d.text or ""), d.icon or "Interface\\Icons\\INV_Misc_Map_01", 0.4, 0.8, 1, 4)
end)
