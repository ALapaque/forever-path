local _, ns = ...

-- Liens entre quêtes (Data/QuestLinks.lua) :
--   - quêtes du journal qui portent sur les mêmes monstres que l'étape en cours (y compris les
--     quêtes hors de la route) : signalées dans le guide et ajoutées aux cibles, pour les faire
--     d'une traite ; et quêtes terminées à rendre au même PNJ que l'étape ;
--   - quêtes de métier (ex. Cuisine 50) : marquées dans le guide, et passées toutes seules si le
--     personnage n'a pas le métier au niveau demandé.

---------------------------------------------------------------------------
-- Données
---------------------------------------------------------------------------
local cache = {}
local function set(s)
    local t = {}
    for v in (s or ""):gmatch("%d+") do t[tonumber(v)] = true end
    return t
end

-- { mobs = {id=true}, enders = {id=true}, skill = id, rank = n, part = i, parts = n, nextQuest = id } ou nil
function ns.QuestLink(q)
    if not q then return end
    local c = cache[q]
    if c ~= nil then return c or nil end
    local raw = ns.QuestLinks and ns.QuestLinks[q]
    if not raw then cache[q] = false return end
    c = { mobs = set(raw:match("m=([%d,]+)")), enders = set(raw:match("e=([%d,]+)")) }
    local sk, rk = raw:match("s=(%d+):(%d+)")
    if sk then c.skill, c.rank = tonumber(sk), tonumber(rk) end
    local pa, pn = raw:match("c=(%d+)/(%d+)")
    if pa then c.part, c.parts = tonumber(pa), tonumber(pn) end
    c.nextQuest = tonumber(raw:match("n=(%d+)"))
    local pm, px, py = raw:match("p=(%d+):([%d.]+):([%d.]+)")
    if pm then c.turnMap, c.turnX, c.turnY = tonumber(pm), tonumber(px), tonumber(py) end
    cache[q] = c
    return c
end

---------------------------------------------------------------------------
-- Métiers
---------------------------------------------------------------------------
-- lignes de compétence -> nom français (traduit par ns.Tr) et noms connus du client
local SKILLS = {
    [185] = { "Cuisine", "Cooking", "Kochkunst", "Cocina" },
    [129] = { "Secourisme", "First Aid", "Erste Hilfe", "Primeros auxilios" },
    [356] = { "Pêche", "Fishing", "Angeln", "Pesca" },
    [164] = { "Forge", "Blacksmithing", "Schmiedekunst", "Herrería" },
    [165] = { "Travail du cuir", "Leatherworking", "Lederverarbeitung", "Peletería" },
    [171] = { "Alchimie", "Alchemy", "Alchemie", "Alquimia" },
    [182] = { "Herboristerie", "Herbalism", "Kräuterkunde", "Herboristería" },
    [186] = { "Minage", "Mining", "Bergbau", "Minería" },
    [197] = { "Couture", "Tailoring", "Schneiderei", "Sastrería" },
    [202] = { "Ingénierie", "Engineering", "Ingenieurskunst", "Ingeniería" },
    [333] = { "Enchantement", "Enchanting", "Verzauberkunst", "Encantamiento" },
    [393] = { "Dépeçage", "Skinning", "Kürschnerei", "Desuello" },
}
ns.SKILL_NAMES = SKILLS
local BY_KEY = { COOKING = 185, FIRSTAID = 129, FISHING = 356, BLACKSMITHING = 164, LEATHERWORKING = 165,
                 ALCHEMY = 171, HERBALISM = 182, MINING = 186, TAILORING = 197, ENGINEERING = 202,
                 ENCHANTING = 333, SKINNING = 393 }
ns.SKILL_KEYS = BY_KEY

function ns.SkillLabel(id)
    local s = SKILLS[id]
    return s and ns.Tr(s[1]) or ("#" .. tostring(id))
end

