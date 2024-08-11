-- Credit to Elttob: https://github.com/dphfox/Fusion/blob/push-pull-execution/src/Graph/castToGraph.luau

local types = require(script.Parent.Parent.types)

local function castToNode(target: any): types.Node?
	if
		typeof(target) == "table"
		and typeof(target.state) == "string"
		and typeof(target.timeliness) == "string"
		and typeof(target.children) == "table"
		and typeof(target.parents) == "table"
	then
		return target
	else
		return nil
	end
end

return castToNode
