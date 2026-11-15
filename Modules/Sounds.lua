local _, ns = ...

-- Signaux sonores : étape terminée, objectifs complets, arrivée au bout d'un détour.
local M = ns.RegisterModule({
    id = "sounds", category = "comfort", default = false,
    name = "Signaux sonores",
    desc = "Un son discret quand une étape est terminée, quand les objectifs d'une quête sont complets et à l'arrivée d'un détour. Pratique pour jouer sans regarder le guide.",
    options = {
        { key = "step", label = "Étape terminée", type = "check", default = true },
        { key = "objective", label = "Objectifs complets", type = "check", default = true },
        { key = "arrive", label = "Arrivée", type = "check", default = true },
    },
})

-- sons du jeu (repli sur des identifiants numériques si SOUNDKIT ne les a pas)
local SOUNDS = { step = { "UI_QUEST_ROLLING_FORWARD_01", 50893 }, objective = { "IG_QUEST_LIST_COMPLETE", 878 },
    arrive = { "MAP_PING", 3175 } }
function M.Play(kind)
    if not (M.enabled and M:Opt(kind)) then return end
    local s = SOUNDS[kind]
    local id = SOUNDKIT and SOUNDKIT[s[1]] or s[2]
    pcall(PlaySound, id, "Master")
    M.last = kind
end

local lastIdx, lastGuide
M:On("FP_STEP_CHANGED", function()
    local g, _, i = ns.Engine.Current()
    if g and g.id == lastGuide and lastIdx and i > lastIdx then M.Play("step") end
    lastGuide, lastIdx = g and g.id, i
end)
local complete = {}
M:On("QUEST_LOG_UPDATE", function()
    local route = ns.Engine.GuideQuests()
    for q in pairs(route) do
        local done = C_QuestLog.GetLogIndexForQuestID(q) and C_QuestLog.IsComplete(q)
        if done and not complete[q] then complete[q] = true; M.Play("objective") end
        if not done then complete[q] = nil end
    end
end)
M:On("FP_DETOUR_ARRIVED", function() M.Play("arrive") end)

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK"); t:SetSize(30, 30); t:SetPoint("CENTER", 0, 8)
    t:SetTexture("Interface\\Common\\VoiceChat-Speaker")
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("TOP", t, "BOTTOM", 0, -4); fs:SetText("ding !")
end
