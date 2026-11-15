-- Scénario : client anglais (FP_LOCALE=enUS) : interface, modèles formatés, guides
local ns = NS
local function check(c, m) if not c then error("FAIL: "..m) end print("ok - "..m) end
FireEvent("ADDON_LOADED", "Questweaver")
FireEvent("PLAYER_LOGIN")
RunTimers()
check(ns.isEnglish, "client anglais détecté")
check(ns.L.ACCEPT == "Accept", "verbes des étapes")
check(ns.Modules.merchant.name == "Auto merchant", "nom de module traduit")
check(ns.Modules.journeys.options[1].label == "Learn paths while playing", "réglages traduits")
check(ns.Tr("Session de 45 min lancée.") == "45 min session started.", "texte formaté reconnu")
check(ns.Tr("|cff66ccffSession|r 12 min restantes  •  arrêt après l'étape 18 (encore 3)") ==
  "|cff66ccffSession|r 12 min left  •  stop after step 18 (3 to go)", "section formatée")
check(ns.Tr("|cffcc66ffXP|r 61% du niveau") == "|cffcc66ffXP|r 61% of level", "pourcentage conservé")
check(ns.Tr("Texte inconnu") == "Texte inconnu", "texte inconnu inchangé")
-- guides générés
local found
for _, id in ipairs(ns.GuideOrder) do
  local g = ns.Guides[id]
  if g.name:find("^Elwynn Forest") then found = g end
end
check(found, "nom de guide traduit (Elwynn Forest)")
local head
for _, st in ipairs(found.steps) do if st.text and st.text:find("^Head to") then head = st.text end end
check(head and head:find("Elwynn Forest"), "texte d'étape traduit : "..tostring(head))
-- toutes les clés du dictionnaire avec %… donnent un modèle valide
local bad = 0
for fr in pairs(ns.EN) do
  if not pcall(string.match, "x", ns.ToPattern(fr)) then bad = bad + 1; print("modèle invalide : "..fr) end
end
check(bad == 0, "modèles valides")
print("ALL TESTS PASSED")
