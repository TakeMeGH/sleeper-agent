class_name Hud
extends Node
## Old-school status bar along the bottom of the screen, five boxes, laid out as Unity's StatusBar
## prefab (Assets/_Game/Prefabs/UI/StatusBar.prefab): substances, heart rate, face, enemies/wave/time,
## weapon and ammo. Every size is a Unity reference pixel at HudData.reference_width, scaled by the
## viewport width (CanvasScaler match width); the bar is rebuilt when the viewport size changes.
## The 3D world is re-rendered by a mirror camera into a rect ABOVE the bar, so it is never
## behind it. The HUD only reads state through signals and getters and changes no game state.

@export var data: HudData
## The player's main camera; the HUD mirrors it into the world view above the bar.
@export var camera: Camera3D
@export var heart: HeartRate
@export var substances: SubstanceInventory
@export var holder: WeaponHolder
@export var run_state: RunState
## Full-screen container of the viewmodel overlay; shrunk to the same rect as the world view.
@export var viewmodel_container: Control
## Optional crosshair; re-centred on the world view above the bar.
@export var crosshair: Control
## Optional Shift ability; shown as a small line in the heart box when HudData.show_shift_text is on.
@export var shift_ability: ShiftAbility

var _glyphs: Dictionary = {}
var _face_textures: Array[Texture2D] = []
var _face_level: int = 0
var _pulse_phase: float = 0.0
var _gun_id: StringName = &""
var _gun_data: GunData
var _held_kind: StringName = &""
var _countdown_seconds: int = -1
var _rate: float = 0.0
var _zone_color: Color = Color.WHITE
var _font: FontVariation
## The bevel tile's centre texels, tiled inside every panel (Unity Tiled image of a bordered sprite).
var _overlay_center: Texture2D
## Reference pixels to screen pixels.
var _s: float = 1.0

var _bar: Control
var _name_labels: Dictionary = {}
var _count_rows: Dictionary = {}
var _held_icon: TextureRect
var _held_icon_kind: StringName = &""
var _held_fill: ColorRect
var _held_track: Control
var _held_percent: Label
var _rate_row: GlyphRow
var _heart_unit: Label
var _zone_label: Label
var _pulse: HudPulse
var _shift_label: Label
var _face: TextureRect
var _enemies_row: GlyphRow
var _wave_label: Label
var _time_label: Label
var _gun_icon: TextureRect
var _gun_label: Label
var _ammo_row: GlyphRow
## Boxable parts for the tutorial (story 023): id -> Control.
var _target_controls: Dictionary = {}

@onready var _world_container: SubViewportContainer = %WorldContainer
@onready var _world_camera: Camera3D = %WorldCamera
@onready var _bar_layer: CanvasLayer = %BarLayer


func _ready() -> void:
	add_to_group(HeartRateScreen.CAMERA_MIRROR_GROUP)
	if data == null or data.pulse_texture == null or data.bevel_texture == null or camera == null or heart == null \
			or substances == null or holder == null or run_state == null:
		push_error("Hud needs data (with pulse and bevel textures), camera, heart, substances, holder and run_state assigned.")
		set_process(false)
		return
	# Run after the player camera has moved so the mirror camera never lags.
	process_priority = 100
	# The window no longer draws 3D itself; the world view renders it above the bar.
	get_tree().root.disable_3d = true
	var view_bottom: float = 1.0 - data.bar_height_ratio
	_world_container.anchor_bottom = view_bottom
	_world_container.offset_bottom = 0.0
	if viewmodel_container != null:
		viewmodel_container.anchor_bottom = view_bottom
		viewmodel_container.offset_bottom = 0.0
	if crosshair != null:
		crosshair.anchor_top = view_bottom * 0.5
		crosshair.anchor_bottom = view_bottom * 0.5
	_held_kind = SubstanceInventory.KINDS[0]
	_load_art()
	_build_bar()
	_connect_signals()
	_refresh_all()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().root.disable_3d = false


func _process(delta: float) -> void:
	if not (is_instance_valid(camera) and is_instance_valid(heart) and is_instance_valid(run_state)):
		set_process(false)
		return
	sync_camera()
	if not heart.has_ended():
		_pulse_phase = fposmod(_pulse_phase + maxf(0.0, _rate) / 60.0 * delta, 1.0)
	_pulse.set_phase(_pulse_phase)
	_refresh_run_state()
	_refresh_held()
	_refresh_shift()


