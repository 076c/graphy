# Graphy

Graphy is a highly performant graph module designed for Roblox to allow developers to optimize their workflows.

# Why

Many tasks on Roblox (whether it be strict pathfinding or heavy mathematics) often require some sort of graph module. Graph modules tend to either turn
out imperformant or simply weak, but this project aims to change that.

# Design

Graphy is supposed to be a **stable** graph and this is how the main graph works. Instead of relying on values and value cloning, each `:addNode()` call
returns an index number (which can be used for various things). Creating a graph with the nodes of type `nil` causes undefined behaviour. Modifying any internal structure or tables returned by `getNodes`, `getPredecessorsOf` and `getSucessorsOf` all cause undefined behaviour aswell.
