extends Node
## Autoload `TutorialHost` (story 023). Drives the in-game tutorial: the opening before wave 1 and the
## moment hints. It only listens to signals of the other systems (heart rate, substances, weapon holder,
## player, dive, spawner, pickups, run end) and asks two small public gates: HeartRate.set_rate_limits and
## LevelRotation.set_wave_hold. Shown hints and the skip flag live in this autoload (memory only), so they
## survive reload_current_scene() and are gone on the next launch. Nothing is written to disk.
##
## Activation: only when the running game scene is the project main scene, or when the scene root has
## the meta `tutorial_enabled` = true (capture scenes). Other scenes (test_range, test_arena, game_*)
## are not touched. Debug meta on the game root (capture scenes): `tutorial_step` (opening id to start at,
## "none" = opening done), `tutorial_hold_wave` (bool, keep wave start held), `tutorial_set_rate` (bpm),
## `tutorial_moment` + `tutorial_moment_frames` (simulate a moment after N frames).
## All time is real time (RealClock).

## A hint went up.
signal hint_shown(id: StringName)
## A hint ended; completed is false when it was dropped without being finished.
signal hint_ended(id: StringName, completed: bool)
## The skip hold was completed.
signal tutorial_skipped
## The opening let wave 1 go (wave hold released).
signal opening_released

const DATA_PATH: String = "res://assets/data/tutorial/tutorial.tres"
const SKIP_ACTION: StringName = &"skip_tutorial"
const META_ENABLED: StringName = &"tutorial_enabled"
const META_STEP: StringName = &"tutorial_step"
const META_HOLD_WAVE: StringName = &"tutorial_hold_wave"
const META_SET_RATE: StringName = &"tutorial_set_rate"
const META_MOMENT: StringName = &"tutorial_moment"
const META_MOMENT_FRAMES: StringName = &"tutorial_moment_frames"
const STEP_NONE: String = "none"

const MOMENT_SLOW_ZONE: StringName = &"slow_zone"
const MOMENT_FAST_ZONE: StringName = &"fast_zone"
const MOMENT_DANGER: StringName = &"danger"
const MOMENT_FIRST_HIT: StringName = &"first_hit"
const MOMENT_EMPTY_GUN: StringName = &"empty_gun"
const MOMENT_PICKUP: StringName = &"pickup"
const MOMENT_DIVE: StringName = &"dive"

var data: TutorialData

var _clock: RealClock = RealClock.new()
var _box: HintBox
## Hint ids already shown this launch (persists across scene reloads).
var _shown: Dictionary = {}
var _skipped: bool = false

var _active: bool = false
var _game: LevelRotation
var _player: PlayerController
var _head: Node3D
var _heart: HeartRate
var _hud: Hud

var _current: TutorialHint
var _current_elapsed: float = 0.0
var _queue: Array[TutorialHint] = []
var _facts: Dictionary = {}
var _consuming: Dictionary = {}
var _gap_left: float = 0.0
var _start_delay_left: float = 0.0
var _skip_held: float = 0.0

var _opening_index: int = 0
var _opening_running: bool = false
var _opening_elapsed: float = 0.0
var _wave_started: bool = false
var _hold_active: bool = false
var _debug_hold: bool = false

var _has_prev: bool = false
var _prev_position: Vector3 = Vector3.ZERO
var _prev_yaw: float = 0.0
var _prev_pitch: float = 0.0
var _danger_active: bool = false

var _debug_moment: StringName = &""
var _debug_moment_frames: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	data = load(DATA_PATH) as TutorialData
	if data == null:
		push_error("TutorialHost: %s is missing or not TutorialData; tutorial disabled." % DATA_PATH)
		set_process(false)
		return
	_box = HintBox.new()
	add_child(_box)
	_box.setup(data)
	get_tree().node_added.connect(_on_node_added)
	# At launch the main scene is already in the tree when this autoload is ready (its _ready comes later).
	var launch_scene: LevelRotation = get_tree().current_scene as LevelRotation
	if launch_scene != null:
		_begin_scene(launch_scene)


func _process(delta: float) -> void:
	var real: float = _clock.step(delta)
	if not _active:
		return
	if not is_instance_valid(_game) or not is_instance_valid(_heart) or not is_instance_valid(_player) or not _player.is_inside_tree() or not _game.is_inside_tree():
		_end_runtime()
		return
	_box.tick(real)
	_track_motion(real)
	_update_skip(real)
	if not _active:
		return
	_update_debug_moment()
	_update_opening_cap(real)
	_check_release()
	_advance_opening()
	if _current != null:
		_update_current(real)
	else:
		_pick_next(real)


