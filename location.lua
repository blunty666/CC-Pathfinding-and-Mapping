--[[
The MIT License (MIT)
 
Copyright (c) 2012 Lyqyd
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

-- Lyqyds location API (https://github.com/lyqyd/location)
-- the headings have been altered to use the Minecraft directions
-- have also made some simplifications to suit the needed use case

local location = {
	add = function(self, o)
		return vector.new(
			self.x + o.x,
			self.y + o.y,
			self.z + o.z
		)
	end,
	sub = function(self, o)
		return vector.new(
			self.x - o.x,
			self.y - o.y,
			self.z - o.z
		)
	end,
	mul = function(self, m)
		return vector.new(
			self.x * m,
			self.y * m,
			self.z * m
		)
	end,
	div = function(self, d)
		return vector.new(
			self.x / d,
			self.y / d,
			self.z / d
		)
	end,
	left = function(self)
		if turtle.turnLeft() then
			self.h = (self.h - 1) % 4
			return true
		end
		return false
	end,
	right = function(self)
		if turtle.turnRight() then
			self.h = (self.h + 1) % 4
			return true
		end
		return false
	end,
	forward = function(self)
		if turtle.forward() then
			self.x = self.x + (self.h - 2) * (self.h % 2)
			self.z = self.z + (1 - self.h) * ((self.h + 1) % 2)
			return true
		end
		return false
	end,
	back = function(self)
		if turtle.back() then
			self.x = self.x - (self.h - 2) * (self.h % 2)
			self.z = self.z - (1 - self.h) * ((self.h + 1) % 2)
			return true
		end
		return false
	end,
	up = function(self)
		if turtle.up() then
			self.y = self.y + 1
			return true
		end
		return false
	end,
	down = function(self)
		if turtle.down() then
			self.y = self.y - 1
			return true
		end
		return false
	end,
	moveDeltas = function(self)
		return (self.h - 2) * (self.h % 2), (1 - self.h) * ((self.h + 1) % 2)
	end,
	setHeading = function(self, heading)
		if not heading or heading < 0 or heading > 3 then return nil, "Heading Not in Range" end
		while self.h ~= heading do
			if (self.h + 1) % 4 == heading % 4 then
				self:right()
			else
				self:left()
			end
		end
		return true
	end,
	getHeading = function(self)
		return self.h
	end,
	tovector = function(self)
		if vector then
			return vector.new(
				self.x,
				self.y,
				self.z
			)
		else
			return nil
		end
	end,
	tostring = function(self)
		return self.x..","..self.y..","..self.z..","..self.h
	end,
	value = function(self)
		return self.x, self.y, self.z, self.h
	end,
}

local lmetatable = {
	__index = location,
	__add = location.add,
	__sub = location.sub,
	__mul = location.mul,
	__div = location.div,
	__unm = function(l) return l:mul(-1) end,
	__tostring = function(l) return l:tostring() end,
}

function new( x, y, z, h )
	local l = {
		x = x or 0,
		y = y or 0,
		z = z or 0,
		h = h or 1
	}
	setmetatable( l, lmetatable )
	return l
end