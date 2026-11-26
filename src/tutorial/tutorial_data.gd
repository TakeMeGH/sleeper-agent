class_name TutorialData
extends Resource
## All tutorial numbers, texts, colours and sizes (assets/data/tutorial/tutorial.tres).
## Pixel sizes are authored for `reference_height` (1080p) and scaled by viewport height / reference_height.

@export_group("Timing")
## Seconds after the scene starts before the first hint (real time).
@export var start_delay_seconds: float = 1.5
## Pause between two hints.
@export var gap_seconds: float = 0.6
## The opening releases wave 1 after this many seconds even if its steps are not done.
@export var opening_cap_seconds: float = 90.0
## Seconds an information hint without max_seconds stays up.
@export var default_info_seconds: float = 4.0
## Hold the skip action this long (real seconds) to skip the tutorial.
@export var skip_hold_seconds: float = 1.5
## A per-frame move bigger than this many metres is a teleport (level load) and not counted.
@export var motion_max_step_meters: float = 2.0

@export_group("Heart limits")
@export var opening_heart_min: float = 40.0
@export var opening_heart_max: float = 160.0

@export_group("Hints")
## Opening step ids in order.
@export var opening: PackedStringArray = PackedStringArray()
@export var hints: Array[TutorialHint] = []

@export_group("Texts")
@export var skip_text: String = "Hold {SkipTutorial} to skip the tutorial"
## {Token} names and the input action each shows the key of (parallel arrays).
@export var placeholder_names: PackedStringArray = PackedStringArray()
@export var placeholder_actions: PackedStringArray = PackedStringArray()
## Fixed labels for tokens that are no single action (parallel arrays).
@export var fixed_placeholder_names: PackedStringArray = PackedStringArray()
@export var fixed_placeholder_values: PackedStringArray = PackedStringArray()
## Token that shows the movement keys composed from move_actions.
@export var move_placeholder: String = "Move"
@export var move_actions: PackedStringArray = PackedStringArray()
## Label per mouse button index (index 0 unused).
@export var mouse_button_labels: PackedStringArray = PackedStringArray()
@export var mouse_button_fallback_format: String = "mouse button %d"
@export var joypad_button_format: String = "pad button %d"
@export var unbound_label: String = "?"

@export_group("Look")
@export var canvas_layer: int = 4
@export var reference_height: float = 1080.0
@export var font_size: int = 44
@export var skip_font_size: int = 26
@export var text_max_width: float = 1600.0
@export var text_bottom_margin: float = 28.0
@export var skip_gap: float = 8.0
@export var skip_bar_width: float = 360.0
@export var skip_bar_height: float = 6.0
@export var text_color: Color = Color(1, 0.84, 0.4, 1)
@export var skip_text_color: Color = Color(0.92, 0.92, 0.9, 0.9)
@export var skip_bar_back_color: Color = Color(0, 0, 0, 0.5)
@export var skip_bar_fill_color: Color = Color(1, 0.75, 0.25, 1)
@export var outline_color: Color = Color(0, 0, 0, 0.85)
## Outline size in pixels = font pixels x outline_width x outline_scale.
@export var outline_width: float = 0.25
@export var outline_scale: float = 0.25
@export var box_color: Color = Color(1, 0.75, 0.25, 1)
@export var danger_box_color: Color = Color(1, 0.25, 0.2, 1)
@export var box_thickness: float = 6.0
@export var box_padding: float = 8.0
@export var pulse_hz: float = 1.5
@export var pulse_min_alpha: float = 0.35


## The hint with this id, or null.
func get_hint(hint_id: StringName) -> TutorialHint:
	for h: TutorialHint in hints:
		if h.id == hint_id:
			return h
	return null


## The hint triggered by this moment, or null.
func get_moment_hint(moment_id: StringName) -> TutorialHint:
	for h: TutorialHint in hints:
		if h.moment == moment_id:
			return h
	return null
