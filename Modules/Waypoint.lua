local _, ns = ...

local M = ns.RegisterModule({
    id = "waypoint", category = "nav", default = true,
    name = "Point sur la carte et la minimap",
    desc = "Pose le point de Blizzard sur l'étape (carte, minimap, pilier lumineux) et le déplace tout seul à chaque étape. Bouton épingle dans le guide pour le replacer.",
    options = {
        { key = "button", label = "Bouton épingle dans le guide", type = "check", default = true },
        { key = "tomtom", label = "Utiliser aussi TomTom (si installé)", type = "check", default = true },
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

local function set(step)
    local map = ns.Geo.StepMap(step)
    if not (map and step and step.x) then return false end
    clear()
    local x, y = step.x / 100, step.y / 100
    if C_Map.CanSetUserWaypointOnMap(map) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        ours = true
    end
    if M:Opt("tomtom") and TomTom and TomTom.AddWaypoint then
        tomtomUid = TomTom:AddWaypoint(map, x, y, { title = "ForeverPath", persistent = false, minimap = true, world = true })
    end
    return ours or tomtomUid ~= nil
end

-- (Re)pose le point sur l'étape visée, à la demande
function M:Place(openMap)
    local step = ns.Engine.NavStep()
    if set(step) then
        lastStep = step
        if openMap and OpenWorldMap then OpenWorldMap(ns.Geo.StepMap(step)) end
        return true
    end
    ns.Toast("Pas de position pour cette étape.", "Interface\\Icons\\INV_Misc_Map_01", 1, 0.8, 0.4, 2)
end

local btn
local function updateButton()
    if not (ns.Guide and ns.Guide.AddButton) then return end
    if not btn then
        btn = ns.Guide:AddButton("waypoint", nil, 22, function(_, mouse) M:Place(mouse == "RightButton") end,
            function(tt)
                tt:SetText("Point sur la carte", 1, 1, 1)
                tt:AddLine("Clic gauche : replacer le point (carte, minimap, pilier)", 0.8, 0.8, 0.8, true)
                tt:AddLine("Clic droit : replacer et ouvrir la carte", 0.8, 0.8, 0.8, true)
                tt:AddLine("Le point suit tout seul les étapes.", 0.6, 0.6, 0.6, true)
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
    local d = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallGold")
    d:SetPoint("TOP", pin, "BOTTOM", 0, -2)
    d:SetText("124 m")
end
