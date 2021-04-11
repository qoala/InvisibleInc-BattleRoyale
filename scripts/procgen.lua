
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local astar = include( "modules/astar" )
local rand = include( "modules/rand" )
local util = include( "modules/util" )
local astar_handlers = include( "sim/astar_handlers" )
local procgen = include( "sim/procgen" )
local procgen_context = include( "sim/procgen_context" )
local simquery = include( "sim/simquery" )

----------------------------------------------------------------
-- Local query functions

local function isNormalExit(r)
	return r.tags ~= nil and (r.tags.exit or r.tags.exit_vault)
end
local function isCampaignExit(r)
	return r.tags ~= nil and (r.tags.exit_mid_1 or r.tags.entry_mid_2 or r.tags.exit_final)
end
local function isExit(r)
	return isNormalExit(r) or isCampaignExit(r)
end

-- Modified copy of procgen_context:canPath. Changes at -- BACKSTAB.
function canPath(cxt, x0, y0, x1, y1, includeLockedDoors)
	local cell1 = cxt:cellAt(x0, y0)
	local cell2 = cxt:cellAt(x1, y1)
	if not cell1 or not cell2 then
		return false
	end
	if cell2.tileIndex == nil or cell2.tileIndex == cdefs.TILE_SOLID or cell2.cell ~= nil or cell2.impass or cell2.dynamic_impass then
		return false
	end

	local dx, dy = x1-x0, y1-y0
	if math.abs(dx) > 1 or math.abs(dy) > 1 then
		return false
	end
	if dx ~= 0 and dy ~= 0 then
		return cxt:canPath(x0, y0, x1, y0, includeLockedDoors) and cxt:canPath(x1, y0, x1, y1, includeLockedDoors)
		 and cxt:canPath(x0, y0, x0, y1, includeLockedDoors) and cxt:canPath(x0, y1, x1, y1, includeLockedDoors)
	else
		--check walls
		local dir1 = simquery.getDirectionFromDelta(dx, dy)
		local side1 = cell1.sides and cell1.sides[dir1]
		-- BACKSTAB: Allow considering locked doors as passable
		if side1 and (not side1.door or (side1.locked and not includeLockedDoors)) then
			return false
		end
		local dir2 = simquery.getDirectionFromDelta(-dx, -dy)
		local side2 = cell2.sides and cell2.sides[dir2]
		-- BACKSTAB: Allow considering locked doors as passable
		if side2 and (not side2.door or (side2.locked and not includeLockedDoors)) then
			return false
		end

		return true
	end
	return false
end
function findLockedPath(cxt, x0, y0, x1, y1)
	return cxt.lockedDoorPather:findPath( {x = x0, y = y0}, {x = x1, y = y1})
end

function cellInFrontOfUnit(cxt, unit)
	if type(unit) == "string" then
		unit = cxt:pickUnit(function (u) return u.template == unit end)
	end
	if not unit then
		return
	end
	simlog("LOG_BACKSTAB", "Objective: %s %d,%d %d", unit.template, unit.x, unit.y, unit.unitData.facing)
	local dx, dy = simquery.getDeltaFromDirection(unit.unitData.facing)
	return cxt:cellAt(unit.x + dx, unit.y + dy)
end

----------------------------------------------------------------
-- Custom Local functions

-- Modified mazegen:breadthFirstSearch(). Changes at -- BACKSTAB
local function breadthFirstSearch( cxt, startRooms, fn )
	-- BACKSTAB: Support multiple 0-depth rooms.
	local rooms = util.tdupe(startRooms)
	for _,r in ipairs(startRooms) do
		r.depth = 0
	end

	while #rooms > 0 do
		local room = table.remove( rooms )
		for i, exit in ipairs( room.exits ) do
			-- BACKSTAB: Minimal extra cost when exit.barrier (locked door or laser)
			local cost = exit.barrier and 1.01 or 1
			if (exit.room.depth or math.huge) > room.depth + cost then
				exit.room.depth = room.depth + cost
				table.insert( rooms, 1, exit.room )
			end
		end
	end

    local rooms = util.tdupe( cxt.rooms )
    table.sort( rooms, function( r1, r2 ) return r1.depth < r2.depth end )
	for i = 1, #rooms do
		fn( rooms[i] )
		rooms[i].depth = nil
	end
end

function analyzeExitDistance(cxt)
	-- Find exit room(s)
	local exitRooms = {}
	for _,r in ipairs(cxt.rooms) do
		if isExit(r) then
			table.insert(exitRooms, r)
		end
	end
	if not exitRooms[1] then
		return
	end

	-- Discover depths from the exit room to all the other rooms.
	breadthFirstSearch( cxt, exitRooms,
	    function(room)
			room.backstab_exitDistance = (room.depth or 0)
		end )

	return exitRooms
