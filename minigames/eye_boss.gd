class_name EyeBoss
extends Node2D
## The end of Book I: the two Vikings who stole the apples share one magic eye. Whoever holds it
## sees, comes at Wiesław swinging and cannot be hurt; the other gropes about blind, and only he
## can be hit. When Wiesław goes for the blind one and is out of the other's reach, the holder
## tosses him the eye: while it flies hits still land, but once he catches it he strikes at once.
## A beaten Viking drops the eye; the one left runs for it and then fights like any Viking, and
## when he falls too the eye is Wiesław's to pick up, which wins the fight. An apple that hits the
## flying eye knocks it down, and the Vikings have to grope for it.

signal caught

const HEALTH := 30
## How close Wiesław gets to the blind one, while farther than this from the holder, before the
## holder tosses the eye; and the wait after a toss before the next one.
const TOSS_RANGE := 2.5 * PlatformerGame.TILE
const SAFE_DISTANCE := 3.0 * PlatformerGame.TILE
const TOSS_COOLDOWN := 3.0
const FLIGHT_TIME := 1.7
## How high the eye goes over the middle of its flight.
const ARC := 220.0
const SEEING_SPEED := 130.0
const BLIND_SPEED := 45.0
## The one who sees lunges at Wiesław when he is this close, and right after catching the eye.
const ATTACK_RANGE := 1.8 * PlatformerGame.TILE
const ATTACK_COOLDOWN := 1.3
const LUNGE_SPEED := 520.0
const LUNGE_TIME := 0.35
## How far either side of where the fight was placed the Vikings may go.
const ARENA := 6.5 * PlatformerGame.TILE
const EYE_RADIUS := 16.0
const SIZE := Vector2(60, 120)

var game: PlatformerGame
## Two of {"node", "dir", "stun", "push", "health", "lunge", "rest"}.
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
## The eye lies on the ground until a Viking (or Wiesław) gets to it.
var _on_ground := false
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
		vikings.append({"node": body, "dir": 1.0 if i == 0 else -1.0, "stun": 0.0, "push": 0.0, "health": HEALTH,
			"lunge": 0.0, "rest": 0.0})
	eye = _head(0)


func _head(i: int) -> Vector2:
	return vikings[i]["node"].position + Vector2(0, -SIZE.y + 14)


func rect_of(i: int) -> Rect2:
	return Rect2(vikings[i]["node"].position - Vector2(SIZE.x / 2, SIZE.y), SIZE)


func _standing(i: int) -> bool:
	return vikings[i]["health"] > 0


## Whether only one Viking is left: he fights alone, eye or not.
func alone() -> bool:
	return not (_standing(0) and _standing(1))


func _distance(i: int) -> float:
	return absf(game.player.position.x - vikings[i]["node"].position.x)


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
		if not alone() and _cooldown <= 0.0 and vikings[holder]["lunge"] <= 0.0 \
				and _distance(blind) < TOSS_RANGE and _distance(holder) > SAFE_DISTANCE:
			_from = eye
			_to = blind
			holder = -1
			_flight = 0.0
	elif _on_ground:
		for i in 2:
			if _standing(i) and absf(vikings[i]["node"].position.x - eye.x) < 24.0:
				_give(i)
				break
	else:
		_flight += delta / FLIGHT_TIME
		if _flight >= 1.0:
			_give(_to)
			# He sees again, and strikes at once.
			_lunge(_to)
		else:
			eye = _from.lerp(_head(_to), _flight) + Vector2(0, -ARC * 4.0 * _flight * (1.0 - _flight))
	var me := Rect2(game.player.position - Vector2(PlatformerGame.PLAYER_SIZE.x / 2, PlatformerGame.PLAYER_SIZE.y), PlatformerGame.PLAYER_SIZE)
	if _on_ground and not _standing(0) and not _standing(1) and me.grow(EYE_RADIUS).has_point(eye):
		_catch()
		return
	# Only the one who sees can hurt Wiesław; the blind one does not know where he is.
	if holder >= 0 and vikings[holder]["stun"] <= 0.0 and me.intersects(rect_of(holder)):
		game.hurt_by_boss()
	queue_redraw()


