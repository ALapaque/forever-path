# Contribuer à ForeverPath

Merci ! Le plus utile aujourd'hui : **signaler les bugs** et **enregistrer les routes des nouvelles zones de Forever**.

## Signaler un bug
Ouvre un ticket « Bug » et joins :
- l'erreur Lua complète (installe **BugSack** + **BugGrabber** pour la copier) ;
- le résultat de `/fp where` ;
- le segment de route et l'étape (`/fp guides`, ou le titre de la fenêtre du guide).

## Proposer ou corriger une route
1. Active le module **Enregistreur de route** dans `/fp config` (ou `/fp rec on`).
2. Joue la zone normalement. Ajoute des notes avec `/fp note Prends le bateau au quai`.
3. `/fp export`, puis copie le texte (Ctrl+A, Ctrl+C).
4. Ouvre un ticket « Route » et colle-le, ou fais une pull request avec un fichier dans `Guides/`, ajouté au `.toc`.

Format complet des étapes : voir le README (section DSL) et l'en-tête de `Parser.lua`.

Les fichiers `Guides/Route_*.lua` et `Guides/_NpcNames.lua` sont **générés** : ne les modifie pas à la main. Change plutôt le générateur `tools/gen_routes.py`, ou ajoute un guide manuel à part.

## Développement
```
pip install lupa          # Lua 5.1 pour les tests
luarocks install luacheck
luacheck . -q             # lint
python3 tests/harness.py  # tests avec une API WoW simulée
```
La CI GitHub lance les deux à chaque push et pull request.

### Ajouter un module
```lua
local M = ns.RegisterModule({
    id = "monmodule", category = "comfort", default = true,
    name = "Mon module", desc = "Ce qu'il fait, en une phrase.",
    options = { { key = "foo", label = "Option", type = "check", default = true } },
    preview = function(parent) --[[ aperçu 150x90 pour le panneau d'options ]] end,
})
M:On("QUEST_ACCEPTED", function(questID) if M:Opt("foo") then ... end end)
function M:OnEnable() end
function M:OnDisable() end
```
Le module apparaît automatiquement dans le panneau d'options. Ajoute son fichier au `.toc`, après `Modules\Guide.lua`.

## Publier une version (mainteneurs)
Pousse un tag `vX.Y.Z` (ou `vX.Y.Z-beta1`) : l'action **Release** empaquette l'addon et le publie sur GitHub Releases. Elle publie aussi sur CurseForge et Wago si les secrets `CF_API_KEY` / `WAGO_API_TOKEN` et les lignes `## X-Curse-Project-ID` / `## X-Wago-ID` du `.toc` sont renseignés.
