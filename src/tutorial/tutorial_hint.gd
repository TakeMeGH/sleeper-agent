class_name TutorialHint
extends Resource
## One tutorial hint. Text may hold {Placeholder} tokens that TutorialData maps to input actions.

@export var id: StringName = &""
@export_multiline var text: String = ""
## HUD part ids boxed while the hint is up (see Hud.get_tutorial_target_rect).
@export var targets: Array[StringName] = []
## Danger hints use the red box, go ahead of the queue and replace a showing information hint.
@export var danger: bool = false
@export var min_seconds: float = 1.0
## Longest time shown (0 = no limit for action hints; information hints then use default_info_seconds).
@export var max_seconds: float = 0.0
## Higher shows first when several wait.
@export var priority: int = 0
## Opening hints that keep wave 1 from starting until they are done.
@export var holds_wave: bool = false
## Opening hint that only becomes ready once wave 1 has started.
@export var requires_wave_start: bool = false
## Moment that triggers this hint (empty = opening hint): slow_zone, fast_zone, danger, first_hit,
## empty_gun, pickup, dive.
@export var moment: StringName = &""
## Empty = information hint (ends after its time).
@export var goals: Array[TutorialGoal] = []
