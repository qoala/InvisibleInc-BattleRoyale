local util = include( "modules/util" )
local cdefs = include( "client_defs" )


local oldLeveltiles = nil

local function patchLeveltiles()
	cdefs.LEVELTILES_PARAMS =
	{
		file = "data/images/backstab/leveltiles.png",
		21,			--width in tiles
		21,			--height in tiles
		48/1008,		--cellWidth
		48/1008,		--cellHeight
		0.5/1008,	--xOffset
		0.5/1008,	--yOffset
		47/1008,		--tileWidth
		47/1008,		--tileHeight
	}
end

local function resetLeveltiles()
	if oldLeveltiles then
		cdefs.LEVELTILES_PARAMS = util.tcopy(oldLeveltiles)
	else
		-- First reset, record the original value
		oldLeveltiles = util.tcopy(cdefs.LEVELTILES_PARAMS)
	end
end

return {
	patchLeveltiles = patchLeveltiles,
	resetLeveltiles = resetLeveltiles,
}
