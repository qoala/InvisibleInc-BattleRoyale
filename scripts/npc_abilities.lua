local util = include( "modules/util" )
local mainframe_common = include("sim/abilities/mainframe_common")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

local createDaemon = mainframe_common.createDaemon

-- ===

-- Copy of Brain:spawnInterest. Changes at -- BACKSTAB.
local function spawnInterest(unit, x, y, sense, reason, sourceUnit)
	local senses = unit:getBrain():getSenses()
	local interest = senses:addInterest(x, y, sense, reason, sourceUnit)
	if interest then
		interest.remember = true
		-- BACKSTAB: Set grenadeHit if there's an existing grenadeHit interest on this tile.
        --  So that the start-of-turn locator doesn't cause an enforcer to re-throw a grenade.
		for _,other in ipairs(senses.interests) do
			if other.grenadeHit and x == other.x and y == other.y then
				interest.grenadeHit = true
				break
			end
		end
		-- BACKSTAB: always draw these interests
		interest.alwaysDraw = true
	end
	unit:getSim():processReactions(unit)
end

local function chaseCell(sim, x, y, agent)
	local closestGuard = simquery.findClosestUnit(sim:getNPC():getUnits(), x, y,
		function(guard)
			return (guard:getBrain() and not guard:isKO()
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_COMBAT
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_FLEE)
		end)
	if closestGuard then
		spawnInterest(closestGuard, x, y, simdefs.SENSE_RADIO, simdefs.REASON_CAMERA, agent)
	end
end
local function chaseAgent(sim, agent)
	local x,y = agent:getLocation()
	return chaseCell(sim, x, y, agent)
end

local function huntCell(sim, x, y, agent, hunters)
	hunters = hunters or {}
	local closestGuard = simquery.findClosestUnit(sim:getNPC():getUnits(), x, y,
		function(guard)
			return (guard:getBrain() and not guard:isKO()
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_COMBAT
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_FLEE
				and not hunters[guard:getID()])
		end)
	if closestGuard then
		hunters[closestGuard:getID()] = agent
		spawnInterest(closestGuard, x, y, simdefs.SENSE_RADIO, simdefs.REASON_HUNTING, agent)
    end
end
local function huntAgent(sim, agent, hunters)
	local x,y = agent:getLocation()
	return huntCell(sim, x, y, agent, hunters)
end

-- ===

local function isPlayerAgent(unit)
	return unit and unit:isPC() and simquery.isAgent(unit) and unit:getLocation() and not unit:getTraits().takenDrone
end

local function royaleFlushApplyPenalties(sim, unit, penalties, hunters)
	local uiTxt = nil
	if penalties.mp and penalties.mp > 0 then
		local mp = unit:getTraits().mp
		local cappedPenalty = mp - math.max(mp - penalties.mp, 4)
		unit:addMP(-cappedPenalty)
		if not penalties.noSprint then
			-- Adjust max MP to avoid blocking the sprint ability
			unit:addMPMax(-cappedPenalty)
			unit:getTraits().backstab_mpMaxPenalty = cappedPenalty
		end
		sim:dispatchEvent( simdefs.EV_HUD_MPUSED, unit )
		uiTxt = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.SLOW_EFFECT
	end
	if penalties.disarm and unit:hasTrait("ap") and unit:getTraits().ap > 0 then
		unit:getTraits().ap = 0

		uiTxt = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.DISARM_EFFECT
	end

	if uiTxt then
		local x,y = unit:getLocation()
		sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT,{txt=uiTxt,x=x,y=y,unit=unit,color={r=1/2,g=1,b=1,a=1}})
	end

	-- No point in locating dead/pinned agents. KOed agents without a chaperone are fair game.
	if penalties.locate and penalties.locate ~= "end" and not unit:isNeutralized() then
		huntAgent(sim, unit, hunters)
	end
end

