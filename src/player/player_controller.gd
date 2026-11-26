class_name PlayerController
extends CharacterBody3D
## Bare first-person controller: WASD movement, mouse look, dive (Space, via the optional DiveState node).

## Emitted by take_hit. source_position is a Vector3 (attacker world position) or null when unknown.
signal hit_taken(damage: float, source_position: Variant)

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.0025
@export var max_pitch_degrees: float = 89.0

@onready var head: Node3D = $Head
@onready var heart_rate: HeartRate = $HeartRate
@onready var shift_ability: ShiftAbility = get_node_or_null("ShiftAbility")
@onready var dive_state: DiveState = get_node_or_null("DiveState")
@onready var player_time: PlayerTime = get_node_or_null("PlayerTime")
@onready var weapon_holder: WeaponHolder = $Head/Camera3D/WeaponHolder


## True after death (story 018): mouse look, movement input, dive and firing no longer act.
var input_locked: bool = false


func _ready() -> void:
	# Browsers only allow pointer lock after a user click; on web the first click captures
	# (see _unhandled_input), so capturing here would only fail with a console error.
	if not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Locks or unlocks player input (death collapse). Also stops the weapon holder firing.
func set_input_locked(locked: bool) -> void:
	input_locked = locked
	weapon_holder.set_physics_process(not locked)
	weapon_holder.set_process_unhandled_input(not locked)


func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		rotate_y(-motion.relative.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - motion.relative.y * mouse_sensitivity,
			-deg_to_rad(max_pitch_degrees), deg_to_rad(max_pitch_degrees))
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Hit contract: lowers heart rate by the hit's damage. direction (pushback) is not used yet.
## source_position is the attacker's world position (Vector3) or null when unknown; it is passed on
## through hit_taken so the HUD can show a direction arc. No source: no arc, no warning.
func take_hit(damage: float, _direction: Vector3, source_position: Variant = null) -> void:
	heart_rate.apply_hit(damage)
	hit_taken.emit(damage, source_position)


func _physics_process(delta: float) -> void:
	# Player time (story 016): pd is the player's delta. move_and_slide moves by velocity x the engine
	# (world-scaled) delta, so the velocity handed to it is multiplied by m, then divided back. The stored
	# velocity is therefore always in player-time units and never compounds from frame to frame.
	var m: float = 1.0 if player_time == null else maxf(player_time.get_delta_multiplier(), PlayerTime.MIN_MULTIPLIER)
	var pd: float = delta * m
	weapon_holder.aim_spread_multiplier = heart_rate.get_aim_spread_multiplier()
	weapon_holder.aim_tremor_degrees = heart_rate.get_aim_tremor()
	var speed_multiplier: float = heart_rate.get_speed_multiplier()
	if shift_ability != null:
		speed_multiplier *= shift_ability.get_speed_multiplier()
	var speed: float = move_speed * speed_multiplier
	var input_dir: Vector2 = Vector2.ZERO
	if not input_locked:
		input_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if dive_state != null:
		if not input_locked and Input.is_action_just_pressed(&"dive"):
			dive_state.try_start(input_dir, speed_multiplier)
		if dive_state.is_diving():
			# Normal WASD movement is suspended; the dive owns the velocity until IDLE.
			velocity = dive_state.compute_velocity(pd) * m
			move_and_slide()
			velocity /= m
			dive_state.finish_step(pd)
			return
	if not is_on_floor():
		velocity += get_gravity() * pd
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity *= m
	move_and_slide()
	velocity /= m
