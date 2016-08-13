local BIT_MASKS = {
	SET_COORD = bit.blshift(1, 5),
	SET_X_COORD = bit.blshift(1, 4),
	COORD = 15,
	COORD_DATA = bit.blshift(1, 4),
}

local function base256_to_base64(input)
	local output = {}
	for i = 1, #input, 3 do
		table.insert(output, bit.brshift(input[i] or 0, 2))
		table.insert(output, bit.blshift(bit.band(input[i] or 0, 3), 4) + bit.brshift(input[i+1] or 0, 4))
		table.insert(output, bit.blshift(bit.band(input[i+1] or 0, 15), 2) + bit.brshift(input[i+2] or 0, 6))
		table.insert(output, bit.band(input[i+2] or 0, 63))
	end
	return output
end

local function base64_to_base256(input)
	local output = {}
	for i = 1, #input, 4 do
		 table.insert(output, bit.blshift(input[i] or 0, 2) + bit.brshift(input[i+1] or 0, 4))
		 table.insert(output, bit.blshift(bit.band(input[i+1] or 0, 15), 4) + bit.brshift(input[i+2] or 0, 2))
		 table.insert(output, bit.blshift(bit.band(input[i+2] or 0, 3), 6) + (input[i+3] or 0))
	end
	return output
end

local function isValidValue(value)
	return value == nil or value == 0 or value == 1
end

local function toGridCode(tVector)
	return math.floor(tVector.x/16), math.floor(tVector.y/16), math.floor(tVector.z/16), tVector.x % 16, tVector.y % 16, tVector.z % 16
end

local function setGrid(tMap, x, y, z, grid)
	if not tMap.map[x] then
		tMap.map[x] = {}
	end
	if not tMap.map[x][y] then
		tMap.map[x][y] = {}
	end
	tMap.map[x][y][z] = grid
	return tMap.map[x][y][z]
end

local function getGrid(tMap, x, y, z)
	if not tMap.map[x] or not tMap.map[x][y] or not tMap.map[x][y][z] then
		return tMap:load(x, y, z)
	else
		return tMap.map[x][y][z]
	end
end