local function royaleFlushUnitStartTurn(sim, unit, hunters)
	if not isPlayerAgent(unit) then
		return
	end
	if unit:getTraits().backstab_mpMaxPenalty then
		unit:addMP(unit:getTraits().backstab_mpMaxPenalty)
		unit:addMPMax(unit:getTraits().backstab_mpMaxPenalty)
		unit:getTraits().backstab_mpMaxPenalty = nil
	end

	local x,y = unit:getLocation()
	local cell = sim:getCell(x, y)
	local simRoom = sim._mutableRooms[cell.procgenRoom.roomIndex]
	if not simRoom or not simRoom.backstabState then
		return
	elseif simRoom.backstabState == 0 then
		royaleFlushApplyPenalties(sim, unit, sim:getParams().difficultyOptions.backstab_redPenalties, hunters)
	elseif simRoom.backstabState == 1 then
		royaleFlushApplyPenalties(sim, unit, sim:getParams().difficultyOptions.backstab_yellowPenalties, hunters)
	end
end

local function royaleFlushUnitEndTurn(sim, unit, hunters)
	if not isPlayerAgent(unit) then
		return
	end
	local penalties = sim:getParams().difficultyOptions.backstab_redPenalties
	if penalties.locate ~= "end" then
	    return
	end

	local x,y = unit:getLocation()
	local cell = sim:getCell(x, y)
	local simRoom = sim._mutableRooms[cell.procgenRoom.roomIndex]
	if not simRoom or not simRoom.backstabState then
		return
	elseif simRoom.backstabState == 0 then
		if penalties.locate == "end" and not unit:isNeutralized() then
			huntAgent(sim, unit, hunters)
		end
	end
end

local function pickNearestDoorCell(unit, doorCell1, doorCell2)
	local x,y = unit:getLocation()
	if doorCell1.x == doorCell2.x then
		if doorCell1.y > doorCell2.y then
			if y >= doorCell1.y then
				return doorCell1
			else
				return doorCell2
			end
		else
			if y >= doorCell2.y then
				return doorCell2
			else
				return doorCell1
			end
		end
	else
		if doorCell1.x > doorCell2.x then
			if x >= doorCell1.x then
				return doorCell1
			else
				return doorCell2
			end
		else
			if x >= doorCell2.x then
				return doorCell2
			else
				return doorCell1
			end
		end
	end
end

local function royaleFlushDoor(sim, unit, doorCell1, doorCell2)
	if not isPlayerAgent(unit) then
		return
	end

	local doorCell = pickNearestDoorCell(unit, doorCell1, doorCell2)
	local simRoom = sim._mutableRooms[doorCell.procgenRoom.roomIndex]
	local penalties
	if not simRoom or not simRoom.backstabState then
		return
	elseif simRoom.backstabState == 0 then
		penalties = sim:getParams().difficultyOptions.backstab_redPenalties
	elseif simRoom.backstabState == 1 then
		penalties = sim:getParams().difficultyOptions.backstab_yellowPenalties
	end

	if penalties.doorAlarm == "a" then
		huntAgent(sim, unit)
	elseif penalties.doorAlarm == "n" then
		chaseAgent(sim, unit)
	end
end
local function royaleFlushSafe(sim, unit, safeUnit)
	if not isPlayerAgent(unit) then
		return
	end

	local sx,sy = safeUnit:getLocation()
	if not sx then
		return
	end
	local safeCell = sim:getCell(sx, sy)
	local simRoom = sim._mutableRooms[safeCell.procgenRoom.roomIndex]
	local penalties
	if not simRoom or not simRoom.backstabState then
		return
	elseif simRoom.backstabState == 0 then
		penalties = sim:getParams().difficultyOptions.backstab_redPenalties
	elseif simRoom.backstabState == 1 then
		penalties = sim:getParams().difficultyOptions.backstab_yellowPenalties
	end

	if penalties.safeAlarm == "a" then
		huntAgent(sim, unit)
	elseif penalties.safeAlarm == "n" then
		chaseAgent(sim, unit)
	end
end

