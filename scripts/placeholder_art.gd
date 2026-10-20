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
		"pot":
			_pot(h)
		"cauldron":
			_cauldron(h)
		"coop":
			_coop(h)
		"sheep":
			_sheep(h)
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
	if Game.flag("jablka_w_drakkarze"):
		for i in 9:
			h.draw_circle(Vector2(-w / 2 + 40 + i * (w - 80) / 8.0, -74), 10, Color("d62828"))


static func _pot(h: Hotspot) -> void:
	h.draw_circle(Vector2(0, -16), 16, Color("7a4a2a"))
	h.draw_rect(Rect2(-12, -34, 24, 6), Color("5a3a1e"))
	h.draw_line(Vector2(6, -30), Vector2(12, -20), Color("f4e9d0"), 2.0)


static func _cauldron(h: Hotspot) -> void:
	for i in 3:
		h.draw_line(Vector2(-14 + i * 14, 0), Vector2(-10 + i * 10, -14), Color("e07a1f"), 5.0)
	h.draw_circle(Vector2(0, -36), 28, Color("2b2b2b"))
	h.draw_rect(Rect2(-30, -62, 60, 12), Color("2b2b2b"))
	h.draw_rect(Rect2(-24, -62, 48, 6), Color("111111"))


static func _coop(h: Hotspot) -> void:
	var w := h.size.x
	var hh := h.size.y
	h.draw_rect(Rect2(-w / 2, -hh * 0.7, w, hh * 0.7), WOOD)
	h.draw_colored_polygon(PackedVector2Array([Vector2(-w / 2 - 8, -hh * 0.7), Vector2(0, -hh), Vector2(w / 2 + 8, -hh * 0.7)]), Color("e0a832"))
	h.draw_rect(Rect2(-12, -30, 24, 30), Color("3b2a1a"))
	if not Game.flag("pierze_wziete"):
		h.draw_circle(Vector2(w / 2 - 14, -10), 12, Color("f4f4f4"))


static func _sheep(h: Hotspot) -> void:
	for i in 3:
		var at := Vector2(-60 + i * 60, -24)
		for puff in [Vector2(-12, 0), Vector2(0, -8), Vector2(12, 0), Vector2(0, 6)]:
			h.draw_circle(at + puff, 14, Color("f4f4f4"))
		h.draw_circle(at + Vector2(22, -6), 9, Color("3b3b3b"))
		h.draw_line(at + Vector2(-8, 16), at + Vector2(-8, 26), Color("3b3b3b"), 3.0)
		h.draw_line(at + Vector2(8, 16), at + Vector2(8, 26), Color("3b3b3b"), 3.0)