## Copies the player camera (transform, fov, near, far, cull mask) to the world camera. Called every frame
## and once by HeartRateScreen on run end (this node is pausable, so the last fov would otherwise stay).
func sync_camera() -> void:
	if _world_camera == null or not is_instance_valid(camera):
		return
	_world_camera.global_transform = camera.global_transform
	_world_camera.fov = camera.fov
	_world_camera.near = camera.near
	_world_camera.far = camera.far
	_world_camera.cull_mask = camera.cull_mask


## Global canvas rect of a HUD part the tutorial can box: heart_panel, coffee_row, cigarette_row,
## substance_panel, gun_panel, ammo_row, run_panel, status_bar. Empty Rect2 for an unknown id or a hidden part.
func get_tutorial_target_rect(id: StringName) -> Rect2:
	var entry: Variant = _target_controls.get(id)
	if entry == null or not is_instance_valid(entry):
		return Rect2()
	var control: Control = entry as Control
	if control == null or not control.is_inside_tree():
		return Rect2()
	return control.get_global_rect()


## Whole seconds as mm:ss (each part at least two digits), the time-survived readout.
static func format_time(seconds: float) -> String:
	var whole: int = maxi(0, int(seconds))
	return "%02d:%02d" % [whole / 60, whole % 60]


# --- Build ---------------------------------------------------------------------------------------

func _load_art() -> void:
	for i: int in data.glyph_order.length():
		var path: String = data.glyph_path_format % [i, data.glyph_file_names[i]]
		_glyphs[data.glyph_order[i]] = load(path) as Texture2D
	for level: int in data.face_danger_steps.size() + 2:
		_face_textures.append(load(data.face_path_format % level) as Texture2D)
	var tile: Image = data.bevel_texture.get_image()
	if tile != null:
		var m: int = data.bevel_margin
		_overlay_center = ImageTexture.create_from_image(
				tile.get_region(Rect2i(m, m, tile.get_width() - 2 * m, tile.get_height() - 2 * m)))
	_font = FontVariation.new()
	_font.base_font = data.font if data.font != null else ThemeDB.fallback_font
	_font.variation_embolden = data.font_embolden


func _icon(icon_name: String) -> Texture2D:
	var path: String = data.icon_path_format % icon_name
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _on_viewport_resized() -> void:
	if _bar == null:
		return
	_bar.queue_free()
	_bar = null
	_build_bar()
	_refresh_all()


func _build_bar() -> void:
	_s = get_viewport().get_visible_rect().size.x / maxf(1.0, data.reference_width)
	_font.spacing_glyph = roundi(data.font_bold_spacing_em * data.label_font_size * _s)
	_target_controls.clear()
	_held_icon_kind = &""
	_name_labels.clear()
	_count_rows.clear()
	_bar = _frame(null, data.bar_color, data.bar_bevel_tint)
	_bar.anchor_left = 0.0
	_bar.anchor_top = 1.0 - data.bar_height_ratio
	_bar.anchor_right = 1.0
	_bar.anchor_bottom = 1.0
	_bar_layer.add_child(_bar)
	_bar.offset_left = 0.0
	_bar.offset_top = 0.0
	_bar.offset_right = 0.0
	_bar.offset_bottom = 0.0
	_target_controls[&"status_bar"] = _bar
	var boxes: Control = _stretched(Control.new(), _bar, data.bar_inset, data.bar_inset, data.bar_inset, data.bar_inset)
	var w: PackedFloat32Array = data.box_width_ratios
	var total: float = 0.0
	for weight: float in w:
		total += weight
	var contents: Array[Control] = []
	var start: float = 0.0
	for i: int in w.size():
		var box: HudFrame = _frame(boxes, data.box_color, data.box_bevel_tint)
		box.set_anchor(SIDE_LEFT, start / total)
		start += w[i]
		box.set_anchor(SIDE_RIGHT, start / total)
		box.set_anchor(SIDE_TOP, 0.0)
		box.set_anchor(SIDE_BOTTOM, 1.0)
		_set_offsets(box, data.box_gap, data.box_gap, -data.box_gap, -data.box_gap)
		contents.append(_stretched(Control.new(), box, data.box_inset, data.box_inset, data.box_inset, data.box_inset))
	_target_controls[&"substance_panel"] = contents[0].get_parent()
	_target_controls[&"heart_panel"] = contents[1].get_parent()
	_target_controls[&"run_panel"] = contents[3].get_parent()
	_target_controls[&"gun_panel"] = contents[4].get_parent()
	_build_substance_box(contents[0])
	_build_heart_box(contents[1])
	_build_face_box(contents[2])
	_build_run_box(contents[3])
	_build_gun_box(contents[4])
	_target_controls[&"ammo_row"] = _ammo_row


