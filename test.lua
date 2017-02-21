local TimerPool = require('TimerPool')

local function countkeys( t )
	local n = 0
	for _, _ in pairs( t ) do
		n = n + 1
	end
	return n
end

assert( getmetatable( TimerPool.new()) == TimerPool )
assert( getmetatable( TimerPool()) == TimerPool )

local pool = TimerPool()
math.randomseed( os.time())
local input, output = {}, {}
for i = 1, 1000 do
	input[i] = math.random()
end
local t = math.random()
for i = 1, 1000 do
	local j = i
	pool:dcall( t, function()
		output[#output+1] = input[j]
	end)
	t = t + math.random()
end

pool:update( 1500 )
assert( pool._size == 0 )
assert( pool._clock == 1500 )
assert( #pool._priorities == 0 )
assert( countkeys( pool._indices ) == 0 )
assert( #pool._timers == 0 )
for i = 1, 1000 do
	assert( input[i] == output[i] )
end

output = {}
local timers = {}
local t = math.random()
for i = 1, 1000 do
	local j = i
	timers[i] = pool:dcall( t, function()
		output[#output+1] = input[j]
	end)
	t = t + math.random()
end

for i = 1, 1000 do
	if i % 2 == 0 then
		pool:remove( timers[i] )
	end
end
pool:update( 3000 )
assert( pool._size == 0 )
assert( pool._clock == 3000 )
assert( #pool._priorities == 0 )
assert( countkeys( pool._indices ) == 0 )
assert( #pool._timers == 0 )
for i = 1, 500 do
	assert( input[2*i-1] == output[i] )
end

local s = 0
for i = 1, 1000 do
	pool:dcall( i, function() s = s + 1 end )
end
pool:reset( 4000 )
assert( s == 0 )
assert( pool._size == 1000 )
assert( pool._clock == 4000 )
assert( #pool._priorities == 1000 )
assert( countkeys( pool._indices ) == 1000 )
assert( #pool._timers == 1000 )

pool:update( 4500 )
assert( s == 500 )
pool:update( 5000 )
assert( s == 1000 )

local t = pool:dcall( 1, function()
	s = s + 1
	return true
end)
pool:update( 6000 )
assert( s == 2000 )

pool:remove( t )

pool:dcall( 1, function(count)
	if count > 0 then
		s = s + 1
		return count -1
	end
end, 500 )
pool:update( 7000 )
assert( s == 2500 )
assert( pool._size == 0 )
assert( pool._clock == 7000 )
assert( #pool._priorities == 0 )
assert( countkeys( pool._indices ) == 0 )
assert( #pool._timers == 0 )
