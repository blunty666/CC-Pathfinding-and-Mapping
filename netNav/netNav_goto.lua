local function printUsage()
	print("Usage:")
	print(fs.getName(shell.getRunningProgram()).." <remoteMap_name> <x_pos> <y_pos> <z_pos>")
	print("<remoteMap_name> The name of the remoteMap to connect to and use.")
	print("<x_pos> <y_pos> <z_pos> The GPS coordinates you want to go to.")
end

if not netNav then
	if not os.loadAPI("netNav") then
		error("could not load netNav API")
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

local tArgs = {...}

if type(tArgs[1]) ~= "string" then
	printError("remoteMap_name: string expected")
	printUsage()
	return
end
netNav.setMap(tArgs[1], 30)
 
for i = 2, 4 do
	if tonumber(tArgs[i]) then
		tArgs[i] = tonumber(tArgs[i])
	else
		printError("argument "..i.." must be a valid coordinate")
		printUsage()
		return
	end
end

print("going to coordinates = ", tArgs[2], ",", tArgs[3], ",", tArgs[4])
local ok, err = netNav.goto(tArgs[2], tArgs[3], tArgs[4])
if not ok then
	printError("navigation failed: ", err)
else
	print("succesfully navigated to coordinates")
end