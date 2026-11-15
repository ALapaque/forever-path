local _, ns = ...

-- Argent : objectif de la monture (niveau 40) et gain d'or par heure, pour savoir s'il faut vendre
-- plutôt que garder. Affiché dans le guide à partir du niveau 30.
local M = ns.RegisterModule({
    id = "gold", category = "comfort", default = true,
    name = "Objectif monture (argent)",
    desc = "À partir du niveau 30 : ton or comparé au prix de la monture du niveau 40 (réglable), avec ton gain d'or par heure et une estimation du temps pour l'atteindre.",
    options = {
        { key = "goal", label = "Prix monture + apprentissage (pièces d'or)", type = "slider", min = 20, max = 200, step = 5, default = 90 },
        { key = "from", label = "Afficher à partir du niveau", type = "slider", min = 20, max = 40, step = 1, default = 30 },
    },
})

local start, startMoney
local function fmtTime(sec)
    if sec >= 3600 then return ("%dh%02d"):format(math.floor(sec / 3600), math.floor(sec % 3600 / 60)) end
    return ("%d min"):format(math.max(1, math.floor(sec / 60)))
end

function M.State()
    local money = GetMoney()
    local goal = (M:Opt("goal") or 90) * 10000
    local elapsed = start and (GetTime() - start) or 0
    local rate = elapsed > 300 and (money - startMoney) / elapsed * 3600 or nil
    return money, goal, rate
end

function M:Update()
    if not ns.Guide then return end
    local lvl = ns.PlayerLevel()
    if not self.enabled or lvl < (self:Opt("from") or 30) or ns.cdb.mountBought then
        ns.Guide:SetSection("gold", 92, nil) return
    end
    local money, goal, rate = M.State()
    local text
    if money >= goal then
        text = ns.Tr("|cffffd100Monture|r : tu as l'or nécessaire")
    else
        text = ns.Tr("|cffffd100Monture|r %d / %d po"):format(math.floor(money / 10000), goal / 10000)
        if rate and rate > 0 then
            text = text .. ns.Tr("  •  %d po/h, objectif dans ~%s"):format(math.floor(rate / 10000), fmtTime((goal - money) / rate * 3600))
        end
    end
    ns.Guide:SetSection("gold", 92, text)
end

M:On("PLAYER_MONEY", function() M:Update() end)
M:On("PLAYER_LEVEL_UP", function() M:Update() end)
M:On("FP_READY", function() start, startMoney = GetTime(), GetMoney(); M:Update() end)
-- monture apprise : plus besoin du rappel
M:On("NEW_MOUNT_ADDED", function() ns.cdb.mountBought = true; M:Update() end)
function M:OnEnable() if not start then start, startMoney = GetTime(), GetMoney() end self:Update() end
function M:OnDisable() self:Update() end
function M:OnOptionChanged() self:Update() end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cffffd100Monture|r 34 / 90 po\n12 po/h, objectif dans ~4h40")
end
