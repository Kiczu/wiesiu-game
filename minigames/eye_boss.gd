class_name EyeBoss
extends Node2D
## The end of Book I: the two Vikings who stole the apples share one magic eye. Whoever holds it
## sees and comes at Wiesław; the other gropes about blind. Now and then the holder tosses the eye
## to the other one, and while it flies (or lies on the ground after an apple knocks it down)
## Wiesław can grab it, which wins the fight. Sword and apples only push the Vikings back.

signal caught

## How long the holder keeps the eye before tossing it, and how long it flies.
const HOLD_TIME := 3.2
const FLIGHT_TIME := 1.3
## How high the eye goes over the middle of its flight.
const ARC := 230.0
const SEEING_SPEED := 150.0
const BLIND_SPEED := 45.0
## How far either side of where the fight was placed the Vikings may go.
const ARENA := 6.5 * PlatformerGame.TILE
const EYE_RADIUS := 16.0
const SIZE := Vector2(60, 120)

var game: PlatformerGame
## Two of {"node", "dir", "stun", "push"}.
var vikings: Array[Dictionary] = []
## The Viking holding the eye (0 or 1), or -1 while it flies or lies on the ground.
var holder := 0
var eye := Vector2.ZERO
var won := false

var _home := Vector2.ZERO
var _hold := HOLD_TIME
var _flight := 0.0
var _from := Vector2.ZERO
var _to := 0
## Where a knocked-down eye lies, and how long until a Viking gropes his way to it.
var _on_ground := false
var _ground_wait := 0.0
var _time := 0.0


func _init(at_game: PlatformerGame, at: Vector2) -> void:
	game = at_game
	_home = at
	position = Vector2.ZERO
	z_index = 1


func _ready() -> void:
	for i in 2:
		var body: Node2D
		if PixelViking.has_art():
			var pixel := PixelViking.new()
			pixel.colour = PixelViking.COLOURS[i]
			pixel.scale = Vector2(1.3, 1.3)
			body = pixel
		else:
			var placeholder := Character.new()
			placeholder.braids = true
			placeholder.body_color = Color("4f7a3a") if i == 0 else Color("d9692b")
			placeholder.scale = Vector2(0.8, 0.8)
			placeholder.running = true
			body = placeholder
		body.position = _home + Vector2((-2.5 if i == 0 else 2.5) * PlatformerGame.TILE, 0)
		get_parent().add_child.call_deferred(body)
		vikings.append({"node": body, "dir": 1.0 if i == 0 else -1.0, "stun": 0.0, "push": 0.0})
	eye = _head(0)


func _head(i: int) -> Vector2:
	return vikings[i]["node"].position + Vector2(0, -SIZE.y + 14)


func rect_of(i: int) -> Rect2:
	return Rect2(vikings[i]["node"].position - Vector2(SIZE.x / 2, SIZE.y), SIZE)


func step(delta: float) -> void:
	if won:
		return
	_time += delta
	for i in 2:
		_walk(i, delta)
	if holder >= 0:
		eye = _head(holder)
		_hold -= delta
		if _hold <= 0.0:
			_from = eye
			_to = 1 - holder
			holder = -1
			_flight = 0.0
	elif _on_ground:
		_ground_wait -= delta
		if _ground_wait <= 0.0:
			# The nearer Viking has found it.
			var near := 0 if absf(vikings[0]["node"].position.x - eye.x) < absf(vikings[1]["node"].position.x - eye.x) else 1
			_on_ground = false
			_give(near)
	else:
		_flight += delta / FLIGHT_TIME
		var target := _head(_to)
		if _flight >= 1.0:
			_give(_to)
		else:
			eye = _from.lerp(target, _flight) + Vector2(0, -ARC * 4.0 * _flight * (1.0 - _flight))
	var me := Rect2(game.player.position - Vector2(PlatformerGame.PLAYER_SIZE.x / 2, PlatformerGame.PLAYER_SIZE.y), PlatformerGame.PLAYER_SIZE)
	if holder < 0 and me.grow(EYE_RADIUS).has_point(eye):
		_catch()
		return
	for i in 2:
		if vikings[i]["stun"] <= 0.0 and me.intersects(rect_of(i)):
			game.hurt_by_boss()
	queue_redraw()


func _give(i: int) -> void:
	holder = i
	_hold = HOLD_TIME
	eye = _head(i)


