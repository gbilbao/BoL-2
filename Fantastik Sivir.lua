if myHero.charName ~= "Sivir" then return end

require "SOW"
if VIP_USER then
	require "VPrediction"
end

--[[		Auto Update		]]
local sversion = "0.2"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/BoLFantastik/BoL/master/Fantastik Sivir.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH.."Fantastik Sivir.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function _AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>SOW:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/BoLFantastik/BoL/master/version/Fantastik Sivir.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(sversion) < ServerVersion then
				_AutoupdaterMsg("New version available"..ServerVersion)
				_AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () _AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				_AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		_AutoupdaterMsg("Error downloading version info")
	end
end

--[[		Code		]]
local sauthor = "Fantastik"
local QREADY, WREADY, EREADY, RREADY = false
local Qrange, Qwidth, Qspeed, Qdelay = 1075, 85, 1350, 0.250
local Rrange = 1000
local ignite = nil
local iDmg = 0
local target = nil
local ts
local ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, Qrange, DAMAGE_PHYSICAL, true)

----------------------------------------------

function OnLoad()
	PrintChat("<font color=\"#00FF00\">Fantastik Sivir version ["..sversion.."] by Fantastik loaded.</font>")
	if _G.Evadeee_Loaded then
	PrintChat("<font color=\"##58D3F7\"><b>Evadeee</b> found! You can use Evadeee integration!")
	_G.Evadeee_Enabled = true
	end
  	IgniteCheck()
	SLoadLib()
end


function OnTick()
  	ts:update()
  	target = ts.target
  	Checks()
	
  if ValidTarget(target) then
		if SivMenu.Extra.KS then KS(target) end
		if SivMenu.Extra.Ignite then AutoIgnite(target) end
	end
	
   if SivMenu.combokey then
		Combo()
   end
   if SivMenu.pokekey then
		Poke()
   end
   if SivMenu.Extra.Evade then
       EvadeeeHelper()
   end
end

function Checks()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
  	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function IgniteCheck()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
			ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
			ignite = SUMMONER_2
	end
end

function OnDraw()
	if SivMenu.Drawing.DrawAA then
	 SOWi:DrawAARange()
	end
   
   if SivMenu.Drawing.DrawQ then
	 if QREADY then
	 DrawCircle(myHero.x, myHero.y, myHero.z, Qrange, 0xF7FE2E)
	 end
   end
end

function SLoadLib()
    VP = VPrediction(true)
    SOWi = SOW(VP)
	SMenu()
end

function SMenu()
	SivMenu = scriptConfig("Fantastik Sivir", "Sivir")
	SivMenu:addParam("combokey", "Combo key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	SivMenu:addParam("pokekey", "Poke key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	SivMenu:addParam("Version", "Version", SCRIPT_PARAM_INFO, sversion)
	SivMenu:addParam("Author", "Author", SCRIPT_PARAM_INFO, sauthor)
	SivMenu:addTS(ts)
	SivMenu:addSubMenu("Combo", "Combo")
--	SivMenu.Combo:addParam("combokey", "Combo key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	SivMenu.Combo:addParam("comboQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	SivMenu.Combo:addParam("comboW", "Use W", SCRIPT_PARAM_ONOFF, true)
	SivMenu.Combo:addParam("comboR", "Use R", SCRIPT_PARAM_ONOFF, true)
	SivMenu.Combo:addParam("minEnemiesR", "Min. no. of enemies for R", SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
	
	SivMenu:addSubMenu("Poke", "Poke")
--	SivMenu.Poke:addParam("pokekey", "Poke key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	SivMenu.Poke:addParam("pokeQ", "Use Q", SCRIPT_PARAM_ONOFF, true)	
	
	SivMenu:addSubMenu("Drawing", "Drawing")
	SivMenu.Drawing:addParam("DrawAA", "Draw AA Range", SCRIPT_PARAM_ONOFF, true)
	SivMenu.Drawing:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	
	SivMenu:addSubMenu("Orbwalker", "Orbwalker")
	SOWi:LoadToMenu(SivMenu.Orbwalker)
	
	SivMenu:addSubMenu("Extra", "Extra")
	SivMenu.Extra:addParam("AutoLev", "Auto level skill", SCRIPT_PARAM_ONOFF, false)
	SivMenu.Extra:addParam("KS", "Auto Killsteal", SCRIPT_PARAM_ONOFF, true)
	SivMenu.Extra:addParam("Ignite", "Use Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	if _G.Evadeee_Loaded then
		SivMenu.Extra:addParam("Evade", "Use Evadeee Integration", SCRIPT_PARAM_ONOFF, true)
	end
	SivMenu:permaShow("combokey")
	SivMenu:permaShow("pokekey")
end

function KS(Target)
	if QREADY and getDmg("Q", Target, myHero) > Target.health then
		local CastPos = VP:GetLineCastPosition(Target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
		if GetDistance(Target) <= Qrange and QREADY then
		CastSpell(_Q, CastPos.x, CastPos.z)
		end
	end
end
  
function AutoIgnite(enemy)
  	iDmg = ((IREADY and getDmg("IGNITE", enemy, myHero)) or 0) 
	if enemy.health <= iDmg and GetDistance(enemy) <= 600 and ignite ~= nil
		then
			if IREADY then CastSpell(ignite, enemy) end
	end
end

function EvadeeeHelper()
	if _G.Evadeee_impossibleToEvade then
		CastSpell(_E)
	end
end

function Combo()
  if ValidTarget(target) then
		if QREADY and SivMenu.Combo.comboQ then
        if VIP_USER then
			local CastPos = VP:GetLineCastPosition(target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
			if GetDistance(target) <= Qrange and QREADY then
				CastSpell(_Q, CastPos.x, CastPos.z)
			end
        else
        CastSpell(_Q, target.x, target.z)
        end
	end
	if WREADY and SivMenu.Combo.comboW and GetDistance(target) <= 600 then
		CastSpell(_W)
	end
	if RREADY and SivMenu.Combo.comboR and GetDistance(target) <= 600 then
		CastR()
	end
  end
end

function Poke()
  if ValidTarget(target) then
		if SivMenu.Poke.pokeQ and QREADY
    	then
        if VIP_USER then
		 local CastPos = VP:GetLineCastPosition(target, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
		 if GetDistance(target) <= Qrange and QREADY then
		  CastSpell(_Q, CastPos.x, CastPos.z)
		 end
       else
        CastSpell(_Q, target.x, target.z)
       end
	end
   end
end

function CastR()
	if SivMenu.Combo.minEnemiesR <= CountEnemyHeroInRange(600) then
		CastSpell(_R)
	end
end
