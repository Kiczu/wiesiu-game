class_name FlightGame
extends CanvasLayer
## Mini-game: the drakkar flies to the next place. Steer up and down, dodge birds and storm clouds,
## catch apples. Three hits and the flight starts over; reaching the end finishes it.

signal finished
signal pause_requested

const SCREEN := Vector2(1280, 720)
const DURATION := 40.0
const LIVES := 3
const SHIP_X := 220.0
const SHIP_SPEED := 380.0
const SHIP_HITBOX := Vector2(170, 60)
const SKY_TOP := Color("7fc4ec")
const SKY_BOTTOM := Color("d9f0fb")

var lives := LIVES
var apples := 0
var elapsed := 0.0
var ship_y := SCREEN.y / 2
## Things flying at the ship: {"kind": "apple" | "bird" | "cloud", "pos": Vector2, "speed": float}
var objects: Array[Dictionary] = []
## "" while flying, then "won" or "lost".
var state := ""

var _view: Node2D
var _ship: Hotspot
var _pilot: Character
var _spawn_in := 1.0
var _hit_flash := 0.0
var _scroll := 0.0
var _fade := 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = 2
	_view = Node2D.new()
	add_child(_view)
	_view.draw.connect(_draw_view)
	_ship = Hotspot.new()
	_ship.art = "drakkar"
	_ship.size = Vector2(240, 190)
	_ship.scale = Vector2(0.8, 0.8)
	_view.add_child(_ship)
	_pilot = Character.new()
	_pilot.helmet = true
	_pilot.body_color = Color("7b5ea7")
	_pilot.scale = Vector2(0.45, 0.45)
	_view.add_child(_pilot)
	if Game.fast:
		state = "won"
		finished.emit.call_deferred()
		return
	if get_parent() == get_tree().root:
		# Run on its own (F6 in the editor): fly again after landing.
		finished.connect(func() -> void:
			_fade = 1.0
			_restart()
			set_process(true))
	_restart()


func _restart() -> void:
	lives = LIVES
	apples = 0
	elapsed = 0.0
	ship_y = SCREEN.y / 2
	objects.clear()
	state = ""
	_spawn_in = 1.5


func _process(delta: float) -> void:
	var ending := state == "won" and elapsed >= DURATION + 1.0
	_fade = clampf(_fade + (2.0 if ending else -2.0) * delta, 0.0, 1.0)
	_scroll += delta * (120.0 if state == "" else 40.0)
	if state == "":
		step(delta, _steering())
	elif state == "won":
		elapsed += delta
		if elapsed >= DURATION + 2.0:
			set_process(false)
			finished.emit()
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_ship.position = Vector2(SHIP_X, ship_y + 30 + sin(_scroll * 0.05) * 4.0)
	_pilot.position = Vector2(SHIP_X - 20, ship_y - 4)
	_ship.visible = fmod(_hit_flash, 0.2) < 0.1
	_pilot.visible = _ship.visible
	_view.queue_redraw()


## One frame of the flight; `steer` is -1 (up) to 1 (down). Separate from input so tests can drive it.
func step(delta: float, steer: float) -> void:
	elapsed += delta
	ship_y = clampf(ship_y + steer * SHIP_SPEED * delta, 90.0, SCREEN.y - 70.0)
	_spawn_in -= delta
	if _spawn_in <= 0.0 and elapsed < DURATION - 2.0:
		_spawn()
	var ship := Rect2(Vector2(SHIP_X, ship_y) - SHIP_HITBOX / 2, SHIP_HITBOX)
	for object in objects.duplicate():
		object["pos"].x -= object["speed"] * delta
		if object["kind"] == "bird":
			object["pos"].y += sin(elapsed * 4.0 + object["pos"].x * 0.01) * 40.0 * delta
		if ship.intersects(_object_rect(object)):
			objects.erase(object)
			if object["kind"] == "apple":
				apples += 1
			else:
				_hit()
		elif object["pos"].x < -120:
			objects.erase(object)
	if state == "" and elapsed >= DURATION:
		state = "won"
		objects.clear()
		Game.set_flag("lot_jablka", apples)


func _hit() -> void:
	lives -= 1
	_hit_flash = 1.0
	if lives <= 0:
		state = "lost"
		objects.clear()


