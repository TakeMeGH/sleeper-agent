class_name PlayerTime
extends Node
## The player's own time scale (story 016). During slow motion the world runs at slow_time_scale
## (Engine.time_scale, written ONLY by ShiftAbility) while the player runs at player_time_scale, so
## player systems multiply their engine delta by get_delta_multiplier(). The engine delta already holds
## the hitstop factor, so a hitstop freezes the player too and the player returns to slow-motion speed after.
## Outside slow motion every value is 1.0. Nothing here writes Engine.time_scale.

## Group every PlayerTime joins so player systems can find it without wiring (see find_for).
const GROUP: StringName = &"player_time"

## Engine processing order, not gameplay: PlayerTime must update before every node that reads it.
const PROCESS_PRIORITY: int = -1000
## Smallest multiplier ever returned, so callers can divide by it safely.
const MIN_MULTIPLIER: float = 0.001

## Source of the active effect and the scales (injected in the scene; no autoload).
@export var shift_ability: ShiftAbility


## Multiplier latched once per frame (_process and _physics_process) so every node sees one value.
var _m: float = 1.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	process_priority = PROCESS_PRIORITY
	process_physics_priority = PROCESS_PRIORITY
	_m = get_live_delta_multiplier()


func _process(_delta: float) -> void:
	_m = get_live_delta_multiplier()


func _physics_process(_delta: float) -> void:
	_m = get_live_delta_multiplier()


## The PlayerTime of the running scene as seen from from_node, or null when there is none.
static func find_for(from_node: Node) -> PlayerTime:
	if from_node == null or not from_node.is_inside_tree():
		return null
	return from_node.get_tree().get_first_node_in_group(GROUP) as PlayerTime


## Delta multiplier of the scene's PlayerTime as seen from from_node; 1.0 when there is none.
static func multiplier_for(from_node: Node) -> float:
	var player_time: PlayerTime = find_for(from_node)
	return 1.0 if player_time == null else player_time.get_delta_multiplier()


## True while slow motion runs.
func is_slow_motion_active() -> bool:
	return shift_ability != null and shift_ability.data != null \
			and shift_ability.get_active_kind() == ShiftAbility.KIND_SLOW_MOTION


## The player's time scale: player_time_scale during slow motion, else 1.0.
func get_time_scale() -> float:
	return maxf(shift_ability.data.player_time_scale, MIN_MULTIPLIER) if is_slow_motion_active() else 1.0


## Factor from engine delta to player delta, latched at the start of the frame: player_time_scale /
## slow_time_scale during slow motion, else 1.0. (Hitstop is already inside the engine delta.)
func get_delta_multiplier() -> float:
	return _m


## The same factor computed from the current ShiftAbility state (for probes); never below MIN_MULTIPLIER.
func get_live_delta_multiplier() -> float:
	if not is_slow_motion_active():
		return 1.0
	return maxf(shift_ability.data.player_time_scale, MIN_MULTIPLIER) 			/ maxf(shift_ability.data.slow_time_scale, MIN_MULTIPLIER)


## delta (engine, scaled) converted to player time (uses the latched multiplier).
func scale_delta(delta: float) -> float:
	return delta * _m
