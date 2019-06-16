local function findSensor()
	for _, side in ipairs({"left", "right"}) do
		if peripheral.getType(side) == "turtlesensorenvironment" then
			return side
		end
	end
	return false
end

function new()
  return {
    priority = 10,
    isAvailable = function()
      return findSensor() and true
    end,
    execute = function(currentPosition, updateSessionMap, updateServerMap)
      local rawBlockInfo = peripheral.call(findSensor(), "sonicScan")
      local sortedBlockInfo = aStar.newMap()
      for _, blockInfo in ipairs(rawBlockInfo) do
        sortedBlockInfo:set(currPos + vector.new(blockInfo.x, blockInfo.y, blockInfo.z), blockInfo)
      end
      local toCheckQueue = {}
      for _, pos in ipairs(aStar.adjacent(currPos)) do
        if sortedBlockInfo:get(pos) then
          table.insert(toCheckQueue, pos)
        end
      end
      while toCheckQueue[1] do
        local pos = table.remove(toCheckQueue, 1)
        local blockInfo = sortedBlockInfo:get(pos)
        if blockInfo.type == "AIR" then
          for _, pos2 in ipairs(aStar.adjacent(pos)) do
            local blockInfo2 = sortedBlockInfo:get(pos2)
            if blockInfo2 and not blockInfo2.checked then
              table.insert(toCheckQueue, pos2)
            end
          end
          updateSessionMap(pos, false)
          updateServerMap(pos, false)
        else
          updateSessionMap(pos, true)
          updateServerMap(pos, true)
        end
        blockInfo.checked = true
      end
      for _, blockInfo in ipairs(rawBlockInfo) do
        local pos = currPos + vector.new(blockInfo.x, blockInfo.y, blockInfo.z)
        local blockInfo = sortedBlockInfo:get(pos)
        if not blockInfo.checked then
          updateSessionMap(pos, blockInfo.type ~= "AIR")
        end
      end
    end,
  }
end
