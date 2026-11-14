local _, ns = ...

local M = ns.RegisterModule({
    id = "reminders", category = "comfort", default = true,
    name = "Rappels utiles",
    desc = "Petits rappels à l'écran : nouveaux sorts à apprendre, équipement à réparer, sacs presque pleins.",
    options = {
        { key = "train", label = "Sorts à apprendre (niveaux pairs)", type = "check", default = true },
        { key = "repair", label = "Réparation (< 30 %)", type = "check", default = true },
        { key = "bags", label = "Sacs presque pleins", type = "check", default = true },
    },
})

local lastRepair, lastBags = 0, 0

M:On("PLAYER_LEVEL_UP", function(lvl)
    if M:Opt("train") and lvl % 2 == 0 then
        C_Timer.After(2, function()
            ns.Toast(("Niveau %d : de nouveaux sorts t'attendent chez ton maître de classe."):format(lvl),
                "Interface\\Icons\\INV_Misc_Book_09", 0.6, 0.85, 1, 6)
        end)
    end
end)

M:On("UPDATE_INVENTORY_DURABILITY", function()
    if not M:Opt("repair") or GetTime() - lastRepair < 600 then return end
    local low = 1
    for slot = 1, 18 do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then low = math.min(low, cur / max) end
    end
    if low < 0.3 then
        lastRepair = GetTime()
        ns.Toast("Ton équipement est presque cassé : pense à réparer.", "Interface\\Icons\\Trade_BlackSmithing", 1, 0.6, 0.2)
    end
end)

M:On("BAG_UPDATE_DELAYED", function()
    if not M:Opt("bags") or GetTime() - lastBags < 300 then return end
    local free = 0
    for bag = 0, 4 do free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0) end
    if free <= 2 then
        lastBags = GetTime()
        ns.Toast(("Plus que %d place(s) dans tes sacs : vends ou jette des objets."):format(free), "Interface\\Icons\\INV_Misc_Bag_08", 1, 0.85, 0.3)
    end
end)

function M.preview(p)
    local box = CreateFrame("Frame", nil, p)
    box:SetSize(150, 30); box:SetPoint("CENTER")
    ns.Skin(box, 0.9)
    local i = box:CreateTexture(nil, "ARTWORK"); i:SetSize(20, 20); i:SetPoint("LEFT", 5, 0)
    i:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    local t = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", i, "RIGHT", 5, 0); t:SetText("Nouveaux sorts !")
end