## The one who sees walks at Wiesław; the blind one shuffles to and fro and turns at walls.
func _walk(i: int, delta: float) -> void:
	var viking := vikings[i]
	var node: Node2D = viking["node"]
	if viking["stun"] > 0.0:
		viking["stun"] -= delta
		_move(node, viking["push"] * delta)
		viking["push"] *= 0.85
		return
	var speed := BLIND_SPEED
	if i == holder:
		speed = SEEING_SPEED
		var toward := signf(game.player.position.x - node.position.x)
		if toward != 0.0:
			viking["dir"] = toward
	elif _on_ground:
		viking["dir"] = signf(eye.x - node.position.x)
	if not _move(node, viking["dir"] * speed * delta):
		viking["dir"] *= -1.0
	node.set("facing", int(signf(viking["dir"])) if viking["dir"] != 0.0 else 1)


## Moves sideways unless a wall, an edge or the end of the arena is in the way.
func _move(node: Node2D, dx: float) -> bool:
	var next := node.position + Vector2(dx, 0)
	var ahead := next + Vector2(signf(dx) * 28.0, 0)
	if absf(next.x - _home.x) > ARENA or game.tile_at(ahead + Vector2(0, -10)) in PlatformerGame.SOLID:
		return false
	var floor_tile := game.tile_at(ahead + Vector2(0, 10))
	if not (floor_tile in PlatformerGame.SOLID or floor_tile == "="):
		return false
	node.position = next
	return true


## The sword or an apple pushes a Viking back; an apple that hits the flying eye knocks it down.
func strike(area: Rect2, from_dir: float) -> bool:
	var hit := false
	for i in 2:
		if area.intersects(rect_of(i)) and vikings[i]["stun"] <= 0.0:
			vikings[i]["stun"] = 0.5
			vikings[i]["push"] = from_dir * 520.0
			var node: Node2D = vikings[i]["node"]
			node.modulate = Color(3, 3, 3)
			node.create_tween().tween_property(node, "modulate", Color.WHITE, 0.2)
			hit = true
	return hit


func knock_eye(at: Vector2) -> bool:
	if holder >= 0 or _on_ground or at.distance_to(eye) > EYE_RADIUS * 2.0:
		return false
	_on_ground = true
	_ground_wait = 2.5
	eye = Vector2(eye.x, floorf(eye.y / PlatformerGame.TILE) * PlatformerGame.TILE)
	while game.tile_at(eye + Vector2(0, 8)) == " " and eye.y < game.map.size() * PlatformerGame.TILE:
		eye.y += PlatformerGame.TILE
	eye.y -= EYE_RADIUS
	return true


func _catch() -> void:
	won = true
	holder = -1
	for viking in vikings:
		viking["node"].set("running", false)
		viking["node"].set("pose", "hurt")
	queue_redraw()
	caught.emit()


func _draw() -> void:
	if won:
		# Held high by Wiesław.
		_draw_eye(game.player.position + Vector2(0, -PlatformerGame.PLAYER_SIZE.y - 60), 1.3)
		return
	for i in 2:
		if i != holder:
			# The blind one: a question mark over his head.
			var head := _head(i) + Vector2(0, -62 + sin(_time * 4.0 + i) * 4.0)
			draw_string(ThemeDB.fallback_font, head + Vector2(-12, 0), "?", HORIZONTAL_ALIGNMENT_CENTER, 24, 34, Color("2b1d14"))
	if holder < 0 and not _on_ground:
		for k in 4:
			var back := maxf(_flight - k * 0.04, 0.0)
			var trail := _from.lerp(_head(_to), back) + Vector2(0, -ARC * 4.0 * back * (1.0 - back))
			draw_circle(trail, EYE_RADIUS * (1.0 - k * 0.2), Color(1, 0.95, 0.6, 0.25))
	_draw_eye(eye if holder < 0 else eye + Vector2(0, -6), 1.0 if holder < 0 else 0.7)


func _draw_eye(at: Vector2, size: float) -> void:
	var r := EYE_RADIUS * size
	draw_circle(at, r + 6, Color(1, 0.9, 0.5, 0.35 + 0.15 * sin(_time * 8.0)))
	draw_circle(at, r, Color.WHITE)
	draw_arc(at, r, 0.0, TAU, 24, Color("2b1d14"), 2.5)
	var look := (game.player.position + Vector2(0, -60) - at).normalized() * r * 0.35
	draw_circle(at + look, r * 0.5, Color("3a7bd5"))
	draw_circle(at + look, r * 0.22, Color("10141c"))
	draw_circle(at + look + Vector2(-r * 0.15, -r * 0.15), r * 0.1, Color.WHITE)
