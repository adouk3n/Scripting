--[[

	EasyCait - Scripted by How I met Katarina.
	Version: 0.02
	
	Credits : Bilbao for maths and skill table, Honda7 for SOW and VPred
	Hope I didn't forget somebody.
]]--

-- Hero check
if GetMyHero().charName ~= "Caitlyn" then 
return 
end

-- Required lib
require "SOW"
require "VPrediction"
require "SourceLib"

-- My script version
local pVersion = "0.02"

-- Are spell ready?
local QREADY = (myHero:CanUseSpell(_Q) == READY)
local WREADY = (myHero:CanUseSpell(_W) == READY)
local EREADY = (myHero:CanUseSpell(_E) == READY)
local RREADY = (myHero:CanUseSpell(_R) == READY)

-- Spell info's in order to get prediction
local Qrange, Qwidth, Qspeed, Qdelay = 1250, 90, 2200, 0.25	
local Wrange, Wwidth, Wspeed, Wdelay = 800, 100, 1450, 0.5	
local Erange, Ewidth, Espeed, Edelay = 950, 80, 2000, 0.65	
local Rrange, Rwidth, Rspeed, Rdelay = 3000, 1, 1500, 0.5

--[[ Callback 1 ]]--
function OnLoad()
   PrintChat("<font color=\"#eFF99CC\">You are using EasyCait ["..pVersion.."] by How I met Katarina.</font>")
   _LoadLib()
end

function OnDraw()
   if CaitMenu.Drawing.DrawAA then
      -- Draw AA hero range
      DrawCircle(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 150, 0xFF80FF)
   end
   if CaitMenu.Drawing.DrawULT then
      if myHero.level >= 6 and myHero.level < 11 then
         DrawCircleMinimap(myHero.x, myHero.y, myHero.z, 2000, 1, TARGB({255, 255, 0, 255}), 100)
	  elseif myHero.level >= 11 and myHero.level < 16 then
	     DrawCircleMinimap(myHero.x, myHero.y, myHero.z, 2500, 1, TARGB({255, 255, 0, 255}), 100)
	  elseif myHero.level >= 16 then
	     DrawCircleMinimap(myHero.x, myHero.y, myHero.z, 3000, 1, TARGB({255, 255, 0, 255}), 100)
	  end
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
   -- if key C pressed then harass
   if CaitMenu.Harass.harasskey then
      _Harass() 
   end
   if CaitMenu.Jump.jumpkey then
      _Jump() 
   end
end



--[[ Personal Function ]]--

-- Load lib
function _LoadLib()
    VP = VPrediction(true)
    STS = SimpleTS(STS_LESS_CAST_PHYSICAL)
    SOWi = SOW(VP, STS)
	
	_LoadMenu()
end
-- Load my menu adding SOW Orbwalking..
function _LoadMenu()
    CaitMenu = scriptConfig("EasyCait "..pVersion, "EasyCait "..pVersion)
	
    CaitMenu:addSubMenu("Target selector", "STS")
    STS:AddToMenu(CaitMenu.STS)
	
	CaitMenu:addSubMenu("Drawing", "Drawing")
	CaitMenu.Drawing:addParam("DrawAA", "Draw AA Range", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Drawing:addParam("DrawULT", "Draw ult minimap", SCRIPT_PARAM_ONOFF, true)
	
	CaitMenu:addSubMenu("Orbwalker", "Orbwalker")
	SOWi:LoadToMenu(CaitMenu.Orbwalker)
    SOWi:RegisterAfterAttackCallback(AfterAttack)
	
	CaitMenu:addSubMenu("Combo", "Combo")
	CaitMenu.Combo:addParam("combokey", "Combo key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	CaitMenu.Combo:addParam("comboQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Combo:addParam("gapcloseE", "Use E anti gapcloser", SCRIPT_PARAM_ONOFF, true)
	CaitMenu.Combo:addParam("gapcloseDist", "lower if u want it to antigaplose when the ennemy is farther", SCRIPT_PARAM_SLICE, 700, 50, 950)
	
	CaitMenu:addSubMenu("Jump", "Jump")
	CaitMenu.Jump:addParam("jumpkey", "Jump to mouse key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	
	CaitMenu:addSubMenu("Harass", "Harass")
	CaitMenu.Harass:addParam("harasskey", "Harass key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	CaitMenu.Harass:addParam("harassQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	
	CaitMenu:addSubMenu("Extra", "Extra")
	CaitMenu.Extra:addParam("AutoLev", "Auto level skill", SCRIPT_PARAM_ONOFF, false)
end

-- Thats the combo function, declaring in range target, checking if key pressed, if spell ready, getting prediction using VPred, casting spell
function _Combo()
    local target = STS:GetTarget(Qrange)
    if CaitMenu.Combo.comboQ and QREADY and target ~= nil then
	   local CastPosition = VP:GetLineCastPosition(target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
	   if GetDistance(target) <= Qrange - 150 and QREADY then
	      CastSpell(_Q, CastPosition.x, CastPosition.z)
       end
    end	
	local target = STS:GetTarget(Erange)
	if CaitMenu.Combo.gapcloseE and EREADY and target ~= nil then
	   local CastPosition = VP:GetLineCastPosition(target, Edelay, Ewidth, Erange, Espeed, myHero, true)
	   if GetDistance(target) <= Erange - CaitMenu.Combo.gapcloseDist and EREADY then
	      CastSpell(_E, CastPosition.x, CastPosition.z)
       end
    end	
end

-- That's the harass function hell yeahh
function _Harass()
    local target = STS:GetTarget(Qrange)
    if CaitMenu.Harass.harassQ and QREADY and target ~= nil then
	   local CastPosition = VP:GetLineCastPosition(target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
	   if GetDistance(target) <= Qrange - 150 and QREADY then
	      CastSpell(_Q, CastPosition.x, CastPosition.z)
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
	   if EREADY then
	      -- Ty Bilbao, math to reverse spell
	      local ToMousePos = Vector(myHero) +  (Vector(myHero) - Vector(mousePos.x, mousePos.y, mousePos.z))*(950/GetDistance(mousePos))
	      CastSpell(_E, ToMousePos.x, ToMousePos.z)
       end
end