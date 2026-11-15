-- Scénario : profils et assistant, rapport de bug, versions, sons, palette daltonien, suivre le chef
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
date = function() return "23:00:00" end
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
local P = ns.Modules.profiles

-- profils
check(P.Apply("minimal"), "profil Minimal appliqué")
check(ns.Modules.guide.enabled and not ns.Modules.journeys.enabled and not ns.Modules.nameplates.enabled, "Minimal : guide oui, itinéraires et barres de nom non")
check(ns.Modules.appearance.enabled, "modules toujours actifs conservés")
P.Apply("hardcore")
check(ns.Modules.hardcore.enabled and ns.Modules.rares.enabled and ns.Modules.journeys.enabled, "Hardcore : mode prudent + défauts")
P.Apply("decouverte")
check(not ns.Modules.hardcore.enabled and ns.Modules.journeys.enabled, "Découverte : retour aux réglages conseillés")
check(not P.Apply("inconnu"), "profil inconnu refusé")
-- export / import
ns.Modules.session:SetOpt("minutes", 45)
ns.SetModuleEnabled("splits", true)
local code = P.Export()
check(code:match("^FPP1;") and code:find("splits=1") and code:find("session.minutes=n:45"), "export : "..code:sub(1, 60).."…")
ns.SetModuleEnabled("splits", false)
ns.Modules.session:SetOpt("minutes", 90)
check(P.Import(code), "import")
check(ns.Modules.splits.enabled and ns.Modules.session:Opt("minutes") == 45, "réglages restaurés")
check(not P.Import("n'importe quoi"), "profil invalide refusé")
P.ShowWizard()
check(_G.QuestweaverWizard ~= nil, "assistant créé")

-- rapport de bug
EXPECTED_ERRORS = 1
ns.ReportError("boom de test")
local txt = ns.BugReport.Text()
check(txt:find("Questweaver ") and txt:find("Modules actifs") and txt:find("boom de test"), "rapport de bug complet")

-- versions
local V = ns.Modules.version
check(V.Newer("v0.3.0", "v0.2.0-beta13"), "0.3.0 > 0.2.0-beta13")
check(V.Newer("v0.2.0", "v0.2.0-beta13"), "finale > beta")
check(V.Newer("v0.2.0-beta14", "v0.2.0-beta13") and not V.Newer("v0.2.0-beta9", "v0.2.0-beta13"), "betas comparées en nombre")
ns.VERSION = "v0.2.0-beta13"
local toasted
local oldToast = ns.Toast
ns.Toast = function(m) toasted = m end
FireEvent("CHAT_MSG_ADDON", "QWVRV", "v0.2.0-beta20", "GUILD", "Hazghard")
ns.Toast = oldToast
check(toasted and toasted:find("beta20"), "averti d'une version plus récente")

-- sons
ns.SetModuleEnabled("sounds", true)
local played
PlaySound = function(id) played = id end
ns.Modules.sounds.Play("arrive")
check(played ~= nil and ns.Modules.sounds.last == "arrive", "son joué")

-- palette daltonien
local before = ns.Guide.STYLE.turnin.color
ns.Modules.appearance:SetOpt("colorblind", true)
check(ns.Guide.STYLE.turnin.color ~= before and ns.Modules.maproute.COLORS.turnin[3] > 0.8, "palette daltonien appliquée")
ns.Modules.appearance:SetOpt("colorblind", false)
check(ns.Guide.STYLE.turnin.color == before, "palette normale restaurée")

-- suivre le chef
ns.Guides["lead-seg"] = { id = "lead-seg", name = "Seg du chef", steps = { { type = "note", text = "x" } } }
ns.Modules.groupsync:SetOpt("follow", true)
UnitIsGroupLeader = function(n) return n == "Thrall" end
Ambiguate = function(n) return n end
UnitInParty = function() return true end
IsInGroup = function() return true end
IsInRaid = function() return false end
FireEvent("CHAT_MSG_ADDON", "QWVR1", "2:lead-seg:1:1:20:", "PARTY", "Jaina")
check(ns.cdb.guideId ~= "lead-seg", "un membre qui n'est pas chef : on ne suit pas")
FireEvent("CHAT_MSG_ADDON", "QWVR1", "2:lead-seg:1:1:20:", "PARTY", "Thrall")
check(ns.cdb.guideId == "lead-seg", "route du chef chargée")
print("ALL TESTS PASSED")
