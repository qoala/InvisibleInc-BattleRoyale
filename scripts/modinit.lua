local function earlyInit(modApi)
	modApi.requirements =
	{
	}
end

local function init(modApi)
	local scriptPath = modApi:getScriptPath()
	-- Store script path for cross-file includes
	rawset(_G,"SCRIPT_PATHS",rawget(_G,"SCRIPT_PATHS") or {})
	SCRIPT_PATHS.backstab_protocol = scriptPath

	local dataPath = modApi:getDataPath()
	KLEIResourceMgr.MountPackage(dataPath .. "/images.kwad", "data")

	include(scriptPath .. "/aiplayer")
	include(scriptPath .. "/cellrig")
	include(scriptPath .. "/engine")
	include(scriptPath .. "/procgen")
end

local function initStrings(modApi)
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
		params.backstab_roomsPerCycle = 2
		params.backstab_finalRooms = 1
		params.backstab_turnsPerCycle = 3
		params.backstab_startTurn = 5
	end
end

return {
	earlyInit = earlyInit,
	load = load,
	init = init,
	initStrings = initStrings,
}
