local cdefs = include( "client_defs" )

cdefs.BACKSTAB = {}

cdefs.BACKSTAB.OVERLAYTILES_PARAMS = {
	-- 1008x1008 pixels, tiles are 48x48 pixels
	file = "data/images/backstab/overlaytiles.png",
	21,			--width in tiles
	21,			--height in tiles
	48/1008,		--cellWidth
	48/1008,		--cellHeight
	0.5/1008,	--xOffset
	0.5/1008,	--yOffset
	47/1008,		--tileWidth
	47/1008,		--tileHeight
}