# ---- public API --------------------------------------------------------------------------------------

## True while the tutorial runs in the current scene.
func is_active() -> bool:
	return _active


## Id of the hint on screen, or an empty name.
func get_current_hint_id() -> StringName:
	return _current.id if _current != null else &""


## Ids of the hints shown so far this launch.
func get_shown_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _shown:
		ids.append(id)
	return ids


## Ids of the hints waiting to show.
func get_queue_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for h: TutorialHint in _queue:
		ids.append(h.id)
	return ids


## True once the player skipped the tutorial this launch.
func is_skipped() -> bool:
	return _skipped


## True while the host holds wave 1 back.
func is_wave_held() -> bool:
	return _hold_active


## True while the opening (wave hold phase) is running.
func is_opening_running() -> bool:
	return _opening_running


## Heart-rate limits now in force as (min, max); (-INF, INF) when none.
func get_heart_limits() -> Vector2:
	if is_instance_valid(_heart):
		return _heart.get_rate_limits()
	return Vector2(-INF, INF)


## Skip-hold progress 0-1.
func get_skip_progress() -> float:
	return clampf(_skip_held / maxf(data.skip_hold_seconds, 0.001), 0.0, 1.0)


## Seconds the current hint has been up.
func get_current_elapsed() -> float:
	return _current_elapsed


## The on-screen hint view.
func get_box() -> HintBox:
	return _box


## Value of a goal fact for the current hint: moved, turned, shots, held_<kind>.
func get_fact(fact_name: StringName) -> float:
	return float(_facts.get(fact_name, 0.0))


## Forgets everything shown and the skip flag (probes; a real launch never calls this).
func reset_progress() -> void:
	_shown.clear()
	_skipped = false


## Ends the tutorial for the rest of the launch: hides the hint, drops the queue, releases the wave hold
## and the heart limits.
func skip() -> void:
	if _skipped:
		return
	_skipped = true
	_release_gates()
	_end_runtime()
	tutorial_skipped.emit()


## Fires a moment as if it just happened (capture scenes and probes).
func simulate_moment(moment: StringName) -> void:
	_on_moment(moment)


## Replaces {Tokens} in a text with the keys of the bound input actions.
func resolve_text(text: String) -> String:
	var out: String = text
	for i: int in mini(data.placeholder_names.size(), data.placeholder_actions.size()):
		out = out.replace("{%s}" % data.placeholder_names[i], label_for_action(StringName(data.placeholder_actions[i])))
	for i: int in mini(data.fixed_placeholder_names.size(), data.fixed_placeholder_values.size()):
		out = out.replace("{%s}" % data.fixed_placeholder_names[i], data.fixed_placeholder_values[i])
	return out.replace("{%s}" % data.move_placeholder, _move_label())


## Display label of the first keyboard/mouse (else pad) binding of an action.
func label_for_action(action: StringName) -> String:
	if not InputMap.has_action(action):
		return data.unbound_label
	var pad_label: String = ""
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			return _key_label(key)
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse != null:
			return _mouse_label(mouse.button_index)
		var pad: InputEventJoypadButton = event as InputEventJoypadButton
		if pad != null and pad_label == "":
			pad_label = data.joypad_button_format % pad.button_index
	return pad_label if pad_label != "" else data.unbound_label


# ---- activation --------------------------------------------------------------------------------------

func _on_node_added(node: Node) -> void:
	if node is LevelRotation:
		_begin_scene(node as LevelRotation)
	elif _active and node is DropPickup:
		var pickup: DropPickup = node as DropPickup
		if not pickup.collected.is_connected(_on_pickup_collected):
			pickup.collected.connect(_on_pickup_collected)


func _begin_scene(game: LevelRotation) -> void:
	_end_runtime()
	if _skipped:
		return
	var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if not (bool(game.get_meta(META_ENABLED, false)) or game.scene_file_path == main_scene):
		return
	_game = game
	_apply_debug_step(game)
	_debug_hold = bool(game.get_meta(META_HOLD_WAVE, false))
	_hold_active = _debug_hold or _opening_holds_pending()
	if _hold_active:
		game.set_wave_hold(true)
	_bind.call_deferred(game)


