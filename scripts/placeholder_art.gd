class_name PlaceholderArt
## Placeholder shapes, to be replaced by the author's art.

const OUTLINE := Color("2b1d14")
const WOOD := Color("8b5a2b")


static func draw(h: Hotspot, art: String) -> void:
	match art:
		"tree":
			_tree(h)
		"barrel":
			_barrel(h)
		"table":
			_table(h)
		"door":
			_door(h)
		"throne":
			_throne(h)
		"bushes":
			_bushes(h)
		"drakkar":
			_drakkar(h)


static func _tree(h: Hotspot) -> void:
	var w := h.size.x
	var hh := h.size.y
	h.draw_rect(Rect2(-20, -hh * 0.5, 40, hh * 0.5), Color("6b4423"))
	var crown := [
		Vector2(0, -hh * 0.72), Vector2(-w * 0.28, -hh * 0.6), Vector2(w * 0.28, -hh * 0.6),
		Vector2(-w * 0.16, -hh * 0.86), Vector2(w * 0.16, -hh * 0.86),
	]
	for c in crown:
		h.draw_circle(c, w * 0.24, Color("3f8f3a"))
	for apple in [Vector2(-70, -hh * 0.58), Vector2(55, -hh * 0.7), Vector2(-20, -hh * 0.5), Vector2(80, -hh * 0.55), Vector2(-40, -hh * 0.85)]:
		h.draw_circle(apple, 9, Color("d62828"))
		h.draw_arc(apple, 9, 0, TAU, 16, OUTLINE, 1.5)


static func _barrel(h: Hotspot) -> void:
	var w := h.size.x
	var hh := h.size.y
	var body := Rect2(-w / 2, -hh, w, hh)
	h.draw_rect(body, WOOD)
	for y in [-hh * 0.8, -hh * 0.2]:
		h.draw_line(Vector2(-w / 2, y), Vector2(w / 2, y), Color("4a4a4a"), 4.0)
	h.draw_rect(body, OUTLINE, false, 2.0)


static func _table(h: Hotspot) -> void:
	var w := h.size.x
	h.draw_rect(Rect2(-w / 2, -60, w, 12), WOOD)
	h.draw_rect(Rect2(-w / 2 + 8, -48, 10, 48), Color("6b4423"))
	h.draw_rect(Rect2(w / 2 - 18, -48, 10, 48), Color("6b4423"))
	if not Game.flag("kubek_wziety"):
		h.draw_rect(Rect2(-8, -82, 16, 22), Color("a0522d"))
		h.draw_rect(Rect2(-8, -82, 16, 22), OUTLINE, false, 1.5)


static func _door(h: Hotspot) -> void:
	var rect := Rect2(-h.size.x / 2, -h.size.y, h.size.x, h.size.y)
	h.draw_rect(rect, Color("5a3a1e"))
	for i in 4:
		var x := rect.position.x + rect.size.x * (i + 1) / 5.0
		h.draw_line(Vector2(x, rect.position.y), Vector2(x, 0), OUTLINE, 2.0)
	h.draw_rect(rect, OUTLINE, false, 3.0)
	h.draw_circle(Vector2(rect.position.x + 18, -h.size.y / 2), 6, Color("e0a832"))


static func _throne(h: Hotspot) -> void:
	var w := h.size.x
	var hh := h.size.y
	h.draw_rect(Rect2(-w / 2, -hh, w, hh * 0.7), WOOD)
	h.draw_rect(Rect2(-w / 2 - 10, -hh * 0.4, w + 20, 22), Color("6b4423"))
	h.draw_rect(Rect2(-w / 2 + 6, -hh * 0.3, 14, hh * 0.3), Color("6b4423"))
	h.draw_rect(Rect2(w / 2 - 20, -hh * 0.3, 14, hh * 0.3), Color("6b4423"))
	h.draw_circle(Vector2(0, -hh * 0.75), 16, Color("e0a832"))
	h.draw_rect(Rect2(-w / 2, -hh, w, hh * 0.7), OUTLINE, false, 2.0)

static func _bushes(h: Hotspot) -> void:
	var w := h.size.x
	var hh := h.size.y
	for i in 4:
		var x := -w / 2 + w * (i + 0.5) / 4.0
		h.draw_circle(Vector2(x, -hh * 0.45), hh * 0.5, Color("2f6f2a"))


static func _drakkar(h: Hotspot) -> void:
	var w := h.size.x
	var hh := h.size.y
	# Mast and the striped sail sit behind the hull.
	h.draw_rect(Rect2(-4, -hh, 8, hh * 0.75), Color("6b4423"))
	for i in 6:
		var stripe := Color("d62828") if i % 2 == 0 else Color.WHITE
		h.draw_rect(Rect2(-60, -hh + 10 + i * 14, 120, 14), stripe)
	var hull_color := Color("9b6b3d")
	for side in [-1, 1]:
		var prow := PackedVector2Array([
			Vector2(side * (w / 2 - 40), -70), Vector2(side * (w / 2 + 30), -130), Vector2(side * w / 2, -70),
		])
		h.draw_colored_polygon(prow, hull_color)
		h.draw_polyline(prow + PackedVector2Array([prow[0]]), OUTLINE, 2.0)
	var hull := PackedVector2Array([
		Vector2(-w / 2, -70), Vector2(w / 2, -70), Vector2(w / 2 - 40, 0), Vector2(-w / 2 + 40, 0),
	])
	h.draw_colored_polygon(hull, hull_color)
	h.draw_polyline(hull + PackedVector2Array([hull[0]]), OUTLINE, 2.0)
	if Game.flag("jablka_odzyskane"):
		for i in 9:
			h.draw_circle(Vector2(-w / 2 + 40 + i * (w - 80) / 8.0, -74), 10, Color("d62828"))
