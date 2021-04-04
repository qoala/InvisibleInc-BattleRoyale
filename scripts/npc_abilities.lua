local util = include( "modules/util" )
local mainframe_common = include("sim/abilities/mainframe_common")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

local createDaemon = mainframe_common.createDaemon

function royaleFlushApplyPenalties(sim, unit, mpPenalty, sprintPenalty, disarmPenalty)
	local uiTxt = nil
	if mpPenalty and mpPenalty > 0 then
		local mp = unit:getTraits().mp
		local cappedPenalty = mp - math.max(mp - mpPenalty, 4)
		unit:addMP(-cappedPenalty)
		if not sprintPenalty then
			-- Adjust max MP to avoid blocking the sprint ability
			unit:addMPMax(-cappedPenalty)
			unit:getTraits().backstab_mpMaxPenalty = cappedPenalty
		end
		sim:dispatchEvent( simdefs.EV_HUD_MPUSED, unit )
		uiTxt = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.SLOW_EFFECT
	end
	if disarmPenalty and unit:hasTrait("ap") and unit:getTraits().ap > 0 then
		unit:getTraits().ap = 0

		uiTxt = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.DISARM_EFFECT
	end

	if uiTxt then
		local x,y = unit:getLocation()
		sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT,{txt=uiTxt,x=x,y=y,unit=unit,color={r=1/2,g=1,b=1,a=1}})
	end
end

function royaleFlushHandleUnit(sim, unit)
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
		local difficultyOptions = sim:getParams().difficultyOptions
		royaleFlushApplyPenalties(sim, unit, difficultyOptions.backstab_redZoneMP, difficultyOptions.backstab_redZoneNoSprint, difficultyOptions.backstab_redZoneDisarm)
	elseif simRoom.backstabState == 1 then
		local difficultyOptions = sim:getParams().difficultyOptions
		royaleFlushApplyPenalties(sim, unit, difficultyOptions.backstab_yellowZoneMP, difficultyOptions.backstab_yellowZoneNoSprint, difficultyOptions.backstab_yellowZoneDisarm)
	end
end

function royaleFlushZoneDesc(mpPenalty, disarmPenalty)
	local strings = STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH

	if disarmPenalty then
		return util.sformat(strings.ZONE_DISARM_DESC, mpPenalty)
	elseif mpPenalty and mpPenalty >= 0 then
		return util.sformat(strings.ZONE_SLOW_DESC, mpPenalty)
	else
		return strings.ZONE_WARNING_DESC
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

		ENDLESS_DAEMONS = false,
		PROGRAM_LIST = false,
		OMNI_PROGRAM_LIST_EASY = false,
		OMNI_PROGRAM_LIST = false,
		REVERSE_DAEMONS = false,

		_didAdvance = false,

		onSpawnAbility = function( self, sim, player )
			self.turns = sim:backstab_turnsUntilNextZone()

			sim:addTrigger( simdefs.TRG_START_TURN, self )
			sim:addTrigger( simdefs.TRG_END_TURN, self )
		end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
		end,

		onTrigger = function( self, sim, evType, evData, userUnit )
			if evType == simdefs.TRG_END_TURN and sim:getCurrentPlayer():isNPC() then
				self._didAdvance = sim:backstab_advanceZones(1)  -- +1, Turn hasn't advanced yet.
				self.turns = sim:backstab_turnsUntilNextZone(1)
			elseif evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
				if self._didAdvance then
					local txt = self.turns and util.sformat(self.activedesc, self.turns) or STRINGS.BACKSTAB.DAEMONS.ROYALE_FLUSH.FINISHED_DESC
					sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = txt } )
					self._didAdvance = false
				end

				for _,unit in ipairs(sim:getPC():getUnits()) do
					royaleFlushHandleUnit(sim, unit)
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

			local redDesc = royaleFlushZoneDesc(difficultyOptions.backstab_redZoneMP, difficultyOptions.backstab_redZoneDisarm)
			section:addAbility( strings.RED_DESC_TITLE, redDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )

			local yellowDesc = royaleFlushZoneDesc(difficultyOptions.backstab_yellowZoneMP, difficultyOptions.backstab_yellowZoneDisarm)
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