func _bind(game: LevelRotation) -> void:
	if not is_instance_valid(game) or game != _game:
		return
	if not game.is_inside_tree():
		_abort_bind()
		return
	_player = game.player as PlayerController
	_heart = game.heart
	if _player == null or _heart == null:
		_abort_bind()
		return
	_head = _player.get_node_or_null("Head") as Node3D
	_hud = null
	for n: Node in get_tree().get_nodes_in_group(HeartRateScreen.CAMERA_MIRROR_GROUP):
		if n is Hud:
			_hud = n as Hud
	_box.set_hud(_hud)
	_connect_signals(game)
	_current = null
	_current_elapsed = 0.0
	_queue.clear()
	_facts.clear()
	_consuming.clear()
	_skip_held = 0.0
	_gap_left = 0.0
	_start_delay_left = data.start_delay_seconds
	_opening_index = 0
	_opening_elapsed = 0.0
	_wave_started = false
	_has_prev = false
	_danger_active = false
	_opening_running = _hold_active and not _debug_hold
	if _opening_pending():
		_heart.set_rate_limits(data.opening_heart_min, data.opening_heart_max)
	_active = true
	_apply_debug_rate_and_moment(game)


## A bind that cannot finish gives back what _begin_scene took: the wave hold and any heart limits.
func _abort_bind() -> void:
	_release_gates()
	_end_runtime()


func _connect_signals(game: LevelRotation) -> void:
	_heart.zone_changed.connect(_on_zone_changed)
	_heart.danger_countdown_changed.connect(_on_countdown_changed)
	_heart.run_ended.connect(_on_run_ended)
	game.run_state.run_ended.connect(_on_run_ended)
	game.spawner.wave_started.connect(_on_wave_started)
	_player.hit_taken.connect(_on_hit_taken)
	var holder: WeaponHolder = _player.get_node_or_null("Head/Camera3D/WeaponHolder") as WeaponHolder
	if holder != null:
		holder.shot_fired.connect(_on_shot_fired)
		holder.dry_fired.connect(_on_dry_fired)
	var inventory: SubstanceInventory = _player.get_node_or_null("SubstanceInventory") as SubstanceInventory
	if inventory != null:
		inventory.consume_started.connect(_on_consume_started)
		inventory.consume_ended.connect(_on_consume_ended)
	var dive: DiveState = _player.get_node_or_null("DiveState") as DiveState
	if dive != null:
		dive.dive_started.connect(_on_dive_started)


func _apply_debug_step(game: LevelRotation) -> void:
	var step: String = str(game.get_meta(META_STEP, ""))
	if step == "":
		return
	for id: String in data.opening:
		if step != STEP_NONE and id == step:
			break
		_shown[StringName(id)] = true


func _apply_debug_rate_and_moment(game: LevelRotation) -> void:
	if game.has_meta(META_SET_RATE):
		_heart.change_rate(float(game.get_meta(META_SET_RATE)) - _heart.get_rate())
	if game.has_meta(META_MOMENT):
		_debug_moment = StringName(str(game.get_meta(META_MOMENT)))
		_debug_moment_frames = int(game.get_meta(META_MOMENT_FRAMES, 1))


func _update_debug_moment() -> void:
	if _debug_moment == &"":
		return
	_debug_moment_frames -= 1
	if _debug_moment_frames <= 0:
		var moment: StringName = _debug_moment
		_debug_moment = &""
		_on_moment(moment)


## Stops showing and forgets the scene (the persistent shown set stays).
func _end_runtime() -> void:
	_active = false
	_current = null
	_queue.clear()
	_opening_running = false
	_danger_active = false
	if _box != null:
		_box.hide_hint()


func _release_gates() -> void:
	if is_instance_valid(_game) and _game.is_wave_held():
		_game.set_wave_hold(false)
	_hold_active = false
	_opening_running = false
	_clear_limits()


func _clear_limits() -> void:
	if is_instance_valid(_heart):
		_heart.clear_rate_limits()


# ---- opening -----------------------------------------------------------------------------------------

func _opening_pending() -> bool:
	for id: String in data.opening:
		if not _shown.has(StringName(id)):
			return true
	return false


func _opening_holds_pending() -> bool:
	for id: String in data.opening:
		var h: TutorialHint = data.get_hint(StringName(id))
		if h != null and h.holds_wave and not _shown.has(h.id):
			return true
	return false


func _advance_opening() -> void:
	if _opening_index >= data.opening.size():
		return
	var h: TutorialHint = data.get_hint(StringName(data.opening[_opening_index]))
	if h == null or _shown.has(h.id):
		_opening_index += 1
		return
	if h.requires_wave_start and not _wave_started:
		return
	if _current == h or _queue.has(h):
		return
	_queue.append(h)


func _check_release() -> void:
	if not _opening_running or _opening_holds_pending():
		return
	_release_opening()


