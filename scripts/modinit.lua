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

	modApi:addGenerationOption("brStartTurn", STRINGS.BACKSTAB.OPTIONS.BR_STARTTURN, STRINGS.BACKSTAB.OPTIONS.BR_STARTTURN_TIP, {
		noUpdate = true,
		values = {false, 1, 2, 3, 4, 5, 6, 10, 15, 20},
		strings = {STRINGS.BACKSTAB.OPTIONS.DISABLED, "1", "2", "3", "4", "5", "6", "10", "15", "20"},
		value = 3,
	})
	modApi:addGenerationOption("brRoomsPerCycle", STRINGS.BACKSTAB.OPTIONS.BR_ZONESIZE, STRINGS.BACKSTAB.OPTIONS.BR_ZONESIZE_TIP, {
		noUpdate = true,
		values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		value = 2,
	})
	modApi:addGenerationOption("brTurnsPerCycle", STRINGS.BACKSTAB.OPTIONS.BR_ZONETURNS, STRINGS.BACKSTAB.OPTIONS.BR_ZONETURNS_TIP, {
		noUpdate = true,
		values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		value = 3,
	})
	modApi:addGenerationOption("brFinalRooms", STRINGS.BACKSTAB.OPTIONS.BR_FINALSIZE, STRINGS.BACKSTAB.OPTIONS.BR_FINALSIZE_TIP, {
		noUpdate = true,
		values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		value = 1,
	})
	modApi:addGenerationOption("brYellowMp", STRINGS.BACKSTAB.OPTIONS.BR_YELLOWMP, STRINGS.BACKSTAB.OPTIONS.BR_YELLOWMP_TIP, {
		noUpdate = true,
		values = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
		value = 2,
	})
	modApi:addGenerationOption("brYellowDisarm", STRINGS.BACKSTAB.OPTIONS.BR_YELLOWDISARM, STRINGS.BACKSTAB.OPTIONS.BR_YELLOWDISARM_TIP, {
		noUpdate = true,
		enabled = false,
	})
	modApi:addGenerationOption("brRedMp", STRINGS.BACKSTAB.OPTIONS.BR_REDMP, STRINGS.BACKSTAB.OPTIONS.BR_REDMP_TIP, {
		noUpdate = true,
		values = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
		value = 4,
	})
	modApi:addGenerationOption("brRedDisarm", STRINGS.BACKSTAB.OPTIONS.BR_REDDISARM, STRINGS.BACKSTAB.OPTIONS.BR_REDDISARM_TIP, {
		noUpdate = true,
		enabled = true,
	})

	local dataPath = modApi:getDataPath()
	KLEIResourceMgr.MountPackage(dataPath .. "/images.kwad", "data")

	include(scriptPath .. "/cellrig")
	include(scriptPath .. "/engine")
	include(scriptPath .. "/procgen")
end

local function earlyUnload(modApi)
	local scriptPath = modApi:getScriptPath()

	local patch_cdefs = include (scriptPath .. "/patch_cdefs")
	patch_cdefs.resetLeveltiles()
end

local function earlyLoad(modApi, options, params)
	earlyUnload(modApi)
end

local function load(modApi, options, params)
	local scriptPath = modApi:getScriptPath()

	local patch_cdefs = include (scriptPath .. "/patch_cdefs")
	patch_cdefs.patchLeveltiles()

	if params then
		params.backstab_enabled = true
	end
	if params and options["brStartTurn"] and options["brStartTurn"].value then
		params.backstab_startTurn = options["brStartTurn"].value
		params.backstab_roomsPerCycle = options["brRoomsPerCycle"] and options["brRoomsPerCycle"].value or 2
		params.backstab_turnsPerCycle = options["brTurnsPerCycle"] and options["brTurnsPerCycle"].value or 3
		params.backstab_finalRooms = options["brFinalRooms"] and options["brFinalRooms"].value or 1

		if options["brYellowMp"] then
			params.backstab_yellowZoneMP = options["brYellowMp"].value
			params.backstab_yellowZoneNoSprint = options["brYellowMp"].value > 0
		else
			params.backstab_yellowZoneMP = 2
			params.backstab_yellowZoneNoSprint = true
		end
		if options["brYellowDisarm"] then
			params.backstab_yellowZoneDisarm = options["brYellowDisarm"].enabled
		else
			params.backstab_yellowZoneDisarm = false
		end
		if options["brRedMP"] then
			params.backstab_redZoneMP = options["brRedMP"].value
			params.backstab_redZoneNoSprint = options["brRedMP"].value > 0
		else
			params.backstab_redZoneMP = 4
			params.backstab_redZoneNoSprint = true
		end
		if options["brRedDisarm"] then
			params.backstab_redZoneDisarm = options["brRedDisarm"].enabled
		else
			params.backstab_redZoneDisarm = true
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
