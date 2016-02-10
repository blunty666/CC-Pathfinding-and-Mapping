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
			local handle = fs.open(gridPath, "r")
			if handle then
				local grid = handle.readAll()
				handle.close()
				grid = textutils.unserialise(grid)
				if type(grid) == "table" then
					return setGrid(self, gX, gY, gZ, grid)
				end
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
				local handle = fs.open(fs.combine(self.mapDir, gX..","..gY..","..gZ), "w")
				if handle then
					handle.write(textutils.serialise(grid))
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