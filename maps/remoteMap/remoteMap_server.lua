local args = {...}

--===== OPEN REDNET =====--
for _, side in ipairs(redstone.getSides()) do
	if peripheral.getType(side) == "modem" then
		rednet.open(side)
	end
end

if not rednet.isOpen() then
	printError("could not open rednet")
	return
end

--===== LOAD MAP =====--
if not compactMap then
	if not os.loadAPI("compactMap") then
		error("could not load API: compactMap")
	end
end
local map = compactMap.new(args[1])

--===== SET REDNET PROTOCOL =====--
local MAP_SHARE_PROTOCOL
if args[2] and type(args[2]) == "string" then
	MAP_SHARE_PROTOCOL = "map_share:"..args[2]
else
	MAP_SHARE_PROTOCOL = "map_share:"..fs.getName(args[1])
end

--===== HOST AS SERVER =====--
do
	local host = rednet.lookup(MAP_SHARE_PROTOCOL, "SERVER")
	if host and host ~= os.computerID() then
		printError("server already running for this map share")
		return
	end
end
rednet.host(MAP_SHARE_PROTOCOL, "SERVER")

--===== UTILS =====--
local MESSAGE_TYPE = {
	GET = 0,
	SET = 1,
}
local receivedMessages = {}
local receivedMessageTimeouts = {}

local function isValidCoord(coord)
	return type(coord) == "number" and coord % 1 == 0 and coord >= 0 and coord <= 15
end

local function updateCoord(x, y, z, value)
	local coord = vector.new(x, y, z)
	local currValue = map:get(coord)
	if value == 1 then
		if currValue then
			map:set(coord, math.min(7, currValue + 1))
		else
			map:set(coord, 0)
		end
	elseif value == -1 then
		if currValue then
			if currValue == 0 then
				map:set(coord, nil)
			else
				map:set(coord, currValue - 1)
			end
		end
	end
end

local function updateMap(newData, gX, gY, gZ)
	if type(newData) == "table" then
		local currX, currY
		for x, gridYZ in pairs(newData) do
			if isValidCoord(x) and type(gridYZ) == "table" then
				currX = gX*16 + x
				for y, gridZ in pairs(gridYZ) do
					if isValidCoord(y) and type(gridZ) == "table" then
						currY = gY*16 + y
						for z, value in pairs(gridZ) do
							if isValidCoord(z) then
								updateCoord(currX, currY, gZ*16 + z, value)
							end
						end
					end
				end
			end
		end
		map:save(gX, gY, gZ)
	end
end

local function checkGridCoordFormat(gridCoord)
	if type(gridCoord) == "table" and #gridCoord == 3 then
		for i = 1, 3 do
			local coord = gridCoord[i]
			if type(coord) ~= "number" or coord % 1 ~= 0 then
				return false
			end
		end
		return true
	end
	return false
end

local function newMessage(messageType, messageID, grid, data)
	return {
		type = messageType,
		ID = messageID,
		grid = grid,
		data = data,
	}
end

--===== REPEATED MESSAGE HANDLING =====--
local function clearOldMessages()
	while true do
		local event, timer = os.pullEvent("timer")
		local messageID = receivedMessageTimeouts[timer]
		if messageID then
			receivedMessageTimeouts[timer] = nil
			receivedMessages[messageID] = nil
		end
	end
end

--===== MAIN =====--
local function main()
	while true do
		local senderID, message = rednet.receive(MAP_SHARE_PROTOCOL)
		if type(message) == "table" and checkGridCoordFormat(message.grid) then
			if message.type == MESSAGE_TYPE.GET then
				local gridData = map:getGrid(unpack(message.grid))
				local replyMessage = newMessage(MESSAGE_TYPE.GET, message.ID, message.grid, gridData)
				rednet.send(senderID, replyMessage, MAP_SHARE_PROTOCOL)
			elseif message.type == MESSAGE_TYPE.SET then
				if not receivedMessages[message.ID] then
					updateMap(message.data, unpack(message.grid))
					receivedMessages[message.ID] = true
					receivedMessageTimeouts[os.startTimer(15)] = message.ID
				end
				local replyMessage = newMessage(MESSAGE_TYPE.SET, message.ID, message.grid, true)
				rednet.send(senderID, replyMessage, MAP_SHARE_PROTOCOL)
			end
		end
	end
end

--===== USER INTERFACE =====--
local function control()
	while true do
		local event, key = os.pullEvent("key")
		if key == keys.backspace then
			break
		end
	end
end

parallel.waitForAny(main, clearOldMessages, control)

rednet.unhost(MAP_SHARE_PROTOCOL)