
local cdefs = include( "client_defs" )
local boardrig = include("gameplay/boardrig")

-- Variation on vanilla createGridProp that renders floor tiles.
function createBackstabGridProp(game, simCore, params)
	local boardWidth, boardHeight = simCore:getBoardSize()

	local grid = MOAIGrid.new()
	grid:initRectGrid(boardWidth, boardHeight, cdefs.BOARD_TILE_SIZE, cdefs.BOARD_TILE_SIZE)

	local tileDeck = MOAITileDeck2D.new()
	local prop = MOAIProp2D.new()

	tileDeck:setTexture(params.file)
	tileDeck:setSize(unpack(params))
	tileDeck:setRect(-0.5, -0.5, 0.5, 0.5)
	tileDeck:setUVRect(-0.5, -0.5, 0.5, 0.5)

	prop:setDeck(tileDeck)
	prop:setGrid(grid)
	prop:setLoc(-boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	prop:setPriority(10)  -- Render above floor tiles and floor prop anims.
	prop:setDepthTest(false)

	prop:forceUpdate()
	return prop
end


local oldInit = boardrig.init
function boardrig:init(layers, levelData, game, ...)
	oldInit(self, layers, levelData, game, ...)

	local simCore = game.simCore
	if simCore:getParams().difficultyOptions.backstab_enabled then
		local overlayGrid = createBackstabGridProp(game, simCore, cdefs.BACKSTAB.OVERLAYTILES_PARAMS)
		layers["floor"]:insertProp(overlayGrid)

		self._backstab_overlayGrid = overlayGrid
	end
end
