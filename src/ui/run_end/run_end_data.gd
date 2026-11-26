class_name RunEndData
extends Resource
## Texts, sizes, colours and timing of the run-end screen (defaults from the Unity run.json).

@export_group("Text")
@export var title: String = "YOUR BODY GAVE OUT"
@export var time_label: String = "TIME SURVIVED"
@export var wave_label: String = "WAVE REACHED"
@export var kills_label: String = "KILLS"
@export var best_label: String = "SESSION BEST"
## Placeholders {time} {wave} {kills}.
@export var best_line: String = "{time}  -  wave {wave}  -  {kills} kills"
@export var new_best_text: String = "NEW BEST"
@export var restart_button: String = "PLAY AGAIN"
@export var restart_prompt: String = "Press Enter (keyboard) or A / Start (gamepad) to play again"
@export var reason_passed_out: String = "YOU PASSED OUT"
@export var reason_heart_attack: String = "HEART ATTACK"

@export_group("Timing")
## Real seconds to wait after the run ends before the screen appears (story 018 hook; 0 = at once).
@export var show_delay_seconds: float = 0.0
## Real seconds after the screen appears during which restart input is ignored.
@export var restart_input_guard: float = 0.75

@export_group("Layout")
@export var layer: int = 30
## Canvas height the sizes below were authored for (Unity 1080p); they scale by viewport height / this.
@export var reference_height: float = 1080.0
@export var panel_width: int = 760
@export var panel_padding: int = 48
@export var panel_border_width: int = 2
@export var panel_corner_radius: int = 6
@export var row_spacing: int = 14
@export var reason_spacing: int = 14
@export var section_spacing: int = 34
@export var button_width: int = 380
@export var button_height: int = 84
@export var button_border_width: int = 3

@export_group("Fonts")
@export var title_font_size: int = 52
@export var label_font_size: int = 28
@export var value_font_size: int = 44
@export var best_font_size: int = 32
@export var new_best_font_size: int = 30
@export var button_font_size: int = 36
@export var prompt_font_size: int = 22
@export var reason_font_size: int = 30

@export_group("Colours")
@export var overlay_color: Color = Color(0.0, 0.0, 0.0, 0.78)
@export var panel_color: Color = Color(0.07, 0.06, 0.06, 0.96)
@export var panel_border_color: Color = Color(0.55, 0.1, 0.1, 1.0)
@export var title_color: Color = Color(0.85, 0.18, 0.18, 1.0)
@export var reason_color: Color = Color(0.95, 0.75, 0.3, 1.0)
@export var label_color: Color = Color(0.72, 0.72, 0.72, 1.0)
@export var value_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var best_color: Color = Color(0.92, 0.82, 0.5, 1.0)
@export var new_best_color: Color = Color(0.45, 1.0, 0.55, 1.0)
@export var button_color: Color = Color(0.5, 0.1, 0.1, 1.0)
@export var button_highlight_color: Color = Color(0.72, 0.16, 0.16, 1.0)
@export var button_border_color: Color = Color(0.3, 0.05, 0.05, 1.0)
@export var button_focus_border_color: Color = Color(1.0, 0.9, 0.4, 1.0)
@export var button_text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var prompt_color: Color = Color(0.66, 0.66, 0.66, 1.0)
