local _, ns = ...

-- Tracé de la route sur la carte du monde : pointillés depuis ta position, puis étapes
-- suivantes numérotées (prendre / faire / rendre), uniquement sur la carte affichée.
local M = ns.RegisterModule({
    id = "maproute", category = "nav", default = true,
    name = ns.Tr("Tracé de la route sur la carte"),
    desc = ns.Tr("Sur la carte du monde : un tracé en pointillés depuis ta position et les prochaines étapes numérotées, pour voir le chemin d'un coup d'œil."),
    options = {
        { key = "count", label = ns.Tr("Étapes tracées"), type = "slider", min = 2, max = 12, step = 1, default = 6 },
        { key = "fromPlayer", label = ns.Tr("Partir de ma position"), type = "check", default = true },
    },
})

local COLORS = {
    accept = { 1, 0.82, 0.1 }, complete = { 1, 0.5, 0.25 }, turnin = { 0.25, 0.85, 0.3 },
    ["goto"] = { 0.4, 0.8, 1 }, default = { 0.85, 0.85, 0.85 },
}

M.COLORS = COLORS
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
        p.num = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
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

-- Deux réserves de points : le corps du tracé (calculé une fois par trajet / étape / carte) et
-- la « tête » (du joueur au prochain point), la seule partie qui bouge quand on avance.
local headDots = {}
local function texture(pool, i)
    local d = pool[i]
    if not d then
        d = overlay:CreateTexture(nil, "OVERLAY")
        d:SetTexture(ns.MEDIA .. "dot")
        pool[i] = d
    end
    return d
end

local MAX_DOTS = 450        -- au-delà, on espace les points plutôt que d'en ajouter