-- Niveaux des métiers du personnage : { [ligne] = niveau }, ou nil si le jeu ne les donne pas.
-- En cache jusqu'au prochain changement de métier : le guide et la flèche l'interrogent souvent.
local ranks
function ns.SkillRanks()
    if ranks then return ranks end
    local out, ok = {}, false
    if GetProfessions and GetProfessionInfo then
        ok = true
        local list = { GetProfessions() }
        for k = 1, select("#", GetProfessions()) do
            local idx = list[k]
            if idx then
                local _, _, rank, _, _, _, line = GetProfessionInfo(idx)
                if line then out[line] = rank or 1 end
            end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        ok = true
        local byName = {}
        for id, names in pairs(SKILLS) do
            for _, n in ipairs(names) do byName[n] = id end
        end
        for i = 1, GetNumSkillLines() or 0 do
            local name, header, _, rank = GetSkillLineInfo(i)
            local id = not header and name and byName[name]
            if id and not out[id] then out[id] = rank or 1 end
        end
    end
    if not ok then return end
    ranks = out
    return out
end
ns.On("SKILL_LINES_CHANGED", function() ranks = nil end)
ns.On("CHAT_MSG_SKILL", function() ranks = nil end)
ns.On("PLAYER_LOGIN", function() ranks = nil end)
ns.On("PLAYER_ENTERING_WORLD", function() ranks = nil end)

-- Métier requis par une étape : option skill= du guide, sinon les données de la quête
function ns.StepSkill(step)
    if not step then return end
    if step.skill then return step.skill, step.skillRank or 1 end
    local l = step.quest and ns.QuestLink(step.quest)
    if l and l.skill then return l.skill, l.rank or 1 end
end

-- true si le personnage n'a pas le métier requis (nil si on ne peut pas le savoir)
function ns.LacksSkill(step)
    local id, rank = ns.StepSkill(step)
    if not id then return false end
    local r = ns.SkillRanks()
    if not r then return nil end
    return (r[id] or 0) < rank
end

-- Partie d'une chaîne de quêtes, à afficher après le nom : « (2/13) »
function ns.ChainTag(q)
    local l = ns.QuestLink(q)
    if l and l.parts and l.parts > 1 then return ("|cffaaaaaa(%d/%d)|r"):format(l.part, l.parts) end
end

-- Quêtes de toute la route du parcours en cours (tous les segments), mises en cache par parcours
local pathCache = {}
function ns.PathQuests()
    local cur = ns.Guides[ns.cdb.guideId or ""]
    if not cur then return {} end
    local key = cur.path or cur.id
    if pathCache[key] then return pathCache[key] end
    local set = {}
    for _, id in ipairs(ns.GuideOrder) do
        local g = ns.Guides[id]
        if (cur.path and g.path == cur.path) or g == cur then
            for _, s in ipairs(g.steps) do if s.quest then set[s.quest] = true end end
        end
    end
    pathCache[key] = set
    return set
end

-- Ce que la route fait d'une chaîne, vu depuis la quête q :
--   first, last = parties faites par la route à partir de q ; parts = longueur ; nextQuest = suite hors route
function ns.ChainCoverage(q)
    local l = ns.QuestLink(q)
    if not (l and l.parts and l.parts > 1) then return end
    local route = ns.PathQuests()
    local last, cur, guard = l.part, l, 0
    local nextOut
    while cur and cur.nextQuest and guard < 50 do
        guard = guard + 1
        if route[cur.nextQuest] then
            last = last + 1
            cur = ns.QuestLink(cur.nextQuest)
        else
            nextOut = cur.nextQuest
            break
        end
    end
    return l.part, last, l.parts, nextOut
end

local P = ns.RegisterModule({
    id = "profquests", category = "guide", default = true,
    name = "Quêtes de métier",
    desc = "Marque dans le guide les quêtes qui demandent un métier (ex. Cuisine 50) et les passe toutes seules si ton personnage n'a pas ce métier au niveau demandé. Elles reviennent dans la route dès que tu l'as.",
    options = {
        { key = "skip", label = "Passer les quêtes de métier que je ne peux pas faire", type = "check", default = true },
    },
})
function P:OnOptionChanged() if ns.Engine and ns.Engine.Refresh then ns.Engine.Refresh() end end
function P:OnEnable() if ns.Engine and ns.Engine.Refresh then ns.Engine.Refresh() end end
function P:OnDisable() if ns.Engine and ns.Engine.Refresh then ns.Engine.Refresh() end end
-- métier appris ou monté : la route se recalcule
ns.On("SKILL_LINES_CHANGED", function() if P.enabled and ns.Engine.Refresh then ns.Engine.Refresh() end end)

