local _, ns = ...

-- Performances : mode « Économie » qui allège tout ce qui se redessine à chaque image (guidage 3D,
-- flèche, tracé de la minimap, barres de nom, modèle 3D du PNJ). En automatique, il s'active quand
-- le jeu rame (moins de 40 images/s pendant quelques secondes, par exemple avec une grosse suite
-- d'addons) et se coupe quand ça va mieux. /qw perf mesure ce que coûte Questweaver.
local MODES = { ns.Tr("Automatique (allège si le jeu rame)"), ns.Tr("Toujours complet"), ns.Tr("Toujours en économie") }

local M = ns.RegisterModule({
    id = "perf", category = "look", default = true, locked = true,
    name = "Performances",
    desc = "Le mode Économie allège les effets qui se redessinent à chaque image : points au sol et pulsation du guidage 3D, flèche, tracé sur la minimap, rebond sur les barres de nom, rotation du modèle du PNJ. En automatique, il s'active quand le jeu passe sous 40 images/s et se coupe quand ça va mieux. /qw perf mesure ce que coûte Questweaver.",
    options = {
        { key = "mode", label = "Mode", type = "select", values = MODES, default = 1 },
    },
})
ns.Perf = M

local LOW, HIGH = 40, 55          -- images/s : seuils d'entrée et de sortie du mode auto
local autoEco, low, high = false, 0, 0

function ns.Eco()
    local mode = M:Opt("mode") or 1
    if mode == 3 then return true end
    if mode == 2 then return false end
    return autoEco
end

local function set(v)
    if v == autoEco then return end
    autoEco = v
    ns.Fire("FP_PERF_CHANGED", ns.Eco())
end

-- vérifié deux fois par seconde (FP_TICK)
function M.Sample(fps)
    fps = fps or (GetFramerate and GetFramerate()) or 60
    if fps < LOW then low, high = low + 1, 0 else low = 0 end
    if fps > HIGH then high = high + 1 else high = 0 end
    if not autoEco and low >= 6 then set(true)            -- 3 s sous 40 i/s
    elseif autoEco and high >= 20 then set(false) end     -- 10 s au-dessus de 55 i/s
end
ns.On("FP_TICK", function() if (M:Opt("mode") or 1) == 1 then M.Sample() end end)
function M:OnOptionChanged() low, high, autoEco = 0, 0, false; ns.Fire("FP_PERF_CHANGED", ns.Eco()) end

---------------------------------------------------------------------------
-- /qw perf : mesure sur 10 s (mémoire allouée, et temps processeur si le profilage est actif)
---------------------------------------------------------------------------
local function mem()
    local upd = UpdateAddOnMemoryUsage or (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage)
    local get = GetAddOnMemoryUsage or (C_AddOns and C_AddOns.GetAddOnMemoryUsage)
    if not (upd and get) then return end
    upd()
    return get("Questweaver")
end
local function cpu()
    if not (GetCVar and GetCVar("scriptProfile") == "1") then return end
    local upd = UpdateAddOnCPUUsage or (C_AddOns and C_AddOns.UpdateAddOnCPUUsage)
    local get = GetAddOnCPUUsage or (C_AddOns and C_AddOns.GetAddOnCPUUsage)
    if not (upd and get) then return end
    upd()
    return get("Questweaver")
end

local measuring
function M.Measure(secs, done)
    if measuring then return end
    secs = secs or 10
    measuring = true
    local m0, c0 = mem(), cpu()
    ns.Print(ns.Tr("Mesure des performances pendant %d s… joue normalement."), secs)
    C_Timer.After(secs, function()
        measuring = false
        local m1, c1 = mem(), cpu()
        local fps = GetFramerate and GetFramerate() or 0
        local r = { fps = fps, eco = ns.Eco() }
        if m0 and m1 then r.kbps = math.max(0, (m1 - m0) / secs); r.kb = m1 end
        if c0 and c1 then r.msps = (c1 - c0) / secs end
        ns.Print(ns.Tr("Images/s : %d  •  mode économie : %s"), math.floor(fps + 0.5), r.eco and ns.Tr("oui") or ns.Tr("non"))
        if r.kb then ns.Print(ns.Tr("Mémoire : %d Ko, %.1f Ko/s alloués"), math.floor(r.kb), r.kbps) end
        if r.msps then
            ns.Print(ns.Tr("Processeur : %.2f ms par seconde de jeu"), r.msps)
        else
            ns.Print(ns.Tr("Temps processeur : tape /console scriptProfile 1 puis /reload, et relance /qw perf (pense à remettre 0 après)."))
        end
        if done then done(r) end
    end)
end
ns.SlashExt.perf = function() M.Measure(10) end

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText(ns.Tr("|cff66ccffÉconomie|r : effets allégés\nquand le jeu rame"))
end
