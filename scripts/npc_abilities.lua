local util = include( "modules/util" )
local mainframe_common = include("sim/abilities/mainframe_common")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include("client_defs")

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

local function chaseCell(sim, x, y, agent, hunters)
	hunters = hunters or {}
	local closestGuard = simquery.findClosestUnit(sim:getNPC():getUnits(), x, y,
		function(guard)
			return (guard:getBrain() and not guard:isKO()
				and not guard:getTraits().noInterestDistraction
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_COMBAT
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_FLEE
				and not hunters[guard:getID()])
		end)
	if closestGuard then
		spawnInterest(closestGuard, x, y, simdefs.SENSE_RADIO, simdefs.REASON_CAMERA, agent)
	end
	return closestGuard
end
local function chaseAgent(sim, agent, hunters)
	local x,y = agent:getLocation()
	return chaseCell(sim, x, y, agent, hunters)
end

local function huntCell(sim, x, y, agent, hunters)
	hunters = hunters or {}
	local closestGuard = simquery.findClosestUnit(sim:getNPC():getUnits(), x, y,
		function(guard)
			return (guard:getBrain() and not guard:isKO()
				and not guard:getTraits().noInterestDistraction
				and not guard:getTraits().pacifist
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_COMBAT
			    and guard:getBrain():getSituation().ClassType ~= simdefs.SITUATION_FLEE
				and not hunters[guard:getID()])
		end)
	if closestGuard then
		hunters[closestGuard:getID()] = agent
		spawnInterest(closestGuard, x, y, simdefs.SENSE_RADIO, simdefs.REASON_HUNTING, agent)
    end
	return closestGuard
end
local function huntAgent(sim, agent, hunters)
	local x,y = agent:getLocation()
	return huntCell(sim, x, y, agent, hunters)
end

-- ===

local function isPlayerAgent(unit)
	return unit and unit:isPC() and simquery.isAgent(unit) and unit:getLocation() and not unit:getTraits().takenDrone
end

local function applyAgentLocator(sim, unit, penalties, hunters, phase)
	-- No point in locating dead/pinned agents. KOed agents without a chaperone are fair game.
	if not penalties.locate or penalties.locate ~= phase or unit:isNeutralized() then
		return
	end
	if penalties.locateAlarm == "a" then
		chase = huntAgent(sim, unit, hunters)
	elseif penalties.locateAlarm == "n" then
		chase = chaseAgent(sim, unit, hunters)
	end
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
		sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT,{txt=uiTxt,x=x,y=y,unit=unit,color=cdefs.COLOR_PLAYER_WARNING})
	end

	applyAgentLocator(sim, unit, penalties, hunters, "start")
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
	local yellowPenalties = sim:getParams().difficultyOptions.backstab_yellowPenalties
	local redPenalties = sim:getParams().difficultyOptions.backstab_redPenalties
	if redPenalties.locate ~= "end" and yellowPenalties.locate ~= "end" then
	    return
	end

	local x,y = unit:getLocation()
	local cell = sim:getCell(x, y)
	local simRoom = sim._mutableRooms[cell.procgenRoom.roomIndex]
	if not simRoom or not simRoom.backstabState then
		return
	elseif simRoom.backstabState == 0 then
		applyAgentLocator(sim, unit, redPenalties, hunters, "end")
	elseif simRoom.backstabState == 1 then
		applyAgentLocator(sim, unit, yellowPenalties, hunters, "end")
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
	else
		return
	end

	local chase = nil
	if penalties.doorAlarm == "a" then
		chase = huntAgent(sim, unit)
	elseif penalties.doorAlarm == "n" then
		chase = chaseAgent(sim, unit)
	end
	if chase then
		local uiTxt = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.DOOR_EFFECT
		sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT,{txt=uiTxt,x=doorCell.x,y=doorCell.y,color=cdefs.COLOR_CORP_WARNING})
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
	else
		return
	end

	local chase = nil
	if penalties.safeAlarm == "a" then
		chase = huntAgent(sim, unit)
	elseif penalties.safeAlarm == "n" then
		chase = chaseAgent(sim, unit)
	end
	if chase then
		local uiTxt = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.SAFE_EFFECT
		sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT,{txt=uiTxt,x=sx,y=sy,color=cdefs.COLOR_CORP_WARNING})
	end
