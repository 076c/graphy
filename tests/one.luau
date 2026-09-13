local Graphy = require("./../src/Graphy")

local graph = Graphy.new()

graph:setRoot(1)
graph:addNode("Hello world!") -- 1
graph:addNode("*never prints*", 1) -- 1 -> 2

assert(#graph:getSuccessorsOf(1) == 1)
assert(#graph:getPredecessorsOf(2) == 1)

for _, pred in ipairs(graph:getPredecessorsOf(2)) do
	print(graph:evaluateIndice(pred))
end
