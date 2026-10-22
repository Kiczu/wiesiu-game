class_name ComicStrip
extends CanvasLayer
## Comic pages shown before and after a level: up to three panels per page, each with
## placeholder characters, a speech bubble and a caption. E, space or a click turns the page.

signal finished
signal pause_requested

const SCREEN := Vector2(1280, 720)
const MARGIN := 40.0
const GAP := 24.0
const PAPER := Color("f4ead5")
const INK := Color("2b1d14")

## Pages, each an array of panels: {"bg": Color, "caption": String,
## "chars": [{"pos": Vector2, ...Character properties}], "say": {"who": int, "text": String}}
var pages: Array = []
var page := 0

var _view: Node2D
var _actors: Node2D


func _init(comic_pages: Array = []) -> void:
	pages = comic_pages


func _ready() -> void:
	layer = 3
	_view = Node2D.new()
	add_child(_view)
	_view.draw.connect(_draw_page)
	_actors = Node2D.new()
	add_child(_actors)
	if Game.fast or pages.is_empty():
		finished.emit.call_deferred()
		return
	_show_page(0)


func next_page() -> void:
	if page + 1 >= pages.size():
		finished.emit()
		return
	_show_page(page + 1)


func _show_page(index: int) -> void:
	page = index
	for child in _actors.get_children():
		child.queue_free()
	var panels: Array = pages[page]
	for i in panels.size():
		var rect := _panel_rect(i, panels.size())
		for spec in panels[i].get("chars", []):
			var actor := Character.new()
			for key in spec:
				if key != "pos":
					actor.set(key, spec[key])
			actor.position = rect.position + spec["pos"]
			actor.scale = Vector2(1.1, 1.1)
			_actors.add_child(actor)
	_view.queue_redraw()


func _panel_rect(index: int, count: int) -> Rect2:
	var width := (SCREEN.x - MARGIN * 2 - GAP * (count - 1)) / count
	return Rect2(MARGIN + index * (width + GAP), 70, width, 560)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("cancel"):
		pause_requested.emit()
	elif event.is_action("interact") or event is InputEventMouseButton or event is InputEventScreenTouch:
		next_page()
	else:
		return
	get_viewport().set_input_as_handled()


func _draw_page() -> void:
	var v := _view
	var font := ThemeDB.fallback_font
	v.draw_rect(Rect2(Vector2.ZERO, SCREEN), PAPER)
	var panels: Array = pages[page]
	for i in panels.size():
		var panel: Dictionary = panels[i]
		var rect := _panel_rect(i, panels.size())
		v.draw_rect(rect, panel.get("bg", Color("bfe3f5")))
		v.draw_rect(Rect2(rect.position.x, rect.end.y - 110, rect.size.x, 110), panel.get("ground", Color("7fb069")))
		v.draw_rect(rect, INK, false, 4.0)
		if panel.has("caption"):
			var box := Rect2(rect.position + Vector2(10, 10), Vector2(rect.size.x - 20, 70))
			v.draw_rect(box, Color("f2d27a"))
			v.draw_rect(box, INK, false, 2.0)
			v.draw_multiline_string(font, box.position + Vector2(10, 28), panel["caption"], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 20, 20, 3, INK)
		if panel.has("say"):
			var who: Dictionary = panel["chars"][panel["say"]["who"]]
			var head: Vector2 = rect.position + who["pos"] + Vector2(0, -170)
			var text: String = panel["say"]["text"].to_upper()
			var text_size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 52, 22)
			var box := Rect2(rect.position.x + 14, rect.position.y + 100, rect.size.x - 28, text_size.y + 28)
			v.draw_colored_polygon(PackedVector2Array([Vector2(box.get_center().x - 16, box.end.y - 2), Vector2(box.get_center().x + 16, box.end.y - 2), head]), Color.WHITE)
			v.draw_rect(box, Color.WHITE)
			v.draw_rect(box, INK, false, 3.0)
			v.draw_multiline_string(font, box.position + Vector2(12, 14 + font.get_ascent(22)), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 24, 22, -1, INK)
	var hint := "E / spacja / klik: dalej" if page + 1 < pages.size() else "E / spacja / klik: do gry"
	v.draw_string(font, Vector2(0, SCREEN.y - 30), hint, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 20, Color(INK, 0.7))
