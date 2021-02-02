[![Build Status](https://travis-ci.org/iskolbin/ltimer.svg?branch=master)](https://travis-ci.org/iskolbin/ltimer)
[![license](https://img.shields.io/badge/license-public%20domain-blue.svg)](http://unlicense.org/)
[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)

Lua timer
=========

Lua timer library. Provides `TimerPool` class to manage timers.


timer.dcall(delay, f, ...) -> timer
-----------------------------------

Delayed call using default timer pool, see `TimerPool:dcall` for details.


timer.update(clock = os.clock)
------------------------------

Update default timer pool.


timer.remove(timer)
-------------------

Removes timer from default timer pool.


timer.reset(clock = os.clock)
-----------------------------

Sets default pool clock time and updates timers activation time.


TimerPool.new(clock = 0)
-------------------------

Create new timer pool with `clock` time.


TimerPool:dcall(delay, f, ...) -> timer
---------------------------------------

Delayed call, calls `f` with arguments after specified `delay`.
Returns new timer, which can be used as argument to `remove`.
If calling `f` returned nothing or first value is `nil` then
timer stops. Otherwise `f` will be called with returned values
after `delay`.

```lua
local pool = TimerPool()
local t = pool:dcall(1, function(count)
	if count > 0 then
		print("Doing stuff")
		return count - 1
	end
end, 5) 
pool:update(5) -- will print "Doing stuff" 5 times
```

TimerPool:update(clock)
-----------------------

Updates pool clock time. Checks timers clock and call associated functions
if timer clock >= pool clock. Note that it's possible that time step is
so big that timer triggers multiple times (see example above).


TimerPool:remove(timer)
-----------------------

Removes timer from pool.


TimerPool:reset(clock)
------------------------

Sets pool clock time and updates timers activation time.
