if not pQueue then
	if not os.loadAPI("pQueue") then
		error("could not load pQueue API")
	end
end

-- a very basic map API used to store node information
local mapMethods = {
	get = function(self, tVector)
		if self.map[tVector.x] and self.map[tVector.x][tVector.y] then
			return self.map[tVector.x][tVector.y][tVector.z]
		end
	end,
	set = function(self, tVector, value)
		if not self.map[tVector.x] then
			self.map[tVector.x] = {}
		end
		if not self.map[tVector.x][tVector.y] then
			self.map[tVector.x][tVector.y] = {}
		end
		self.map[tVector.x][tVector.y][tVector.z] = value
		return self.map[tVector.x][tVector.y][tVector.z]
	end,
	getOrSet = function(self, tVector, value)
		if self.map[tVector.x] and self.map[tVector.x][tVector.y] and self.map[tVector.x][tVector.y][tVector.z] ~= nil then
			return self.map[tVector.x][tVector.y][tVector.z], false
		else
			return self:set(tVector, value), true
		end
	end,
}
local mapMetatable = {__index = mapMethods}

function newMap()
	return setmetatable({map = {}}, mapMetatable)
end

local function makePath(nodes, start, startEnd, goalStart, goal)
	local current, path = startEnd, {}
	while not vectorEquals(current, start) do
		table.insert(path, current)
		current = nodes:get(current)[1]
	end
	current = goalStart
	while not vectorEquals(current, goal) do
		table.insert(path, 1, current)
		current = nodes:get(current)[1]
	end
	table.insert(path, 1, goal)
	return path
end

function vectorEquals(a, b) -- the comparison function used in pQueue
	return a.x == b.x and a.y == b.y and a.z == b.z
end

local posZ = vector.new(0, 0, 1)
local negX = vector.new(-1, 0, 0)
local negZ = vector.new(0, 0, -1)
local posX = vector.new(1, 0, 0)
local posY = vector.new(0, 1, 0)
local negY = vector.new(0, -1, 0)
function adjacent(u)
	return {
		u + posZ,
		u + negX,
		u + negZ,
		u + posX,
		u + posY,
		u + negY,
	}
end
	
function distance(a, b) -- 1-norm/manhattan metric
	return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
end

function compute(distanceFunction, start, goal)
	
	if type(distanceFunction) ~= "function" then
		error("aStar new: distanceFunction must be of type function", 2)
	end
		
	local distanceFunc = distanceFunction -- is this necessary?

	-- node data structure is {parent node, true cost from startNode/goalNode, whether in closed list, search direction this node was found in, whether in open list}
	local nodes = newMap()
	nodes:set(start, {start + vector.new(0, 0, -1), 0, false, true, true})
	nodes:set(goal, {goal + vector.new(0, 0, -1), 0, false, false, true})

	local openStartSet = pQueue.new()
	openStartSet:insert(start, distance(start, goal))
	local openGoalSet = pQueue.new()
	openGoalSet:insert(goal, distance(start, goal))

	local yieldCount = 0
	local activeOpenSet, pendingOpenSet = openStartSet, openGoalSet
	local forwardSearch, lastNode, switch = true, false, false
	
	local current, currNode, parent
	local baseCost
	local newCost
	local nbrNode, newNode
	local preHeuristic

	while not openStartSet:isEmpty() and not openGoalSet:isEmpty() do

		--yield every so often to avoid getting timed out
		yieldCount = yieldCount + 1
		if yieldCount > 200 then
			os.pullEvent(os.queueEvent("yield"))
			yieldCount = 0
		end

		if switch then --switch the search direction
			activeOpenSet, pendingOpenSet = pendingOpenSet, activeOpenSet
			forwardSearch = not forwardSearch
			lastNode = false
		end

		current = activeOpenSet:pop()
		currNode = nodes:get(current)
		parent = current - currNode[1]
			
		currNode[3], currNode[5], switch = true, false, true
			
		for _, neighbour in ipairs(adjacent(current)) do
			
			baseCost = distanceFunc(current, neighbour)
			if baseCost < math.huge then -- if not graph:get(neighbour) then
			
				newCost = currNode[2] + baseCost
			
				nbrNode, newNode = nodes:getOrSet(neighbour, {current, newCost, false, forwardSearch, false})
				if switch and ((not lastNode) or vectorEquals(lastNode, neighbour)) then
					switch = false
				end

				if not newNode then
					if forwardSearch ~= nbrNode[4] then -- nbrNode has been discovered in the opposite search direction
						if nbrNode[3] then -- and is in the closed list so has been expanded already
							return makePath(nodes, start, (forwardSearch and current) or neighbour, (forwardSearch and neighbour) or current, goal)
						end
					elseif newCost < nbrNode[2] then
						if nbrNode[5] then
							activeOpenSet:remove(neighbour, vectorEquals)
							nbrNode[5] = false
						end
						nbrNode[3] = false
					end
				end

				if (newNode or (forwardSearch ~= nbrNode[4] and not nbrNode[5] and not nbrNode[3])) and newCost < math.huge then
					nbrNode[1] = current
					nbrNode[2] = newCost
					nbrNode[4] = currNode[4]
					nbrNode[5] = true
					preHeuristic = distance(neighbour, (forwardSearch and goal) or start)
					activeOpenSet:insert(neighbour, newCost + preHeuristic + 0.0001*(preHeuristic + parent.length(parent:cross(neighbour - current))))
				end
			end
		end
		lastNode = current
	end
	return false
end