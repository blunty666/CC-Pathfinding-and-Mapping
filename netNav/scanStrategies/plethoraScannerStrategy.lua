local PLETHORA_SCANNER = "plethora:scanner"
local AIR_BLOCK = "minecraft:air"

function new()
  return {
    priority = 10,
    isAvailable = function()
      return peripheral.find(PLETHORA_SCANNER)
    end,
    execute = function(currentPosition, updateSessionMap, updateServerMap)
      local scanner = peripheral.find(PLETHORA_SCANNER)
      if not scanner then return end -- throw error?

      -- get block data from scan and add to temporary map
      local rawBlockInfo = scanner.scan()
      local sortedBlockInfo = aStar.newMap()
      for _, blockInfo in ipairs(rawBlockInfo) do
        sortedBlockInfo:set(currentPosition + vector.new(blockInfo.x, blockInfo.y, blockInfo.z), blockInfo)
      end

      -- add adjacent blocks to initial toCheck queue
      local toCheckQueue = {}
      for _, pos in ipairs(aStar.adjacent(currentPosition)) do
		  local blockInfo = sortedBlockInfo:get(pos)
        if blockInfo then
          table.insert(toCheckQueue, pos)
		      blockInfo.queued = true
        end
      end
	  
      -- flag position of turtle as checked to prevent updating map incorrectly
      updateSessionMap(currentPosition, false)
      updateServerMap(currentPosition, false)
      sortedBlockInfo:get(currentPosition).queued = true

      -- process all blocks from the scan
      while toCheckQueue[1] do
        local pos = table.remove(toCheckQueue, 1)
        local blockInfo = sortedBlockInfo:get(pos)
        if blockInfo.name == AIR_BLOCK then
          for _, pos2 in ipairs(aStar.adjacent(pos)) do
            local blockInfo2 = sortedBlockInfo:get(pos2)
            if blockInfo2 and not blockInfo2.queued then
              -- only add air blocks to the toCheck queue to prevent overscanning the area and bloating the map data size
              table.insert(toCheckQueue, pos2)
              blockInfo2.queued = true
            end
          end
          updateSessionMap(pos, false)
          updateServerMap(pos, false)
        else
          updateSessionMap(pos, true)
          updateServerMap(pos, true)
        end
      end

      -- go through list again and add all block data to session map
      for _, blockInfo in ipairs(rawBlockInfo) do
        local pos = currentPosition + vector.new(blockInfo.x, blockInfo.y, blockInfo.z)
        if not blockInfo.queued then
          updateSessionMap(pos, blockInfo.name ~= AIR_BLOCK)
        end
      end
    end,
  }
end
