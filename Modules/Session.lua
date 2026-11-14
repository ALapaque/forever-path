local _, ns = ...
local Nav = ns.Nav

-- Session de jeu : « j'ai 45 min ». Estime jusqu'où tu iras dans le guide et propose un point
-- d'arrêt sur un rendu de quête, puis l'auberge la plus proche pour finir reposé.
local M = ns.RegisterModule({
    id = "session", category = "comfort", default = true,
    name = "Session de jeu",
    desc = "Indique le temps dont tu disposes (bouton horloge ou /fp session 45) : ForeverPath estime jusqu'où tu iras, propose de t'arrêter juste après un rendu de quête, puis te guide vers l'auberge la plus proche.",
    options = {
        { key = "minutes", label = "Durée par défaut (minutes)", type = "slider", min = 15, max = 240, step = 15, default = 60 },
        { key = "inn", label = "Guider vers l'auberge à la fin", type = "check", default = true },
    },
})

-- temps estimé d'une étape (secondes), hors trajet
local T = { accept = 10, turnin = 10, complete = 150, ["goto"] = 0, level = 600, note = 5, fly = 60, hearth = 15, flightpath = 15 }
M.T = T

local function stepTime(s)
    if s.type == "complete" and not s.mobs then return 70 end
    return T[s.type] or 10
end

-- Étape encore à faire dans le futur ? (IsDone considère « faire / rendre » comme faits si la quête
-- n'est pas encore dans le journal, ce qui est vrai maintenant mais pas après l'avoir prise)
local function ahead(s, j, i)
    if j == i then return true end
    local q = s.quest
    if q and C_QuestLog.IsQuestFlaggedCompleted(q) then return false end
    local inLog = q and C_QuestLog.GetLogIndexForQuestID(q) ~= nil
    if s.type == "accept" then return not inLog end
    if s.type == "complete" then return not (inLog and C_QuestLog.IsComplete(q)) end
    if s.type == "turnin" then return true end
    return not ns.Engine.IsDone(s, j)
end

-- Plan : jusqu'où aller dans le guide en `seconds` secondes. Renvoie l'index d'arrêt (dernier rendu
-- atteignable), le temps estimé jusque-là et le nombre d'étapes.
function M.Plan(seconds)
    local g, _, i = ns.Engine.Current()
    if not g then return end
    local here = Nav.Player()
    local speed = Nav.RunSpeed()
    local cum, stopIdx, stopCum, count, n = 0, nil, 0, 0, 0
    for j = i, #g.steps do
        local s = g.steps[j]
        if ns.Engine.Applies(s) and ahead(s, j, i) then
            local p = s.x and Nav.StepPoint(s)
            if p and here then
                cum = cum + (p.c == here.c and Nav.Dist(here, p) / speed or 120)
                here = p
            elseif p then
                here = p
            end
            cum = cum + stepTime(s)
            if cum > seconds then break end
            n = n + 1
            if s.type == "turnin" or j == #g.steps then stopIdx, stopCum, count = j, cum, n end
        end
    end
    return stopIdx, stopCum, count, g.id
end

local btn
local function fmt(sec)
    sec = math.max(0, sec)
    if sec >= 3600 then return ("%dh%02d"):format(math.floor(sec / 3600), math.floor(sec % 3600 / 60)) end
    return ("%d min"):format(math.ceil(sec / 60))
end

function M:Start(minutes)
    minutes = tonumber(minutes) or self:Opt("minutes") or 60
    local idx, cum, count, gid = M.Plan(minutes * 60)
    ns.cdb.session = { endsAt = time() + minutes * 60, minutes = minutes, stopIdx = idx, guideId = gid }
    if idx then
        local g = ns.Guides[gid]
        ns.Print(("Session de %d min : arrêt conseillé après « %s » (%d étapes, environ %s)."):format(minutes,
            ns.Guide and ns.Guide.StepLabel(g.steps[idx]):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") or idx, count, fmt(cum)))
    else
        ns.Print(("Session de %d min lancée."):format(minutes))
    end
    self:Update()
end

function M:Stop(silent)
    ns.cdb.session = nil
    if not silent then ns.Print("Session terminée.") end
    self:Update()
end

local function finish()
    local s = ns.cdb.session
    if not s or s.finished then return end
    s.finished = true
    local inn = M:Opt("inn") and ns.Nav.Places.NearestInn()
    ns.Toast(inn and ("Fin de session : auberge %s (%s)"):format(inn.name, ns.Nav.Places.ZoneName(inn.map)) or "Fin de session : bon moment pour t'arrêter",
        "Interface\\Icons\\INV_Misc_PocketWatch_01", 0.4, 0.8, 1, 8)
    if inn then ns.Nav.Places.Go(inn, ("Auberge : %s"):format(inn.name), "Interface\\Icons\\Spell_Nature_Sleep") end
end

function M:Update()
    if not ns.Guide then return end
    if not btn then
        btn = ns.Guide:AddButton("session", nil, 22, function()
            if ns.cdb.session then M:Stop() else M:Start() end
        end, function(tt)
            local s = ns.cdb.session
            if s then
                tt:AddLine(("Session : %s restantes"):format(fmt(s.endsAt - time())))
                tt:AddLine("Clic : terminer la session", 0.6, 0.6, 0.6)
            else
                tt:AddLine("Session de jeu")
                tt:AddLine(("Clic : démarrer une session de %d min\n/fp session 45 pour une autre durée"):format(M:Opt("minutes") or 60), 1, 1, 1, true)
            end
        end, "Interface\\Icons\\INV_Misc_PocketWatch_01")
    end
    btn:SetShown(self.enabled and true or false)
    local s = ns.cdb.session
    if not (self.enabled and s) then ns.Guide:SetSection("session", 8, nil) return end
    local left = s.endsAt - time()
    local g, _, i = ns.Engine.Current()
    local text
    if left <= 0 or (s.stopIdx and g and g.id == s.guideId and i > s.stopIdx) then
        text = "|cff66ccffSession|r terminée : c'est le bon moment pour t'arrêter."
        finish()
    elseif s.stopIdx and g and g.id == s.guideId then
        text = ("|cff66ccffSession|r %s restantes  •  arrêt après l'étape %d (encore %d)"):format(fmt(left), s.stopIdx, s.stopIdx - i + 1)
    else
        text = ("|cff66ccffSession|r %s restantes"):format(fmt(left))
    end
    ns.Guide:SetSection("session", 8, text)
end

M:On("FP_STEP_CHANGED", function() M:Update() end)
local acc = 0
M:On("FP_TICK", function()
    acc = acc + 1
    if acc >= 20 then acc = 0; M:Update() end      -- toutes les 10 s
end)
M:On("FP_READY", function()
    local s = ns.cdb.session
    if s and time() - s.endsAt > 3600 then M:Stop(true) end    -- session oubliée
    M:Update()
end)
function M:OnEnable() self:Update() end
function M:OnDisable() self:Update() end

ns.SlashExt.session = function(arg)
    if arg == "stop" or arg == "fin" then M:Stop() else M:Start(tonumber(arg)) end
end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|cff66ccffSession|r 42 min restantes\narrêt après l'étape 18\n\n|cff66ccffDétour :|r Auberge")
end