end

function analyzeObjectivePath(cxt, exitRoom)
	cxt.pather = astar.AStar:new(astar_handlers.backstab_plan_handler:new(cxt, nil, {includeLockedDoors=false}))
	cxt.lockedDoorPather = astar.AStar:new(astar_handlers.backstab_plan_handler:new(cxt, nil, {includeLockedDoors=true}))

	local exitCell
	if exitRoom.tags.exit_final then
		exitCell = cxt:cellInFrontOfUnit("yellow_level_console")
	else
		-- Pick a cell next to the elevator
		_,_,exitCell = cxt:pickCell(cxt.IS_EXIT_CELL)
		simlog("LOG_BACKSTAB", "Exit Cell: %d,%d", exitCell.x, exitCell.y)
	end

	local objectiveCells = {}
	if exitRoom.tags.exit_final then
		table.insert(objectiveCells, cxt:cellInFrontOfUnit("ending_jackin"))
	elseif exitRoom.tags.exit_mid_1 then
		for _,unit in ipairs(cxt.units) do
			if unit.unitData and unit.unitData.tags and array.find(unit.unitData.tags, "switch_mid_1") ~= nil then
				table.insert(objectiveCells, cxt:cellInFrontOfUnit(unit))
			end
		end
	elseif exitRoom.tags.entry_mid_2 then
		table.insert(objectiveCells, cxt:cellInFrontOfUnit("research_security_processor"))
	end

	local rooms = {}
	for _,cell in ipairs(objectiveCells) do
		simlog("LOG_BACKSTAB", "Objective path: INIT %d,%d - %d,%d", cell.x, cell.y, exitCell.x, exitCell.y)
		local pathRooms = {}
		local lastRoom = nil
		local path = cxt:findPath(cell.x, cell.y, exitCell.x, exitCell.y)
		simlog("LOG_BACKSTAB", "Objective path: total cost %d", path:getTotalMoveCost())
		for _,node in ipairs(path:getNodes()) do
			local cell = cxt:cellAt(node.location.x, node.location.y)
			local room = cell.procgenRoom
			if room ~= lastRoom then
				simlog("LOG_BACKSTAB", "Objective path: add room %d", room.roomIndex)
				table.insert(pathRooms, room)
				lastRoom = room
			end
		end
		lastRoom = nil
		path = cxt:findLockedPath(cell.x, cell.y, exitCell.x, exitCell.y)
		simlog("LOG_BACKSTAB", "Objective lockedpath: total cost %d", path:getTotalMoveCost())
		for _,node in ipairs(path:getNodes()) do
			local cell = cxt:cellAt(node.location.x, node.location.y)
			local room = cell.procgenRoom
			if room ~= lastRoom then
				simlog("LOG_BACKSTAB", "Objective lockedpath: add room %d", room.roomIndex)
				table.insert(pathRooms, room)
				lastRoom = room
			end
		end
		array.uniqueMerge(rooms, pathRooms)
	end

	if rooms[1] then
		-- Distance from an objective path
		breadthFirstSearch( cxt, rooms,
			function(room)
				room.backstab_objectivePathDistance = (room.depth or 0)
			end )
	else
		simlog("BACKSTAB WARNING: no objective path rooms")
	end
end

function analyzeBattleRoyaleProgression(cxt)
	local exitRooms = analyzeExitDistance(cxt)

	if isCampaignExit(exitRooms[1]) then
		analyzeObjectivePath(cxt, exitRooms[1])
	end
end

----------------------------------------------------------------

local oldGenerateLevel = procgen.generateLevel
function procgen.generateLevel( params )
	local result = oldGenerateLevel( params )

	if params.difficultyOptions.backstab_enabled  then
		-- Fake procgen_context, with the final state and the bare minimum of methods copied over.
		local cxt = {
			board = result.board,
			rooms = result.rooms,
			units = result.units,
			rnd = rand.createGenerator( params.seed % 2^32 ),

			canPath = canPath,
			cellInFrontOfUnit = cellInFrontOfUnit,
			findLockedPath = findLockedPath,

			cellAt = procgen_context.cellAt,
			findPath = procgen_context.findPath,
			getBounds = procgen_context.getBounds,
			pickCell = procgen_context.pickCell,
			pickUnit = procgen_context.pickUnit,
			IS_EXIT_CELL = procgen_context.IS_EXIT_CELL,
		}
		analyzeBattleRoyaleProgression(cxt)
	end


	return result
end
