local _, ns = ...

local M = ns.RegisterModule({
    id = "waypoint", category = "nav", default = true,
    name = ns.Tr("Point sur la carte et la minimap"),
    desc = ns.Tr("Pose le point de Blizzard sur l'étape (carte, minimap, pilier lumineux) et le déplace tout seul à chaque étape. Bouton épingle dans le guide pour le replacer."),
    options = {
        { key = "button", label = ns.Tr("Bouton épingle dans le guide"), type = "check", default = true },
        { key = "tomtom", label = ns.Tr("Utiliser aussi TomTom (si installé)"), type = "check", default = true },
    },
})
ns.Waypoint = M

local tomtomUid, ours, lastStep

local function clear()
    if ours and C_Map.HasUserWaypoint() then C_Map.ClearUserWaypoint() end
    ours = false
    if tomtomUid and TomTom then TomTom:RemoveWaypoint(tomtomUid) end
    tomtomUid = nil
end

-- pose le point (map, x/y 0..1). M.placing permet aux autres modules de reconnaître nos propres poses.
local function setPoint(map, x, y)
    clear()
    if C_Map.CanSetUserWaypointOnMap(map) then
        M.placing = true
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        M.placing = false
        ours = true
    end
end

function M:PlaceAt(map, x, y)
    if not self.enabled then return end
    setPoint(map, x, y)
    if M:Opt("tomtom") and TomTom and TomTom.AddWaypoint then
        tomtomUid = TomTom:AddWaypoint(map, x, y, { title = "Questweaver", persistent = false, minimap = true, world = true })
    end
end

local function set(step)
    local map = ns.Geo.StepMap(step)
    if not (map and step and step.x) then return false end
    local x, y = step.x / 100, step.y / 100
    setPoint(map, x, y)
    if M:Opt("tomtom") and TomTom and TomTom.AddWaypoint then
        tomtomUid = TomTom:AddWaypoint(map, x, y, { title = "Questweaver", persistent = false, minimap = true, world = true })
    end
    return ours or tomtomUid ~= nil
end

-- (Re)pose le point sur l'étape visée, à la demande (quiet : sans message si pas de position)
function M:Place(openMap, quiet)
    if not openMap and not quiet and ns.Journeys and ns.Journeys:Driving() then
        ns.Journeys:Replan("bouton")       -- itinéraire actif : on repart du virage en cours
        return true
    end
    local step = ns.Engine.NavStep()
    if set(step) then
        lastStep = step
        if openMap and OpenWorldMap then OpenWorldMap(ns.Geo.StepMap(step)) end
        return true
    end
    if not quiet then
        ns.Toast(ns.Tr("Pas de position pour cette étape."), "Interface\\Icons\\INV_Misc_Map_01", 1, 0.8, 0.4, 2)
    end
end

local btn
local function updateButton()
    if not (ns.Guide and ns.Guide.AddButton) then return end
    if not btn then
        btn = ns.Guide:AddButton("waypoint", nil, 22, function(_, mouse) M:Place(mouse == "RightButton") end,
            function(tt)
                tt:SetText(ns.Tr("Point sur la carte"), 1, 1, 1)
                tt:AddLine(ns.Tr("Clic gauche : replacer le point (carte, minimap, pilier)"), 0.8, 0.8, 0.8, true)
                tt:AddLine(ns.Tr("Clic droit : replacer et ouvrir la carte"), 0.8, 0.8, 0.8, true)
                tt:AddLine(ns.Tr("Le point suit tout seul les étapes."), 0.6, 0.6, 0.6, true)
            end, ns.MEDIA .. "pin")
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn.icon:SetVertexColor(1, 0.85, 0.3)
    end
    btn:SetShown(M.enabled and M:Opt("button") and true or false)
    ns.Guide:Layout()
end

function M:OnEnable() lastStep = nil; updateButton(); ns.Fire("FP_STEP_CHANGED", true) end
function M:OnDisable() clear(); lastStep = nil; updateButton() end
function M:OnOptionChanged() updateButton() end

M:On("FP_STEP_CHANGED", function()
    -- les itinéraires pilotent le point virage par virage
    if ns.Journeys and ns.Journeys.enabled and ns.Journeys:Opt("corners") then return end
    local step = ns.Engine.NavStep()
    if step == lastStep then return end
    lastStep = step
    if step then set(step) else clear() end
end)

function M.preview(p)
    local glow = p:CreateTexture(nil, "BACKGROUND")
    glow:SetSize(40, 74)
    glow:SetPoint("CENTER", -24, 4)
    glow:SetTexture(ns.MEDIA .. "glow")
    glow:SetVertexColor(1, 0.85, 0.3, 0.6)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(8, 56)
    t:SetPoint("CENTER", -24, 4)
    t:SetColorTexture(1, 0.85, 0.3, 0.55)
    local pin = p:CreateTexture(nil, "ARTWORK")
    pin:SetSize(26, 26)
    pin:SetPoint("CENTER", 24, 8)
    pin:SetTexture(ns.MEDIA .. "pin")
    pin:SetVertexColor(1, 0.85, 0.3)
    local d = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
    d:SetPoint("TOP", pin, "BOTTOM", 0, -2)
    d:SetText("124 m")
end
