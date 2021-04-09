
local array = include( "modules/array" )
local util = include( "modules/util" )
local procgen = include( "sim/procgen" )

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

function analyzeExitDistance( cxt )
	-- Find exit room(s)
	local exitRooms = {}
	for _,r in ipairs(cxt.rooms) do
		if r.tags ~= nil and (r.tags.exit or r.tags.exit_vault or r.tags.exit_mid_1 or r.tags.entry_mid_2 or r.tags.exit_final) then
			table.insert(exitRooms, r)
		end
	end
	if not exitRooms[1] then
		return
	end

	-- Discover depths from the exit room to all the other rooms.
	breadthFirstSearch( cxt, exitRooms,
	    function( room )
			room.backstab_exitDistance = (room.depth or 0)
		end )
end

local oldGenerateLevel = procgen.generateLevel

function procgen.generateLevel( params )
	local result = oldGenerateLevel( params )

	if params.difficultyOptions.backstab_enabled  then
		local cxt = {
			rooms = result.rooms
		}
		analyzeExitDistance(cxt)
	end


	return result
end
