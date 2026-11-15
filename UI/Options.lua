local _, ns = ...

-- Panneau d'options, en trois colonnes :
--   à gauche  : Accueil (route, profils rapides) puis les catégories, avec le nombre de modules actifs ;
--   au milieu : les modules de la catégorie, une ligne chacun (case, nom, résumé) ;
--   à droite  : le module choisi en grand (aperçu vivant, description complète, réglages).
-- Une recherche en haut filtre tous les modules d'un coup.
local O = {}
ns.Options = O

local CATEGORIES = {
    { id = "guide", label = "Guide", icon = "Interface\\Icons\\INV_Misc_Book_09", ids = { core = true, guide = true } },
    { id = "nav", label = ns.Tr("Navigation"), icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = "targets", label = ns.Tr("Repérage"), icon = "Interface\\Icons\\Ability_Hunter_SniperShot" },
    { id = "comfort", label = ns.Tr("Confort"), icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    { id = "safety", label = ns.Tr("Sécurité"), icon = "Interface\\Icons\\Spell_Holy_SealOfProtection" },
    { id = "community", label = ns.Tr("Communauté"), icon = "Interface\\Icons\\INV_Misc_GroupNeedMore" },
    { id = "look", label = ns.Tr("Apparence"), icon = "Interface\\Icons\\INV_Misc_Gem_Variety_01" },
}
local CAT_OF = {}      -- catégorie de module -> entrée de CATEGORIES
for _, c in ipairs(CATEGORIES) do
    for k in pairs(c.ids or { [c.id] = true }) do CAT_OF[k] = c end
end

local PATH_LABELS = {
    ["alliance-human"] = "Humain (Elwynn)", ["alliance-dwarf"] = "Nain / Gnome (Dun Morogh)",
    ["alliance-nightelf"] = "Elfe de la nuit (Teldrassil)", ["horde-orc"] = "Orc / Troll (Durotar)",
    ["horde-tauren"] = "Tauren (Mulgore)", ["horde-undead"] = "Mort-vivant (Tirisfal)",
    ["alliance-skyborne"] = "Éolide (Île de Zéphras)", ["horde-skyborne"] = "Éolide (Île de Zéphras)",
}

local W, H = 920, 600
local SIDE_W, LIST_W, ROW_H = 176, 300, 46
local TOP, BOTTOM = -64, 44

local f = CreateFrame("Frame", "QuestweaverOptions", UIParent, "BackdropTemplate")
f:SetSize(W, H)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:SetToplevel(true)
f:Hide()
ns.Skin(f, 0.96)
f:EnableMouse(true)
f:SetMovable(true)
f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
tinsert(UISpecialFrames, "QuestweaverOptions")

f.title = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontHuge")
f.title:SetPoint("TOPLEFT", 16, -12)
f.title:SetText("|cffd4af37Questweaver|r")
f.ver = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
f.ver:SetPoint("LEFT", f.title, "RIGHT", 8, -3)
f.sub = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4)
f.sub:SetText(ns.Tr("Coche ce que tu veux utiliser. Tout s'applique immédiatement."))

local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 0, 0)

-- Recherche
local search = CreateFrame("EditBox", nil, f, "BackdropTemplate")
search:SetSize(220, 24)
search:SetPoint("TOPRIGHT", -40, -16)
search:SetAutoFocus(false)
search:SetFontObject("QuestweaverFontHighlight")
search:SetTextInsets(24, 8, 0, 0)
ns.Skin(search, 0.6, 0.35)
search.icon = search:CreateTexture(nil, "OVERLAY")
search.icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
search.icon:SetSize(14, 14)
search.icon:SetPoint("LEFT", 6, 0)
search.hint = search:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
search.hint:SetPoint("LEFT", 24, 0)
search.hint:SetText(ns.Tr("Rechercher un module…"))
search:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

-- Pied
local footer = {}
footer.defaults = ns.Button(f, ns.Tr("Réglages recommandés"), 160, 22)
footer.defaults:SetPoint("BOTTOMLEFT", 12, 12)
footer.allOn = ns.Button(f, ns.Tr("Tout activer"), 110, 22)
footer.allOn:SetPoint("LEFT", footer.defaults, "RIGHT", 6, 0)
local hint = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
hint:SetPoint("BOTTOMRIGHT", -14, 18)
hint:SetText(ns.Tr("/qw config pour rouvrir ce panneau  •  Raccourcis : Options > Raccourcis > Questweaver"))