end
local function royaleFlushAttacked(sim, attackedUnit, x,y, hunters)
	-- Unlike other triggers, this one triggers on the enemy units, not the player units.
	if not x and attackedUnit then
		x,y = attackedUnit:getLocation()
	end
	if not x then
		return
	end

	local cell = sim:getCell(x, y)
	local simRoom = sim._mutableRooms[cell.procgenRoom.roomIndex]
	local penalties
	if not simRoom or not simRoom.backstabState then
		return
	elseif simRoom.backstabState == 0 then
		penalties = sim:getParams().difficultyOptions.backstab_redPenalties
	elseif simRoom.backstabState == 1 then
		penalties = sim:getParams().difficultyOptions.backstab_yellowPenalties
	else
		return
	end

	local hunter
	if penalties.attackAlarm == "a" then
		hunter = huntCell(sim, x,y, attackedUnit, hunters)
	elseif penalties.attackAlarm == "n" then
		hunter = chaseCell(sim, x,y, attackedUnit, hunters)
	end
	if hunter then
		local uiTxt = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.ATTACK_EFFECT
		sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT,{txt=uiTxt,x=x,y=y,color=cdefs.COLOR_CORP_WARNING})
	end
end

-- ===

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

local ICONS =
{
	["se"] =             "gui/icons/daemon_icons/backstab_royaleflush_s.png",
	["se+"] =            "gui/icons/daemon_icons/backstab_royaleflush_s_plus.png",
	["ce"] =             "gui/icons/daemon_icons/backstab_royaleflush_c.png",
	["ce+"] =            "gui/icons/daemon_icons/backstab_royaleflush_c_plus.png",
	["double"] =         "gui/icons/daemon_icons/backstab_royaleflush_d.png",
	["double+"] =        "gui/icons/daemon_icons/backstab_royaleflush_d_plus.png",
	["custom-se"] =      "gui/icons/daemon_icons/backstab_royaleflush_s_edit.png",
	["custom-se+"] =     "gui/icons/daemon_icons/backstab_royaleflush_s_plus_edit.png",
	["custom-ce"] =      "gui/icons/daemon_icons/backstab_royaleflush_c_edit.png",
	["custom-ce+"] =     "gui/icons/daemon_icons/backstab_royaleflush_c_plus_edit.png",
	["custom-double"] =  "gui/icons/daemon_icons/backstab_royaleflush_d_edit.png",
	["custom-double+"] = "gui/icons/daemon_icons/backstab_royaleflush_d_plus_edit.png",
	["custom-easy"] =    "gui/icons/daemon_icons/backstab_royaleflush_h_edit.png",
	["custom-easy+"] =   "gui/icons/daemon_icons/backstab_royaleflush_h_plus_edit.png",
}

