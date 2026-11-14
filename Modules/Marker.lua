local _, ns = ...

local ICONS = { "Étoile", "Cercle", "Losange", "Triangle", "Lune", "Carré", "Croix", "Crâne" }

local M = ns.RegisterModule({
    id = "marker", category = "targets", default = true,
    name = "Marqueur automatique",
    desc = "Pose un symbole (étoile, crâne…) au-dessus du PNJ ou du monstre de l'étape quand tu le survoles. Visible de loin dans le monde.",
    options = {
        { key = "npcIcon", label = "Symbole des PNJ", type = "select", values = ICONS, default = 1 },
        { key = "mobIcon", label = "Symbole des monstres", type = "select", values = ICONS, default = 8 },
        { key = "mobs", label = "Marquer aussi les monstres", type = "check", default = false },
    },
})

local function canMark()
    if not IsInGroup() then return true end
    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

local function tryMark(unit)
    if not UnitExists(unit) or UnitIsPlayer(unit) or UnitIsDead(unit) then return end
    if not canMark() then return end
    local ok, current = pcall(GetRaidTargetIndex, unit)
    if not ok or ns.IsSecret(current) or current then return end
    local targets = ns.Engine.Targets()
    local id = ns.NpcIDFromUnit(unit)
    local kind = id and targets.ids[id]
    if not kind then
        local okN, name = pcall(UnitName, unit)
        kind = okN and name and not ns.IsSecret(name) and targets.names[name]
    end
    if kind == "npc" then
        pcall(SetRaidTarget, unit, M:Opt("npcIcon") or 1)
    elseif kind == "mob" and M:Opt("mobs") then
        pcall(SetRaidTarget, unit, M:Opt("mobIcon") or 8)
    end
end

M:On("UPDATE_MOUSEOVER_UNIT", function() tryMark("mouseover") end)
M:On("PLAYER_TARGET_CHANGED", function() tryMark("target") end)

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(30, 30)
    t:SetPoint("CENTER", 0, 14)
    t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    local n = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    n:SetPoint("TOP", t, "BOTTOM", 0, -4)
    n:SetText("Maréchal McBride")
end
