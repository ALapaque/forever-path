local _, ns = ...

--[==[
Format de guide (DSL) — une étape par ligne :

  M elwynn                      carte courante (clé de zone de Data/Zones.lua, ou uiMapID numérique)
  A 783 "Une menace intérieure" @48.2,42.9 npc=Adjoint_Willem id=823
  C 7 "Tue les kobolds" @48.0,33.0 mobs=257,6
  T 783 @48.9,41.6 npc=Maréchal_McBride id=197
  G "Va à Comté-de-l'Or" @42.1,65.9 r=20
  L 6 "Tue des loups jusqu'au niveau 6"
  N "Achète des sacs"
  H "Pierre de foyer"      F "Vol vers Hurlevent"     P "Prends le point de vol" @..
  # commentaire

Options (après le texte, sans espaces dans la valeur, _ = espace) :
  npc=Nom      id=<npcID>         PNJ à qui parler (bouton Cibler, barres de nom, modèle 3D)
  mobs=1,2,3   target=Nom         mobs à tuer (barres de nom / bouton Cibler)
  class=MAGE,PRIEST  race=Human,Dwarf   restreint l'étape
  r=<yards>    rayon de validation d'un G
  upto=<niv>   étape ignorée si le joueur a déjà ce niveau (routes adaptatives)
  danger=1     étape signalée comme dangereuse (élites, PvP...)
  opt=1        étape optionnelle
]==]

local TYPES = {
    A = "accept", C = "complete", T = "turnin", G = "goto",
    L = "level", N = "note", H = "hearth", F = "fly", P = "flightpath",
}
ns.STEP_TYPES = TYPES

local function splitSet(s, numeric)
    local set = {}
    for v in s:gmatch("[^,]+") do
        set[numeric and tonumber(v) or v] = true
    end
    return set
end

local function unders(v) return (v:gsub("_", " ")) end

function ns.ParseGuide(text)
    local steps, map = {}, nil
    local lineNo = 0
    for raw in (text .. "\n"):gmatch("(.-)\r?\n") do
        lineNo = lineNo + 1
        local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and not line:find("^#") and not line:find("^%-%-") then
            local code, rest = line:match("^(%u)%s*(.*)$")
            if code == "M" then
                local v = rest:match("^(%S+)")
                map = tonumber(v) or v
            elseif code and TYPES[code] then
                local step = { type = TYPES[code], map = map, line = lineNo }
                local txt = rest:match('"(.-)"')
                if txt then
                    step.text = txt
                    rest = rest:gsub('"(.-)"', "", 1)
                end
                local x, y = rest:match("@(%d+%.?%d*)%s*,%s*(%d+%.?%d*)")
                if x then
                    step.x, step.y = tonumber(x), tonumber(y)
                    rest = rest:gsub("@%d+%.?%d*%s*,%s*%d+%.?%d*", "", 1)
                end
                for k, v in rest:gmatch("(%a+)=(%S+)") do
                    if k == "class" then step.class = splitSet(v)
                    elseif k == "race" then step.race = splitSet(v)
                    elseif k == "r" then step.radius = tonumber(v)
                    elseif k == "npc" then step.npc = unders(v)
                    elseif k == "id" then step.npcID = tonumber(v)
                    elseif k == "mobs" then step.mobs = splitSet(v, true)
                    elseif k == "target" then step.target = unders(v)
                    elseif k == "upto" then step.upto = tonumber(v)
                    elseif k == "danger" then step.danger = true
                    elseif k == "opt" then step.optional = true
                    elseif k == "map" then step.map = tonumber(v) or v
                    end
                end
                rest = rest:gsub("%a+=%S+", "")
                local num = tonumber(rest:match("(%d+)"))
                if step.type == "level" then
                    step.level = num
                elseif step.type == "accept" or step.type == "complete" or step.type == "turnin" then
                    step.quest = num
                    if not num then
                        error(("ForeverPath: ligne %d sans questID"):format(lineNo))
                    end
                end
                steps[#steps + 1] = step
            end
        end
    end
    return steps
end
