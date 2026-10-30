class_name EyeBoss
extends Node2D
## The end of Book I: the two Vikings who stole the apples share one magic eye. Whoever holds it
## sees, comes at Wiesław and cannot be hurt; the other gropes about blind, and only he can be hit.
## When Wiesław goes for the blind one, the holder tosses him the eye: while it flies Wiesław can
## still hit him, but once he catches it he strikes at once. A Viking who takes HEALTH hits falls,
## the eye rolls away and Wiesław picks it up, which wins the fight. An apple that hits the flying
## eye knocks it down, and both Vikings are blind until one of them finds it.

signal caught

const HEALTH := 3
## How close Wiesław gets to the blind one before the holder tosses him the eye.
const TOSS_RANGE := 3.0 * PlatformerGame.TILE
## How long the eye flies, and how long a Viking keeps it before he may toss it again.
const FLIGHT_TIME := 1.1
const TOSS_COOLDOWN := 1.5
## How high the eye goes over the middle of its flight.
const ARC := 200.0
const SEEING_SPEED := 130.0
const BLIND_SPEED := 45.0
## The lunge a Viking makes as soon as he catches the eye.
const LUNGE_SPEED := 520.0
const LUNGE_TIME := 0.35
## How far either side of where the fight was placed the Vikings may go.
const ARENA := 6.5 * PlatformerGame.TILE
const EYE_RADIUS := 16.0
const SIZE := Vector2(60, 120)

var game: PlatformerGame
## Two of {"node", "dir", "stun", "push", "health", "lunge"}.
var vikings: Array[Dictionary] = []
## The Viking holding the eye (0 or 1), or -1 while it flies or lies on the ground.
var holder := 0
var eye := Vector2.ZERO
var won := false

var _home := Vector2.ZERO
var _cooldown := 0.0
var _flight := 0.0
var _from := Vector2.ZERO
var _to := 0
## A knocked-down or dropped eye lies on the ground until a Viking (or Wiesław) gets to it.
var _on_ground := false
var _ground_wait := 0.0
## Once a Viking has fallen, the eye on the ground is Wiesław's for the taking.
var _fallen := false
var _time := 0.0


func _init(at_game: PlatformerGame, at: Vector2) -> void:
	game = at_game
	_home = at
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
		vikings.append({"node": body, "dir": 1.0 if i == 0 else -1.0, "stun": 0.0, "push": 0.0, "health": HEALTH, "lunge": 0.0})
	eye = _head(0)


func _head(i: int) -> Vector2:
	return vikings[i]["node"].position + Vector2(0, -SIZE.y + 14)


func rect_of(i: int) -> Rect2:
	return Rect2(vikings[i]["node"].position - Vector2(SIZE.x / 2, SIZE.y), SIZE)


func _standing(i: int) -> bool:
	return vikings[i]["health"] > 0


func step(delta: float) -> void:
	if won:
		return
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	for i in 2:
		if _standing(i):
			_walk(i, delta)
	if holder >= 0:
		eye = _head(holder)
		var blind := 1 - holder
		if _cooldown <= 0.0 and _standing(blind) and absf(game.player.position.x - vikings[blind]["node"].position.x) < TOSS_RANGE:
			_from = eye
			_to = blind
			holder = -1
			_flight = 0.0
	elif _on_ground:
		_ground_wait -= delta
		if not _fallen and _ground_wait <= 0.0:
			# The nearer Viking has groped his way to it.
			var near := 0 if absf(vikings[0]["node"].position.x - eye.x) < absf(vikings[1]["node"].position.x - eye.x) else 1
			_on_ground = false
			_give(near)
	else:
		_flight += delta / FLIGHT_TIME
		if _flight >= 1.0:
			_give(_to)
			# He sees again, and strikes at once.
			vikings[_to]["lunge"] = LUNGE_TIME
			vikings[_to]["dir"] = signf(game.player.position.x - vikings[_to]["node"].position.x)
		else:
			eye = _from.lerp(_head(_to), _flight) + Vector2(0, -ARC * 4.0 * _flight * (1.0 - _flight))
	var me := Rect2(game.player.position - Vector2(PlatformerGame.PLAYER_SIZE.x / 2, PlatformerGame.PLAYER_SIZE.y), PlatformerGame.PLAYER_SIZE)
	if _fallen and me.grow(EYE_RADIUS).has_point(eye):
		_catch()
		return
	# Only the one who sees can hurt Wiesław; the blind one does not know where he is.
	if holder >= 0 and vikings[holder]["stun"] <= 0.0 and me.intersects(rect_of(holder)):
		game.hurt_by_boss()
	queue_redraw()


