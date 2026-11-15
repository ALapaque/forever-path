local _, ns = ...
local L = ns.L

-- Fenêtre principale du guide. Les autres modules y ajoutent des « sections » :
--   ns.Guide:SetSection(id, order, text)   (text = nil pour retirer)
local M = ns.RegisterModule({
    id = "guide", category = "core", default = true,
    name = ns.Tr("Fenêtre du guide"),
    desc = ns.Tr("L'étape en cours, la suivante, la progression et les boutons précédent / suivant."),
    options = {
        { key = "upcoming", label = ns.Tr("Étapes suivantes affichées"), type = "slider", min = 0, max = 4, step = 1, default = 1 },
        { key = "scale", label = ns.Tr("Taille"), type = "slider", min = 0.6, max = 1.6, step = 0.05, default = 1 },
        { key = "alpha", label = ns.Tr("Opacité du fond"), type = "slider", min = 0.1, max = 1, step = 0.05, default = 0.85 },
    },
})
ns.Guide = M

M.STYLE = {
    accept     = { verb = "ACCEPT",   icon = "Interface\\GossipFrame\\AvailableQuestIcon", color = "ffffd100" },
    complete   = { verb = "COMPLETE", icon = "Interface\\Icons\\Ability_DualWield",        color = "ffff7f3f" },
    turnin     = { verb = "TURNIN",   icon = "Interface\\GossipFrame\\ActiveQuestIcon",    color = "ff3fbf3f" },
    ["goto"]   = { verb = "GOTO",     icon = "Interface\\Icons\\INV_Misc_Map_01",          color = "ff66ccff" },
    level      = { verb = "LEVEL",    icon = "Interface\\Icons\\Spell_Holy_SealOfMight",   color = "ffcc66ff" },
    note       = { verb = "NOTE",     icon = "Interface\\Icons\\INV_Misc_Note_01",         color = "ffdddddd" },
    hearth     = { verb = "HEARTH",   icon = "Interface\\Icons\\INV_Misc_Rune_01",         color = "ff66ccff" },
    fly        = { verb = "FLY",      icon = "Interface\\Icons\\Ability_Mount_Gryphon_01", color = "ff66ccff" },
    flightpath = { verb = "FLIGHTPATH", icon = "Interface\\Icons\\Ability_Mount_Wyvern_01", color = "ff66ccff" },
    bind       = { verb = "BIND",     icon = "Interface\\Icons\\INV_Misc_Rune_01",         color = "ff66ccff" },
}

-- « » » dessiné en texture : les flèches Unicode (→) ne sont pas dans la police du jeu
M.CHEVRON = "|T" .. ns.MEDIA .. "chevron:10:10:0:0|t "

function M.StepLabel(step)
    if not step then return "" end
    local st = M.STYLE[step.type] or M.STYLE.note
    local verb = step.type == "level" and L.LEVEL:format(step.level or 0) or L[st.verb]
    local body = step.text
    if not body and step.quest then
        body = C_QuestLog.GetTitleForQuestID(step.quest)
        if not body then
            C_QuestLog.RequestLoadQuestByID(step.quest)
            body = "#" .. step.quest
        end
    end
    local s = ("|c%s%s|r"):format(st.color, verb)
    if body then s = s .. " : " .. body end
    if step.danger then s = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14|t " .. s end
    return s, st
end

---------------------------------------------------------------------------
local f = CreateFrame("Frame", "QuestweaverFrame", UIParent, "BackdropTemplate")
M.frame = f
f:SetSize(330, 120)
f:Hide()
ns.Skin(f)
ns.MakeMovable(f, "guide", { "RIGHT", "RIGHT", -60, 120 })

-- Poignée de redimensionnement (coin bas droit) : règle la largeur, la hauteur suit le contenu.
f:SetResizable(true)
if f.SetResizeBounds then f:SetResizeBounds(240, 60, 640, 2000) end
f.grip = CreateFrame("Button", nil, f)
f.grip:SetSize(14, 14)
f.grip:SetPoint("BOTTOMRIGHT", -1, 1)
f.grip:SetFrameLevel(f:GetFrameLevel() + 5)
f.grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
f.grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
f.grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
f.grip:SetScript("OnMouseDown", function()
    if not ns.db.locked then f:StartSizing("RIGHT") end
end)
f.grip:SetScript("OnMouseUp", function()
    f:StopMovingOrSizing()
    ns.db.guideWidth = math.floor(f:GetWidth() + 0.5)
    -- StartSizing peut ré-ancrer le cadre : on sauvegarde aussi sa position
    local p, _, rp, x, y = f:GetPoint()
    ns.db.frames.guide = { p, rp, x, y }
    M:Layout()
end)
f.grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.Tr("Glisser pour élargir / rétrécir"), 1, 1, 1)
    GameTooltip:Show()
