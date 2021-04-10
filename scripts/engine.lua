
local util = include( "modules/util" )
local simengine = include( "sim/engine" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )


local oldInit = simengine.init

-- Sort by reverse distance from exit
function compareRooms(a, b)
	if a.backstab_exitDistance ~= b.backstab_exitDistance then
		return (a.backstab_exitDistance or math.huge) > (b.backstab_exitDistance or math.huge)
	end

	if a.backstab_objectivePathDistance ~= b.backstab_objectivePathDistance then
		return (a.backstab_objectivePathDistance or math.huge) > (b.backstab_objectivePathDistance or math.huge)
	end

	-- Treat objectives as closer than other rooms at the same effective distance.
	if a.tags.objective ~= b.tags.objective then
		return b.tags.objective
	end

	return a.roomIndex > b.roomIndex
end

-- Sort by reverse distance from objective path, then reverse distance from exit
function compareCampaignRooms(a, b)
	if a.backstab_objectivePathDistance ~= b.backstab_objectivePathDistance then
		return (a.backstab_objectivePathDistance or math.huge) > (b.backstab_objectivePathDistance or math.huge)
	end

	if a.backstab_exitDistance ~= b.backstab_exitDistance then
		return (a.backstab_exitDistance or math.huge) > (b.backstab_exitDistance or math.huge)
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

	local hasNormalExit = false
	local hasObjectivePath = true
	for _,room in ipairs(self._rooms) do
		if room.backstab_objectivePathDistance then
			hasObjectivePath = true
		end
		if room.tags.exit or room.tags.exit_vault then
			hasNormalExit = true
			break
		end
	end

	simlog("LOG_BACKSTAB", "SIMINIT hasNormalExit=%s hasObjectivePath=%s", tostring(hasNormalExit), tostring(hasObjectivePath))
	self._backstab_startTurn = difficultyOptions.backstab_startTurn
	local campaignMode = false
	if self._backstab_startTurn and not hasNormalExit then
		if not difficultyOptions.backstab_campaign or not difficultyOptions.backstab_campaign.mode then
			return
		elseif difficultyOptions.backstab_campaign.mode == "normal" then
			campaignMode = false
		elseif not hasObjectivePath then
			simlog("BACKSTAB WARNING: disabling Royale Flush, no objective path")
			return
		else
			campaignMode = difficultyOptions.backstab_campaign.mode
		end

		if difficultyOptions.backstab_campaign.turnDelay then
			self._backstab_startTurn = self._backstab_startTurn + difficultyOptions.backstab_campaign.turnDelay
		end
	end

	-- Assign each room to a backstabZone
	if self._backstab_startTurn and self._rooms then
		local roomsPerCycle = difficultyOptions.backstab_roomsPerCycle
		local finalRooms = difficultyOptions.backstab_finalRooms

		-- Make a shallow copy and sort by reverse distance from exit.
		rooms = util.tdupe(self._rooms)
		table.sort(rooms, campaignMode and compareCampaignRooms or compareRooms)
		local maxBackstabZone
		local lastID = util.tcount(self._rooms) - finalRooms
		for i, room in ipairs( rooms ) do
			local backstabZone = math.ceil(i / roomsPerCycle)
			local limited = false
			if campaignMode and room.backstab_objectivePathDistance == 0 then
				if campaignMode == "pathyellow" then
					backstabZone = backstabZone + 1
					limited = true
				elseif campaignMode == "pathred" then
					backstabZone = backstabZone + 1
				else
					-- No more penalty zones
					break
				end
			end

			simlog("LOG_BACKSTAB", "room=%s: toExit=%s toObjPath=%s zone=%s limit=%s",
				room.roomIndex, room.backstab_exitDistance, room.backstab_objectivePathDistance or "",
				backstabZone, limited and "t" or "f")
			self._mutableRooms[room.roomIndex].backstabZone = backstabZone
			if limited then
				maxBackstabZone = backstabZone - 1
				self._mutableRooms[room.roomIndex].backstabZoneLimited = true
			else
				maxBackstabZone = backstabZone
			end

			if i >= lastID then
				break
			end
		end

		self._backstab_maxZone = maxBackstabZone

		self._backstab_nextZoneTurn = self._backstab_startTurn
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
		if not simRoom.backstabZone then
			-- pass
		elseif simRoom.backstabZone <= zone and not simRoom.backstabZoneLimited then
			-- RED
			simRoom.backstabState = 0
		elseif simRoom.backstabZone <= zone + 1 then
			-- YELLOW
			simRoom.backstabState = 1
		elseif simRoom.backstabZone <= zone + 2 then
			-- BLUE
			simRoom.backstabState = 2
		end
	end
end

function simengine:backstab_advanceZones(turnOffset)
	local difficultyOptions = self:getParams().difficultyOptions
	local turnsPerCycle = difficultyOptions.backstab_turnsPerCycle
	local startTurn = self._backstab_startTurn

	local turn = math.ceil( (self:getTurnCount() + 1 + (turnOffset or 0)) / 2)

	if turn < startTurn or (self._backstab_nextZone and self._backstab_nextZone > self._backstab_maxZone) then
		simlog("LOG_BACKSTAB", "ADVANCE: turn=%s start=%s", turn, startTurn)
		return false
	end

	-- First zone is at 1. On startTurn, the next cycle is 0 with only warnings being marked into rooms.
	local nextZone = math.floor((turn - startTurn) / turnsPerCycle)
	if nextZone ~= self._backstab_nextZone then
		updateRooms(self, nextZone - 1)
		self._backstab_nextZone = nextZone
		self._backstab_nextZoneTurn = startTurn + (nextZone + 1) * turnsPerCycle

		self:dispatchEvent("EV_BACKSTAB_REFRESHOVERLAY", {})

		simlog("LOG_BACKSTAB", "ADVANCE: turn=%s next=%s", turn, self._backstab_nextZone)
		return true
	end
	return false
end