func _give(i: int) -> void:
	holder = i
	_cooldown = TOSS_COOLDOWN
	eye = _head(i)


## The one who sees walks at Wiesław (and lunges right after catching the eye); the blind one
## shuffles to and fro and turns at walls.
func _walk(i: int, delta: float) -> void:
	var viking := vikings[i]
	var node: Node2D = viking["node"]
	if viking["stun"] > 0.0:
		viking["stun"] -= delta
		_move(node, viking["push"] * delta)
		viking["push"] *= 0.85
		return
	var speed := BLIND_SPEED
	if viking["lunge"] > 0.0:
		viking["lunge"] -= delta
		speed = LUNGE_SPEED
	elif i == holder:
		speed = SEEING_SPEED
		var toward := signf(game.player.position.x - node.position.x)
		if toward != 0.0:
			viking["dir"] = toward
	elif _on_ground:
		viking["dir"] = signf(eye.x - node.position.x)
	if not _move(node, viking["dir"] * speed * delta):
		viking["dir"] *= -1.0
	node.set("facing", -1 if viking["dir"] < 0.0 else 1)


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


## The sword or an apple: the blind one (no eye in his hands) takes a hit and slides back; the one
## who sees only blocks it. Returns whether anyone was in the way.
func strike(area: Rect2, from_dir: float) -> bool:
	var hit := false
	for i in 2:
		if not _standing(i) or not area.intersects(rect_of(i)) or vikings[i]["stun"] > 0.0:
			continue
		hit = true
		var node: Node2D = vikings[i]["node"]
		vikings[i]["stun"] = 0.4
		vikings[i]["lunge"] = 0.0
		if i == holder:
			vikings[i]["push"] = from_dir * 160.0
			continue
		vikings[i]["push"] = from_dir * 520.0
		vikings[i]["health"] -= 1
		node.modulate = Color(3, 3, 3)
		node.create_tween().tween_property(node, "modulate", Color.WHITE, 0.2)
		if vikings[i]["health"] <= 0:
			_fall(i)
	return hit


## A beaten Viking falls over; the eye (in the other's hands or in the air) rolls to the ground
## between them, and the one left standing is too dazed to look for it.
func _fall(i: int) -> void:
	var node: Node2D = vikings[i]["node"]
	node.set("running", false)
	node.create_tween().tween_property(node, "rotation", -PI / 2 * signf(vikings[i]["push"]), 0.3)
	_fallen = true
	holder = -1
	_on_ground = true
	eye = Vector2(node.position.x + signf(vikings[i]["push"]) * 80.0, node.position.y - EYE_RADIUS)


func knock_eye(at: Vector2) -> bool:
	if holder >= 0 or _on_ground or at.distance_to(eye) > EYE_RADIUS * 2.0:
		return false
	_on_ground = true
	_ground_wait = 1.5
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
	queue_redraw()
	caught.emit()


func _draw() -> void:
	if won:
		# Held high by Wiesław.
		_draw_eye(game.player.position + Vector2(0, -PlatformerGame.PLAYER_SIZE.y - 60), 1.3)
		return
	var ink := Color("2b1d14")
	for i in 2:
		if not _standing(i):
			continue
		var head := _head(i) + Vector2(0, -62 + sin(_time * 4.0 + i) * 4.0)
		if i != holder:
			# The blind one: a question mark over his head.
			draw_string(ThemeDB.fallback_font, head + Vector2(-12, 0), "?", HORIZONTAL_ALIGNMENT_CENTER, 24, 34, ink)
		elif vikings[i]["lunge"] > 0.0:
			draw_string(ThemeDB.fallback_font, head + Vector2(-12, 0), "!", HORIZONTAL_ALIGNMENT_CENTER, 24, 40, Color("c0302a"))
		# Hits left, as small dots under the question mark.
		for k in vikings[i]["health"]:
			draw_circle(head + Vector2((k - (vikings[i]["health"] - 1) / 2.0) * 14.0, 16), 5, Color("c0302a"))
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
