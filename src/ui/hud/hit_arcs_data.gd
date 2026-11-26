class_name HitArcsData
extends Resource
## Tuning for the hit direction arcs and the danger countdown number (Unity hit_direction.json values).
## All pixel sizes are authored for the 1280x720 project viewport; the canvas_items stretch scales them
## with the window, so nothing here is scaled again by viewport height.

## Most arcs shown at once; past this the oldest is reused.
@export var arc_pool_size: int = 6
## Real seconds an arc stays fully visible.
@export var arc_hold_seconds: float = 0.6
## Real seconds an arc takes to fade out after the hold.
@export var arc_fade_seconds: float = 0.5
## A hit within this many degrees of a showing arc refreshes that arc.
@export var merge_angle: float = 25.0
## Ring radius in pixels, measured from the crosshair centre to the arc centre line.
@export var ring_radius: float = 110.0
## Angular length of one arc in degrees.
@export var arc_span_degrees: float = 28.0
## Arc thickness in pixels.
@export var arc_thickness: float = 9.0
@export var arc_color: Color = Color(1.0, 0.15, 0.1, 1.0)
@export var arc_outline_color: Color = Color(0.0, 0.0, 0.0, 0.85)
## Outline width in pixels on each side of the arc.
@export var arc_outline_width: float = 3.0
## Points used to draw one arc (smoothness).
@export var arc_point_count: int = 24

## Distance in pixels from the crosshair centre down to the centre of the countdown number.
@export var countdown_offset_y: float = 60.0
@export var countdown_font_size: int = 30
@export var countdown_outline_size: int = 4
@export var countdown_outline_color: Color = Color(0.0, 0.0, 0.0, 0.85)
