class_name SfxPlayer
extends AudioEmitter
## Gun, impact and substance sounds. Listens to WeaponHolder and SubstanceInventory; the on_* methods are
## public so a probe can trigger every reaction without input. Shots, clicks and reloads are 2D voices;
## flesh, kill and surface impacts come from a capped pool of AudioStreamPlayer3D voices.
##
## Order note: Gun emits shot_hit for every pellet BEFORE shot_fired, so on_shot_fired closes a shot and
## resets the per-shot flesh / kill / surface counters.

@export var config: AudioConfig
@export var holder: WeaponHolder
@export var substances: SubstanceInventory

var _players_2d: Array[AudioStreamPlayer] = []
var _next_2d: int = 0
var _players_3d: Array[AudioStreamPlayer3D] = []
var _next_3d: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_pick: Dictionary = {}
var _consume_voices: Dictionary = {}
var _consume_counts: Dictionary = {}
var _flesh_played: int = 0
var _kill_played: int = 0
var _surface_played: int = 0
var _reload_gun: Gun = null
var _reload_done: Array[bool] = []
# Gun voice rings (Unity GunFeedback): ring name -> Array[AudioStreamPlayer]; _ring_next: ring name -> next index.
var _rings: Dictionary = {}
var _ring_next: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i: int in config.voices_2d:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = config.sfx_bus
		add_child(voice)
		_players_2d.append(voice)
	_build_ring(&"shot", config.shot_voices)
	_build_ring(&"tail", config.tail_voices)
	_build_ring(&"thump", config.thump_voices)
	_build_ring(&"reload", config.reload_voices)
	_build_ring(&"dry_click", config.dry_click_voices)
	for i: int in config.voice_cap_3d:
		var voice_3d: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		voice_3d.bus = config.sfx_bus
		voice_3d.max_distance = config.max_distance
		voice_3d.unit_size = config.min_distance
		add_child(voice_3d)
		_players_3d.append(voice_3d)
	for entry: ConsumeSoundData in config.consume_sounds:
		var loop: LoopVoice = LoopVoice.new()
		add_child(loop)
		loop.setup(entry.clip, config.sfx_bus, entry.volume)
		_consume_voices[entry.substance_id] = loop
	if holder != null:
		holder.shot_fired.connect(on_shot_fired)
		holder.dry_fired.connect(on_dry_fired)
		holder.shot_hit.connect(on_shot_hit)
		holder.reloaded.connect(on_reloaded)
		holder.shell_loaded.connect(on_shell_loaded)
	if substances != null:
		substances.consume_started.connect(on_consume_started)
		substances.consume_ended.connect(on_consume_ended)
		substances.count_changed.connect(on_count_changed)
		for kind: StringName in SubstanceInventory.KINDS:
			_consume_counts[kind] = substances.get_count(kind)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Advances consume fades and the reload sound timeline. real_delta is in real seconds.
func tick(real_delta: float) -> void:
	for kind: StringName in _consume_voices:
		(_consume_voices[kind] as LoopVoice).tick(real_delta)
	_update_reload()


## Plays the gun's shot take (rotated), plus tail and thump layers, then closes the shot (resets the hit caps).
## One pitch and one volume factor are drawn per shot and shared by every layer (Unity), so the layers stay coherent.
func on_shot_fired(data: GunData) -> void:
	var gun_audio: GunAudioData = config.get_gun_audio(data.gun_id)
	if gun_audio != null:
		var gun_name: String = String(data.gun_id)
		var pitch: float = 1.0 + _rng.randf_range(-gun_audio.shot_pitch_variation, gun_audio.shot_pitch_variation)
		var factor: float = 1.0 + _rng.randf_range(-gun_audio.shot_volume_variation, gun_audio.shot_volume_variation)
		_play_ring(&"shot", StringName("shot_" + gun_name), _pick(gun_audio.shot_clips, &"shot_" + data.gun_id),
				gun_audio.shot_volume * factor, pitch)
		if gun_audio.use_tail:
			_play_ring(&"tail", StringName("shot_tail_" + gun_name), _pick(gun_audio.tail_clips, &"tail_" + data.gun_id),
					gun_audio.tail_volume * factor, pitch)
		if gun_audio.use_thump:
			_play_ring(&"thump", StringName("shot_thump_" + gun_name),
					_pick(gun_audio.thump_clips, &"thump_" + data.gun_id), gun_audio.thump_volume * factor, pitch)
	_flesh_played = 0
	_kill_played = 0
	_surface_played = 0


## Plays the dry click (rotated takes) on its own ring.
func on_dry_fired(_data: GunData) -> void:
	_play_ring(&"dry_click", &"dry_click", _pick(config.dry_click_clips, &"dry_click"), config.dry_click_volume, 1.0)


