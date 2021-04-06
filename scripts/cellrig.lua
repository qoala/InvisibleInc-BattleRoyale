
local cdefs = include( "client_defs" )
local cellrig = include("gameplay/cellrig")
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

----------------------------------------------------------------
-- Custom Local functions

local function backstabOverlayTactical(sim, cell)
	local room = cell.procgenRoom
	local simRoom = sim._mutableRooms[ room.roomIndex ]
	if not room or not simRoom.backstabState then
		return 0
	elseif simRoom.backstabState == 0 then
		return cdefs.BACKSTAB.OVERLAY.RED_CELL
	elseif simRoom.backstabState == 1 then
		return cdefs.BACKSTAB.OVERLAY.YELLOW_CELL
	elseif simRoom.backstabState == 2 then
		return cdefs.BACKSTAB.OVERLAY.BLUE_CELL
	end
	return 0
end

local function matchBackstabState(sim, x, y, startCell, state)
	local cell = sim:getCell(x, y)
	if not cell or not cell.procgenRoom or cell.tileIndex == cdefs.TILE_SOLID then
		return false
	end
	if not simquery.canPathBetween(sim, nil, startCell, cell) then
		return false
	end
	if cell.procgenRoom.roomIndex == startCell.procgenRoom.roomIndex then
		-- Trivial match
		return true
	end
	local simRoom = sim._mutableRooms[ cell.procgenRoom.roomIndex ]
	return simRoom and simRoom.backstabState == state
end

local function backstabOverlayCornerOffset(matchHorz, matchDiag, matchVert)
	if matchHorz == matchVert then
		if matchHorz then
			if matchDiag then
				return cdefs.BACKSTAB.OVERLAY.FILL_OFFSET
			else
				return cdefs.BACKSTAB.OVERLAY.INNERCORNER_OFFSET
			end
		else
			return cdefs.BACKSTAB.OVERLAY.OUTERCORNER_OFFSET
		end
	else
		if matchHorz then
			return cdefs.BACKSTAB.OVERLAY.HORZEDGE_OFFSET
		else
			return cdefs.BACKSTAB.OVERLAY.VERTEDGE_OFFSET
		end
	end
end

local function backstabOverlayNormal(sim, cell)
	local room = cell.procgenRoom
	local simRoom = sim._mutableRooms[ room.roomIndex ]
	local base = 0
	if not room or not simRoom.backstabState then
		return 0,0,0,0
	end
	local state = simRoom.backstabState
	if state == 0 then
		base = cdefs.BACKSTAB.OVERLAY.RED_CELL
	elseif state == 1 then
		base = cdefs.BACKSTAB.OVERLAY.YELLOW_CELL
	elseif state == 2 then
		base = cdefs.BACKSTAB.OVERLAY.BLUE_CELL
	else
		return 0,0,0,0
	end

	matchW = matchBackstabState(sim, cell.x-1, cell.y, cell, state)
	matchSW = matchBackstabState(sim, cell.x-1, cell.y-1, cell, state)
	matchS = matchBackstabState(sim, cell.x, cell.y-1, cell, state)
	matchSE = matchBackstabState(sim, cell.x+1, cell.y-1, cell, state)
	matchE = matchBackstabState(sim, cell.x+1, cell.y, cell, state)
	matchNE = matchBackstabState(sim, cell.x+1, cell.y+1, cell, state)
	matchN = matchBackstabState(sim, cell.x, cell.y+1, cell, state)
	matchNW = matchBackstabState(sim, cell.x-1, cell.y+1, cell, state)

	local sw = base + backstabOverlayCornerOffset(matchW, matchSW, matchS)
	local se = base + backstabOverlayCornerOffset(matchE, matchSE, matchS)
	local nw = base + backstabOverlayCornerOffset(matchW, matchNW, matchN)
	local ne = base + backstabOverlayCornerOffset(matchE, matchNE, matchN)
	return sw, se, nw, ne
end

----------------------------------------------------------------

local oldRefresh = cellrig.refresh
function cellrig:refresh()
	oldRefresh(self)

	if not self._boardRig._backstab_overlayGrid then
		-- Bail out.
		return
	end

	-- Refresh Backstab zone overlay
	local scell = self._boardRig:getLastKnownCell( self._x, self._y )
	local rawcell = self._game.simCore:getCell( self._x, self._y )
	-- Cell must exist, be seen, and not be solid (e.g. a pillar)
	if rawcell ~= nil then
		local idxSW = 0
		local idxSE = 0
		local idxNW = 0
		local idxNE = 0
		local show = false

		if scell ~= nil and rawcell.tileIndex ~= cdefs.TILE_SOLID then
			local gfxOptions = self._game:getGfxOptions()
			if gfxOptions.bMainframeMode then
				-- pass
			elseif gfxOptions.bTacticalView then
				-- Each map tile draws as a box. All corners are the same.
				idxSW = backstabOverlayTactical( self._game.simCore, rawcell )
				idxSE = idxSW
				idxNW = idxSW
				idxNE = idxSW
				show = idxSW ~= 0
			else
				-- Draw a border around the entire zone. Each corner depends on neighbors.
				idxSW,idxSE,idxNW,idxNE = backstabOverlayNormal( self._game.simCore, rawcell )
				show = idxSW ~= 0
			end
		end
		local x = (self._x - 1) * 2 + 1
		local y = (self._y - 1) * 2 + 1
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x, y, idxSW )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x, y, show and MOAIGridSpace.TILE_Y_FLIP or MOAIGridSpace.TILE_HIDE )
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x+1, y, idxSE )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x+1, y, show and MOAIGridSpace.TILE_XY_FLIP or MOAIGridSpace.TILE_HIDE )
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x, y+1, idxNW )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x, y+1, show and 0 or MOAIGridSpace.TILE_HIDE )
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x+1, y+1, idxNE )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x+1, y+1, show and MOAIGridSpace.TILE_X_FLIP or MOAIGridSpace.TILE_HIDE )
	end
end
