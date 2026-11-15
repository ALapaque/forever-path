local _, ns = ...

-- Achats automatiques chez le marchand : nourriture, boisson (classes à mana), munitions (chasseur).
-- Choisit le meilleur article utilisable à ton niveau et complète jusqu'à la quantité voulue.
local M = ns.RegisterModule({
    id = "supplies", category = "comfort", default = false,
    name = "Achats automatiques",
    desc = "Chez un marchand : complète tes réserves de nourriture, de boisson (classes à mana) et de munitions (chasseurs) avec le meilleur article de ton niveau, sans dépasser un budget. Maintiens Maj pour ne rien acheter.",
    options = {
        { key = "food", label = "Nourriture (quantité)", type = "slider", min = 0, max = 60, step = 5, default = 20 },
        { key = "drink", label = "Boisson (quantité)", type = "slider", min = 0, max = 60, step = 5, default = 20 },
        { key = "ammo", label = "Munitions (quantité)", type = "slider", min = 0, max = 2000, step = 200, default = 1000 },
        { key = "budget", label = "Budget max (% de ton or)", type = "slider", min = 5, max = 50, step = 5, default = 20 },
    },
})

local MANA = { MAGE = true, PRIEST = true, WARLOCK = true, DRUID = true, PALADIN = true, SHAMAN = true, HUNTER = true }
M.MANA = MANA

-- catégorie d'un article : "food", "drink", "arrow", "bullet" ou nil
local spellNames
function M.Kind(itemID)
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    if classID == 6 then return subclassID == 2 and "arrow" or subclassID == 3 and "bullet" or nil end
    if classID ~= 0 then return end
    if not spellNames then
        local get = C_Spell and C_Spell.GetSpellName or GetSpellInfo
        spellNames = { food = get and get(433), drink = get and get(430) }
    end
    local name = C_Item.GetItemSpell and C_Item.GetItemSpell(itemID)
    if not name then return end
    if name == spellNames.drink then return "drink" end
    if name == spellNames.food then return "food" end
end

-- arme à distance du chasseur : arcs et arbalètes -> flèches, fusils -> balles
local function ammoKind()
    local id = GetInventoryItemID("player", 18)
    if not id then return end
    local _, _, _, _, _, classID, sub = C_Item.GetItemInfoInstant(id)
    if classID ~= 2 then return end
    if sub == 2 or sub == 18 then return "arrow" end
    if sub == 3 then return "bullet" end
end

-- liste d'achats : { index, kind, qty, price }
function M.Plan()
    local _, class = UnitClass("player")
    local level = ns.PlayerLevel()
    local want = { food = M:Opt("food") or 0 }
    if MANA[class] then want.drink = M:Opt("drink") or 0 end
    local ak = class == "HUNTER" and ammoKind()
    if ak then want[ak] = M:Opt("ammo") or 0 end
    -- meilleur article par catégorie (niveau requis le plus haut <= mon niveau)
    local best = {}
    for i = 1, (GetMerchantNumItems() or 0) do
        local id = GetMerchantItemID(i)
        local kind = id and M.Kind(id)
        if kind and want[kind] and want[kind] > 0 then
            local info = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(i)
            local price, stack, usable = info and info.price, info and info.stackCount or 1, not info or info.isUsable ~= false
            if not info then
                local _, _, p, q = GetMerchantItemInfo(i)
                price, stack = p, q or 1
            end
            local req = select(5, C_Item.GetItemInfo(id)) or 0
            if usable and price and req <= level and (not best[kind] or req > best[kind].req) then
                best[kind] = { index = i, id = id, req = req, price = price, stack = math.max(1, stack or 1) }
            end
        end
    end
    local plan = {}
    for kind, b in pairs(best) do
        local need = want[kind] - (C_Item.GetItemCount(b.id) or 0)
        if need > 0 then plan[#plan + 1] = { index = b.index, kind = kind, qty = need, price = b.price / b.stack } end
    end
    return plan
end

M:On("MERCHANT_SHOW", function()
    if IsShiftKeyDown() or InCombatLockdown() then return end
    C_Timer.After(0.3, function()
        local budget = GetMoney() * (M:Opt("budget") or 20) / 100
        local spent = 0
        for _, it in ipairs(M.Plan()) do
            local qty = it.qty
            if spent + qty * it.price > budget then qty = math.floor((budget - spent) / math.max(it.price, 1)) end
            if qty > 0 then
                local maxStack = GetMerchantItemMaxStack(it.index) or qty
                local left = qty
                while left > 0 do
                    local n = math.min(left, maxStack)
                    BuyMerchantItem(it.index, n)
                    left = left - n
                end
                spent = spent + qty * it.price
            end
        end
        if spent > 0 then ns.Print(("Réserves complétées : %s"):format(GetCoinTextureString and GetCoinTextureString(math.floor(spent)) or spent)) end
    end)
end)

function M.preview(p)
    for i, icon in ipairs({ "INV_Misc_Food_15", "INV_Drink_07", "INV_Ammo_Arrow_02" }) do
        local t = p:CreateTexture(nil, "ARTWORK"); t:SetSize(26, 26); t:SetPoint("CENTER", (i - 2) * 36, 6)
        t:SetTexture("Interface\\Icons\\" .. icon)
        local n = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
        n:SetPoint("TOP", t, "BOTTOM", 0, -2); n:SetText(({ "20", "20", "1000" })[i])
    end
end
