"""Banc de test Questweaver : charge l'addon (ordre du .toc) dans Lua 5.1 avec une API WoW simulée,
puis exécute un script de test Lua.

Usage : python3 tests/harness.py [dossier_addon] [script_test.lua]
Dépendance : pip install lupa
"""
import os, re, sys
from lupa import lua51
lua = lua51.LuaRuntime(unpack_returned_tuples=True)
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(HERE)
TEST = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "test_addon.lua")
mocks = r'''
function mockobj()
  local o = {}
  return setmetatable(o, {__call=function() return nil end, __index=function(t,k)
    if k=="GetFontString" or k:match("^Create") then return function() return mockobj() end end
    if k:match("Height$") or k:match("Width$") or k:match("Scale$") or k:match("Level$") then return function() return 10 end end
    if k=="IsShown" then return function() return false end end
    if k=="GetPoint" then return function() return "CENTER",nil,"CENTER",0,0 end end
    return function() return nil end
  end})
end
EVENTS = {}
local core
function CreateFrame(kind, name)
  local f = mockobj()
  local scripts = {}
  rawset(f,"RegisterEvent", function(self,e) EVENTS[e]=true end)
  rawset(f,"SetScript", function(self,k,fn) scripts[k]=fn end)
  rawset(f,"_scripts", scripts)
  if name=="QuestweaverCore" then core=f end
  if name then _G[name]=f end
  return f
end
function FireEvent(e, ...) core._scripts.OnEvent(core, e, ...) end
function GetLocale() return "frFR" end
MISSING = {}
setmetatable(_G, {__index=function(t,k)
  if type(k)=="string" and (k:match("^Questweaver") or k=="DaylightUI") then return nil end
  if type(k)=="string" and k:match("^[A-Z]") or (type(k)=="string" and k:match("^C_")) then
    MISSING[k]=true
    local stub = mockobj()
    rawset(t,k,stub)
    return stub
  end
end})
function strsplit(sep, s) local out={} for p in (s..sep):gmatch("(.-)"..sep:gsub("%p","%%%0")) do out[#out+1]=p end return unpack(out) end
function Mixin(o, ...) return o end
-- comme le vrai client : pas de police tant que SetFont n'a pas été appelé, hauteur > 0 obligatoire
function CreateFont(name)
  local f = mockobj(); local font = { nil, 0, "" }
  rawset(f, "GetFont", function() return font[1], font[2], font[3] end)
  rawset(f, "SetFont", function(self, path, h, flags)
    if type(h) ~= "number" or h <= 0 then error(name..":SetFont(): Invalid font height ("..tostring(h).."): height must be > 0") end
    font = { path, h, flags } end)
  rawset(f, "CopyFontObject", function(self, o) font = { o:GetFont() } end)
  _G[name] = f; return f end
BackdropTemplateMixin = {}
function GetTime() return 1000 end
function InCombatLockdown() return false end
function IsInGroup() return false end
function IsInInstance() return false end
function UnitXP() return 100 end
function UnitXPMax() return 400 end
function UnitExists() return false end
function UnitIsPlayer() return false end
Enum={UIMapType={Zone=3}, TooltipDataLineType={QuestObjective=8}}
WORLD = { [1429] = { c = 0, ox = 0, oy = 0, w = 3000, h = 2000 }, [1436] = { c = 0, ox = -2000, oy = 0, w = 3000, h = 2000 },
          [1411] = { c = 1, ox = 0, oy = 0, w = 3000, h = 2000 } }
function CreateVector2D(x, y) return { x = x, y = y, GetXY = function(self) return self.x, self.y end } end
SOUNDKIT={RAID_WARNING=1}
function PlaySound() end

function CopyTable(t) local r={} for k,v in pairs(t) do r[k]=type(v)=="table" and CopyTable(v) or v end return r end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
tinsert=table.insert
UISpecialFrames={}
UIParent=mockobj()
DEFAULT_CHAT_FRAME={AddMessage=function(_,m) print("CHAT: "..m) end}
LUA_ERRORS={}
function geterrorhandler() return function(e) print("ERR: "..tostring(e)) table.insert(LUA_ERRORS, tostring(e)) end end
PLAYER = {level=1, race="Human", class="WARRIOR", faction="Alliance", map=1429, x=0.482, y=0.429}
function UnitLevel() return PLAYER.level end
function UnitRace() return "Humain", PLAYER.race end
function UnitClass() return "Guerrier", PLAYER.class end
function UnitFactionGroup() return PLAYER.faction end
function UnitName() return "Tester" end
function IsShiftKeyDown() return false end
function GetBuildInfo() return "1.60.1","1","",16001 end
QLOG = {}  -- questID -> {complete=bool}
DONE = {}
C_QuestLog = {
  GetLogIndexForQuestID=function(q) return QLOG[q] and 1 or nil end,
  IsQuestFlaggedCompleted=function(q) return DONE[q]==true end,
  IsComplete=function(q) return QLOG[q] and QLOG[q].complete or false end,
  GetTitleForQuestID=function(q) return "Quest"..q end,
  RequestLoadQuestByID=function() end,
  GetQuestObjectives=function(q) return {{text="Kobold 3/10", finished=false}} end,
  GetNumQuestLogEntries=function() local n=0 for _ in pairs(QLOG) do n=n+1 end return n end,
  GetInfo=function(i) local n=0 for q,v in pairs(QLOG) do n=n+1 if n==i then return {questID=q,isHeader=false} end end end,
}
C_Map = {
  GetBestMapForUnit=function() return PLAYER.map end,
  GetPlayerMapPosition=function(m) if m~=PLAYER.map then return nil end return {GetXY=function() return PLAYER.x, PLAYER.y end} end,
  GetMapWorldSize=function() return 3500, 2300 end,
  GetMapInfo=function(m) if m==1429 then return {name="Forêt d'Elwynn", mapType=3} elseif m==1411 then return {name="Durotar", mapType=3} end end,
  -- monde simulé : continent 0, x = nord, y = ouest (yards)
  GetWorldPosFromMapPos=function(m, v)
    local t = WORLD[m]; if not t then return nil end
    local mx, my = v:GetXY()
    return t.c, CreateVector2D(t.ox - my * t.h, t.oy - mx * t.w)
  end,
  GetMapPosFromWorldPos=function(c, v, m)
    local t = WORLD[m]; if not t or t.c ~= c then return nil end
    local wx, wy = v:GetXY()
    return m, CreateVector2D((t.oy - wy) / t.w, (t.ox - wx) / t.h)
  end,
  CanSetUserWaypointOnMap=function() return true end,
  SetUserWaypoint=function(p) WAYPOINT=p end,
  HasUserWaypoint=function() return WAYPOINT~=nil end,
  ClearUserWaypoint=function() WAYPOINT=nil end,
}
UiMapPoint={CreateFromCoordinates=function(m,x,y) return {m=m,x=x,y=y} end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function() end}
TIMERS={}
C_Timer={After=function(_,fn) table.insert(TIMERS,fn) end, NewTicker=function(_,fn) TICK=fn end}
function RunTimers() local t=TIMERS TIMERS={} for _,fn in ipairs(t) do fn() end end
C_GossipInfo={}
SlashCmdList={}
'''
mocks = mocks.replace('return "frFR"', 'return "%s"' % (__import__("os").environ.get("FP_LOCALE") or "frFR"))
lua.execute(mocks)
toc = open(f"{ROOT}/Questweaver.toc", encoding="utf-8").read().splitlines()
lua.execute("C_GossipInfo={} SlashCmdList={}")
files = [l.strip().replace("\\","/") for l in toc if l.strip() and not l.startswith("#")]
lua.execute("NS = {}")
for fn in files:
    src = open(f"{ROOT}/{fn}", encoding="utf-8").read()
    chunk = lua.eval("function(src,name) local f,err=loadstring(src,'@'..name) if not f then error(err) end return f end")(src, fn)
    lua.eval("function(f) f('Questweaver', NS) end")(chunk)
print("Loaded", len(files), "files OK")
lua.execute(open(TEST, encoding="utf-8").read())
n_err = lua.eval("(function() return table.getn(LUA_ERRORS) - (tonumber(EXPECTED_ERRORS) or 0) end)")()
if n_err > 0:
    print(f"FAIL: {n_err} erreur(s) Lua inattendue(s) remontée(s) par l'addon")
    raise SystemExit(1)
