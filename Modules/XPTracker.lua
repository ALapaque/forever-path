local _, ns = ...

local M = ns.RegisterModule({
    id = "xp", category = "comfort", default = true,
    name = "Compteur d'XP",
    desc = ns.Tr("XP par heure de la session et temps estimé avant le prochain niveau, affichés dans la fenêtre du guide."),
    options = {},
})

local startTime, gained, lastXP, lastMax

local function fmtTime(sec)
    if sec == math.huge or sec ~= sec then return "?" end
    if sec >= 3600 then return ("%dh%02d"):format(math.floor(sec / 3600), math.floor(sec % 3600 / 60)) end
    return ("%d min"):format(math.max(1, math.floor(sec / 60)))
end
local function short(n) return n >= 1000 and ("%.1fk"):format(n / 1000) or tostring(math.floor(n)) end

function M:Update()
    if not ns.Guide then return end
    local xp, max = UnitXP("player"), UnitXPMax("player")
    if ns.IsSecret(xp) or not max or max == 0 then return end
    local elapsed = GetTime() - startTime
    local rate = elapsed > 60 and gained / elapsed * 3600 or 0
    local text
    if rate > 0 then
        text = (ns.Tr("|cffcc66ffXP|r %s/h  •  niveau dans %s  •  %d%%")):format(short(rate), fmtTime((max - xp) / rate * 3600), math.floor(xp / max * 100))
    else
        text = (ns.Tr("|cffcc66ffXP|r %d%% du niveau")):format(math.floor(xp / max * 100))
    end
    ns.Guide:SetSection("xp", 90, text)
end

function M:OnEnable()
    startTime, gained = GetTime(), 0
    lastXP, lastMax = UnitXP("player"), UnitXPMax("player")
    self:Update()
end
function M:OnDisable() if ns.Guide then ns.Guide:SetSection("xp", 90, nil) end end

M:On("PLAYER_XP_UPDATE", function()
    local xp, max = UnitXP("player"), UnitXPMax("player")
    if lastXP then
        if xp >= lastXP then gained = gained + (xp - lastXP) else gained = gained + (lastMax - lastXP) + xp end
    end
    lastXP, lastMax = xp, max
    M:Update()
end)
M:On("FP_STEP_CHANGED", function() M:Update() end)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("|cffcc66ffXP|r 18.4k/h\nniveau dans 23 min  •  61%"))
end
