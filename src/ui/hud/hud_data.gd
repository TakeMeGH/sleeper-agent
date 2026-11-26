class_name HudData
extends Resource
## Tuning, layout and text for the status-bar HUD.
## Values come from the Unity StatusBar prefab (Assets/_Game/Prefabs/UI/StatusBar.prefab, seeded by
## HudPrefabBuilder.cs) and hud.json. Layout sizes are in Unity reference pixels at reference_width
## (1920); the HUD multiplies them by viewport_width / reference_width, as Unity's CanvasScaler does
## (Scale With Screen Size, match width).

@export_group("Layout")
## Share of the screen height taken by the bottom bar (3D view and viewmodel sit above it).
@export_range(0.1, 0.4, 0.01) var bar_height_ratio: float = 0.2
## Width the reference-pixel sizes below are authored at (Unity CanvasScaler reference resolution x).
@export var reference_width: float = 1920.0
## Relative widths of the five boxes, left to right (Unity box weights).
@export var box_width_ratios: PackedFloat32Array = PackedFloat32Array([9.0, 10.0, 5.0, 8.0, 9.0])
## Inset of the box row from the bar edge (bevel + padding).
@export var bar_inset: float = 10.0
## Margin on every side of a box.
@export var box_gap: float = 4.0
## Inset of a box's content from the box edge (bevel + padding).
@export var box_inset: float = 10.0
## Width of the bar and box bevel frames.
@export var bevel_width: float = 4.0
## Width of the inset bevel around the held item's bar.
@export var track_bevel_width: float = 2.0
## Reference pixels per texel of the faint panel texture.
@export var panel_texture_scale: float = 3.0
## Vertical gap between stacked rows in a box.
@export var row_spacing: float = 12.0
## Horizontal gap between items in a row.
@export var item_spacing: float = 12.0
## Gap between glyph cells.
@export var glyph_spacing: float = 4.0
## Cell size of the big glyphs (5x7 art at 9) and the small glyphs (at 6).
@export var large_cell: Vector2 = Vector2(45.0, 63.0)
@export var small_cell: Vector2 = Vector2(30.0, 42.0)
@export var face_size: float = 144.0
@export var substance_icon_size: float = 48.0
@export var weapon_icon_size: float = 96.0
@export var heart_icon_size: float = 48.0
## The pulse window, and reference pixels per strip texel.
@export var pulse_size: Vector2 = Vector2(330.0, 48.0)
@export var pulse_art_scale: float = 3.0
@export var item_bar_height: float = 22.0
@export var label_font_size: float = 30.0
@export var zone_font_size: float = 32.0
## Height of a single text row.
@export var text_height: float = 36.0
## Widths of the percent text, the BPM unit and the weapon name.
@export var percent_width: float = 120.0
@export var unit_width: float = 80.0
@export var weapon_name_width: float = 150.0
## Glyph cells per row: substance count ("3/5"), heart rate, enemies left, ammo ("999/999").
@export var count_cells: int = 3
@export var heart_cells: int = 3
@export var enemies_cells: int = 3
@export var ammo_cells: int = 7

@export_group("Font")
## Unity's TMP default font (LiberationSans SDF) source; drawn bold like TMP's Bold style.
@export var font: Font
## Faux-bold strength (FontVariation.variation_embolden) standing in for TMP's Bold style.
@export var font_embolden: float = 0.9
## Extra space after each glyph, in em of label_font_size (TMP's bold spacing, 7 per 100 em).
@export var font_bold_spacing_em: float = 0.07

@export_group("Art")
@export var bevel_texture: Texture2D
@export var pulse_texture: Texture2D
## Texels of the bevel tile's 9-slice border.
@export var bevel_margin: int = 1
## Characters in glyph order; file names are glyph_path_format % [index, glyph_file_names[index]].
@export var glyph_order: String = "0123456789/:∞<>-."
@export var glyph_file_names: PackedStringArray = []
@export var glyph_path_format: String = "res://assets/art/ui/hud/hud_glyph_%02d_%s.png"
@export var face_path_format: String = "res://assets/art/ui/hud/hud_face_%d.png"
@export var icon_path_format: String = "res://assets/art/ui/hud/hud_icon_%s.png"

@export_group("Face")
## Share of the way from resting rate to a danger limit at which the face worsens one step.
@export var face_danger_steps: PackedFloat32Array = PackedFloat32Array([0.25, 0.5, 0.75])
@export var face_hysteresis_bpm: float = 2.0
@export var flinch_seconds: float = 0.45

@export_group("Text")
## Indexed by HeartRate.Zone.
@export var zone_names: PackedStringArray = []
@export var bpm_unit: String = "BPM"
## Unit shown in place of BPM while the pass-out / heart-attack countdown replaces the number.
@export var countdown_unit: String = "SEC"
@export var wave_format: String = "WAVE {wave}"
## {time} is replaced by mm:ss.
@export var time_format: String = "TIME {time}"
## Caption above the enemies-left number.
@export var enemies_text: String = "ENEMIES LEFT"
## {percent} is the held item's whole percent left.
@export var item_left_format: String = "{percent}%"
@export var item_empty_text: String = "EMPTY"

@export_group("Shift ability")
## Unity's status bar has no ability text; set true to show it as a small line at the top of the heart box.
@export var show_shift_text: bool = false
## Effect kind (ShiftAbility.KIND_*) to a "%.1f" format receiving real seconds left.
@export var shift_active_formats: Dictionary = {}
@export var shift_cooldown_format: String = "COOLDOWN %.1f"
@export var shift_ready_text: String = "SHIFT READY"
@export var shift_font_size: float = 20.0

@export_group("Colours")
@export var label_color: Color = Color(0.92, 0.92, 0.9)
## Captions: BPM unit, ENEMIES LEFT.
@export var caption_color: Color = Color(0.85, 0.85, 0.82)
## Glyph numbers and icons.
@export var number_color: Color = Color.WHITE
@export var dim_color: Color = Color(0.4, 0.4, 0.42)
@export var highlight_color: Color = Color(1.0, 0.84, 0.4)
@export var bar_color: Color = Color(0.16, 0.16, 0.17)
@export var box_color: Color = Color(0.11, 0.11, 0.12)
@export var panel_texture_tint: Color = Color(1.0, 1.0, 1.0, 0.18)
@export var bar_bevel_tint: Color = Color(0.56, 0.56, 0.56)
@export var box_bevel_tint: Color = Color(0.46, 0.46, 0.46)
@export var item_bar_color: Color = Color(0.9, 0.72, 0.3)
@export var item_track_color: Color = Color(0.05, 0.05, 0.06)
@export var pulse_back_color: Color = Color(0.02, 0.06, 0.03)
## Indexed by HeartRate.Zone.
@export var zone_colors: PackedColorArray = PackedColorArray()
