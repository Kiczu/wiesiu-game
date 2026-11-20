class_name FlyingShip
extends Node2D
## The Vikings' drakkar hanging in the air over the eye fight. It rises and falls slowly and rocks a
## little, and its deck (a floor Wiesław can jump up through) goes with it. A rope ladder hangs
## over its side and is the only way up: its cells are H in the map, so it climbs like any ladder.

const PICTURE := "res://art/platformer/boss/drakkar.png"
## The part of the ladder hanging below the hull, cut out of the ship's picture so it can swing
## (drawn in code instead when missing).
const LADDER_PICTURE := "res://art/platformer/boss/drabinka.png"
## The places below are in px of the picture as if it were WIDTH px wide (whatever its real
## size), each SCALE level px.
const WIDTH := 233.0
const SCALE := 3.0
## Where the deck is on the picture (from the top) and how far along it goes.
const DECK_Y := 82.0
const DECK_FROM := 40.0
const DECK_TO := 195.0
## Where the ladder hangs (its middle, from the picture's left) and where it leaves the hull.
const LADDER_X := 143.0
const LADDER_TOP := 117.0
## How far it rises and falls (level px), how fast, and how far it rocks (radians).
const RISE := 10.0
const RISE_SPEED := 1.1
const ROCK := 0.012
const ROPE := Color("5a3b20")
const RUNG := Color("8b5a2b")
const INK := Color("1a120c")

var texture: Texture2D
var ladder_texture: Texture2D
## The level y of the deck at rest, and of the ladder's lowest rung.
var deck_top := 0.0
var ladder_bottom := 0.0
var _rest := Vector2.ZERO
## The deck: a body of its own beside the ship, moved with it, so it carries whoever stands on it.
var _deck: AnimatableBody2D
var _deck_at := Vector2.ZERO
var _time := 0.0


static func has_art() -> bool:
	return ResourceLoader.exists(PICTURE)


## The level x of the ladder when the ship's middle stands at x.
static func ladder_x(middle: float) -> float:
	return middle + (LADDER_X - WIDTH / 2.0) * SCALE


func _init(middle: float, deck: float, ladder_end: float) -> void:
	texture = load(PICTURE)
	if ResourceLoader.exists(LADDER_PICTURE):
		ladder_texture = load(LADDER_PICTURE)
	deck_top = deck
	ladder_bottom = ladder_end
	_rest = Vector2(middle, deck)
	position = _rest
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	var deck := AnimatableBody2D.new()
	_deck = deck
	deck.sync_to_physics = false
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2((DECK_TO - DECK_FROM) * SCALE, 16.0)
	shape.one_way_collision = true
	_deck_at = Vector2(((DECK_FROM + DECK_TO) / 2.0 - WIDTH / 2.0) * SCALE, 8.0)
	deck.add_child(shape)
	deck.position = _rest + _deck_at
	get_parent().add_child.call_deferred(deck)


func _physics_process(delta: float) -> void:
	_time += delta
	position = _rest + Vector2(0, sin(_time * RISE_SPEED) * RISE)
	rotation = sin(_time * RISE_SPEED * 0.6 + 1.0) * ROCK
	if is_instance_valid(_deck):
		_deck.position = position + _deck_at.rotated(rotation)
		_deck.rotation = rotation
	queue_redraw()


func _draw() -> void:
	var size := Vector2(WIDTH, WIDTH * texture.get_height() / texture.get_width()) * SCALE
	draw_texture_rect(texture, Rect2(Vector2(-size.x / 2.0, -DECK_Y * SCALE), size), false)
	var top := Vector2((LADDER_X - WIDTH / 2.0) * SCALE, 0)
	if ladder_texture:
		var unit := size.x / texture.get_width()
		_draw_ladder_picture(top + Vector2(0, (LADDER_TOP - DECK_Y) * SCALE), unit)
	else:
		_draw_ladder(top, ladder_bottom - deck_top)


func _exit_tree() -> void:
	if is_instance_valid(_deck):
		_deck.queue_free()


## A rope ladder thrown over the gunwale, its bottom swinging a little.
func _draw_ladder(top: Vector2, length: float) -> void:
	var swing := sin(_time * 1.4) * 8.0
	var half := 18.0
	var rungs := int(length / 28.0)
	var at := func(share: float, side: float) -> Vector2:
		return top + Vector2(side * half + swing * share * share, share * length)
	for side in [-1.0, 1.0]:
		var points := PackedVector2Array()
		for k in 11:
			points.append(at.call(k / 10.0, side))
		draw_polyline(points, INK, 6.0)
		draw_polyline(points, ROPE, 3.0)
	for k in range(1, rungs + 1):
		var share := (k * 28.0) / length
		var left: Vector2 = at.call(share, -1.0)
		var right: Vector2 = at.call(share, 1.0)
		draw_line(left - Vector2(4, 0), right + Vector2(4, 0), INK, 9.0)
		draw_line(left - Vector2(2, 0), right + Vector2(2, 0), RUNG, 5.0)


## The ladder's picture, its bottom swinging: drawn one row of its pixels at a time, each row
## moved along the swing (more the lower it is) by whole level px, so the pixels stay upright and
## the bend moves smoothly.
func _draw_ladder_picture(top: Vector2, unit: float) -> void:
	var swing := sin(_time * 1.2) * 5.0
	var rows := ladder_texture.get_height()
	var width := ladder_texture.get_width()
	for row in rows:
		var share := float(row) / rows
		var shift := roundf(swing * share * share)
		draw_texture_rect_region(ladder_texture, Rect2(top + Vector2(-width * unit / 2.0 + shift, row * unit), Vector2(width, 1) * unit),
			Rect2(0, row, width, 1))
