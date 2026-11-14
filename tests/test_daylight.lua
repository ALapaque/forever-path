-- Scénario : Daylight UI installé (API 1.4) + guidage 3D sur le cadre de navigation.
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end

local registered, events, commands = nil, {}, {}
local accent = { 0.2, 0.6, 1.0 }
DaylightUI = {
  API = {
    major = 1, minor = 4,
    Accent = function() return accent[1], accent[2], accent[3] end,
    Colors = function() return { TEXT = { r = 0.9, g = 0.9, b = 0.92 } } end,
    FontFile = function(key) return key == "general" and "Interface\\AddOns\\DaylightUI\\Media\\Inter.ttf" or nil end,
    For = function(name) return {
      On = function(ev, fn) events[ev] = fn; return {} end,
      RegisterCommand = function(word, fn) commands[word] = fn end,
    } end,
  },
  RegisterPlugin = function(self, name, opts) registered = { name = name, opts = opts } end,
}

FireEvent("ADDON_LOADED", "ForeverPath")
FireEvent("PLAYER_LOGIN")

check(registered and registered.name == "ForeverPath", "plugin enregistré auprès de Daylight UI")
check(registered.opts.needs[1] == 1 and registered.opts.needs[2] == 4, "version d'API demandée 1.4")
check(ns.Daylight.registered, "pont actif")
check(ns.db.theme == "daylight", "thème Daylight UI adopté par défaut")
check(ns.db.font == ns.Daylight.FONT_NAME, "police de Daylight UI adoptée")
local t = ns.Theme()
check(t.key == "daylight" and math.abs(t.accent[3] - 1.0) < 1e-6, "accent lu depuis API.Accent")
check(math.abs(t.text[1] - 0.9) < 1e-6, "couleur de texte lue depuis API.Colors")
check(ns.FontList()[1] == ns.Daylight.FONT_NAME, "police DUI proposée en premier")
check(commands.path ~= nil, "commande /dui path")

-- changement de style dans DUI -> thème mis à jour
accent = { 1.0, 0.4, 0.1 }
events.StyleChanged()
check(math.abs(ns.Theme().accent[1] - 1.0) < 1e-6, "suit StyleChanged")

-- l'utilisateur choisit un autre thème : on le respecte au rechargement suivant
ns.Modules.appearance:SetOpt("theme", "Minimal")
check(ns.db.theme == "minimal", "choix de thème respecté")

-- API trop récente (majeure 2) : pas d'enregistrement
DaylightUI.API.major = 2
check(not ns.Daylight.Available(), "API majeure inconnue refusée")
DaylightUI.API.major = 1

-- guidage 3D
check(ns.IsEnabled("guide3d"), "guidage 3D actif par défaut")
local navX, navY, clamped = 600, 300, false
C_Navigation = {
  GetFrame = function() return { GetCenter = function() return navX, navY end, GetEffectiveScale = function() return 1 end } end,
  HasValidScreenPosition = function() return true end,
  GetTargetState = function() return 2 end,
  WasClampedToScreen = function() return clamped end,
  GetDistance = function() return 50 end,
}
C_SuperTrack = { IsSuperTrackingUserWaypoint = function() return true end, SetSuperTrackedUserWaypoint = function() end }
local function part() local o = { a = 1 } function o:SetAlpha(v) self.a = v end function o:GetAlpha() return self.a end return o end
SuperTrackedFrame = { Icon = part(), DistanceText = part(), Arrow = part() }
IN_GAME_NAVIGATION_RANGE = "%s mètres"
ns.Modules.guide3d:Refresh()
local onUpdate = ForeverPathGuide3D._scripts and ForeverPathGuide3D._scripts.OnUpdate
check(onUpdate ~= nil, "boucle d'affichage du marqueur")
check(SuperTrackedFrame.DistanceText.a == 0 and SuperTrackedFrame.Icon.a == 0, "marqueur de Blizzard masqué")
SuperTrackedFrame.DistanceText.a = 1   -- le jeu le réaffiche
onUpdate(ForeverPathGuide3D, 0.1)
check(SuperTrackedFrame.DistanceText.a == 0, "marqueur de Blizzard gardé masqué")
check(ns.FormatDistance(64.6) == "65 mètres", "distance au format du jeu : "..ns.FormatDistance(64.6))
ns.Modules.guide3d:SetOpt("hideBlizzard", false)
check(SuperTrackedFrame.DistanceText.a == 1, "marqueur de Blizzard réaffiché sur demande")
onUpdate(ForeverPathGuide3D, 0.1)
ns.Modules.guide3d:SetOpt("hideBlizzard", true)
clamped = true
onUpdate(ForeverPathGuide3D, 0.1)
check(true, "marqueur en champ et hors champ (flèche de bord)")
ns.SetModuleEnabled("guide3d", false)
check(not ns.IsEnabled("guide3d"), "désactivation du guidage 3D")
print("ALL TESTS PASSED")
