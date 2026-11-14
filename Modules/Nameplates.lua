local _, ns = ...

-- Met en évidence, sur les barres de nom, les PNJ et monstres de l'étape en cours,
-- et (option) tous les monstres liés à une quête du journal (via les infobulles).
local M = ns.RegisterModule({
    id = "nameplates", category = "targets", default = true,
    name = "Repérage sur les barres de nom",
    desc = "Halo et icône au-dessus des monstres à tuer et du PNJ à qui parler. Rebondit pour attirer l'œil.",
    options = {
        { key = "questMobs", label = "Marquer aussi les monstres de toutes mes quêtes", type = "check", default = true },
        { key = "friendly", label = "Afficher les barres de nom des PNJ amicaux", type = "check", default = true },
        { key = "bounce", label = "Icône animée", type = "check", default = true },
    },
})

local overlays = {}   -- [nameplate] = overlay
local active = {}     -- [unit] = overlay

local function overlayFor(plate)
    local o = overlays[plate]
    if o then return o end
    o = CreateFrame("Frame", nil, plate)
    o:SetAllPoints(plate)
    o:SetFrameLevel(plate:GetFrameLevel() + 10)
    o.glow = o:CreateTexture(nil, "BACKGROUND")
    o.glow:SetTexture(ns.MEDIA .. "glow")
    o.glow:SetPoint("CENTER", o, "CENTER", 0, 0)
    o.glow:SetSize(160, 46)
    o.glow:SetBlendMode("ADD")
    o.icon = o:CreateTexture(nil, "OVERLAY")
    o.icon:SetSize(22, 22)
    o.icon:SetPoint("BOTTOM", o, "TOP", 0, 2)
    o.t = 0
    o:SetScript("OnUpdate", function(self, dt)
        if not M:Opt("bounce") then return end
        self.t = self.t + dt
        self.icon:SetPoint("BOTTOM", self, "TOP", 0, 2 + math.abs(math.sin(self.t * 4)) * 6)
    end)
    overlays[plate] = o
    return o
end

-- Le monstre est-il lié à une quête active ? (lignes d'objectif dans l'infobulle)
local function isQuestUnit(unit)
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return false end
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if not ok or not data or not data.lines then return false end
    local qType = Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestObjective
    for _, line in ipairs(data.lines) do
        if line.type == qType and not ns.IsSecret(line.leftText) then
            local done = line.completed
            if not done then return true end
        end
    end
    return false
end

local function classify(unit)
    local targets = ns.Engine.Targets()
    local id = ns.NpcIDFromUnit(unit)
    if id and targets.ids[id] then return targets.ids[id] end
    local okName, name = pcall(UnitName, unit)
    if okName and name and not ns.IsSecret(name) and targets.names[name] then return targets.names[name] end
    if M:Opt("questMobs") and UnitCanAttack("player", unit) and isQuestUnit(unit) then return "quest" end
end

local STYLE = {
    npc   = { icon = "Interface\\GossipFrame\\AvailableQuestIcon", r = 1, g = 0.85, b = 0.2 },
    mob   = { icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", r = 1, g = 0.25, b = 0.2 },
    quest = { icon = "Interface\\Icons\\Ability_DualWield", r = 1, g = 0.55, b = 0.15 },
}

local function refreshUnit(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
    local kind = classify(unit)
    local o = overlayFor(plate)
    if kind then
        local st = STYLE[kind]
        o.glow:SetVertexColor(st.r, st.g, st.b, 0.85)
        o.icon:SetTexture(st.icon)
        o:Show()
        active[unit] = o
    else
        o:Hide()
        active[unit] = nil
    end
end

local function refreshAll()
    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit then pcall(refreshUnit, unit) end
    end
end
M.RefreshAll = refreshAll

M:On("NAME_PLATE_UNIT_ADDED", function(unit) pcall(refreshUnit, unit) end)
M:On("NAME_PLATE_UNIT_REMOVED", function(unit)
    local o = active[unit]
    if o then o:Hide() end
    active[unit] = nil
end)
M:On("FP_STEP_CHANGED", refreshAll)
M:On("QUEST_LOG_UPDATE", refreshAll)
M:On("UNIT_QUEST_LOG_CHANGED", refreshAll)

local function applyCVars()
    if InCombatLockdown() then return end
    if M:Opt("friendly") then
        pcall(SetCVar, "nameplateShowFriendlyNPCs", 1)
    end
end

function M:OnEnable() applyCVars(); refreshAll() end
function M:OnDisable() for _, o in pairs(overlays) do o:Hide() end wipe(active) end
function M:OnOptionChanged() applyCVars(); refreshAll() end

function M.preview(p)
    local bar = p:CreateTexture(nil, "ARTWORK")
    bar:SetSize(90, 9)
    bar:SetPoint("CENTER", 0, -6)
    bar:SetColorTexture(0.8, 0.15, 0.1)
    local name = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("BOTTOM", bar, "TOP", 0, 2)
    name:SetText("Vermine kobold")
    local glow = p:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(ns.MEDIA .. "glow")
    glow:SetSize(140, 40)
    glow:SetPoint("CENTER", bar, "CENTER")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.25, 0.2, 0.9)
    local icon = p:CreateTexture(nil, "OVERLAY")
    icon:SetSize(18, 18)
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    local t = 0
    p:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        icon:SetPoint("BOTTOM", name, "TOP", 0, 2 + math.abs(math.sin(t * 4)) * 6)
    end)
end
