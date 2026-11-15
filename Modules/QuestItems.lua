local _, ns = ...

-- Objets de quête dans les sacs : à quelle quête sert cet objet, où en est cette quête, et
-- vaut-il encore la peine de le garder (quête déjà rendue, quête grise qui ne rapporte presque
-- plus d'XP…). Infobulle des objets + /qw sac pour passer tout le sac en revue.
-- Données : Data/QuestItems.lua (généré depuis QuestieDB par tools/gen_items.py).
local M = ns.RegisterModule({
    id = "questitems", category = "comfort", default = true,
    name = ns.Tr("Objets de quête dans les sacs"),
    desc = ns.Tr("Dans l'infobulle d'un objet : la quête à laquelle il sert, si elle est en cours, déjà faite ou pas encore prise, l'XP qu'elle rapporte encore à ton niveau et si elle est dans ta route. Avec un verdict : à garder, peu utile ou inutile. /qw sac passe tout ton sac en revue."),
    options = {
        { key = "tooltip", label = ns.Tr("Infobulle des objets"), type = "check", default = true },
        { key = "max", label = ns.Tr("Quêtes listées par objet"), type = "slider", min = 1, max = 6, step = 1, default = 3 },
    },
})

local KEEP, LOW, USELESS = "keep", "low", "useless"
M.KEEP, M.LOW, M.USELESS = KEEP, LOW, USELESS

-- Même règle que la génération des routes : XP pleine jusqu'à 5 niveaux d'écart, puis
-- 80 / 60 / 40 / 20 %, et 10 % au-delà (quête grise).
function M.XPFactor(questLevel, playerLevel)
    local d = playerLevel - questLevel
    if d <= 5 then return 1 end
    return ({ [6] = 0.8, [7] = 0.6, [8] = 0.4, [9] = 0.2 })[d] or 0.1
end

local parsed = {}
local function entry(itemID)
    local raw = ns.QuestItems and ns.QuestItems[itemID]
    if not raw then return nil end
    local e = parsed[itemID]
    if e then return e end
    e = {}
    for role, list in raw:gmatch("(%a)=([%d,]+)") do
        for q in list:gmatch("%d+") do e[#e + 1] = { role = role, quest = tonumber(q) } end
    end
    parsed[itemID] = e
    return e
end

-- quêtes prévues dans les routes de ta faction
local routeQuests
local function inRoute(qid)
    if not routeQuests then
        routeQuests = {}
        local fac = ns.PlayerFaction()
        for _, g in pairs(ns.Guides or {}) do
            if not g.faction or g.faction == fac then
                for _, s in ipairs(g.steps or {}) do
                    if s.quest then routeQuests[s.quest] = true end
                end
            end
        end
    end
    return routeQuests[qid]
end

function M.QuestName(qid)
    local t = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(qid)
    if t and t ~= "" and not ns.IsSecret(t) then return t end
    local info = ns.QuestInfo and ns.QuestInfo[qid]
    if info then
        if ns.isFrench and info[6] ~= "" then return info[6] end
        return info[5]
    end
    return "#" .. qid
end

-- Analyse d'un objet : liste des quêtes concernées (état, XP) et verdict global.
function M.Analyze(itemID)
    local e = entry(itemID)
    if not e then return nil end
    local level = ns.PlayerLevel()
    local fac = (ns.PlayerFaction() or ""):sub(1, 1)       -- "A" / "H"
    local classID = select(3, UnitClass("player"))
    local classBit = classID and 2 ^ (classID - 1) or 0
    local out, best = {}, nil
    local rank = { [USELESS] = 1, [LOW] = 2, [KEEP] = 3 }
    for _, it in ipairs(e) do
        local info = ns.QuestInfo and ns.QuestInfo[it.quest]
        local mask = info and info[7] or 0
        local forClass = mask == 0 or classBit == 0 or math.floor(mask / classBit) % 2 == 1
        if info and (info[4] == "B" or info[4] == fac) and forClass then
            local r = { quest = it.quest, role = it.role, level = info[1], req = info[2] }
            r.done = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(it.quest) or false
            r.inLog = (C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(it.quest)) ~= nil
            r.factor = M.XPFactor(info[1], level)
            r.xp = math.floor(info[3] * r.factor)
            r.route = inRoute(it.quest)
            if r.done then
                r.verdict = USELESS
            elseif r.inLog then
                r.verdict = KEEP
            elseif r.factor <= 0.2 then
                r.verdict = LOW                                    -- quête grise : presque plus d'XP
            else
                r.verdict = KEEP
            end
            out[#out + 1] = r
            if not best or rank[r.verdict] > rank[best] then best = r.verdict end
        end
    end
    -- les plus utiles d'abord : en cours, puis dans la route, puis le reste
    table.sort(out, function(a, b)
        if a.verdict ~= b.verdict then return rank[a.verdict] > rank[b.verdict] end
        if a.inLog ~= b.inLog then return a.inLog end
        if (a.route or false) ~= (b.route or false) then return a.route end
        return a.quest < b.quest
    end)
    -- vrai objet de quête (classe « Quête ») ou objet qui lance une quête ; sinon c'est un objet
    -- ordinaire (tissu, cuir…) que des quêtes demandent aussi : pas de conseil de s'en débarrasser.
    local questItem = false
    if C_Item and C_Item.GetItemInfoInstant then
        local itemClass = select(6, C_Item.GetItemInfoInstant(itemID))
        questItem = itemClass == 12
    end
    for _, it in ipairs(e) do if it.role == "s" then questItem = true end end
    return { quests = out, verdict = best or USELESS, otherFaction = #out == 0, questItem = questItem }
end

local ROLE = {
    o = ns.Tr("Sert à"), s = ns.Tr("Lance"), p = ns.Tr("Fourni par"),
}
local VERDICT = {
    [KEEP] = { ns.Tr("À garder"), 0.25, 0.9, 0.35 },
    [LOW] = { ns.Tr("Peu utile : quête grise, presque plus d'XP"), 1, 0.65, 0.2 },
    [USELESS] = { ns.Tr("Inutile : tu peux t'en débarrasser"), 1, 0.3, 0.3 },
}

function M.StatusText(r)
    if r.done then return ns.Tr("|cff888888déjà faite|r") end
    local parts = {}
    if r.inLog then parts[#parts + 1] = ns.Tr("|cff40ff40en cours|r")
    elseif r.req > ns.PlayerLevel() then parts[#parts + 1] = (ns.Tr("|cffff8040à partir du niveau %d|r")):format(r.req)
    else parts[#parts + 1] = ns.Tr("|cffffd100pas encore prise|r") end
    if r.xp > 0 then
        local col = r.factor >= 1 and "ffffffff" or r.factor > 0.2 and "ffffd100" or "ff999999"
        parts[#parts + 1] = ("|c%s%d XP|r"):format(col, r.xp)
    end
    if r.route then parts[#parts + 1] = ns.Tr("|cff66ccffdans ta route|r") end
    return table.concat(parts, ", ")
end

local function addLines(tt, itemID)
    local a = M.Analyze(itemID)
    if not a then return end
    if not a.questItem then
        -- objet ordinaire : on ne parle que des quêtes encore à faire
        if a.otherFaction or a.verdict == USELESS then return end
        tt:AddLine(" ")
        tt:AddLine(ns.Tr("Questweaver : demandé par des quêtes"), 0.4, 0.8, 1)
    elseif a.otherFaction then
        tt:AddLine(" ")
        tt:AddLine(ns.Tr("Questweaver : objet de quête de l'autre faction"), 0.6, 0.6, 0.6)
        return
    else
        local v = VERDICT[a.verdict]
        tt:AddLine(" ")
        tt:AddLine("Questweaver : " .. v[1], v[2], v[3], v[4])
    end
    local max = M:Opt("max") or 3
    local shown = 0
    for _, r in ipairs(a.quests) do
        if not a.questItem and r.done then break end         -- objet ordinaire : quêtes faites inutiles à lister
        shown = shown + 1
        local i = shown
        if i > max then
            tt:AddLine((ns.Tr("  … et %d autre(s) quête(s)")):format(#a.quests - max), 0.6, 0.6, 0.6)
            break
        end
        tt:AddLine(("  %s [%d] %s : %s"):format(ROLE[r.role] or "", r.level, M.QuestName(r.quest), M.StatusText(r)),
            0.85, 0.85, 0.85, true)
    end
end

-- Infobulle (API moderne : TooltipDataProcessor)
local hooked = false
local function hook()
    if hooked or not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType) then return end
    hooked = true
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
        if not (M.enabled and M:Opt("tooltip")) or tt ~= GameTooltip and tt ~= ItemRefTooltip then return end
        local id = data and data.id
        if type(id) ~= "number" or ns.IsSecret(id) then return end
        local ok, err = pcall(addLines, tt, id)
        if not ok then ns.ReportError(err) end
    end)
end

-- /qw sac : tout le sac en revue
function M.ScanBags()
    local groups = { [KEEP] = {}, [LOW] = {}, [USELESS] = {} }
    if not (C_Container and C_Container.GetContainerNumSlots) then return groups end
    local seen = {}
    for bag = 0, 5 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local id = C_Container.GetContainerItemID(bag, slot)
            if id and not seen[id] then
                seen[id] = true
                local a = M.Analyze(id)
                if a and a.questItem and not a.otherFaction then
                    local link = C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bag, slot)
                    table.insert(groups[a.verdict], { id = id, link = link, a = a })
                end
            end
        end
    end
    return groups
end

ns.SlashExt.sac = function()
    local gr = M.ScanBags()
    local total = #gr[KEEP] + #gr[LOW] + #gr[USELESS]
    if total == 0 then ns.Print(ns.Tr("Aucun objet de quête dans tes sacs.")) return end
    for _, key in ipairs({ USELESS, LOW, KEEP }) do
        local list = gr[key]
        if #list > 0 then
            local v = VERDICT[key]
            local head = ("|cff%02x%02x%02x%s|r (%d)"):format(v[2] * 255, v[3] * 255, v[4] * 255, v[1], #list)
            ns.Print(head)
            for _, it in ipairs(list) do
                local r = it.a.quests[1]
                local line = ("  %s : %s — %s"):format(it.link or ("#" .. it.id), M.QuestName(r.quest), M.StatusText(r))
                ns.Print(line)
            end
        end
    end
end
ns.SlashExt.bag = ns.SlashExt.sac

function M:OnEnable() hook() end
M:On("PLAYER_LOGIN", function() routeQuests = nil end)

function M.preview(p)
    local bg = p:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.09, 1)
    local ic = p:CreateTexture(nil, "ARTWORK")
    ic:SetSize(22, 22); ic:SetPoint("TOPLEFT", 8, -8)
    ic:SetTexture("Interface\\Icons\\INV_Misc_Food_14")
    local n = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    n:SetPoint("LEFT", ic, "RIGHT", 6, 0); n:SetText(ns.Tr("Viande de loup coriace")); n:SetTextColor(1, 1, 1)
    local v = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    v:SetPoint("TOPLEFT", 8, -38); v:SetText(VERDICT[USELESS][1]); v:SetTextColor(1, 0.3, 0.3)
    v:SetWidth(136); v:SetJustifyH("LEFT")
    local q = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
    q:SetPoint("TOPLEFT", v, "BOTTOMLEFT", 0, -3); q:SetWidth(136); q:SetJustifyH("LEFT")
    q:SetText(ns.Tr("Sert à [2] Les loups derrière la frontière : déjà faite"))
end
