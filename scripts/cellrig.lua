
local cdefs = include( "client_defs" )
local cellrig = include("gameplay/cellrig")
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

----------------------------------------------------------------
-- Vanilla Local functions

local function isUnknownCell( boardRig, rawcell )
	if rawcell.tileIndex ~= cdefs.TILE_UNKNOWN then
		for _, dir in ipairs( simdefs.DIR_SIDES ) do
			local dx, dy = simquery.getDeltaFromDirection( dir )
			local tocell = boardRig:getLastKnownCell( rawcell.x + dx, rawcell.y + dy )
			if tocell and rawcell.exits[ dir ] then
				return true
			end
		end
	end
	return false
end

----------------------------------------------------------------
-- Custom Local functions

local function backstabOffset(sim, cell)
	local room = cell.procgenRoom
	local simRoom = sim._mutableRooms[ room.roomIndex ]
	if not room or not simRoom.backstabState then
		return 0
	else
		return (1 + simRoom.backstabState) * 4
	end
	return 0
end

----------------------------------------------------------------

-- Override cellrig:refresh(). Changes at -- BACKSTAB
local oldRefresh = cellrig.refresh
function cellrig:refresh()
	-- BACKSTAB: Check enabled.
	if not self._game.simCore:getParams().difficultyOptions.backstab_enabled  then
		return oldRefresh(self)
	end

	local scell = self._boardRig:getLastKnownCell( self._x, self._y )
	local rawcell = self._game.simCore:getCell( self._x, self._y )
	if rawcell ~= nil then
		local orientation = self._boardRig._game:getCamera():getOrientation()

		local idx = cdefs.BLACKOUT_CELL
		local flags = MOAIGridSpace.TILE_HIDE

		local gfxOptions = self._game:getGfxOptions()
		if gfxOptions.bMainframeMode then
			if scell then
				idx, flags = cdefs.MAINFRAME_CELL + orientation, 0
            elseif isUnknownCell( self._boardRig, rawcell ) then
				idx, flags = cdefs.MAINFRAME_UNKNOWN_CELL, 0
			end

		elseif rawcell.tileIndex ~= cdefs.TILE_UNKNOWN and scell == nil then
			if isUnknownCell( self._boardRig, rawcell ) then
				idx, flags = cdefs.UNKNOWN_CELL, 0
			end

		elseif gfxOptions.bTacticalView then
			local localPlayer = self._game:getLocalPlayer()
			local isWatched = localPlayer and simquery.isCellWatched( self._game.simCore, localPlayer, self._x, self._y )

			-- BACKSTAB: Tactical tileset is modified by backstab status of the cell.
			local offset = backstabOffset( self._game.simCore, rawcell )
			if isWatched == simdefs.CELL_WATCHED then
				idx, flags = cdefs.WATCHED_CELL - offset, 0
			elseif isWatched == simdefs.CELL_NOTICED then
				idx, flags = cdefs.NOTICED_CELL - offset, 0
			elseif self._boardRig:isBlindSpot( self._x, self._y ) then
				idx, flags = cdefs.COVER_CELL - offset, 0
			else
				idx, flags = cdefs.SAFE_CELL - offset, 0
			end

		else
			local mapTile = cdefs.MAPTILES[ rawcell.tileIndex ]
			idx = mapTile.tileStart + (self._x-1 + self._y-1) % mapTile.patternLen
			flags = 0
		end
		self._boardRig._grid:getGrid():setTile( self._x, self._y, idx )
		self._boardRig._grid:getGrid():setTileFlags( self._x, self._y, flags )
	end
end
