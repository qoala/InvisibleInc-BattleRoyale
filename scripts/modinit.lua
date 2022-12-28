local function earlyInit(modApi)
	modApi.requirements =
	{
	}
end

local function initStrings(modApi)
	local dataPath = modApi:getDataPath()
	local scriptPath = modApi:getScriptPath()

	local MOD_STRINGS = include( scriptPath .. "/strings" )
	modApi:addStrings( dataPath, "BACKSTAB", MOD_STRINGS)
end

local function init(modApi)
	local scriptPath = modApi:getScriptPath()
	-- Store script path for cross-file includes
	rawset(_G,"SCRIPT_PATHS",rawget(_G,"SCRIPT_PATHS") or {})
	SCRIPT_PATHS.backstab_protocol = scriptPath

	local util = include( "modules/util" )
	local function formatDefault(value, presetLabel)
		return util.sformat("{1} ({2})", value, presetLabel)
	end

	local STR = STRINGS.BACKSTAB.OPTIONS

	-- Main Switch
	modApi:addGenerationOption("brMod", STR.BR_MAIN, STR.BR_MAIN_TIP, {
		noUpdate=true,
		enabled = true,
		masks = {{mask = "mask_br_enabled", requirement = true}},
	})
	-- Zone parameters
	modApi:addGenerationOption("brStartTurn", STR.BR_STARTTURN, STR.BR_STARTTURN_TIP, {
		noUpdate = true,
		values = {1, 2, 3, 4, 5, 6, 10, 15, 20},
		strings = {"1", "2", formatDefault("3", STR.DEFAULT), "4", "5", "6", "10", "15", "20"},
		value = 3,
		requirements = {{mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brRoomsPerCycle", STR.BR_ZONESIZE, STR.BR_ZONESIZE_TIP, {
		noUpdate = true,
		values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		strings = {"1", formatDefault("2", STR.DEFAULT), "3", "4", "5", "6", "7", "8", "9", "10"},
		value = 2,
		requirements = {{mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brTurnsPerCycle", STR.BR_ZONETURNS, STR.BR_ZONETURNS_TIP, {
		noUpdate = true,
		values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		strings = {"1", "2", formatDefault("3", STR.DEFAULT), "4", "5", "6", "7", "8", "9", "10"},
		value = 3,
		requirements = {{mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brFinalRooms", STR.BR_FINALSIZE, STR.BR_FINALSIZE_TIP, {
		noUpdate = true,
		values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		strings = {formatDefault("1", STR.DEFAULT), "2", "3", "4", "5", "6", "7", "8", "9", "10"},
		value = 1,
		requirements = {{mask = "mask_br_enabled", requirement = true}},
	})
	-- Reversal
	modApi:addGenerationOption("stabReverseZones", STR.STAB_REVERSEZONES, STR.STAB_REVERSEZONES_TIP, {
		noUpdate = true,
		values = {false, 1, 2, 3, 4, 5, 6, 7, 8, 9},
		strings = {formatDefault(STR.DISABLED, STR.DEFAULT), "1", formatDefault("2", STR.PRESET_BACKSTAB), "3", "4", "5", "6", "7", "8", "9"},
		value = false,
		requirements = {{mask = "mask_br_enabled", requirement = true}},
	})

	-- Zone penalties
	modApi:addGenerationOption("brZonePenalties", STR.BR_ZONEPENALTIES, STR.BR_ZONEPENALTIES_TIP, {
		noUpdate = true,
		values = {"se", "se+", "classic", "custom"},
		strings = {STR.PRESET_SE_FULL, STR.PRESET_SE_PLUS_FULL, STR.PRESET_CLASSIC_FULL, STR.CUSTOM},
		difficulties = {{1,"se"},{2,"se"},{3,"se"},{4,"se+"},{5,"se"},{6,"se+"},{7,"se"},{8,"se+"}},
		masks = {{mask = "mask_custom_penalties", requirement = "custom"}},
		requirements = {{mask = "mask_br_enabled", requirement = true}},
	})
	-- Yellow-zone penalties
	modApi:addGenerationOption("brYellowMp", STR.BR_YELLOWMP, STR.BR_YELLOWMP_TIP, {
		noUpdate = true,
		values = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_SE), "1", formatDefault("2", STR.PRESET_CLASSIC), "3", "4", "5", "6", "7", "8", "9"},
		value = 0,
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brYellowDisarm", STR.BR_YELLOWDISARM, STR.BR_YELLOWDISARM_TIP, {
		noUpdate = true,
		values = {false, true},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC.."/"..STR.PRESET_SE), STR.ENABLED},
		value = false,
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brYellowLocate", STR.BR_YELLOWLOCATE, STR.BR_YELLOWLOCATE_TIP, {
		noUpdate = true,
		values = {false, "n.start", "a.start", "n.end", "a.end"},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC.."/"..STR.PRESET_SE), STR.ALARM_NOTIFY_NEXT, STR.ALARM_ALERT_NEXT, STR.ALARM_NOTIFY_NOW, STR.ALARM_ALERT_NOW},
		value = false,
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brYellowDoorAlarm", STR.BR_YELLOWDOORALARM, STR.BR_YELLOWDOORALARM_TIP, {
		noUpdate = true,
		values = {false, "n", "a"},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC), formatDefault(STR.ALARM_NOTIFY, STR.PRESET_SE), STR.ALARM_ALERT},
		value = "n",
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brYellowSafeAlarm", STR.BR_YELLOWSAFEALARM, STR.BR_YELLOWSAFEALARM_TIP, {
		noUpdate = true,
		values = {false, "n", "a"},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC), formatDefault(STR.ALARM_NOTIFY, STR.PRESET_SE), STR.ALARM_ALERT},
		value = "n",
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brYellowAttackAlarm", STR.BR_YELLOWATTACKALARM, STR.BR_YELLOWATTACKALARM_TIP, {
		noUpdate = true,
		values = {false, "n", "a"},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC.."/"..STR.PRESET_SE), STR.ALARM_NOTIFY, STR.ALARM_ALERT},
		value = false,
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	-- Red-zone penalties
	modApi:addGenerationOption("brRedMp", STR.BR_REDMP, STR.BR_REDMP_TIP, {
		noUpdate = true,
		values = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_SE), "1", "2", "3", formatDefault("4", STR.PRESET_CLASSIC), "5", "6", "7", "8", "9"},
		value = 0,
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brRedDisarm", STR.BR_REDDISARM, STR.BR_REDDISARM_TIP, {
		noUpdate = true,
		values = {false, true},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_SE), formatDefault(STR.ENABLED, STR.PRESET_CLASSIC)},
		value = false,
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brRedLocate", STR.BR_REDLOCATE, STR.BR_REDLOCATE_TIP, {
		noUpdate = true,
		values = {false, "n.start", "a.start", "n.end", "a.end"},
		strings = {STR.DISABLED, STR.ALARM_NOTIFY_NEXT, formatDefault(STR.ALARM_ALERT_NEXT, STR.PRESET_CLASSIC.."/"..STR.PRESET_SE), STR.ALARM_NOTIFY_NOW, formatDefault(STR.ALARM_ALERT_NOW, STR.PRESET_SE_PLUS)},
		difficulties = {{1,"a.start"},{2,"a.start"},{3,"a.start"},{4,"a.end"},{5,"a.start"},{6,"a.end"},{7,"a.start"},{8,"a.end"}},
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brRedDoorAlarm", STR.BR_REDDOORALARM, STR.BR_REDDOORALARM_TIP, {
		noUpdate = true,
		values = {false, "n", "a"},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC), STR.ALARM_NOTIFY, formatDefault(STR.ALARM_ALERT, STR.PRESET_SE)},
		value = "a",
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brRedSafeAlarm", STR.BR_REDSAFEALARM, STR.BR_REDSAFEALARM_TIP, {
		noUpdate = true,
		values = {false, "n", "a"},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC), STR.ALARM_NOTIFY, formatDefault(STR.ALARM_ALERT, STR.PRESET_SE)},
		value = "a",
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})
	modApi:addGenerationOption("brRedAttackAlarm", STR.BR_REDATTACKALARM, STR.BR_REDATTACKALARM_TIP, {
		noUpdate = true,
		values = {false, "n", "a"},
		strings = {formatDefault(STR.DISABLED, STR.PRESET_CLASSIC), STR.ALARM_NOTIFY, formatDefault(STR.ALARM_ALERT, STR.PRESET_SE)},
		value = "a",
		requirements = {{mask = "mask_custom_penalties", requirement = true}, {mask = "mask_br_enabled", requirement = true}},
	})

	local dataPath = modApi:getDataPath()
	KLEIResourceMgr.MountPackage(dataPath .. "/gui.kwad", "data")
	KLEIResourceMgr.MountPackage(dataPath .. "/images.kwad", "data")

	-- client overrides
	include(scriptPath .. "/boardrig")
	include(scriptPath .. "/cdefs")
	include(scriptPath .. "/cellrig")

	-- sim overrides
	include(scriptPath .. "/engine")
	include(scriptPath .. "/procgen")
