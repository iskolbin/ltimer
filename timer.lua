--[[

 timer - v0.4.0 - public domain Lua timers library
 no warranty implied; use at your own risk

 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/ltimer

 Library provides timer pool class, which you need to create to use timers.
 Timers are stored in the indirect binary min heap structure with the
 activation time as the priority.

 See documentation in README file.

 COMPATIBILITY

 Lua 5.1+ LuaJIT

 LICENSE

 See end of file for license information.

--]]

local setmetatable, assert, floor, unpack = _G.setmetatable, _G.assert, math.floor, table.unpack or _G.unpack

local function sift_up(timers, priorities, from, indices)
	local index = from
	local parent_idx = floor(0.5 * index)
	while index > 1 and priorities[parent_idx] > priorities[index] do
		priorities[index], priorities[parent_idx] = priorities[parent_idx], priorities[index]
		timers[index], timers[parent_idx] = timers[parent_idx], timers[index]
		indices[timers[index]], indices[timers[parent_idx]] = index, parent_idx
		index = parent_idx
		parent_idx = floor(0.5 * index)
	end
	return index
end

local function sift_down(timers, priorities, size, limit, indices)
	for index = limit, 1, -1 do
		local left_idx = index + index
		local right_idx = left_idx + 1
		while left_idx <= size do
			local smaller = left_idx
			if right_idx <= size and priorities[left_idx] > priorities[right_idx] then
				smaller = right_idx
			end
			if priorities[index] > priorities[smaller] then
				timers[index], timers[smaller] = timers[smaller], timers[index]
				priorities[index], priorities[smaller] = priorities[smaller], priorities[index]
				indices[timers[index]], indices[timers[smaller]] = index, smaller
			else
				break
			end
			index = smaller
			left_idx = index + index
			right_idx = left_idx + 1
		end
	end
end

local function enq_timer(q, tmr, clock)
	local timers, priorities, indices = q.timers, q.priorities, q.indices
	local size = q.size + 1
	q.size = size
	timers[size], priorities[size], indices[tmr] = tmr, clock, size
	sift_up(timers, priorities, size, indices)
	return tmr
end

local function deq_timer(q)
	local size = q.size
	assert(size > 0, 'Heap is empty')
	local timers, priorities, indices = q.timers, q.priorities, q.indices
	local tmr = timers[1]
	indices[tmr] = nil
	if size > 1 then
		local newtmr = timers[size]
		timers[1], priorities[1] = newtmr, priorities[size]
		timers[size], priorities[size] = nil, nil
		indices[newtmr] = 1
		size = size - 1
		q.size = size
		sift_down(timers, priorities, size, 1, indices)
	else
		timers[1], priorities[1] = nil, nil
		q.size = 0
	end
	return tmr
end

local function rm_timer(q, tmr)
	local index = q.indices[tmr]
	if index == nil then
		return false
	end
	local size, timers, priorities, indices = q.size, q.timers, q.priorities, q.indices
	indices[tmr] = nil
	if size == index then
		timers[size], priorities[size] = nil, nil
		q.size = size - 1
	else
		local lastitem = timers[size]
		timers[index], priorities[index] = timers[size], priorities[size]
		timers[size], priorities[size] = nil, nil
		indices[lastitem] = index
		size = size - 1
		q.size = size
		if size > 1 then
			local siftedindex = sift_up(timers, priorities, index, indices)
			sift_down(timers, priorities, size, siftedindex, indices)
		end
	end
	return true
end

local TimerPool = {}

TimerPool.__index = TimerPool

function TimerPool.new(clock)
	return setmetatable({
		clock = clock or 0,
		timers = {},
		priorities = {},
		size = 0,
		indices = {},
	}, TimerPool)
end

function TimerPool:dcall(delay, f, ...)
	return enq_timer(self, {f, delay, ...}, self.clock + delay)
end

function TimerPool:remove(tmr)
	rm_timer(self, tmr)
end

function TimerPool:update(clock)
	self.clock = clock
	local priorities = self.priorities
	local next_clock = priorities[1]
	while next_clock and next_clock <= clock do
		local tmr = deq_timer(self)
		local args = {tmr[1](unpack(tmr, 3))}
		local n = #args
		if args[1] ~= nil then
			for i = 1, n do tmr[i+2] = args[i] end
			for i = n+3, #tmr do tmr[i] = nil end
			enq_timer(self, tmr, next_clock + tmr[2])
		end
		next_clock = priorities[1]
	end
end

function TimerPool:reset(clock)
	local dt = clock - self.clock
	self.clock = clock
	for i = 1, self.size do
		self.priorities[i] = self.priorities[i] + dt
	end
end

local default_pool = TimerPool.new(os.clock())

local timer = {
	default_pool = default_pool,
	TimerPool = setmetatable(TimerPool, {__call = function(_, ...)
		return TimerPool.new(...)
	end})
}

function timer.dcall(delay, f, ...)
	return default_pool:dcall(delay, f, ...)
end

function timer.remove(tmr)
	default_pool:remove(tmr)
end

function timer.update(clock)
	default_pool:update(clock or os.clock())
end

function timer.reset(clock)
	default_pool:update(clock or os.clock())
end

return timer

--[[
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2021 Ilya Kolbin
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
--]]
