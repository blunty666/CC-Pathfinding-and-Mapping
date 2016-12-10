local tArgs = {...}

-- FIND AREA BOUNDARIES
local minX, minY, minZ = unpack(tArgs, 2, 4)
minX, minY, minZ = tonumber(minX), tonumber(minY), tonumber(minZ)
local maxX, maxY, maxZ = unpack(tArgs, 5, 7)
maxX, maxY, maxZ = tonumber(maxX), tonumber(maxY), tonumber(maxZ)
local function isInteger(var)
	return type(var) == "number" and math.floor(var) == var
end
if not isInteger(minX) then printError("minX must be integer") return end
if not isInteger(minY) then printError("minX must be integer") return end
if not isInteger(minZ) then printError("minX must be integer") return end
if not isInteger(maxX) then printError("maxX must be integer") return end
if not isInteger(maxY) then printError("maxY must be integer") return end
if not isInteger(maxZ) then printError("maxZ must be integer") return end
if minX > maxX then minX, maxX = maxX, minX end
if minY > maxY then minY, maxY = maxY, minY end
if minZ > maxZ then minZ, maxZ = maxZ, minZ end

-- LOAD STARNAV API
if not starNav then
	if not os.loadAPI("starNav") then
		error("could not load starNav API")
	end
end

-- OPEN REDNET
for _, side in ipairs({"left", "right"}) do
	if peripheral.getType(side) == "modem" then
		rednet.open(side)
	end
end
if not rednet.isOpen() then
	printError("Could not open rednet")
	return
end

-- SET STARNAV MAP
local mapName = tArgs[1]
if type(mapName) ~= "string" then
	printError("mapName must be string")
	return
end
starNav.setMap(mapName)

local exit = false
local returning = false

local function main()
	local startX, startY, startZ = gps.locate(1)
	while turtle.getFuelLevel() > 0 and not exit do
		local x = math.random(minX, maxX)
		local y = math.random(minY, maxY)
		local z = math.random(minZ, maxZ)
		starNav.goto(x, y, z)
	end
	returning = true
	starNav.goto(startX, startY, startZ)
end

local function control()
	while true do
		local senderID, message = rednet.receive("explore:return_to_base")
		if not exit and not returning then
			starNav.stop()
			exit = true
		end
	end
end

parallel.waitForAny(main, control)
