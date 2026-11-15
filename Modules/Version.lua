local _, ns = ...

-- Nouvelle version : les joueurs de ton groupe ou de ta guilde qui ont Questweaver s'échangent leur
-- version ; si l'un d'eux en a une plus récente, tu es prévenu (une fois par session).
local PREFIX = "QWVRV"
local M = ns.RegisterModule({
    id = "version", category = "community", default = true,
    name = "Avertissement de nouvelle version",
    desc = "Compare ta version avec celles de ton groupe et de ta guilde (sans rien envoyer d'autre) et te prévient quand une version plus récente existe.",
    options = {},
})

-- "v0.2.0-beta13" -> { 0, 2, 0, 13, beta = true } ; une version finale passe devant ses betas
function M.Parse(v)
    local a, b, c, rest = tostring(v or ""):match("v?(%d+)%.(%d+)%.(%d+)(.*)")
    if not a then return end
    return { tonumber(a), tonumber(b), tonumber(c), tonumber(rest:match("(%d+)")) or 0, beta = rest ~= "" }
end
function M.Newer(a, b)          -- a plus récente que b ?
    local x, y = M.Parse(a), M.Parse(b)
    if not (x and y) then return false end
    for i = 1, 3 do if x[i] ~= y[i] then return x[i] > y[i] end end
    if x.beta ~= y.beta then return not x.beta end
    return x[4] > y[4]
end

local warned, newest
local function send(channel)
    if not ns.VERSION or ns.VERSION == "dev" then return end
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, ns.VERSION, channel)
end
local function broadcast()
    if not M.enabled then return end
    if IsInGroup() and not IsInInstance() then send(IsInRaid() and "RAID" or "PARTY") end
    if IsInGuild and IsInGuild() then send("GUILD") end
end

M:On("CHAT_MSG_ADDON", function(prefix, msg)
    if prefix ~= PREFIX or ns.IsSecret(msg) or not M.enabled then return end
    if M.Newer(msg, ns.VERSION) and (not newest or M.Newer(msg, newest)) then
        newest = msg
        if not warned then
            warned = true
            ns.Toast(ns.Tr("Nouvelle version de Questweaver disponible : %s"):format(msg), "Interface\\Icons\\INV_Misc_Map_01", 0.4, 0.8, 1, 8)
            ns.Print(ns.Tr("Nouvelle version disponible : %s (tu as %s). Télécharge-la sur GitHub ou CurseForge."):format(msg, tostring(ns.VERSION)))
        end
    end
end)
local sent = 0
M:On("GROUP_ROSTER_UPDATE", function() if GetTime() - sent > 60 then sent = GetTime(); broadcast() end end)
M:On("FP_READY", function() C_Timer.After(15, broadcast) end)
function M:OnEnable() C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cff66ccffNouvelle version|r\nv0.3.0 disponible")
end
