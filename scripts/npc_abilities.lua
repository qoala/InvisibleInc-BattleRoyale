local util = include( "modules/util" )
local mainframe_common = include("sim/abilities/mainframe_common")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

local createDaemon = mainframe_common.createDaemon

-- Copy of Brain:spawnInterest. Changes at -- BACKSTAB.
function spawnInterest(unit, x, y, sense, reason, sourceUnit)
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
	end
	unit:getSim():processReactions(unit)
end

function huntAgent(sim, agent, hunters)
	local x,y = agent:getLocation()
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

function royaleFlushApplyPenalties(sim, unit, penalties, hunters)
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

function royaleFlushUnitStartTurn(sim, unit, hunters)
	if not simquery.isAgent(unit) or unit:getTraits().takenDrone then
		return
	end
	if unit:getTraits().backstab_mpMaxPenalty then
		unit:addMP(unit:getTraits().backstab_mpMaxPenalty)
		unit:addMPMax(unit:getTraits().backstab_mpMaxPenalty)
		unit:getTraits().backstab_mpMaxPenalty = nil
	end

	local x,y = unit:getLocation()
	if not x then
		return
	end
	local cell = sim:getCell(x, y)
	local simRoom = sim._mutableRooms[cell.procgenRoom.roomIndex]
	if not simRoom or not simRoom.backstabState then
		return
	elseif simRoom.backstabState == 0 then
		royaleFlushApplyPenalties(sim, unit, sim:getParams().difficultyOptions.backstab_redPenalties, hunters)
	elseif simRoom.backstabState == 1 then
		local difficultyOptions = sim:getParams().difficultyOptions
		royaleFlushApplyPenalties(sim, unit, sim:getParams().difficultyOptions.backstab_yellowPenalties, hunters)
	end
end

function royaleFlushUnitEndTurn(sim, unit, hunters)
	if not simquery.isAgent(unit) or unit:getTraits().takenDrone then
		return
	end
	local penalties = sim:getParams().difficultyOptions.backstab_redPenalties
	if penalties.locate ~= "end" then
	    return
	end

	local x,y = unit:getLocation()
	if not x then
		return
	end
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

function royaleFlushZoneDesc(penalties)
	local strings = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH

	local desc
	if penalties.disarm then
		desc = util.sformat(strings.ZONE_DISARM_DESC, penalties.mp)
	elseif penalties.mp and penalties.mp >= 0 then
		desc = util.sformat(strings.ZONE_SLOW_DESC, penalties.mp)
	else
		if penalties.locate == "end" then
			return strings.ZONE_LOCATEENDONLY_DESC
		elseif penalties.locate then
			return strings.ZONE_LOCATEONLY_DESC
		else
			return strings.ZONE_WARNING_DESC
		end
	end

	if penalties.locate == "end" then
		return desc .. " " .. strings.ZONE_LOCATEEND_DESC
	elseif penalties.locate then
		return desc .. " " .. strings.ZONE_LOCATE_DESC
	else
		return desc
	end
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
		end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
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

			local redDesc = royaleFlushZoneDesc(difficultyOptions.backstab_redPenalties)
			section:addAbility( strings.RED_DESC_TITLE, redDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )

			local yellowDesc = royaleFlushZoneDesc(difficultyOptions.backstab_yellowPenalties)
			section:addAbility( strings.YELLOW_DESC_TITLE, yellowDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )

			local blueDesc = strings.ZONE_WARNING_DESC
			section:addAbility( strings.BLUE_DESC_TITLE, blueDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )

			if self.dlcFooter then
				section:addFooter(self.dlcFooter[1],self.dlcFooter[2])
			end

			return tooltip
		end,
	}
}

return npc_abilities
