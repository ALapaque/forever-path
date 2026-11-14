local _, ns = ...
local L = ns.L

-- Zones et donjons conseillés selon le niveau, alerte au level-up, choix de la route.
local M = ns.RegisterModule({
    id = "zones", category = "guide", default = true,
    name = "Zones et donjons conseillés",
    desc = "Bouton « Zones » : les meilleures zones et les donjons pour ton niveau, avec les nouvelles zones de Forever. Alerte quand ta zone devient trop basse.",
    options = {
        { key = "alert", label = "Alerte au passage de niveau", type = "check", default = true },
        { key = "count", label = "Nombre de zones affichées", type = "slider", min = 3, max = 8, step = 1, default = 5 },
    },
})
ns.ZonesModule = M

local R = {}
ns.Recommend = R

function R.Score(z, lvl, faction)
    if z.city or z.key == "zephras" then return end
    if z.faction ~= "Contested" and z.faction ~= faction then return end
    if z.start and z.max <= 12 and lvl > z.max then return end
    if lvl < z.min - 2 or lvl > z.max - 1 then return end
    local ideal = z.min + (z.max - z.min) * 0.35
    local score = 100 - math.abs(lvl - ideal) * 6
    if z.faction == faction then score = score + 8 end
    if lvl < z.min then score = score - 15 end
    if z.unconfirmed then score = score - 10 end
    if z.new then score = score + 5 end
    return score
end

function R.Zones(lvl, faction, n)
    lvl, faction = lvl or ns.PlayerLevel(), faction or ns.PlayerFaction()
    local list = {}
    for _, z in ipairs(ns.Zones) do
        local s = R.Score(z, lvl, faction)
        if s then list[#list + 1] = { zone = z, score = s } end
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    local out = {}
    for i = 1, math.min(n or 4, #list) do out[i] = list[i].zone end
    return out
end

function R.Dungeons(lvl)
    lvl = lvl or ns.PlayerLevel()
    local out = {}
    for _, d in ipairs(ns.Dungeons) do
        if lvl >= d.min - 1 and lvl <= d.max then out[#out + 1] = d end
    end
    return out
end

function R.Color(z, lvl)
    local d = (z.min + z.max) / 2 - lvl
    if d >= 5 then return 1, 0.1, 0.1 elseif d >= 3 then return 1, 0.5, 0.25
    elseif d >= -2 then return 1, 1, 0 elseif d >= -5 then return 0.25, 0.75, 0.25 end
    return 0.6, 0.6, 0.6
end

-- Panneau
local p = CreateFrame("Frame", "ForeverPathZonePanel", UIParent, "BackdropTemplate")
p:SetSize(330, 10)
p:Hide()
ns.Skin(p, 0.92, 0.6)
p.lines = {}

local function hex(r, g, b) return ("ff%02x%02x%02x"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)) end

function p:Refresh()
    for _, fs in ipairs(self.lines) do fs:Hide() end
    local lvl = ns.PlayerLevel()
    local here = ns.CurrentZone()
    local n, y = 0, -8
    local function add(text, header)
        n = n + 1
        local fs = self.lines[n]
        if not fs then
            fs = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetJustifyH("LEFT"); fs:SetWordWrap(true); fs:SetWidth(310)
            self.lines[n] = fs
        end
        fs:SetFontObject(header and "GameFontNormal" or "GameFontHighlightSmall")
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 10, y)
        fs:SetText(text)
        fs:Show()
        y = y - fs:GetStringHeight() - (header and 6 or 4)
    end
    add(L.ZONES_TITLE:format(lvl), true)
    for _, z in ipairs(R.Zones(lvl, nil, M:Opt("count") or 5)) do
        local r, g, b = R.Color(z, lvl)
        local s = ("|c%s%d-%d|r  %s"):format(hex(r, g, b), z.min, z.max, ns.ZoneName(z))
        if z.faction == "Contested" then s = s .. " |cffaaaaaa(contestée)|r" end
        if z.new then s = s .. " |cff66ccffNOUVEAU|r" end
        if z.unconfirmed then s = s .. " |cffff7f3f" .. L.UNCONFIRMED .. "|r" end
        if here == z then s = s .. " |cff3fbf3f← " .. L.YOU_ARE_HERE .. "|r" end
        add(s)
        if z.note then add("   |cff888888" .. z.note .. "|r") end
    end
    local dj = R.Dungeons(lvl)
    if #dj > 0 then
        y = y - 4
        add(L.DUNGEONS_TITLE, true)
        for _, d in ipairs(dj) do
            add(("|cffcc66ff%d-%d|r  %s"):format(d.min, d.max, ns.isFrench and d.fr or d.en))
        end
    end
    self:SetHeight(-y + 6)
end

function p:Toggle()
    if self:IsShown() then self:Hide() return end
    self:ClearAllPoints()
    local g = ns.Guide and ns.Guide.frame
    if g and g:IsShown() then self:SetPoint("TOP", g, "BOTTOM", 0, -4) else self:SetPoint("CENTER") end
    self:Refresh()
    self:Show()
end
ns.ZonePanel = p

local btn
function M:OnEnable()
    if ns.Guide and not btn then btn = ns.Guide:AddButton("zones", L.ZONES, 60, function() p:Toggle() end) end
    if btn then btn:Show(); ns.Guide:Layout() end
end
function M:OnDisable()
    p:Hide()
    if btn then btn:Hide(); ns.Guide:Layout() end
end

M:On("PLAYER_LEVEL_UP", function(newLevel)
    C_Timer.After(1, function()
        if p:IsShown() then p:Refresh() end
        if not M:Opt("alert") then return end
        local z = ns.CurrentZone()
        if z and not z.city and newLevel > z.max then
            local names = {}
            for _, rz in ipairs(R.Zones(newLevel, nil, 3)) do names[#names + 1] = ns.ZoneName(rz) end
            ns.Toast(L.TOO_HIGH:format(ns.ZoneName(z), table.concat(names, ", ")), "Interface\\Icons\\INV_Misc_Map_01", 1, 0.85, 0.3, 6)
        end
    end)
end)
M:On("ZONE_CHANGED_NEW_AREA", function() if p:IsShown() then p:Refresh() end end)

function M.preview(pp)
    local fs = pp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", 10, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText("|cffffd100Zones (niv. 38)|r\n|cffffff0036-44|r Rives Claires |cff66ccffNOUVEAU|r\n|cffffff0035-45|r Terres ingrates\n|cffcc66ff35-40|r La Cité engloutie")
end
