local _, ns = ...

-- Tracé de la route sur la carte du monde : pointillés depuis ta position, puis étapes
-- suivantes numérotées (prendre / faire / rendre), uniquement sur la carte affichée.
local M = ns.RegisterModule({
    id = "maproute", category = "nav", default = true,
    name = "Tracé de la route sur la carte",
    desc = "Sur la carte du monde : un tracé en pointillés depuis ta position et les prochaines étapes numérotées, pour voir le chemin d'un coup d'œil.",
    options = {
        { key = "count", label = "Étapes tracées", type = "slider", min = 2, max = 12, step = 1, default = 6 },
        { key = "fromPlayer", label = "Partir de ma position", type = "check", default = true },
    },
})

local COLORS = {
    accept = { 1, 0.82, 0.1 }, complete = { 1, 0.5, 0.25 }, turnin = { 0.25, 0.85, 0.3 },
    ["goto"] = { 0.4, 0.8, 1 }, default = { 0.85, 0.85, 0.85 },
}

local overlay, pins, dots = nil, {}, {}

local function canvas()
    return WorldMapFrame and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
end

local function ensureOverlay()
    if overlay then return overlay end
    local c = canvas()
    if not c then return end
    overlay = CreateFrame("Frame", nil, c)
    overlay:SetAllPoints(c)
    overlay:SetFrameLevel(c:GetFrameLevel() + 2000)
    return overlay
end

local function pin(i)
    local p = pins[i]
    if not p then
        p = CreateFrame("Frame", nil, overlay)
        p:SetSize(22, 22)
        p.bg = p:CreateTexture(nil, "ARTWORK")
        p.bg:SetAllPoints()
        p.bg:SetTexture(ns.MEDIA .. "dot")
        p.ring = p:CreateTexture(nil, "BACKGROUND")
        p.ring:SetPoint("TOPLEFT", -2, 2)
        p.ring:SetPoint("BOTTOMRIGHT", 2, -2)
        p.ring:SetTexture(ns.MEDIA .. "dot")
        p.ring:SetVertexColor(0, 0, 0, 0.8)
        p.num = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
        p.num:SetPoint("CENTER", 0, 0)
        p.num:SetTextColor(0, 0, 0)
        p:EnableMouse(true)
        p:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.label or "", 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        p:SetScript("OnLeave", function() GameTooltip:Hide() end)
        pins[i] = p
    end
    return p
end

local function dot(i)
    local d = dots[i]
    if not d then
        d = overlay:CreateTexture(nil, "OVERLAY")
        d:SetTexture(ns.MEDIA .. "dot")
        dots[i] = d
    end
    return d
end

