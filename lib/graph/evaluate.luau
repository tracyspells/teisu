local types = require(script.Parent.Parent.types)

type Node = types.Node

local function evaluate(node: Node, forceComputation: boolean): boolean
    if node.state == "busy" then
        error("infinite loop", 0) 
        return false
    end

    local firstEvaluation = node.version == 0
    local isDirty = node.state == "dirty"

    if firstEvaluation or isDirty or forceComputation then
        local needsComputation = firstEvaluation or forceComputation

        if not needsComputation then
            for parent in node.parents do
                evaluate(parent, false)

                if parent.version > node.version then
                    needsComputation = true
                    break
                end
            end
        end

        local meaningfullyChanged = false

        if needsComputation then
            for parent in node.parents do
                parent.children[node] = nil
                node.parents[parent] = nil
            end

            node.state = "busy"
            meaningfullyChanged = node:_evaluate() or firstEvaluation
        end

        if meaningfullyChanged then
            node.version += 1
        end
        node.state = "clean"

        return meaningfullyChanged
    end

    return false
end

return evaluate
