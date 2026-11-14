local _, ns = ...

-- Panneau d'options : une carte par module, avec aperçu vivant, case à cocher et réglages.
local O = {}
ns.Options = O

local CATEGORIES = {
    { id = "look", label = "Apparence" },
    { id = "core", label = "Guide" }, { id = "guide", label = "Guide" },
    { id = "nav", label = "Navigation" }, { id = "targets", label = "Repérage" },
    { id = "comfort", label = "Confort" }, { id = "safety", label = "Sécurité" },
    { id = "community", label = "Communauté" },
}
local CAT_ORDER, CAT_LABEL = {}, {}
for i, c in ipairs(CATEGORIES) do CAT_ORDER[c.id] = i; CAT_LABEL[c.id] = c.label end

local PATH_LABELS = {
    ["alliance-human"] = "Humain (Elwynn)", ["alliance-dwarf"] = "Nain / Gnome (Dun Morogh)",
    ["alliance-nightelf"] = "Elfe de la nuit (Teldrassil)", ["horde-orc"] = "Orc / Troll (Durotar)",
    ["horde-tauren"] = "Tauren (Mulgore)", ["horde-undead"] = "Mort-vivant (Tirisfal)",
    ["skyborne-alliance"] = "Éolide (Île de Zéphras)", ["skyborne-horde"] = "Éolide (Île de Zéphras)",
}

local W, H, CARD_W = 780, 560, 368

local f = CreateFrame("Frame", "ForeverPathOptions", UIParent, "BackdropTemplate")
f:SetSize(W, H)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:SetToplevel(true)
f:Hide()
ns.Skin(f, 0.96)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
tinsert(UISpecialFrames, "ForeverPathOptions")

f.title = f:CreateFontString(nil, "OVERLAY", "ForeverPathFontHuge")
f.title:SetPoint("TOPLEFT", 16, -12)
f.title:SetText("|cffd4af37ForeverPath|r")
f.ver = f:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallDim")
f.ver:SetPoint("LEFT", f.title, "RIGHT", 8, -3)
f.sub = f:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4)
f.sub:SetText("Coche ce que tu veux utiliser. Tout s'applique immédiatement.")

local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 0, 0)

-- Barre de route
local route = CreateFrame("Frame", nil, f, "BackdropTemplate")
route:SetPoint("TOPLEFT", 12, -58)
route:SetPoint("TOPRIGHT", -12, -58)
route:SetHeight(34)
ns.Skin(route, 0.5, 0.3)
route.label = route:CreateFontString(nil, "OVERLAY", "ForeverPathFontNormal")
route.label:SetPoint("LEFT", 10, 0)
route.label:SetText("Route :")
route.value = route:CreateFontString(nil, "OVERLAY", "ForeverPathFontHighlight")
route.value:SetPoint("LEFT", route.label, "RIGHT", 8, 0)
route.change = ns.Button(route, "Changer", 80, 22)
route.change:SetPoint("RIGHT", -8, 0)
route.reset = ns.Button(route, "Recommencer le segment", 170, 22)
route.reset:SetPoint("RIGHT", route.change, "LEFT", -6, 0)

local menu = CreateFrame("Frame", nil, f, "BackdropTemplate")
menu:SetFrameStrata("FULLSCREEN_DIALOG")
menu:SetSize(260, 10)
menu:Hide()
ns.Skin(menu, 0.98)
menu.buttons = {}

