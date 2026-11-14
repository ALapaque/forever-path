local ADDON, ns = ...

local meta = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)
ns.VERSION = meta and meta(ADDON, "Version") or "dev"
if not ns.VERSION or ns.VERSION:find("@") then ns.VERSION = "dev" end
ns.MEDIA = "Interface\\AddOns\\ForeverPath\\Media\\"

local FP = CreateFrame("Frame", "ForeverPathCore")
ns.FP = FP

---------------------------------------------------------------------------
-- Base de données
---------------------------------------------------------------------------
local defaults = {
    global = {
        modules = {},        -- [moduleId] = true/false (nil = valeur par défaut du module)
        mopts = {},          -- [moduleId][key] = valeur
        frames = {},         -- positions des fenêtres : [name] = { point, rel, relPoint, x, y }
        firstRun = true,
        locked = false,
    },
    char = {
        guideId = nil,
        stepIndex = 1,
        skipped = {},
        recording = false,
        recorded = {},
    },
}

local function applyDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(dst[k]) == "table" then
            applyDefaults(dst[k], v)
        end
    end
end

function ns.Print(fmt, ...)
    local msg = select("#", ...) > 0 and fmt:format(...) or fmt
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37ForeverPath|r " .. msg)
end

---------------------------------------------------------------------------
-- Bus d'événements
---------------------------------------------------------------------------
local handlers = {}
function ns.On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        if not event:find("^FP_") then FP:RegisterEvent(event) end
    end
    table.insert(handlers[event], fn)
end

function ns.Fire(event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then geterrorhandler()(err) end
    end
end

FP:SetScript("OnEvent", function(_, event, ...) ns.Fire(event, ...) end)

---------------------------------------------------------------------------
-- Système de modules
--  ns.RegisterModule({
--      id, name, desc, category, default = true,
--      options = { { key, label, type = "check"|"slider"|"select", default, min, max, step, values } },
--      preview = function(parent) ... end,  -- construit un aperçu dans `parent` (zone 150x80)
--      OnEnable = fn, OnDisable = fn, OnOptionChanged = fn(key, value),
--  })
--  Dans le module : M:On("EVENT", fn) — handler appelé seulement si le module est actif.
---------------------------------------------------------------------------
ns.Modules, ns.ModuleOrder = {}, {}

local ModuleProto = {}
ModuleProto.__index = ModuleProto

function ModuleProto:On(event, fn)
    ns.On(event, function(...)
        if self.enabled then fn(...) end
    end)
end

function ModuleProto:Opt(key)
    local o = ns.db and ns.db.mopts[self.id]
    if o and o[key] ~= nil then return o[key] end
    for _, def in ipairs(self.options or {}) do
        if def.key == key then return def.default end
    end
end

function ModuleProto:SetOpt(key, value)
    ns.db.mopts[self.id] = ns.db.mopts[self.id] or {}
    ns.db.mopts[self.id][key] = value
    if self.enabled and self.OnOptionChanged then self:OnOptionChanged(key, value) end
    ns.Fire("FP_OPTION_CHANGED", self.id, key, value)
end

function ns.RegisterModule(m)
    assert(m.id, "module sans id")
    setmetatable(m, ModuleProto)
    if m.default == nil then m.default = true end
    m.enabled = false
    ns.Modules[m.id] = m
    table.insert(ns.ModuleOrder, m.id)
    return m
end

function ns.IsEnabled(id)
    local m = ns.Modules[id]
    return m and m.enabled
end

function ns.WantsEnabled(id)
    local m = ns.Modules[id]
    if not m then return false end
    if m.locked then return true end
    local v = ns.db.modules[id]
    if v == nil then return m.default end
    return v
end

function ns.SetModuleEnabled(id, on)
    local m = ns.Modules[id]
    if not m then return end
    ns.db.modules[id] = on and true or false
    if on and not m.enabled then
        m.enabled = true
        if m.OnEnable then m:OnEnable() end
    elseif not on and m.enabled then
        m.enabled = false
        if m.OnDisable then m:OnDisable() end
    end
    ns.Fire("FP_MODULE_TOGGLED", id, on)
    ns.Fire("FP_STEP_CHANGED", true) -- rafraîchit l'affichage
end

---------------------------------------------------------------------------
-- Démarrage
---------------------------------------------------------------------------
FP:RegisterEvent("ADDON_LOADED")
ns.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    ForeverPathDB = ForeverPathDB or {}
    ForeverPathCharDB = ForeverPathCharDB or {}
    applyDefaults(ForeverPathDB, defaults.global)
    applyDefaults(ForeverPathCharDB, defaults.char)
    ns.db = ForeverPathDB
    ns.cdb = ForeverPathCharDB
    ns.Fire("FP_INIT")
end)

ns.On("PLAYER_LOGIN", function()
    if ns.ResolveMaps then ns.ResolveMaps() end
    for _, id in ipairs(ns.ModuleOrder) do
        if ns.WantsEnabled(id) then
            local m = ns.Modules[id]
            m.enabled = true
            if m.OnEnable then
                local ok, err = pcall(m.OnEnable, m)
                if not ok then geterrorhandler()(err) end
            end
        end
    end
    ns.Fire("FP_READY")
    if ns.db.firstRun then
        ns.db.firstRun = false
        C_Timer.After(3, function() if ns.Options then ns.Options:Open() end end)
    end
end)

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
function ns.PlayerFaction() return (UnitFactionGroup("player")) end
function ns.PlayerLevel() return UnitLevel("player") or 1 end
function ns.PlayerRace() return select(2, UnitRace("player")) end
function ns.PlayerClass() return select(2, UnitClass("player")) end

function ns.PlayerMapPos()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return mapID end
    local x, y = pos:GetXY()
    return mapID, x, y
end

-- Valeur "secrète" (restrictions d'addons) : on ne peut pas la lire.
function ns.IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

-- npcID depuis un GUID "Creature-0-xxxx-xxxx-xxxx-NPCID-xxxx" (le npcID n'est pas brouillé sur Forever)
function ns.NpcIDFromUnit(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or not guid or ns.IsSecret(guid) then return end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end

-- Nom localisé d'un PNJ (table générée Guides/_NpcNames.lua)
function ns.NpcName(id)
    local n = ns.NpcNames and ns.NpcNames[id]
    if not n then return end
    return ns.isFrench and n[1] or n[2]
end

-- Sauvegarde/restaure la position d'une fenêtre déplaçable
function ns.MakeMovable(frame, key, defaultPoint)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not (ns.db.locked or InCombatLockdown() and self:IsProtected()) then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        ns.db.frames[key] = { p, rp, x, y }
    end)
    local function restore()
        local p = ns.db.frames[key] or defaultPoint
        frame:ClearAllPoints()
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    end
    if ns.db then restore() else ns.On("FP_INIT", restore) end
end
