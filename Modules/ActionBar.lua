local _, ns = ...

-- Barre d'actions : un seul cadre qui regroupe les boutons sécurisés (Cibler, Objet de quête...).
-- Les boutons sécurisés ne peuvent être placés qu'hors combat : la mise en page attend la fin
-- du combat si besoin, et la barre ne se déplace pas en combat.
local M = ns.RegisterModule({
    id = "actionbar", category = "look", default = true, locked = true,
    name = "Barre d'actions",
    desc = "Regroupe les boutons « Cibler » et « Objet de quête » dans un même cadre. Glisse la poignée pour la déplacer.",
    options = {
        { key = "vertical", label = "Disposition verticale", type = "check", default = false },
        { key = "size", label = "Taille des boutons", type = "slider", min = 24, max = 56, step = 2, default = 36 },
        { key = "spacing", label = "Espacement", type = "slider", min = 0, max = 16, step = 1, default = 4 },
        { key = "handle", label = "Toujours afficher la poignée", type = "check", default = false },
    },
})
ns.ActionBar = M

local bar = CreateFrame("Frame", "ForeverPathActionBar", UIParent)
bar:SetSize(40, 40)
bar:SetClampedToScreen(true)
bar:SetMovable(true)
M.frame = bar

-- poignée de déplacement (à gauche ou au-dessus de la barre)
local handle = CreateFrame("Frame", nil, bar, "BackdropTemplate")
handle:SetSize(10, 36)
handle:EnableMouse(true)
handle:RegisterForDrag("LeftButton")
ns.Skin(handle, 0.8)
handle.grip = handle:CreateTexture(nil, "ARTWORK")
handle.grip:SetTexture(ns.MEDIA .. "chevron")
handle.grip:SetSize(8, 8)
handle.grip:SetPoint("CENTER")
handle:SetScript("OnDragStart", function()
    if not InCombatLockdown() and not ns.db.locked then bar:StartMoving() end
end)
handle:SetScript("OnDragStop", function()
    bar:StopMovingOrSizing()
    local p, _, rp, x, y = bar:GetPoint()
    ns.db.frames.actionbar = { p, rp, x, y }
end)
handle:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Barre d'actions ForeverPath", 1, 1, 1)
    GameTooltip:AddLine("Glisser pour déplacer (hors combat)", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Réglages : /fp config > Barre d'actions", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
handle:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    if not M:Opt("handle") then self:SetAlpha(0.15) end
end)

local buttons = {}   -- { button, order }
local dirty = false

-- Les modules y inscrivent leurs boutons ; ils gardent la main sur Show/Hide (hors combat).
function M:Register(button, order)
    buttons[#buttons + 1] = { b = button, order = order or 50 }
    table.sort(buttons, function(a, b) return a.order < b.order end)
    button:SetMovable(false)
end

function M:Layout()
    if InCombatLockdown() then dirty = true return end
    dirty = false
    local size, gap = self:Opt("size") or 36, self:Opt("spacing") or 4
    local vertical = self:Opt("vertical")
    local n = 0
    for _, e in ipairs(buttons) do
        local b = e.b
        b:SetSize(size, size)
        b:ClearAllPoints()
        if b:IsShown() then
            local off = n * (size + gap)
            if vertical then b:SetPoint("TOP", bar, "TOP", 0, -off)
            else b:SetPoint("LEFT", bar, "LEFT", off, 0) end
            n = n + 1
        else
            b:SetPoint("CENTER", bar, "CENTER")
        end
    end
    local len = math.max(1, n) * size + math.max(0, n - 1) * gap
    if vertical then bar:SetSize(size, len) else bar:SetSize(len, size) end
    handle:ClearAllPoints()
    if vertical then
        handle:SetSize(size, 10)
        handle:SetPoint("BOTTOM", bar, "TOP", 0, 3)
    else
        handle:SetSize(10, size)
        handle:SetPoint("RIGHT", bar, "LEFT", -3, 0)
    end
    handle:SetShown(n > 0)
    handle:SetAlpha(self:Opt("handle") and 1 or 0.15)
end

function M:OnOptionChanged() self:Layout() end
M:On("PLAYER_REGEN_ENABLED", function() if dirty then M:Layout() end end)
M:On("FP_READY", function() M:Layout() end)

ns.On("FP_INIT", function()
    local p = ns.db.frames.actionbar or { "CENTER", "CENTER", 0, -170 }
    bar:ClearAllPoints()
    bar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end)

function M.preview(p)
    local x = -24
    for _, icon in ipairs({ "Ability_Hunter_SniperShot", "INV_Potion_51", "INV_Misc_Bone_HumanSkull_01" }) do
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(26, 26)
        t:SetPoint("CENTER", x, 6)
        t:SetTexture("Interface\\Icons\\" .. icon)
        x = x + 29
    end
    local h = p:CreateTexture(nil, "ARTWORK")
    h:SetSize(6, 26)
    h:SetPoint("CENTER", -45, 6)
    h:SetColorTexture(1, 1, 1, 0.3)
    local k = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallDim")
    k:SetPoint("BOTTOM", 0, 6)
    k:SetText("Un seul cadre, déplaçable")
end
