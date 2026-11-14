local _, ns = ...

local M = ns.RegisterModule({
    id = "waypoint", category = "nav", default = true,
    name = "Waypoint natif",
    desc = "Pose le marqueur de carte de Blizzard sur l'étape : pilier lumineux dans le monde et distance. Compatible TomTom.",
    options = {
        { key = "tomtom", label = "Utiliser aussi TomTom (si installé)", type = "check", default = true },
    },
})

local tomtomUid, ours, lastStep

local function clear()
    if ours and C_Map.HasUserWaypoint() then C_Map.ClearUserWaypoint() end
    ours = false
    if tomtomUid and TomTom then TomTom:RemoveWaypoint(tomtomUid) end
    tomtomUid = nil
end

local function set(step)
    clear()
    local map = ns.Geo.StepMap(step)
    if not (map and step.x) then return end
    local x, y = step.x / 100, step.y / 100
    if C_Map.CanSetUserWaypointOnMap(map) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        ours = true
    end
    if M:Opt("tomtom") and TomTom and TomTom.AddWaypoint then
        tomtomUid = TomTom:AddWaypoint(map, x, y, { title = "ForeverPath", persistent = false, minimap = true, world = true })
    end
end

function M:OnEnable() lastStep = nil; ns.Fire("FP_STEP_CHANGED", true) end
function M:OnDisable() clear(); lastStep = nil end

M:On("FP_STEP_CHANGED", function()
    local _, step = ns.Engine.Current()
    if step == lastStep then return end
    lastStep = step
    set(step)
end)

-- Aperçu pour le panneau d'options
function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(14, 60)
    t:SetPoint("CENTER", 0, 4)
    t:SetColorTexture(1, 0.85, 0.3, 0.5)
    local glow = p:CreateTexture(nil, "BACKGROUND")
    glow:SetSize(40, 74)
    glow:SetPoint("CENTER", 0, 4)
    glow:SetTexture(ns.MEDIA .. "glow")
    glow:SetVertexColor(1, 0.85, 0.3, 0.6)
    local d = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    d:SetPoint("TOP", t, "BOTTOM", 0, -2)
    d:SetText("124 m")
end
