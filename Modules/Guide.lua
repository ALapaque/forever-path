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
    local s
    local t = ns.Theme()
    if t.keywords then
        -- verbe en blanc, objet de la quête en couleur (vert pour une quête, orange pour un objectif)
        local kc = step.type == "complete" and "ffff8a3d" or "ff3dff9a"
        s = verb
        if body then
            local quoted = (step.type == "accept" or step.type == "turnin") and ("'" .. body .. "'") or body
            s = ("%s |c%s%s|r"):format(verb, kc, quoted)
        end
    else
        s = ("|c%s%s|r"):format(st.color, verb)
        if body then s = s .. " : " .. body end
    end
    if step.danger then s = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14|t " .. s end
    local ct = step.quest and ns.ChainTag and ns.ChainTag(step.quest)
    if ct then s = s .. " " .. ct end
    local pq = ns.Modules.profquests
    local tag = pq and pq.Tag and pq.Tag(step)
    if tag then s = s .. " " .. tag end
    return s, st
end

---------------------------------------------------------------------------
local f = CreateFrame("Frame", "QuestweaverFrame", UIParent, "BackdropTemplate")
M.frame = f
f:SetSize(330, 120)
f:Hide()
f.fpGuide = true                 -- fond propre à la fenêtre du guide quand le thème en a un (Classic)
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

-- bandeau derrière le titre (thèmes Classic et Classic Forever)
f.header = f:CreateTexture(nil, "BORDER")
f.header:SetTexture("Interface\\Buttons\\WHITE8x8")
f.header:Hide()

f.title = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
f.title:SetPoint("TOPLEFT", 8, -6)
f.title:SetPoint("TOPRIGHT", -84, -6)
f.title:SetJustifyH("LEFT")
f.title:SetWordWrap(false)

-- Le titre (zone du segment en cours) est un bouton : il ouvre la liste des zones pour en changer.
f.zoneArrow = f:CreateTexture(nil, "OVERLAY")
f.zoneArrow:SetSize(12, 12)
f.zoneArrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
f.zone = CreateFrame("Button", nil, f)
f.zone:SetPoint("TOPLEFT", 4, -2)
f.zone:SetSize(120, 18)
f.zone.hl = f.zone:CreateTexture(nil, "HIGHLIGHT")
f.zone.hl:SetAllPoints()
f.zone.hl:SetColorTexture(1, 1, 1, 0.10)
f.zone:SetScript("OnClick", function() M.OpenZones() end)
f.zone:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(ns.Tr("Changer de zone"), 1, 1, 1)
    GameTooltip:AddLine(ns.Tr("Les zones conseillées à ton niveau : clique sur l'une d'elles pour y suivre ta route."), 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end)
f.zone:SetScript("OnLeave", function() GameTooltip:Hide() end)
-- on déplace souvent la fenêtre en la tirant par son titre : le bouton laisse passer le glisser
f.zone:RegisterForDrag("LeftButton")
f.zone:SetScript("OnDragStart", function()
    local start = f:GetScript("OnDragStart")
    if start then start(f) end
end)
f.zone:SetScript("OnDragStop", function()
    local stop = f:GetScript("OnDragStop")
    if stop then stop(f) end
end)
function M.OpenZones()
    if ns.ZonePanel and ns.ZonePanel.Toggle then ns.ZonePanel:Toggle(); return true end
end

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

-- Objectifs de la quête en cours : une ligne par objectif, avec son compteur et sa barre.
-- list : une table par objectif, avec label (texte sans le compteur), have, need et done
f.objRows = {}
M.objData = {}
function M:SetObjectives(list)
    M.objData = list or {}
    M:Layout()
end
local function objRow(i)
    local r = f.objRows[i]
    if r then return r end
    r = {}
    r.label = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(false)
    r.count = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
    r.count:SetJustifyH("RIGHT")
    r.bar = CreateFrame("StatusBar", nil, f)
    r.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    r.bar.bg = r.bar:CreateTexture(nil, "BACKGROUND")
    r.bar.bg:SetAllPoints()
    f.objRows[i] = r
    return r
end

-- petits titres de groupe : « Ensuite » (étapes suivantes) et « À côté de la route » (rappels)
local SIDE_ORDER = 80            -- sections d'ordre >= 80 : rappels qui ne sont pas l'étape en cours
local function groupTitle()
    local fs = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
    fs:SetJustifyH("LEFT")
    fs:Hide()
    return fs