func _release_opening() -> void:
	_opening_running = false
	if _hold_active and not _debug_hold and is_instance_valid(_game):
		_game.set_wave_hold(false)
		_hold_active = false
	opening_released.emit()
	_fire_current_state_moments()


func _update_opening_cap(real: float) -> void:
	if not _opening_running:
		return
	_opening_elapsed += real
	if _opening_elapsed < data.opening_cap_seconds:
		return
	for id: String in data.opening:
		var h: TutorialHint = data.get_hint(StringName(id))
		if h != null and h.holds_wave:
			_shown[h.id] = true
			_queue.erase(h)
			if _current == h:
				_end_current(true)
	_release_opening()


# ---- hint life ---------------------------------------------------------------------------------------

func _pick_next(real: float) -> void:
	_start_delay_left = maxf(_start_delay_left - real, 0.0)
	_gap_left -= real
	for h: TutorialHint in _queue.duplicate():
		if h.moment != &"" and not _moment_valid(h):
			_queue.erase(h)
	var best: TutorialHint = null
	for h: TutorialHint in _queue:
		if best == null or h.priority > best.priority:
			best = h
	if best == null:
		return
	if (_start_delay_left > 0.0 or _gap_left > 0.0) and not best.danger:
		return
	_queue.erase(best)
	_start_hint(best)


func _start_hint(h: TutorialHint) -> void:
	_current = h
	_current_elapsed = 0.0
	_facts.clear()
	_box.show_hint(resolve_text(h.text), resolve_text(data.skip_text), h.targets, h.danger)
	_box.set_skip_progress(get_skip_progress())
	hint_shown.emit(h.id)


func _update_current(real: float) -> void:
	_current_elapsed += real
	var h: TutorialHint = _current
	if not h.danger and h.goals.is_empty() and _danger_waiting():
		_end_current(true)
		_gap_left = 0.0
		return
	if _current_elapsed < h.min_seconds:
		return
	if h.danger and h.moment != &"" and not _moment_valid(h):
		_end_current(true)
		return
	var limit: float = h.max_seconds
	if limit <= 0.0 and h.goals.is_empty():
		limit = data.default_info_seconds
	if limit > 0.0 and _current_elapsed >= limit:
		_end_current(true)
		return
	if not h.goals.is_empty() and _goals_met(h):
		_end_current(true)


func _danger_waiting() -> bool:
	for h: TutorialHint in _queue:
		if h.danger:
			return true
	return false


func _end_current(completed: bool) -> void:
	var h: TutorialHint = _current
	if h == null:
		return
	if completed:
		_shown[h.id] = true
	_current = null
	_gap_left = data.gap_seconds
	_box.hide_hint()
	hint_ended.emit(h.id, completed)
	if completed and h.requires_wave_start and not _wave_hint_pending():
		_fire_current_state_moments()


func _goals_met(h: TutorialHint) -> bool:
	for g: TutorialGoal in h.goals:
		if _goal_value(g) < g.amount:
			return false
	return true


func _goal_value(g: TutorialGoal) -> float:
	match g.fact:
		TutorialGoal.FACT_MOVED_METERS:
			return get_fact(&"moved")
		TutorialGoal.FACT_TURNED_DEGREES:
			return get_fact(&"turned")
		TutorialGoal.FACT_SUBSTANCE_HELD_SECONDS:
			return get_fact(StringName("held_" + String(g.substance)))
		TutorialGoal.FACT_SHOTS_FIRED:
			return get_fact(&"shots")
	return 0.0


func _add_fact(fact_name: StringName, amount: float) -> void:
	if _current != null:
		_facts[fact_name] = float(_facts.get(fact_name, 0.0)) + amount


func _track_motion(real: float) -> void:
	var position: Vector3 = _player.global_position
	var yaw: float = _player.rotation.y
	var pitch: float = _head.rotation.x if _head != null else 0.0
	if _has_prev:
		var step: float = Vector2(position.x - _prev_position.x, position.z - _prev_position.z).length()
		if step <= data.motion_max_step_meters:
			_add_fact(&"moved", step)
		_add_fact(&"turned", rad_to_deg(absf(angle_difference(_prev_yaw, yaw)) + absf(angle_difference(_prev_pitch, pitch))))
	_has_prev = true
	_prev_position = position
	_prev_yaw = yaw
	_prev_pitch = pitch
	for kind: StringName in _consuming:
		if _consuming[kind]:
			_add_fact(StringName("held_" + String(kind)), real)


