class_name PlaceholderArt
## Placeholder shapes, to be replaced by the author's art.

const OUTLINE := Color("2b1d14")


static func draw(h: Hotspot, art: String) -> void:
	if art == "drakkar":
		_drakkar(h)


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
