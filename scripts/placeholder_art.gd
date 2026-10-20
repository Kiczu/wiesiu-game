class_name PlaceholderArt
## Placeholder shapes, to be replaced by the author's art.

const OUTLINE := Color("2b1d14")


static func draw(h: Hotspot, art: String) -> void:
	match art:
		"tree":
			_tree(h)
		"rake":
			_rake(h)
		"well":
			_well(h)


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
	for apple in [Vector2(-70, -hh * 0.58), Vector2(55, -hh * 0.7), Vector2(-20, -hh * 0.5)]:
		h.draw_circle(apple, 10, Color("ffcc33"))
		h.draw_arc(apple, 10, 0, TAU, 16, OUTLINE, 1.5)
	if not Game.flag("pioro_zdobyte"):
		var f := Vector2(70, -hh * 0.9)
		var feather := PackedVector2Array([f, f + Vector2(14, -10), f + Vector2(34, -6), f + Vector2(16, 4)])
		h.draw_colored_polygon(feather, Color("ffb000"))
		h.draw_line(f, f + Vector2(34, -6), Color("fff1a8"), 2.0)


static func _rake(h: Hotspot) -> void:
	var hh := h.size.y
	h.draw_line(Vector2(0, 0), Vector2(6, -hh + 10), Color("8b5a2b"), 6.0)
	h.draw_rect(Rect2(-14, -hh, 40, 8), Color("6b6b6b"))
	for i in 5:
		h.draw_line(Vector2(-12 + i * 9, -hh + 8), Vector2(-12 + i * 9, -hh + 20), Color("6b6b6b"), 3.0)


static func _well(h: Hotspot) -> void:
	var w := h.size.x
	var hh := h.size.y
	h.draw_rect(Rect2(-w / 2, -hh * 0.45, w, hh * 0.45), Color("9a9a9a"))
	h.draw_rect(Rect2(-w / 2, -hh * 0.45, w, hh * 0.45), OUTLINE, false, 2.0)
	h.draw_rect(Rect2(-w / 2 + 6, -hh, 8, hh * 0.55), Color("6b4423"))
	h.draw_rect(Rect2(w / 2 - 14, -hh, 8, hh * 0.55), Color("6b4423"))
	var roof := PackedVector2Array([Vector2(-w / 2 - 10, -hh + 4), Vector2(0, -hh - 30), Vector2(w / 2 + 10, -hh + 4)])
	h.draw_colored_polygon(roof, Color("a0522d"))
	h.draw_polyline(roof, OUTLINE, 2.0)
