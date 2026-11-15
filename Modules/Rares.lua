local _, ns = ...

-- Rares sur la carte du monde : les monstres rares de la zone (données QuestieDB) avec leur niveau,
-- pour les chasser ou les éviter (Hardcore).
local M = ns.RegisterModule({
    id = "rares", category = "safety", default = true,
    name = "Rares sur la carte",
    desc = "Affiche sur la carte du monde les monstres rares de la zone et leur niveau (étoile argentée : rare, dorée : rare élite). Survole pour le nom. Pour les chasser… ou les éviter.",
    options = {
        { key = "range", label = "Seulement autour de mon niveau (± niveaux)", type = "slider", min = 3, max = 60, step = 1, default = 10 },
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
local function pin(i)
    local p = pins[i]
    if not p then
        p = CreateFrame("Frame", nil, overlay)
        p.t = p:CreateTexture(nil, "OVERLAY")
        p.t:SetAllPoints()
        p.t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        p:EnableMouse(true)
        p:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local r = self.rare
            GameTooltip:SetText(r.name, 1, 0.82, 0.1)
            GameTooltip:AddLine(("%s %d%s"):format(ns.Tr("Niveau"), r.min, r.max > r.min and ("-" .. r.max) or ""), 1, 1, 1)
            GameTooltip:AddLine(r.rank == 2 and ns.Tr("Rare élite") or ns.Tr("Rare"), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        p:SetScript("OnLeave", function() GameTooltip:Hide() end)
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
