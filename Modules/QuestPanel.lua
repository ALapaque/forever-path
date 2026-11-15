local _, ns = ...

-- Panneau des quêtes, deux onglets :
--   « Mes quêtes » : ton journal, ce qui est prêt à rendre, ce qui est dans ta route, et qui du
--                    groupe a aussi la quête ;
--   « Groupe »     : pour chaque membre qui utilise Questweaver, son étape, sa route et ses quêtes,
--                    avec ce que vous avez en commun et ce que tu pourrais prendre aussi.
-- En groupe, chacun garde sa propre route (option « Suivre la route du chef » dans le module
-- Progression du groupe pour faire autrement).
local M = ns.RegisterModule({
    id = "questpanel", category = "community", default = true,
    name = ns.Tr("Panneau des quêtes (moi et le groupe)"),
    desc = ns.Tr("Une fenêtre à deux onglets. Mes quêtes : ton journal, ce qui est prêt à rendre, ce qui est dans ta route et qui du groupe a la même quête. Groupe : l'étape, la route et les quêtes de chaque membre qui utilise Questweaver, avec les quêtes en commun. Chacun peut suivre sa propre route. Bouton dans le guide, ou /qw quetes."),
    options = {
        { key = "button", label = ns.Tr("Bouton dans le guide"), type = "check", default = true },
    },
})

local W, H = 380, 440
local f = CreateFrame("Frame", "QuestweaverQuestPanel", UIParent, "BackdropTemplate")
f:SetSize(W, H)
f:SetPoint("CENTER", 320, 40)
f:SetFrameStrata("HIGH")
ns.MakeMovable(f, "questpanel", { "CENTER", "CENTER", 320, 40 })
f:Hide()
tinsert(UISpecialFrames, "QuestweaverQuestPanel")

local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 2)

local tabs = {}
local state = { tab = "me" }
local function tab(i, key, label)
    local b = ns.Button(f, label, 110, 22)
    b:SetPoint("TOPLEFT", 10 + (i - 1) * 116, -10)
    b:SetScript("OnClick", function() state.tab = key; M:Refresh() end)
    b.key = key
    tabs[#tabs + 1] = b
    return b
end
tab(1, "me", ns.Tr("Mes quêtes"))
tab(2, "group", ns.Tr("Groupe"))

f.followBtn = ns.Button(f, "", 150, 20)
f.followBtn:SetPoint("BOTTOMLEFT", 10, 10)
f.followBtn:SetScript("OnClick", function()
    local G = ns.Modules.groupsync
    if G then G:SetOpt("follow", not G:Opt("follow")) end
    M:Refresh()
end)
f.status = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
f.status:SetPoint("LEFT", f.followBtn, "RIGHT", 8, 0)
f.status:SetPoint("RIGHT", -10, 0)
f.status:SetJustifyH("LEFT")

local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 10, -40)
scroll:SetPoint("BOTTOMRIGHT", -30, 38)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(W - 44, 10)
scroll:SetScrollChild(content)
local text = content:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
text:SetPoint("TOPLEFT", 2, -2)
text:SetWidth(W - 48)
text:SetJustifyH("LEFT")
text:SetSpacing(3)

---------------------------------------------------------------------------
-- Données
---------------------------------------------------------------------------
local function questName(q)
    if ns.Modules.questitems and ns.Modules.questitems.QuestName then return ns.Modules.questitems.QuestName(q) end
    local t = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(q)
    return (t and not ns.IsSecret(t) and t) or ("#" .. q)
end

