local _, ns = ...

-- Profils : quatre réglages prêts à l'emploi (assistant au premier lancement), et export / import
-- de tes réglages pour les partager ou les recopier sur un autre compte.
local M = ns.RegisterModule({
    id = "profiles", category = "look", default = true, locked = true,
    name = "Profils",
    desc = "Quatre profils prêts à l'emploi (Découverte, Speedrun, Hardcore, Minimal) qui cochent les bons modules d'un coup, proposés au premier lancement. /qw profil <nom>, /qw profil export pour partager tes réglages, /qw profil import pour les reprendre.",
    options = {},
})

M.PRESETS = {
    { key = "decouverte", name = "Découverte", icon = "Interface\\Icons\\INV_Misc_Map_01",
      desc = "Les réglages conseillés : guidage complet, aides utiles, rien d'envahissant.", on = {}, off = {} },
    { key = "speedrun", name = "Speedrun", icon = "Interface\\Icons\\INV_Misc_PocketWatch_02",
      desc = "Tout pour aller vite : vols, dialogues et achats automatiques, écran de splits, chrono.",
      on = { "splits", "supplies", "flights", "dialogue", "automation", "chrono", "catchup" },
      off = { "npcmodel", "rares", "secondary", "gold", "dungeons" } },
    { key = "hardcore", name = "Hardcore", icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
      desc = "Route prudente : quêtes dangereuses sautées, alertes de danger, rares sur la carte, secourisme.",
      on = { "hardcore", "danger", "rares", "secondary", "grouphint", "supplies" }, off = { "splits" } },
    { key = "minimal", name = "Minimal", icon = "Interface\\Icons\\INV_Misc_Note_01",
      desc = "Juste l'essentiel : la fenêtre du guide, la flèche, le point sur la carte et les objectifs.",
      on = { "guide", "arrow", "waypoint", "objectives" },
      off = { "maproute", "guide3d", "journeys", "nameplates", "targetbutton", "npcmodel", "questitem", "actionbar",
              "automation", "rewards", "xp", "reminders", "groupsync", "trainer", "session", "merchant", "gather",
              "grouphint", "chrono", "flights", "dialogue", "supplies", "questlog", "dungeons", "rares", "secondary",
              "gold", "talents", "splits", "zones", "minimapbutton", "sounds", "version", "library", "editor" } },
}
for _, p in ipairs(M.PRESETS) do p.name, p.desc = ns.Tr(p.name), ns.Tr(p.desc) end

function M.Apply(key)
    local preset
    for _, p in ipairs(M.PRESETS) do if p.key == key then preset = p end end
    if not preset then return false end
    -- on repart des valeurs par défaut, puis on applique le profil
    for id, m in pairs(ns.Modules) do
        if not m.locked then
            local want = m.default
            for _, x in ipairs(preset.on) do if x == id then want = true end end
            for _, x in ipairs(preset.off) do if x == id then want = false end end
            ns.SetModuleEnabled(id, want)
            ns.db.modules[id] = nil
            if want ~= m.default then ns.db.modules[id] = want end
        end
    end
    ns.db.profile = key
    ns.Print(ns.Tr("Profil appliqué : %s"):format(preset.name))
    return true
end

-- export : FPP1;mod=1,mod=0;module.clé=type:valeur|...
local function encodeValue(v)
    local t = type(v)
    if t == "boolean" then return "b:" .. (v and 1 or 0) end
    if t == "number" then return "n:" .. v end
    if t == "string" then return "s:" .. v:gsub("[|;=,]", "") end
