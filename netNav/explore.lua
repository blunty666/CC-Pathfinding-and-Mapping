local tArgs = {...}

-- CONSTANTS
local REDNET_PROTOCOL = "NET_NAV:CONTROL"

-- VARIABLES
local minX, minY, minZ
local maxX, maxY, maxZ
local mapName
local states
local state, arguments
local idle
local startX, startY, startZ

-- CHECK MAP NAME
mapName = tArgs[1]
if type(mapName) ~= "string" then
	printError("mapName must be string")
	return
end

-- FIND AREA BOUNDARIES
minX, minY, minZ = unpack(tArgs, 2, 4)
minX, minY, minZ = tonumber(minX), tonumber(minY), tonumber(minZ)
maxX, maxY, maxZ = unpack(tArgs, 5, 7)
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

-- LOAD NETNAV API
if not netNav then
	if not os.loadAPI("netNav") then
		error("could not load netNav API")
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

-- SET NETNAV MAP
netNav.setMap(mapName, 15)

-- SET UP STATES
local states = {
	EXPLORE = function()
		local x = math.random(minX, maxX)
		local y = math.random(minY, maxY)
		local z = math.random(minZ, maxZ)
		netNav.goto(x, y, z)
	end,
	RETURN = function()
		netNav.goto(startX, startY, startZ)
		state = "IDLE"
	end,
	FOLLOW = function(xPos, yPos, zPos)
		netNav.goto(xPos, yPos, zPos)
		state = "IDLE"
	end,
	IDLE = function()
		idle = true
		while idle do
			os.pullEvent()
		end
	end,
}

-- FIND START POSITION
startX, startY, startZ = gps.locate(1)
-- check coords valid

-- STATUS UPDATE FUNCTION
local function sendStatus(senderID)
	local status = {
		mapName,
		senderID,
		"PONG",
		{netNav.getPosition()},
		state,
		arguments,
	}
	if senderID == -1 then
		rednet.broadcast(status, REDNET_PROTOCOL)
	else
		rednet.send(senderID, status, REDNET_PROTOCOL)
	end
end

-- DEFINE CONTROL ROUTINE
local function control()
	while true do
		local senderID, message = rednet.receive(REDNET_PROTOCOL)
		if type(message) == "table" and message[1] == mapName then
			local sentTo = message[2]
			if sentTo == os.computerID() or sentTo == -1 then
				local request = message[3]
				if request == "PING" then
					sendStatus(senderID)
				elseif states[request] then
					state, arguments = request, message[4]
					netNav.stop()
					idle = false
				end
			end
		end
	end
end

-- DEFINE MAIN ROUTINE
local function main()
	state, arguments = "EXPLORE", {}
	while true do
		sendStatus(-1)
		if states[state] then
			states[state](unpack(arguments))
		end
	end
end

parallel.waitForAny(control, main)