local function members()
    local G = ns.Modules.groupsync
    local out = {}
    for name, d in pairs(G and G.members or {}) do
        if GetTime() - (d.time or 0) < 600 and (not UnitInParty or UnitInParty(Ambiguate(name, "none"))) then
            out[#out + 1] = { name = Ambiguate(name, "short"), d = d }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end
M.Members = members

-- mon journal : { quest, title, level, ready, objectives "3/8", route }
function M.MyLog()
    local out = {}
    local route = ns.Engine.GuideQuests and ns.Engine.GuideQuests() or {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and not ns.IsSecret(info.questID) then
            local q = info.questID
            local done, total = 0, 0
            for _, o in ipairs(C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(q) or {}) do
                total = total + 1
                if o.finished then done = done + 1 end
            end
            out[#out + 1] = { quest = q, title = info.title or questName(q), level = info.level,
                ready = C_QuestLog.IsComplete and C_QuestLog.IsComplete(q) or false,
                done = done, total = total, route = route[q] or false }
        end
    end
    -- prêtes d'abord, puis celles de la route, puis le reste
    table.sort(out, function(a, b)
        if a.ready ~= b.ready then return a.ready end
        if a.route ~= b.route then return a.route end
        return (a.level or 0) < (b.level or 0)
    end)
    return out
end

local function stepLabel(d)
    local g = d.guide and ns.Guides[d.guide]
    local st = g and d.index and g.steps[d.index]
    return g, st and ns.Guide and ns.Guide.StepLabel(st) or nil
end

---------------------------------------------------------------------------
-- Rendu
---------------------------------------------------------------------------
local GREEN, GOLD, GREY, BLUE = "ff3fd46a", "ffffd100", "ff8a8a8a", "ff66ccff"
local function c(col, s) return "|c" .. col .. s .. "|r" end

function M.RenderMe()
    local lines, team = {}, members()
    local log = M.MyLog()
    if #log == 0 then return ns.Tr("Ton journal de quêtes est vide.") end
    for _, it in ipairs(log) do
        local lvl = it.level and ("[" .. it.level .. "] ") or ""
        local progress
        if it.ready then progress = c(GREEN, ns.Tr("prête à rendre"))
        elseif it.total > 0 then progress = ("%d/%d"):format(it.done, it.total)
        else progress = "" end
        local tags = {}
        if it.route then tags[#tags + 1] = c(BLUE, ns.Tr("route")) end
        local with, without = {}, {}
        for _, m in ipairs(team) do
            if m.d.quests and m.d.quests[it.quest] then with[#with + 1] = m.name
            elseif m.d.full then without[#without + 1] = m.name end
        end
        if #with > 0 then tags[#tags + 1] = c(GREEN, ns.Tr("aussi : ") .. table.concat(with, ", ")) end
        if #without > 0 then tags[#tags + 1] = c(GREY, ns.Tr("pas : ") .. table.concat(without, ", ")) end
        lines[#lines + 1] = ("%s%s  %s"):format(c(GOLD, lvl), it.title, progress)
        if #tags > 0 then lines[#lines + 1] = "    " .. table.concat(tags, "  •  ") end
    end
    return table.concat(lines, "\n")
end

function M.RenderGroup()
    local team = members()
    if not IsInGroup() and #team == 0 then return ns.Tr("Tu n'es pas en groupe.") end
    if #team == 0 then
        return ns.Tr("Personne d'autre dans le groupe n'utilise Questweaver (ou pas encore de nouvelles).")
    end
    local mine = {}
    for _, it in ipairs(M.MyLog()) do mine[it.quest] = true end
    local myRoute = ns.Engine.GuideQuests and ns.Engine.GuideQuests() or {}
    local myGuide = ns.cdb and ns.cdb.guideId
    local lines = {}
    for _, m in ipairs(team) do
        local d = m.d
        local g, label = stepLabel(d)
        lines[#lines + 1] = ("%s%s"):format(c(BLUE, m.name), d.level and (" (" .. d.level .. ")") or "")
        local seg = g and g.name or (d.guide or "?")
        local same = d.guide == myGuide and c(GREEN, ns.Tr(" (même segment que toi)")) or ""
        lines[#lines + 1] = ("  %s%s — %s %d/%d"):format(seg, same, ns.Tr("étape"), d.index or 0, d.total or 0)
        if label then lines[#lines + 1] = "  " .. label end
        local common, takeable, other = {}, {}, {}
        for q in pairs(d.quests or {}) do
            local name = questName(q) .. (d.ready and d.ready[q] and c(GREEN, ns.Tr(" (prête)")) or "")
            if mine[q] then common[#common + 1] = name
            elseif myRoute[q] then takeable[#takeable + 1] = name
            else other[#other + 1] = name end
        end
        table.sort(common); table.sort(takeable); table.sort(other)
        if #common > 0 then lines[#lines + 1] = "  " .. c(GREEN, ns.Tr("En commun : ")) .. table.concat(common, ", ") end
        if #takeable > 0 then lines[#lines + 1] = "  " .. c(GOLD, ns.Tr("Dans ta route aussi : ")) .. table.concat(takeable, ", ") end
        if #other > 0 then lines[#lines + 1] = "  " .. c(GREY, ns.Tr("Autres : ") .. table.concat(other, ", ")) end
        if not d.full then lines[#lines + 1] = "  " .. c(GREY, ns.Tr("(version plus ancienne de Questweaver : seulement les quêtes de sa route)")) end
        lines[#lines + 1] = " "
    end
    return table.concat(lines, "\n")
end

function M:Refresh()
    if not f:IsShown() then return end
    for _, b in ipairs(tabs) do
        local a = ns.Theme().accent
        if b.key == state.tab then b:SetBackdropBorderColor(a[1], a[2], a[3], 1) else ns.ReSkin(b) end
    end
    text:SetText(state.tab == "me" and M.RenderMe() or M.RenderGroup())
    content:SetHeight(text:GetStringHeight() + 8)
    local G = ns.Modules.groupsync
    local follow = G and G.enabled and G:Opt("follow")
    f.followBtn:SetText(follow and ns.Tr("Route : celle du chef") or ns.Tr("Route : la mienne"))
    f.status:SetText(follow and ns.Tr("Tu suis la route du chef de groupe.")
        or ns.Tr("Tu suis ta propre route, même en groupe."))
end

function M:Toggle(which)
    if which then state.tab = which end
    if f:IsShown() and not which then f:Hide() return end
    ns.Skin(f, 0.95)
    f:Show()
    self:Refresh()
end
M.frame = f

ns.SlashExt.quetes = function() M:Toggle("me") end
ns.SlashExt.quests = ns.SlashExt.quetes
ns.SlashExt.groupe = function() M:Toggle("group") end
ns.SlashExt.group = ns.SlashExt.groupe

local btn
local function updateButton()
    if not (ns.Guide and ns.Guide.AddButton) then return end
    if not btn then
        btn = ns.Guide:AddButton("questpanel", nil, 22, function(_, mouse) M:Toggle(mouse == "RightButton" and "group" or nil) end,
            function(tt)
                tt:SetText(ns.Tr("Panneau des quêtes"), 1, 1, 1)
                tt:AddLine(ns.Tr("Clic gauche : mes quêtes"), 0.8, 0.8, 0.8)
                tt:AddLine(ns.Tr("Clic droit : le groupe"), 0.8, 0.8, 0.8)
            end, "Interface\\Icons\\INV_Misc_Book_08")
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
    btn:SetShown(M.enabled and M:Opt("button") and true or false)
    ns.Guide:Layout()
end

function M:OnEnable() updateButton() end
function M:OnDisable() f:Hide(); updateButton() end
function M:OnOptionChanged() updateButton() end

local queued
local function queue()
    if queued or not f:IsShown() then return end
    queued = true
    C_Timer.After(0.5, function() queued = false; M:Refresh() end)
end
M:On("QUEST_LOG_UPDATE", queue)
M:On("CHAT_MSG_ADDON", queue)
M:On("GROUP_ROSTER_UPDATE", queue)
M:On("FP_STEP_CHANGED", queue)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("TOPLEFT", 6, -6)
    fs:SetWidth(138)
    fs:SetJustifyH("LEFT")
    fs:SetText(ns.Tr("|cff66ccffJaina|r (13)\n|cff3fd46aEn commun :|r La menace kobold\n|cffffd100Dans ta route aussi :|r Les loups"))
end
