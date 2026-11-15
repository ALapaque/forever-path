local _, ns = ...

-- Chez un marchand : vend les objets gris et répare l'équipement.
local M = ns.RegisterModule({
    id = "merchant", category = "comfort", default = true,
    name = "Marchand automatique",
    desc = ns.Tr("À l'ouverture d'un marchand : vend tes objets gris (camelote) et répare ton équipement si le marchand le permet. Récapitulatif dans la discussion. Maintiens Maj pour ne rien faire."),
    options = {
        { key = "junk", label = ns.Tr("Vendre la camelote (objets gris)"), type = "check", default = true },
        { key = "repair", label = ns.Tr("Réparer l'équipement"), type = "check", default = true },
    },
})

local function money(c)
    return GetCoinTextureString and GetCoinTextureString(c) or (math.floor(c / 10000) .. "po")
end

-- objets gris des sacs (valeur > 0)
function M.Junk()
    local list = {}
    for bag = 0, 4 do
        for slot = 1, (C_Container.GetContainerNumSlots(bag) or 0) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == 0 and not info.hasNoValue and not info.isLocked and info.itemID then
                local sell = select(11, C_Item.GetItemInfo(info.itemID)) or 0
                if sell > 0 then list[#list + 1] = { bag = bag, slot = slot, value = sell * (info.stackCount or 1) } end
            end
        end
    end
    return list
end

local selling
local function sellBatch(list, i, total)
    if not (MerchantFrame and MerchantFrame:IsShown()) then selling = nil return end
    local last = math.min(#list, i + 9)          -- 10 objets par vague (le serveur suit)
    for k = i, last do
        local it = list[k]
        C_Container.UseContainerItem(it.bag, it.slot)
        total = total + it.value
    end
    if last < #list then
        C_Timer.After(0.3, function() sellBatch(list, last + 1, total) end)
    else
        selling = nil
        ns.Print((ns.Tr("Camelote vendue : %d objet(s), %s")):format(#list, money(total)))
    end
end

M:On("MERCHANT_SHOW", function()
    if IsShiftKeyDown() or InCombatLockdown() then return end
    if M:Opt("repair") and CanMerchantRepair and CanMerchantRepair() then
        local cost, can = GetRepairAllCost()
        if can and cost and cost > 0 and cost <= GetMoney() then
            RepairAllItems(false)
            ns.Print((ns.Tr("Équipement réparé : %s")):format(money(cost)))
        end
    end
    if M:Opt("junk") and not selling then
        local list = M.Junk()
        if #list > 0 then selling = true; sellBatch(list, 1, 0) end
    end
end)

function M.preview(p)
    local t = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    t:SetPoint("CENTER")
    t:SetText(ns.Tr("|cff9d9d9dCamelote vendue : 7 objet(s)|r\n|cffffd100+ 1 po 23 pa|r\n\nÉquipement réparé"))
end
