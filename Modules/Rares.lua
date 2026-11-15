local _, ns = ...

-- Rares sur la carte du monde : les monstres rares de la zone (données QuestieDB) avec leur niveau,
-- pour les chasser ou les éviter, avec leur butin possible.
local M = ns.RegisterModule({
    id = "rares", category = "safety", default = true,
    name = "Rares sur la carte",
    desc = "Affiche sur la carte du monde les monstres rares de la zone et leur niveau (étoile argentée : rare, dorée : rare élite). Survole une étoile pour le nom et le butin possible (équipement, sacs, recettes ; ceux propres à ce rare en premier). Pour les chasser… ou les éviter.",
    options = {
        { key = "range", label = "Seulement autour de mon niveau (± niveaux)", type = "slider", min = 3, max = 60, step = 1, default = 10 },
        { key = "loot", label = ns.Tr("Butin dans l'infobulle"), type = "check", default = true },
    },
})

local byMap
function M.ForMap(mapID)
    if not byMap then
        byMap = {}
        for _, r in ipairs(ns.World and ns.World.rares or {}) do
            local m = r[2]
            byMap[m] = byMap[m] or {}
            table.insert(byMap[m], { npc = r[1], map = m, x = r[3], y = r[4], min = r[5], max = r[6], rank = r[7], name = r[8] })
        end
    end
    local lvl, range = ns.PlayerLevel(), M:Opt("range") or 10
    local out = {}
    for _, r in ipairs(byMap[mapID] or {}) do
        if r.max >= lvl - range and r.min <= lvl + range then out[#out + 1] = r end
    end
    return out
end

local overlay, pins = nil, {}

---------------------------------------------------------------------------
-- Butin du rare (Data/RareLoot.lua, tiré de QuestieDB) : équipement, sacs et recettes, triés par
-- qualité, ceux propres à ce rare en premier. Les objets pas encore en cache sont demandés au
-- jeu et l'infobulle se met à jour dès qu'ils arrivent.
---------------------------------------------------------------------------
local LOOT_MAX = 10
function M.Loot(npc)
    local raw = ns.RareLoot and ns.RareLoot[npc]
    if not raw then return {} end
    local out = {}
    for id, star in raw:gmatch("(%d+)(%*?)") do out[#out + 1] = { id = tonumber(id), unique = star == "*" } end
    return out
end

local function itemInfo(id)
    local get = C_Item and C_Item.GetItemInfo or GetItemInfo
    if not get then return end
    local name, _, quality, _, _, _, _, _, _, icon = get(id)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return name, quality, icon
end

local function qualityHex(q)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q or 1]
    if c and c.hex then return c.hex end
    return ({ [0] = "|cff9d9d9d", "|cffffffff", "|cff1eff00", "|cff0070dd", "|cffa335ee", "|cffff8000" })[q or 1] or "|cffffffff"
end

local hovered
function M.AddLootLines(tt, npc)
    local loot = M.Loot(npc)
    if #loot == 0 then return 0 end
    local rows, pending = {}, 0
    for _, it in ipairs(loot) do
        local name, quality, icon = itemInfo(it.id)
        if not name then pending = pending + 1 end
        rows[#rows + 1] = { id = it.id, unique = it.unique, name = name, quality = quality or 1, icon = icon }
    end
    table.sort(rows, function(a, b)
        if a.unique ~= b.unique then return a.unique end
        if a.quality ~= b.quality then return a.quality > b.quality end
        return (a.name or "") < (b.name or "")
    end)
    tt:AddLine(" ")
    tt:AddLine(ns.Tr("Butin possible"), 1, 0.82, 0.1)
    for k, r in ipairs(rows) do
        if k > LOOT_MAX then
            tt:AddLine((ns.Tr("… et %d autre(s) objet(s)")):format(#rows - LOOT_MAX), 0.6, 0.6, 0.6)
            break
        end
        local ic = r.icon and ("|T" .. r.icon .. ":14:14:0:0|t ") or ""
        local tag = r.unique and ns.Tr(" |cffffd100(propre à ce rare)|r") or ""
        tt:AddLine(ic .. qualityHex(r.quality) .. (r.name or ("#" .. r.id)) .. "|r" .. tag)
    end
    if pending > 0 then tt:AddLine(ns.Tr("Chargement des objets…"), 0.6, 0.6, 0.6) end
    return pending
end

local function showTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local r = self.rare
    GameTooltip:SetText(r.name, 1, 0.82, 0.1)
    GameTooltip:AddLine(("%s %d%s"):format(ns.Tr("Niveau"), r.min, r.max > r.min and ("-" .. r.max) or ""), 1, 1, 1)
    GameTooltip:AddLine(r.rank == 2 and ns.Tr("Rare élite") or ns.Tr("Rare"), 0.7, 0.7, 0.7)
    if M:Opt("loot") ~= false then M.AddLootLines(GameTooltip, r.npc) end
    GameTooltip:Show()
end

-- un objet du butin vient d'arriver dans le cache : on redessine l'infobulle survolée
local refresh = CreateFrame("Frame")
refresh:RegisterEvent("GET_ITEM_INFO_RECEIVED")
refresh:SetScript("OnEvent", function()
    if hovered and hovered:IsVisible() and GameTooltip:IsOwned(hovered) then showTooltip(hovered) end
end)
local function pin(i)
    local p = pins[i]
    if not p then
        p = CreateFrame("Frame", nil, overlay)
        p.t = p:CreateTexture(nil, "OVERLAY")
        p.t:SetAllPoints()
        p.t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        p:EnableMouse(true)
        p:SetScript("OnEnter", function(self) hovered = self; showTooltip(self) end)
        p:SetScript("OnLeave", function() hovered = nil; GameTooltip:Hide() end)
        pins[i] = p
    end
    return p
end

local function draw()
    for _, p in ipairs(pins) do p:Hide() end
    if not (M.enabled and WorldMapFrame and WorldMapFrame:IsShown()) then return end
    local canvas = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
    if not canvas then return end
    if not overlay then
        overlay = CreateFrame("Frame", nil, canvas)
        overlay:SetAllPoints(canvas)
        overlay:SetFrameLevel(canvas:GetFrameLevel() + 1995)
    end
    local W, H = overlay:GetWidth(), overlay:GetHeight()
    if not (W and W > 0) then return end
    local scale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1
    for k, r in ipairs(M.ForMap(WorldMapFrame:GetMapID())) do
        local p = pin(k)
        p.rare = r
        p:SetSize(16 / scale, 16 / scale)
        p.t:SetVertexColor(r.rank == 2 and 1 or 0.8, r.rank == 2 and 0.82 or 0.8, r.rank == 2 and 0.1 or 0.85)
        p:ClearAllPoints()
        p:SetPoint("CENTER", overlay, "TOPLEFT", r.x / 100 * W, -r.y / 100 * H)
        p:Show()
    end
end
M.Draw = draw
local acc, ticker = 0, CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc < 0.5 then return end
    acc = 0
    if M.enabled and WorldMapFrame and WorldMapFrame:IsShown() then draw() end
end)
function M:OnEnable() draw() end
function M:OnDisable() draw() end

function M.preview(p)
    local bg = p:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.3, 0.26, 0.16, 1)
    for k, pos in ipairs({ { 45, 40 }, { 100, 55 } }) do
        local t = p:CreateTexture(nil, "OVERLAY"); t:SetSize(16, 16)
        t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        if k == 2 then t:SetVertexColor(0.8, 0.8, 0.85) end
        t:SetPoint("CENTER", p, "TOPLEFT", pos[1], -pos[2])
    end
end
