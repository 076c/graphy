--!optimize 2
--!native

-- Algorithms for Graphy

local Graphy = require("./Graphy")

local Algorithms = {}

-- Removes an element of a table and shifts
-- every element accordingly
local function remove<T>(t: { T }, idx: number?): T?
	idx = idx or #t

	local tableSize = #t

	if idx < 1 or idx > tableSize then
		return nil
	end

	local removed = t[idx]

	for i = idx, tableSize - 1 do
		t[i] = t[i + 1]
	end

	t[tableSize] = nil

	return removed
end

-- Calculates the post order of a graph
function Algorithms.postOrder(graph: Graphy.Graph): { number? }
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
function Algorithms.reversePostOrder(graph: Graphy.Graph): { number? }
	local postOrder = Algorithms.postOrder(graph)
	local reversePostOrder = {}

	for i = #postOrder, 1, -1 do
		reversePostOrder[#reversePostOrder + 1] = postOrder[i]
	end

	return reversePostOrder
end

-- Calculates the immediate dominators of every node
-- https://www.cs.tufts.edu/~nr/cs257/archive/keith-cooper/dom14.pdf
function Algorithms.immediateDominators(graph: Graphy.Graph): { [number]: number }
	local root = graph:getRoot()
	local reversePostOrder = Algorithms.reversePostOrder(graph)

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

	return doms
end

-- Calculates the dominance frontiers
-- https://www.cs.tufts.edu/comp/150FP/archive/keith-cooper/dom14.pdf
function Algorithms.dominanceFrontiers(graph: Graphy.Graph): { [number]: { number } }
	local idom = Algorithms.immediateDominators(graph)
	local df = {}

	for _, node in ipairs(graph:getNodes()) do
		local preds = graph:getPredecessorsOf(node)

		if #preds >= 2 then
			for _, pred in ipairs(preds) do
				local runner = pred

				while runner ~= idom[node] do
					if not df[runner] then
						df[runner] = {}
					end

					df[runner][#df[runner] + 1] = node

					runner = idom[runner]
				end
			end
		end
	end

	return df
end

-- Helper function for A*
local function reconstructPath(cameFrom, current)
	local totalPath = { current }

	while cameFrom[current] ~= nil do
		current = cameFrom[current]

		totalPath[#totalPath + 1] = current
	end

	return totalPath
end

-- Calculates the shortest path between two nodes
-- with a cost function using the A* algorithm
-- This algorithm has been modified to run a little faster
-- and avoid O(n) wherever possible
-- https://en.wikipedia.org/wiki/A*_search_algorithm
function Algorithms.cheapestPathAStar(
	graph: Graphy.Graph,
	start: number,
	goal: number,
	cost: (number) -> number,
	weight: (number, number) -> number
): (boolean, { number }?)
	local inOpenSet = { [start] = true } :: { [number]: boolean }
	local openSet = { start }
	local cameFrom = {}

	local gScore = {}
	local fScore = {}

	gScore[start] = 0
	fScore[start] = cost(start)

	while #openSet > 0 do
		local current
		local currentIdx
		local lowest = math.huge

		for i, node in openSet do
			if fScore[node] < lowest then
				current = node
				currentIdx = i
				lowest = fScore[node]
			end
		end

		if current == goal then
			return true, reconstructPath(cameFrom, current)
		end

		inOpenSet[current] = false
		remove(openSet, currentIdx)

		for _, neighbor in ipairs(graph:getSuccessorsOf(current)) do
			local tentativeGScore = gScore[current] + weight(current, neighbor)

			local neighborGScore = gScore[neighbor] or math.huge

			if tentativeGScore < neighborGScore then
				cameFrom[neighbor] = current

				gScore[neighbor] = tentativeGScore
				fScore[neighbor] = tentativeGScore + cost(neighbor)

				if not inOpenSet[neighbor] then
					openSet[#openSet + 1] = neighbor
					inOpenSet[neighbor] = true
				end
			end
		end
	end

	return false, nil
end

return Algorithms
