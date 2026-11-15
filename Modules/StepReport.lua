local _, ns = ...

-- Signaler une étape : les routes sont générées à partir d'une base de quêtes encore incomplète
-- pour Forever. Un clic sur le drapeau note l'étape et la raison ; /qw signalements donne un texte
-- à copier pour l'envoyer (GitHub, Discord). Les étapes passées automatiquement parce que le PNJ
-- ne proposait pas la quête sont notées aussi.
local M = ns.RegisterModule({
    id = "stepreport", category = "community", default = true,
    name = ns.Tr("Signaler une étape"),
    desc = ns.Tr("Un bouton drapeau dans le guide pour signaler une étape qui pose problème : quête trop haute, pas disponible, mauvais endroit, trop dangereuse. /qw signalements affiche un texte à copier et à envoyer pour corriger les routes."),
    options = {
        { key = "button", label = ns.Tr("Bouton dans le guide"), type = "check", default = true },
    },
})
ns.StepReport = M

local REASONS = {
    { key = "high", label = ns.Tr("Quête ou monstres trop hauts") },
    { key = "unavailable", label = ns.Tr("Quête pas disponible") },
    { key = "place", label = ns.Tr("Mauvais endroit") },
    { key = "danger", label = ns.Tr("Trop dangereux (élite, groupe)") },
    { key = "other", label = ns.Tr("Autre problème") },
}
M.REASONS = REASONS

local function store()
    ns.db.stepReports = ns.db.stepReports or {}
    return ns.db.stepReports
end

-- Ajoute un signalement (silent : pas de message, pour les signalements automatiques)
function M.Add(reason, g, step, i, silent)
    if not (g and step) then return end
    local list = store()
    local key = ("%s:%d:%s"):format(g.id, i or 0, reason)
    for _, r in ipairs(list) do if r.key == key then return end end      -- déjà signalé
    local pos = ns.PlayerMapPos and { ns.PlayerMapPos() } or {}
    list[#list + 1] = { key = key, reason = reason, guide = g.id, index = i or 0, type = step.type or "?",
        quest = step.quest or 0, qlvl = step.qlvl or 0, level = ns.PlayerLevel(),
        map = pos[1] or 0, x = pos[2] and math.floor(pos[2] * 1000 + 0.5) / 10 or 0,
        y = pos[3] and math.floor(pos[3] * 1000 + 0.5) / 10 or 0 }
    while #list > 200 do table.remove(list, 1) end
    if not silent then
        ns.Toast((ns.Tr("Étape signalée, merci ! (%d en attente, /qw signalements pour les envoyer)")):format(#list),
            "Interface\\Icons\\INV_Banner_03", 0.4, 0.9, 0.5, 4)
    end
end

function M.Export()
    local out = { ("QWS1;%s;%s;%s;%s"):format(ns.VERSION or "?", GetLocale and GetLocale() or "?",
        ns.PlayerFaction() or "?", ns.PlayerClass and ns.PlayerClass() or "?") }
    for _, r in ipairs(store()) do
        out[#out + 1] = ("S;%s;%d;%s;%d;%d;%d;%s;%d;%s;%s"):format(r.guide, r.index, r.type, r.quest, r.qlvl, r.level,
            r.reason, r.map, tostring(r.x), tostring(r.y))
    end
    return table.concat(out, "\n")
end

-- petit menu des raisons, sous le bouton
local menu
local function openMenu(anchor)
    if not menu then
        menu = CreateFrame("Frame", "QuestweaverStepReportMenu", UIParent, "BackdropTemplate")
        menu:SetFrameStrata("DIALOG")
        menu:SetSize(230, 16 + #REASONS * 22)
        ns.Skin(menu, 0.97)
        menu.rows = {}
        for k, r in ipairs(REASONS) do
            local b = ns.Button(menu, r.label, 214, 20)
            b:SetPoint("TOPLEFT", 8, -8 - (k - 1) * 22)
            b:SetScript("OnClick", function()
                local g, step, i = ns.Engine.Current()
                M.Add(r.key, g, step, i)
                menu:Hide()
            end)
            menu.rows[k] = b
        end
        tinsert(UISpecialFrames, "QuestweaverStepReportMenu")
    end
    if menu:IsShown() then menu:Hide() return end
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor or UIParent, "BOTTOMLEFT", 0, -2)
    menu:Show()
end
M.OpenMenu = openMenu

ns.SlashExt.signalements = function(arg)
    if arg == "reset" then
        ns.db.stepReports = nil
        ns.Print(ns.Tr("Signalements effacés."))
        return
    end
    if #store() == 0 then ns.Print(ns.Tr("Aucune étape signalée pour l'instant.")) return end
    ns.ShowExport(M.Export(), ns.Tr("Étapes signalées (Ctrl+A, Ctrl+C) — à envoyer sur GitHub ou Discord"))
end
ns.SlashExt.reports = ns.SlashExt.signalements
ns.SlashExt.signaler = function()
    local g, step = ns.Engine.Current()
    if g and step then openMenu(ns.Guide and ns.Guide.frame) end
end

local btn
local function updateButton()
    if not (ns.Guide and ns.Guide.AddButton) then return end
    if not btn then
        btn = ns.Guide:AddButton("stepreport", nil, 22, function(self) openMenu(self) end,
            function(tt)
                tt:SetText(ns.Tr("Signaler cette étape"), 1, 1, 1)
                tt:AddLine(ns.Tr("Quête trop haute, pas disponible, mauvais endroit… Ton signalement aide à corriger les routes."), 0.8, 0.8, 0.8, true)
            end, "Interface\\Icons\\INV_Banner_03")
    end
    btn:SetShown(M.enabled and M:Opt("button") and true or false)
    ns.Guide:Layout()
end

function M:OnEnable() updateButton() end
function M:OnDisable() if menu then menu:Hide() end updateButton() end
function M:OnOptionChanged() updateButton() end

function M.preview(p)
    local ic = p:CreateTexture(nil, "ARTWORK")
    ic:SetSize(26, 26); ic:SetPoint("TOP", 0, -8)
    ic:SetTexture("Interface\\Icons\\INV_Banner_03")
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("TOP", ic, "BOTTOM", 0, -6)
    fs:SetWidth(140)
    fs:SetText(ns.Tr("Quête ou monstres trop hauts") .. "\n" .. ns.Tr("Quête pas disponible"))
end
