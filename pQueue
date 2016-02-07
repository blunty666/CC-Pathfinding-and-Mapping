local function sift_up(queue, index)
	local current, parent = index, (index - (index % 2))/2
	while current > 1 and queue.cmp(queue[current][2], queue[parent][2]) do
		queue[current], queue[parent] = queue[parent], queue[current]
		current, parent = parent, (parent - (parent % 2))/2
	end
	return current
end

local function sift_down(queue, index)
	local current, child, size = index, 2*index, #queue
	while child <= size do
		if child < size and queue.cmp(queue[child + 1][2], queue[child][2]) then
			child = child + 1
		end
		if queue.cmp(queue[child][2], queue[current][2]) then
			queue[current], queue[child] = queue[child], queue[current]
			current, child = child, 2*child
		else
			break
		end
	end
	return current
end

local methods = {

	insert = function(self, element, value)
		table.insert(self, {element, value})
		return sift_up(self, #self)
	end,

	remove = function(self, element, compFunc)
		local index = self:contains(element, compFunc)
		if index then
			local size = #self
			self[index], self[size] = self[size], self[index]
			local ret = table.remove(self)
			if size > 1 and index < size then
				sift_down(self, index)
				if index > 1 then
					sift_up(self, index)
				end
			end
			return unpack(ret)
		end
	end,

	pop = function(self)
		if self[1] then
			local size = #self
			self[1], self[size] = self[size], self[1]
			local ret = table.remove(self)
			if size > 1 then
				sift_down(self, 1)
			end
			return unpack(ret)
		end
	end,

	peek = function(self)
		if self[1] then
			return self[1][1], self[1][2]
		end
	end,

	contains = function(self, element, compFunc)
		for index, entry in ipairs(self) do
			if (compFunc and compFunc(entry[1], element)) or entry[1] == element then
				return index
			end
		end
		return false
	end,

	isEmpty = function(self)
		return #self == 0
	end,

	size = function(self)
		return #self
	end,

	getValue = function(self, element, compFunc)
		local index = self:contains(element, compFunc)
		return (index and self[index][2]) or false
	end,

	setValue = function(self, element, value, compFunc)
		local index = self:contains(element, compFunc)
		if index then
			self[index][2] = value
			sift_up(self, index)
			sift_down(self, index)
			return true
		else
			return false
		end
	end,

}

function new(compareFunc)
	local queue = {}
	queue.cmp = type(compareFunc) == "function" and compareFunc or function(a, b) return a < b end
	setmetatable(queue, {__index = methods})
	return queue
end