class_name Rat
extends Node2D
## A dungeon rat, drawn from frames bieg_<n>.png in ART_DIR (facing right) or, without them, as a
## grey placeholder. The origin is at the feet.

const ART_DIR := "res://art/platformer/szczur/"
## Each drawn pixel becomes PIXEL x PIXEL screen pixels.
const PIXEL := 2.0
const FPS := 14.0
## Where the front feet are in a frame.
const FEET := Vector2(42, 27)

## 1 faces right, -1 left.
var facing := 1:
	set(value):
		facing = value
		queue_redraw()

var _frames: Array[Texture2D] = []
var _time := 0.0


static func has_art() -> bool:
	return ResourceLoader.exists(ART_DIR + "bieg_0.png")


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	while ResourceLoader.exists(ART_DIR + "bieg_%d.png" % _frames.size()):
		_frames.append(load(ART_DIR + "bieg_%d.png" % _frames.size()))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(PIXEL * facing, PIXEL))
	if not _frames.is_empty():
		draw_texture(_frames[int(_time * FPS) % _frames.size()], -FEET)
		return
	# Placeholder: a grey body, a pink tail and a red eye.
	var bob := sin(_time * 30.0) * 1.0
	draw_line(Vector2(-12, -6), Vector2(-30, -4 + sin(_time * 12.0) * 3.0), Color("c48080"), 2.0)
	draw_circle(Vector2(0, -10 + bob), 11, Color("4a4a50"))
	draw_circle(Vector2(12, -9 + bob), 6, Color("4a4a50"))
	draw_circle(Vector2(15, -11 + bob), 1.5, Color("e03030"))