local function triggeredPenaltiesDesc(doors, safes, attacks, alerting)
	local strings = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH
	local trigger
	if doors then
		if safes then
			if attacks then
				trigger = strings.ZONE_ALARM_TRIGGER.DOOR_SAFE_ATTACK
			else
				trigger = strings.ZONE_ALARM_TRIGGER.DOOR_SAFE
			end
		else
			if attacks then
				trigger = strings.ZONE_ALARM_TRIGGER.DOOR_ATTACK
			else
				trigger = strings.ZONE_ALARM_TRIGGER.DOOR
			end
		end
	else
		if safes then
			if attacks then
				trigger = strings.ZONE_ALARM_TRIGGER.SAFE_ATTACK
			else
				trigger = strings.ZONE_ALARM_TRIGGER.SAFE
			end
		else
			if attacks then
				trigger = strings.ZONE_ALARM_TRIGGER.ATTACK
			else
				return nil
			end
		end
	end

	local effect = alerting and strings.ZONE_ALARM_EFFECT.ALERT or strings.ZONE_ALARM_EFFECT.NOTIFY 

	return util.sformat(strings.ZONE_ALARM_TEMPLATE, trigger, effect)
end

local function royaleFlushZoneDesc(penalties)
	local strings = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH

	local descs = {}
	local desc

	desc = triggeredPenaltiesDesc(penalties.doorAlarm == "n", penalties.safeAlarm == "n", penalties.attackAlarm == "n", false)
	if desc then
		table.insert(descs, desc)
	end
	desc = triggeredPenaltiesDesc(penalties.doorAlarm == "a", penalties.safeAlarm == "a", penalties.attackAlarm == "a", true)
	if desc then
		table.insert(descs, desc)
	end

	if penalties.disarm then
		desc = util.sformat(strings.ZONE_DISARM_DESC, penalties.mp) .. " "
	elseif penalties.mp and penalties.mp > 0 then
		desc = util.sformat(strings.ZONE_SLOW_DESC, penalties.mp) .. " "
	else
		-- No other per-turn penalties
		if penalties.locate == "end" then
			table.insert(descs, strings.ZONE_LOCATEENDONLY_DESC)
		elseif penalties.locate then
			table.insert(descs, strings.ZONE_LOCATEONLY_DESC)
		elseif #descs == 0 then
			-- No penalties found
			return {strings.ZONE_WARNING_DESC}
		end
		return descs
	end

	-- Per-turn penalties, and...
	if penalties.locate == "end" then
		desc = desc .. strings.ZONE_LOCATEEND_DESC
		table.insert(descs, desc)
	elseif penalties.locate then
		desc = desc .. strings.ZONE_LOCATE_DESC
		table.insert(descs, desc)
	else
		table.insert(descs, desc)
	end
	return descs
end

local function updateLegacyParams(difficultyOptions)
	if difficultyOptions.backstab_redZoneMP and not difficultyOptions.backstab_redPenalties then
		difficultyOptions.backstab_yellowPenalties =
		{
			mp = difficultyOptions.backstab_yellowZoneMP,
			noSprint = difficultyOptions.backstab_yellowZoneNoSprint,
			disarm = difficultyOptions.backstab_yellowZoneDisarm,
			locate = false
		}
		difficultyOptions.backstab_redPenalties =
		{
			mp = difficultyOptions.backstab_redZoneMP,
			noSprint = difficultyOptions.backstab_redZoneNoSprint,
			disarm = difficultyOptions.backstab_redZoneDisarm,
			locate = difficultyOptions.backstab_redZoneLocate,
		}
	end
end

-- ===