-- l'étape doit-elle être passée faute de métier ?
function P.Skip(step)
    return P.enabled and P:Opt("skip") and ns.LacksSkill(step) == true
end

-- marque à ajouter au libellé de l'étape : « (Cuisine 50) », en orange s'il te manque
function P.Tag(step)
    if not P.enabled then return end
    local id, rank = ns.StepSkill(step)
    if not id then return end
    local lacks = ns.LacksSkill(step)
    return ("|c%s(%s %d)|r"):format(lacks and "ffff7f3f" or "ffaaaaaa", ns.SkillLabel(id), rank)
end

function P.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("Prends 'Kébab de loup' |cffff7f3f(Cuisine 50)|r\n|cffaaaaaapassée : métier trop bas|r"))
end

---------------------------------------------------------------------------
-- Quêtes aux mêmes monstres
---------------------------------------------------------------------------
local M = ns.RegisterModule({
    id = "questlinks", category = "comfort", default = true,
    name = "Quêtes aux mêmes monstres",
    desc = "Regarde ton journal de quêtes, y compris les quêtes hors de la route : quand l'étape en cours porte sur les mêmes monstres qu'une autre de tes quêtes, le guide te le dit et marque aussi ces monstres, pour tout faire d'une traite. Il signale aussi les quêtes terminées à rendre au même PNJ.",
    options = {
        { key = "mobs", label = "Regrouper les quêtes aux mêmes monstres", type = "check", default = true },
        { key = "turnin", label = "Signaler les quêtes à rendre au même PNJ", type = "check", default = true },
        { key = "chain", label = "Quêtes en plusieurs parties : dire où la route s'arrête", type = "check", default = true },
        { key = "starters", label = "Objets qui lancent une quête : bouton pour la lancer, et où la rendre", type = "check", default = true },
        { key = "detour", label = "Proposer le détour pour la rendre jusqu'à (yards)", type = "slider", min = 0, max = 2000, step = 100, default = 600 },
    },
})
ns.QuestLinksModule = M

local function inter(a, b)
    if not (a and b) then return false end
    for k in pairs(a) do if b[k] then return true end end
    return false
end

local function title(q, info)
    return (info and info.title) or C_QuestLog.GetTitleForQuestID(q) or ("#" .. q)
end

-- monstres de l'étape : ceux du guide et ceux de la quête (objets lâchés compris)
local function stepMobs(step)
    if not step then return end
    local l = step.quest and ns.QuestLink(step.quest)
    local out
    for _, src in ipairs({ step.mobs or {}, l and l.mobs or {} }) do
        for id in pairs(src) do out = out or {}; out[id] = true end
    end
    return out
end
M.StepMobs = stepMobs

