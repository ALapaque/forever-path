local _, ns = ...

-- Pensé pour le mode Hardcore de Forever : alerte quand tu cibles un monstre dangereux.
local M = ns.RegisterModule({
    id = "danger", category = "safety", default = false,
    name = "Alertes de danger (Hardcore)",
    desc = "Prévient quand tu cibles un élite, un rare ou un monstre trop haut niveau, et signale les étapes risquées. Idéal en mode Hardcore.",
    options = {
        { key = "diff", label = "Écart de niveau dangereux", type = "slider", min = 2, max = 6, step = 1, default = 3 },
        { key = "sound", label = "Son d'alerte", type = "check", default = true },
    },
})

local last
M:On("PLAYER_TARGET_CHANGED", function()
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then return end
    local okL, lvl = pcall(UnitLevel, "target")
    local okC, class = pcall(UnitClassification, "target")
    if not okL or ns.IsSecret(lvl) then return end
    local guid = UnitGUID("target")
    if guid == last then return end
    local reason
    if lvl == -1 then reason = "niveau ??"
    elseif lvl - ns.PlayerLevel() >= (M:Opt("diff") or 3) then reason = ("niveau %d"):format(lvl) end
    if okC and not ns.IsSecret(class) and (class == "elite" or class == "rareelite" or class == "worldboss") then
        reason = (reason and reason .. ", " or "") .. "élite"
    end
    if reason then
        last = guid
        ns.Toast("Danger : " .. (UnitName("target") or "?") .. " (" .. reason .. ")",
            "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", 1, 0.25, 0.2, 3)
        if M:Opt("sound") then PlaySound(SOUNDKIT.RAID_WARNING) end
    end
end)

M:On("FP_STEP_CHANGED", function()
    local _, step = ns.Engine.Current()
    if step and step.danger then
        ns.Toast("Étape dangereuse : avance prudemment ou cherche un groupe.", "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", 1, 0.4, 0.2, 5)
    end
end)

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(26, 26); t:SetPoint("CENTER", 0, 10)
    t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    local s = p:CreateFontString(nil, "OVERLAY", "ForeverPathFontSmallGold")
    s:SetPoint("TOP", t, "BOTTOM", 0, -3)
    s:SetTextColor(1, 0.3, 0.2)
    s:SetText("Danger : élite niv. 31")
end