func _spawn() -> void:
	var speed := lerpf(300.0, 520.0, elapsed / DURATION)
	var roll := _rng.randf()
	var kind := "apple" if roll < 0.35 else ("bird" if roll < 0.8 else "cloud")
	if kind == "cloud":
		speed *= 0.7
	objects.append({"kind": kind, "pos": Vector2(SCREEN.x + 100, _rng.randf_range(100.0, SCREEN.y - 90.0)), "speed": speed})
	_spawn_in = _rng.randf_range(0.45, 0.9) * lerpf(1.2, 0.7, elapsed / DURATION)


func _object_rect(object: Dictionary) -> Rect2:
	var size: Vector2 = {"apple": Vector2(30, 30), "bird": Vector2(50, 30), "cloud": Vector2(150, 80)}[object["kind"]]
	return Rect2(object["pos"] - size / 2, size)


func _steering() -> float:
	var steer := Input.get_axis("move_up", "move_down")
	if steer == 0.0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_y := _view.get_local_mouse_position().y
		steer = clampf((mouse_y - ship_y) / 60.0, -1.0, 1.0)
	return steer


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("cancel"):
		pause_requested.emit()
	elif state == "lost" and (event.is_action("interact") or event is InputEventMouseButton):
		_restart()
	else:
		return
	get_viewport().set_input_as_handled()


func _draw_view() -> void:
	var v := _view
	for i in 12:
		v.draw_rect(Rect2(0, i * 60, SCREEN.x, 61), SKY_TOP.lerp(SKY_BOTTOM, i / 11.0))
	# Distant hills and the forest below scroll at different speeds.
	for i in 8:
		var x := fposmod(i * 260.0 - _scroll * 0.3, SCREEN.x + 260.0) - 130.0
		v.draw_circle(Vector2(x, SCREEN.y + 60), 200, Color("9cc9a0"))
	for i in 14:
		var x := fposmod(i * 110.0 - _scroll, SCREEN.x + 110.0) - 55.0
		v.draw_colored_polygon(PackedVector2Array([Vector2(x - 40, SCREEN.y), Vector2(x, SCREEN.y - 90), Vector2(x + 40, SCREEN.y)]), Color("3f7f4a"))
	for object in objects:
		var at: Vector2 = object["pos"]
		match object["kind"]:
			"apple":
				v.draw_circle(at, 14, Color("d62828"))
				v.draw_line(at + Vector2(0, -12), at + Vector2(3, -20), Color("5a3a1e"), 3.0)
			"bird":
				var wing := sin(elapsed * 14.0 + at.y) * 10.0
				v.draw_polyline(PackedVector2Array([at + Vector2(-24, -6 + wing), at, at + Vector2(24, -6 + wing)]), Color("222222"), 4.0)
			"cloud":
				for puff in [Vector2(-45, 8), Vector2(0, -12), Vector2(45, 8), Vector2(0, 14)]:
					v.draw_circle(at + puff, 38, Color("5d6470"))
				v.draw_polyline(PackedVector2Array([at + Vector2(-5, 30), at + Vector2(8, 52), at + Vector2(-4, 56), at + Vector2(10, 80)]), Color("ffe066"), 4.0)
	_draw_hud(v)
	if _fade > 0.0:
		v.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, _fade))


func _draw_hud(v: Node2D) -> void:
	var font := ThemeDB.fallback_font
	for i in LIVES:
		v.draw_circle(Vector2(40 + i * 40, 40), 14, Color("d62828") if i < lives else Color(0, 0, 0, 0.25))
	v.draw_string(font, Vector2(170, 50), "Jabłka: %d" % apples, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("2b1d14"))
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	v.draw_rect(Rect2(440, 30, 400, 16), Color(0, 0, 0, 0.25))
	v.draw_rect(Rect2(440, 30, 400 * progress, 16), Color("e0a832"))
	v.draw_string(font, Vector2(860, 46), "Munina", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("2b1d14"))
	var message := ""
	if state == "" and elapsed < 4.0:
		message = "W/S, strzałki albo przytrzymana mysz: steruj.\nOmijaj ptaki i burzowe chmury, łap jabłka!"
	elif state == "lost":
		message = "Drakkar oberwał za mocno!\nE albo klik: lecimy jeszcze raz"
	elif state == "won":
		message = "Ląd na horyzoncie!"
	if message != "":
		v.draw_multiline_string(font, Vector2(0, 300), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 34, -1, Color("2b1d14"))