local function pathsForFaction()
    local seen, list = {}, {}
    local faction = ns.PlayerFaction()
    for _, id in ipairs(ns.GuideOrder) do
        local g = ns.Guides[id]
        if g.path and not seen[g.path] and (not g.faction or g.faction == faction) then
            seen[g.path] = true
            list[#list + 1] = g.path
        end
    end
    return list
end

local function openMenu()
    local items = { { label = "Automatique (race et niveau)", path = false } }
    for _, p in ipairs(pathsForFaction()) do items[#items + 1] = { label = PATH_LABELS[p] or p, path = p } end
    for i, it in ipairs(items) do
        local b = menu.buttons[i]
        if not b then
            b = CreateFrame("Button", nil, menu)
            b:SetSize(244, 20)
            b.text = b:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
            b.text:SetPoint("LEFT", 6, 0)
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            menu.buttons[i] = b
        end
        b:SetPoint("TOPLEFT", 8, -8 - (i - 1) * 21)
        b.text:SetText(it.label)
        b:SetScript("OnClick", function()
            ns.cdb.path = it.path or nil
            local id = ns.Engine.PickDefault()
            if id then ns.Engine.Load(id) end
            menu:Hide()
            O:Refresh()
        end)
        b:Show()
    end
    for i = #items + 1, #menu.buttons do menu.buttons[i]:Hide() end
    menu:SetHeight(16 + #items * 21)
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", route.change, "BOTTOMRIGHT", 0, -2)
    menu:Show()
end
route.change:SetScript("OnClick", function() if menu:IsShown() then menu:Hide() else openMenu() end end)
route.reset:SetScript("OnClick", function()
    local id = ns.cdb.guideId
    if id then ns.cdb.skipped[id] = {}; ns.Engine.Load(id) end
end)

-- Zone défilante des cartes
local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 12, -100)
scroll:SetPoint("BOTTOMRIGHT", -32, 44)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(W - 50, 10)
scroll:SetScrollChild(content)

-- Pied
local allOn = ns.Button(f, "Tout activer", 110, 22, function()
    for _, id in ipairs(ns.ModuleOrder) do ns.SetModuleEnabled(id, true) end
    O:Refresh()
end)
allOn:SetPoint("BOTTOMLEFT", 12, 12)
local defaults = ns.Button(f, "Réglages recommandés", 160, 22, function()
    for _, id in ipairs(ns.ModuleOrder) do ns.SetModuleEnabled(id, ns.Modules[id].default) end
    O:Refresh()
end)
defaults:SetPoint("LEFT", allOn, "RIGHT", 6, 0)
local hint = f:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallDim")
hint:SetPoint("BOTTOMRIGHT", -14, 18)
hint:SetText("/fp config pour rouvrir ce panneau  •  Raccourcis : Options > Raccourcis > ForeverPath")

---------------------------------------------------------------------------
-- Contrôles
---------------------------------------------------------------------------
local function makeCheck(parent, label, get, set)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetSize(22, 22)
    c.label = c:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    c.label:SetPoint("LEFT", c, "RIGHT", 2, 0)
    c.label:SetText(label)
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    c.Sync = function(self) self:SetChecked(get() and true or false) end
    return c, 22
end

local function makeSlider(parent, def, get, set)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(190, 30)
    local lbl = holder:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    lbl:SetPoint("TOPLEFT", 4, 0)
    local s = CreateFrame("Slider", nil, holder, "BackdropTemplate")
    s:SetOrientation("HORIZONTAL")
    s:SetSize(170, 10)
    s:SetPoint("TOPLEFT", 6, -14)
    s:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    s:SetBackdropColor(0, 0, 0, 0.6)
    s:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    s:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local th = s:GetThumbTexture()
    if th then
        th:SetSize(8, 14)
        th:SetVertexColor(unpack(ns.Theme().accent))
    end
    s:SetMinMaxValues(def.min, def.max)
    s:SetValueStep(def.step or 1)
    s:SetObeyStepOnDrag(true)
    local function label(v)
        local txt = (def.step or 1) < 1 and ("%.2f"):format(v) or tostring(math.floor(v + 0.5))
        lbl:SetText(def.label .. " : |cffffd100" .. txt .. "|r")
    end
    s:SetScript("OnValueChanged", function(_, v, user)
        label(v)
        if user then set(v) end
    end)
    holder.Sync = function() local v = get() or def.default; s:SetValue(v); label(v) end
    return holder, 32
end

-- Sélecteur « < valeur > ». def.values : liste ou fonction ; def.store = "value" pour
-- mémoriser le libellé (listes dynamiques, ex. polices) plutôt que l'index.
local function makeSelect(parent, def, get, set)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(330, 22)
    local lbl = holder:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    lbl:SetPoint("LEFT", 4, 0)
    lbl:SetText(def.label .. " :")
    local prev = ns.Button(holder, "<", 20, 18)
    local val = holder:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallGold")
    local nxt = ns.Button(holder, ">", 20, 18)
    local w = def.width or 90
    prev:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
    val:SetPoint("LEFT", prev, "RIGHT", 4, 0)
    val:SetWidth(w)
    val:SetWordWrap(false)
    nxt:SetPoint("LEFT", prev, "RIGHT", w + 8, 0)
    local function values()
        return type(def.values) == "function" and def.values() or def.values
    end
    local function index()
        local list, cur = values(), get()
        if def.store == "value" then
            for i, v in ipairs(list) do if v == cur then return i end end
            return 1
        end
        return cur or def.default or 1
    end
    local function step(d)
        local list = values()
        local i = index() + d
        if i < 1 then i = #list elseif i > #list then i = 1 end
        set(def.store == "value" and list[i] or i)
        holder.Sync()
    end
    prev:SetScript("OnClick", function() step(-1) end)
    nxt:SetScript("OnClick", function() step(1) end)
    holder.Sync = function() val:SetText(values()[index()] or "?") end
    return holder, 24
end

---------------------------------------------------------------------------
-- Cartes
---------------------------------------------------------------------------
local cards = {}

local function buildCard(m)
    local c = CreateFrame("Frame", nil, content, "BackdropTemplate")
    c:SetWidth(CARD_W)
    ns.Skin(c, 0.55, 0.25)

    -- aperçu
    c.pv = CreateFrame("Frame", nil, c, "BackdropTemplate")
    c.pv:SetSize(150, 90)
    c.pv:SetPoint("TOPLEFT", 8, -8)
    c.pv:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    c.pv:SetBackdropColor(0.12, 0.13, 0.16, 1)
    c.pv:SetClipsChildren(true)
    if m.preview then
        local ok, err = pcall(m.preview, c.pv)
        if not ok then geterrorhandler()(err) end
    end

    -- titre + case (les modules « locked » sont toujours actifs : pas de case)
    c.check = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    c.check:SetSize(24, 24)
    c.check:SetPoint("TOPLEFT", c.pv, "TOPRIGHT", 6, 2)
    if m.locked then c.check:Hide() end
    c.check:SetScript("OnClick", function(self)
        ns.SetModuleEnabled(m.id, self:GetChecked() and true or false)
        O:SyncCard(c)
    end)
    c.name = c:CreateFontString(nil, "OVERLAY", "ForeverPathFontNormal")
    c.name:SetPoint("LEFT", c.check, "RIGHT", 2, 0)
    c.name:SetPoint("RIGHT", c, "RIGHT", -8, 0)
    c.name:SetJustifyH("LEFT")
    c.name:SetText(m.name)
    c.cat = c:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallDim")
    c.cat:SetPoint("TOPRIGHT", -8, -8)
    c.cat:SetText(CAT_LABEL[m.category] or "")

    c.desc = c:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    c.desc:SetPoint("TOPLEFT", c.check, "BOTTOMLEFT", 4, -2)
    c.desc:SetWidth(CARD_W - 150 - 30)
    c.desc:SetJustifyH("LEFT")
    c.desc:SetSpacing(2)
    c.desc:SetTextColor(0.8, 0.8, 0.8)
    c.desc:SetText(m.desc or "")

    -- options du module, sous l'aperçu (largeur complète)
    c.controls = {}
    local descH = 34 + c.desc:GetStringHeight()
    local y = -math.max(106, descH + 6)
    for _, def in ipairs(m.options or {}) do
        local get = function() return m:Opt(def.key) end
        local set = function(v) m:SetOpt(def.key, v) end
        local ctl, h
        if def.type == "check" then ctl, h = makeCheck(c, def.label, get, set)
        elseif def.type == "slider" then ctl, h = makeSlider(c, def, get, set)
        elseif def.type == "select" then ctl, h = makeSelect(c, def, get, set) end
        if ctl then
            ctl:SetPoint("TOPLEFT", 10, y)
            y = y - h - 2
            c.controls[#c.controls + 1] = ctl
        end
    end
    c.height = math.max(106, descH, -y + 6)
    c:SetHeight(c.height)
    c.module = m
    return c
end

function O:SyncCard(c)
    local on = c.module.locked or ns.WantsEnabled(c.module.id)
    c.check:SetChecked(on)
    local a = ns.Theme().accent
    if on then c.name:SetTextColor(a[1], a[2], a[3]) else c.name:SetTextColor(0.6, 0.6, 0.6) end
    c.pv:SetAlpha(on and 1 or 0.4)
    for _, ctl in ipairs(c.controls) do
        if ctl.Sync then ctl:Sync() end
        ctl:SetAlpha(on and 1 or 0.4)
    end
end

function O:Build()
    if self.built then return end
    self.built = true
    local list = {}
    for _, id in ipairs(ns.ModuleOrder) do list[#list + 1] = ns.Modules[id] end
    table.sort(list, function(a, b)
        local ca, cb = CAT_ORDER[a.category] or 99, CAT_ORDER[b.category] or 99
        if ca ~= cb then return ca < cb end
        return a.name < b.name
    end)
    -- deux colonnes, placement en « maçonnerie »
    local colY = { 0, 0 }
    for _, m in ipairs(list) do
        local c = buildCard(m)
        local col = colY[1] <= colY[2] and 1 or 2
        c:SetPoint("TOPLEFT", content, "TOPLEFT", (col - 1) * (CARD_W + 10), -colY[col])
        colY[col] = colY[col] + c.height + 10
        cards[#cards + 1] = c
    end
    content:SetHeight(math.max(colY[1], colY[2]))
end

function O:Refresh()
    if not f:IsShown() then return end
    f.ver:SetText("v" .. ns.VERSION)
    local g = ns.Engine.Current()
    local pathLabel = ns.cdb.path and (PATH_LABELS[ns.cdb.path] or ns.cdb.path) or "Automatique"
    route.value:SetText(("%s  —  |cffffffff%s|r"):format(pathLabel, g and g.name or "aucun segment"))
    for _, c in ipairs(cards) do self:SyncCard(c) end
end

function O:Open()
    self:Build()
    f:Show()
    self:Refresh()
end
function O:Toggle() if f:IsShown() then f:Hide() else self:Open() end end
f:SetScript("OnHide", function() menu:Hide() end)
ns.On("FP_STEP_CHANGED", function() O:Refresh() end)
ns.On("FP_THEME_CHANGED", function() O:Refresh() end)

-- Entrée dans le menu Options de Blizzard
ns.On("FP_READY", function()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    local panel = CreateFrame("Frame")
    local t = panel:CreateFontString(nil, "OVERLAY", "ForeverPathFontHuge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText("ForeverPath")
    local d = panel:CreateFontString(nil, "OVERLAY", "ForeverPathFontHighlight")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    d:SetText("Guide de leveling gratuit pour WoW Forever.")
    local b = ns.Button(panel, "Ouvrir le panneau ForeverPath", 240, 26, function()
        if SettingsPanel then HideUIPanel(SettingsPanel) end
        O:Open()
    end)
    b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)
    local cat = Settings.RegisterCanvasLayoutCategory(panel, "ForeverPath")
    Settings.RegisterAddOnCategory(cat)
end)