-- Quêtes du journal liées à l'étape :
--   mobs   = { { quest, title, offRoute, mobs } } (pas terminées, mêmes monstres)
--   turnin = { { quest, title, offRoute } }       (terminées, même PNJ que l'étape)
function M.Related(step)
    local res = { mobs = {}, turnin = {} }
    if not step then return res end
    local route = ns.Engine.GuideQuests()
    local mobs = step.type == "complete" and stepMobs(step) or nil
    local npc = (step.type == "turnin" or step.type == "accept") and step.npcID or nil
    if not (mobs or npc) then return res end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local q = info and not info.isHeader and info.questID
        if q and not ns.IsSecret(q) and q ~= step.quest then
            local l = ns.QuestLink(q)
            local done = C_QuestLog.IsComplete(q)
            if l and mobs and not done and inter(mobs, l.mobs) then
                res.mobs[#res.mobs + 1] = { quest = q, title = title(q, info), offRoute = not route[q], mobs = l.mobs }
            elseif l and npc and done and l.enders[npc] then
                res.turnin[#res.turnin + 1] = { quest = q, title = title(q, info), offRoute = not route[q] }
            end
        end
    end
    return res
end

-- Pour une quête hors route du journal : prochaine étape de la route sur les mêmes monstres
function M.RouteStepFor(q)
    local l = ns.QuestLink(q)
    if not (l and next(l.mobs)) then return end
    local g, _, i = ns.Engine.Current()
    if not g then return end
    for j = i or 1, #g.steps do
        local s = g.steps[j]
        -- (une étape « faire » d'une quête pas encore prise compte : on la prendra en chemin)
        local skipped = ns.cdb.skipped[g.id]
        if s.type == "complete" and s.quest and ns.Engine.Applies(s) and not (skipped and skipped[j])
            and not C_QuestLog.IsQuestFlaggedCompleted(s.quest) and not P.Skip(s) and inter(stepMobs(s), l.mobs) then
            return s, j - (i or 1)
        end
    end
end

local function names(list, n)
    local out = {}
    for k = 1, math.min(n, #list) do
        local it = list[k]
        out[k] = "« " .. it.title .. " »" .. (it.offRoute and ns.Tr(" |cffaaaaaa(hors route)|r") or "")
    end
    if #list > n then out[#out + 1] = ("+%d"):format(#list - n) end
    return table.concat(out, ", ")
end

-- Quête en plusieurs parties (même nom à chaque partie) : à la prise, quelles parties la route fait ;
-- au rendu de la dernière partie de la route, dire que la suite n'en fait pas partie.
function M.ChainLine(step)
    if not (step and step.quest and (step.type == "accept" or step.type == "turnin")) then return end
    local first, last, parts, nextOut = ns.ChainCoverage(step.quest)
    if not first then return end
    if step.type == "accept" then
        if last >= parts then
            if first == 1 then return ns.Tr("|cff66ccffQuête en %d parties|r : ta route les fait toutes"):format(parts) end
            return
        end
        return ns.Tr("|cff66ccffQuête en %d parties|r : ta route fait les parties %d à %d, pas la suite"):format(parts, first, last)
    end
    -- rendu : la suite est-elle dans la route ?
    if nextOut and first == last and not C_QuestLog.IsQuestFlaggedCompleted(nextOut) then
        return ns.Tr("|cffaaaaaaFin de cette quête dans ta route|r : la partie %d/%d n'y est pas, pas besoin de la prendre"):format(first + 1, parts)
    end
end

---------------------------------------------------------------------------
-- Objets lâchés par des monstres qui lancent une quête (souvent : juste aller la rendre, de l'XP
-- pour quelques pas). On ne peut pas prévoir le butin dans la route, alors on les prend quand ils
-- tombent : bouton pour lancer la quête, puis où la rendre — chez un PNJ où la route passe de toute
-- façon, sinon un détour proposé s'il est court.
---------------------------------------------------------------------------
local QI = function() return ns.Modules.questitems end

-- objets du sac qui lancent une quête pas encore prise : { { item, bag, slot, quest, xp } }
function M.Starters()
    local out = {}
    if not (C_Container and C_Container.GetContainerNumSlots) then return out end
    local qi, seen = QI(), {}
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local id = C_Container.GetContainerItemID(bag, slot)
            if id and not seen[id] and ns.QuestItems and ns.QuestItems[id] and ns.QuestItems[id]:find("s=", 1, true) then
                seen[id] = true
                local a = qi and qi.Analyze and qi.Analyze(id)
                for _, r in ipairs(a and a.quests or {}) do
                    if r.role == "s" and not r.done and not r.inLog and (r.req or 1) <= ns.PlayerLevel() and r.factor > 0.2 then
                        out[#out + 1] = { item = id, bag = bag, slot = slot, quest = r.quest, xp = r.xp }
                        break
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b) return (a.xp or 0) > (b.xp or 0) end)
    return out
end

-- quêtes du journal, terminées, hors de la route, dont on sait où les rendre
function M.TurnIns()
    local out = {}
    local route = ns.PathQuests()
    local g, _, cur = ns.Engine.Current()
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local q = info and not info.isHeader and info.questID
        if q and not ns.IsSecret(q) and not route[q] and C_QuestLog.IsComplete(q) then
            local l = ns.QuestLink(q)
            if l and (l.turnMap or next(l.enders)) then
                local it = { quest = q, title = title(q, info), link = l }
                -- la route passe-t-elle chez ce PNJ plus loin ?
                if g then
                    for j = cur or 1, #g.steps do
                        local s = g.steps[j]
                        if s.npcID and l.enders[s.npcID] and ns.Engine.Applies(s) then it.ahead = j - (cur or 1) break end
                    end
                end
                if l.turnMap then
                    it.dist = ns.Geo.Vector({ map = l.turnMap, x = l.turnX, y = l.turnY })
                end
                out[#out + 1] = it
            end
        end
    end
    return out
end

local function npcLabel(l)
    for id in pairs(l.enders) do
        local n = ns.NpcName(id)
        if n then return n end
    end
    return ns.Tr("son PNJ")
end

function M.Detour(it)
    local l = it and it.link
    if not (l and l.turnMap) then return end
    ns.Engine.SetDetour({ map = l.turnMap, x = l.turnX, y = l.turnY, radius = 10, kind = "questlinks",
        text = ns.Tr("Rendre « %s »"):format(it.title), icon = "Interface\\GossipFrame\\ActiveQuestIcon",
        npcID = next(l.enders) })
end

-- bouton sécurisé : lancer la quête de l'objet (clic = utiliser l'objet du sac)
local sb = CreateFrame("Button", "QuestweaverStarterButton", UIParent, "SecureActionButtonTemplate")
sb:SetSize(36, 36)
sb:RegisterForClicks("AnyUp", "AnyDown")
sb:SetAttribute("type", "item")
sb:Hide()
if ns.ActionBar and ns.ActionBar.Register then ns.ActionBar:Register(sb, 21) end
sb.icon = sb:CreateTexture(nil, "ARTWORK")
sb.icon:SetAllPoints()
sb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
sb.mark = sb:CreateTexture(nil, "OVERLAY")
sb.mark:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
sb.mark:SetSize(16, 16)
sb.mark:SetPoint("TOPRIGHT", 4, 4)
sb:SetScript("OnEnter", function(self)
    if not self.itemID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(self.itemID)
    GameTooltip:AddLine(ns.Tr("Clic : lancer la quête"), 0.4, 0.8, 1)
    GameTooltip:Show()
end)
sb:SetScript("OnLeave", function() GameTooltip:Hide() end)

local starterDirty, announced = false, {}
local function setStarter(st)
    if InCombatLockdown() then starterDirty = true return end
    starterDirty = false
    if st then
        sb.itemID = st.item
        sb:SetAttribute("item", ("item:%d"):format(st.item))
        sb.icon:SetTexture(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(st.item) or "Interface\\Icons\\INV_Misc_Note_01")
        sb:Show()
    else
        sb.itemID = nil
        sb:SetAttribute("item", nil)
        sb:Hide()
    end
    if ns.ActionBar and ns.ActionBar.Layout then ns.ActionBar:Layout() end
end

local detourBtn
function M:ItemLines(lines)
    local starters = (self.enabled and self:Opt("starters")) and M.Starters() or {}
    setStarter(starters[1])
    for k = 1, math.min(2, #starters) do
        local st = starters[k]
        local qi = QI()
        local name = qi and qi.QuestName and qi.QuestName(st.quest) or ("#" .. st.quest)
        lines[#lines + 1] = ns.Tr("|cffffd100Objet de quête|r : lance « %s » (+%d XP) — bouton ou clic droit dans ton sac"):format(name, st.xp or 0)
        if not announced[st.quest] then
            announced[st.quest] = true
            ns.Toast(ns.Tr("Cet objet lance une quête : « %s » (+%d XP)"):format(name, st.xp or 0), "Interface\\GossipFrame\\AvailableQuestIcon", 1, 0.82, 0, 5)
        end
    end
    local best
    if self.enabled and self:Opt("starters") then
        for _, it in ipairs(M.TurnIns()) do
            local l = it.link
            if it.ahead then
                lines[#lines + 1] = ns.Tr("|cff3fd46aÀ rendre|r : « %s » à %s, ta route y passe dans %d étapes"):format(it.title, npcLabel(l), it.ahead)
            elseif it.dist then
                lines[#lines + 1] = ns.Tr("|cff3fd46aÀ rendre|r : « %s » à %s (%s)"):format(it.title, npcLabel(l), ns.FormatDistance(it.dist))
                local max = self:Opt("detour") or 600
                if it.dist <= max and (not best or it.dist < best.dist) then best = it end
            end
        end
    end
    M.detourTarget = best
    if not detourBtn and ns.Guide and ns.Guide.AddButton then
        detourBtn = ns.Guide:AddButton("itemquest", nil, 22, function() M.Detour(M.detourTarget) end,
            ns.Tr("Détour : aller rendre la quête lancée par un objet"), "Interface\\GossipFrame\\ActiveQuestIcon")
    end
    if detourBtn then
        local show = best ~= nil and not (ns.Engine.Detour() and ns.Engine.Detour().kind == "questlinks")
        if detourBtn:IsShown() ~= show then detourBtn:SetShown(show); ns.Guide:Layout() end
    end
end

local extra = {}       -- monstres des quêtes regroupées, ajoutés aux cibles
function M:Update()
    wipe(extra)
    if not ns.Guide then return end
    local _, step = ns.Engine.Current()
    local lines = {}
    if self.enabled and step then
        local r = M.Related(step)
        if self:Opt("mobs") and #r.mobs > 0 then
            for _, it in ipairs(r.mobs) do
                for id in pairs(it.mobs) do extra[id] = true end
            end
            lines[#lines + 1] = ns.Tr("|cff66ccffMêmes monstres|r : fais aussi %s"):format(names(r.mobs, 3))
        end
        if self:Opt("turnin") and #r.turnin > 0 then
            lines[#lines + 1] = ns.Tr("|cff3fd46aÀ rendre ici aussi|r : %s"):format(names(r.turnin, 3))
        end
        local chain = self:Opt("chain") and M.ChainLine(step)
        if chain then lines[#lines + 1] = chain end
    end
    self:ItemLines(lines)
    ns.Guide:SetSection("questlinks", 11, #lines > 0 and table.concat(lines, "\n") or nil)
end
function M.ExtraMobs() return M.enabled and M:Opt("mobs") and extra or nil end

-- les monstres des quêtes regroupées sont aussi des cibles (barres de nom, bouton Cibler)
local baseTargets = ns.Engine.Targets
function ns.Engine.Targets()
    local t = baseTargets()
    local ex = M.ExtraMobs()
    if ex and t.step and t.step.type == "complete" then
        for id in pairs(ex) do
            if not t.ids[id] then
                t.ids[id] = "mob"
                local n = ns.NpcName(id)
                if n and not t.names[n] then t.names[n] = "mob" end
            end
        end
    end
    return t
end

local queued
local function queue()
    if queued then return end
    queued = true
    C_Timer.After(0.3, function() queued = false; M:Update() end)
end
M:On("FP_STEP_CHANGED", queue)
M:On("QUEST_ACCEPTED", queue)
M:On("QUEST_REMOVED", queue)
M:On("QUEST_LOG_UPDATE", queue)
M:On("BAG_UPDATE_DELAYED", queue)
M:On("PLAYER_REGEN_ENABLED", function() if starterDirty then queue() end end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update(); setStarter(nil) end
function M:OnOptionChanged() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("|cff66ccffMêmes monstres|r : fais aussi\n« Les loups affamés » |cffaaaaaa(hors route)|r"))
end
