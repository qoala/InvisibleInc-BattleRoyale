local util = include( "modules/util" )
local mainframe_common = include("sim/abilities/mainframe_common")
local simdefs = include("sim/simdefs")

local createDaemon = mainframe_common.createDaemon

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

			local redDesc = util.sformat(strings.ZONE_DISARM_DESC, 4)
			section:addAbility( strings.RED_DESC_TITLE, redDesc, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )

			local yellowDesc = util.sformat(strings.ZONE_SLOW_DESC, 2)
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
