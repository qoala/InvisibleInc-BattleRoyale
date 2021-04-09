
local util = include( "modules/util" )
local astar_handlers = include( "sim/astar_handlers" )

------------------------------------------------------------------------------
-- AI "planned path" search (for planning battle royale distances in the WorldGen stage)
local backstab_plan_handler = util.tcopy(astar_handlers.plan_handler)

function backstab_plan_handler:new(context, unusedFn, options)
	local instance = astar_handlers.plan_handler.new(self, context)

	instance.includeLockedDoors = options and options.includeLockedDoors

	return instance
end

-- Modified copy of plan_handler:getAdjacentNodes. Changes at -- BACKSTAB.
function backstab_plan_handler:getAdjacentNodes( cur_node, goal_cell, closed )
	local result = {}
	local cell = cur_node.location
	local n = nil

	for dx = -1,1 do
		for dy = -1,1 do
			local targetX, targetY = cell.x + dx, cell.y + dy
			local target_lid = self:getNodeLid(targetX, targetY)
			-- BACKSTAB: Pass includeLockedDoors to canPath
			if self:getCell(targetX, targetY) and self._context:canPath(cell.x, cell.y, targetX, targetY, self.includeLockedDoors) and not closed[ target_lid ] then
				n = self:_handleNode( {x=targetX, y=targetY}, cur_node, goal_cell )
				if n then
					table.insert(result, n)
				end
			end
		end
	end

	return result
end


astar_handlers.backstab_plan_handler = backstab_plan_handler
