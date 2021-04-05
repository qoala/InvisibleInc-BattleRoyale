
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local boardrig = include("gameplay/boardrig")

-- Variation on vanilla createGridProp that renders floor tiles.
-- The overlay grid has a 2x2 of tiles for every floor tile.
function createBackstabGridProp(game, simCore, params)
	local boardWidth, boardHeight = simCore:getBoardSize()

	local grid = MOAIGrid.new()
	grid:initRectGrid(boardWidth*2, boardHeight*2, cdefs.BOARD_TILE_SIZE/2, cdefs.BOARD_TILE_SIZE/2)

	local tileDeck = MOAITileDeck2D.new()
	tileDeck:setTexture(params.file)
	tileDeck:setSize(unpack(params.sizeParams))
	tileDeck:setRect(-0.5, -0.5, 0.5, 0.5)
	tileDeck:setUVRect(-0.5, -0.5, 0.5, 0.5)

	local remapper = MOAIDeckRemapper.new()
	remapper:reserve(boardWidth * boardHeight * 4)

	local prop = MOAIProp2D.new()
	prop:setDeck(tileDeck)
	prop:setGrid(grid)
	prop:setRemapper(remapper)
	prop:setLoc(-boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	prop:setPriority(cdefs.BOARD_PRIORITY + 10)  -- Render above floor tiles.
	prop:setDepthTest(false)


	local curve = MOAIAnimCurve.new()
	local animSize = util.tcount(params.animTiming)
	curve:reserveKeys(animSize)
	for i,timing in ipairs(params.animTiming) do
		curve:setKey(i, timing[1], timing[2], MOAIEaseType.FLAT)
	end
	local anim = MOAIAnim:new()
	anim:reserveLinks(1)
	anim:setLink(1, curve,remapper, 1)
	anim:setMode(MOAITimer.LOOP)
	anim:start()

	prop:forceUpdate()
	return prop, tileDeck, anim
end


local oldInit = boardrig.init
function boardrig:init(layers, levelData, game, ...)
	oldInit(self, layers, levelData, game, ...)

	local simCore = game.simCore
	if simCore:getParams().difficultyOptions.backstab_enabled then
		local overlayGrid, _, overlayAnim = createBackstabGridProp(game, simCore, cdefs.BACKSTAB.OVERLAYTILES)
		layers["floor"]:insertProp(overlayGrid)

		self._backstab_overlayGrid = overlayGrid
		self._backstab_overlayAnim = overlayAnim
	end
end

local oldDestroy = boardrig.destroy
function boardrig:destroy(...)
	if self._backstab_overlayGrid then
		self._backstab_overlayAnim:stop()
		self._layers["floor"]:removeProp(self._backstab_overlayGrid)

		self._backstab_overlayGrid = nil
		self._backstab_overlayAnim = nil
	end

	oldDestroy(self, ...)
end
