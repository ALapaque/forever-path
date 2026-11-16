local _, ns = ...
local L = ns.L

-- Zones et donjons conseillés selon le niveau, alerte au level-up, choix de la route.
local M = ns.RegisterModule({
    id = "zones", category = "guide", default = true,
    name = ns.Tr("Zones et donjons conseillés"),
    desc = ns.Tr("Bouton « Zones » : les meilleures zones et les donjons pour ton niveau, avec les nouvelles zones de Forever. Alerte quand ta zone devient trop basse."),
    options = {
        { key = "alert", label = ns.Tr("Alerte au passage de niveau"), type = "check", default = true },
        { key = "count", label = ns.Tr("Nombre de zones affichées"), type = "slider", min = 3, max = 8, step = 1, default = 5 },
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

-- Segments de la route par zone : pour changer de zone à la main.
-- Clé de zone tirée de l'id du segment (« horde-orc-22-ashenvale-2 » -> « ashenvale »).
function R.SegmentZone(g) return g and g.id and g.id:match("^.-%-%d+%-(%a+)") end

-- quêtes encore à prendre dans un segment (avec les étapes passées de CE segment)
function R.Remaining(g)
    local n = 0
    for i, s in ipairs(g.steps) do
        if s.type == "accept" and ns.Engine.Applies(s) and not ns.Engine.IsDone(s, i, g.id) then n = n + 1 end
    end
    return n
end

-- Parcours (path) suivi : celui du segment en cours, ou de la zone choisie
local function currentPath()
    local cur = ns.Guides[ns.cdb.guideId or ""]
    return cur and cur.path
end

-- Segments du parcours dans une zone, utiles à ton niveau (de 6 niveaux sous toi à 3 au-dessus)
function R.ZoneSegments(key, lvl, path)
    lvl, path = lvl or ns.PlayerLevel(), path or currentPath()
    local faction, out = ns.PlayerFaction(), {}
    for _, id in ipairs(ns.GuideOrder) do
        local g = ns.Guides[id]
        if R.SegmentZone(g) == key and (not g.faction or g.faction == faction) and (not path or g.path == path)
            and (g.minLevel or 1) <= lvl + 3 and (g.maxLevel or 60) >= lvl - 6 then
            out[#out + 1] = g
        end
    end
    return out
end

-- { { zone = <entrée de Data/Zones>, key, min, max, left } }, une ligne par zone de la route
function R.Segments(lvl)
    lvl = lvl or ns.PlayerLevel()
    local cur = ns.Guides[ns.cdb.guideId or ""]
    local path, faction = cur and cur.path, ns.PlayerFaction()
    local best = {}
    for _, id in ipairs(ns.GuideOrder) do
        local g = ns.Guides[id]
        local key = R.SegmentZone(g)
        if key and (not g.faction or g.faction == faction) and (not path or g.path == path)
            and (g.minLevel or 1) <= lvl + 3 and (g.maxLevel or 60) >= lvl - 6 then
            local left = R.Remaining(g)
            if left > 0 then
                local b = best[key]
                if not b then
                    b = { key = key, zone = ns.ZoneByKey[key], min = g.minLevel or 1, max = g.maxLevel or 60, left = 0 }
                    best[key] = b
                end
                b.min, b.max = math.min(b.min, g.minLevel or 1), math.max(b.max, g.maxLevel or 60)
                b.left = b.left + left
            end
        end
    end
    local out = {}
    for _, v in pairs(best) do
        local mid = (v.min + v.max) / 2
        v.d = math.abs(mid - lvl) + (v.min > lvl and 2 or 0)
        out[#out + 1] = v
    end
    table.sort(out, function(a, b) if a.d ~= b.d then return a.d < b.d end return a.key < b.key end)
    return out
end

-- Zone choisie à la main : un guide « zone » qui enchaîne TOUS les segments de ta route dans cette
-- zone à ton niveau (les routes coupent une zone en plusieurs passages : suivre un seul passage
-- renvoyait ailleurs dès qu'il était fini, par exemple de Bois de la Pénombre vers Orneval). Quand
-- il n'y a plus rien à faire dans la zone, retour à la route conseillée.
local ZPREFIX = "zone:"
function R.BuildZoneGuide(key, path, lvl)
    local segs = R.ZoneSegments(key, lvl, path)
    if #segs == 0 then return end
    local id = ZPREFIX .. (path or "-") .. ":" .. key
    local steps, minL, maxL, faction = {}, 99, 1, nil
    for _, g in ipairs(segs) do
        for _, s in ipairs(g.steps) do steps[#steps + 1] = s end
        minL, maxL = math.min(minL, g.minLevel or 1), math.max(maxL, g.maxLevel or 60)
        faction = faction or g.faction
    end
    local z = ns.ZoneByKey[key]
    local g = { id = id, name = ("%s %d-%d"):format(z and ns.ZoneName(z) or key, minL, maxL), faction = faction,
                path = path, minLevel = minL, maxLevel = maxL, steps = steps, zoneKey = key, chosen = true }
    ns.Guides[id] = g                -- pas dans GuideOrder : jamais choisi automatiquement
    return g
end

-- après un /reload : reconstruire le guide « zone » enregistré
function ns.RebuildGuide(id)
    local path, key = (id or ""):match("^" .. ZPREFIX .. "(.-):(%a+)$")
    if not key then return end
    local saved = ns.cdb.zoneChoice
    return R.BuildZoneGuide(key, path ~= "-" and path or nil, saved and saved.level)
end

function R.Choose(key)
    -- compat : id de segment
    if ns.Guides[key] and not ns.Guides[key].chosen then key = R.SegmentZone(ns.Guides[key]) or key end
    local path, lvl = currentPath(), ns.PlayerLevel()
    local g = R.BuildZoneGuide(key, path, lvl)
    if not g then return end
    ns.cdb.zoneChoice = { key = key, path = path, level = lvl }
    -- nouveau choix : la liste des passages peut avoir changé, les étapes passées à la main
    -- d'un choix précédent ne correspondent plus (les quêtes faites restent reconnues)
    ns.cdb.skipped[g.id] = {}
    ns.Engine.Load(g.id)
    ns.cdb.pinned = g.id
    if ns.ZonePanel and ns.ZonePanel:IsShown() then ns.ZonePanel:Refresh() end
    return g
end

-- Panneau
local p = CreateFrame("Frame", "QuestweaverZonePanel", UIParent, "BackdropTemplate")
p:SetSize(330, 10)
p:Hide()
ns.Skin(p, 0.92, 0.6)
p.lines = {}
p.rows = {}

local function hex(r, g, b) return ("ff%02x%02x%02x"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)) end

function p:Refresh()
    for _, fs in ipairs(self.lines) do fs:Hide() end
    for _, b in ipairs(self.rows) do b:Hide() end
    local nr = 0
    -- ligne cliquable (changer de zone)
    local function row(text, onClick, tip)
        nr = nr + 1
        local b = self.rows[nr]
        if not b then
            b = CreateFrame("Button", nil, self)
            b:SetSize(310, 16)
            b.fs = b:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
            b.fs:SetAllPoints(); b.fs:SetJustifyH("LEFT")
            b.hl = b:CreateTexture(nil, "HIGHLIGHT")
            b.hl:SetAllPoints(); b.hl:SetColorTexture(1, 1, 1, 0.08)
            b:SetScript("OnClick", function(btn) if btn.onClick then btn.onClick() end end)
            b:SetScript("OnEnter", function(btn)
                if not btn.tip then return end
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT"); GameTooltip:SetText(btn.tip, 1, 1, 1, 1, true); GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            self.rows[nr] = b
        end
        b.onClick, b.tip = onClick, tip
        b.fs:SetText(text)
        return b
    end
    local lvl = ns.PlayerLevel()
    local here = ns.CurrentZone()
    local n, y = 0, -8
    local function add(text, header)
        n = n + 1
        local fs = self.lines[n]
        if not fs then
            fs = self:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
            fs:SetJustifyH("LEFT"); fs:SetWordWrap(true); fs:SetWidth(310)
            self.lines[n] = fs
        end
        fs:SetFontObject(header and "QuestweaverFontNormal" or "QuestweaverFontSmall")
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
        if z.faction == "Contested" then s = s .. ns.Tr(" |cffaaaaaa(contestée)|r") end
        if z.new then s = s .. " |cff66ccffNOUVEAU|r" end
        if z.unconfirmed then s = s .. " |cffff7f3f" .. L.UNCONFIRMED .. "|r" end
        if here == z then s = s .. " |cff3fbf3f(" .. L.YOU_ARE_HERE .. ")|r" end
        add(s)
        if z.note then add("   |cff888888" .. z.note .. "|r") end
    end
    -- changer de zone : segments de ta route, un clic pour y aller
    local segs = R.Segments(lvl)
    local curG = ns.Guides[ns.cdb.guideId or ""]
    local curKey = curG and (curG.zoneKey or R.SegmentZone(curG))
    if #segs > 0 then
        y = y - 4
        add(ns.Tr("Changer de zone"), true)
        for k = 1, math.min(8, #segs) do
            local sg = segs[k]
            local r, g, b = R.Color({ min = sg.min, max = sg.max }, lvl)
            local name = sg.zone and ns.ZoneName(sg.zone) or sg.key
            local s = ("|c%s%d-%d|r  %s  |cffaaaaaa"):format(hex(r, g, b), sg.min, sg.max, name)
                .. ns.Tr("%d quête(s)"):format(sg.left) .. "|r"
            if sg.key == curKey then s = s .. " |cff3fbf3f(" .. ns.Tr("en cours") .. ")|r" end
            local zkey = sg.key
            local bt = row(s, function() R.Choose(zkey) end, ns.Tr("Clic : suivre la route dans cette zone"))
            bt:ClearAllPoints(); bt:SetPoint("TOPLEFT", 10, y); bt:Show()
            y = y - 18
        end
        local cur = ns.Guides[ns.cdb.guideId or ""]
        if ns.cdb.pinned and cur then
            local bt = row("|cff66ccff" .. ns.Tr("Revenir à la route conseillée") .. "|r", function()
                ns.cdb.pinned, ns.cdb.zoneChoice = nil, nil
                local id = ns.Engine.PickDefault()
                if id then ns.Engine.Load(id) end
                p:Refresh()
            end)
            bt:ClearAllPoints(); bt:SetPoint("TOPLEFT", 10, y); bt:Show()
            y = y - 18
        end
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
    if ns.Guide and not btn then btn = ns.Guide:AddButton("zones", L.ZONES, 60, function() p:Toggle() end,
        ns.Tr("Zones et donjons conseillés pour ton niveau")) end
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
    local fs = pp:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("LEFT", 10, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(ns.Tr("|cffffd100Zones (niv. 38)|r\n|cffffff0036-44|r Rives Claires |cff66ccffNOUVEAU|r\n|cffffff0035-45|r Terres ingrates\n|cffcc66ff35-40|r La Cité engloutie"))
end
