
local MOD_STRINGS =
{
	OPTIONS =
	{
		DEFAULT = "DEFAULT",
		CUSTOM = "CUSTOM",
		PRESET_BACKSTAB = "BACKSTAB",
		PRESET_CLASSIC_FULL = "CLASSIC",
		PRESET_CLASSIC = "C",
		PRESET_SE_FULL = "STANDARD",
		PRESET_SE = "S",
		PRESET_SE_PLUS_FULL = "STANDARD+",
		PRESET_SE_PLUS = "S+",

		BR_MAIN = "ROYALE FLUSH",
		BR_MAIN_TIP = "<c:FF8411>ROYALE FLUSH:</c>\nA challenging new daemon installed at the start of every (non-story) mission.\nThe map gradually shrinks towards the exit with increasing penalties for being out of bounds.\nZones progress from blue->yellow->red.",
		BR_STARTTURN = "    START TURN",
		BR_STARTTURN_TIP = "<c:FF8411>START TURN</c>\nThe turn that a warning (Blue Zone) is first shown. It takes [TURNS PER ZONE] additional turns to become a Yellow Zone, and the same number of turns past that to become a Red Zone.",
		BR_ZONESIZE = "    ZONE SIZE",
		BR_ZONESIZE_TIP = "<c:FF8411>ZONE SIZE</c>\nThe size of the zone marked as out of bounds each cycle. May not be contiguous.\nIncrease this to raise difficulty.\nAt default settings, the entire map is 15-16 units. (ROOMS IN LEVEL + 5 + optional side mission)",
		BR_ZONETURNS = "    TURNS PER ZONE",
		BR_ZONETURNS_TIP = "<c:FF8411>TURNS PER ZONE</c>\nThe number of turns between each zone being marked as out of bounds.\nIncrease this to lower difficulty. Lower this to raise difficulty.",
		BR_FINALSIZE = "    FINAL SIZE",
		BR_FINALSIZE_TIP = "<c:FF8411>FINAL SIZE</c>\nThe size of the final area when the map reaches its minimum size.\nIncrease this to lower difficulty.\nAt 1, eventually only the exit room will be safe.",

		STAB_REVERSEZONES = "    BACKSTAB REVERSAL",
		STAB_REVERSEZONES_TIP = "<c:FF8411>BACKSTAB REVERSAL</c>\nWhen only 1 agent is left standing, reverse Royale Flush by this many zones. Triggers once per mission.\nUsually only used when trying to emulate a Battle Royale feel in the game (with some form of multiplayer).",

		BR_ZONEPENALTIES = "ZONE EFFECTS",
		BR_ZONEPENALTIES_TIP = ("<c:FF8411>ZONE EFFECTS</c>\nWhat penalties are applied in each zone.\n\n"..
			"STANDARD (S): Actions in the zone notify guards.\n  YELLOW: alarmed doors, alarmed safes\n  RED: + alarm on guard injury, agents are located at the start of your turn.\n  Red Zone notifications alert guards.\n\n"..
			"STANDARD+ (S+): As above, except that in the Red Zone, agents are located at the end of your turn. Guards will come for you immediately.\n\n"..
			"CLASSIC (C): Penalize agents ending in the zone.\n  YELLOW: -2AP\n  RED: -4AP, disarm, agent locator\n  Red Zone notifications alert guards."),

		BR_YELLOWMP = "    YELLOW ZONE: AP PENALTY",
		BR_YELLOWMP_TIP = "<c:FF8411>YELLOW ZONE: AP PENALTY</c>\nAP Penalty for agents ending in the yellow zone. Cannot lower AP below 4.",
		BR_YELLOWDISARM = "    YELLOW ZONE: DISARM",
		BR_YELLOWDISARM_TIP = "<c:FF8411>YELLOW ZONE: DISARM</c>\nIf enabled, agents ending in the yellow zone lose their attack.",
		BR_YELLOWLOCATE = "    YELLOW ZONE: LOCATE AGENT",
		BR_YELLOWLOCATE_TIP = "<c:FF8411>YELLOW ZONE: LOCATE AGENT</c>\nIf enabled, agents ending turn in the yellow zone will be located, either at the start of their next turn or immediately at the end of their turn.",
		BR_YELLOWDOORALARM = "    YELLOW ZONE: ALARMED DOORS",
		BR_YELLOWDOORALARM_TIP = "<c:FF8411>YELLOW ZONE: ALARMED DOORS</c>\nIf enabled, toggling a door from the yellow zone will notify or alert a nearby guard.",
		BR_YELLOWSAFEALARM = "    YELLOW ZONE: ALARMED SAFES",
		BR_YELLOWSAFEALARM_TIP = "<c:FF8411>YELLOW ZONE: ALARMED SAFES</c>\nIf enabled, looting a safe in the yellow zone will notify or alert a nearby guard.",
		BR_YELLOWATTACKALARM = "    YELLOW ZONE: GUARD TRANSPONDERS",
		BR_YELLOWATTACKALARM_TIP = "<c:FF8411>YELLOW ZONE: GUARD TRANSPONDERS/c>\nIf enabled, KOing or killing a guard/drone in the yellow zone will notify or alert a nearby guard.",
		BR_REDMP = "    RED ZONE: AP PENALTY",
		BR_REDMP_TIP = "<c:FF8411>RED ZONE: AP PENALTY</c>\nAP Penalty for agents ending in the red zone. Cannot lower AP below 4.",
		BR_REDDISARM = "    RED ZONE: DISARM",
		BR_REDDISARM_TIP = "<c:FF8411>RED ZONE: DISARM</c>\nIf enabled, agents ending in the red zone lose their attack.",
		BR_REDLOCATE = "    RED ZONE: LOCATE AGENT",
		BR_REDLOCATE_TIP = "<c:FF8411>RED ZONE: LOCATE AGENT</c>\nIf enabled, agents ending turn in the red zone will be located, either at the start of their next turn or immediately at the end of their turn.",
		BR_REDDOORALARM = "    RED ZONE: ALARMED DOORS",
		BR_REDDOORALARM_TIP = "<c:FF8411>RED ZONE: ALARMED DOORS</c>\nIf enabled, toggling a door from the red zone will notify or alert a nearby guard.",
		BR_REDSAFEALARM = "    RED ZONE: ALARMED SAFES",
		BR_REDSAFEALARM_TIP = "<c:FF8411>RED ZONE: ALARMED SAFES</c>\nIf enabled, looting a safe in the red zone will notify or alert a nearby guard.",
		BR_REDATTACKALARM = "    RED ZONE: GUARD TRANSPONDERS",
		BR_REDATTACKALARM_TIP = "<c:FF8411>RED ZONE: GUARD TRANSPONDERS/c>\nIf enabled, KOing or killing a guard/drone in the red zone will notify or alert a nearby guard.",

		DISABLED = "DISABLED",
		ENABLED = "ENABLED",
		ALARM_NOTIFY = "NOTIFY",
		ALARM_ALERT = "ALERT",
		ALARM_NOTIFY_NEXT = "NOTIFY NEXT TURN",
		ALARM_ALERT_NEXT = "ALERT NEXT TURN",
		ALARM_NOTIFY_NOW = "NOTIFY IMMEDIATELY",
		ALARM_ALERT_NOW = "ALERT IMMEDIATELY",
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

			REVERSE_NAME = "DEAD MAN'S HAND",
			REVERSE_DESC = "ZONES RECEDE",

			RED_DESC_TITLE = "RED ZONE",
			YELLOW_DESC_TITLE = "YELLOW ZONE",
			BLUE_DESC_TITLE = "BLUE ZONE",
			CONTINUED_TITLE = "{1} (CONTINUED)",
			ZONE_WARNING_DESC = "No penalty.",
			-- triggered penalties
			ZONE_ALARM_TEMPLATE = "{1} in this zone will {2} a nearby guard.",
			ZONE_ALARM_TRIGGER =
			{
				DOOR = "Doors",
				SAFE = "Safes",
				ATTACK = "KOs/kills",
				DOOR_SAFE = "Doors and safes",
				DOOR_ATTACK = "Doors and KOs/kills",
				SAFE_ATTACK = "Safes and KOs/kills",
				DOOR_SAFE_ATTACK = "Doors, safes, and KOs/kills",
			},
			ZONE_ALARM_EFFECT = {
				NOTIFY = "notify",
				ALERT = "alert",
			},
			-- End of turn penalties
			ZONE_DISARM_DESC = "Agents ending their turn in this zone lose {1} AP and their attack next turn.",
			ZONE_SLOW_DESC = "Agents ending their turn in this zone lose {1} AP next turn.",
			ZONE_LOCATEONLY_DESC = "Agents ending their turn in this zone will be located by a nearby guard next turn.",
			ZONE_LOCATEENDONLY_DESC = "Agents ending their turn in this zone will will be located by a nearby guard immediately.",
			ZONE_LOCATE_DESC = "They will also be located by a guard.",
			ZONE_LOCATEEND_DESC = "They will also be immediately located by a guard.",

			SLOW_EFFECT = "AP DRAINED",
			DISARM_EFFECT = "AP/ATTACK DRAINED",
			DOOR_EFFECT = "ROYALE SENSOR",
			SAFE_EFFECT = "ROYALE SENSOR",
			ATTACK_EFFECT = "ROYALE TRANSPONDER",
		},
	},
}

return MOD_STRINGS