func _give(i: int) -> void:
	holder = i
	_on_ground = false
	_cooldown = TOSS_COOLDOWN
	eye = _head(i)


func _lunge(i: int) -> void:
	vikings[i]["lunge"] = LUNGE_TIME
	vikings[i]["rest"] = ATTACK_COOLDOWN
	vikings[i]["dir"] = signf(game.player.position.x - vikings[i]["node"].position.x)


## The one who sees walks at Wiesław and lunges when close; the blind one shuffles to and fro and
## turns at walls; with the eye on the ground, whoever is standing heads for it.
func _walk(i: int, delta: float) -> void:
	var viking := vikings[i]
	var node: Node2D = viking["node"]
	viking["rest"] = maxf(viking["rest"] - delta, 0.0)
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
		if _distance(i) < ATTACK_RANGE and viking["rest"] <= 0.0:
			_lunge(i)
	elif _on_ground:
		# The last one standing knows where it fell; a blind one has to grope.
		speed = SEEING_SPEED * 1.2 if alone() else BLIND_SPEED * 2.0
		viking["dir"] = signf(eye.x - node.position.x)
	if not _move(node, viking["dir"] * speed * delta) and viking["lunge"] <= 0.0:
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


## The sword or an apple: a Viking without the eye (or the last one left) takes the damage and
## slides back; the one who sees only blocks. Returns whether anyone was in the way.
func strike(area: Rect2, from_dir: float, damage: int) -> bool:
	var hit := false
	for i in 2:
		if not _standing(i) or not area.intersects(rect_of(i)) or vikings[i]["stun"] > 0.0:
			continue
		hit = true
		var node: Node2D = vikings[i]["node"]
		vikings[i]["stun"] = 0.4
		vikings[i]["lunge"] = 0.0
		if i == holder and not alone():
			vikings[i]["push"] = from_dir * 160.0
			continue
		vikings[i]["push"] = from_dir * 520.0
		vikings[i]["health"] -= damage
		node.modulate = Color(3, 3, 3)
		node.create_tween().tween_property(node, "modulate", Color.WHITE, 0.2)
		if vikings[i]["health"] <= 0:
			_fall(i)
	return hit


## A beaten Viking falls over and the eye (wherever it was) rolls to the ground near him.
func _fall(i: int) -> void:
	var node: Node2D = vikings[i]["node"]
	node.set("running", false)
	node.create_tween().tween_property(node, "rotation", -PI / 2 * signf(vikings[i]["push"]), 0.3)
	holder = -1
	_on_ground = true
	var x := node.position.x + signf(vikings[i]["push"]) * 80.0
	if absf(x - _home.x) > ARENA:
		x = node.position.x - signf(vikings[i]["push"]) * 80.0
	eye = Vector2(x, node.position.y - EYE_RADIUS)


func knock_eye(at: Vector2) -> bool:
	if holder >= 0 or _on_ground or at.distance_to(eye) > EYE_RADIUS * 2.0:
		return false
	_on_ground = true
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
		# Above the helmet and its horns.
		var head: Vector2 = vikings[i]["node"].position + Vector2(0, -185)
		PlatformerGame.draw_health_bar(self, head + Vector2(0, -6), float(vikings[i]["health"]) / HEALTH, 70.0)
		var bob := sin(_time * 4.0 + i) * 4.0
		if i != holder:
			# The blind one: a question mark over his head.
			draw_string(ThemeDB.fallback_font, head + Vector2(-12, -18 + bob), "?", HORIZONTAL_ALIGNMENT_CENTER, 24, 34, ink)
		elif vikings[i]["lunge"] > 0.0:
			draw_string(ThemeDB.fallback_font, head + Vector2(-12, -18 + bob), "!", HORIZONTAL_ALIGNMENT_CENTER, 24, 40, Color("c0302a"))
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
