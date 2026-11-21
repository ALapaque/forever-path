local _, ns = ...

local M = ns.RegisterModule({
    id = "objectives", category = "guide", default = true,
    name = ns.Tr("Objectifs en direct"),
    desc = ns.Tr("Affiche la progression de la quête en cours dans la fenêtre du guide (ex. Vermine kobold 6/10)."),
    options = {
        { key = "allLog", label = ns.Tr("Afficher aussi les autres quêtes de la zone"), type = "check", default = false },
    },
})

local function objectiveLines(questID)
    local out = {}
    local objs = C_QuestLog.GetQuestObjectives(questID)
    for _, o in ipairs(objs or {}) do
        if o.text and o.text ~= "" then
            local c = o.finished and "|cff3fbf3f" or "|cffffffff"
            out[#out + 1] = ("%s• %s|r"):format(c, o.text)
        end
    end
    return out
end

-- Objectifs d'une quête pour la fenêtre du guide : libellé sans le compteur, compteur à part
-- (« Sangliers tachetés tués : 3/8 » ou « 3/8 Mottled Boar slain » -> libellé, 3, 8).
function M.Rows(questID)
    local out = {}
    for _, o in ipairs(C_QuestLog.GetQuestObjectives(questID) or {}) do
        if o.text and o.text ~= "" then
            local have, need = o.numFulfilled, o.numRequired
            if type(have) ~= "number" or type(need) ~= "number" or ns.IsSecret(have) or ns.IsSecret(need) then
                have, need = nil, nil
            end
            local label = o.text
            if need and need > 0 then
                label = label:gsub("%s*:?%s*%d+%s*/%s*%d+%s*:?%s*", " "):gsub("^%s+", ""):gsub("%s+$", "")
                if label == "" then label = o.text end
            end
            out[#out + 1] = { label = label, have = have, need = need, done = o.finished and true or false }
        end
    end
    return out
end

function M:Update()
    if not ns.Guide then return end
    local _, step = ns.Engine.Current()
    local lines = {}
    -- l'étape en cours : une barre par objectif, dessinée par la fenêtre du guide
    local rows
    if step and step.quest and C_QuestLog.GetLogIndexForQuestID(step.quest) then
        rows = M.Rows(step.quest)
    end
    ns.Guide:SetObjectives(rows)
    if self:Opt("allLog") then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID ~= (step and step.quest) and not C_QuestLog.IsComplete(info.questID) then
                local objs = objectiveLines(info.questID)
                if #objs > 0 and #lines < 8 then
                    lines[#lines + 1] = "|cffaaaaaa" .. (info.title or "") .. "|r"
                    lines[#lines + 1] = objs[1]
                end
            end
        end
    end
    ns.Guide:SetSection("objectives", 10, table.concat(lines, "\n"))
end

function M:OnDisable() if ns.Guide then ns.Guide:SetObjectives(nil); ns.Guide:SetSection("objectives", 10, nil) end end
function M:OnEnable() self:Update() end
M:On("FP_STEP_CHANGED", function() M:Update() end)
M:On("QUEST_LOG_UPDATE", function() M:Update() end)
M:On("UNIT_QUEST_LOG_CHANGED", function() M:Update() end)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("LEFT", 10, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(ns.Tr("|cffff7f3fFaire|r : Nettoyer le camp\n|cffffffff• Vermine kobold 6/10|r\n|cff3fbf3f• Bougie ramassée 4/4|r"))
end
