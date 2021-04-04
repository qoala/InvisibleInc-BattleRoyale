
local aiplayer = include( "sim/aiplayer" )


local oldOnEndTurn = aiplayer.onEndTurn

function aiplayer:onEndTurn(sim, ...)
	oldOnEndTurn(self, sim, ...)

	if sim:getParams().difficultyOptions.backstab_enabled and sim:getCurrentPlayer() == self then
		sim:backstab_onEndTurn()
	end
end
