--!native
--!optimize 2

-- Graphy
-- A performant graph library designed for Roblox

-- Helper functions

-- Inserts into a table and creates it, if non-existant
local function createAndInsert<T, I>(t: { [I]: T }?, v: T)
	if not t then
		t = {}
	end

	table.insert(t, v)

	return t
end

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

-- Escapes a string into double-quotes
local function escapeStr(str: string)
	local formatted = ""

	for i = 1, #str do
		local char = str:sub(i, i)

		if char == "\n" then
			formatted ..= "\\n"
		elseif char == "\r" then
			formatted ..= "\\r"
		elseif char == "\t" then
			formatted ..= "\\t"
		elseif char == '"' then
			formatted ..= '\\"'
		elseif char >= 32 and char <= 126 then
			formatted ..= char
		else
			formatted ..= "\\" .. char:byte(1, 1)
		end
	end

	return '"' .. formatted .. '"'
end

local Graphy = {}

export type Graph = typeof(Graphy.new())

-- Creates a new graph object
function Graphy.new<T>(optionalGraphName: string?)
	local self = {}

	-- The name of the graph
	self._graphName = optionalGraphName or "Unnamed graph"

	-- The list of nodes in the graph
	self._nodes = {} :: { T }

	-- The list of node indices
	self._indices = {} :: { number? }

	-- The root node of the graph
	-- Should only be changed using `:setRoot()`
	self._root = nil

	-- The list of successors for each node N
	self._succs = {}

	-- The list of predecessors for each node N
	self._preds = {}

	self._neighbors = {}

	-- Changes the root of the graph to the first argument
	function self:setRoot(root: number)
		self._root = root
	end

	-- Returns the graph's root
	function self:getRoot(): number?
		return self._root
	end

	-- Adds a node to the graph and appends it to the back,
	-- with an optional predecessor
	function self:addNode(node: T, optionalPredecessor: number?): number
		local nodeIdx = #self._nodes + 1

		self._nodes[nodeIdx] = node
		self._indices[#self._indices + 1] = nodeIdx

		self._preds[nodeIdx] = {}
		self._succs[nodeIdx] = {}
		self._neighbors[nodeIdx] = {}

		-- Parent the node to the predecessor
		if optionalPredecessor then
			if not self._nodes[optionalPredecessor] then
				warn(`Node {optionalPredecessor} doesn't exist.`)
			end

			self._preds[nodeIdx] = createAndInsert(self._preds[nodeIdx], optionalPredecessor)
			self._succs[optionalPredecessor] = createAndInsert(self._succs[optionalPredecessor], nodeIdx)
			self._neighbors[nodeIdx] = createAndInsert(self._neighbors[nodeIdx], optionalPredecessor)
		end

		return nodeIdx
	end

	-- Removes / terminates every outgoing and incoming connection
	-- related to that node
	function self:removeNodeConnections(id: number)
		self._preds[id] = nil
		self._succs[id] = nil

		-- Terminate every connection
		-- by iterating the connection lists
		for i, preds in pairs(self._preds) do
			for j = #preds, 1, -1 do
				if preds[j] == id then
					-- Don't do `preds[j] = nil` because that
					-- leaves a nil space in the array and breaks
					-- numeric iterators
					remove(preds, j)
				end
			end
		end

		for i, succs in pairs(self._succs) do
			for j = #succs, 1, -1 do
				if succs[j] == id then
					-- Don't do `succs[j] = nil` because that
					-- leaves a nil space in the array and breaks
					-- numeric iterators
					remove(succs, j)
				end
			end
		end
	end

	-- Connects two nodes together and creates an outgoing connection
	-- n1 is the 'predecessor' and n2 is the 'successor'
	function self:addConnection(n1: number, n2: number)
		self._preds[n2] = createAndInsert(self._preds[n2], n1)
		self._succs[n1] = createAndInsert(self._succs[n1], n2)
	end

	-- Removes a node from the nodes list and returns
	-- whether the node exists and the value
	function self:removeNode(id: number): (boolean, T)
		local value = self._nodes[id]

		if not value then
			return false, nil
		end

		self._nodes[id] = nil

		-- Clear every connection
		self:removeNodeConnections(id)

		return true, value
	end

	-- Returns the predecessors of a node
	function self:getPredecessorsOf(id: number): { number? }
		return self._preds[id] or {}
	end

	-- Returns the successors of a node
	function self:getSuccessorsOf(id: number): { number? }
		return self._succs[id] or {}
	end

	-- Returns every neighbor of a node regardless
	-- of their direction
	function self:getNeighborsOf(id: number): { number? }
		return self._neigbors[id] or {}
	end

	-- Returns every node
	function self:getNodes(): { T? }
		return self._nodes
	end

	-- Returns every node indice
	function self:getNodeIndices(): { number? }
		return self._indices
	end

	-- Returns a filtered version of the nodes
	-- which passed the predicate
	function self:filter(predicate: (T) -> boolean): { T? }
		local passed = {}

		for _, node in ipairs(self._nodes) do
			if predicate(node) then
				passed[#passed + 1] = node
			end
		end

		return passed
	end

	-- Removes every node which is not reachable
	-- Rule: n where preds(n) <= 0 & succs(n) <= 0 or no connections
	function self:removeUnreachableNodes()
		local entries: { [number]: boolean } = {}

		local function search(n)
			entries[n] = true

			for _, succ in ipairs(self:getSuccessorsOf(n)) do
				search(succ)
			end
		end

		search(self:getRoot())

		for _, node in ipairs(self:getNodes()) do
			if not entries[node] then
				self:removeNode(node)
			end
		end
	end

	-- Evaluates the indice to the node value
	function self:evaluateIndice(id: number): T?
		return self._nodes[id]
	end

	-- Converts the graph into the DOT format
	function self:serializeToDot()
		if #self._nodes == 0 then
			return "digraph " .. self._graphName .. " {}"
		end

		local output = "digraph " .. self._graphName .. " {\n"

		for _, node in ipairs(self:getNodeIndices()) do
			output ..= escapeStr(tostring(node)) .. '[label="' .. escapeStr(tostring(self:evaluateIndice(node))) .. '"]\n'

			for _, succ in ipairs(self:getSuccessorsOf(node)) do
				output ..= escapeStr(tostring(node)) .. " -> " .. escapeStr(tostring(succ)) .. "\n"
			end
		end

		return output .. "}"
	end

	return self
end

return Graphy
