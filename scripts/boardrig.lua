
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local boardrig = include("gameplay/boardrig")

function createBackstabGridAnim(params)
	local animRootCount = util.tcount(params.animRoots)
	local animLengths = {}
	for name,anim in pairs(params.anims) do
		animLengths[name] = util.tcount(anim)
	end

	local remapper = MOAIDeckRemapper.new()
	remapper:reserve(params.maxAnimRoot)

	local anim = MOAIAnim:new()
	anim:reserveLinks(animRootCount)
	for i,animRoot in ipairs(params.animRoots) do
		local curve = MOAIAnimCurve.new()
		curve:reserveKeys(animLengths[animRoot.anim])
		for j,timing in ipairs(params.anims[animRoot.anim]) do
			curve:setKey(j, timing.t, animRoot.root + timing.offset, MOAIEaseType.FLAT)
		end
		anim:setLink(i, curve, remapper, animRoot.root)
	end
	anim:setMode(MOAITimer.LOOP)

	return anim, remapper
end

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

	local anim, remapper = createBackstabGridAnim(params)

	local prop = MOAIProp2D.new()
	prop:setDeck(tileDeck)
	prop:setGrid(grid)
	prop:setRemapper(remapper)
	prop:setLoc(-boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	prop:setPriority(cdefs.BOARD_PRIORITY + 10)  -- Render above floor tiles.
	prop:setDepthTest(false)

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
