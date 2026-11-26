class_name GlyphRow
extends Control
## A fixed row of pixel-glyph cells (digits and / : infinity < > - .), like Unity's HudGlyphRow:
## the cells never move, only which cells show a glyph changes. Text shorter than the row is placed
## left, centred (an odd spare cell goes to the right end) or right.

enum Align { LEFT, CENTER, RIGHT }

var _textures: Dictionary = {}
var _cells: Array[TextureRect] = []
var _align: Align = Align.RIGHT
var _tint: Color = Color.WHITE
var _text: String = "\u0001"


## Builds cell_count cells of cell_size with spacing between them, and sizes the row to fit.
## textures maps a character to its Texture2D.
func setup(textures: Dictionary, cell_count: int, cell_size: Vector2, spacing: float, align: Align, tint: Color) -> void:
	_textures = textures
	_align = align
	_tint = tint
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in get_children():
		child.queue_free()
	_cells.clear()
	for i: int in cell_count:
		var cell: TextureRect = TextureRect.new()
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.position = Vector2(i * (cell_size.x + spacing), 0.0)
		cell.size = cell_size
		cell.modulate = tint
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.visible = false
		add_child(cell)
		_cells.append(cell)
	custom_minimum_size = Vector2(cell_count * cell_size.x + maxf(0.0, cell_count - 1) * spacing, cell_size.y)
	_text = "\u0001"


## Number of cells in the row.
func get_cell_count() -> int:
	return _cells.size()


## Shows text; characters with no glyph leave their cell empty. Text longer than the row is cut. No-op when unchanged.
func set_text(text: String) -> void:
	if text == _text:
		return
	_text = text
	var shown: int = mini(text.length(), _cells.size())
	var first: int = 0
	match _align:
		Align.RIGHT:
			first = _cells.size() - shown
		Align.CENTER:
			first = (_cells.size() - shown) / 2
	for i: int in _cells.size():
		var cell: TextureRect = _cells[i]
		var index: int = i - first
		var texture: Texture2D = null
		if index >= 0 and index < shown:
			texture = _textures.get(text[index]) as Texture2D
		cell.texture = texture
		cell.visible = texture != null


## Re-tints every cell.
func set_tint(tint: Color) -> void:
	_tint = tint
	for cell: TextureRect in _cells:
		cell.modulate = tint
