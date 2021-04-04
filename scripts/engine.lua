
local util = include( "modules/util" )
local simengine = include( "sim/engine" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )


oldInit = simengine.init

function simengine:init( ... )
	oldInit( self, ... )

	-- Assign each room to a backstabZone
	local difficultyOptions = self:getParams().difficultyOptions
	if difficultyOptions.backstab_enabled and self._rooms then
		local roomsPerCycle = difficultyOptions.backstab_roomsPerCycle
		local finalRooms = difficultyOptions.backstab_finalRooms

		-- Make a shallow copy and sort by reverse distance from exit.
		rooms = util.tdupe(self._rooms)
		table.sort(rooms, function(a,b) return a.backstabExitDistance > b.backstabExitDistance end)
		local backstabZone = 1
		local lastID = util.tcount(self._rooms) - finalRooms
		for i, room in ipairs( rooms ) do
			self._mutableRooms[room.roomIndex].backstabZone = backstabZone
			-- simlog("DBGBACKSTAB %s: %s, %s", room.roomIndex, room.backstabExitDistance, backstabZone)

			if (i % roomsPerCycle) == 0 then
				backstabZone = backstabZone + 1
			end
			if i >= lastID then
				break
			end
		end

		-- TODO: calculate zone as turns pass
		self._backstabLatestZone = 4
	end
end
