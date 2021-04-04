
local array = include( "modules/array" )
local util = include( "modules/util" )
local procgen = include( "sim/procgen" )

local oldGenerateLevel = procgen.generateLevel

-- Modified mazegen:breadthFirstSearch(). Changes at -- BACKSTAB
local function breadthFirstSearch( cxt, searchRoom, fn )
	local rooms = { searchRoom }
	searchRoom.depth = 0

	while #rooms > 0 do
		local room = table.remove( rooms )
		for i, exit in ipairs( room.exits ) do
			-- BACKSTAB: Minimal extra cost when exit.barrier (locked door or laser)
			local cost = exit.barrier and 1.1 or 1
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
	-- Discover depths from the entrance room to all the other rooms.
	local originRoom = array.findIf( cxt.rooms,
	    function( r )
			return r.tags ~= nil and (r.tags.exit or r.tags.exit_vault or r.tags.exit_mid_1 or r.tags.entry_mid_2 or r.tags.exit_final)
		end )
	if not originRoom then
		return
	end

	breadthFirstSearch( cxt, originRoom,
	    function( room )
			room.backstabExitDistance = room.depth or 0
		end )
end

function procgen.generateLevel( params )
	local result = oldGenerateLevel( params )

	if true then
		local cxt = {
			rooms = result.rooms
		}
		analyzeExitDistance(cxt)
	end


	return result
end