end)
f.grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
local lastW
f:SetScript("OnSizeChanged", function(self, w)
    if w ~= lastW then lastW = w; if M.enabled then M:Layout() end end
end)

f.title = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
f.title:SetPoint("TOPLEFT", 8, -6)
f.title:SetPoint("TOPRIGHT", -84, -6)
f.title:SetJustifyH("LEFT")
f.title:SetWordWrap(false)

f.progress = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
f.progress:SetPoint("TOPRIGHT", -26, -6)

f.cfg = CreateFrame("Button", nil, f)
f.cfg:SetSize(14, 14)
f.cfg:SetPoint("TOPRIGHT", -6, -4)
f.cfg:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
f.cfg:SetScript("OnClick", function() ns.Options:Open() end)
f.cfg:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(ns.Tr("Options de Questweaver"), 1, 1, 1)
    GameTooltip:AddLine("Modules, apparence, route", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
f.cfg:SetScript("OnLeave", function() GameTooltip:Hide() end)

f.bar = CreateFrame("StatusBar", nil, f)
f.bar:SetPoint("TOPLEFT", 8, -20)
f.bar:SetPoint("TOPRIGHT", -8, -20)
f.bar:SetHeight(3)
f.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
f.bar:SetStatusBarColor(unpack(ns.Theme().accent))
f.bar.bg = f.bar:CreateTexture(nil, "BACKGROUND")
f.bar.bg:SetAllPoints()
f.bar.bg:SetColorTexture(1, 1, 1, 0.08)

f.icon = f:CreateTexture(nil, "ARTWORK")
f.icon:SetSize(28, 28)
f.icon:SetPoint("TOPLEFT", 8, -30)

f.text = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontHighlight")
f.text:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 8, 0)
f.text:SetPoint("RIGHT", f, "RIGHT", -8, 0)
f.text:SetJustifyH("LEFT")
f.text:SetWordWrap(true)

f.sub = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
f.sub:SetPoint("TOPLEFT", f.text, "BOTTOMLEFT", 0, -3)
f.sub:SetPoint("RIGHT", f, "RIGHT", -8, 0)
f.sub:SetJustifyH("LEFT")

-- sections des modules
f.sections = {}
local sectionData = {}
function M:SetSection(id, order, text)
    text = ns.Tr(text)
    if text == nil or text == "" then sectionData[id] = nil
    else sectionData[id] = { order = order, text = text } end
    M:Layout()
end

f.upcoming = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
f.upcoming:SetJustifyH("LEFT")
f.upcoming:SetWordWrap(true)

f.prev = ns.Button(f, "<", 26, 20, function() ns.Engine.Prev() end, ns.Tr("Étape précédente"))
f.prev:SetPoint("BOTTOMLEFT", 6, 6)
f.next = ns.Button(f, ">", 26, 20, function() ns.Engine.Next() end,
    ns.Tr("Étape suivante\n|cffaaaaaaPasse cette étape (elle reste passée après un /reload)|r"))
f.next:SetPoint("LEFT", f.prev, "RIGHT", 3, 0)
f.dist = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
f.dist:SetPoint("LEFT", f.next, "RIGHT", 8, 0)

