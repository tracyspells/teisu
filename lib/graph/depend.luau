local types = require(script.Parent.Parent.types)
local evaluate = require(script.Parent.evaluate)

type Node = types.Node

local function depend(child: Node, parent: Node)
	evaluate(parent, false)

	if table.isfrozen(parent.children) or table.isfrozen(child.parents) then
		return
		--External.logError("cannotDepend", nil, nameOf(dependent, "Dependent"), nameOf(dependency, "dependency"))
	end

	child.parents[parent] = true
	parent.children[child] = true
end

return depend