## A reload completed: plays any fraction part still waiting (so the parts keep their order), then the finish
## parts (rack or pump).
func on_reloaded(gun_id: StringName) -> void:
	var gun_audio: GunAudioData = config.get_gun_audio(gun_id)
	if gun_audio == null:
		return
	if _reload_gun != null and _reload_gun.data.gun_id == gun_id and _reload_done.size() == gun_audio.reload_parts.size():
		for i: int in gun_audio.reload_parts.size():
			var part: ReloadSoundPart = gun_audio.reload_parts[i]
			if part.trigger == ReloadSoundPart.Trigger.FRACTION and not _reload_done[i]:
				play_reload_part(gun_audio, part)
	_reload_gun = null
	for part: ReloadSoundPart in gun_audio.reload_parts:
		if part.trigger == ReloadSoundPart.Trigger.FINISH:
			play_reload_part(gun_audio, part)


## A shell-by-shell reload loaded one shell: plays the shell parts.
func on_shell_loaded(gun_id: StringName) -> void:
	var gun_audio: GunAudioData = config.get_gun_audio(gun_id)
	if gun_audio == null:
		return
	for part: ReloadSoundPart in gun_audio.reload_parts:
		if part.trigger == ReloadSoundPart.Trigger.SHELL:
			play_reload_part(gun_audio, part)


## Plays an impact at the hit point: flesh for a damageable hit, the heavier kill sound for a kill, a surface
## sound for the world. Each is capped per shot (config flesh_per_shot, kill_per_shot, surface_sounds_per_shot).
func on_shot_hit(position: Vector3, _normal: Vector3, collider: Object, damageable: bool,
		killed: bool, _direction: Vector3) -> void:
	if damageable and killed:
		if _kill_played < config.kill_per_shot:
			_kill_played += 1
			_play_3d(&"kill", _pick(config.kill_clips, &"kill"), position, config.kill_volume, config.kill_pitch_variation)
	elif damageable:
		if _flesh_played < config.flesh_per_shot:
			_flesh_played += 1
			_play_3d(&"hit", _pick(config.flesh_clips, &"flesh"), position, config.flesh_volume, config.flesh_pitch_variation)
	elif not _is_dead_body(collider) and _surface_played < config.surface_sounds_per_shot:
		_surface_played += 1
		_play_3d(&"surface", _pick(config.surface_clips, &"surface"), position, config.surface_volume, config.surface_pitch_variation)


## Starts the consume loop of a substance kind (fade in).
func on_consume_started(kind: StringName) -> void:
	var loop: LoopVoice = _consume_voices.get(kind) as LoopVoice
	if loop == null:
		return
	loop.fade_to(1.0, config.consume_fade_in_seconds)
	_record(&"consume_start", loop.player.stream, loop.get_volume_db())


## Fades the consume loop out (it stops when silent).
func on_consume_ended(kind: StringName) -> void:
	var loop: LoopVoice = _consume_voices.get(kind) as LoopVoice
	if loop == null:
		return
	loop.fade_to(0.0, config.consume_fade_out_seconds)
	_record(&"consume_stop", loop.player.stream, loop.get_volume_db())


## Plays the substance-taken sound each time a count drops (a unit used up).
func on_count_changed(kind: StringName, count: int) -> void:
	var previous: int = _consume_counts.get(kind, count) as int
	_consume_counts[kind] = count
	if count < previous:
		_play_2d(&"substance_taken", config.substance_taken_clip, config.substance_taken_volume, 0.0, 0.0)


## True while the consume loop of a kind is active (including its fade-out).
func is_consume_playing(kind: StringName) -> bool:
	var loop: LoopVoice = _consume_voices.get(kind) as LoopVoice
	return loop != null and loop.is_active()


## Consume loop level 0-1 (relative to its volume).
func get_consume_level(kind: StringName) -> float:
	var loop: LoopVoice = _consume_voices.get(kind) as LoopVoice
	return 0.0 if loop == null else loop.get_level()


## Number of 3D voices in the pool (the cap).
func get_voice_count_3d() -> int:
	return _players_3d.size()


