class_name DropData
extends Resource
## Pickup tuning shared by every drop (Unity ammo_drops.json + dose_drops.json values, and the look of the Unity
## pickups: AmmoDrops in Game.unity and the DosePickup_coffee / DosePickup_cigarette prefabs).

@export var smg_rounds: int = 30
@export var shotgun_rounds: int = 6
@export var dose_amount: int = 1
@export var pickup_lifetime: float = 20.0
## Seconds at the end of the lifetime in which the pickup blinks (0 = no blinking).
@export var blink_time: float = 4.0
## Flashes (off then on) per second while blinking: off for the second half of each 1 / blink_rate cycle.
@export var blink_rate: float = 3.0
## Horizontal distance from the player's root to the pickup's resting point at which it is collected.
@export var pickup_radius: float = 1.5
## Most height difference between the player's root and the resting point that still collects (Godot guard;
## Unity compares the horizontal distance only).
@export var pickup_height_tolerance: float = 2.5
@export var ammo_cap: int = 12
@export var dose_cap: int = 12
## Distance from the dead enemy at which a single drop lands.
@export var drop_offset: float = 0.6
## Radius over which several guaranteed drops (boss) are spread.
@export var drop_spread_radius: float = 1.2

@export_group("Floor")
## The floor probe starts this far above the drop position (Unity DoseDrops FloorProbeUp)...
@export var floor_probe_up: float = 1.0
## ...and reaches this far below it (Unity FloorProbeDown). No hit: the drop position is the floor.
@export var floor_probe_down: float = 3.0
## Physics layers a dropped pickup can rest on.
@export_flags_3d_physics var floor_collision_mask: int = 1
## Height of the resting point above the floor.
@export var hover_height: float = 0.6

@export_group("Motion")
## Height of the bob either side of the resting point.
@export var bob_height: float = 0.12
## Speed of the bob in radians per second (Unity: sin(age * bob_speed)).
@export var bob_speed: float = 2.0
## Degrees per second about the vertical axis, clockwise seen from above (Unity's positive Y turn).
@export var spin_speed_degrees: float = 90.0

@export_group("Look")
@export var ammo_model: PackedScene
@export var coffee_model: PackedScene
@export var cigarette_model: PackedScene
## Unlit manprop material every drop model draws with (Unity manpropUnlit.mat, the FBX slot remap).
@export var model_material: Material
## Extra rotation of each imported FBX so it faces the way Unity shows it (Unity mirrors X on import).
@export var fbx_rotation_degrees: Vector3 = Vector3(0.0, 180.0, 0.0)
## Scale of the ammo model (Unity ammo_drops.json box_size, applied to the drop_ammo mesh).
@export var ammo_model_scale: Vector3 = Vector3(0.35, 0.2, 0.25)
## Scale of the coffee and cigarette models (the Unity prefabs keep the FBX at its own size).
@export var dose_model_scale: Vector3 = Vector3.ONE
## Ammo tint per gun (ammo_drops.json pickups[].color), multiplied into the manprop texture.
@export var smg_color: Color = Color(0.95, 0.8, 0.2)
@export var shotgun_color: Color = Color(0.9, 0.25, 0.2)
## Whether the blink also hides the dose model. Unity's dose prefabs list only the (inactive) Shape and the Glow
## renderers, so in Unity only the glow blinks and the model stays on; the ammo box always blinks.
@export var dose_blink_hides_model: bool = false
## Pickup renderers cast no shadows (Unity: shadow casting off, no receive).
@export var cast_shadows: bool = false

@export_group("Glow")
## Additive glow quad behind each dose pickup, always facing the camera (Unity DosePickupGlow_*.mat, flare_01).
@export var glow_texture: Texture2D
## Edge length of the glow quad (dose_drops.json glow_size; 0 hides it).
@export var glow_size: float = 0.9
@export var coffee_glow_color: Color = Color(1.0, 0.6, 0.15, 1.0)
@export var cigarette_glow_color: Color = Color(1.0, 0.45, 0.1, 0.7)
## Height of the glow centre above the pickup root (prefab Glow child local Y).
@export var coffee_glow_height: float = 0.055
@export var cigarette_glow_height: float = 0.128

@export_group("Sound")
## Played (non-spatial) when a dose pickup is collected (Unity DoseDrops _pickupClip). Unity ammo has no sound.
@export var dose_pickup_sound: AudioStream
@export var ammo_pickup_sound: AudioStream
## Linear volume of the pickup sound (dose_drops.json pickup_volume).
@export_range(0.0, 1.0, 0.01) var pickup_volume: float = 0.8
@export var pickup_sound_bus: StringName = &"SFX"

## Runtime cache (not saved): the tinted ammo materials and glow materials built from this data, shared by
## every pickup of a kind.
var runtime_materials: Dictionary = {}


## Returns the ammo tint for a pickup kind (&"smg", &"shotgun"); white for the doses (untinted).
func get_color(kind: StringName) -> Color:
	match kind:
		&"smg":
			return smg_color
		&"shotgun":
			return shotgun_color
	return Color.WHITE


## Returns the model scene for a pickup kind, or null.
func get_model(kind: StringName) -> PackedScene:
	match kind:
		&"smg", &"shotgun":
			return ammo_model
		&"coffee":
			return coffee_model
	return cigarette_model


## Returns the glow colour of a dose kind; transparent (no glow) for ammo.
func get_glow_color(kind: StringName) -> Color:
	match kind:
		&"coffee":
			return coffee_glow_color
		&"cigarette":
			return cigarette_glow_color
	return Color(0.0, 0.0, 0.0, 0.0)


## Returns the glow height above the pickup root for a dose kind.
func get_glow_height(kind: StringName) -> float:
	return coffee_glow_height if kind == &"coffee" else cigarette_glow_height


## Returns the pickup sound for a kind, or null.
func get_pickup_sound(kind: StringName) -> AudioStream:
	if kind == &"smg" or kind == &"shotgun":
		return ammo_pickup_sound
	return dose_pickup_sound
