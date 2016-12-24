local tArgs = {...}

local function printUsage()
	print("Usage: viewRemoteMap <(string) mapName> <(int) x-coord> <(int) y-coord> <(int) z-coord>")
end

if not remoteMap then
	if not os.loadAPI("remoteMap") then
		error("Could not load remoteMap API")
	end
end

for _, side in ipairs(redstone.getSides()) do
	if peripheral.getType(side) == "modem" then
		rednet.open(side)
	end
end

if not rednet.isOpen() then
	error("could not open rednet")
end

if type(tArgs[1]) ~= "string" then
	printError("string expected for map name")
	printUsage()
	return
end
local map = remoteMap.new(tArgs[1], 5)

local currX, currY, currZ
if #tArgs == 4 then
	for i = 2, 4 do
		local num = tArgs[i]
		if not tonumber(num) or num % 1 ~= 0 then
			printError("argument "..tostring(i).." is not a number")
			printUsage()
			return
		end
	end
	currX = tArgs[2]
	currY = tArgs[3]
	currZ = tArgs[4]
else
	currX, currY, currZ = gps.locate(1)
	if tonumber(currX) then
		currX = math.floor(tonumber(currX))
	end
	if tonumber(currY) then
		currY = math.floor(tonumber(currY))
	end
	if tonumber(currZ) then
		currZ = math.floor(tonumber(currZ))
	end
end
if not (currX and currY and currZ) then
	printError("could not identify start coords")
	printUsage()
	return
end

term.setCursorBlink(false)
term.setTextColour(colours.white)
term.setBackgroundColour(colours.black)
term.clear()

local width, height = term.getSize()
local currW, currH = 1, 1

local mainWindow = window.create(term.current(), 1, 1, width, math.max(0, height - 1), false)
mainWindow.setTextColour(colours.red)

local toolbarWindow = window.create(term.current(), 1, height, width, 1, false)
toolbarWindow.setBackgroundColour(colours.grey)
toolbarWindow.setTextColour(colours.white)
toolbarWindow.clear()

local function redrawMainWindow()
	mainWindow.setVisible(false)
	
	mainWindow.setBackgroundColour(colours.black)
	mainWindow.clear()
	mainWindow.setBackgroundColour(colours.white)
	
	local w, h = mainWindow.getSize()
	for x = 1, w do
		for z = 1, h do
			local value = map:get(vector.new(currX + x - 1, currY, currZ + z - 1))
			if value then
				mainWindow.setCursorPos(x, z)
				mainWindow.write(string.sub(value, 1, 1))
			end
		end
	end
	
	local cursorValue = map:get(vector.new(currX + currW - 1, currY, currZ + currH - 1))
	mainWindow.setBackgroundColour(colours.green)
	mainWindow.setCursorPos(currW, currH)
	if cursorValue then
		mainWindow.write(string.sub(cursorValue, 1, 1))
	else
		mainWindow.write(" ")
	end
	
	mainWindow.setVisible(true)
end

local function redrawToolbarWindow()
	toolbarWindow.setVisible(false)
	
	toolbarWindow.setCursorPos(1, 1)
	toolbarWindow.clearLine()
	toolbarWindow.write(tostring(currX + currW - 1)..","..tostring(currY)..","..tostring(currZ + currH - 1))
	toolbarWindow.write(" -- ")
	toolbarWindow.write(tostring(math.floor( (currX + currW - 1)/16 )))
	toolbarWindow.write(",")
	toolbarWindow.write(tostring(math.floor( (currY)/16 )))
	toolbarWindow.write(",")
	toolbarWindow.write(tostring(math.floor( (currZ + currH - 1)/16 )))
	
	toolbarWindow.setVisible(true)
end

local cont = true
local redraw = true
while cont do
	if redraw then
		map:check()
		redrawToolbarWindow()
		redrawMainWindow()
		redraw = false
	end
	local event = {os.pullEvent()}
	if event[1] == "key" then
		local key = event[2]
		if key == keys.up or key == keys.w then
			currZ = currZ - 1
			currH = math.min(height - 1, currH + 1)
		elseif key == keys.down or key == keys.s then
			currZ = currZ + 1
			currH = math.max(1, currH - 1)
		elseif key == keys.left or key == keys.a then
			currX = currX - 1
			currW = math.min(width, currW + 1)
		elseif key == keys.right or key == keys.d then
			currX = currX + 1
			currW = math.max(1, currW - 1)
		elseif key == keys.numPadAdd or key == keys.e then
			currY = currY + 1
		elseif key == keys.numPadSubtract or key == keys.q then
			currY = currY - 1
		elseif key == keys.backspace then
			cont = false
		end
		redraw = true
	elseif event[1] == "mouse_click" then
		if event[4] < height then
			currW, currH = event[3], event[4]
			redraw = true
		end
	elseif event[1] == "term_resize" then
		width, height = term.getSize()
		mainWindow.reposition(1, 1, width, math.max(0, height - 1))
		toolbarWindow.reposition(1, height, width, height)
		redraw = true
	end
end

term.setBackgroundColour(colours.black)
term.setCursorPos(1, 1)
term.clear()