end
f.hNext, f.hSide = groupTitle(), groupTitle()
f.rule = f:CreateTexture(nil, "ARTWORK")
f.rule:SetTexture("Interface\\Buttons\\WHITE8x8")
f.rule:Hide()

f.upcoming = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
f.upcoming:SetJustifyH("LEFT")
f.upcoming:SetWordWrap(true)
f.upLines = {}       -- une ligne par étape suivante (fond coloré possible selon le thème)
M.upData = {}

-- barre colorée derrière une ligne (thème Néon)
local function rowBar()
    local b = f:CreateTexture(nil, "BORDER")
    b:SetTexture("Interface\\Buttons\\WHITE8x8")
    b:Hide()
    return b
end
f.mainBar = rowBar()

local function caps(s)
    return ns.Theme().caps and ns.Upper(s) or s
end

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
    local theme = ns.Theme()
    local y = -30
    local textH = f.text:GetStringHeight() + (f.sub:GetText() ~= "" and f.sub:GetStringHeight() + 3 or 0)
    y = y - math.max(28, textH) - 6

    -- objectifs de l'étape en cours : libellé, compteur, barre
    local track = theme.guide and theme.guide.track
    for k, o in ipairs(M.objData) do
        local r = objRow(k)
        local done = o.done or (o.need and o.need > 0 and (o.have or 0) >= o.need)
        r.label:ClearAllPoints()
        r.label:SetPoint("TOPLEFT", 10, y)
        r.label:SetPoint("RIGHT", f, "RIGHT", -66, 0)
        r.label:SetText(caps(o.label or ""))
        if done then r.label:SetTextColor(0.2, 0.6, 0.2) else r.label:SetTextColor(ns.GuideColor("text")) end
        r.label:Show()
        local h = math.max(11, r.label:GetStringHeight() or 11)
        if o.need and o.need > 0 then
            r.count:ClearAllPoints()
            r.count:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, y + 1)
            r.count:SetText(("%d / %d"):format(o.have or 0, o.need))
            if done then r.count:SetTextColor(0.2, 0.6, 0.2) else r.count:SetTextColor(ns.GuideColor("text")) end
            r.count:Show()
            r.bar:ClearAllPoints()
            r.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, y - h - 3)
            r.bar:SetPoint("RIGHT", f, "RIGHT", -10, 0)
            r.bar:SetHeight(6)
            r.bar:SetMinMaxValues(0, o.need)
            r.bar:SetValue(math.min(o.have or 0, o.need))
            if done then
                r.bar:SetStatusBarColor(0.25, 0.7, 0.25)
            else
                r.bar:SetStatusBarColor(theme.accent[1], theme.accent[2], theme.accent[3])
            end
            if track then r.bar.bg:SetColorTexture(track[1], track[2], track[3], track[4] or 1)
            else r.bar.bg:SetColorTexture(1, 1, 1, 0.10) end
            r.bar:Show()
            y = y - h - 14
        else
            r.count:Hide(); r.bar:Hide()
            y = y - h - 5
        end
    end
    for k = #M.objData + 1, #f.objRows do
        local r = f.objRows[k]
        r.label:Hide(); r.count:Hide(); r.bar:Hide()
    end

    local list = {}
    for id, d in pairs(sectionData) do list[#list + 1] = { id = id, order = d.order, text = d.text } end
    table.sort(list, function(a, b) return a.order < b.order end)
    local used = 0
    local function place(d)
        used = used + 1
        local fs = f.sections[used]
        if not fs then
            fs = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(true)
            f.sections[used] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 10, y)
        fs:SetPoint("RIGHT", f, "RIGHT", -8, 0)
        fs:SetText(ns.Ink(d.text))
        fs:SetTextColor(ns.GuideColor("text"))
        fs:Show()
        y = y - fs:GetStringHeight() - 4
    end
    -- ce qui concerne l'étape en cours (itinéraire, groupe, journal, objectifs des autres quêtes...)
    local side = {}
    for _, d in ipairs(list) do
        if d.order >= SIDE_ORDER then side[#side + 1] = d else place(d) end
    end

    f.upcoming:Hide()
    local font = theme.outline and "QuestweaverFontOutlineSmall" or "QuestweaverFontSmallDim"
    if #M.upData > 0 then
        y = y - 2
        f.hNext:ClearAllPoints()
        f.hNext:SetPoint("TOPLEFT", 10, y)
        f.hNext:SetText(ns.Upper(ns.Tr("Ensuite")))
        f.hNext:SetTextColor(ns.GuideColor("dim"))
        f.hNext:Show()
        y = y - (f.hNext:GetStringHeight() or 10) - 3
    else
        f.hNext:Hide()
    end
    for k, d in ipairs(M.upData) do
        local line = f.upLines[k]
        if not line then
            line = { fs = f:CreateFontString(nil, "OVERLAY", font), bar = rowBar() }
            line.fs:SetJustifyH("LEFT")
            line.fs:SetWordWrap(true)
            f.upLines[k] = line
        end
        line.fs:SetFontObject(font)
        line.fs:ClearAllPoints()
        line.fs:SetPoint("TOPLEFT", 12, y - 2)
        line.fs:SetPoint("RIGHT", f, "RIGHT", -10, 0)
        line.fs:SetText(ns.Ink(d.text))
        if not theme.outline then line.fs:SetTextColor(ns.GuideColor("dim")) end
        line.fs:Show()
        local h = line.fs:GetStringHeight() + 4
        local rc = theme.rows and d.step and theme.rows[d.step.type]
        if rc then
            line.bar:ClearAllPoints()
            line.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 6, y)
            line.bar:SetPoint("RIGHT", f, "RIGHT", -6, 0)
            line.bar:SetHeight(h)
            line.bar:SetVertexColor(rc[1], rc[2], rc[3], rc[4])
            line.bar:Show()
        else
            line.bar:Hide()
        end
        y = y - h - 2
    end
    for k = #M.upData + 1, #f.upLines do f.upLines[k].fs:Hide(); f.upLines[k].bar:Hide() end

    -- rappels qui ne sont pas l'étape en cours (groupe, quête de classe, donjon, XP...) : regroupés
    if #side > 0 then
        y = y - 4
        f.rule:ClearAllPoints()
        f.rule:SetPoint("TOPLEFT", f, "TOPLEFT", 10, y)
        f.rule:SetPoint("RIGHT", f, "RIGHT", -10, 0)
        f.rule:SetHeight(1)
        local r, g, b = ns.GuideColor("dim")
        f.rule:SetVertexColor(r, g, b, 0.35)
        f.rule:Show()
        y = y - 6
        f.hSide:ClearAllPoints()
        f.hSide:SetPoint("TOPLEFT", 10, y)
        f.hSide:SetText(ns.Upper(ns.Tr("À côté de la route")))
        f.hSide:SetTextColor(r, g, b)
        f.hSide:Show()
        y = y - (f.hSide:GetStringHeight() or 10) - 4
        for _, d in ipairs(side) do place(d) end
    else
        f.rule:Hide(); f.hSide:Hide()
    end
    for k = used + 1, #f.sections do f.sections[k]:Hide() end

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

    -- fond coloré derrière l'étape en cours (thème Néon, lignes surlignées du thème Modern)
    local step = ns.Engine.Current and select(2, ns.Engine.Current())
    local rc = theme.rows and step and theme.rows[step.type]
    if rc then
        f.mainBar:ClearAllPoints()
        f.mainBar:SetPoint("TOPLEFT", f.icon, "TOPLEFT", -2, 2)
        f.mainBar:SetPoint("RIGHT", f, "RIGHT", -6, 0)
        f.mainBar:SetHeight(math.max(28, textH) + 4)
        f.mainBar:SetVertexColor(rc[1], rc[2], rc[3], rc[4])
        f.mainBar:Show()
    else
        f.mainBar:Hide()
    end
