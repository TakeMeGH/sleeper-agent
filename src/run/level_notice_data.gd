class_name LevelNoticeData
extends Resource
## Text notices shown when a level visit is cleared (Unity level_notice.json).

@export var cleared_text: String = "LEVEL CLEARED"
@export var exit_open_text: String = "EXIT OPEN: WALK INTO THE GREEN LIGHT"
## Seconds the cleared text stays on screen.
@export var cleared_seconds: float = 2.5
@export var cleared_font_size: int = 56
@export var exit_font_size: int = 30
## Distance of the cleared text from the top of the screen, percent of height.
@export var top_percent: float = 22.0
## Extra distance of the exit text below the cleared text, percent of height.
@export var exit_offset_percent: float = 9.0
@export var text_color: Color = Color(1, 0.84, 0.4, 1)
@export var outline_color: Color = Color(0, 0, 0, 0.85)
@export var outline_width: float = 1.5
