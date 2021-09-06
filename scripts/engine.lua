
local util = include( "modules/util" )
local simengine = include( "sim/engine" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )


local oldInit = simengine.init

-- Sort by reverse distance from exit
function compareRooms(a, b)
	if a.backstab_exitDistance ~= b.backstab_exitDistance then
		return a.backstab_exitDistance > b.backstab_exitDistance
	end

	-- Treat objectives as closer than other rooms at the same effective distance.
	if a.tags.objective ~= b.tags.objective then
		return b.tags.objective
	end

	return a.roomIndex > b.roomIndex
end

function simengine:init( ... )
	oldInit( self, ... )

	local difficultyOptions = self:getParams().difficultyOptions
	if not difficultyOptions.backstab_enabled then
		return
	end

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
	local startTurn = difficultyOptions.backstab_startTurn
	if startTurn and self._rooms then
		local roomsPerCycle = difficultyOptions.backstab_roomsPerCycle
		local finalRooms = difficultyOptions.backstab_finalRooms

		-- Make a shallow copy, filtering out "always rooms", ...
		rooms = {}
		roomCount = 0
		for _, room in ipairs(self._rooms) do
			if room.tags and room.tags.backstab_alwaysSafe then
				self._mutableRooms[room.roomIndex].backstabZone = nil
				simlog("LOG_BACKSTAB", "room=%s alwaysSafe zone=nil", room.roomIndex)
			elseif room.backstab_alwaysRed or (room.tags and room.tags.backstab_alwaysRed) or room.backstab_exitDistance>=1000 then
				-- HallwayHell's external guard-entry rooms lock in exitDistance==1000, make them alwaysRed.
				self._mutableRooms[room.roomIndex].backstabZone = nil
				self._mutableRooms[room.roomIndex].backstabAlwaysRed = true
				simlog("LOG_BACKSTAB", "room=%s alwaysRed zone=always", room.roomIndex)
			else
				table.insert(rooms, room)
				roomCount = roomCount + 1
			end
		end
		-- ...and sort by reverse distance from exit.
		table.sort(rooms, compareRooms)

		-- and assign them to backstabZone IDs in order.
		local backstabZone = 1
		local lastID = roomCount - finalRooms
		for i, room in ipairs( rooms ) do
			self._mutableRooms[room.roomIndex].backstabZone = backstabZone
			simlog("LOG_BACKSTAB", "room=%s toExit=%s zone=%s", room.roomIndex, room.backstab_exitDistance, backstabZone)

			if i >= lastID then
				break
			end
			if (i % roomsPerCycle) == 0 then
				backstabZone = backstabZone + 1
			end
		end

		self._backstab_startTurn = startTurn
		self._backstab_maxZone = backstabZone
		self._backstab_nextZoneTurn = startTurn
		self._backstab_nextZone = -100  -- Always update the first time.
		self:backstab_advanceZones()
		self:getNPC():addMainframeAbility(self, "backstab_royaleFlush", nil, 0)
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
		if simRoom.backstabAlwaysRed then
			-- RED
			simRoom.backstabState = 0
		elseif not simRoom.backstabZone or not zone then
			simRoom.backstabState = nil
		elseif simRoom.backstabZone <= zone then
			-- RED
			simRoom.backstabState = 0
		elseif simRoom.backstabZone == zone + 1 then
			-- YELLOW
			simRoom.backstabState = 1
		elseif simRoom.backstabZone == zone + 2 then
			-- BLUE
			simRoom.backstabState = 2
		else
			simRoom.backstabState = nil
		end
	end
end

function simengine:backstab_advanceZones(turnOffset)
	local difficultyOptions = self:getParams().difficultyOptions
	local turnsPerCycle = difficultyOptions.backstab_turnsPerCycle
	local startTurn = self._backstab_startTurn

	local turn = math.ceil( (self:getTurnCount() + 1 + (turnOffset or 0)) / 2)

	-- First zone is marked 1. On startTurn, the next zone is 0 with only warnings being marked into rooms.
	local nextZone = math.floor((turn - startTurn) / turnsPerCycle)
	if nextZone < 0 then
		nextZone = nil
	elseif nextZone > self._backstab_maxZone then
		nextZone = self._backstab_maxZone + 1
	end

	if nextZone ~= self._backstab_nextZone then
		if nextZone then
			updateRooms(self, nextZone - 1)
			self._backstab_nextZoneTurn = startTurn + (nextZone + 1) * turnsPerCycle
		else
			updateRooms(self, nil)
			self._backstab_nextZoneTurn = startTurn
		end
		self._backstab_nextZone = nextZone

		self:dispatchEvent("EV_BACKSTAB_REFRESHOVERLAY", {})

		simlog("LOG_BACKSTAB", "ADVANCE: turn=%s next=%s", turn, tostring(self._backstab_nextZone))
		return true
	end
	return false
end

-- Called for events that push back the Royale Flush zone advancement
function simengine:backstab_reverse(cycleCount)
	if self._backstab_nextZone <= self._backstab_maxZone then
		local difficultyOptions = self:getParams().difficultyOptions
		local turnsPerCycle = difficultyOptions.backstab_turnsPerCycle
		self._backstab_startTurn = self._backstab_startTurn + cycleCount * turnsPerCycle
	else
		local difficultyOptions = self:getParams().difficultyOptions
		local turnsPerCycle = difficultyOptions.backstab_turnsPerCycle

		local turn = math.ceil((self:getTurnCount() + 1) / 2)

		self._backstab_startTurn = turn - (self._backstab_maxZone - 1) * turnsPerCycle
	end

	self:backstab_advanceZones()
end

function simengine:backstab_isBackstabComplete()
	local downCount = 0
	local standingCount = 0
	for _, unit in ipairs(self:getPC():getUnits()) do
		if unit:hasAbility("escape") then
			if unit:isNeutralized() then
				downCount = downCount + 1
			else
				standingCount = standingCount + 1
			end
		end
	end

	simlog("LOG_BACKSTAB", "CHECK_BACKSTAB down=%d standing=%d", downCount, standingCount)
	return downCount > 0 and standingCount == 1
end