end

-- flèche et zone cliquable calées sur la largeur du titre
local function fitZone()
    local w = math.min((f.title:GetStringWidth() or 60), math.max(60, f:GetWidth() - 110))
    f.zoneArrow:ClearAllPoints()
    f.zoneArrow:SetPoint("LEFT", f.title, "LEFT", w + 3, -1)
    f.zone:SetWidth(w + 22)
end

function M:Update()
    if not self.enabled then return end
    local g, step, i = ns.Engine.Current()
    if not g then
        f.title:SetText("Questweaver")
        f.progress:SetText("")
        f.text:SetText(L.NO_GUIDE)
        f.sub:SetText("")
        ns.SetStepIcon(f.icon, nil, "Interface\\Icons\\INV_Misc_Map_01")
        f.bar:SetMinMaxValues(0, 1); f.bar:SetValue(0)
        f.upcoming:SetText("")
        wipe(M.upData)
        self:Layout()
        return
    end
    f.title:SetText(caps(g.name))
    fitZone()
    f.progress:SetText(("%d/%d"):format(math.min(i, #g.steps), #g.steps))
    f.bar:SetMinMaxValues(0, #g.steps)
    f.bar:SetValue(i - 1)

    if not step then
        f.text:SetText(L.GUIDE_DONE)
        ns.SetStepIcon(f.icon, nil, "Interface\\Icons\\Achievement_Quests_Completed_01")
        f.sub:SetText("")
        f.upcoming:SetText("")
        wipe(M.upData)
        self:Layout()
        return
    end

    local label, st = M.StepLabel(step)
    ns.SetStepIcon(f.icon, step, st.icon)
    f.text:SetText(ns.Ink(caps(label)))
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
    f.sub:SetText(caps(table.concat(sub, "  •  ")))

    local n = self:Opt("upcoming") or 1
    local lines = {}
    wipe(M.upData)
    for _, s in ipairs(ns.Engine.Upcoming(n)) do
        local text = M.CHEVRON .. caps((M.StepLabel(s)))
        lines[#lines + 1] = text
        M.upData[#M.upData + 1] = { text = text, step = s }
    end
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
    local t = ns.Theme()
    f.bar:SetStatusBarColor(unpack(t.accent))
    -- barre de progression : en haut, ou en bas en dégradé (thème Néon)
    f.bar:ClearAllPoints()
    if t.barBottom then
        f.bar:SetPoint("BOTTOMLEFT", 8, 4)
        f.bar:SetPoint("BOTTOMRIGHT", -8, 4)
        f.bar:SetHeight(4)
    else
        f.bar:SetPoint("TOPLEFT", 8, -20)
        f.bar:SetPoint("TOPRIGHT", -8, -20)
        f.bar:SetHeight(3)
    end
    local tex = f.bar:GetStatusBarTexture()
    if tex and tex.SetGradient and CreateColor then
        local a, b = t.gradient and t.gradient[1] or t.accent, t.gradient and t.gradient[2] or t.accent
        pcall(tex.SetGradient, tex, "HORIZONTAL", CreateColor(a[1], a[2], a[3], 1), CreateColor(b[1], b[2], b[3], 1))
    end
    -- textes avec contour
    f.text:SetFontObject(t.outline and "QuestweaverFontOutline" or "QuestweaverFontHighlight")
    f.sub:SetFontObject(t.outline and "QuestweaverFontOutlineSmall" or "QuestweaverFontSmallDim")
    -- bandeau du titre : à l'intérieur de la bordure du thème
    if t.header then
        local i = t.inset or 0
        f.header:ClearAllPoints()
        f.header:SetPoint("TOPLEFT", f, "TOPLEFT", i, -i)
        f.header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -i, -i)
        f.header:SetHeight(26 - i)
        f.header:SetVertexColor(t.header[1], t.header[2], t.header[3], t.header[4] or 1)
        f.header:Show()
    else
        f.header:Hide()
    end
    M.Recolor()
end

-- Couleurs propres à la fenêtre du guide (parchemin du thème Classic : texte sombre). Reposées
-- après chaque changement de police, qui peut rendre aux textes la couleur de leur objet de police.
function M.Recolor()
    local t = ns.Theme()
    if not t.outline then
        f.text:SetTextColor(ns.GuideColor("text"))
        f.sub:SetTextColor(ns.GuideColor("dim"))
    end
    f.dist:SetTextColor(ns.GuideColor("accent"))
    -- le titre et la progression sont sur le bandeau quand le thème en a un
    f.title:SetTextColor(unpack(t.accent))
    if t.header or not t.guide then f.progress:SetTextColor(0.55, 0.55, 0.58) else f.progress:SetTextColor(ns.GuideColor("dim")) end
    f.zoneArrow:SetVertexColor(t.accent[1], t.accent[2], t.accent[3], 0.9)
end
ns.On("FP_THEME_CHANGED", function() M:ApplyLook(); if M.enabled then M:Update() end end)
ns.On("FP_FONTS_APPLIED", function() if M.enabled then M.Recolor(); M:Layout() end end)

function M:OnEnable() self:ApplyLook(); f:Show(); self:Update() end
function M:OnDisable() f:Hide() end
function M:OnOptionChanged() self:ApplyLook(); self:Update() end
function M:Toggle()
    if f:IsShown() then f:Hide() else f:Show(); self:Update() end
end

M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("FP_TICK", function() if f:IsShown() then M:UpdateDistance() end end)
M:On("QUEST_DATA_LOAD_RESULT", function() M:Update() end)