## A panel: fill, the faint tiled bevel texture and a bevel frame. Added to parent when not null.
func _frame(parent: Control, fill: Color, bevel_tint: Color) -> HudFrame:
	var frame: HudFrame = HudFrame.new()
	frame.fill_color = fill
	frame.overlay_texture = data.bevel_texture
	frame.overlay_center = _overlay_center
	frame.overlay_tint = data.panel_texture_tint
	frame.overlay_scale = data.panel_texture_scale * _s
	frame.bevel_texture = data.bevel_texture
	frame.bevel_margin = data.bevel_margin
	frame.bevel_width = data.bevel_width * _s
	frame.bevel_tint = bevel_tint
	if parent != null:
		parent.add_child(frame)
	return frame


# Placement in Unity reference pixels (y up from the parent's centre, as a RectTransform), scaled by _s.

func _set_offsets(c: Control, left: float, top: float, right: float, bottom: float) -> void:
	c.offset_left = left * _s
	c.offset_top = top * _s
	c.offset_right = right * _s
	c.offset_bottom = bottom * _s


func _set_anchors(c: Control, left: float, top: float, right: float, bottom: float) -> void:
	c.set_anchor(SIDE_LEFT, left)
	c.set_anchor(SIDE_TOP, top)
	c.set_anchor(SIDE_RIGHT, right)
	c.set_anchor(SIDE_BOTTOM, bottom)


func _adopt(c: Control, parent: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)


## Stretched over the parent, inset by the margins.
func _stretched(c: Control, parent: Control, left: float, bottom: float, right: float, top: float) -> Control:
	_adopt(c, parent)
	_set_anchors(c, 0.0, 0.0, 1.0, 1.0)
	_set_offsets(c, left, top, -right, -bottom)
	return c


## Across the parent's width (inset left and right), centre y above the parent's centre.
func _row(c: Control, parent: Control, y: float, height: float, left: float = 0.0, right: float = 0.0) -> Control:
	_adopt(c, parent)
	_set_anchors(c, 0.0, 0.5, 1.0, 0.5)
	_set_offsets(c, left, -(y + height * 0.5), -right, -(y - height * 0.5))
	return c


## Fixed size, centre at (x, y) from the parent's centre.
func _centered(c: Control, parent: Control, x: float, y: float, width: float, height: float) -> Control:
	_adopt(c, parent)
	_set_anchors(c, 0.5, 0.5, 0.5, 0.5)
	_set_offsets(c, x - width * 0.5, -(y + height * 0.5), x + width * 0.5, -(y - height * 0.5))
	return c


## Fixed size, left edge `left` from the parent's left edge, centred vertically at y.
func _left_at(c: Control, parent: Control, left: float, y: float, width: float, height: float) -> Control:
	_adopt(c, parent)
	_set_anchors(c, 0.0, 0.5, 0.0, 0.5)
	_set_offsets(c, left, -(y + height * 0.5), left + width, -(y - height * 0.5))
	return c


## Fixed size, right edge `right` from the parent's right edge, centred vertically at y.
func _right_at(c: Control, parent: Control, right: float, y: float, width: float, height: float) -> Control:
	_adopt(c, parent)
	_set_anchors(c, 1.0, 0.5, 1.0, 0.5)
	_set_offsets(c, -(right + width), -(y + height * 0.5), -right, -(y - height * 0.5))
	return c


