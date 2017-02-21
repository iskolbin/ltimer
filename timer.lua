-- Lua timer library
-- implemented by Ilya Kolbin iskolbin@gmail.com
--
-- Library provides timers pool class, and default pool to use directly as
-- libary functions (which can be confusing in some cases). Timers stores
-- in the indirect binary min heap structure with the activation time as the priority.

local floor, unpack = math.floor, table.unpack or unpack

local timer = {}

local function siftup( timers, priorities, from, indices )
	local index = from
	local parentidx = floor( 0.5 * index )
	while index > 1 and priorities[parentidx] > priorities[index] do
		priorities[index], priorities[parentidx] = priorities[parentidx], priorities[index]
		timers[index], timers[parentidx] = timers[parentidx], timers[index]
		indices[timers[index]], indices[timers[parentidx]] = index, parentidx
		index = parentidx
		parentidx = floor( 0.5 * index )
	end
	return index
end

local function siftdown( timers, priorities, size, limit, indices )
	for index = limit, 1, -1 do
		local leftidx = index + index
		local rightidx = leftidx + 1
		while leftidx <= size do
			local smaller = leftidx
			if rightidx <= size and priorities[leftidx] > priorities[rightidx] then
				smaller = rightidx
			end
				
			if priorities[index] > priorities[smaller] then
				timers[index], timers[smaller] = timers[smaller], timers[index]
				priorities[index], priorities[smaller] = priorities[smaller], priorities[index]
				indices[timers[index]], indices[timers[smaller]] = index, smaller
			else
				break
			end
				
			index = smaller
			leftidx = index + index
			rightidx = leftidx + 1
		end
	end
end

local function enqtimer( q, tmr, clock )
	local timers, priorities, indices = q._timers, q._priorities, q._indices
	local size = q._size + 1
	q._size = size	
	timers[size], priorities[size], indices[tmr] = tmr, clock, size
	siftup( timers, priorities, size, indices ) 
	return tmr
end

local function deqtimer( q )
	local size = q._size
	assert( size > 0, 'Heap is empty' )
	local timers, priorities, indices = q._timers, q._priorities, q._indices
	local tmr = timers[1]
	indices[tmr] = nil
	if size > 1 then
		local newtmr = timers[size]
		timers[1], priorities[1] = newtmr, priorities[size]
		timers[size], priorities[size] = nil, nil
		indices[newtmr] = 1
		size = size - 1
		q._size = size
		siftdown( timers, priorities, size, 1, indices )
	else
		timers[1], priorities[1] = nil, nil
		q._size = 0
	end
	return tmr
end

local function rmtimer( q, tmr )
	local index = q._indices[tmr]
	if index ~= nil then
		local size = q._size
		local timers, priorities, indices = q._timers, q._priorities, q._indices
		indices[tmr] = nil
		if size == index then
			timers[size], priorities[size] = nil, nil
			q._size = size - 1
		else
			local lastitem = timers[size]
			timers[index], priorities[index] = timers[size], priorities[size]
			timers[size], priorities[size] = nil, nil
			indices[lastitem] = index
			size = size - 1
			q._size = size
			if size > 1 then
				local siftedindex = siftup( timers, priorities, index, indices )
				siftdown( timers, priorities, size, siftedindex, indices ) 
			end
		end
		return true
	else
		return false
	end
end

local function updtimer( q, tmr, clock )
	if rmtimer( q, tmr ) then
		enqtimer( q, tmr, clock )
	end
end

local TimerPool = {}

TimerPool.__index = TimerPool

function TimerPool.new( clock )
	return setmetatable( {
		_clock = clock or 0,
		_timers = {},
		_priorities = {},
		_size = 0,
		_indices = {},
	}, TimerPool )
end

function TimerPool:dcall( delay, f, ... )
	return enqtimer( self, {f, ...}, self._clock + delay )
end

function TimerPool:remove( tmr )
	rmtimer( self, tmr )
end

function TimerPool:update( dt )
	local timers = self.timers
	local t = self._clock + dt
	self._clock = t
	while self._size > 0 do
		local clock = self._priorities[1]
		
		if clock > t then
			return
		end

		local tmr = deqtimer( self )
		
		local delay = tmr[1]( unpack( tmr, 2 ))
		if delay then
			updtimer( self, tmr, t + delay )
		end
	end
end

function TimerPool:reset( clock )
	local dt = clock - self._clock
	self._clock = clock
	for i = 1, self._size do
		self._priorities[i] = self._priorities[i] + dt
	end
end

timer.TimerPool = setmetatable( TimerPool, { __call = function(_,...)
	return TimerPool.new( ... )
end } )

timer._defaultpool = TimerPool()

function timer.dcall( ... )
	return timer._defaultpool:dcall( ... )
end

function timer.remove( ... )
	return timer._defaultpool:remove( ... )
end

function timer.update( ... )
	return timer._defaultpool:update( ... )
end

function timer.reset( ... )
	return timer._defaultpool:reset( ... )
end

return timer
