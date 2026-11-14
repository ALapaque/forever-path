local _, ns = ...
local Places = ns.Nav.Places

-- Maître de classe : rappel aux niveaux où de nouveaux sorts arrivent, et détour vers le maître
-- de ta classe le plus proche (données QuestieDB).
local M = ns.RegisterModule({
    id = "trainer", category = "comfort", default = true,
    name = "Maître de classe",
    desc = "Aux niveaux où de nouveaux sorts arrivent, indique le maître de ta classe le plus proche. Un clic pour y aller : la flèche et l'itinéraire font le détour, puis reprennent le guide.",
    options = {
        { key = "auto", label = "Faire le détour sans demander", type = "check", default = false },
        { key = "minGap", label = "Rappel tous les N niveaux", type = "slider", min = 1, max = 6, step = 1, default = 2 },
    },
})

local btn
local function pending()
    local lvl = ns.PlayerLevel()
    local last = ns.cdb.trainedAt or 1
    return lvl >= 2 and lvl - last >= (M:Opt("minGap") or 2)
end

function M:Go()
    local t, d = Places.NearestTrainer()
    if not t then ns.Toast("Aucun maître de ta classe connu près d'ici.", nil, 1, 0.5, 0.3) return end
    Places.Go(t, ("Maître de classe : %s (%s)"):format(t.name, Places.ZoneName(t.map)), "Interface\\Icons\\INV_Misc_Book_09")
    return t, d
end

function M:Update()
    if not ns.Guide then return end
    if not btn then
        btn = ns.Guide:AddButton("trainer", nil, 22, function() M:Go() end, function(tt)
            local t = Places.NearestTrainer()
            tt:AddLine("Nouveaux sorts disponibles")
            if t then tt:AddLine(("Maître le plus proche : %s\n%s"):format(t.name, Places.ZoneName(t.map)), 1, 1, 1, true) end
            tt:AddLine("Clic : y aller (détour)", 0.6, 0.6, 0.6)
        end, "Interface\\Icons\\INV_Misc_Book_09")
    end
    local show = self.enabled and pending() and not (ns.Engine.Detour() and ns.Engine.Detour().npcID)
    btn:SetShown(show and true or false)
    ns.Guide:Layout()
end

local function trained()
    ns.cdb.trainedAt = ns.PlayerLevel()
    M:Update()
end

M:On("PLAYER_LEVEL_UP", function()
    C_Timer.After(1.5, function()
        if not (M.enabled and pending()) then return end
        local t = Places.NearestTrainer()
        if M:Opt("auto") then M:Go() end
        ns.Toast(t and ("Nouveaux sorts : %s, %s"):format(t.name, Places.ZoneName(t.map)) or "Nouveaux sorts chez ton maître de classe",
            "Interface\\Icons\\INV_Misc_Book_09", 0.6, 0.85, 1, 6)
        M:Update()
    end)
end)
M:On("TRAINER_SHOW", trained)
M:On("FP_DETOUR_ARRIVED", function(d) if d.npcID and d.text and d.text:find("Maître") then trained() end end)
M:On("FP_DETOUR", function() M:Update() end)
M:On("FP_READY", function()
    ns.cdb.trainedAt = ns.cdb.trainedAt or ns.PlayerLevel()   -- premier lancement : rien en retard
    M:Update()
end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end
function M:OnOptionChanged() self:Update() end

function M.preview(p)
    local box = CreateFrame("Frame", nil, p)
    box:SetSize(150, 44); box:SetPoint("CENTER")
    ns.Skin(box, 0.9)
    local i = box:CreateTexture(nil, "ARTWORK"); i:SetSize(22, 22); i:SetPoint("LEFT", 6, 0)
    i:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    local t = box:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    t:SetPoint("LEFT", i, "RIGHT", 6, 0); t:SetPoint("RIGHT", -4, 0); t:SetJustifyH("LEFT")
    t:SetText("|cff66ccffDétour :|r Maître de classe\nKhelden Bremen")
end
