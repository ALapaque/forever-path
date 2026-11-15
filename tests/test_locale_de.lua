-- Scénario : client allemand (FP_LOCALE=deDE) : textes courts en allemand, le reste en anglais
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
check(ns.L.ACCEPT == "Annehmen", "verbes en allemand")
check(ns.Modules.merchant.name == "Automatischer Händler", "nom de module en allemand")
check(ns.Modules.merchant.desc:find("^When opening a merchant"), "description longue : repli anglais")
check(ns.Tr("Session de 45 min lancée.") == "Sitzung von 45 Min. gestartet.", "modèle formaté en allemand")
check(ns.Tr("|cffcc66ffXP|r 61% du niveau") == "|cffcc66ffXP|r 61% der Stufe", "pourcentage conservé")
print("ALL TESTS PASSED")
