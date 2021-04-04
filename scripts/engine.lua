
local util = include( "modules/util" )
local simengine = include( "sim/engine" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )


oldInit = simengine.init

function simengine:init( ... )
	oldInit( self, ... )

	if true and self._rooms then
		local roomsPerCycle = 2;
		local finalRooms = 1;

		-- Make a shallow copy and sort by reverse distance from exit.
		rooms = util.tdupe(self._rooms)
		table.sort(rooms, function(a,b) return a.backstabExitDistance > b.backstabExitDistance end)
		local backstabIndex = 1
		local lastID = util.tcount(self._rooms) - finalRooms
		for i, room in ipairs( rooms ) do
			self._mutableRooms[room.roomIndex].backstabIndex = backstabIndex
			simlog("DBGBACKSTAB %s: %s, %s", room.roomIndex, room.backstabExitDistance, backstabIndex)

			if (i % roomsPerCycle) == 0 then
				backstabIndex = backstabIndex + 1
			end
			if i >= lastID then
				break
			end
		end
	end
end
