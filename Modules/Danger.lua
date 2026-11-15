local _, ns = ...

-- Pensé pour le mode Hardcore de Forever : alerte quand tu cibles un monstre dangereux.
local M = ns.RegisterModule({
    id = "danger", category = "safety", default = false,
    name = ns.Tr("Alertes de danger"),
    desc = ns.Tr("Prévient quand tu cibles un élite, un rare ou un monstre trop haut niveau, et signale les étapes risquées. Idéal pour jouer prudemment."),
    options = {
        { key = "diff", label = ns.Tr("Écart de niveau dangereux"), type = "slider", min = 2, max = 6, step = 1, default = 3 },
        { key = "sound", label = "Son d'alerte", type = "check", default = true },
    },
})

local last, lastTime
M:On("PLAYER_TARGET_CHANGED", function()
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then return end
    local okL, lvl = pcall(UnitLevel, "target")
    local okC, class = pcall(UnitClassification, "target")
    if not okL or ns.IsSecret(lvl) then return end
    -- le GUID de la cible peut être « secret » (hors de portée des addons) : on ne le compare
    -- qu'en clair ; sinon on évite juste de répéter l'alerte plus d'une fois toutes les 8 s.
    local okG, guid = pcall(UnitGUID, "target")
    if not okG or ns.IsSecret(guid) then guid = nil end
    if guid and guid == last then return end
    if not guid and lastTime and GetTime() - lastTime < 8 then return end
    local reason
    if lvl == -1 then reason = ns.Tr("niveau ??")
    elseif lvl - ns.PlayerLevel() >= (M:Opt("diff") or 3) then reason = ns.Tr("niveau %d"):format(lvl) end
    if okC and not ns.IsSecret(class) and (class == "elite" or class == "rareelite" or class == "worldboss") then
        reason = (reason and reason .. ", " or "") .. ns.Tr("élite")
    end
    if reason then
        last, lastTime = guid, GetTime()
        local okN, name = pcall(UnitName, "target")
        if not okN or not name or ns.IsSecret(name) then name = ns.Tr("ta cible") end
        ns.Toast(("Danger : %s (%s)"):format(name, reason),
            "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", 1, 0.25, 0.2, 3)
        if M:Opt("sound") then PlaySound(SOUNDKIT.RAID_WARNING) end
    end
end)

M:On("FP_STEP_CHANGED", function()
    local _, step = ns.Engine.Current()
    if step and step.danger then
        ns.Toast(ns.Tr("Étape dangereuse : avance prudemment ou cherche un groupe."), "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", 1, 0.4, 0.2, 5)
    end
end)

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(26, 26); t:SetPoint("CENTER", 0, 10)
    t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    local s = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallGold")
    s:SetPoint("TOP", t, "BOTTOM", 0, -3)
    s:SetTextColor(1, 0.3, 0.2)
    s:SetText(ns.Tr("Danger : élite niv. 31"))
end