local function pickIcon(params)
	local icon = ICONS[params.backstab_stab and params.backstab_stab.label]
	if icon then return icon end
	local yellowPenalties = params.backstab_yellowPenalties or {}
	local redPenalties = params.backstab_redPenalties or {}
	-- Option for extra-hard mode.
	local isPlus = redPenalties.locate == "end" and redPenalties.locateAlarm == "a"

	-- Options never enabled by a preset.
	local hasNoCustom = (not yellowPenalties.disarm and not yellowPenalties.locate
			and not yellowPenalties.attackAlarm)

	-- Options enabled by the standard preset.
	local hasStandard = (yellowPenalties.doorAlarm and yellowPenalties.safeAlarm
			and redPenalties.doorAlarm == "a" and redPenalties.safeAlarm == "a"
			and redPenalties.attackAlarm == "a"
			and redPenalties.locate and redPenalties.locateAlarm == "a")
	local hasExactlyStandard = (
			yellowPenalties.doorAlarm == "n" and yellowPenalties.safeAlarm == "n")
	-- Options disabled by the standard preset, but enabled by the classic preset.
	local hasNoClassic = (yellowPenalties.mp == 0
			and redPenalties.mp == 0 and not redPenalties.disarm)

	-- Options enabled by the classic preset.
	local hasClassic = (yellowPenalties.mp >= 2 and yellowPenalties.noSprint
			and redPenalties.mp >= 4 and redPenalties.noSprint
			and redPenalties.disarm
			and redPenalties.locate and redPenalties.locateAlarm == "a")
	local hasExactlyClassic = (
			yellowPenalties.mp == 2 and redPenalties.mp == 4)
	-- Options disabled by the classic preset, but enabled by the standard preset.
	local hasNoStandard = (not yellowPenalties.doorAlarm and not yellowPenalties.safeAlarm
			and not redPenalties.doorAlarm and not redPenalties.safeAlarm
			and not redPenalties.attackAlarm)

	if hasStandard and hasClassic then
		if hasNoCustom and hasExactlyStandard and hasExactlyClassic then
			return isPlus and ICONS["double+"] or ICONS["double"]
		else
			return isPlus and ICONS["custom-double+"] or ICONS["custom-double"]
		end
	elseif hasStandard then
		if hasNoCustom and hasExactlyStandard and hasNoClassic then
			return isPlus and ICONS["se+"] or ICONS["se"]
		else
			return isPlus and ICONS["custom-se+"] or ICONS["custom-se"]
		end
	elseif hasClassic then
		if hasNoCustom and hasExactlyClassic and hasNoStandard then
			return isPlus and ICONS["ce+"] or ICONS["ce"]
		else
			return isPlus and ICONS["custom-ce+"] or ICONS["custom-ce"]
		end
	else
		return isPlus and ICONS["custom-easy+"] or ICONS["custom-easy"]
	end
end

-- ===

local npc_abilities =
{
	backstab_royaleFlush = util.extend(createDaemon(STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH))
	{
		icon = "gui/icons/daemon_icons/backstab_royaleflush_h_edit.png",
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
			local difficultyOptions = sim:getParams().difficultyOptions
			updateLegacyParams(difficultyOptions)
			self.icon = pickIcon(difficultyOptions) or self.icon

			local stabOptions = difficultyOptions.backstab_stab or {}
			self._reverseZones = stabOptions.reverseZones
			self.turns = sim:backstab_turnsUntilNextZone()

			sim:addTrigger( simdefs.TRG_START_TURN, self )
			sim:addTrigger( simdefs.TRG_END_TURN, self )
			sim:addTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:addTrigger( simdefs.TRG_SAFE_LOOTED, self )
			sim:addTrigger( simdefs.TRG_UNIT_KILLED, self )
			sim:addTrigger( simdefs.TRG_UNIT_KO, self )
			sim:addTrigger( "BACKSTAB_attackQueueStart", self )
			sim:addTrigger( "BACKSTAB_attackQueueProcess", self )
		end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
			sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:removeTrigger( simdefs.TRG_SAFE_LOOTED, self )
			sim:removeTrigger( simdefs.TRG_UNIT_KILLED, self )
			sim:removeTrigger( simdefs.TRG_UNIT_KO, self )
			sim:removeTrigger( "BACKSTAB_attackQueueStart", self )
			sim:removeTrigger( "BACKSTAB_attackQueueProcess", self )
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
			elseif evType == simdefs.TRG_UNIT_KO and evData.ticks and evData.unit and evData.unit:isNPC() then
				if self._attackQueue then
					local x,y = evData.unit:getLocation()
					table.insert(self._attackQueue, {unitID=evData.unit:getID(), x=x, y=y})
				else
					royaleFlushAttacked(sim, evData.unit)
				end
			elseif evType == simdefs.TRG_UNIT_KILLED and evData.unit and evData.unit:getTraits().isGuard and evData.corpse then
				if self._attackQueue then
					local x,y = evData.corpse:getLocation()
					table.insert(self._attackQueue, {unitID=evData.corpse:getID(), x=x, y=y})
				else
					royaleFlushAttacked(sim, evData.corpse)
				end
			elseif evType == "BACKSTAB_attackQueueStart" then
				self._attackQueue = {}
			elseif evType == "BACKSTAB_attackQueueProcess" then
				local queue = self._attackQueue
				self._attackQueue = nil
				if queue then
					local hunters = {}
					for _,entry in ipairs(queue) do
						local unit = sim:getUnit(entry.unitID)
						royaleFlushAttacked(sim, unit, entry.x, entry.y, hunters)
					end
				end
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
