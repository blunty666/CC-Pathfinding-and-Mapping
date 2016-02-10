local tArgs = {...}

local function printUsage()
	print("Usage:")
	print(fs.getName(shell.getRunningProgram()).." <mapAPI_path> <map_path> <x_pos> <y_pos> <z_pos>")
	print("<(string)mapAPI_path> The path of the mapAPI the map uses.")
	print("<(string)map_path> The directory path of the map you want to view.")
	print("[optional] <(number)x_pos> <(number)y_pos> <(number)z_pos> The GPS coordinates you want to view the map at.")
end

--===== LOAD MAP API =====--
local mapAPIPath = tArgs[1]
if type(mapAPIPath) ~= "string" or not fs.exists(mapAPIPath) or fs.isDir(mapAPIPath) then
	printError("invalid mapAPI_path: "..tostring(mapAPIPath))
	printUsage()
	return
end
local mapAPI = fs.getName(mapAPIPath)
if not _G[mapAPI] then
	if not os.loadAPI(mapAPIPath) then
		printError("could not load mapAPI: "..tostring(mapAPIPath))
		printUsage()
		return
	end
end
mapAPI = _G[mapAPI]

--===== LOAD MAP =====--
if type(tArgs[2]) ~= "string" then
	printError("string expected for map name")
	printUsage()
	return
end
local map = mapAPI.new(tArgs[2])

--===== FIND START COORDINATES =====--
local currX, currY, currZ
if #tArgs == 5 then
	for i = 3, 5 do
		local num = tArgs[i]
		if not tonumber(num) or num % 1 ~= 0 then
			printError("argument "..tostring(i).." is not a number")
			printUsage()
			return
		end
	end
	currX = tArgs[3]
	currY = tArgs[4]
	currZ = tArgs[5]
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
			if value ~= nil then
				mainWindow.setCursorPos(x, z)
				mainWindow.write(string.sub(tostring(value), 1, 1))
			end
		end
	end
	
	local cursorValue = map:get(vector.new(currX + currW - 1, currY, currZ + currH - 1))
	mainWindow.setBackgroundColour(colours.green)
	mainWindow.setCursorPos(currW, currH)
	if cursorValue ~= nil then
		mainWindow.write(string.sub(tostring(cursorValue), 1, 1))
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
		redrawToolbarWindow()
		redrawMainWindow()
		redraw = false
	end
	local event = {os.pullEvent()}
	if event[1] == "key" then
		local key = event[2]
		if key == keys.up then
			currZ = currZ - 1
			currH = math.min(height - 1, currH + 1)
		elseif key == keys.down then
			currZ = currZ + 1
			currH = math.max(1, currH - 1)
		elseif key == keys.left then
			currX = currX - 1
			currW = math.min(width, currW + 1)
		elseif key == keys.right then
			currX = currX + 1
			currW = math.max(1, currW - 1)
		elseif key == keys.numPadAdd then
			currY = currY + 1
		elseif key == keys.numPadSubtract then
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