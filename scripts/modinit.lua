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
	modApi:addGenerationOption("brRedLocate", STRINGS.BACKSTAB.OPTIONS.BR_REDLOCATE, STRINGS.BACKSTAB.OPTIONS.BR_REDLOCATE_TIP, {
		noUpdate = true,
		enabled = false,
	})

	local dataPath = modApi:getDataPath()
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

local function load(modApi, options, params)
	local scriptPath = modApi:getScriptPath()

	if params then
		params.backstab_enabled = true
	end
	if params and options["brStartTurn"] and options["brStartTurn"].value then
		params.backstab_startTurn = options["brStartTurn"].value
		params.backstab_roomsPerCycle = options["brRoomsPerCycle"] and options["brRoomsPerCycle"].value or 2
		params.backstab_turnsPerCycle = options["brTurnsPerCycle"] and options["brTurnsPerCycle"].value or 3
		params.backstab_finalRooms = options["brFinalRooms"] and options["brFinalRooms"].value or 1

		local yellowPenalties = {}
		params.backstab_yellowPenalties = yellowPenalties
		yellowPenalties.mp = options["brYellowMp"].value
		yellowPenalties.noSprint = options["brYellowMp"].value > 0
		yellowPenalties.disarm = options["brYellowDisarm"].enabled
		yellowPenalties.locate = false

		local redPenalties = {}
		params.backstab_redPenalties = redPenalties
		redPenalties.mp = options["brRedMp"].value
		redPenalties.noSprint = options["brRedMp"].value > 0
		redPenalties.disarm = options["brRedDisarm"].enabled
		redPenalties.locate = options["brRedLocate"].enabled
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
