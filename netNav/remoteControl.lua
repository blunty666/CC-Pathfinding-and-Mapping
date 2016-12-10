local tArgs = {...}

-- CONSTANTS
local REDNET_PROTOCOL = "NET_NAV:CONTROL"

-- VARIABLES
local mapName
local listWidth, listHeight
local buttonInstance
local turtleList
local selectedTurtle
local setSelectedTurtle
local turtleData
local guiOffset
local mainTerm

-- CHECK MAP NAME
mapName = tArgs[1]
if type(mapName) ~= "string" then
	printError("mapName must be string")
	return
end

-- LOAD BUTTON_HANDLER API
if not buttonHandler then
	if not os.loadAPI("buttonHandler") then
		error("could not load buttonHandler API")
	end
end

-- OPEN REDNET
for _, side in ipairs(redstone.getSides()) do
	if peripheral.getType(side) == "modem" then
		rednet.open(side)
	end
end
if not rednet.isOpen() then
	printError("Could not open rednet")
	return
end

-- DEFINE REDNET METHODS
local function newPacket(senderID, request, arguments)
	return {
		mapName,
		senderID,
		request,
		arguments,
	}
end

local function sendPacket(packet)
	if packet[2] == -1 then
		rednet.broadcast(packet, REDNET_PROTOCOL)
	else
		rednet.send(packet[2], packet, REDNET_PROTOCOL)
	end
end

local function sendPingPacket(sendTo)
	sendPacket(newPacket(sendTo, "PING"))
end

local function sendExplorePacket(sendTo)
	sendPacket(newPacket(sendTo, "EXPLORE", {}))
end

local function sendReturnPacket(sendTo)
	sendPacket(newPacket(sendTo, "RETURN", {}))
end

local function sendFollowPacket(sendTo, position)
	sendPacket(newPacket(sendTo, "FOLLOW", position))
end

local function sendIdlePacket(sendTo)
	sendPacket(newPacket(sendTo, "IDLE", {}))
end

