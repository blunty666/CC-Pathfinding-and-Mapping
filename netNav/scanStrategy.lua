local strategies = {}

local function compareStrategies(a, b)
    return a.priority > b.priority
end

function add(strategy)
    table.insert(strategies, strategy)
    table.sort(strategies, compareStrategies)
end

function getBest()
    for _, strategy in ipairs(strategies) do
        if strategy.isAvailable() then
            return strategy
        end
    end
    return false
end

--===== SET UP VANILLA SCAN STRATEGY =====--
local function detect(currPos, adjPos)
    local heading = location.headingFromDelta(adjPos - currPos)
    if heading then
        currPos:setHeading(heading)
        if heading == 4 then
            return turtle.detectUp()
        elseif heading == 5 then
            return turtle.detectDown()
        else
            return turtle.detect()
        end
    end
    return false
end

local vanillaScanStrategy = {
    priority = 0, -- lowest priority
    isAvailable = function() return true end, -- always available
    execute = function(currentPosition, updateSessionMap, updateServerMap)
        for _, pos in ipairs(aStar.adjacent(currentPosition)) do -- find better order of checking directions
            local isBlocked = detect(currentPosition, pos)
            updateSessionMap(pos, isBlocked)
            updateServerMap(pos, isBlocked)
        end
    end,
}
add(vanillaScanStrategy)

--===== LOAD STRATEGIES FROM NET NAV STRATEGY FOLDER
local function loadStrategy(path)
    local name = fs.getName(path)
    if name:sub(-4) == ".lua" then
        name = name:sub(1, -5)
    end
    
    local tEnv = {}
    setmetatable(tEnv, {__index = _G})
    local fnAPI, err = loadfile(path, tEnv)
    if fnAPI then
        local ok, err = pcall(fnAPI)
        if not ok then
            return printError("Failed to load strategy " .. name .. " due to " .. err, 1)
        end
    else
        return printError("Failed to load strategy " .. name .. " due to " .. err, 1)
    end
    
    if type(tEnv.new) == "function" then
        local strategy = tEnv.new()
        add(strategy)
    else
        return printError("Failed to find constructor for strategy " .. name)
    end
end

local STRATEGY_FOLDER = "netNavScanStrategies"

if fs.exists(STRATEGY_FOLDER) and fs.isDir(STRATEGY_FOLDER) then
    for _, file in ipairs(fs.list(STRATEGY_FOLDER)) do
        local path = fs.combine(STRATEGY_FOLDER, file)
        loadStrategy(path)
    end
end
