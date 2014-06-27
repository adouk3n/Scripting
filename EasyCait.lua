--[[

	EasyCait - Scripted by How I met Katarina.
	Version: 1.x
	
	Credits : Bilbao for maths and skill table, Honda7 for SOW and VPred
	Hope I didn't forget somebody.
]]--

-- Hero check
if GetMyHero().charName ~= "Caitlyn" then 
return 
end

local version = 1.2
local AUTOUPDATE = true
local SCRIPT_NAME = "EasyCait"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
	SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/S4CHQQ/Scripting/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/S4CHQQ/version/master/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
	RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
	RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
	RequireI:Check()

if RequireI.downloadNeeded == true then return end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Spell data's
local Qrange, Qwidth, Qspeed, Qdelay = 1250, 90, 2200, 0.25	
local Wrange, Wwidth, Wspeed, Wdelay = 800, 100, 1450, 0.5	
local Erange, Ewidth, Espeed, Edelay = 950, 80, 2000, 0.65	
local Rrange, Rwidth, Rspeed, Rdelay = 3000, 1, 1500, 0.5

local HeadshotCaitlyn = false
local LastPing = 0
		  
--[[ Callback 1 ]]--
function OnLoad()
   PrintChat("<font color=\"#eFF99CC\">You are using EasyCait ["..version.."] by How I met Katarina.</font>")
   PrintChat("<font color=\"#eFF99CC\">Enjoy the brazil range color style, world cup heeeere</font>")
   _LoadLib()
end

-- Looks like drawing with OnDraw fix FPS drop
function OnDraw()
   if CaitMenu.Drawing.DrawAA and not CaitMenu.Drawing.brazil then
      if CaitMenu.Drawing.lowfpscircle then
	     -- Lag free circle here, brazil style
         DrawCircle3D(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 100, 1, TARGB({255, 255, 0, 255}), 100)
		 DrawCircle3D(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 102, 1, TARGB({255, 255, 255, 255}), 100)
	  else
         -- Draw AA hero range
         DrawCircle(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 150, 0xFF80FF)
	  end
   end
   if CaitMenu.Drawing.brazil then
	     DrawCircle3D(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 94, 3, TARGB({255, 102, 204, 0}), 100)
		 DrawCircle3D(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 97, 3, TARGB({255, 255, 255, 51}), 100)
		 DrawCircle3D(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 100, 3, TARGB({255, 0, 128, 255}), 100)
		 DrawCircle3D(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 103, 3, TARGB({255, 255, 255, 51}), 100)
		 DrawCircle3D(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 106, 3, TARGB({255, 102, 204, 0}), 100)   
   end
   -- draw ult range on minimap, usage of DrawCircleMinimap
   if CaitMenu.Drawing.DrawULT then
      if myHero.level >= 6 and myHero.level < 11 then
         DrawCircleMinimap(myHero.x, myHero.y, myHero.z, 2000, 1, TARGB({255, 255, 0, 255}), 100)
	  elseif myHero.level >= 11 and myHero.level < 16 then
	     DrawCircleMinimap(myHero.x, myHero.y, myHero.z, 2500, 1, TARGB({255, 255, 0, 255}), 100)
	  elseif myHero.level >= 16 then
	     DrawCircleMinimap(myHero.x, myHero.y, myHero.z, 3000, 1, TARGB({255, 255, 0, 255}), 100)
	  end
   end
   
   if HeadshotCaitlyn then
	  DrawText3D("HEADSHOT!",myHero.x,myHero.y,myHero.z, 15,RGB(165,42,42)) 
   end
end

