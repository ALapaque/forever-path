local _, ns = ...

-- Duo / groupe : chaque membre avec ForeverPath partage son étape.
local PREFIX = "FPATH1"

local M = ns.RegisterModule({
    id = "groupsync", category = "comfort", default = true,
    name = "Progression du groupe",
    desc = "En groupe, affiche l'étape de chaque membre qui utilise ForeverPath, pour avancer ensemble.",
    options = {},
})

local members = {}   -- [name] = { guide, index, total, time }

local function send()
    if not IsInGroup() or IsInInstance() then return end
    local g, _, i = ns.Engine.Current()
    if not g then return end
    local msg = ("%s:%d:%d"):format(g.id, i, #g.steps)
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, IsInRaid() and "RAID" or "PARTY")
end

function M:Update()
    if not ns.Guide then return end
    local myGuide = ns.cdb.guideId
    local lines = {}
    for name, d in pairs(members) do
        if GetTime() - d.time < 600 and UnitInParty(name) then
            local same = d.guide == myGuide
            lines[#lines + 1] = ("|cff66ccff%s|r : %s"):format(Ambiguate(name, "short"),
                same and ("étape %d/%d"):format(d.index, d.total) or "autre segment")
        end
    end
    table.sort(lines)
    ns.Guide:SetSection("group", 80, table.concat(lines, "\n"))
end

function M:OnEnable()
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    send()
end
function M:OnDisable() if ns.Guide then ns.Guide:SetSection("group", 80, nil) end end

M:On("CHAT_MSG_ADDON", function(prefix, msg, _, sender)
    if prefix ~= PREFIX or ns.IsSecret(msg) then return end
    if Ambiguate(sender, "none") == UnitName("player") then return end
    local guide, i, total = msg:match("^(.-):(%d+):(%d+)$")
    if guide then
        members[sender] = { guide = guide, index = tonumber(i), total = tonumber(total), time = GetTime() }
        M:Update()
    end
end)
M:On("FP_STEP_CHANGED", function() send(); M:Update() end)
M:On("GROUP_ROSTER_UPDATE", function() send(); M:Update() end)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cff66ccffThrall|r : étape 12/48\n|cff66ccffJaina|r : étape 14/48")
end