end
function M.Export()
    local mods, opts = {}, {}
    for id, v in pairs(ns.db.modules) do mods[#mods + 1] = id .. "=" .. (v and 1 or 0) end
    for id, o in pairs(ns.db.mopts) do
        for k, v in pairs(o) do
            local e = encodeValue(v)
            if e then opts[#opts + 1] = id .. "." .. k .. "=" .. e end
        end
    end
    table.sort(mods); table.sort(opts)
    return "FPP1;" .. table.concat(mods, ",") .. ";" .. table.concat(opts, "|")
end
function M.Import(text)
    local mods, opts = (text or ""):match("^%s*FPP1;([^;]*);([^\n]*)")
    if not mods then ns.Print(ns.Tr("Profil invalide.")) return false end
    for id, v in mods:gmatch("([%w_]+)=([01])") do
        if ns.Modules[id] and not ns.Modules[id].locked then ns.SetModuleEnabled(id, v == "1") end
    end
    for id, k, t, v in opts:gmatch("([%w_]+)%.([%w_]+)=(%a):([^|]*)") do
        local m = ns.Modules[id]
        if m then
            local val = t == "b" and v == "1" or t == "n" and tonumber(v) or t == "s" and v
            if t == "b" then val = (v == "1") end
            m:SetOpt(k, val)
        end
    end
    ns.Print(ns.Tr("Profil importé."))
    return true
end

---------------------------------------------------------------------------
-- Assistant du premier lancement
---------------------------------------------------------------------------
local wiz
function M.ShowWizard()
    if not wiz then
        wiz = CreateFrame("Frame", "QuestweaverWizard", UIParent, "BackdropTemplate")
        wiz:SetSize(560, 330)
        wiz:SetPoint("CENTER", 0, 60)
        wiz:SetFrameStrata("DIALOG")
        ns.Skin(wiz, 0.96)
        tinsert(UISpecialFrames, "QuestweaverWizard")
        local t = wiz:CreateFontString(nil, "OVERLAY", "QuestweaverFontHuge")
        t:SetPoint("TOP", 0, -18)
        t:SetText(ns.Tr("Bienvenue dans Questweaver"))
        local s = wiz:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmallDim")
        s:SetPoint("TOP", t, "BOTTOM", 0, -6)
        s:SetText(ns.Tr("Choisis un profil pour commencer : tout reste modifiable ensuite (/qw config)."))
        for i, p in ipairs(M.PRESETS) do
            local b = CreateFrame("Button", nil, wiz, "BackdropTemplate")
            b:SetSize(250, 100)
            b:SetPoint("TOPLEFT", 22 + ((i - 1) % 2) * 266, -70 - math.floor((i - 1) / 2) * 112)
            ns.Skin(b, 0.6)
            local ic = b:CreateTexture(nil, "ARTWORK")
            ic:SetSize(34, 34); ic:SetPoint("TOPLEFT", 10, -10); ic:SetTexture(p.icon)
            local n = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontLarge")
            n:SetPoint("LEFT", ic, "RIGHT", 10, 0); n:SetText(p.name)
            local d = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
            d:SetPoint("TOPLEFT", 10, -50); d:SetPoint("RIGHT", -10, 0); d:SetJustifyH("LEFT"); d:SetText(p.desc)
            b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.83, 0.69, 0.22, 1) end)
            b:SetScript("OnLeave", function(self) ns.ReSkin(self) end)
            b:SetScript("OnClick", function()
                M.Apply(p.key)
                wiz:Hide()
                if ns.Options then ns.Options:Open() end
            end)
        end
    end
    wiz:Show()
end

ns.SlashExt.profil = function(arg)
    local cmd = (arg or ""):match("^(%S*)")
    if cmd == "export" then ns.ShowExport(M.Export(), ns.Tr("Profil Questweaver (Ctrl+A, Ctrl+C)"))
    elseif cmd == "import" then ns.ShowImport(ns.Tr("Colle le profil puis Importer"), M.Import)
    elseif cmd == "" then M.ShowWizard()
    elseif not M.Apply(cmd) then ns.Print("/qw profil decouverte | speedrun | hardcore | minimal | export | import") end
end
ns.SlashExt.profile = ns.SlashExt.profil

function M.preview(p)
    for i, pr in ipairs(M.PRESETS) do
        local ic = p:CreateTexture(nil, "ARTWORK")
        ic:SetSize(26, 26); ic:SetPoint("CENTER", (i - 2.5) * 34, 6); ic:SetTexture(pr.icon)
    end
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("BOTTOM", 0, 8); fs:SetText("/qw profil")
end