-- boutons optionnels (les modules les montrent/cachent)
f.buttons = {}
function M:AddButton(id, label, w, onClick, tooltip, icon)
    local b = ns.Button(f, label, w, 20, onClick, tooltip, icon)
    b:Hide()
    f.buttons[#f.buttons + 1] = { id = id, b = b }
    return b
end

function M:Layout()
    local y = -30
    local textH = f.text:GetStringHeight() + (f.sub:GetText() ~= "" and f.sub:GetStringHeight() + 3 or 0)
    y = y - math.max(28, textH) - 6

    local list = {}
    for id, d in pairs(sectionData) do list[#list + 1] = { id = id, order = d.order, text = d.text } end
    table.sort(list, function(a, b) return a.order < b.order end)
    for i, d in ipairs(list) do
        local fs = f.sections[i]
        if not fs then
            fs = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(true)
            f.sections[i] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 10, y)
        fs:SetPoint("RIGHT", f, "RIGHT", -8, 0)
        fs:SetText(d.text)
        fs:Show()
        y = y - fs:GetStringHeight() - 4
    end
    for i = #list + 1, #f.sections do f.sections[i]:Hide() end

    if f.upcoming:GetText() and f.upcoming:GetText() ~= "" then
        f.upcoming:ClearAllPoints()
        f.upcoming:SetPoint("TOPLEFT", 10, y)
        f.upcoming:SetPoint("RIGHT", f, "RIGHT", -8, 0)
        f.upcoming:Show()
        y = y - f.upcoming:GetStringHeight() - 4
    else
        f.upcoming:Hide()
    end

    -- boutons visibles alignés à droite
    local anchor
    for i = #f.buttons, 1, -1 do
        local b = f.buttons[i].b
        if b:IsShown() then
            b:ClearAllPoints()
            if anchor then b:SetPoint("RIGHT", anchor, "LEFT", -3, 0) else b:SetPoint("BOTTOMRIGHT", -16, 6) end
            anchor = b
        end
    end
    f:SetHeight(-y + 32)
end

function M:Update()
    if not self.enabled then return end
    local g, step, i = ns.Engine.Current()
    if not g then
        f.title:SetText("Questweaver")
        f.progress:SetText("")
        f.text:SetText(L.NO_GUIDE)
        f.sub:SetText("")
        f.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
        f.bar:SetMinMaxValues(0, 1); f.bar:SetValue(0)
        f.upcoming:SetText("")
        self:Layout()
        return
    end
    f.title:SetText(g.name)
    f.progress:SetText(("%d/%d"):format(math.min(i, #g.steps), #g.steps))
    f.bar:SetMinMaxValues(0, #g.steps)
    f.bar:SetValue(i - 1)

    if not step then
        f.text:SetText(L.GUIDE_DONE)
        f.icon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_01")
        f.sub:SetText("")
        f.upcoming:SetText("")
        self:Layout()
        return
    end

    local label, st = M.StepLabel(step)
    f.icon:SetTexture(st.icon)
    f.text:SetText(label)
    local sub = {}
    local z = ns.ZoneByKey[step.map or ""] or ns.ZoneByMap[step.map or 0]
    if z then sub[#sub + 1] = ns.ZoneName(z) end
    local who = step.npc or (step.npcID and ns.NpcName(step.npcID))
    if who then sub[#sub + 1] = who end
    if step.mobs then
        local names = {}
        for id in pairs(step.mobs) do
            local n = ns.NpcName(id)
            if n and #names < 3 then names[#names + 1] = n end
        end
        if #names > 0 then sub[#sub + 1] = table.concat(names, ", ") end
    end
    if step.x then sub[#sub + 1] = ("%.1f, %.1f"):format(step.x, step.y) end
    f.sub:SetText(table.concat(sub, "  •  "))

    local n = self:Opt("upcoming") or 1
    local lines = {}
    for _, s in ipairs(ns.Engine.Upcoming(n)) do lines[#lines + 1] = M.CHEVRON .. (M.StepLabel(s)) end
    f.upcoming:SetText(table.concat(lines, "\n"))
    self:UpdateDistance()
    self:Layout()
end

function M:UpdateDistance()
    local step = ns.Engine.NavStep()
    local d = step and ns.Engine.Distance(step)
    f.dist:SetText(d and ns.FormatDistance(d) or "")
end

function M:ApplyLook()
    f:SetScale(self:Opt("scale") or 1)
    f:SetWidth(ns.db.guideWidth or 330)
    f.fpAlpha = self:Opt("alpha")
    ns.ReSkin(f)
    f.bar:SetStatusBarColor(unpack(ns.Theme().accent))
end
ns.On("FP_THEME_CHANGED", function() M:ApplyLook() end)

function M:OnEnable() self:ApplyLook(); f:Show(); self:Update() end
function M:OnDisable() f:Hide() end
function M:OnOptionChanged() self:ApplyLook(); self:Update() end
function M:Toggle()
    if f:IsShown() then f:Hide() else f:Show(); self:Update() end
end

M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("FP_TICK", function() if f:IsShown() then M:UpdateDistance() end end)
M:On("QUEST_DATA_LOAD_RESULT", function() M:Update() end)
