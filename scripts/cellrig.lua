
local cdefs = include( "client_defs" )
local cellrig = include("gameplay/cellrig")
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

----------------------------------------------------------------
-- Custom Local functions

local function backstabOverlayIndex(sim, cell)
	local room = cell.procgenRoom
	local simRoom = sim._mutableRooms[ room.roomIndex ]
	if not room or not simRoom.backstabState then
		return 0
	else
		return (2 - simRoom.backstabState) * 42 * 2 + 1
	end
	return 0
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
	if rawcell ~= nil and scell ~= nil then
		local orientation = self._boardRig._game:getCamera():getOrientation()

		local idx = 0
		local show = false
		local flags = MOAIGridSpace.TILE_HIDE

		local gfxOptions = self._game:getGfxOptions()
		if gfxOptions.bMainframeMode then
			-- pass
		else
			-- BACKSTAB: Tactical tileset is modified by backstab status of the cell.
			idx = backstabOverlayIndex( self._game.simCore, rawcell )
			show = true
			flags = 0
		end
		local x = (self._x - 1) * 2 + 1
		local y = (self._y - 1) * 2 + 1
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x, y, idx )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x, y, show and MOAIGridSpace.TILE_Y_FLIP or MOAIGridSpace.TILE_HIDE )
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x+1, y, idx )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x+1, y, show and MOAIGridSpace.TILE_XY_FLIP or MOAIGridSpace.TILE_HIDE )
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x, y+1, idx )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x, y+1, show and 0 or MOAIGridSpace.TILE_HIDE )
		self._boardRig._backstab_overlayGrid:getGrid():setTile( x+1, y+1, idx )
		self._boardRig._backstab_overlayGrid:getGrid():setTileFlags( x+1, y+1, show and MOAIGridSpace.TILE_X_FLIP or MOAIGridSpace.TILE_HIDE )
	end
end
