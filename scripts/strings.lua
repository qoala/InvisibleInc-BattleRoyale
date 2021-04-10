
local MOD_STRINGS =
{
	OPTIONS =
	{
		DISABLED = "DISABLED",

		BR_STARTTURN = "START TURN",
		BR_STARTTURN_TIP = "<c:FF8411>START TURN</c>\nIn Battle Royale mode, the map gradually shrinks towards the exit with increasing penalties for being out of bounds.\nZones progress from blue->yellow->red.\nIf enabled, this is the turn a warning (Blue Zone) is shown. It takes 2x TURNS PER ZONE additional turns to become a Red Zone.",
		BR_ZONESIZE = "ZONE SIZE",
		BR_ZONESIZE_TIP = "<c:FF8411>ZONE SIZE</c>\nThe size of the zone marked as out of bounds each cycle. May not be contiguous.\nAt default settings, the entire map is 15-16 units. (ROOMS IN LEVEL + 5 + side mission)",
		BR_ZONETURNS = "TURNS PER ZONE",
		BR_ZONETURNS_TIP = "<c:FF8411>TURNS PER ZONE</c>\nThe number of turns between each zone being marked as out of bounds.",
		BR_FINALSIZE = "FINAL SIZE",
		BR_FINALSIZE_TIP = "<c:FF8411>FINAL SIZE</c>\nThe size of the final area when the map reaches its minimum size.",

		BR_YELLOWMP = "YELLOW ZONE: AP PENALTY",
		BR_YELLOWMP_TIP = "<c:FF8411>YELLOW ZONE: AP PENALTY</c>\nAP Penalty for agents ending in the yellow zone. Cannot lower AP below 4.",
		BR_YELLOWDISARM = "YELLOW ZONE: DISARM",
		BR_YELLOWDISARM_TIP = "<c:FF8411>YELLOW ZONE: DISARM</c>\nIf enabled, agents ending in the yellow zone lose their attack.",
		BR_REDMP = "RED ZONE: AP PENALTY",
		BR_REDMP_TIP = "<c:FF8411>RED ZONE: AP PENALTY</c>\nAP Penalty for agents ending in the red zone. Cannot lower AP below 4.",
		BR_REDDISARM = "RED ZONE: DISARM",
		BR_REDDISARM_TIP = "<c:FF8411>RED ZONE: DISARM</c>\nIf enabled, agents ending in the red zone lose their attack.",
		BR_REDLOCATE = "RED ZONE: LOCATE AGENT",
		BR_REDLOCATE_TIP = "<c:FF8411>RED ZONE: LOCATE AGENT</c>\nIf enabled, agents ending in the red zone will be located at the start of their next turn.",
		BR_CAMPAIGN_MODE = "CAMPAIGN MISSIONS: MODE", 
		BR_CAMPAIGN_MODE_TIP = ("<c:FF8411>CAMPAIGN MISSIONS: MODE</c>\n" ..
				"For campaign missions (Transport Conduit, Foundry Lab, Mainframe) a shortest path between required objective(s) and the exit is protected.\n" ..
			    "First, penalty zones spread through areas off the shortest path. Then, they spread along the shortest path towards the exit.\n" ..
				"DISABLED: Battle Royale doesn't apply in campaign missions.\n" ..
				"PATH (SAFE): penalty zones never spread to the shortest path.\n" ..
				"PATH (YELLOW): penalty zones only apply yellow penalties along the shortest path.\n" ..
				"PATH (RED): penalty zones apply full penalties along the shortest path.\n" ..
				"EXIT ONLY: Instead of the above, zones collapse towards the exit, like normal."),
		BR_CAMPAIGN_MODE_PATHSAFE = "PATH (SAFE)",
		BR_CAMPAIGN_MODE_PATHYELLOW = "PATH (YELLOW)",
		BR_CAMPAIGN_MODE_PATHRED = "PATH (RED)",
		BR_CAMPAIGN_MODE_NORMAL = "EXIT ONLY",
		BR_CAMPAIGN_TURNDELAY = "BATTLE ROYALE CAMPAIGN MISSIONS: START DELAY", 
		BR_CAMPAIGN_TURNDELAY_TIP = "<c:FF8411>CAMPAIGN MISSIONS: START DELAY</c>\nAn additional number of turns before the first penalty zone appears in campaign missions.", 
	},

	DAEMONS =
	{
		ROYALE_FLUSH =
		{
			NAME = "ROYALE FLUSH",
			DESC = "Permanent.\nEvery {1} turns, zones advance towards exit. BLUE->YELLOW->RED",
			SHORT_DESC = "FLUSH TOWARDS EXIT",
			ACTIVE_DESC = "NEXT ZONE IN {1} {1:TURN|TURNS}",
			FINISHED_DESC = "ALL IN",

			RED_DESC_TITLE = "RED ZONE",
			YELLOW_DESC_TITLE = "YELLOW ZONE",
			BLUE_DESC_TITLE = "BLUE ZONE",
			ZONE_DISARM_DESC = "Agents ending their turn in this zone lose {1} AP and their attack next turn.",
			ZONE_SLOW_DESC = "Agents ending their turn in this zone lose {1} AP next turn.",
			ZONE_LOCATEONLY_DESC = "Agents ending their turn in this location will have their location relayed to the nearest guard next turn.",
			ZONE_WARNING_DESC = "No penalty.",
			ZONE_LOCATE_DESC = "They will also be located by a guard.",

			SLOW_EFFECT = "AP DRAINED",
			DISARM_EFFECT = "AP/ATTACK DRAINED",
		},
	},
}

return MOD_STRINGS