func _update_reload() -> void:
	var gun: Gun = null if holder == null else holder.get_current_gun()
	if _reload_gun != null and gun != _reload_gun:
		# A weapon switch cancelled the reload: stop every reload sound (Unity); shots and clicks ring on.
		stop_ring(&"reload")
		_reload_gun = null
	if gun == null or not gun.is_reloading():
		_reload_gun = null
		return
	var gun_audio: GunAudioData = config.get_gun_audio(gun.data.gun_id)
	if gun_audio == null:
		return
	if _reload_gun != gun or gun.get_reload_progress() < 0.0:
		_reload_gun = gun
		_reload_done.clear()
		_reload_done.resize(gun_audio.reload_parts.size())
		_reload_done.fill(false)
	var progress: float = gun.get_reload_progress()
	for i: int in gun_audio.reload_parts.size():
		var part: ReloadSoundPart = gun_audio.reload_parts[i]
		if part.trigger == ReloadSoundPart.Trigger.FRACTION and not _reload_done[i] and progress >= part.fraction:
			_reload_done[i] = true
			play_reload_part(gun_audio, part)


## Plays one reload part on the reload ring (also callable by a probe).
func play_reload_part(gun_audio: GunAudioData, part: ReloadSoundPart) -> void:
	var event: StringName = StringName("reload_%s_%s" % [gun_audio.gun_id, part.event_id])
	var volume: float = part.volume if part.volume >= 0.0 else gun_audio.reload_volume
	_play_ring(&"reload", event, _pick(part.clips, event), volume, 1.0)


## Stops every voice of a ring.
func stop_ring(ring: StringName) -> void:
	for voice: AudioStreamPlayer in _rings.get(ring, []):
		voice.stop()


## Voices of a ring (for probes).
func get_ring(ring: StringName) -> Array:
	return _rings.get(ring, [])


func _build_ring(ring: StringName, count: int) -> void:
	var voices: Array[AudioStreamPlayer] = []
	for i: int in maxi(count, 1):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "%sVoice%d" % [String(ring).capitalize().replace(" ", ""), i]
		voice.bus = config.sfx_bus
		add_child(voice)
		voices.append(voice)
	_rings[ring] = voices
	_ring_next[ring] = 0


## One sound on the ring's next voice, which cuts whatever that voice still played (the ring's oldest sound).
func _play_ring(ring: StringName, event_id: StringName, stream: AudioStream, volume: float, pitch: float) -> void:
	var voices: Array = _rings.get(ring, [])
	if stream == null or voices.is_empty():
		return
	var index: int = _ring_next[ring] as int
	_ring_next[ring] = (index + 1) % voices.size()
	var voice: AudioStreamPlayer = voices[index] as AudioStreamPlayer
	voice.stop()
	voice.stream = stream
	voice.volume_db = linear_to_db(maxf(volume, 0.0001))
	voice.pitch_scale = pitch
	voice.play()
	_record(event_id, stream, voice.volume_db)


func _is_dead_body(collider: Object) -> bool:
	var node: Node = collider as Node
	for i: int in 2:
		if node == null:
			return false
		if node.has_method(&"is_dead") and node.call(&"is_dead") as bool:
			return true
		node = node.get_parent()
	return false


## Picks a clip, never the same one twice in a row for the same key.
func _pick(clips: Array[AudioStream], key: StringName) -> AudioStream:
	if clips.is_empty():
		return null
	var index: int = 0
	if clips.size() > 1:
		var last: int = _last_pick.get(key, -1) as int
		index = _rng.randi_range(0, clips.size() - 2)
		if index >= last and last >= 0:
			index += 1
	_last_pick[key] = index
	return clips[index]


func _volume_with_variation(volume: float, variation: float) -> float:
	return maxf(volume * (1.0 + _rng.randf_range(-variation, variation)), 0.0001)


func _play_2d(event_id: StringName, stream: AudioStream, volume: float, pitch_variation: float,
		volume_variation: float) -> void:
	if stream == null or _players_2d.is_empty():
		return
	var voice: AudioStreamPlayer = null
	for candidate: AudioStreamPlayer in _players_2d:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		voice = _players_2d[_next_2d]
		_next_2d = (_next_2d + 1) % _players_2d.size()
	voice.stream = stream
	voice.volume_db = linear_to_db(_volume_with_variation(volume, volume_variation))
	voice.pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	voice.play()
	_record(event_id, stream, voice.volume_db)


func _play_3d(event_id: StringName, stream: AudioStream, position: Vector3, volume: float,
		pitch_variation: float) -> void:
	if stream == null or _players_3d.is_empty():
		return
	var voice: AudioStreamPlayer3D = null
	for candidate: AudioStreamPlayer3D in _players_3d:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		voice = _players_3d[_next_3d]
		_next_3d = (_next_3d + 1) % _players_3d.size()
	voice.stream = stream
	voice.global_position = position
	voice.volume_db = linear_to_db(maxf(volume, 0.0001))
	voice.pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	voice.play()
	_record(event_id, stream, voice.volume_db, position)
