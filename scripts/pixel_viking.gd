class_name PixelViking
extends Node2D
## A small pixel-art Viking drawn at its real size and shown enlarged without smoothing.
## Frames are PNGs in ART_DIR named <colour>_walk_<n>.png, all the same size, drawn facing right.
## The origin is at the feet. When ANIM_DIR has frames (walk_<n>.png, hurt_<n>.png,
## death_<n>.png, on 96 px canvases) all Vikings use them instead, with the poses below.

const ART_DIR := "res://art/platformer/viking/"
## Each drawn pixel becomes PIXEL x PIXEL screen pixels.
const PIXEL := 3.0
const COLOURS := ["green", "red", "blue"]
const WALK_FRAMES := 4
const WALK_FPS := 8.0
## Where the feet are in a frame: the middle of the body, one row under the boots.
const FEET := Vector2(19, 43)
const ANIM_DIR := ART_DIR + "wiking/"
const ANIM_PIXEL := 2.0
const ANIM_FEET := Vector2(48, 78)
const ANIM_FPS := {"walk": 10.0, "hurt": 14.0, "death": 9.0, "attack": 12.0, "run": 12.0}
## The attack frame where the axe comes down.
const STRIKE_FRAME := 6

## 1 faces right, -1 left.
var facing := 1:
	set(value):
		facing = value
		if _sprite:
			_sprite.flip_h = value < 0
			_sprite.offset.x = -_feet.x if value > 0 else _feet.x - _sprite.texture.get_width()
var running := true
var colour := "green"
## How much faster than a walk the walk frames play (he runs when chasing).
var anim_speed := 1.0
## Seconds left of the "!" over his head when he spots Wiesław.
var alert := 0.0:
	set(value):
		alert = value
		queue_redraw()
## "walk" or "run" (looping), "hurt" or "attack" (once each) or "death" (once, then stays on its last
## frame); only with ANIM_DIR frames.
var pose := "walk":
	set(value):
		if value != pose:
			pose = value
			_time = 0.0

var _sprite: Sprite2D
var _frames: Array[Texture2D] = []
var _poses := {}
var _feet := FEET
var _time := 0.0


static func has_art() -> bool:
	return ResourceLoader.exists(ART_DIR + "green_walk_0.png") or ResourceLoader.exists(ANIM_DIR + "walk_0.png")


## How many frames a pose has (0 without ANIM_DIR frames).
func frames_of(name: String) -> int:
	return _poses.get(name, []).size()


func _ready() -> void:
	var pixel := PIXEL
	if ResourceLoader.exists(ANIM_DIR + "walk_0.png"):
		for name in ANIM_FPS:
			var list: Array[Texture2D] = []
			while ResourceLoader.exists(ANIM_DIR + "%s_%d.png" % [name, list.size()]):
				list.append(load(ANIM_DIR + "%s_%d.png" % [name, list.size()]))
			_poses[name] = list
		_frames = _poses["walk"]
		_feet = ANIM_FEET
		pixel = ANIM_PIXEL
	else:
		for i in WALK_FRAMES:
			_frames.append(load(ART_DIR + "%s_walk_%d.png" % [colour, i]))
	_sprite = Sprite2D.new()
	_sprite.texture = _frames[0]
	_sprite.centered = false
	_sprite.offset = -_feet
	_sprite.scale = Vector2.ONE * pixel
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	facing = facing


func _process(delta: float) -> void:
	if alert > 0.0:
		alert = maxf(alert - delta, 0.0)
	if not _poses.is_empty():
		_time += delta * (anim_speed if pose in ["walk", "run"] else 1.0)
		var list: Array = _poses.get(pose, [])
		if list.is_empty():
			list = _frames
		var frame := int(_time * float(ANIM_FPS.get(pose, WALK_FPS)))
		if pose in ["walk", "run"]:
			frame = frame % list.size() if running else 0
		elif frame >= list.size():
			if pose in ["hurt", "attack"]:
				pose = "walk"
				return
			frame = list.size() - 1
		_sprite.texture = list[frame]
		return
	if not running:
		return
	_time += delta
	_sprite.texture = _frames[int(_time * WALK_FPS) % WALK_FRAMES]


func _draw() -> void:
	if alert <= 0.0 or not _sprite:
		return
	# A pixel "!" over his helmet.
	var top := -(_feet.y - 10.0) * _sprite.scale.y - 34.0
	var ink := Color(1.0, 0.85, 0.2)
	draw_rect(Rect2(-5, top - 2, 10, 26), Color(0.15, 0.08, 0.05))
	draw_rect(Rect2(-5, top + 26, 10, 10), Color(0.15, 0.08, 0.05))
	draw_rect(Rect2(-3, top, 6, 22), ink)
	draw_rect(Rect2(-3, top + 28, 6, 6), ink)
