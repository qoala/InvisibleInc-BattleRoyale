local cdefs = include( "client_defs" )

cdefs.BACKSTAB = {}

cdefs.BACKSTAB.OVERLAYTILES =
{
	-- 384x216 pixels, tiles are 24x24 pixels
	file = "data/images/backstab/overlaytiles.png",
	-- Tile indices corresponding to the start of an animation
	animRoots =
	{
		{root=1, anim="TACTICAL"},
		{root=49, anim="TACTICAL"},
		{root=97, anim="TACTICAL"},
	},
	maxAnimRoot = 97,
	-- Time values paired with an offset to apply to each animation root index.
	anims =
	{
		TACTICAL =
		{
			{t=0.00, offset=0},
			{t=0.70, offset=1},
			{t=0.75, offset=2},
			{t=0.80, offset=3},
			{t=0.85, offset=4},
			{t=0.90, offset=5},
			{t=0.95, offset=6},
			{t=1.00, offset=7},
			{t=1.70, offset=6},
			{t=1.75, offset=5},
			{t=1.80, offset=4},
			{t=1.85, offset=3},
			{t=1.90, offset=2},
			{t=1.95, offset=1},
			{t=2.00, offset=0},
		},
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