func _update_skip(real: float) -> void:
	if Input.is_action_pressed(SKIP_ACTION):
		_skip_held += real
	else:
		_skip_held = 0.0
	_box.set_skip_progress(get_skip_progress())
	if _skip_held >= maxf(data.skip_hold_seconds, 0.001):
		skip()


# ---- moments -----------------------------------------------------------------------------------------

func _moment_valid(h: TutorialHint) -> bool:
	if not is_instance_valid(_heart):
		return false
	match h.moment:
		MOMENT_SLOW_ZONE:
			return _heart.get_zone() == HeartRate.Zone.SLOW
		MOMENT_FAST_ZONE:
			return _heart.get_zone() == HeartRate.Zone.FAST
		MOMENT_DANGER:
			return _heart.get_countdown_left() > 0.0
	return true


func _on_moment(moment: StringName) -> void:
	if not _active or _skipped or _opening_running:
		return
	# Until the wave-start hint ("shoot") has been shown only a danger hint may go ahead of it; the zone the
	# player is in then counts as entered once it ends (_fire_current_state_moments).
	if moment != MOMENT_DANGER and _wave_hint_pending():
		return
	var h: TutorialHint = data.get_moment_hint(moment)
	if h == null or _shown.has(h.id) or _current == h or _queue.has(h) or not _moment_valid(h):
		return
	_queue.append(h)


## True while an opening hint that waits for wave 1 has not been shown yet.
func _wave_hint_pending() -> bool:
	for id: String in data.opening:
		var h: TutorialHint = data.get_hint(StringName(id))
		if h != null and h.requires_wave_start and not _shown.has(h.id):
			return true
	return false


## After the opening: the zone the player is already in counts as entered.
func _fire_current_state_moments() -> void:
	match _heart.get_zone():
		HeartRate.Zone.SLOW:
			_on_moment(MOMENT_SLOW_ZONE)
		HeartRate.Zone.FAST:
			_on_moment(MOMENT_FAST_ZONE)
	if _heart.get_countdown_left() > 0.0:
		_on_moment(MOMENT_DANGER)


func _on_zone_changed(zone: HeartRate.Zone, _previous: HeartRate.Zone) -> void:
	if zone == HeartRate.Zone.SLOW:
		_on_moment(MOMENT_SLOW_ZONE)
	elif zone == HeartRate.Zone.FAST:
		_on_moment(MOMENT_FAST_ZONE)


func _on_countdown_changed(seconds_left: float, reason: StringName) -> void:
	var running: bool = seconds_left > 0.0 and reason != &""
	if running and not _danger_active:
		_on_moment(MOMENT_DANGER)
	_danger_active = running


func _on_hit_taken(_damage: float, _source: Variant) -> void:
	_on_moment(MOMENT_FIRST_HIT)


func _on_dry_fired(_gun: GunData) -> void:
	_on_moment(MOMENT_EMPTY_GUN)


func _on_pickup_collected(_kind: StringName) -> void:
	_on_moment(MOMENT_PICKUP)


func _on_dive_started(_direction: Vector3) -> void:
	_on_moment(MOMENT_DIVE)


func _on_shot_fired(_gun: GunData) -> void:
	_add_fact(&"shots", 1.0)


func _on_consume_started(kind: StringName) -> void:
	_consuming[kind] = true


func _on_consume_ended(kind: StringName) -> void:
	_consuming[kind] = false


func _on_wave_started(_wave: int) -> void:
	_wave_started = true
	_clear_limits()


func _on_run_ended(_reason: StringName) -> void:
	_end_runtime()


# ---- labels ------------------------------------------------------------------------------------------

func _key_label(key: InputEventKey) -> String:
	var code: Key = key.physical_keycode
	if code != KEY_NONE:
		var mapped: Key = KEY_NONE
		# Headless and web display servers do not support layout lookup (it errors every call).
		if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
			mapped = DisplayServer.keyboard_get_keycode_from_physical(code)
		return OS.get_keycode_string(mapped if mapped != KEY_NONE else code)
	return OS.get_keycode_string(key.keycode)


func _mouse_label(button_index: int) -> String:
	if button_index > 0 and button_index < data.mouse_button_labels.size() and data.mouse_button_labels[button_index] != "":
		return data.mouse_button_labels[button_index]
	return data.mouse_button_fallback_format % button_index


func _move_label() -> String:
	var labels: PackedStringArray = PackedStringArray()
	var single: bool = true
	for action: String in data.move_actions:
		var label: String = label_for_action(StringName(action))
		labels.append(label)
		single = single and label.length() == 1
	return "".join(labels) if single else "/".join(labels)
