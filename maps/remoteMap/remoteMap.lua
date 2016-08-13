local REDNET_TIMEOUT = 1

local MESSAGE_TYPE = {
	GET = 0,
	SET = 1,
}

local function newMessage(messageType, grid, data)
	return {
		type = messageType,
		ID = math.random(0, 2^30),
		grid = grid,
		data = data,
	}
end

local function sendAndWaitForResponse(recipientID, message, protocol)
	rednet.send(recipientID, message, protocol)
	local attemptNumber = 1
	while true do
		local senderID, reply = rednet.receive(protocol, REDNET_TIMEOUT)
		if senderID == recipientID and type(reply) == "table" and reply.type == message.type and reply.ID == message.ID then
			return reply.data
		elseif not senderID then
			if attemptNumber < 3 then
				rednet.send(recipientID, message, protocol)
				attemptNumber = attemptNumber + 1
			else
				return false
			end
		end
	end
end

local function isValidValue(value)
	return value == nil or value == -1 or value == 1
end

local function toGridCode(tVector)
	return math.floor(tVector.x/16), math.floor(tVector.y/16), math.floor(tVector.z/16), tVector.x % 16, tVector.y % 16, tVector.z % 16
end

local function getRemoteGrid(tMap, x, y, z)
	if not tMap.remoteGrids[x] or not tMap.remoteGrids[x][y] or not tMap.remoteGrids[x][y][z] then
		local message = newMessage(MESSAGE_TYPE.GET, {x, y, z}, nil)
		local remoteGrid = sendAndWaitForResponse(tMap.serverID, message, tMap.protocol) or {}
		tMap.remoteGridsAge[x..","..y..","..z] = os.clock()
		if not tMap.remoteGrids[x] then
			tMap.remoteGrids[x] = {}
		end
		if not tMap.remoteGrids[x][y] then
			tMap.remoteGrids[x][y] = {}
		end
		tMap.remoteGrids[x][y][z] = remoteGrid
		return remoteGrid
	else
		return tMap.remoteGrids[x][y][z]
	end
end

local function getUpdateGrid(tMap, x, y, z)
	if not tMap.updateGrids[x] or not tMap.updateGrids[x][y] or not tMap.updateGrids[x][y][z] then
		local updateGrid = {}
		if not tMap.updateGrids[x] then
			tMap.updateGrids[x] = {}
		end
		if not tMap.updateGrids[x][y] then
			tMap.updateGrids[x][y] = {}
		end
		tMap.updateGrids[x][y][z] = updateGrid
		return updateGrid
	else
		return tMap.updateGrids[x][y][z]
	end
end

local remoteMapMethods = {
	get = function(self, coord)
		local gX, gY, gZ, pX, pY, pZ = toGridCode(coord)
		local grid = getRemoteGrid(self, gX, gY, gZ)
		if grid[pX] and grid[pX][pY] then
			return grid[pX][pY][pZ]
		end
	end,

	set = function(self, coord, value)
		if not isValidValue(value) then
			--should we throw an error or use a default value?
			error("remoteMap set: value is not valid", 2)
		end
		local gX, gY, gZ, pX, pY, pZ = toGridCode(coord)
		local grid = getUpdateGrid(self, gX, gY, gZ)
		if not grid[pX] then
			grid[pX] = {}
		end
		if not grid[pX][pY] then
			grid[pX][pY] = {}
		end
		grid[pX][pY][pZ] = value
	end,

	check = function(self)
		local time = os.clock()
		local newRemoteGridsAge = {}
		for gridCode, gridAge in pairs(self.remoteGridsAge) do
			if time - gridAge >= self.timeout then
				local x, y, z = string.match(gridCode, "([-]?%d+),([-]?%d+),([-]?%d+)")
				x, y, z = tonumber(x), tonumber(y), tonumber(z)
				if x and y and z then
					if self.remoteGrids[x] and self.remoteGrids[x][y] then
						self.remoteGrids[x][y][z] = nil
					end
				end
			else
				newRemoteGridsAge[gridCode] = gridAge
			end
		end
		local newUpdateGridsAge = {}
		for gridCode, gridAge in pairs(self.updateGridsAge) do
			if time - gridAge >= self.timeout then
				-- remove grid from updateGrids ???
			else
				newUpdateGridsAge[gridCode] = gridAge
			end
		end
		self.remoteGridsAge = newRemoteGridsAge
		self.updateGridsAge = newUpdateGridsAge
	end,

	pushUpdates = function(self, ignoreTimeout)
		local newUpdateGrids = {}
		for gX, YZmap in pairs(self.updateGrids) do
			newUpdateGrids[gX] = {}
			for gY, Zmap in pairs(YZmap) do
				newUpdateGrids[gX][gY] = {}
				for gZ, grid in pairs(Zmap) do
					local gridCode = gX..","..gY..","..gZ
					if next(grid) then
						if ignoreTimeout == true or (not self.updateGridsAge[gridCode]) or os.clock() - self.updateGridsAge[gridCode] >= self.timeout then
							local message = newMessage(MESSAGE_TYPE.SET, {gX, gY, gZ}, grid)
							local response = sendAndWaitForResponse(self.serverID, message, self.protocol)
							if response == true then
								self.updateGridsAge[gridCode] = os.clock()
							else
								newUpdateGrids[gX][gY][gZ] = grid
							end
						else
							newUpdateGrids[gX][gY][gZ] = grid
						end
					end
				end
			end
		end
		self.updateGrids = newUpdateGrids
	end,
}
local remoteMapMetatable = {__index = remoteMapMethods}

function new(mapName, timeout)
	if type(mapName) ~= "string" then
		error("mapName must be string")
	end
	if type(timeout) ~= "number" or timeout < 0 then
		error("timeout must be positive number")
	end
	
	local protocol = "map_share:"..mapName
	
	local serverID = rednet.lookup(protocol, "SERVER")
	if not serverID then
		error("could not find map share server")
	end
	
	local remoteMap = {
		mapName = mapName,
		protocol = protocol,
		serverID = serverID,
		timeout = timeout,
		remoteGrids = {},
		remoteGridsAge = {},
		updateGrids = {},
		updateGridsAge = {},
	}
	return setmetatable(remoteMap, remoteMapMetatable)
end