class_name CrumblingFloor
extends Node2D
## A slab of cellar floor over a hole (Z cells outside the castle). It holds until Wiesław stands
## on it: then it trembles and sheds grit for a moment, breaks into lumps that tumble down the
## hole, and the hole is open from then on.

## How long it trembles before it gives way (seconds), and how hard.
const HOLD := 0.65
const TREMBLE := 3.0
## The lumps it breaks into (level px wide), how fast they fall and how long they are seen.
const LUMP := 32.0
const GRAVITY := 1800.0
const FALL_TIME := 1.2

signal started_trembling(at: Vector2)
signal gave_way(cells: Array[Vector2i])

## The slab's place in the level: its top is the floor's surface.
var area := Rect2()
var cells: Array[Vector2i] = []
## The floor's top picture (laid across the slab), its scale and where its surface is on it.
var picture: Texture2D
var picture_scale := 1.0
var surface := 0.0
var dark := Color.BLACK
## The level, whose Wiesław (player) may stand on the slab.
var _game: Node
var _trembling := -1.0
var _lumps: Array = []
var _time := 0.0


func _init(place: Rect2, floor_cells: Array[Vector2i], game: Node) -> void:
	area = place
	cells = floor_cells
	_game = game
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _physics_process(delta: float) -> void:
	_time += delta
	if not _lumps.is_empty():
		_fall(delta)
	elif _trembling >= 0.0:
		_trembling += delta
		if _trembling >= HOLD:
			_break()
	elif _stood_on():
		_trembling = 0.0
		started_trembling.emit(Vector2(area.get_center().x, area.position.y))
	else:
		return
	queue_redraw()


## Whether Wiesław stands on the slab: on the floor, his feet on its top and over it.
func _stood_on() -> bool:
	var player: CharacterBody2D = _game.get("player")
	if not is_instance_valid(player) or not player.is_on_floor():
		return false
	var feet := player.position
	return absf(feet.y - area.position.y) < 6.0 and feet.x > area.position.x + 6.0 and feet.x < area.end.x - 6.0


func _break() -> void:
	# Lumps about LUMP across, in rows from the top of the floor's picture down to the slab's bottom.
	var top := -surface * picture_scale
	var across := maxi(int(area.size.x / LUMP), 1)
	var down := maxi(int((area.size.y - top) / LUMP), 1)
	var size := Vector2(area.size.x / across, (area.size.y - top) / down)
	for row in down:
		for col in across:
			var spread := (col + 0.5) / across - 0.5
			_lumps.append({"part": Rect2(Vector2(col * size.x, top + row * size.y), size), "at": Vector2.ZERO,
				"speed": Vector2(spread * 220.0 + randf_range(-40.0, 40.0), randf_range(-140.0, 0.0) - (down - row) * 30.0),
				"turn": 0.0, "spin": randf_range(-4.0, 4.0)})
	_time = 0.0
	gave_way.emit(cells)


func _fall(delta: float) -> void:
	for lump: Dictionary in _lumps:
		lump["speed"].y += GRAVITY * delta
		lump["at"] += lump["speed"] * delta
		lump["turn"] += lump["spin"] * delta
	if _time > FALL_TIME:
		queue_free()


func _draw() -> void:
	if _lumps.is_empty():
		var shift := Vector2.ZERO
		if _trembling >= 0.0:
			var grow := _trembling / HOLD
			shift = Vector2(sin(_trembling * 70.0) * TREMBLE * grow, absf(sin(_trembling * 53.0)) * grow * 2.0)
		var top := -surface * picture_scale
		_draw_part(Rect2(0, top, area.size.x, area.size.y - top), shift, 0.0, 1.0)
		if _trembling >= 0.0:
			_draw_cracks(shift)
		return
	var fade := clampf(1.0 - (_time - FALL_TIME * 0.5) / (FALL_TIME * 0.5), 0.0, 1.0)
	for lump: Dictionary in _lumps:
		_draw_part(lump["part"], lump["at"], lump["turn"], fade)


## A part of the slab (a rect from its top-left corner), moved and turned about its middle: the
## dark earth with the floor's top picture over it.
func _draw_part(part: Rect2, shift: Vector2, turn: float, alpha: float) -> void:
	draw_set_transform(area.position + part.get_center() + shift, turn)
	var dirt := part.intersection(Rect2(0, 10, area.size.x, area.size.y - 10))
	if dirt.has_area():
		draw_rect(Rect2(dirt.position - part.get_center(), dirt.size), Color(dark, alpha))
	if picture:
		var top := -surface * picture_scale
		var whole := Rect2(0, top, area.size.x, minf(picture.get_height() * picture_scale, area.size.y - top))
		var seen := part.intersection(whole)
		if seen.has_area():
			var source := Rect2(fposmod(area.position.x + seen.position.x, picture.get_width() * picture_scale) / picture_scale,
				(seen.position.y - top) / picture_scale, seen.size.x / picture_scale, seen.size.y / picture_scale)
			draw_texture_rect_region(picture, Rect2(seen.position - part.get_center(), seen.size), source, Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO)


## Cracks spreading through the slab as it trembles.
func _draw_cracks(shift: Vector2) -> void:
	var grow := clampf(_trembling / HOLD, 0.0, 1.0)
	var count := maxi(int(area.size.x / LUMP) - 1, 1)
	var width := area.size.x / (count + 1)
	for k in count:
		var x := area.position.x + (k + 1) * width + shift.x
		var points := PackedVector2Array([Vector2(x, area.position.y + shift.y)])
		for step in 4:
			var last := points[points.size() - 1]
			points.append(last + Vector2((-1.0 if (k + step) % 2 == 0 else 1.0) * 5.0, area.size.y * 0.25 * grow))
		draw_polyline(points, Color(0.05, 0.03, 0.03, 0.9), 3.0)