---------------------------------------------------------------------------
-- Contrôles des réglages
---------------------------------------------------------------------------
local function makeCheck(parent, label, get, set)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetSize(22, 22)
    c.label = c:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    c.label:SetPoint("LEFT", c, "RIGHT", 2, 0)
    c.label:SetText(label)
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    c.Sync = function(self) self:SetChecked(get() and true or false) end
    return c, 22
end

local function makeSlider(parent, def, get, set)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(190, 30)
    local lbl = holder:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
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
    local lbl = holder:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    lbl:SetPoint("LEFT", 4, 0)
    lbl:SetText(def.label .. " :")
    local prev = ns.Button(holder, "<", 20, 18)
    local val = holder:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
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
-- Colonne de gauche : Accueil + catégories
---------------------------------------------------------------------------
local side = CreateFrame("Frame", nil, f, "BackdropTemplate")
side:SetPoint("TOPLEFT", 12, TOP)
side:SetPoint("BOTTOMLEFT", 12, BOTTOM)
side:SetWidth(SIDE_W)
ns.Skin(side, 0.35, 0.2)

local state = { view = "home", module = nil, query = "" }
local navButtons = {}

local function navButton(i, key, label, icon)
    local b = CreateFrame("Button", nil, side, "BackdropTemplate")
    b:SetSize(SIDE_W - 12, 34)
    b:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 37)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(20, 20)
    b.icon:SetPoint("LEFT", 8, 0)
    b.icon:SetTexture(icon)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.label = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
    b.label:SetPoint("LEFT", b.icon, "RIGHT", 8, 0)
    b.label:SetText(label)
    b.count = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
    b.count:SetPoint("RIGHT", -8, 0)
    b.key = key
    b:SetScript("OnEnter", function(self) self.hover = true; O:PaintNav() end)
    b:SetScript("OnLeave", function(self) self.hover = false; O:PaintNav() end)
    b:SetScript("OnClick", function()
        search:SetText(""); search:ClearFocus()
        O:Show(key)
    end)
    navButtons[#navButtons + 1] = b
    return b
end

navButton(1, "home", ns.Tr("Accueil"), "Interface\\Icons\\INV_Misc_Note_01")
for i, c in ipairs(CATEGORIES) do navButton(i + 1, c.id, c.label, c.icon) end

function O:PaintNav()
    local a = ns.Theme().accent
    for _, b in ipairs(navButtons) do
        local sel = state.query == "" and state.view == b.key
        if sel then
            b:SetBackdropColor(a[1], a[2], a[3], 0.22)
            b.label:SetTextColor(1, 1, 1)
        else
            b:SetBackdropColor(1, 1, 1, b.hover and 0.06 or 0)
            b.label:SetTextColor(a[1], a[2], a[3])
        end
    end
end

---------------------------------------------------------------------------
-- Données : modules par catégorie
---------------------------------------------------------------------------
local byCat, allModules = {}, {}
local function indexModules()
    wipe(byCat); wipe(allModules)
    for _, id in ipairs(ns.ModuleOrder) do
        local m = ns.Modules[id]
        local c = CAT_OF[m.category] or CATEGORIES[#CATEGORIES]
        byCat[c.id] = byCat[c.id] or {}
        table.insert(byCat[c.id], m)
        allModules[#allModules + 1] = m
    end
    local function cmp(a, b) return a.name < b.name end
    for _, list in pairs(byCat) do table.sort(list, cmp) end
    table.sort(allModules, cmp)
end

local function isOn(m) return m.locked or ns.WantsEnabled(m.id) end

-- recherche insensible à la casse et aux accents
local ACCENTS = { ["à"]="a", ["â"]="a", ["ä"]="a", ["ç"]="c", ["é"]="e", ["è"]="e", ["ê"]="e", ["ë"]="e",
    ["î"]="i", ["ï"]="i", ["ô"]="o", ["ö"]="o", ["ù"]="u", ["û"]="u", ["ü"]="u", ["ñ"]="n", ["ß"]="ss" }
local function fold(s)
    s = (s or ""):lower()
    return (s:gsub("[\195][\128-\191]", function(ch) return ACCENTS[ch] or ch end))
end

local function filtered()
    if state.query ~= "" then
        local q, out = fold(state.query), {}
        for _, m in ipairs(allModules) do
            if fold(m.name):find(q, 1, true) or fold(m.desc):find(q, 1, true) then out[#out + 1] = m end
        end
        return out
    end
    return byCat[state.view] or {}
end

---------------------------------------------------------------------------
-- Accueil : route + profils rapides
---------------------------------------------------------------------------
local home = CreateFrame("Frame", nil, f)
home:SetPoint("TOPLEFT", side, "TOPRIGHT", 10, 0)
home:SetPoint("BOTTOMRIGHT", -12, BOTTOM)

local function header(parent, text, anchor, y)
    local h = parent:CreateFontString(nil, "OVERLAY", "QuestweaverFontLarge")
    if anchor then h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y or -18) else h:SetPoint("TOPLEFT", 4, -2) end
    h:SetText(text)
    return h
end

local routeTitle = header(home, ns.Tr("Ta route"))
local route = CreateFrame("Frame", nil, home, "BackdropTemplate")
route:SetPoint("TOPLEFT", routeTitle, "BOTTOMLEFT", -4, -8)
route:SetPoint("RIGHT", home, "RIGHT", 0, 0)
route:SetHeight(40)
ns.Skin(route, 0.5, 0.3)
route.value = route:CreateFontString(nil, "OVERLAY", "QuestweaverFontHighlight")
route.value:SetPoint("LEFT", 12, 0)
route.value:SetPoint("RIGHT", -290, 0)
route.value:SetJustifyH("LEFT")
route.value:SetWordWrap(false)
route.change = ns.Button(route, ns.Tr("Changer"), 90, 24)
route.change:SetPoint("RIGHT", -8, 0)
route.reset = ns.Button(route, ns.Tr("Recommencer le segment"), 180, 24)
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
    local items = { { label = ns.Tr("Automatique (race et niveau)"), path = false } }
    for _, p in ipairs(pathsForFaction()) do items[#items + 1] = { label = PATH_LABELS[p] or p, path = p } end
    for i, it in ipairs(items) do
        local b = menu.buttons[i]
        if not b then
            b = CreateFrame("Button", nil, menu)
            b:SetSize(244, 20)
            b.text = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
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

local presetTitle = header(home, ns.Tr("Profils rapides"), route, -22)
presetTitle:SetPoint("TOPLEFT", route, "BOTTOMLEFT", 4, -22)
local presetHint = home:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
presetHint:SetPoint("TOPLEFT", presetTitle, "BOTTOMLEFT", 0, -4)
presetHint:SetText(ns.Tr("Un clic coche les bons modules d'un coup. Tu peux ensuite affiner catégorie par catégorie."))
local presetButtons = {}

local summaryTitle = home:CreateFontString(nil, "OVERLAY", "QuestweaverFontLarge")
local summary = home:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
summary:SetJustifyH("LEFT")
summary:SetSpacing(3)

local function buildPresets()
    local P = ns.Modules.profiles
    if not (P and P.PRESETS) or #presetButtons > 0 then return end
    local bw = (W - SIDE_W - 34 - 10) / 2
    for i, p in ipairs(P.PRESETS) do
        local b = CreateFrame("Button", nil, home, "BackdropTemplate")
        b:SetSize(bw, 70)
        b:SetPoint("TOPLEFT", presetHint, "BOTTOMLEFT", -4 + ((i - 1) % 2) * (bw + 10), -10 - math.floor((i - 1) / 2) * 78)
        ns.Skin(b, 0.55, 0.3)
        local ic = b:CreateTexture(nil, "ARTWORK")
        ic:SetSize(32, 32); ic:SetPoint("TOPLEFT", 10, -10); ic:SetTexture(p.icon)
        local n = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
        n:SetPoint("TOPLEFT", ic, "TOPRIGHT", 10, -1); n:SetText(p.name)
        local d = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
        d:SetPoint("TOPLEFT", n, "BOTTOMLEFT", 0, -4); d:SetPoint("RIGHT", -10, 0)
        d:SetJustifyH("LEFT"); d:SetText(p.desc); d:SetTextColor(0.8, 0.8, 0.8)
        b:SetScript("OnEnter", function(self) local a = ns.Theme().accent; self:SetBackdropBorderColor(a[1], a[2], a[3], 1) end)
        b:SetScript("OnLeave", function(self) ns.ReSkin(self) end)
        b:SetScript("OnClick", function()
            P.Apply(p.key)
            ns.Toast(ns.Tr("Profil appliqué : ") .. p.name, p.icon)
            O:Refresh()
        end)
        presetButtons[i] = b
    end
    summaryTitle:SetPoint("TOPLEFT", presetButtons[#presetButtons - 1] or presetButtons[1], "BOTTOMLEFT", 4, -22)
    summaryTitle:SetText(ns.Tr("Tes modules"))
    summary:SetPoint("TOPLEFT", summaryTitle, "BOTTOMLEFT", 0, -8)
    summary:SetPoint("RIGHT", home, "RIGHT", -8, 0)
end

---------------------------------------------------------------------------
-- Liste des modules (colonne du milieu)
---------------------------------------------------------------------------
local list = CreateFrame("Frame", nil, f, "BackdropTemplate")
list:SetPoint("TOPLEFT", side, "TOPRIGHT", 10, 0)
list:SetPoint("BOTTOMLEFT", side, "BOTTOMRIGHT", 10, 0)
list:SetWidth(LIST_W)
ns.Skin(list, 0.35, 0.2)
list.title = list:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
list.title:SetPoint("TOPLEFT", 10, -9)
list.count = list:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
list.count:SetPoint("TOPRIGHT", -10, -10)
list.empty = list:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
list.empty:SetPoint("TOP", 0, -60)
list.empty:SetText(ns.Tr("Aucun module ne correspond."))

local listScroll = CreateFrame("ScrollFrame", nil, list, "UIPanelScrollFrameTemplate")
listScroll:SetPoint("TOPLEFT", 4, -30)
listScroll:SetPoint("BOTTOMRIGHT", -26, 4)
local listContent = CreateFrame("Frame", nil, listScroll)
listContent:SetSize(LIST_W - 30, 10)
listScroll:SetScrollChild(listContent)
local rows = {}

local function row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, listContent, "BackdropTemplate")
    r:SetSize(LIST_W - 32, ROW_H - 2)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    r.check = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.check:SetSize(24, 24)
    r.check:SetPoint("LEFT", 4, 0)
    r.check:SetScript("OnClick", function(self)
        ns.SetModuleEnabled(r.module.id, self:GetChecked() and true or false)
        O:Refresh()
    end)
    r.lock = r:CreateTexture(nil, "ARTWORK")
    r.lock:SetSize(14, 14)
    r.lock:SetPoint("CENTER", r.check, "CENTER")
    r.lock:SetTexture("Interface\\PetBattles\\PetBattle-LockIcon")
    r.name = r:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
    r.name:SetPoint("TOPLEFT", r.check, "TOPRIGHT", 4, -1)
    r.name:SetPoint("RIGHT", -34, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.desc = r:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
    r.desc:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
    r.desc:SetPoint("RIGHT", -10, 0)
    r.desc:SetJustifyH("LEFT")
    r.desc:SetWordWrap(false)
    r.gear = r:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
    r.gear:SetPoint("TOPRIGHT", -8, -6)
    r:SetScript("OnEnter", function(self) self.hover = true; O:PaintRows() end)
    r:SetScript("OnLeave", function(self) self.hover = false; O:PaintRows() end)
    r:SetScript("OnClick", function(self) O:Select(self.module) end)
    rows[i] = r
    return r
end

-- premier morceau de la description, pour tenir sur une ligne
local function short(desc)
    desc = desc or ""
    local first = desc:match("^(.-[%.:;!])%s") or desc
    return first
end

function O:PaintRows()
    local a = ns.Theme().accent
    for _, r in ipairs(rows) do
        if r:IsShown() then
            local on, sel = isOn(r.module), r.module == state.module
            if sel then r:SetBackdropColor(a[1], a[2], a[3], 0.2)
            else r:SetBackdropColor(1, 1, 1, r.hover and 0.05 or 0) end
            if on then r.name:SetTextColor(a[1], a[2], a[3]) else r.name:SetTextColor(0.55, 0.55, 0.55) end
        end
    end
end

function O:FillList()
    local mods = filtered()
    for i, m in ipairs(mods) do
        local r = row(i)
        r.module = m
        r.name:SetText(m.name)
        r.desc:SetText(short(m.desc))
        r.check:SetShown(not m.locked)
        r.lock:SetShown(m.locked and true or false)
        r.check:SetChecked(isOn(m))
        local n = #(m.options or {})
        r.gear:SetText(n > 0 and ("|TInterface\\Buttons\\UI-OptionsButton:0|t " .. n) or "")
        r:Show()
    end
    for i = #mods + 1, #rows do rows[i]:Hide() end
    listContent:SetHeight(math.max(10, #mods * ROW_H))
    list.empty:SetShown(#mods == 0)
    local on = 0
    for _, m in ipairs(mods) do if isOn(m) then on = on + 1 end end
    list.count:SetText((ns.Tr("%d / %d actifs")):format(on, #mods))
    if state.query ~= "" then
        list.title:SetText(ns.Tr("Résultats"))
    else
        for _, c in ipairs(CATEGORIES) do if c.id == state.view then list.title:SetText(c.label) end end
    end
    self:PaintRows()
    return mods
end

---------------------------------------------------------------------------
-- Détail du module (colonne de droite)
---------------------------------------------------------------------------
local detail = CreateFrame("Frame", nil, f, "BackdropTemplate")
detail:SetPoint("TOPLEFT", list, "TOPRIGHT", 10, 0)
detail:SetPoint("BOTTOMRIGHT", -12, BOTTOM)
ns.Skin(detail, 0.35, 0.2)
local DETAIL_W = W - 12 - SIDE_W - 10 - LIST_W - 10 - 12

-- aperçu : les aperçus des modules sont dessinés pour 150 × 90, on les agrandit
local PV_SCALE = 1.6
local pvHolder = CreateFrame("Frame", nil, detail, "BackdropTemplate")
pvHolder:SetSize(150 * PV_SCALE + 8, 90 * PV_SCALE + 8)
pvHolder:SetPoint("TOP", 0, -12)
ns.Skin(pvHolder, 0.6, 0.3)
local previews = {}

local function previewFor(m)
    local p = previews[m.id]
    if p == nil then
        p = CreateFrame("Frame", nil, pvHolder, "BackdropTemplate")
        p:SetSize(150, 90)
        p:SetScale(PV_SCALE)
        p:SetPoint("CENTER")
        p:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        p:SetBackdropColor(0.12, 0.13, 0.16, 1)
        p:SetClipsChildren(true)
        if m.preview then
            local ok, err = pcall(m.preview, p)
            if not ok then geterrorhandler()(err) end
        else
            local ic = p:CreateTexture(nil, "ARTWORK")
            ic:SetSize(36, 36); ic:SetPoint("CENTER")
            ic:SetTexture((CAT_OF[m.category] or CATEGORIES[1]).icon)
            ic:SetDesaturated(true); ic:SetAlpha(0.5)
        end
        previews[m.id] = p
    end
    return p
end

local dScroll = CreateFrame("ScrollFrame", nil, detail, "UIPanelScrollFrameTemplate")
dScroll:SetPoint("TOPLEFT", pvHolder, "BOTTOMLEFT", -2, -10)
dScroll:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -26, 6)
local dContent = CreateFrame("Frame", nil, dScroll)
dContent:SetSize(DETAIL_W - 34, 10)
dScroll:SetScrollChild(dContent)

local dName = dContent:CreateFontString(nil, "OVERLAY", "QuestweaverFontLarge")
dName:SetPoint("TOPLEFT", 10, -2)
dName:SetPoint("RIGHT", -10, 0)
dName:SetJustifyH("LEFT")
local dCat = dContent:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
dCat:SetPoint("TOPLEFT", dName, "BOTTOMLEFT", 0, -3)
local dToggle = CreateFrame("CheckButton", nil, dContent, "UICheckButtonTemplate")
dToggle:SetSize(26, 26)
dToggle:SetPoint("TOPLEFT", dCat, "BOTTOMLEFT", -4, -6)
dToggle.label = dToggle:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
dToggle.label:SetPoint("LEFT", dToggle, "RIGHT", 2, 0)
dToggle:SetScript("OnClick", function(self)
    if state.module then ns.SetModuleEnabled(state.module.id, self:GetChecked() and true or false) end
    O:Refresh()
end)
local dDesc = dContent:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
dDesc:SetPoint("TOPLEFT", dToggle, "BOTTOMLEFT", 4, -6)
dDesc:SetWidth(DETAIL_W - 54)
dDesc:SetJustifyH("LEFT")
dDesc:SetSpacing(3)
dDesc:SetTextColor(0.85, 0.85, 0.85)
local dOptTitle = dContent:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
dOptTitle:SetText(ns.Tr("Réglages"))
local dNoOpt = dContent:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
dNoOpt:SetText(ns.Tr("Aucun réglage pour ce module."))
local dEmpty = detail:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
dEmpty:SetPoint("CENTER")
dEmpty:SetText(ns.Tr("Choisis un module dans la liste."))
local controlSets = {}   -- [module id] = { holder, controls, height }

local function controlsFor(m)
    local set = controlSets[m.id]
    if set then return set end
    local holder = CreateFrame("Frame", nil, dContent)
    holder:SetSize(DETAIL_W - 40, 10)
    local ctls, y = {}, 0
    for _, def in ipairs(m.options or {}) do
        local get = function() return m:Opt(def.key) end
        local setv = function(v) m:SetOpt(def.key, v) end
        local ctl, h
        if def.type == "check" then ctl, h = makeCheck(holder, def.label, get, setv)
        elseif def.type == "slider" then ctl, h = makeSlider(holder, def, get, setv)
        elseif def.type == "select" then ctl, h = makeSelect(holder, def, get, setv) end
        if ctl then
            ctl:SetPoint("TOPLEFT", 0, y)
            y = y - h - 4
            ctls[#ctls + 1] = ctl
        end
    end
    holder:SetHeight(math.max(10, -y))
    set = { holder = holder, controls = ctls, height = -y }
    controlSets[m.id] = set
    return set
end

function O:FillDetail()
    for _, p in pairs(previews) do p:Hide() end
    for _, s in pairs(controlSets) do s.holder:Hide() end
    local m = state.module
    local shown = m ~= nil
    pvHolder:SetShown(shown); dScroll:SetShown(shown); dEmpty:SetShown(not shown)
    if not m then return end
    local on = isOn(m)
    local p = previewFor(m)
    p:Show()
    p:SetAlpha(on and 1 or 0.45)
    local a = ns.Theme().accent
    dName:SetText(m.name)
    if on then dName:SetTextColor(a[1], a[2], a[3]) else dName:SetTextColor(0.6, 0.6, 0.6) end
    dCat:SetText((CAT_OF[m.category] or CATEGORIES[1]).label)
    dToggle:SetChecked(on)
    dToggle:SetEnabled(not m.locked)
    dToggle.label:SetText(m.locked and ns.Tr("Toujours actif") or (on and ns.Tr("Activé") or ns.Tr("Désactivé")))
    dDesc:SetText(m.desc or "")
    dOptTitle:ClearAllPoints()
    dOptTitle:SetPoint("TOPLEFT", dDesc, "BOTTOMLEFT", 0, -16)
    local set = controlsFor(m)
    dNoOpt:ClearAllPoints()
    dNoOpt:SetPoint("TOPLEFT", dOptTitle, "BOTTOMLEFT", 0, -6)
    dNoOpt:SetShown(#set.controls == 0)
    set.holder:ClearAllPoints()
    set.holder:SetPoint("TOPLEFT", dOptTitle, "BOTTOMLEFT", 0, -8)
    set.holder:Show()
    for _, ctl in ipairs(set.controls) do
        if ctl.Sync then ctl:Sync() end
        ctl:SetAlpha(on and 1 or 0.45)
    end
    local top = 2 + dName:GetStringHeight() + 3 + 14 + 6 + 26 + 6 + dDesc:GetStringHeight() + 16 + 16 + 8
    dContent:SetHeight(top + math.max(20, set.height) + 10)
end

---------------------------------------------------------------------------
-- Navigation entre les vues
---------------------------------------------------------------------------
function O:Select(m)
    state.module = m
    if ns.db and m then ns.db.optModule = m.id end
    self:PaintRows()
    self:FillDetail()
end

function O:Show(view)
    state.view = view or state.view
    if ns.db then ns.db.optView = state.view end
    local isHome = state.query == "" and state.view == "home"
    home:SetShown(isHome)
    list:SetShown(not isHome)
    detail:SetShown(not isHome)
    menu:Hide()
    if not isHome then
        local mods = self:FillList()
        -- garde le module choisi s'il est dans la liste, sinon prend le premier
        local keep = false
        for _, m in ipairs(mods) do if m == state.module then keep = true end end
        if not keep then state.module = mods[1] end
        self:FillDetail()
        listScroll:SetVerticalScroll(0)
    end
    self:PaintNav()
end

search:SetScript("OnTextChanged", function(self)
    state.query = self:GetText() or ""
    self.hint:SetShown(state.query == "")
    O:Show()
end)

footer.defaults:SetScript("OnClick", function()
    for _, id in ipairs(ns.ModuleOrder) do ns.SetModuleEnabled(id, ns.Modules[id].default) end
    O:Refresh()
end)
footer.allOn:SetScript("OnClick", function()
    for _, id in ipairs(ns.ModuleOrder) do ns.SetModuleEnabled(id, true) end
    O:Refresh()
end)

function O:Build()
    if self.built then return end
    self.built = true
    indexModules()
    buildPresets()
    state.view = (ns.db and ns.db.optView) or "home"
    local want = ns.db and ns.db.optModule
    state.module = want and ns.Modules[want] or nil
end

function O:Refresh()
    if not f:IsShown() then return end
    f.ver:SetText("v" .. ns.VERSION)
    -- accueil
    local g = ns.Engine.Current()
    local pathLabel = ns.cdb.path and (PATH_LABELS[ns.cdb.path] or ns.cdb.path) or ns.Tr("Automatique (race et niveau)")
    route.value:SetText(("%s  —  |cffffffff%s|r"):format(pathLabel, g and g.name or ns.Tr("aucun segment")))
    local total, on, lines = 0, 0, {}
    for _, c in ipairs(CATEGORIES) do
        local cn, ct = 0, 0
        for _, m in ipairs(byCat[c.id] or {}) do
            ct = ct + 1
            if isOn(m) then cn = cn + 1 end
        end
        total, on = total + ct, on + cn
        for _, b in ipairs(navButtons) do if b.key == c.id then b.count:SetText(cn .. "/" .. ct) end end
        lines[#lines + 1] = ("|cffd4af37%s|r  %d/%d"):format(c.label, cn, ct)
    end
    summary:SetText((ns.Tr("%d modules actifs sur %d. Choisis une catégorie à gauche pour voir et régler chaque module.")):format(on, total)
        .. "\n" .. table.concat(lines, "    "))
    -- liste et détail
    if list:IsShown() then
        self:FillList()
        self:FillDetail()
    end
    self:PaintNav()
end

function O:Open()
    self:Build()
    f:Show()
    self:Show(state.view)
    self:Refresh()
end
function O:Toggle() if f:IsShown() then f:Hide() else self:Open() end end
f:SetScript("OnHide", function() menu:Hide(); search:ClearFocus() end)
ns.On("FP_STEP_CHANGED", function() O:Refresh() end)
ns.On("FP_THEME_CHANGED", function() O:Refresh() end)

-- Entrée dans le menu Options de Blizzard
ns.On("FP_READY", function()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    local panel = CreateFrame("Frame")
    local t = panel:CreateFontString(nil, "OVERLAY", "QuestweaverFontHuge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText("Questweaver")
    local d = panel:CreateFontString(nil, "OVERLAY", "QuestweaverFontHighlight")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    d:SetText(ns.Tr("Guide de leveling gratuit pour WoW Forever."))
    local b = ns.Button(panel, ns.Tr("Ouvrir le panneau Questweaver"), 240, 26, function()
        if SettingsPanel then HideUIPanel(SettingsPanel) end
        O:Open()
    end)
    b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)
    local cat = Settings.RegisterCanvasLayoutCategory(panel, "Questweaver")
    Settings.RegisterAddOnCategory(cat)
end)
