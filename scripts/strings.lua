
local MOD_STRINGS =
{
	DAEMONS =
	{
		ROYALE_FLUSH =
		{
			NAME = "ROYALE FLUSH",
			DESC = "Permanent.\nEvery {1} turns, zones advance towards exit. BLUE->YELLOW->RED",
			SHORT_DESC = "FLUSH TOWARDS EXIT",
			ACTIVE_DESC = "NEXT ZONE FLUSHED IN {1} {1:TURN|TURNS}",
			FINISHED_DESC = "ALL IN",

			RED_DESC_TITLE = "RED ZONE",
			YELLOW_DESC_TITLE = "YELLOW ZONE",
			BLUE_DESC_TITLE = "BLUE ZONE",
			ZONE_DISARM_DESC = "Agents starting their turn in this zone lose {1} AP and lose their attack.",
			ZONE_SLOW_DESC = "Agents starting their turn in this zone lose {1} AP.",
			ZONE_WARNING_DESC = "No penalty.",

			SLOW_EFFECT = "AP DRAINED",
			DISARM_EFFECT = "AP/ATTACK DRAINED",
		},
	},
}

return MOD_STRINGS
