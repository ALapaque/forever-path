local _, ns = ...
local Nav = ns.Nav

-- Récolte sur la route : sur la carte du monde, les filons et herbes accessibles à ton niveau de
-- métier, uniquement le long du trajet des prochaines étapes (données QuestieDB).
local M = ns.RegisterModule({
    id = "gather", category = "nav", default = true,
    name = "Récolte sur la route",
    desc = "Si tu es mineur ou herboriste : affiche sur la carte du monde les filons et les herbes que tu peux récolter, seulement le long du trajet vers tes prochaines étapes.",
    options = {
        { key = "corridor", label = "Largeur du couloir (yards)", type = "slider", min = 40, max = 300, step = 20, default = 120 },
        { key = "steps", label = "Étapes couvertes", type = "slider", min = 1, max = 12, step = 1, default = 5 },
        { key = "grey", label = "Montrer aussi les points trop faciles", type = "check", default = true },
    },
})

local SKILL = { [186] = "mine", [182] = "herb" }
local ICON = { mine = "Interface\\Icons\\INV_Ore_Copper_01", herb = "Interface\\Icons\\INV_Misc_Flower_02" }

-- métiers de récolte du joueur : { mine = rang, herb = rang }
function M.Skills()
    local out = {}
    if not GetProfessions then return out end
    for _, idx in ipairs({ GetProfessions() }) do
        if idx then
            local _, _, rank, _, _, _, line = GetProfessionInfo(idx)
            if SKILL[line] then out[SKILL[line]] = rank or 0 end
        end
    end
    return out
end

-- points d'une carte décodés (et mis en cache) : { kind, skill, name, x, y (0..1) }
local cache = {}
function M.Nodes(mapID)
    local c = cache[mapID]
    if c then return c end
    c = {}
    for _, e in ipairs(ns.World and ns.World.nodes and ns.World.nodes[mapID] or {}) do
        local s = e[4]
        for k = 1, #s - 5, 6 do
            c[#c + 1] = { kind = e[1], skill = e[2], name = e[3],
                x = tonumber(s:sub(k, k + 2)) / 1000, y = tonumber(s:sub(k + 3, k + 5)) / 1000 }
        end
    end
    cache[mapID] = c
    return c
end

-- distance d'un point à un segment (coordonnées monde)
local function segDist(p, a, b)
    local dx, dy = b.x - a.x, b.y - a.y
    local l2 = dx * dx + dy * dy
    local t = l2 > 0 and math.max(0, math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / l2)) or 0
    local qx, qy = a.x + t * dx - p.x, a.y + t * dy - p.y
    return math.sqrt(qx * qx + qy * qy)
end

-- trajet (monde) : joueur puis prochaines étapes sur le même continent
function M.Route(n)
    local pts = {}
    local me = Nav.Player()
    if me then pts[1] = me end
    local g, _, i = ns.Engine.Current()
    if not g then return pts end
    local cont = me and me.c
    for j = i, #g.steps do
        local s = g.steps[j]
        if s.x and ns.Engine.Applies(s) and (j == i or not ns.Engine.IsDone(s, j)) then
            local p = Nav.StepPoint(s)
            if p and (not cont or p.c == cont) then
                cont = p.c
                pts[#pts + 1] = p
                if #pts > n then break end
            end
        end
    end
    return pts
end

-- points à afficher sur une carte
function M.Visible(mapID)
    local skills = M.Skills()
    if not (skills.mine or skills.herb) then return {} end
    local route = M.Route(M:Opt("steps") or 5)
    if #route < 2 then return {} end
    local width = M:Opt("corridor") or 120
    local out = {}
    for _, nd in ipairs(M.Nodes(mapID)) do
        local rank = skills[nd.kind]
        if rank and nd.skill <= rank and (M:Opt("grey") or nd.skill + 100 > rank) then
            local c, wx, wy = Nav.ToWorld(mapID, nd.x, nd.y)
            if c and c == route[1].c then
                local p = { x = wx, y = wy }
                for k = 2, #route do
                    if segDist(p, route[k - 1], route[k]) <= width then out[#out + 1] = nd break end
                end
            end
        end
    end
    return out
end

-- dessin sur la carte du monde
local overlay, icons = nil, {}
local function draw()
    for _, t in ipairs(icons) do t:Hide() end
    if not (M.enabled and WorldMapFrame and WorldMapFrame:IsShown()) then return end
    local canvas = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
    if not canvas then return end
    if not overlay then
        overlay = CreateFrame("Frame", nil, canvas)
        overlay:SetAllPoints(canvas)
        overlay:SetFrameLevel(canvas:GetFrameLevel() + 1990)
    end
    local W, H = overlay:GetWidth(), overlay:GetHeight()
    if not (W and W > 0) then return end
    local scale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1
    local list = M.Visible(WorldMapFrame:GetMapID())
    for k, nd in ipairs(list) do
        if k > 300 then break end
        local t = icons[k]
        if not t then t = overlay:CreateTexture(nil, "OVERLAY"); icons[k] = t end
        t:SetTexture(ICON[nd.kind])
        t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        t:SetSize(12 / scale, 12 / scale)
        t:ClearAllPoints()
        t:SetPoint("CENTER", overlay, "TOPLEFT", nd.x * W, -nd.y * H)
        t:Show()
    end
end
M.Draw = draw

local acc = 0
local ticker = CreateFrame("Frame")
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
    for t = 1, 6 do
        local d = p:CreateTexture(nil, "ARTWORK"); d:SetTexture(ns.MEDIA .. "dot"); d:SetSize(4, 4)
        d:SetPoint("CENTER", p, "TOPLEFT", 15 + t * 20, -(70 - t * 9)); d:SetVertexColor(0.4, 0.8, 1)
    end
    for k, pos in ipairs({ { 40, 50 }, { 75, 45 }, { 110, 20 }, { 95, 35 } }) do
        local i = p:CreateTexture(nil, "OVERLAY"); i:SetSize(13, 13)
        i:SetTexture(k % 2 == 0 and ICON.herb or ICON.mine)
        i:SetPoint("CENTER", p, "TOPLEFT", pos[1], -pos[2])
    end
end
