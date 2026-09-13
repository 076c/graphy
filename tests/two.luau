local Graphy = require("./../src/Graphy")
local Algorithms = require("./../src/Algorithms")

local map = {
	{ 0, 0, 0, 0, 0, 0 },
	{ 0, 1, 1, 0, 0, 0 },
	{ 0, 1, 1, 0, 1, 0 },
	{ 0, 1, 1, 0, 1, 0 },
	{ 0, 0, 0, 1, 1, 0 },
	{ 0, 0, 0, 0, 0, 0 },
}

local start = { 1, 1 }
local goal = { 4, 6 }

local width = #map[1]

local function positionToId(x, y)
	return (y - 1) * width + x
end

local function idToPosition(id)
	local y = math.floor((id - 1) / width) + 1
	local x = (id - 1) % width + 1
	return x, y
end

local graph = Graphy.new()

local nodes = {}

for y, row in ipairs(map) do
	for x, value in ipairs(row) do
		if value == 0 then
			nodes[positionToId(x, y)] = graph:addNode(positionToId(x, y))
		end
	end
end

for y, row in ipairs(map) do
	for x, value in ipairs(row) do
		if value == 0 then
			local node = nodes[positionToId(x, y)]

			for _, direction in ipairs({
				{ 1, 0 },
				{ -1, 0 },
				{ 0, 1 },
				{ 0, -1 },
			}) do
				local nx = x + direction[1]
				local ny = y + direction[2]

				if map[ny] and map[ny][nx] == 0 then
					local neighbor = nodes[positionToId(nx, ny)]

					graph:addConnection(node, neighbor)
				end
			end
		end
	end
end

local startNode = nodes[positionToId(start[1], start[2])]
local goalNode = nodes[positionToId(goal[1], goal[2])]

local success, path = Algorithms.cheapestPathAStar(graph, startNode, goalNode, function(node)
	local x, y = idToPosition(graph:evaluateIndice(node))
	return math.abs(x - goal[1]) + math.abs(y - goal[2])
end, function()
	return 1
end)

print("Success:", success)

if path then
	for _, node in path do
		local x, y = idToPosition(graph:evaluateIndice(node))
		print(`({x}, {y})`)
	end
end
