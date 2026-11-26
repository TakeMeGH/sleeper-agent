class_name DropRoller
extends RefCounted
## Pure drop rolls. Every method takes the roll values (0-1) so tests can fix them.

const AMMO_KINDS: Array[StringName] = [&"smg", &"shotgun"]
const DOSE_KINDS: Array[StringName] = [&"coffee", &"cigarette"]


## Returns the weighted index chosen by roll (0 <= roll < 1), or -1 if all weights are zero.
static func pick_weighted(weights: PackedFloat32Array, roll: float) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += maxf(w, 0.0)
	if total <= 0.0:
		return -1
	var target: float = clampf(roll, 0.0, 0.999999) * total
	var acc: float = 0.0
	for i: int in weights.size():
		acc += maxf(weights[i], 0.0)
		if target < acc:
			return i
	return weights.size() - 1


## Returns the pickup kinds a dying enemy drops for the given roll values.
## A chance roll below the drop chance means "drop"; the pick roll chooses the kind by weight.
static func roll_drops(data: EnemyData, ammo_chance_roll: float, ammo_pick_roll: float,
		dose_chance_roll: float, dose_pick_roll: float) -> Array[StringName]:
	var out: Array[StringName] = []
	for i: int in mini(data.guaranteed_ammo.size(), AMMO_KINDS.size()):
		for n: int in data.guaranteed_ammo[i]:
			out.append(AMMO_KINDS[i])
	for i: int in mini(data.guaranteed_doses.size(), DOSE_KINDS.size()):
		for n: int in data.guaranteed_doses[i]:
			out.append(DOSE_KINDS[i])
	if ammo_chance_roll < data.ammo_drop_chance:
		var a: int = pick_weighted(data.ammo_weights, ammo_pick_roll)
		if a >= 0 and a < AMMO_KINDS.size():
			out.append(AMMO_KINDS[a])
	if dose_chance_roll < data.dose_drop_chance:
		var d: int = pick_weighted(data.dose_weights, dose_pick_roll)
		if d >= 0 and d < DOSE_KINDS.size():
			out.append(DOSE_KINDS[d])
	return out


## Same as roll_drops with the four rolls taken from rng.
static func roll_drops_rng(data: EnemyData, rng: RandomNumberGenerator) -> Array[StringName]:
	var a: float = rng.randf()
	var b: float = rng.randf()
	var c: float = rng.randf()
	var d: float = rng.randf()
	return roll_drops(data, a, b, c, d)
