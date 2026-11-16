local _, ns = ...

-- Met en évidence, sur les barres de nom, les PNJ et monstres de l'étape en cours,
-- et (option) tous les monstres liés à une quête du journal (via les infobulles).
local M = ns.RegisterModule({
    id = "nameplates", category = "targets", default = true,
    name = ns.Tr("Repérage sur les barres de nom"),
    desc = ns.Tr("Halo et icône au-dessus des monstres à tuer et du PNJ à qui parler. Rebondit pour attirer l'œil."),
    options = {
        { key = "questMobs", label = ns.Tr("Marquer aussi les monstres de toutes mes quêtes"), type = "check", default = true },
        { key = "friendly", label = ns.Tr("Afficher les barres de nom des PNJ amicaux"), type = "check", default = true },
        { key = "bounce", label = ns.Tr("Icône animée"), type = "check", default = true },
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
    o.acc = 0
    o:SetScript("OnUpdate", function(self, dt)
        self.t = self.t + dt
        self.acc = self.acc + dt
        if self.acc < 1 / 30 then return end         -- 30 fois/s suffisent pour un rebond
        self.acc = 0
        local still = not M:Opt("bounce") or (ns.Eco and ns.Eco())
        if still then
            if self.bouncing then self.bouncing = false; self.icon:SetPoint("BOTTOM", self, "TOP", 0, 2) end
            return
        end
        self.bouncing = true
        self.icon:SetPoint("BOTTOM", self, "TOP", 0, 2 + math.abs(math.sin(self.t * 4)) * 6)
    end)
    overlays[plate] = o
    return o
end

-- État de quête d'un monstre d'après les lignes d'objectif de son infobulle :
--   "todo" = au moins un objectif non rempli le concerne, "done" = tous remplis, nil = aucun.
local function questState(unit)
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return end
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if not ok or not data or not data.lines then return end
    local qType = Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestObjective
    local seen, todo = false, false
    for _, line in ipairs(data.lines) do
        if line.type == qType and not ns.IsSecret(line.leftText) and not ns.IsSecret(line.completed) then
            seen = true
            if not line.completed then todo = true end
        end
    end
    if todo then return "todo" elseif seen then return "done" end
end
M.QuestState = questState

local function classify(unit)
    local targets = ns.Engine.Targets()
    local id = ns.NpcIDFromUnit(unit)
    local kind = id and targets.ids[id]
    if not kind then
        local okName, name = pcall(UnitName, unit)
        if okName and name and not ns.IsSecret(name) then kind = targets.names[name] end
    end
    local attackable = UnitCanAttack("player", unit)
    if kind == "mob" or (not kind and attackable) then
        local st = questState(unit)
        -- objectif déjà rempli pour ce monstre (ex. 8/8) : plus de marque
        if st == "done" then return end
        if kind == "mob" then return kind end
        if st == "todo" and M:Opt("questMobs") then return "quest" end
        return
    end
    return kind
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
        o.kind = kind
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

-- Barre de nom du PNJ de l'étape, si elle est à l'écran : elle est exactement au-dessus de lui
-- (le guidage 3D s'y accroche de près, les coordonnées de la base pouvant être décalées de quelques mètres).
function M.NpcPlate()
    if not M.enabled then return end
    for _, o in pairs(active) do
        if o.kind == "npc" and o:IsVisible() then return o end
    end
end

M:On("NAME_PLATE_UNIT_ADDED", function(unit) pcall(refreshUnit, unit) end)
M:On("NAME_PLATE_UNIT_REMOVED", function(unit)
    local o = active[unit]
    if o then o:Hide() end
    active[unit] = nil
end)
-- le journal change souvent (chaque monstre tué) : on regroupe les rafraîchissements
local queued = false
local function queueRefresh()
    if queued then return end
    queued = true
    C_Timer.After(0.25, function() queued = false; refreshAll() end)
end
M:On("FP_STEP_CHANGED", queueRefresh)
M:On("QUEST_LOG_UPDATE", queueRefresh)
M:On("UNIT_QUEST_LOG_CHANGED", queueRefresh)

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
    local name = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
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
