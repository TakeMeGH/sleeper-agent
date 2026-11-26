class_name RealClock
extends RefCounted
## Turns a scaled _process delta into real seconds without the one-frame error when Engine.time_scale
## changes mid-frame (hitstop starts in the physics step, after that frame's delta was computed).
## The result is the smaller of the wall-clock step and delta / the scale seen last frame, capped.

const MAX_STEP_SECONDS: float = 0.25

var _last_usec: int = 0
var _last_scale: float = 1.0


## Real seconds that passed this frame. Call exactly once per frame.
func step(delta: float) -> float:
	var now: int = Time.get_ticks_usec()
	var wall: float = delta
	if _last_usec > 0:
		wall = float(now - _last_usec) / 1000000.0
	_last_usec = now
	var scaled: float = delta / maxf(_last_scale, 0.001)
	_last_scale = Engine.time_scale
	return minf(minf(wall, scaled), MAX_STEP_SECONDS)
