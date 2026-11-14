local _, ns = ...

-- Éolides (Skyborne) : l'Île de Zéphras est un contenu nouveau de Forever, absent des bases
-- de données publiques. Route minimale en attendant un enregistrement (bouton ● / /fp rec on).
for _, faction in ipairs({ "Alliance", "Horde" }) do
    local boat = faction == "Alliance"
        and "Prends l'aéronef au quai est de Valanaar : il te dépose au nord de Dalaran."
        or "Prends l'aéronef au quai ouest de Valanaar : il te dépose près des Pitons-du-Tonnerre."
    ns.RegisterGuide({
        id = "skyborne-" .. faction:lower() .. "-01-zephras",
        name = "Île de Zéphras 1-12",
        faction = faction, startZone = "zephras", path = "skyborne-" .. faction:lower(),
        race = { Skyborne = true, SkyborneElf = true, Eolid = true },
        minLevel = 1, maxLevel = 12,
        text = ([[
M zephras
N "Fais toutes les quêtes de l'île : suis les points d'exclamation, la carte montre les objectifs."
N "Astuce : active l'enregistreur (bouton rond rouge) pour créer la route de l'île et la partager."
L 12 "Termine l'île jusqu'au niveau 12"
N "%s"
N "La route continue automatiquement avec le parcours de ta faction."
]]):format(boat),
    })
end
