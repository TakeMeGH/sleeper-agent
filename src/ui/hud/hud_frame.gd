class_name HudFrame
extends Control
## One status-bar panel as Unity's prefab draws it: a flat fill, the bevel tile tiled faintly over it
## (the "panel texture"), and a hollow 9-sliced bevel frame whose border is drawn at a set width.
## A flipped frame is turned half a turn (dark top-left, light bottom-right: an inset bevel).

## Flat fill under everything; alpha 0 draws none.
var fill_color: Color = Color(0, 0, 0, 0)
## Faint overlay as Unity's Tiled Image draws a bordered sprite: the bevel tile's border 9-sliced at
## the edges and overlay_center (the tile's centre texels) tiled inside, at overlay_scale screen
## pixels per texel. Null overlay_texture draws none.
var overlay_texture: Texture2D
var overlay_center: Texture2D
var overlay_tint: Color = Color.WHITE
var overlay_scale: float = 1.0
## 9-slice bevel (null for none): texels of its border, the border's screen width, the tint.
var bevel_texture: Texture2D
var bevel_margin: int = 1
var bevel_width: float = 4.0
var bevel_tint: Color = Color.WHITE
var bevel_flipped: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)


func _draw() -> void:
	if fill_color.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), fill_color)
	if overlay_texture != null and overlay_scale > 0.0:
		var border: float = bevel_margin * overlay_scale
		if overlay_center != null:
			var inner: Rect2 = Rect2(Vector2.ONE * border, size - Vector2.ONE * border * 2.0)
			if inner.size.x > 0.0 and inner.size.y > 0.0:
				draw_set_transform(inner.position, 0.0, Vector2.ONE * overlay_scale)
				draw_texture_rect(overlay_center, Rect2(Vector2.ZERO, inner.size / overlay_scale), true, overlay_tint)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_nine_slice_frame(overlay_texture, border, overlay_tint)
	if bevel_texture != null and bevel_width > 0.0:
		if bevel_flipped:
			draw_set_transform(size, PI, Vector2.ONE)
		_draw_nine_slice_frame(bevel_texture, bevel_width, bevel_tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_nine_slice_frame(texture: Texture2D, width: float, tint: Color) -> void:
	var t: Vector2 = texture.get_size()
	var m: float = float(bevel_margin)
	var b: float = minf(width, minf(size.x, size.y) * 0.5)
	var src_x: PackedFloat32Array = PackedFloat32Array([0.0, m, t.x - m, t.x])
	var src_y: PackedFloat32Array = PackedFloat32Array([0.0, m, t.y - m, t.y])
	var dst_x: PackedFloat32Array = PackedFloat32Array([0.0, b, size.x - b, size.x])
	var dst_y: PackedFloat32Array = PackedFloat32Array([0.0, b, size.y - b, size.y])
	for row: int in 3:
		for col: int in 3:
			if row == 1 and col == 1:
				continue
			var src: Rect2 = Rect2(src_x[col], src_y[row], src_x[col + 1] - src_x[col], src_y[row + 1] - src_y[row])
			var dst: Rect2 = Rect2(dst_x[col], dst_y[row], dst_x[col + 1] - dst_x[col], dst_y[row + 1] - dst_y[row])
			if dst.size.x > 0.0 and dst.size.y > 0.0:
				draw_texture_rect_region(texture, dst, src, tint)
