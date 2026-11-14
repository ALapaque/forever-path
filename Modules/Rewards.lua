local _, ns = ...

-- Récompenses de quête : flèche verte sur les améliorations utilisables, pièce sur la plus chère à revendre.
local M = ns.RegisterModule({
    id = "rewards", category = "comfort", default = true,
    name = "Conseil de récompense",
    desc = "Au rendu d'une quête, signale l'objet qui t'améliore (flèche verte) et celui qui se vend le plus cher (pièce d'or).",
    options = {},
})

local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 },
}

local marks = {}
local function mark(button, kind)
    local m = marks[button]
    if not m then
        m = button:CreateTexture(nil, "OVERLAY")
        m:SetSize(18, 18)
        m:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
        marks[button] = m
    end
    if kind == "up" then
        m:SetTexture("Interface\\Buttons\\UI-MicroStream-Green")
        m:SetTexCoord(0, 1, 1, 0) -- flèche vers le haut
    elseif kind == "gold" then
        m:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
        m:SetTexCoord(0, 1, 0, 1)
    end
    m:SetShown(kind ~= nil)
end

local function equippedLevel(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then return 0 end
    return C_Item.GetDetailedItemLevelInfo(link) or 0
end

local function evaluate()
    local n = GetNumQuestChoices()
    for _, m in pairs(marks) do m:Hide() end
    if n < 2 then return end
    local bestGold, bestGoldIdx = -1
    local up = {}
    for i = 1, n do
        local link = GetQuestItemLink("choice", i)
        if link then
            local _, _, _, _, _, _, _, _, equipLoc, _, sell = C_Item.GetItemInfo(link)
            if sell and sell > bestGold then bestGold, bestGoldIdx = sell, i end
            local slots = SLOTS[equipLoc or ""]
            local id = C_Item.GetItemInfoInstant(link)
            local usable = id and (not C_PlayerInfo.CanUseItem or C_PlayerInfo.CanUseItem(id))
            if slots and usable then
                local ilvl = C_Item.GetDetailedItemLevelInfo(link) or 0
                local worst = math.huge
                for _, s in ipairs(slots) do worst = math.min(worst, equippedLevel(s)) end
                if ilvl > worst then up[i] = true end
            end
        end
    end
    for i = 1, n do
        local button = QuestInfo_GetRewardButton and QuestInfo_GetRewardButton(QuestInfoFrame.rewardsFrame, i)
        if button then
            mark(button, up[i] and "up" or (i == bestGoldIdx and "gold") or nil)
        end
    end
end

M:On("QUEST_COMPLETE", function() C_Timer.After(0.1, function() pcall(evaluate) end) end)
M:On("GET_ITEM_INFO_RECEIVED", function() if QuestFrame and QuestFrame:IsShown() then pcall(evaluate) end end)

function M.preview(p)
    for i, icon in ipairs({ "INV_Chest_Leather_09", "INV_Sword_04", "INV_Jewelry_Ring_02" }) do
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(30, 30)
        t:SetPoint("CENTER", (i - 2) * 40, 4)
        t:SetTexture("Interface\\Icons\\" .. icon)
        if i == 1 then
            local m = p:CreateTexture(nil, "OVERLAY")
            m:SetSize(16, 16); m:SetPoint("TOPLEFT", t, -4, 4)
            m:SetTexture("Interface\\Buttons\\UI-MicroStream-Green"); m:SetTexCoord(0, 1, 1, 0)
        elseif i == 3 then
            local m = p:CreateTexture(nil, "OVERLAY")
            m:SetSize(14, 14); m:SetPoint("TOPLEFT", t, -4, 4)
            m:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
        end
    end
end
