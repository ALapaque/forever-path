local _, ns = ...

-- Journal de quêtes : prévient avant qu'il soit plein, ou quand les prochaines prises n'y tiendront
-- pas, et propose quoi abandonner (quêtes que la route ne rend plus, les plus basses d'abord).
local M = ns.RegisterModule({
    id = "questlog", category = "comfort", default = true,
    name = "Journal de quêtes plein",
    desc = "Prévient quand ton journal de quêtes est presque plein, ou quand les prochaines quêtes de la route n'y tiendront pas, et propose celles à abandonner : les quêtes que ta route ne rend plus, les plus basses d'abord. Un bouton dans le guide abandonne la première suggestion.",
    options = {
        { key = "margin", label = "Prévenir à N places de la limite", type = "slider", min = 1, max = 6, step = 1, default = 2 },
        { key = "ahead", label = "Prévenir avant un PNJ si ses quêtes ne tiennent pas", type = "check", default = true },
    },
})

function M.Count()
    local n = 0
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and not info.isHidden and info.questID then n = n + 1 end
    end
    local max = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 20
    return n, max
end

-- Quêtes que la route rend encore : dans le guide en cours à partir de l'étape en cours, puis dans
-- tous les segments suivants. (Avant, seul le guide en cours comptait : une quête prise ici pour
-- être rendue dans un segment suivant était proposée à l'abandon.)
local later = {}                 -- [id de guide] = quêtes rendues dans les segments suivants
local function turnedLater(g)
    if later[g.id] then return later[g.id] end
    local set, seen, cur = {}, { [g.id] = true }, g.next and ns.Guides[g.next]
    while cur and not seen[cur.id] do
        seen[cur.id] = true
        for _, s in ipairs(cur.steps) do
            if s.type == "turnin" and s.quest then set[s.quest] = true end
        end
        cur = cur.next and ns.Guides[cur.next]
    end
    later[g.id] = set
    return set
end
function M.Ahead()
    local g, _, cur = ns.Engine.Current()
    local set = {}
    if not g then return set end
    for i = cur or 1, #g.steps do
        local s = g.steps[i]
        if s.type == "turnin" and s.quest and ns.Engine.Applies(s) then set[s.quest] = true end
    end
    for q in pairs(turnedLater(g)) do set[q] = true end
    return set
end

-- Places qu'il faut pour les prochaines prises : les prises à venir avant la première quête à
-- faire ou à rendre (au même PNJ ou au même camp, on prend tout d'un coup).
function M.Needed()
    local g, _, cur = ns.Engine.Current()
    local n = 0
    if not g then return n end
    local taking = {}
    for i = cur or 1, math.min(#g.steps, (cur or 1) + 30) do
        local s = g.steps[i]
        if s.quest then
            if s.type == "accept" then
                if not ns.Engine.IsDone(s, i) then n = n + 1; taking[s.quest] = true end
            elseif taking[s.quest] or not ns.Engine.IsDone(s, i) then
                break                 -- on part faire ou rendre une quête : la tournée de prises est finie
            end
        end
    end
    return n
end

-- quêtes à abandonner en priorité : celles que la route ne rend plus, niveau le plus bas d'abord
function M.Suggestions()
    local ahead = M.Ahead()
    local out = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local q = info and not info.isHeader and info.questID
        if q and not ahead[q] and not C_QuestLog.IsComplete(q) then
            out[#out + 1] = { id = q, title = info.title or C_QuestLog.GetTitleForQuestID(q) or ("#" .. q), level = info.level or 0 }
        end
    end
    table.sort(out, function(a, b) return a.level < b.level end)
    return out
end

local btn
function M:Update()
    if not ns.Guide then return end
    local n, max = M.Count()
    -- à l'avance : les prochaines prises ne tiennent pas dans le journal
    local need = (self.enabled and M:Opt("ahead") ~= false) and M.Needed() or 0
    local short = need - (max - n)
    local full = self.enabled and (max - n <= (M:Opt("margin") or 2) or short > 0)
    local sugg = full and M.Suggestions() or {}
    if full then
        local names = {}
        for k = 1, math.min(math.max(3, short), #sugg) do names[k] = sugg[k].title end
        local text = ns.Tr("|cffff7f3fJournal presque plein|r (%d/%d)"):format(n, max)
        if short > 0 then
            text = ns.Tr("|cffff7f3fJournal trop plein|r : %d place(s) à libérer pour les %d prochaines quêtes"):format(short, need)
        end
        if #names > 0 then text = text .. "\n" .. ns.Tr("À abandonner : %s"):format(table.concat(names, ", ")) end
        ns.Guide:SetSection("questlog", 7, text)
    else
        ns.Guide:SetSection("questlog", 7, nil)
    end
    if not btn and ns.Guide.AddButton then
        btn = ns.Guide:AddButton("questlog", nil, 22, function() M:AbandonFirst() end, function(tt)
            local s = M.Suggestions()[1]
            tt:AddLine(ns.Tr("Abandonner une quête hors de la route"))
            if s then tt:AddLine(s.title, 1, 1, 1) end
        end, "Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    end
    if btn then btn:SetShown(full and #sugg > 0 or false); ns.Guide:Layout() end
end

function M:AbandonFirst()
    local s = M.Suggestions()[1]
    if not s then return end
    C_QuestLog.SetSelectedQuest(s.id)
    C_QuestLog.SetAbandonQuest()
    C_QuestLog.AbandonQuest()
    ns.Print(("Quête abandonnée : %s"):format(s.title))
end

local queued
local function queue()
    if queued then return end
    queued = true
    C_Timer.After(0.5, function() queued = false; M:Update() end)
end
M:On("QUEST_ACCEPTED", queue)
M:On("QUEST_REMOVED", queue)
M:On("QUEST_LOG_UPDATE", queue)
M:On("FP_STEP_CHANGED", queue)
M:On("QUEST_DETAIL", function()
    local n, max = M.Count()
    if n >= max then ns.Toast("Journal de quêtes plein : abandonne une quête hors de la route.", nil, 1, 0.5, 0.25) end
end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cffff7f3fJournal presque plein|r (19/20)\nÀ abandonner : Le vieux puits")
end