function M:Draw()
    for _, p in ipairs(pins) do p:Hide() end
    for _, d in ipairs(dots) do d:Hide() end
    if not (self.enabled and WorldMapFrame and WorldMapFrame:IsShown()) then return end
    if not ensureOverlay() then return end
    local mapID = WorldMapFrame:GetMapID()
    local W, H = overlay:GetWidth(), overlay:GetHeight()
    if not (W and W > 0) then return end
    local scale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1
    local size = 20 / scale

    -- itinéraire calculé (module Itinéraires) : tracé coloré jusqu'à l'étape en cours
    local nd = 0
    local gap = 9 / scale
    local journeyLines = ns.Journeys and ns.Journeys:Polylines() or {}
    for _, seg in ipairs(journeyLines) do
        local a, b = seg.pts[1], seg.pts[2]
        local _, ax, ay = ns.Nav.ToMap(a.c, a.x, a.y, mapID)
        local _, bx, by = ns.Nav.ToMap(b.c, b.x, b.y, mapID)
        if ax and bx and math.max(ax, bx) > -0.05 and math.min(ax, bx) < 1.05
            and math.max(ay, by) > -0.05 and math.min(ay, by) < 1.05 then
            local x1, y1, x2, y2 = ax * W, ay * H, bx * W, by * H
            local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
            local steps = math.max(1, math.floor(len / gap))
            for t = 0, steps do
                nd = nd + 1
                if nd > 600 then break end
                local d = dot(nd)
                local f = t / steps
                d:SetSize(6 / scale, 6 / scale)
                d:ClearAllPoints()
                d:SetPoint("CENTER", overlay, "TOPLEFT", x1 + (x2 - x1) * f, -(y1 + (y2 - y1) * f))
                d:SetVertexColor(seg.color[1], seg.color[2], seg.color[3], 1)
                d:Show()
            end
        end
    end

    -- points à relier : position du joueur (si sur cette carte) puis étapes suivantes
    -- (avec un itinéraire, le premier tronçon est déjà tracé ci-dessus)
    local pts = {}
    if self:Opt("fromPlayer") and #journeyLines == 0 then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local px, py = pos:GetXY()
            if px and px > 0 then pts[#pts + 1] = { x = px, y = py } end
        end
    end
    local g, _, i = ns.Engine.Current()
    if not g then return end
    local n, max = 0, self:Opt("count") or 6
    for j = i, #g.steps do
        local s = g.steps[j]
        if s.x and ns.Engine.Applies(s) and (j == i or not ns.Engine.IsDone(s, j)) then
            if ns.Geo.StepMap(s) ~= mapID then break end   -- on ne trace que la carte affichée
            n = n + 1
            pts[#pts + 1] = { x = s.x / 100, y = s.y / 100, step = s, n = n }
            if n >= max then break end
        end
    end

    -- pointillés entre les étapes suivantes
    for k = 2, #pts do
        local a, b = pts[k - 1], pts[k]
        local ax, ay, bx, by = a.x * W, a.y * H, b.x * W, b.y * H
        local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
        local steps = math.floor(len / gap)
        for t = 1, steps - 1 do
            nd = nd + 1
            if nd > 400 then break end
            local d = dot(nd)
            local f = t / steps
            d:SetSize(5 / scale, 5 / scale)
            d:ClearAllPoints()
            d:SetPoint("CENTER", overlay, "TOPLEFT", ax + (bx - ax) * f, -(ay + (by - ay) * f))
            local c = COLORS[b.step and b.step.type] or COLORS.default
            d:SetVertexColor(c[1], c[2], c[3], k == 2 and 1 or 0.75)
            d:Show()
        end
    end

    -- étapes numérotées
    for _, p in ipairs(pts) do
        if p.step then
            local pi = pin(p.n)
            local c = COLORS[p.step.type] or COLORS.default
            pi:SetSize(size, size)
            pi:ClearAllPoints()
            pi:SetPoint("CENTER", overlay, "TOPLEFT", p.x * W, -p.y * H)
            pi.bg:SetVertexColor(c[1], c[2], c[3])
            pi.num:SetText(p.n)
            pi.num:SetScale(1 / scale)
            pi.label = ns.Guide and ns.Guide.StepLabel(p.step) or ""
            pi:Show()
        end
    end
end

-- La carte zoome / change : on redessine régulièrement tant qu'elle est ouverte (léger : < 20 éléments + pointillés)
local ticker = CreateFrame("Frame")
local acc = 0
ticker:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc < 0.2 then return end
    acc = 0
    if M.enabled and WorldMapFrame and WorldMapFrame:IsShown() then M:Draw() end
end)

function M:OnEnable() self:Draw() end
function M:OnDisable() self:Draw() end
function M:OnOptionChanged() self:Draw() end
M:On("FP_STEP_CHANGED", function() M:Draw() end)

function M.preview(p)
    local bg = p:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.33, 0.27, 0.16, 1)
    local pts = { { 20, 70 }, { 55, 40 }, { 95, 58 }, { 128, 22 } }
    local cols = { COLORS.accept, COLORS.complete, COLORS.turnin }
    for k = 2, #pts do
        local a, b = pts[k - 1], pts[k]
        for t = 1, 5 do
            local d = p:CreateTexture(nil, "ARTWORK")
            d:SetTexture(ns.MEDIA .. "dot")
            d:SetSize(4, 4)
            local f = t / 6
            d:SetPoint("CENTER", p, "TOPLEFT", a[1] + (b[1] - a[1]) * f, -(a[2] + (b[2] - a[2]) * f))
            local c = cols[k - 1]
            d:SetVertexColor(c[1], c[2], c[3])
        end
        local pi = p:CreateTexture(nil, "OVERLAY")
        pi:SetTexture(ns.MEDIA .. "dot")
        pi:SetSize(14, 14)
        pi:SetPoint("CENTER", p, "TOPLEFT", b[1], -b[2])
        local c = cols[k - 1]
        pi:SetVertexColor(c[1], c[2], c[3])
        local num = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
        num:SetPoint("CENTER", pi, "CENTER")
        num:SetTextColor(0, 0, 0)
        num:SetText(k - 1)
    end
end
