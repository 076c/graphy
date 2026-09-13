--!optimize 2
--!native

-- Dominator algorithms for Graphy

local Graphy = require("./Graphy")

local Dominators = {}

-- Calculates the post order of a graph
function Dominators.postOrder(graph: Graphy.Graph): { number? }
	local root = graph:getRoot()

	if not root then
		error("Graph does not have a root.")
	end

	local visited = {} :: { [number]: boolean }
	local order = {} :: { number }

	local function dfs(id: number)
		if visited[id] then
			return
		end

		visited[id] = true

		for _, succ in ipairs(graph:getSuccessorsOf(id)) do
			dfs(succ)
		end

		order[#order + 1] = id
	end

	dfs(root)

	return order
end

-- Calculates the post order in reverse
function Dominators.reversePostOrder(graph: Graphy.Graph): { number? }
	local postOrder = Dominators.postOrder(graph)
	local reversePostOrder = {}

	for i = #postOrder, 1, -1 do
		reversePostOrder[#reversePostOrder + 1] = postOrder[i]
	end

	return reversePostOrder
end

-- Calculates the immediate dominators of every node
-- https://www.cs.tufts.edu/~nr/cs257/archive/keith-cooper/dom14.pdf
function Dominators.immediateDominators(graph: Graphy.Graph)
	local root = graph:getRoot()
	local reversePostOrder = Dominators.reversePostOrder(graph)

	local doms = {}
	local rpo = {}

	for i, node in ipairs(reversePostOrder) do
		rpo[node] = i
	end

	local function intersect(node1, node2): number
		local finger1 = node1
		local finger2 = node2

		while finger1 ~= finger2 do
			while rpo[finger1] < rpo[finger2] do
				finger1 = doms[finger1]
			end

			while rpo[finger2] < rpo[finger1] do
				finger2 = doms[finger2]
			end
		end

		return finger1
	end

	-- Pre-initialization step of the `doms` list is not needed

	doms[root] = root

	local changed = false

	repeat
		changed = false

		for _, node in ipairs(reversePostOrder) do
			if node == root then
				continue
			end

			local preds = graph:getPredecessorsOf(node)
			local newIdom: number? = nil

			for _, pred in ipairs(preds) do
				if doms[pred] ~= nil then
					newIdom = pred
					break
				end
			end

			if newIdom == nil then
				continue
			end

			for _, pred in ipairs(preds) do
				if pred ~= newIdom and doms[pred] ~= nil then
					newIdom = intersect(pred, newIdom)
				end
			end

			if doms[node] ~= newIdom then
				doms[node] = newIdom
				changed = true
			end
		end
	until changed == false
end