func _label(text: String, color: Color, font_size: float, align: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", maxi(1, roundi(font_size * _s)))
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _image(texture: Texture2D, color: Color = Color.WHITE) -> TextureRect:
	var image: TextureRect = TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.modulate = color
	return image


func _glyph_row(cells: int, cell: Vector2, align: GlyphRow.Align) -> GlyphRow:
	var glyph_row: GlyphRow = GlyphRow.new()
	glyph_row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glyph_row.setup(_glyphs, cells, cell * _s, data.glyph_spacing * _s, align, data.number_color)
	return glyph_row


func _row_width(cells: int, cell_width: float) -> float:
	return cells * cell_width + (cells - 1) * data.glyph_spacing


## Box 0: one row per substance (name left, "count/max" right), then the held row: < icon > item bar, percent.
func _build_substance_box(content: Control) -> void:
	var cell: Vector2 = data.small_cell
	var kinds: Array[StringName] = SubstanceInventory.KINDS
	var held_height: float = maxf(data.substance_icon_size, cell.y)
	var top: float = (kinds.size() * (cell.y + data.row_spacing) + held_height) * 0.5
	var count_width: float = _row_width(data.count_cells, cell.x)
	for i: int in kinds.size():
		var kind: StringName = kinds[i]
		var y: float = top - cell.y * 0.5 - i * (cell.y + data.row_spacing)
		var row: Control = _row(Control.new(), content, y, cell.y)
		var substance: SubstanceData = substances.get_substance_data(kind)
		var display: String = substance.display_name if substance != null else String(kind).capitalize()
		var name_label: Label = _stretched(_label(display, data.label_color, data.label_font_size,
				HORIZONTAL_ALIGNMENT_LEFT), row, 0.0, 0.0, count_width + data.item_spacing, 0.0) as Label
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
		name_label.clip_text = true
		_name_labels[kind] = name_label
		_count_rows[kind] = _right_at(_glyph_row(data.count_cells, cell, GlyphRow.Align.RIGHT), row, 0.0, 0.0,
				count_width, cell.y)
		_target_controls[StringName(String(kind) + "_row")] = row

	var held_y: float = top - kinds.size() * (cell.y + data.row_spacing) - held_height * 0.5
	var held: Control = _row(Control.new(), content, held_y, held_height)
	_left_at(_image(_glyphs.get("<"), data.number_color), held, 0.0, 0.0, cell.x, cell.y)
	_held_icon = _left_at(_image(null, data.number_color), held, cell.x, 0.0, data.substance_icon_size,
			data.substance_icon_size) as TextureRect
	_left_at(_image(_glyphs.get(">"), data.number_color), held, cell.x + data.substance_icon_size, 0.0, cell.x, cell.y)
	var track_left: float = 2.0 * cell.x + data.substance_icon_size + data.item_spacing
	var track: HudFrame = HudFrame.new()
	track.fill_color = data.item_track_color
	_row(track, held, 0.0, data.item_bar_height, track_left, data.percent_width + data.item_spacing)
	_held_track = _stretched(Control.new(), track, data.track_bevel_width, data.track_bevel_width,
			data.track_bevel_width, data.track_bevel_width)
	_held_fill = ColorRect.new()
	_held_fill.color = data.item_bar_color
	_stretched(_held_fill, _held_track, 0.0, 0.0, 0.0, 0.0)
	var track_bevel: HudFrame = HudFrame.new()
	track_bevel.bevel_texture = data.bevel_texture
	track_bevel.bevel_margin = data.bevel_margin
	track_bevel.bevel_width = data.track_bevel_width * _s
	track_bevel.bevel_tint = data.box_bevel_tint
	track_bevel.bevel_flipped = true
	_stretched(track_bevel, track, 0.0, 0.0, 0.0, 0.0)
	_held_percent = _right_at(_label("", data.label_color, data.label_font_size, HORIZONTAL_ALIGNMENT_RIGHT), held,
			0.0, 0.0, data.percent_width, data.text_height) as Label


## Box 1: [heart] number unit, the pulse strip under it in a dark window, the zone name under that.
func _build_heart_box(content: Control) -> void:
	var cell: Vector2 = data.large_cell
	var pulse_h: float = data.pulse_size.y
	var top: float = (cell.y + data.row_spacing + pulse_h + data.row_spacing + data.text_height) * 0.5
	var row: Control = _row(Control.new(), content, top - cell.y * 0.5, cell.y)
	var number_width: float = _row_width(data.heart_cells, cell.x)
	var width: float = data.heart_icon_size + data.item_spacing + number_width + data.item_spacing + data.unit_width
	var x: float = -width * 0.5
	_centered(_image(_icon("heart"), data.number_color), row, x + data.heart_icon_size * 0.5, 0.0,
			data.heart_icon_size, data.heart_icon_size)
	x += data.heart_icon_size + data.item_spacing
	_rate_row = _centered(_glyph_row(data.heart_cells, cell, GlyphRow.Align.RIGHT), row, x + number_width * 0.5, 0.0,
			number_width, cell.y) as GlyphRow
	x += number_width + data.item_spacing
	_heart_unit = _centered(_label(data.bpm_unit, data.caption_color, data.label_font_size, HORIZONTAL_ALIGNMENT_LEFT),
			row, x + data.unit_width * 0.5, 0.0, data.unit_width, data.text_height) as Label

	var pulse_y: float = top - cell.y - data.row_spacing - pulse_h * 0.5
	_pulse = HudPulse.new()
	_pulse.back_color = data.pulse_back_color
	_pulse.strip = data.pulse_texture
	_pulse.art_scale = data.pulse_art_scale * _s
	_centered(_pulse, content, 0.0, pulse_y, data.pulse_size.x, pulse_h)

	var zone_y: float = pulse_y - pulse_h * 0.5 - data.row_spacing - data.text_height * 0.5
	_zone_label = _row(_label("", data.label_color, data.zone_font_size, HORIZONTAL_ALIGNMENT_CENTER), content,
			zone_y, data.text_height) as Label

	_shift_label = null
	if data.show_shift_text:
		_shift_label = _row(_label("", data.dim_color, data.shift_font_size, HORIZONTAL_ALIGNMENT_RIGHT), content,
				top - data.shift_font_size * 0.5, data.shift_font_size) as Label


## Box 2: the face, centred.
func _build_face_box(content: Control) -> void:
	_face = _centered(_image(null), content, 0.0, 0.0, data.face_size, data.face_size) as TextureRect


## Box 3: the caption, the enemies-left number, then the wave (left) and the time (right) on one row.
func _build_run_box(content: Control) -> void:
	var cell: Vector2 = data.large_cell
	var th: float = data.text_height
	var top: float = (th + data.row_spacing + cell.y + data.row_spacing + th) * 0.5
	_row(_label(data.enemies_text, data.caption_color, data.label_font_size, HORIZONTAL_ALIGNMENT_CENTER), content,
			top - th * 0.5, th)
	var number_y: float = top - th - data.row_spacing - cell.y * 0.5
	_enemies_row = _centered(_glyph_row(data.enemies_cells, cell, GlyphRow.Align.CENTER), content, 0.0, number_y,
			_row_width(data.enemies_cells, cell.x), cell.y) as GlyphRow
	var row_y: float = number_y - cell.y * 0.5 - data.row_spacing - th * 0.5
	_wave_label = _row(_label("", data.label_color, data.label_font_size, HORIZONTAL_ALIGNMENT_LEFT), content,
			row_y, th) as Label
	_time_label = _row(_label("", data.label_color, data.label_font_size, HORIZONTAL_ALIGNMENT_RIGHT), content,
			row_y, th) as Label


## Box 4: < icon > name, then magazine / spare.
func _build_gun_box(content: Control) -> void:
	var small: Vector2 = data.small_cell
	var cell: Vector2 = data.large_cell
	var icon_size: float = data.weapon_icon_size
	var top: float = (icon_size + data.row_spacing + cell.y) * 0.5
	var row: Control = _row(Control.new(), content, top - icon_size * 0.5, icon_size)
	var width: float = small.x + icon_size + small.x + data.item_spacing + data.weapon_name_width
	var x: float = -width * 0.5
	_centered(_image(_glyphs.get("<"), data.number_color), row, x + small.x * 0.5, 0.0, small.x, small.y)
	x += small.x
	_gun_icon = _centered(_image(null, data.number_color), row, x + icon_size * 0.5, 0.0, icon_size,
			icon_size) as TextureRect
	x += icon_size
	_centered(_image(_glyphs.get(">"), data.number_color), row, x + small.x * 0.5, 0.0, small.x, small.y)
	x += small.x + data.item_spacing
	_gun_label = _centered(_label("", data.label_color, data.label_font_size, HORIZONTAL_ALIGNMENT_LEFT), row,
			x + data.weapon_name_width * 0.5, 0.0, data.weapon_name_width, data.text_height) as Label
	_gun_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	var ammo_y: float = top - icon_size - data.row_spacing - cell.y * 0.5
	_ammo_row = _centered(_glyph_row(data.ammo_cells, cell, GlyphRow.Align.CENTER), content, 0.0, ammo_y,
			_row_width(data.ammo_cells, cell.x), cell.y) as GlyphRow


# --- Update --------------------------------------------------------------------------------------

func _connect_signals() -> void:
	substances.count_changed.connect(_on_count_changed)
	substances.consume_started.connect(_on_consume_started)
	heart.heart_rate_changed.connect(_on_heart_rate_changed)
	heart.zone_changed.connect(_on_zone_changed)
	heart.danger_countdown_changed.connect(_on_countdown_changed)
	holder.gun_switched.connect(_on_gun_switched)
	holder.ammo_changed.connect(_on_ammo_changed)


## The inventory and holder send no initial signal, so read everything once through getters.
func _refresh_all() -> void:
	for kind: StringName in SubstanceInventory.KINDS:
		_on_count_changed(kind, substances.get_count(kind))
	_on_zone_changed(heart.get_zone(), heart.get_zone())
	var reason: StringName = &""
	match heart.get_zone():
		HeartRate.Zone.LOW:
			reason = HeartRate.REASON_PASSED_OUT
		HeartRate.Zone.HIGH:
			reason = HeartRate.REASON_HEART_ATTACK
	_on_countdown_changed(heart.get_countdown_left(), reason)
	_on_heart_rate_changed(heart.get_rate())
	var gun: Gun = holder.get_current_gun()
	if gun != null:
		_on_gun_switched(gun.data)
		_on_ammo_changed(gun.data.gun_id, gun.magazine, gun.get_spare_display())
	elif _gun_data != null:
		_on_gun_switched(_gun_data)
	_refresh_run_state()
	_refresh_held()
	_refresh_shift()


func _refresh_run_state() -> void:
	_enemies_row.set_text(str(clampi(run_state.enemies_left, 0, 999)))
	_wave_label.text = data.wave_format.replace("{wave}", str(run_state.wave))
	_time_label.text = data.time_format.replace("{time}", format_time(run_state.time_survived))


func _refresh_shift() -> void:
	if _shift_label == null or shift_ability == null or not is_instance_valid(shift_ability):
		return
	if shift_ability.is_active():
		var format: String = data.shift_active_formats.get(shift_ability.get_active_kind(), "")
		_shift_label.text = format % shift_ability.get_effect_left()
		_shift_label.add_theme_color_override("font_color", data.highlight_color)
	elif shift_ability.get_cooldown_left() > 0.0:
		_shift_label.text = data.shift_cooldown_format % shift_ability.get_cooldown_left()
		_shift_label.add_theme_color_override("font_color", data.dim_color)
	else:
		_shift_label.text = data.shift_ready_text
		_shift_label.add_theme_color_override("font_color", data.label_color)


## Held item row: its icon, the share of the current item left as a bar and a percent ("EMPTY" at 0 items).
func _refresh_held() -> void:
	var count: int = substances.get_count(_held_kind)
	var empty: bool = count <= 0
	var percent: int = 0
	if not empty:
		var left: float = 1.0 - clampf(substances.get_hold_progress(_held_kind), 0.0, 1.0)
		percent = 100 if left >= 1.0 else clampi(ceili(left * 100.0), 1, 100)
	if _held_icon_kind != _held_kind:
		_held_icon_kind = _held_kind
		_held_icon.texture = _icon(String(_held_kind))
	_held_icon.modulate = data.dim_color if empty else data.number_color
	_held_fill.set_anchor(SIDE_RIGHT, percent / 100.0)
	_held_fill.offset_right = 0.0
	_held_percent.text = data.item_empty_text if empty else data.item_left_format.replace("{percent}", str(percent))
	_held_percent.add_theme_color_override("font_color", data.dim_color if empty else data.label_color)


## A substance row: "count/max", dimmed when empty; the held substance's name highlighted.
func _refresh_slot(kind: StringName) -> void:
	var count_row: GlyphRow = _count_rows.get(kind) as GlyphRow
	var name_label: Label = _name_labels.get(kind) as Label
	if count_row == null or name_label == null:
		return
	var count: int = substances.get_count(kind)
	var substance: SubstanceData = substances.get_substance_data(kind)
	var digits: int = maxi(1, (count_row.get_cell_count() - 1) / 2)
	var cap: int = int(pow(10.0, digits)) - 1
	var max_count: int = substance.max_count if substance != null else count
	count_row.set_text("%d/%d" % [clampi(count, 0, cap), clampi(max_count, 0, cap)])
	var empty: bool = count <= 0
	count_row.set_tint(data.dim_color if empty else data.number_color)
	var color: Color = data.dim_color if empty else (data.highlight_color if kind == _held_kind else data.label_color)
	name_label.add_theme_color_override("font_color", color)


func _on_count_changed(kind: StringName, _count: int) -> void:
	_refresh_slot(kind)
	if kind == _held_kind:
		_refresh_held()


## The substance being consumed becomes the held one (Godot has no item selection; Unity's held slot).
func _on_consume_started(kind: StringName) -> void:
	if kind == _held_kind:
		return
	_held_kind = kind
	for k: StringName in SubstanceInventory.KINDS:
		_refresh_slot(k)
	_refresh_held()


func _on_heart_rate_changed(rate: float) -> void:
	_rate = rate
	_show_heart_number()
	_update_face(rate)


func _show_heart_number() -> void:
	if _countdown_seconds >= 0:
		_rate_row.set_text(str(mini(_countdown_seconds, 999)))
		_heart_unit.text = data.countdown_unit
	else:
		_rate_row.set_text(str(clampi(roundi(_rate), 0, 999)))
		_heart_unit.text = data.bpm_unit


func _on_zone_changed(zone: HeartRate.Zone, _previous: HeartRate.Zone) -> void:
	_zone_color = data.zone_colors[zone]
	_zone_label.text = data.zone_names[zone]
	_zone_label.add_theme_color_override("font_color", _zone_color)
	_rate_row.set_tint(_zone_color)
	_pulse.tint = _zone_color


## While a danger countdown runs, its whole seconds (rounded up) replace the bpm and the unit reads SEC.
func _on_countdown_changed(seconds_left: float, reason: StringName) -> void:
	var active: bool = reason != &"" and seconds_left > 0.0
	_countdown_seconds = ceili(seconds_left) if active else -1
	_show_heart_number()


func _on_gun_switched(gun_data: GunData) -> void:
	_gun_data = gun_data
	_gun_id = gun_data.gun_id
	_gun_label.text = gun_data.display_name
	_gun_icon.texture = _icon(String(gun_data.gun_id))


func _on_ammo_changed(gun_id: StringName, magazine: int, spare: int) -> void:
	if gun_id != _gun_id:
		return
	var digits: int = maxi(1, (_ammo_row.get_cell_count() - 1) / 2)
	var cap: int = int(pow(10.0, digits)) - 1
	_ammo_row.set_text("%d/%s" % [clampi(magazine, 0, cap), "∞" if spare < 0 else str(clampi(spare, 0, cap))])


## Face level 0 (calm) to steps+1 (past a danger limit), with a bpm hysteresis when improving.
func _update_face(rate: float) -> void:
	var resting: float = heart.data.resting_rate
	var rising: int = _face_level_for(rate)
	var falling: int = _face_level_for(move_toward(rate, resting, data.face_hysteresis_bpm))
	if rising > _face_level:
		_face_level = rising
	elif falling < _face_level:
		_face_level = falling
	_face.texture = _face_textures[_face_level]


func _face_level_for(rate: float) -> int:
	var resting: float = heart.data.resting_rate
	var ratio: float
	if rate <= resting:
		ratio = (resting - rate) / (resting - heart.data.slow_from)
	else:
		ratio = (rate - resting) / (heart.data.heart_attack_above - resting)
	if ratio >= 1.0:
		return data.face_danger_steps.size() + 1
	var level: int = 0
	for step: float in data.face_danger_steps:
		if ratio >= step:
			level += 1
	return level
