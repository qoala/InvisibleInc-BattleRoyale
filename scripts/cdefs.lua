local cdefs = include( "client_defs" )

cdefs.BACKSTAB = {}

cdefs.BACKSTAB.OVERLAYTILES =
{
	-- 1008x1008 pixels, tiles are 48x48 pixels
	file = "data/images/backstab/overlaytiles.png",
	tileCount = 21 * 21,
	animTiming =
	{
		{0.00, 1},
		{0.70, 3},
		{0.75, 5},
		{0.80, 7},
		{0.85, 9},
		{0.90, 11},
		{0.95, 13},
		{1.00, 15},
		{1.70, 13},
		{1.75, 11},
		{1.80, 9},
		{1.85, 7},
		{1.90, 5},
		{1.95, 3},
		-- {0.00, 1},
		-- {0.70, 2},
		-- {0.75, 3},
		-- {0.80, 4},
		-- {0.85, 5},
		-- {0.90, 6},
		-- {0.95, 7},
		-- {1.00, 8},
		-- {1.70, 7},
		-- {1.75, 6},
		-- {1.80, 5},
		-- {1.85, 4},
		-- {1.90, 3},
		-- {1.95, 2},
		{2.00, 1},
	},
	sizeParams =
	{
		42,			--width in tiles
		42,			--height in tiles
		24/1008,		--cellWidth
		24/1008,		--cellHeight
		0.5/1008,	--xOffset
		0.5/1008,	--yOffset
		23.5/1008,		--tileWidth
		23.5/1008,		--tileHeight
	},
}
