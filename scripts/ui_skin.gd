class_name UiSkin
## The embroidered linen look of the menus, the item bar, the shop and the level name.
## Each picture is a nine-patch: its edges keep their size, its middle is tiled.
## Without the pictures in art/ the callers fall back to plain shapes.

const DIR := "res://art/platformer/ui/wyszywanka/"
## Picture name -> edges that keep their size: left, top, right, bottom (picture pixels).
const EDGES := {
	"recznik": [6, 25, 6, 32],
	"pasek": [4, 9, 4, 10],
	"nazwa": [4, 9, 4, 10],
	"slot": [6, 6, 6, 6],
	"slot_wybrany": [6, 6, 6, 6],
}
## Thread colours, for text on the linen.
const INK := Color("2a1a18")
const RED := Color("9b1d22")

static var _boxes := {}


## The picture as a style box, or null when it is missing.
static func box(name: String) -> StyleBoxTexture:
	if _boxes.has(name):
		return _boxes[name]
	var style: StyleBoxTexture = null
	var path: String = DIR + name + ".png"
	if ResourceLoader.exists(path):
		style = StyleBoxTexture.new()
		style.texture = load(path)
		var edges: Array = EDGES[name]
		style.texture_margin_left = edges[0]
		style.texture_margin_top = edges[1]
		style.texture_margin_right = edges[2]
		style.texture_margin_bottom = edges[3]
		style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	_boxes[name] = style
	return style


static func has(name: String) -> bool:
	return box(name) != null


## Draws the picture over a screen rectangle, its pixels `scale` times bigger.
## Returns false when the picture is missing.
static func draw_box(item: CanvasItem, name: String, rect: Rect2, scale := 2.0, alpha := 1.0) -> bool:
	var style := box(name)
	if not style:
		return false
	style.modulate_color = Color(1, 1, 1, alpha)
	item.draw_set_transform(rect.position, 0.0, Vector2(scale, scale))
	item.draw_style_box(style, Rect2(Vector2.ZERO, rect.size / scale))
	item.draw_set_transform(Vector2.ZERO)
	return true


## A towel hanging from a wooden rod, as a node behind a menu; null when the picture is missing.
static func towel(rect: Rect2, scale := 3.0) -> Control:
	var style := box("recznik")
	if not style:
		return null
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cloth := Panel.new()
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloth.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cloth.add_theme_stylebox_override("panel", style)
	cloth.position = rect.position
	cloth.size = rect.size / scale
	cloth.scale = Vector2(scale, scale)
	root.add_child(cloth)
	var rod := Rect2(rect.position + Vector2(-36, -16), Vector2(rect.size.x + 72, 16))
	for part: Array in [[rod.grow(3), Color("2e1c10")], [rod, Color("6b4528")], [Rect2(rod.position, Vector2(rod.size.x, 4)), Color("8a5d36")]]:
		var wood := ColorRect.new()
		wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wood.position = part[0].position
		wood.size = part[0].size
		wood.color = part[1]
		root.add_child(wood)
	return root


## Buttons and labels in thread colours: plain text, the chosen one red and stitched under.
static func theme() -> Theme:
	var t := Theme.new()
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", RED)
	t.set_color("font_focus_color", "Button", RED)
	t.set_color("font_pressed_color", "Button", RED)
	t.set_color("font_hover_pressed_color", "Button", RED)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.4))
	t.set_stylebox("normal", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", StyleBoxEmpty.new())
	var chosen := StyleBoxFlat.new()
	chosen.bg_color = Color(RED, 0.08)
	chosen.border_color = RED
	chosen.border_width_bottom = 3
	chosen.content_margin_bottom = 4
	for state in ["hover", "focus", "pressed"]:
		t.set_stylebox(state, "Button", chosen)
	return t