-- Pose des points tous les `gap` pixels le long d'une polyligne (en pixels du canevas),
-- en reportant le reste d'un segment au suivant : espacement régulier, pas de doublons aux coins.
local function along(out, poly, gap, color, alpha, sizePx, skipFirst)
    local nextAt = skipFirst and gap or 0       -- distance, dans le segment, du prochain point
    for k = 2, #poly do
        local ax, ay, bx, by = poly[k - 1][1], poly[k - 1][2], poly[k][1], poly[k][2]
        local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
        local t = nextAt
        while t <= len do
            local f = len > 0 and t / len or 0
            out[#out + 1] = { ax + (bx - ax) * f, ay + (by - ay) * f, color, alpha, sizePx }
            t = t + gap
        end
        nextAt = t - len
    end
end

local function polyLength(poly)
    local L = 0
    for k = 2, #poly do L = L + math.sqrt((poly[k][1] - poly[k - 1][1]) ^ 2 + (poly[k][2] - poly[k - 1][2]) ^ 2) end
    return L
end

local cache = { key = nil, scale = nil, body = {}, pts = {}, nBody = 0, head = nil, headKey = nil }
M.cache = cache

local function hideAll()
    for _, p in ipairs(pins) do p:Hide() end
    for _, d in ipairs(dots) do d:Hide() end
    for _, d in ipairs(headDots) do d:Hide() end
    cache.key, cache.scale, cache.headKey = nil, nil, nil
end

-- Clé de ce qui change le corps du tracé : carte affichée, trajet, étape, réglages
local function bodyKey(mapID, W)
    local g, _, i = ns.Engine.Current()
    local jv = ns.Journeys and ns.Journeys.enabled and ns.Journeys.version or 0
    return table.concat({ mapID or 0, math.floor(W or 0), jv, g and g.id or "-", i or 0,
        M:Opt("count") or 6, M:Opt("fromPlayer") and 1 or 0 }, ":")
end

-- Calcule (une fois) le corps du tracé : itinéraire puis étapes suivantes, en pixels du canevas
local function buildBody(mapID, W, H, scale)
    local body, pts = {}, {}
    cache.headTarget, cache.headColor = nil, nil
    local polys = {}
    -- itinéraire calculé (module Itinéraires)
    local journeyLines = ns.Journeys and ns.Journeys:Polylines() or {}
    cache.hasJourney = #journeyLines > 0
    local run, runColor
    local function flush()
        if run and #run > 1 then polys[#polys + 1] = { pts = run, color = runColor, alpha = 1, size = 6 } end
        run, runColor = nil, nil
    end
    for _, seg in ipairs(journeyLines) do
        local a, b = seg.pts[1], seg.pts[2]
        if seg.head then
            -- tête : redessinée à part, à chaque déplacement du joueur
            local _, bx, by = ns.Nav.ToMap(b.c, b.x, b.y, mapID)
            if bx then cache.headTarget, cache.headColor = { map = mapID, mx = bx, my = by }, seg.color end
        else
            local _, ax, ay = ns.Nav.ToMap(a.c, a.x, a.y, mapID)
            local _, bx, by = ns.Nav.ToMap(b.c, b.x, b.y, mapID)
            if ax and bx and math.max(ax, bx) > -0.05 and math.min(ax, bx) < 1.05
                and math.max(ay, by) > -0.05 and math.min(ay, by) < 1.05 then
                if run and runColor == seg.color and run[#run][1] == ax * W and run[#run][2] == ay * H then
                    run[#run + 1] = { bx * W, by * H }
                else
                    flush()
                    run, runColor = { { ax * W, ay * H }, { bx * W, by * H } }, seg.color
                end
            else
                flush()
            end
        end
    end
    flush()

    -- étapes suivantes sur la carte affichée
    local g, _, i = ns.Engine.Current()
    if g then
        local n, max = 0, M:Opt("count") or 6
        for j = i, #g.steps do
            local st = g.steps[j]
            if st.x and ns.Engine.Applies(st) and (j == i or not ns.Engine.IsDone(st, j)) then
                if ns.Geo.StepMap(st) ~= mapID then break end   -- on ne trace que la carte affichée
                n = n + 1
                pts[#pts + 1] = { x = st.x / 100, y = st.y / 100, step = st, n = n }
                if n >= max then break end
            end
        end
    end
    for k = 2, #pts do
        local a, b = pts[k - 1], pts[k]
        polys[#polys + 1] = { pts = { { a.x * W, a.y * H }, { b.x * W, b.y * H } },
            color = COLORS[b.step.type] or COLORS.default, alpha = 0.75, size = 5, skipFirst = true }
    end
    if #pts > 0 and not cache.hasJourney and M:Opt("fromPlayer") then
        cache.headTarget = { map = mapID, mx = pts[1].x, my = pts[1].y }
        cache.headColor = COLORS[pts[1].step.type] or COLORS.default
    end

    -- espacement : 9 px à l'écran, élargi si le tracé est très long (trajets lointains)
    local total = 0
    for _, pl in ipairs(polys) do total = total + polyLength(pl.pts) end
    local gap = math.max(9 / scale, total / MAX_DOTS)
    for _, pl in ipairs(polys) do along(body, pl.pts, gap, pl.color, pl.alpha, pl.size, pl.skipFirst) end
    cache.body, cache.pts, cache.gap = body, pts, gap
end

local function paintBody(scale)
    local body = cache.body
    for k, e in ipairs(body) do
        local d = texture(dots, k)
        d:SetSize(e[5] / scale, e[5] / scale)
        d:ClearAllPoints()
        d:SetPoint("CENTER", overlay, "TOPLEFT", e[1], -e[2])
        d:SetVertexColor(e[3][1], e[3][2], e[3][3], e[4])
        d:Show()
    end
    for k = #body + 1, #dots do dots[k]:Hide() end
end

local function resizeBody(scale)
    for k, e in ipairs(cache.body) do dots[k]:SetSize(e[5] / scale, e[5] / scale) end
end

-- Tête : du joueur au prochain point. Recalculée seulement si le joueur a bougé.
local function drawHead(mapID, W, H, scale)
    local tgt = cache.headTarget
    local n = 0
    if tgt then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        local px, py
        if pos then px, py = pos:GetXY() end
        if px and not ns.IsSecret(px) and px > 0 then
            local tx, ty = tgt.mx, tgt.my
            if tgt.c and (tgt.map ~= mapID or not tx) then
                local _, x, y = ns.Nav.ToMap(tgt.c, tgt.x, tgt.y, mapID)
                tx, ty = x, y
            end
            if tx then
                local hk = ("%d:%d:%d:%.3f"):format(math.floor(px * W / 2), math.floor(py * H / 2), mapID, scale)
                if hk == cache.headKey then return end
                cache.headKey = hk
                local out = {}
                along(out, { { px * W, py * H }, { tx * W, ty * H } }, cache.gap or 9 / scale,
                    cache.headColor or COLORS.default, 1, cache.hasJourney and 6 or 5, true)
                for k, e in ipairs(out) do
                    if k > 120 then break end
                    n = k
                    local d = texture(headDots, k)
                    d:SetSize(e[5] / scale, e[5] / scale)
                    d:ClearAllPoints()
                    d:SetPoint("CENTER", overlay, "TOPLEFT", e[1], -e[2])
                    d:SetVertexColor(e[3][1], e[3][2], e[3][3], e[4])
                    d:Show()
                end
            end
        end
    end
    if n == 0 then cache.headKey = nil end
    for k = n + 1, #headDots do headDots[k]:Hide() end
end

local function drawPins(W, H, scale)
    for _, p in ipairs(pins) do p:Hide() end
    local size = 20 / scale
    -- étapes numérotées : les étapes au même endroit (ou qui se chevauchent à ce zoom) sont
    -- regroupées en une seule pastille « 2-4 » ; la liste complète est dans l'infobulle.
    local groups = {}
    local near = size * 0.9
    for _, p in ipairs(cache.pts) do
        local sx, sy = p.x * W, p.y * H
        local into
        for _, gr in ipairs(groups) do
            if math.abs(gr.x - sx) < near and math.abs(gr.y - sy) < near then into = gr break end
        end
        if into then
            into.items[#into.items + 1] = p
        else
            groups[#groups + 1] = { x = sx, y = sy, items = { p } }
        end
    end
    for gi, gr in ipairs(groups) do
        local first = gr.items[1]
        local nums = {}
        for _, it in ipairs(gr.items) do nums[#nums + 1] = it.n end
        local pi = pin(gi)
        local c = COLORS[first.step.type] or COLORS.default
        local current = first.n == 1
        pi.num:SetScale(1 / scale)
        pi.num:SetText(M.Label(nums))
        local textW = (pi.num:GetStringWidth() or 0) / scale
        local h = current and size * 1.25 or size
        pi:SetSize(math.max(h, textW + 10 / scale), h)
        pi:ClearAllPoints()
        pi:SetPoint("CENTER", overlay, "TOPLEFT", gr.x, -gr.y)
        pi:SetFrameLevel(overlay:GetFrameLevel() + 100 - gi)      -- l'étape en cours au-dessus
        pi.bg:SetVertexColor(c[1], c[2], c[3])
        pi.ring:SetVertexColor(current and 1 or 0, current and 1 or 0, current and 1 or 0, current and 1 or 0.8)
        local lines = {}
        for _, it in ipairs(gr.items) do
            local ic = COLORS[it.step.type] or COLORS.default
            lines[#lines + 1] = ("|cff%02x%02x%02x%d.|r %s"):format(ic[1] * 255, ic[2] * 255, ic[3] * 255, it.n,
                ns.Guide and ns.Guide.StepLabel(it.step) or "")
        end
        pi.label = table.concat(lines, "\n")
        pi:Show()
    end
end

-- Dessin : le corps n'est recalculé que si la carte, le trajet ou l'étape changent ; un zoom
-- ne fait que redimensionner les points ; seule la tête suit le joueur.
function M:Draw(force)
    if not (self.enabled and WorldMapFrame and WorldMapFrame:IsShown()) then hideAll() return end
    if not ensureOverlay() then return end
    local mapID = WorldMapFrame:GetMapID()
    local W, H = overlay:GetWidth(), overlay:GetHeight()
    if not (W and W > 0) then return end
    local scale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1
    local key = bodyKey(mapID, W)
    local rebuilt = false
    if force or key ~= cache.key then
        cache.key, cache.scale, cache.headKey = key, nil, nil
        buildBody(mapID, W, H, scale)
        paintBody(scale)
        rebuilt = true
        M.builds = (M.builds or 0) + 1
    end
    if rebuilt or not cache.scale or math.abs(scale - cache.scale) / cache.scale > 0.04 then
        if not rebuilt then resizeBody(scale) end
        cache.scale = scale
        cache.headKey = nil
        drawPins(W, H, scale)
    end
    drawHead(mapID, W, H, scale)
end

-- { 2, 3, 4, 8 } -> "2-4, 8" (au-delà de deux morceaux : "2-4+")
function M.Label(nums)
    table.sort(nums)
    local parts, a, b = {}, nums[1], nums[1]
    for k = 2, #nums + 1 do
        local v = nums[k]
        if v and v == b + 1 then
            b = v
        else
            parts[#parts + 1] = a == b and tostring(a) or (b == a + 1 and (a .. "," .. b) or (a .. "-" .. b))
            a, b = v, v
        end
    end
    if #parts > 2 then return parts[1] .. "+" end
    return table.concat(parts, ",")
end

-- Tant que la carte est ouverte : vérification légère toutes les 0,2 s (le corps n'est refait
-- que si quelque chose a changé ; sinon seuls le zoom et la tête sont suivis).
local ticker = CreateFrame("Frame")
local acc = 0
ticker:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc < 0.2 then return end
    acc = 0
    if M.enabled and WorldMapFrame and WorldMapFrame:IsShown() then M:Draw() end
end)

function M:OnEnable() self:Draw(true) end
function M:OnDisable() self:Draw() end
function M:OnOptionChanged() self:Draw(true) end
M:On("FP_STEP_CHANGED", function() M:Draw(true) end)

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
        local num = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
        num:SetPoint("CENTER", pi, "CENTER")
        num:SetTextColor(0, 0, 0)
        num:SetText(k - 1)
    end
end
