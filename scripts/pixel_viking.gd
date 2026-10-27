class_name PixelViking
extends Node2D
## A small pixel-art Viking drawn at its real size and shown enlarged without smoothing.
## Frames are PNGs in ART_DIR named <colour>_walk_<n>.png, all the same size, drawn facing right.
## The origin is at the feet.

const ART_DIR := "res://art/platformer/viking/"
## Each drawn pixel becomes PIXEL x PIXEL screen pixels.
const PIXEL := 3.0
const COLOURS := ["green", "red", "blue"]
const WALK_FRAMES := 4
const WALK_FPS := 8.0
## Where the feet are in a frame: the middle of the body, one row under the boots.
const FEET := Vector2(19, 43)

## 1 faces right, -1 left.
var facing := 1:
	set(value):
		facing = value
		if _sprite:
			_sprite.flip_h = value < 0
			_sprite.offset.x = -FEET.x if value > 0 else FEET.x - _sprite.texture.get_width()
var running := true
var colour := "green"

var _sprite: Sprite2D
var _frames: Array[Texture2D] = []
var _time := 0.0


static func has_art() -> bool:
	return ResourceLoader.exists(ART_DIR + "green_walk_0.png")


func _ready() -> void:
	for i in WALK_FRAMES:
		_frames.append(load(ART_DIR + "%s_walk_%d.png" % [colour, i]))
	_sprite = Sprite2D.new()
	_sprite.texture = _frames[0]
	_sprite.centered = false
	_sprite.offset = -FEET
	_sprite.scale = Vector2.ONE * PIXEL
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	facing = facing


func _process(delta: float) -> void:
	if not running:
		return
	_time += delta
	_sprite.texture = _frames[int(_time * WALK_FPS) % WALK_FRAMES]
