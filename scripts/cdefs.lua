local cdefs = include( "client_defs" )

cdefs.BACKSTAB = {}

cdefs.BACKSTAB.OVERLAYTILES =
{
	-- 384x216 pixels, tiles are 24x24 pixels
	file = "data/images/backstab/overlaytiles.png",
	animTiming =
	{
		{0.00, 1},
		{0.70, 2},
		{0.75, 3},
		{0.80, 4},
		{0.85, 5},
		{0.90, 6},
		{0.95, 7},
		{1.00, 8},
		{1.70, 7},
		{1.75, 6},
		{1.80, 5},
		{1.85, 4},
		{1.90, 3},
		{1.95, 2},
		{2.00, 1},
	},
	sizeParams =
	{
		16,			--width in tiles
		9,			--height in tiles
		24/384,		--cellWidth
		24/216,		--cellHeight
		0.5/384,	--xOffset
		0.5/216,	--yOffset
		23/384,	--tileWidth
		23/216,	--tileHeight
	},
}
cdefs.BACKSTAB.OVERLAY =
{
	-- Tactical Overview tiles
	BLUE_CELL = 1,
	YELLOW_CELL = 49,
	RED_CELL = 97,
}