local npc_abilities =
{
	backstab_royaleFlush = util.extend(createDaemon(STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH))
	{
		icon = "gui/icons/programs_icons/ProgramAces.png",
		standardDaemon = false,
		reverseDaemon = false,
		permanent = true,
		noDaemonReversal = true,

		ENDLESS_DAEMONS = false,
		PROGRAM_LIST = false,
		OMNI_PROGRAM_LIST_EASY = false,
		OMNI_PROGRAM_LIST = false,
		REVERSE_DAEMONS = false,

		onSpawnAbility = function( self, sim, player )
			updateLegacyParams(sim:getParams().difficultyOptions)
			local stabOptions = sim:getParams().difficultyOptions.backstab_stab or {}
			self._reverseZones = stabOptions.reverseZones

			self.turns = sim:backstab_turnsUntilNextZone()

			sim:addTrigger( simdefs.TRG_START_TURN, self )
			sim:addTrigger( simdefs.TRG_END_TURN, self )
			sim:addTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:addTrigger( simdefs.TRG_SAFE_LOOTED, self )
		end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
			sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:removeTrigger( simdefs.TRG_SAFE_LOOTED, self )
		end,

		onTrigger = function( self, sim, evType, evData, userUnit )
			if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
				local hunters = {}
				for _,unit in ipairs(sim:getPC():getUnits()) do
					royaleFlushUnitStartTurn(sim, unit, hunters)
				end

				if self._reverseZones and sim:backstab_isBackstabComplete() then
					simlog("LOG_BACKSTAB", "BACKSTAB COMPLETE")
					sim:backstab_reverse(self._reverseZones)
					self._reverseZones = false

					self.turns = sim:backstab_turnsUntilNextZone(0)
					sim:dispatchEvent( simdefs.EV_HUD_REFRESH, {} )

					local daemonStrings = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH
					sim:dispatchEvent( simdefs.EV_SHOW_REVERSE_DAEMON, { name = daemonStrings.REVERSE_NAME, icon=self.icon, txt = daemonStrings.REVERSE_DESC } )
				end


				if sim:backstab_advanceZones() then
					self.turns = 0
					sim:dispatchEvent( simdefs.EV_HUD_REFRESH, {} )

					local nextTurns = sim:backstab_turnsUntilNextZone(0)
					local txt = nextTurns and util.sformat(self.activedesc, nextTurns) or STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.FINISHED_DESC
					sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = txt } )
					self.turns = nextTurns
				else
					self.turns = sim:backstab_turnsUntilNextZone(0)
				end
			elseif evType == simdefs.TRG_END_TURN and sim:getCurrentPlayer():isPC() then
				local hunters = {}
				for _,unit in ipairs(sim:getPC():getUnits()) do
					royaleFlushUnitEndTurn(sim, unit, hunters)
				end
			elseif evType == simdefs.TRG_UNIT_USEDOOR and sim:getCurrentPlayer():isPC() and evData.unit and evData.unit:isPC() then
				royaleFlushDoor(sim, evData.unit, evData.cell, evData.tocell)
			elseif evType == simdefs.TRG_SAFE_LOOTED and evData.targetUnit:getTraits().safeUnit and evData.unit and evData.unit:isPC() then
				royaleFlushSafe(sim, evData.unit, evData.targetUnit)
			end
		end,

		onTooltip = function( self, hud, sim, player )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			section:addLine( self.name )

			local strings = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH
			local difficultyOptions = sim:getParams().difficultyOptions

			local desc = util.sformat(self.desc, difficultyOptions.backstab_turnsPerCycle)
			section:addAbility( self.shortdesc, desc, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )

			local blueDesc = strings.ZONE_WARNING_DESC
			section:addAbility( strings.BLUE_DESC_TITLE, blueDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )

			local title
			title = strings.YELLOW_DESC_TITLE
			for _,yellowDesc in ipairs(royaleFlushZoneDesc(difficultyOptions.backstab_yellowPenalties)) do
				section:addAbility( title, yellowDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )
				title = util.sformat(strings.CONTINUED_TITLE, title)
			end

			title = strings.RED_DESC_TITLE
			for _,redDesc in ipairs(royaleFlushZoneDesc(difficultyOptions.backstab_redPenalties)) do
				section:addAbility( title, redDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )
				title = util.sformat(strings.CONTINUED_TITLE, title)
			end

			if self.dlcFooter then
				section:addFooter(self.dlcFooter[1],self.dlcFooter[2])
			end

			return tooltip
		end,
	}
}

return npc_abilities
