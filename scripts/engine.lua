
local util = include( "modules/util" )
local simengine = include( "sim/engine" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )


local oldInit = simengine.init

function simengine:init( ... )
	oldInit( self, ... )

	local hasExit = false
	for _,room in ipairs(self._rooms) do
		if room.tags.exit or room.tags.exit_vault then
			hasExit = true
			break
		end
	end

	if not hasExit then
		-- No support for mid1/mid2/ending missions yet.
		return
	end

	-- Assign each room to a backstabZone
	local difficultyOptions = self:getParams().difficultyOptions
	local startTurn = difficultyOptions.backstab_startTurn
	if startTurn and self._rooms then
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

			if i >= lastID then
				break
			end
			if (i % roomsPerCycle) == 0 then
				backstabZone = backstabZone + 1
			end
		end

		self._backstab_maxZone = backstabZone

		self._backstab_nextZoneTurn = startTurn
		self:backstab_advanceZones()
		self:getNPC():addMainframeAbility(self, "backstab_royaleFlush", 0)
	end
end

function simengine:backstab_nextZone()
	return self._backstab_nextZone
end

function simengine:backstab_turnsUntilNextZone(turnOffset)
	if self._backstab_nextZoneTurn and (not self._backstab_nextZone or self._backstab_nextZone <= self._backstab_maxZone) then
		local turn = math.ceil( (self:getTurnCount() + 1 + (turnOffset or 0)) / 2)
		return self._backstab_nextZoneTurn - turn
	end
	return nil
end

function updateRooms(sim, zone)
	for _, simRoom in ipairs( sim._mutableRooms ) do
		if simRoom.backstabZone == zone then
			-- RED
			simRoom.backstabState = 0
		elseif simRoom.backstabZone == zone + 1 then
			-- YELLOW
			simRoom.backstabState = 1
		elseif simRoom.backstabZone == zone + 2 then
			-- BLUE
			simRoom.backstabState = 2
		end
	end
end

function simengine:backstab_advanceZones(turnOffset)
	local difficultyOptions = self:getParams().difficultyOptions
	local turnsPerCycle = difficultyOptions.backstab_turnsPerCycle
	local startTurn = difficultyOptions.backstab_startTurn

	local turn = math.ceil( (self:getTurnCount() + 1 + (turnOffset or 0)) / 2)

	if turn < startTurn or (self._backstab_nextZone and self._backstab_nextZone > self._backstab_maxZone) then
		-- simlog("DBGBACKSTAB ADVANCE: %s start=%s", turn, startTurn)
		return false
	end

	-- First zone is at 1. On startTurn, the next cycle is 0 with only warnings being marked into rooms.
	local nextZone = math.floor((turn - startTurn) / turnsPerCycle)
	if nextZone ~= self._backstab_nextZone then
		updateRooms(self, nextZone - 1)
		self._backstab_nextZone = nextZone
		self._backstab_nextZoneTurn = startTurn + (nextZone + 1) * turnsPerCycle

		-- simlog("DBGBACKSTAB ADVANCE: %s next=%s", turn, self._backstab_nextZone)
		return true
	end
	return false
end