local mapMethods = {

	getGrid = function(self, tVector, y, z)
		local gX, gY, gZ
		if y and z then
			gX, gY, gZ = tVector, y, z
		else
			gX, gY, gZ = toGridCode(tVector)
		end
		return getGrid(self, gX, gY, gZ)
	end,

	load = function(self, tVector, y, z)
		local gX, gY, gZ
		if y and z then
			gX, gY, gZ = tVector, y, z
		else
			gX, gY, gZ = toGridCode(tVector)
		end
		local gridPath = fs.combine(self.mapDir, gX..","..gY..","..gZ)
		if fs.exists(gridPath) then
			local handle = fs.open(gridPath, "rb")
			if handle then
				local grid = {}
				
				local rawData = {}
				local rawDataByte = handle.read()
				while rawDataByte do
					table.insert(rawData, rawDataByte)
					rawDataByte = handle.read()
				end
				handle.close()
				
				--local data = rawData
				local data = base256_to_base64(rawData)
				
				--load grid data
				local currX, currY, currZ
				local dataByte
				for _, dataByte in ipairs(data) do
					if bit.band(dataByte, BIT_MASKS.SET_COORD) == BIT_MASKS.SET_COORD then
						--we are changing our currX or currY coord
						if bit.band(dataByte, BIT_MASKS.SET_X_COORD) == BIT_MASKS.SET_X_COORD then
							--we are changing our currX coord
							currX = bit.band(dataByte, BIT_MASKS.COORD)
						else
							--we are changing our currY coord
							currY = bit.band(dataByte, BIT_MASKS.COORD)
						end
					else
						--we are setting the value for a proper coord
						currZ = bit.band(dataByte, BIT_MASKS.COORD)
						if currX and currY and currZ then
							if not grid[currX] then
								grid[currX] = {}
							end
							if not grid[currX][currY] then
								grid[currX][currY] = {}
							end
							grid[currX][currY][currZ] = bit.brshift(bit.band(dataByte, BIT_MASKS.COORD_DATA), 4)
						end
					end
				end
				return setGrid(self, gX, gY, gZ, grid)
			end
		end
		return setGrid(self, gX, gY, gZ, {})
	end,

	loadAll = function(self)
		if fs.exists(self.mapDir) and fs.isDir(self.mapDir) then
			for _, gridFile in ipairs(fs.list(self.mapDir)) do
				local _, _, gX, gY, gZ = string.find(gridFile, "(.+)%,(.+)%,(.+)")
				if gX and gY and gX then
					self:load(tonumber(gX), tonumber(gY), tonumber(gZ))
				end
			end
		end
	end,

	save = function(self, tVector, y, z)
		local gX, gY, gZ
		if y and z then
			gX, gY, gZ = tVector, y, z
		else
			gX, gY, gZ = toGridCode(tVector)
		end
		if self.map[gX] and self.map[gX][gY] and self.map[gX][gY][gZ] then
			local grid = self.map[gX][gY][gZ]
			if next(grid) then
				local rawData = {}
				for x, gridYZ in pairs(grid) do
					table.insert(rawData, BIT_MASKS.SET_COORD + BIT_MASKS.SET_X_COORD + x)
					for y, gridZ in pairs(gridYZ) do
						table.insert(rawData, BIT_MASKS.SET_COORD + y)
						for z, coordValue in pairs(gridZ) do
							table.insert(rawData, bit.blshift(coordValue, 4) + z)
						end
					end
				end
				--local data = rawData
				local data = base64_to_base256(rawData)
				local handle = fs.open(fs.combine(self.mapDir, gX..","..gY..","..gZ), "wb")
				if handle then
					for _, dataByte in ipairs(data) do
						handle.write(dataByte)
					end
					handle.close()
				end
			else
				fs.delete(fs.combine(self.mapDir, gX..","..gY..","..gZ))
			end
		end
	end,
	
	saveAll = function(self)
		for gX, YZmap in pairs(self.map) do
			for gY, Zmap in pairs(YZmap) do
				for gZ, grid in pairs(Zmap) do
					self:save(gX, gY, gZ)
				end
			end
		end
	end,

	get = function(self, tVector)
		local gX, gY, gZ, pX, pY, pZ = toGridCode(tVector)
		local grid = getGrid(self, gX, gY, gZ)
		if grid[pX] and grid[pX][pY] then
			return grid[pX][pY][pZ]
		end
	end,

	set = function(self, tVector, value)
		if not isValidValue(value) then
			--should we throw an error or use a default value?
			error("set: value is not valid")
		end
		local gX, gY, gZ, pX, pY, pZ = toGridCode(tVector)
		local grid = getGrid(self, gX, gY, gZ)
		if not grid[pX] then
			grid[pX] = {}
		end
		if not grid[pX][pY] then
			grid[pX][pY] = {}
		end
		grid[pX][pY][pZ] = value
		return grid[pX][pY][pZ]
	end,

	getOrSet = function(self, tVector, value)
		local gX, gY, gZ, pX, pY, pZ = toGridCode(tVector)
		local grid = getGrid(self, gX, gY, gZ)
		if grid[pX] and grid[pX][pY] and grid[pX][pY][pZ] then
			return grid[pX][pY][pZ], false
		else
			if not isValidValue(value) then
				--should we throw an error or use a default value?
				error("getOrSet: value is not valid")
			end
			if not grid[pX] then
				grid[pX] = {}
			end
			if not grid[pX][pY] then
				grid[pX][pY] = {}
			end
			grid[pX][pY][pZ] = value
			return grid[pX][pY][pZ], true
		end
	end,

}
local mapMetatable = {__index = mapMethods}

function new(mapDir)
	local tMap = {}
	if type(mapDir) == "string" then
		if not fs.exists(mapDir) then
			fs.makeDir(mapDir)
		elseif not fs.isDir(mapDir) then
			error("new: not a valid directory")
		end
		tMap.mapDir = mapDir
	else
		error("new: directory must be string")
	end
	tMap.map = {}
	setmetatable(tMap, mapMetatable)
	return tMap
end