-- SET UP GUI
local function createListValue(turtleID, status)
	local value = turtleID..string.rep(" ", math.max(0, 4 - #tostring(turtleID)))
	value = value..string.rep(" ", math.max(0, 8 - #status))..status
	return value
end

do
	term.setBackgroundColour(colours.cyan)
	term.setTextColour(colours.white)
	term.clear()

	local width, height = term.getSize()
	guiOffset = math.ceil((width - 26)/2)
	local win = window.create(term.current(), guiOffset + 1, 1, 26, height, true)
	win.setBackgroundColour(colours.grey)
	win.clear()
	mainTerm = term.redirect(win)
end

buttonInstance = buttonHandler.new(term.current())

local width, height = term.getSize()
paintutils.drawLine(13, 1, 13, height, colours.cyan)
paintutils.drawLine(14, height - 5, width, height - 5, colours.cyan)
paintutils.drawLine(14, 6, width, 6, colours.cyan)

-- SET UP TURTLE LIST SECTION
local function turtleListHandler(value)
	if value then
		local turtleID = tonumber(value:match("^%d+"))
		local data = turtleData[turtleID] or {}
		setSelectedTurtle(turtleID, unpack(data))
	end
end
turtleData = {}
turtleList = buttonInstance:AddList("turtle", {}, turtleListHandler, 1, 1, 12, height - 1)
local function allPing()
	buttonInstance:Flash("ALL_PING")
	turtleData = {}
	turtleList:SetValues({})
	sendPingPacket(-1)
end
buttonInstance:Add("ALL_PING", allPing, 1, height, 12, 1, "  Refresh   ", colours.red)

-- SET UP INDIVIDUAL TURTLE CONTROL SECTION
term.setCursorPos(14, 1)
term.setBackgroundColour(colours.red)
term.setTextColour(colours.white)
term.write(" Control: nil")

local function selectedExplore()
	if selectedTurtle then
		buttonInstance:Flash("EXPLORE")
		sendExplorePacket(selectedTurtle)
	end
end
buttonInstance:Add("EXPLORE", selectedExplore, 14, 2, 13, 1, "   Explore   ", colours.grey)

local function selectedReturn()
	if selectedTurtle then
		buttonInstance:Flash("RETURN")
		sendReturnPacket(selectedTurtle)
	end
end
buttonInstance:Add("RETURN", selectedReturn, 14, 3, 13, 1, "   Return    ", colours.lightGrey)

local function selectedFollow()
	if selectedTurtle then
		buttonInstance:Flash("FOLLOW")
		local x, y, z = gps.locate()
		if x then
			local position = {math.floor(x), math.floor(y), math.floor(z)}
			sendFollowPacket(selectedTurtle, position)
		end
	end
end
buttonInstance:Add("FOLLOW", selectedFollow, 14, 4, 13, 1, "   Follow    ", colours.grey)

local function selectedStop()
	if selectedTurtle then
		buttonInstance:Flash("STOP")
		sendIdlePacket(selectedTurtle)
	end
end
buttonInstance:Add("STOP", selectedStop, 14, 5, 13, 1, "   Stop      ", colours.lightGrey)

-- SET UP TURTLE INFO SECTION
setSelectedTurtle = function(turtleID, xPos, yPos, zPos)
	if turtleID then
		selectedTurtle = turtleID
	end
	
	term.setCursorPos(14, 1)
	term.setBackgroundColour(colours.red)
	term.setTextColour(colours.white)
	term.write(" Control:"..string.rep(" ", math.max(0, 4 - #tostring(turtleID)))..tostring(turtleID))

	term.setBackgroundColour(colours.grey)
	term.setTextColour(colours.white)
	
	term.setCursorPos(14, 7)
	term.write("ID:"..string.rep(" ", 10 - #tostring(turtleID))..tostring(turtleID))
	
	term.setCursorPos(14, 9)
	term.write("X Pos:"..string.rep(" ", 7 - #tostring(xPos))..tostring(xPos))
	
	term.setCursorPos(14, 10)
	term.write("Y Pos:"..string.rep(" ", 7 - #tostring(yPos))..tostring(yPos))
	
	term.setCursorPos(14, 11)
	term.write("Z Pos:"..string.rep(" ", 7 - #tostring(zPos))..tostring(zPos))
end
setSelectedTurtle()

local function selectedPing()
	if selectedTurtle then
		buttonInstance:Flash("PING")
		sendPingPacket(selectedTurtle)
	end
end
buttonInstance:Add("PING", selectedPing, 14, height - 6, 13, 1, "   Refresh   ", colours.red)

-- SET UP CONTROL ALL SECTION
term.setCursorPos(14, height - 4)
term.setBackgroundColour(colours.red)
term.setTextColour(colours.white)
term.write(" Control All ")

local function allExplore()
	buttonInstance:Flash("ALL_EXPLORE")
	sendExplorePacket(-1)
end
buttonInstance:Add("ALL_EXPLORE", allExplore, 14, height - 3, 13, 1, "   Explore   ", colours.grey)

local function allReturn()
	buttonInstance:Flash("ALL_RETURN")
	sendReturnPacket(-1)
end
buttonInstance:Add("ALL_RETURN", allReturn, 14, height - 2, 13, 1, "   Return    ", colours.lightGrey)

local function allFollow()
	buttonInstance:Flash("ALL_FOLLOW")
	local x, y, z = gps.locate()
	if x then
		local position = {math.floor(x), math.floor(y), math.floor(z)}
		sendFollowPacket(-1, position)
	end
end
buttonInstance:Add("ALL_FOLLOW", allFollow, 14, height - 1, 13, 1, "   Follow    ", colours.grey)

local function allStop()
	buttonInstance:Flash("ALL_STOP")
	sendIdlePacket(-1)
end
buttonInstance:Add("ALL_STOP", allStop, 14, height, 13, 1, "   Stop      ", colours.lightGrey)

-- DEFINE INPUT ROUTINE
local function input()
	buttonInstance:Draw()
	while true do
		local event = {os.pullEvent()}
		if event[1] == "mouse_click" then
			buttonInstance:HandleClick(event[3] - guiOffset, event[4])
		elseif event[1] == "key" then
			if event[2] == keys.backspace then
				break
			elseif event[2] == keys.up then
				turtleList:SetOffset(turtleList:GetOffset() - 1)
			elseif event[2] == keys.down then
				turtleList:SetOffset(turtleList:GetOffset() + 1)
			end
		end
	end
end

-- DEFINE LISTEN ROUTINE
local function listen()
	sendPingPacket(-1)
	while true do
		local senderID, message = rednet.receive(REDNET_PROTOCOL)
		if type(message) == "table" and message[1] == mapName then
			local sentTo = message[2]
			if sentTo == os.computerID() or sentTo == -1 then
				if message[3] == "PONG" then
					-- update turtleList
					local values = turtleList:GetValues()
					local found = false
					for index, data in ipairs(values) do
						local id = tonumber(data:match("^%d+"))
						if id == senderID then
							data = createListValue(senderID, message[5])
							table.remove(values, index)
							table.insert(values, index, data)
							turtleList:SetValues(values)
							found = true
							break
						end
					end
					if not found then
						local data = createListValue(senderID, message[5])
						table.insert(values, data)
						turtleList:SetValues(values)
					end
					turtleData[senderID] = message[4]

					if senderID == selectedTurtle then
						setSelectedTurtle(senderID, unpack(message[4]))
						-- update selectedTurtle info
					end
				end
			end
		end
	end
end

parallel.waitForAny(input, listen)

term.redirect(mainTerm)
term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
term.clear()
term.setCursorPos(1, 1)
