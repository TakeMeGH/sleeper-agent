class_name HudPulse
extends Control
## The heartbeat trace: a dark window showing the pulse strip tiled sideways, one beat per strip
## width, scrolled by a phase (0-1 of a beat) rounded down to whole strip texels (Unity's
## StatusBarRules.PulseOffset). Clips to its rect.

## Window background.
var back_color: Color = Color.BLACK
## The strip (one beat per texture width) and its screen pixels per texel.
var strip: Texture2D
var art_scale: float = 1.0
## Trace colour (the zone colour).
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()

var _offset_texels: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)


## Sets the scroll phase in beats (only the fraction counts); redraws only on a whole-texel change.
func set_phase(phase: float) -> void:
	if strip == null:
		return
	var texels: float = floorf(fposmod(phase, 1.0) * strip.get_width())
	if texels != _offset_texels:
		_offset_texels = texels
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	if strip == null or art_scale <= 0.0:
		return
	var h: float = size.y / art_scale
	draw_set_transform(Vector2(-_offset_texels * art_scale, 0.0), 0.0, Vector2.ONE * art_scale)
	var w: float = size.x / art_scale + _offset_texels + strip.get_width()
	draw_texture_rect_region(strip, Rect2(0.0, 0.0, w, h), Rect2(0.0, 0.0, w, strip.get_height()), tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
