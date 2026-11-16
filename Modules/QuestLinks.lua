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

-- { mobs = {id=true}, enders = {id=true}, skill = id, rank = n } ou nil
function ns.QuestLink(q)
    if not q then return end
    local c = cache[q]
    if c ~= nil then return c or nil end
    local raw = ns.QuestLinks and ns.QuestLinks[q]
    if not raw then cache[q] = false return end
    c = { mobs = set(raw:match("m=([%d,]+)")), enders = set(raw:match("e=([%d,]+)")) }
    local sk, rk = raw:match("s=(%d+):(%d+)")
    if sk then c.skill, c.rank = tonumber(sk), tonumber(rk) end
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
local ranks, ranksAt
function ns.SkillRanks()
    if ranks and ranksAt == GetTime() then return ranks end
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
    ranks, ranksAt = out, GetTime()
    return out
end
ns.On("SKILL_LINES_CHANGED", function() ranks = nil end)
ns.On("CHAT_MSG_SKILL", function() ranks = nil end)

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
    end
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
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end
function M:OnOptionChanged() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("|cff66ccffMêmes monstres|r : fais aussi\n« Les loups affamés » |cffaaaaaa(hors route)|r"))
end
