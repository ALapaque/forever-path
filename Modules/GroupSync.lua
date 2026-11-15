local _, ns = ...

-- Duo / groupe : chaque membre avec Questweaver partage son étape et ses quêtes de la route.
-- On voit qui est en avance ou en retard, et qui n'a pas la quête de l'étape (bouton Partager).
local PREFIX = "QWVR1"

local M = ns.RegisterModule({
    id = "groupsync", category = "comfort", default = true,
    name = ns.Tr("Progression du groupe"),
    desc = ns.Tr("En groupe, affiche l'étape de chaque membre qui utilise Questweaver (en avance, en retard), signale qui n'a pas la quête de l'étape et propose de la partager."),
    options = {
        { key = "share", label = ns.Tr("Proposer de partager les quêtes"), type = "check", default = true },
        { key = "follow", label = ns.Tr("Suivre la route du chef de groupe"), type = "check", default = false },
    },
})

local members = {}   -- [name] = { guide, index, total, level, quests = { [id] = true }, time }

-- tout mon journal de quêtes (celles de la route d'abord), et lesquelles sont prêtes à rendre
local function myQuests()
    local route, other, ready = {}, {}, {}
    local wanted = ns.Engine.GuideQuests()
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local q = info and not info.isHeader and info.questID
        if q and not ns.IsSecret(q) then
            if wanted[q] then route[#route + 1] = q else other[#other + 1] = q end
            if C_QuestLog.IsComplete and C_QuestLog.IsComplete(q) then ready[#ready + 1] = q end
        end
    end
    for _, q in ipairs(other) do route[#route + 1] = q end
    return route, ready
end
M.MyQuests = myQuests

-- liste « 1,2,3 » qui tient dans `budget` caractères (sans couper un numéro)
local function fit(list, budget)
    local out, len = {}, 0
    for _, q in ipairs(list) do
        local s = tostring(q)
        if len + #s + 1 > budget then break end
        out[#out + 1] = s
        len = len + #s + 1
    end
    return table.concat(out, ",")
end

function M.Encode()
    local g, _, i = ns.Engine.Current()
    if not g then return end
    local quests, ready = myQuests()
    local head = ("3:%s:%d:%d:%d:"):format(g.id, i, #g.steps, ns.PlayerLevel())
    local readyTxt = fit(ready, 60)
    return head .. fit(quests, 250 - #head - #readyTxt - 1) .. ":" .. readyTxt
end

function M.Decode(msg)
    local v3 = { msg:match("^3:(.-):(%d+):(%d+):(%d+):([%d,]*):([%d,]*)$") }
    if v3[1] then
        local q, r = {}, {}
        for id in v3[5]:gmatch("%d+") do q[tonumber(id)] = true end
        for id in v3[6]:gmatch("%d+") do r[tonumber(id)] = true end
        return { guide = v3[1], index = tonumber(v3[2]), total = tonumber(v3[3]), level = tonumber(v3[4]),
            quests = q, ready = r, full = true }
    end
    local v2 = { msg:match("^2:(.-):(%d+):(%d+):(%d+):([%d,]*)$") }
    if v2[1] then
        local q = {}
        for id in v2[5]:gmatch("%d+") do q[tonumber(id)] = true end
        return { guide = v2[1], index = tonumber(v2[2]), total = tonumber(v2[3]), level = tonumber(v2[4]), quests = q }
    end
    local guide, i, total = msg:match("^(.-):(%d+):(%d+)$")          -- ancienne version
    if guide then return { guide = guide, index = tonumber(i), total = tonumber(total) } end
end

local function send()
    if not IsInGroup() or IsInInstance() then return end
    local msg = M.Encode()
    if msg then pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg:sub(1, 250), IsInRaid() and "RAID" or "PARTY") end
end

local shareBtn, shareQuest
function M.Missing()
    local _, step = ns.Engine.Current()
    local q = step and step.quest
    if not q or not (step.type == "complete" or step.type == "turnin") then return end
    local missing = {}
    for name, d in pairs(members) do
        if d.quests and not d.quests[q] and d.guide == ns.cdb.guideId and GetTime() - d.time < 600 then
            missing[#missing + 1] = Ambiguate(name, "short")
        end
    end
    table.sort(missing)
    return q, missing
end

function M:Update()
    if not ns.Guide then return end
    local myGuide = ns.cdb.guideId
    local _, _, myIdx = ns.Engine.Current()
    local lines = {}
    for name, d in pairs(members) do
        if GetTime() - d.time < 600 and (not UnitInParty or UnitInParty(name)) then
            local where
            if d.guide ~= myGuide then where = ns.Tr("autre segment")
            elseif not myIdx or d.index == myIdx then where = ns.Tr("même étape")
            elseif d.index > myIdx then where = (ns.Tr("|cff3fbf3fen avance de %d|r")):format(d.index - myIdx)
            else where = (ns.Tr("|cffff7f3fen retard de %d|r")):format(myIdx - d.index) end
            lines[#lines + 1] = ("|cff66ccff%s|r%s : %s"):format(Ambiguate(name, "short"),
                d.level and (" (%d)"):format(d.level) or "", where)
        end
    end
    table.sort(lines)
    local q, missing = M.Missing()
    shareQuest = nil
    if q and #missing > 0 then
        lines[#lines + 1] = (ns.Tr("|cffffd100Sans la quête :|r %s")):format(table.concat(missing, ", "))
        if C_QuestLog.GetLogIndexForQuestID(q) then shareQuest = q end
    end
    ns.Guide:SetSection("group", 80, #lines > 0 and table.concat(lines, "\n") or nil)
    if not shareBtn and ns.Guide.AddButton then
        shareBtn = ns.Guide:AddButton("share", nil, 22, function() M:Share() end,
            ns.Tr("Partager la quête de l'étape avec le groupe"), "Interface\\GossipFrame\\AvailableQuestIcon")
    end
    if shareBtn then
        shareBtn:SetShown(self.enabled and M:Opt("share") and shareQuest ~= nil and IsInGroup() or false)
        ns.Guide:Layout()
    end
end

-- session de groupe : on suit le segment du chef (sans toucher à ses propres étapes faites)
function M.Follow(sender, d)
    if not (M.enabled and M:Opt("follow") and d.guide and ns.Guides[d.guide]) then return end
    local leader = UnitIsGroupLeader and UnitIsGroupLeader(Ambiguate(sender, "none"))
    if ns.IsSecret(leader) or not leader then return end
    if ns.cdb.guideId ~= d.guide then
        ns.Engine.Load(d.guide, true)
        ns.Print(ns.Tr("Route du chef de groupe chargée : %s"):format(ns.Guides[d.guide].name or d.guide))
    end
end

function M:Share()
    if not shareQuest then return end
    if C_QuestLog.SetSelectedQuest then C_QuestLog.SetSelectedQuest(shareQuest) end
    if QuestLogPushQuest then QuestLogPushQuest() end
end

function M:OnEnable()
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    send()
end
function M:OnDisable() if ns.Guide then ns.Guide:SetSection("group", 80, nil) end end

M:On("CHAT_MSG_ADDON", function(prefix, msg, _, sender)
    if prefix ~= PREFIX or ns.IsSecret(msg) or ns.IsSecret(sender) then return end
    if Ambiguate(sender, "none") == UnitName("player") then return end
    local d = M.Decode(msg)
    if d then
        d.time = GetTime()
        members[sender] = d
        M.Follow(sender, d)
        M:Update()
    end
end)
M.members = members
local queued
local function queueSend()
    if queued then return end
    queued = true
    C_Timer.After(1, function() queued = false; send(); M:Update() end)
end
M:On("FP_STEP_CHANGED", queueSend)
M:On("GROUP_ROSTER_UPDATE", queueSend)
M:On("QUEST_ACCEPTED", queueSend)
M:On("QUEST_REMOVED", queueSend)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("|cff66ccffThrall|r (14) : même étape\n|cff66ccffJaina|r (13) : |cffff7f3fen retard de 3|r\n|cffffd100Sans la quête :|r Jaina"))
end