end

local function earlyUnload(modApi)
end

local function earlyLoad(modApi, options, params)
	earlyUnload(modApi)
end

local LOCATOR_MAPPING = {
	["n.start"] = {"n", "start"},
	["a.start"] = {"a", "start"},
	["n.end"] = {"n", "end"},
	["a.end"] = {"a", "end"},
}

local function load(modApi, options, params)
	local scriptPath = modApi:getScriptPath()

	if params then
		params.backstab_enabled = true
	end
	if params and options["brMod"] and options["brMod"].enabled then
		params.backstab_startTurn = options["brStartTurn"] and options["brStartTurn"].value or 3
		params.backstab_roomsPerCycle = options["brRoomsPerCycle"] and options["brRoomsPerCycle"].value or 2
		params.backstab_turnsPerCycle = options["brTurnsPerCycle"] and options["brTurnsPerCycle"].value or 3
		params.backstab_finalRooms = options["brFinalRooms"] and options["brFinalRooms"].value or 1
		local stab = {}
		params.backstab_stab = stab
		stab.reverseZones = options["stabReverseZones"].value

		local yellowPenalties = {}
		params.backstab_yellowPenalties = yellowPenalties
		local redPenalties = {}
		params.backstab_redPenalties = redPenalties

		if options["brZonePenalties"] and options["brZonePenalties"].value == "se" then
			params.backstab_stab.label = "se"

			yellowPenalties.mp = 0
			yellowPenalties.noSprint = false
			yellowPenalties.disarm = false
			yellowPenalties.locate = false
			yellowPenalties.doorAlarm = "n"
			yellowPenalties.safeAlarm = "n"
			yellowPenalties.attackAlarm = false

			redPenalties.mp = 0
			redPenalties.noSprint = false
			redPenalties.disarm = false
			redPenalties.locate = "start"
			redPenalties.locateAlarm = "a"
			redPenalties.doorAlarm = "a"
			redPenalties.safeAlarm = "a"
			redPenalties.attackAlarm = "a"
		elseif options["brZonePenalties"] and options["brZonePenalties"].value == "se+" then
			params.backstab_stab.label = "se+"

			yellowPenalties.mp = 0
			yellowPenalties.noSprint = false
			yellowPenalties.disarm = false
			yellowPenalties.locate = false
			yellowPenalties.doorAlarm = "n"
			yellowPenalties.safeAlarm = "n"
			yellowPenalties.attackAlarm = false

			redPenalties.mp = 0
			redPenalties.noSprint = false
			redPenalties.disarm = false
			redPenalties.locate = "end"
			redPenalties.locateAlarm = "a"
			redPenalties.doorAlarm = "a"
			redPenalties.safeAlarm = "a"
			redPenalties.attackAlarm = "a"
		elseif options["brZonePenalties"] and options["brZonePenalties"].value == "classic" then
			params.backstab_stab.label = "ce"

			yellowPenalties.mp = 2
			yellowPenalties.noSprint = true
			yellowPenalties.disarm = false
			yellowPenalties.locate = false
			yellowPenalties.doorAlarm = false
			yellowPenalties.safeAlarm = false
			yellowPenalties.attackAlarm = false

			redPenalties.mp = 4
			redPenalties.noSprint = true
			redPenalties.disarm = true
			redPenalties.locate = "start"
			redPenalties.locateAlarm = "a"
			redPenalties.doorAlarm = false
			redPenalties.safeAlarm = false
			redPenalties.attackAlarm = false
		else
			yellowPenalties.mp = options["brYellowMp"].value
			yellowPenalties.noSprint = options["brYellowMp"].value > 0
			yellowPenalties.disarm = options["brYellowDisarm"].value
			do
				local locatorValues = LOCATOR_MAPPING[options["brYellowLocate"].value] or {false, false}
				yellowPenalties.locateAlarm = locatorValues[1]
				yellowPenalties.locate = locatorValues[2]
			end
			yellowPenalties.doorAlarm = options["brYellowDoorAlarm"].value
			yellowPenalties.safeAlarm = options["brYellowSafeAlarm"].value
			yellowPenalties.attackAlarm = options["brYellowAttackAlarm"].value

			redPenalties.mp = options["brRedMp"].value
			redPenalties.noSprint = options["brRedMp"].value > 0
			redPenalties.disarm = options["brRedDisarm"].value
			do
				local locatorValues = LOCATOR_MAPPING[options["brRedLocate"].value] or {false, false}
				redPenalties.locateAlarm = locatorValues[1]
				redPenalties.locate = locatorValues[2]
			end
			redPenalties.doorAlarm = options["brRedDoorAlarm"].value
			redPenalties.safeAlarm = options["brRedSafeAlarm"].value
			redPenalties.attackAlarm = options["brRedAttackAlarm"].value
		end
	end

	local npc_abilities = include( scriptPath .. "/npc_abilities" )
	for name, ability in pairs(npc_abilities) do
		modApi:addDaemonAbility( name, ability )
	end
end

return {
	earlyInit = earlyInit,
	earlyLoad = earlyLoad,
	earlyUnload = earlyUnload,
	load = load,
	init = init,
	initStrings = initStrings,
}
