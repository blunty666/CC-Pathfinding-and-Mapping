local function printUsage()
	print("Usage:")
	print(fs.getName(shell.getRunningProgram()).." <map_name> <x_pos> <y_pos> <z_pos> <(optional)max_distance>")
	print("<map_name> The name of the map to use.")
	print("<x_pos> <y_pos> <z_pos> The GPS coordinates you want to go to.")
	print("<(optional)max_distance> The farthest distance allowed to travel from start position.")
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

local maxDistance
if tArgs[5] ~= nil then
	if tonumber(tArgs[5]) then
		print("setting max_distance to: ", tArgs[5])
		maxDistance = tonumber(tArgs[5])
	else
		printError("max_distance: number expected")
		printUsage()
		return
	end
end

print("going to coordinates = ", tArgs[2], ",", tArgs[3], ",", tArgs[4])
local ok, err = netNav.goto(tArgs[2], tArgs[3], tArgs[4], maxDistance)
if not ok then
	printError("navigation failed: ", err)
else
	print("succesfully navigated to coordinates")
end