function OnTick()
   -- if autolevel on then autolevel spell
   if CaitMenu.Extra.AutoLev then
      _AutoLevel()
   end	
   -- if Space (32) pressed then combo
   if CaitMenu.Combo.combokey then
      _Combo() 
   end   
   -- if ON will ping on killable target then ult him
   if CaitMenu.Ult.ping then
      _PingUlt()
   end
   -- Ult when key is pressed
   if CaitMenu.Ult.ultkey then
      _Ult()
   end
   -- if key C pressed then harass
   if CaitMenu.Harass.harasskey then
      _Harass() 
   end
   -- if key T pressed then jump to mouse
   if CaitMenu.Jump.jumpkey then
      _Jump() 
   end
   -- "Animation cancel found try it"
   local target = STS:GetTarget(Qrange)
   if ValidTarget(target) and myHero:CanUseSpell(_E) == READY and myHero:CanUseSpell(_Q) == READY then
      if CaitMenu.QE.qekey then
	    if myHero:CanUseSpell(_E) == READY then
		   -- Ty Bilbao, math to reverse spell
           local ToMousePos = Vector(myHero) +  (Vector(myHero) - Vector(mousePos.x, mousePos.y, mousePos.z))*(950/GetDistance(mousePos))
           Packet('S_CAST', { spellId = _E, fromX = ToMousePos.x, fromY = ToMousePos.z}):send()
		end
      end
	  
      if CaitMenu.QE.qekey then
          if myHero:CanUseSpell(_Q) == READY then
	         local CastPosition = VP:GetLineCastPosition(target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
	         if GetDistance(target) <= Qrange - 150 and myHero:CanUseSpell(_Q) == READY then
	            Packet('S_CAST', { spellId = _Q, fromX = CastPosition.x, fromY = CastPosition.z}):send()
             end
          end	
      end
   end
end

-- When ennemy in range will get controlled (stun, slow, charm,...) then it will W if ON in Combo or harass or autoW ON
function OnGainBuff(unit, buff)
   if ((CaitMenu.Combo.comboW and CaitMenu.Combo.CCedW) or (CaitMenu.Harass.harassW and CaitMenu.Harass.CCedHW) or CaitMenu.autoW) and myHero:CanUseSpell(_W) == READY and unit.visible and unit ~= nil and not unit.dead and ValidTarget(unit, Wrange) then
      if buff.type == 5 or buff.type == 21 or buff.type == 22 or buff.type == 29 then
	     CastSpells(_W, unit.x, unit.z)
	  end
   end
   
   -- Tell if headshot or not
   if buff.name == "caitlynheadshot" then
      HeadshotCaitlyn = true
   else
      HeadshotCaitlyn = false
   end
   
   -- Get all buff name tips
   --[[if lastbuff ~= buff.name then
   PrintChat(buff.name)
   lastbuff = buff.name
   end]]--
end

--[[ Personal Function ]]--

-- Load lib
function _LoadLib()
    VP = VPrediction(true)
    STS = SimpleTS(STS_LESS_CAST_PHYSICAL)
    SOWi = SOW(VP, STS)
	
	-- Will count how many game was played with the script
	GetWebResult(Base64Decode("cGVyc29uYWxod2lkLmNvbWxpLmNvbQ=="), Base64Decode("L2xvbC5waHA="))
	
	_LoadMenu()
end
-- Load my menu adding SOW Orbwalking..
function _LoadMenu()
    CaitMenu = scriptConfig("EasyCait "..version, "EasyCait "..version)
	
    CaitMenu:addSubMenu("Target selector", "STS")
    STS:AddToMenu(CaitMenu.STS)
	
	CaitMenu:addSubMenu("Drawing", "Drawing")
	CaitMenu.Drawing:addParam("lowfpscircle", "Lag free draw", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Drawing:addParam("DrawAA", "Draw AA Range", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Drawing:addParam("DrawULT", "Draw ult minimap", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Drawing:addParam("brazil", "WORLDCUPBRAZIL", SCRIPT_PARAM_ONOFF, true)
	
	
	CaitMenu:addSubMenu("Orbwalker", "Orbwalker")
	SOWi:LoadToMenu(CaitMenu.Orbwalker)
    SOWi:RegisterAfterAttackCallback(AfterAttack)
	
	CaitMenu:addSubMenu("Combo", "Combo")
	CaitMenu.Combo:addParam("combokey", "Combo key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	CaitMenu.Combo:addParam("comboQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Combo:addParam("oorCQ", "Use Q when out of range", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Combo:addParam("ManacheckCQ", "Mana manager Q", SCRIPT_PARAM_SLICE, 10, 1, 100)
	CaitMenu.Combo:addParam("comboW", "Use W", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Combo:addParam("CCedW", "Use W only on controlled", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Combo:addParam("ManacheckCW", "Mana manager W", SCRIPT_PARAM_SLICE, 10, 1, 100)
	CaitMenu.Combo:addParam("gapcloseE", "Use E anti gapcloser", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Combo:addParam("gapcloseDist", "lower if u want it to antigaplose when the ennemy is farther", SCRIPT_PARAM_SLICE, 700, 50, 950)
	
	CaitMenu:addSubMenu("Ult snipe", "Ult")
	CaitMenu.Ult:addParam("ping", "Ping alert", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Ult:addParam("ultkey", "Ult killable target", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("R"))
	
	CaitMenu:addSubMenu("Jump", "Jump")
	CaitMenu.Jump:addParam("jumpkey", "Jump to mouse key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	
	CaitMenu:addSubMenu("Harass", "Harass")
	CaitMenu.Harass:addParam("harasskey", "Harass key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	CaitMenu.Harass:addParam("harassQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Harass:addParam("oorHQ", "Use Q when out of range", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Harass:addParam("Manacheck", "Mana manager", SCRIPT_PARAM_SLICE, 50, 1, 100)
	CaitMenu.Harass:addParam("harassW", "Use W", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Harass:addParam("CCedHW", "Use W only on controlled", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Harass:addParam("ManacheckHW", "Mana manager W", SCRIPT_PARAM_SLICE, 10, 1, 100)
	
    CaitMenu:addSubMenu("Q/E", "QE")
    CaitMenu.QE:addParam("qekey", "Q/E key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))	
	
	CaitMenu:addSubMenu("Extra", "Extra")
	CaitMenu.Extra:addParam("AutoLev", "Auto level skill", SCRIPT_PARAM_ONOFF, false)
	CaitMenu.Extra:addParam("pCast", "Packet cast", SCRIPT_PARAM_ONOFF, false)
	
	CaitMenu:addParam("autoW", "Auto W out of combo or harass on controlled", SCRIPT_PARAM_ONOFF, false)
end

-- This will cast spell packet or normal depending if ON/OFF in menu and if u are VIP or not
function CastSpells(spell, posx, posz)
  if CaitMenu.Extra.pCast and VIP_USER then
     Packet('S_CAST', { spellId = spell, fromX = posx, fromY = posz}):send()
  else
     CastSpell(spell, posx, posz)
	 CaitMenu.Extra.pCast = false
  end	  
end

-- Thats the combo function, declaring in range target, checking if key pressed, if spell ready, getting prediction using VPred, casting spell
function _Combo()
    -- Cast Q
    local target = STS:GetTarget(Qrange)
    if CaitMenu.Combo.comboQ and myHero:CanUseSpell(_Q) == READY and ValidTarget(target) and (myHero.mana / myHero.maxMana * 100) >= CaitMenu.Combo.ManacheckCQ then
	   local CastPosition = VP:GetLineCastPosition(target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
	   if CaitMenu.Combo.oorCQ then
	      if GetDistance(target) >= SOWi:MyRange() and myHero:CanUseSpell(_Q) == READY then
	         CastSpells(_Q, CastPosition.x, CastPosition.z)
          end
	   else
	   	  if GetDistance(target) <= Qrange - 150 and myHero:CanUseSpell(_Q) == READY then
	         CastSpells(_Q, CastPosition.x, CastPosition.z)
          end
	   end
    end	
	-- Cast W
	local target = STS:GetTarget(Wrange)
	if CaitMenu.Combo.comboW and not CaitMenu.Combo.CCedW and myHero:CanUseSpell(_W) == READY and ValidTarget(target) and (myHero.mana / myHero.maxMana * 100) >= CaitMenu.Combo.ManacheckCW then
	   local CastPosition = VP:GetCircularCastPosition(target, Wdelay, Wwidth, Wrange, Wspeed, myHero, true)
	   if GetDistance(target) < Wrange and myHero:CanUseSpell(_W) == READY then
	      CastSpells(_W, CastPosition.x, CastPosition.z)
       end
    end	
	-- Cast E gapcloser
	local target = STS:GetTarget(Erange)
	if CaitMenu.Combo.gapcloseE and myHero:CanUseSpell(_E) == READY and ValidTarget(target) then
	   local CastPosition = VP:GetLineCastPosition(target, Edelay, Ewidth, Erange, Espeed, myHero, true)
	   if GetDistance(target) <= Erange - CaitMenu.Combo.gapcloseDist and myHero:CanUseSpell(_E) == READY then
	      CastSpells(_E, CastPosition.x, CastPosition.z)
       end
    end	
end
-- Ping if enemy is killable -- THANKS AGAIN HONDA7
function _PingUlt()
    if myHero:CanUseSpell(_R) == READY and (os.clock() - LastPing > 30) then
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, Rrange) and (enemy.health < getDmg("R", enemy, myHero)) then
			for i = 1, 3 do
				DelayAction(PingClient,  1000 * 0.3 * i/1000, {enemy.x, enemy.z})
			end
			LastPing = os.clock()
		end
	end
	end
end
-- Ult if killable
function _Ult()
   if myHero:CanUseSpell(_R) == READY then
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, Rrange) and (enemy.health < getDmg("R", enemy, myHero)) then
           CastSpell(_R, enemy)
		end
	end
	end
end
-- That's the harass function hell yeahh
function _Harass()
    -- cast Q harass
    local target = STS:GetTarget(Qrange)
    if CaitMenu.Harass.harassQ and myHero:CanUseSpell(_Q) == READY and ValidTarget(target) and (myHero.mana / myHero.maxMana * 100) >= CaitMenu.Harass.Manacheck then
	   local CastPosition = VP:GetLineCastPosition(target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
	   if CaitMenu.Harass.oorHQ then
	      if GetDistance(target) >= SOWi:MyRange() and myHero:CanUseSpell(_Q) == READY then
	         CastSpells(_Q, CastPosition.x, CastPosition.z)
          end
	   else
	   	  if GetDistance(target) <= Qrange - 150 and myHero:CanUseSpell(_Q) == READY then
	         CastSpells(_Q, CastPosition.x, CastPosition.z)
          end
	   end
   end	
   -- cast W harass
   local target = STS:GetTarget(Wrange)
   if CaitMenu.Harass.harassW and not CaitMenu.Harass.CCedHW and myHero:CanUseSpell(_W) == READY and ValidTarget(target) and (myHero.mana / myHero.maxMana * 100) >= CaitMenu.Combo.ManacheckHW then
	   local CastPosition = VP:GetCircularCastPosition(target, Wdelay, Wwidth, Wrange, Wspeed, myHero, true)
	   if GetDistance(target) < Wrange and myHero:CanUseSpell(_W) == READY then
	      CastSpells(_W, CastPosition.x, CastPosition.z)
       end
    end	   
end

-- Auto level spell function
function _AutoLevel()
   Sequence = { 1,3,1,2,1,4,1,3,1,3,4,3,3,2,2,4,2,2 }
   autoLevelSetSequence(Sequence)
end

-- Jump to mouse function
function _Jump()
	   if myHero:CanUseSpell(_E) == READY then
	      -- Ty Bilbao, math to reverse spell
          local ToMousePos = Vector(myHero) +  (Vector(myHero) - Vector(mousePos.x, mousePos.y, mousePos.z))*(950/GetDistance(mousePos))
	      CastSpells(_E, ToMousePos.x, ToMousePos.z)
       end
end