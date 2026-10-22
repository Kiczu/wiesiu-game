class_name PlatformerGame
extends Node2D
## Platformer level in the spirit of Mario: Wiesław walks and jumps through the orchard after the
## Vikings' drakkar. Jump on Vikings to knock them out, bump ? blocks from below for apples,
## avoid thorns and pits. The level is drawn from the text map in LEVEL, so it is easy to edit.

signal finished
signal pause_requested

const TILE := 64
const SCREEN := Vector2(1280, 720)
## One character per tile:
## # ground   B crate   ? apple block (bump it from below)   = plank (jump through from below)
## a apple   x thorns   V Viking   C checkpoint   P start   D the drakkar (finish)
const LEVEL := [
	"                                                                                                                                                                          ",
	"                                                                                                                                                                          ",
	"                                                                                                                                                                          ",
	"                                                                                                        a a a                                                             ",
	"                                                     a  a  a                                                                                                              ",
	"         ?B?                     aaa                                      ?B?B?                        =====                        V                                     ",
	"                                                  #  ===  ===                                                                     ######    ?             ##              ",
	"    a a        a a              ===              ##                                   a a         ===          ===                                       ###              ",
	"                            V        a          ###            a                                                           a   a                        ####              ",
	" P                       ##          #         ####          x     C       V        V                                    B   x   B          a      V   #####        D     ",
	"#############################  ####################       ######################################                  ########################################################",
	"#############################  ####################       ######################################                  ########################################################",
]
const SOLID := "#B?X"
const LIVES := 3
const WALK_SPEED := 330.0
const ACCELERATION := 2400.0
const GRAVITY := 2400.0
const JUMP_SPEED := 1050.0
## Letting go of jump early cuts the jump short, so small hops are possible.
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const HURT_TIME := 1.5
const STOMP_BOUNCE := 650.0
const VIKING_SPEED := 70.0
const PLAYER_SIZE := Vector2(40, 92)

var lives := LIVES
var apples := 0
## "" while playing, then "won" or "lost".
var state := ""
## Tests set these instead of the keyboard.
var auto_input := false
var input_x := 0.0
var input_jump := false

var player: CharacterBody2D
var vikings: Array[Dictionary] = []
var map: Array[String] = []
var checkpoint := Vector2.ZERO

var _level: Node2D
var _tiles: Node2D
var _wieslaw: Character
var _camera: Camera2D
var _hud: Node2D
var _background: Node2D
var _drakkar: Hotspot
var _coyote := 0.0
var _buffered := 0.0
var _jump_was_held := false
var _hurt := 0.0
var _end_time := 0.0
var _anim := 0.0
## Short-lived pictures: apples popping out of blocks, knocked-out Vikings.
var _effects: Array[Dictionary] = []


func _ready() -> void:
	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	_background = Node2D.new()
	back.add_child(_background)
	_background.draw.connect(_draw_background)
	var front := CanvasLayer.new()
	front.layer = 2
	add_child(front)
	_hud = Node2D.new()
	front.add_child(_hud)
	_hud.draw.connect(_draw_hud)
	if Game.fast and not auto_input:
		state = "won"
		set_physics_process(false)
		finished.emit.call_deferred()
		return
	if get_parent() == get_tree().root:
		# Run on its own (F6 in the editor): play again after the finish.
		finished.connect(restart)
	restart()


func restart() -> void:
	if _level:
		remove_child(_level)
		_level.queue_free()
	lives = LIVES
	apples = 0
	state = ""
	_hurt = 0.0
	_end_time = 0.0
	_effects.clear()
	vikings.clear()
	map.assign(LEVEL)
	_level = Node2D.new()
	add_child(_level)
	_tiles = Node2D.new()
	_tiles.draw.connect(_draw_tiles)
	_level.add_child(_tiles)
	_build_collision()
	for row in map.size():
		for col in map[row].length():
			var at := Vector2((col + 0.5) * TILE, (row + 1) * TILE)
			match map[row][col]:
				"P":
					checkpoint = at
				"V":
					_add_viking(at)
				"D":
					_drakkar = Hotspot.new()
					_drakkar.art = "drakkar"
					_drakkar.size = Vector2(320, 230)
					_drakkar.position = at + Vector2(60, 0)
					_level.add_child(_drakkar)
	_add_player()
	set_physics_process(true)


func _add_player() -> void:
	player = CharacterBody2D.new()
	player.position = checkpoint
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = PLAYER_SIZE
	shape.position = Vector2(0, -PLAYER_SIZE.y / 2)
	player.add_child(shape)
	_wieslaw = Character.new()
	_wieslaw.helmet = true
	_wieslaw.body_color = Color("7b5ea7")
	_wieslaw.scale = Vector2(0.68, 0.68)
	player.add_child(_wieslaw)
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map[0].length() * TILE
	_camera.limit_bottom = map.size() * TILE
	_camera.position_smoothing_enabled = true
	_camera.offset = Vector2(0, -80)
	player.add_child(_camera)
	_level.add_child(player)
	_camera.make_current()


func _add_viking(at: Vector2) -> void:
	var body := Character.new()
	body.braids = true
	body.body_color = Color("4f7a3a") if vikings.size() % 2 == 0 else Color("d9692b")
	body.scale = Vector2(0.6, 0.6)
	body.position = at
	body.running = true
	body.facing = -1
	_level.add_child(body)
	vikings.append({"node": body, "dir": -1.0})


## Rows of solid tiles become one static box each; planks become one-way boxes.
func _build_collision() -> void:
	var body := StaticBody2D.new()
	_level.add_child(body)
	for row in map.size():
		var col := 0
		while col < map[row].length():
			var kind := map[row][col]
			var plank := kind == "="
			if not (plank or kind in SOLID):
				col += 1
				continue
			var start := col
			while col < map[row].length() and (map[row][col] == "=" if plank else map[row][col] in SOLID):
				col += 1
			var shape := CollisionShape2D.new()
			shape.shape = RectangleShape2D.new()
			var height := 16.0 if plank else float(TILE)
			shape.shape.size = Vector2((col - start) * TILE, height)
			shape.position = Vector2((start + col) * TILE / 2.0, row * TILE + height / 2)
			shape.one_way_collision = plank
			body.add_child(shape)


func tile_at(point: Vector2) -> String:
	var row := floori(point.y / TILE)
	var col := floori(point.x / TILE)
	if row < 0 or row >= map.size() or col < 0 or col >= map[row].length():
		return " "
	return map[row][col]


func _set_tile(point: Vector2, kind: String) -> void:
	var row := floori(point.y / TILE)
	var col := floori(point.x / TILE)
	map[row] = map[row].substr(0, col) + kind + map[row].substr(col + 1)
	_tiles.queue_redraw()


func _physics_process(delta: float) -> void:
	_anim += delta
	_hurt = maxf(_hurt - delta, 0.0)
	_buffered = maxf(_buffered - delta, 0.0)
	if state == "won":
		_end_time += delta
		_wieslaw.running = false
		if _end_time >= 2.0:
			set_physics_process(false)
			finished.emit()
		_redraw()
		return
	if state == "lost":
		_redraw()
		return
	var steer := input_x if auto_input else Input.get_axis("move_left", "move_right")
	var jump_held := input_jump if auto_input else (Input.is_action_pressed("move_up") or Input.is_action_pressed("interact"))
	if jump_held and not _jump_was_held:
		_buffered = JUMP_BUFFER
	_move_player(delta, steer, jump_held)
	_jump_was_held = jump_held
	_move_vikings(delta)
	_check_touches()
	_redraw()


func _move_player(delta: float, steer: float, jump_held: bool) -> void:
	var v := player.velocity
	v.x = move_toward(v.x, steer * WALK_SPEED, ACCELERATION * delta)
	v.y += GRAVITY * delta
	_coyote = COYOTE_TIME if player.is_on_floor() else maxf(_coyote - delta, 0.0)
	if _buffered > 0.0 and _coyote > 0.0:
		v.y = -JUMP_SPEED
		_buffered = 0.0
		_coyote = 0.0
	if not jump_held and v.y < 0.0:
		v.y = maxf(v.y, -JUMP_SPEED * JUMP_CUT)
	player.velocity = v
	player.move_and_slide()
	if player.is_on_ceiling():
		_bump_block(player.position + Vector2(0, -PLAYER_SIZE.y - 4))
	if absf(steer) > 0.1:
		_wieslaw.facing = 1 if steer > 0 else -1
	_wieslaw.running = player.is_on_floor() and absf(player.velocity.x) > 20.0
	_wieslaw.visible = fmod(_hurt, 0.2) < 0.12
	if player.position.y > map.size() * TILE + 120:
		_hit(true)


func _bump_block(point: Vector2) -> void:
	if tile_at(point) != "?":
		return
	_set_tile(point, "X")
	apples += 1
	var center := Vector2((floori(point.x / TILE) + 0.5) * TILE, floori(point.y / TILE) * TILE)
	_effects.append({"kind": "apple", "pos": center, "time": 0.0})


## Vikings walk back and forth and turn at walls and ledges.
func _move_vikings(delta: float) -> void:
	for viking in vikings:
		var node: Character = viking["node"]
		var ahead: Vector2 = node.position + Vector2(viking["dir"] * 26.0, 0)
		var wall := tile_at(ahead + Vector2(0, -10)) in SOLID
		var floor_tile := tile_at(ahead + Vector2(0, 10))
		if wall or not (floor_tile in SOLID or floor_tile == "="):
			viking["dir"] *= -1.0
		node.position.x += viking["dir"] * VIKING_SPEED * delta
		node.facing = int(viking["dir"])


func _check_touches() -> void:
	var me := Rect2(player.position - Vector2(PLAYER_SIZE.x / 2, PLAYER_SIZE.y), PLAYER_SIZE)
	for corner in [me.position, me.position + Vector2(me.size.x, 0), me.position + me.size / 2, me.end - Vector2(me.size.x, 0), me.end - Vector2(0, 1)]:
		match tile_at(corner):
			"a":
				_set_tile(corner, " ")
				apples += 1
			"x":
				_hit(false)
			"C":
				checkpoint = Vector2((floori(corner.x / TILE) + 0.5) * TILE, (floori(corner.y / TILE) + 1) * TILE)
				_set_tile(corner, "c")
			"D":
				state = "won"
				Game.set_flag("jablka_proba", apples)
				return
	for viking in vikings.duplicate():
		var node: Character = viking["node"]
		var them := Rect2(node.position - Vector2(24, 80), Vector2(48, 80))
		if not me.intersects(them):
			continue
		# Coming down onto the head knocks the Viking out; anything else hurts.
		if player.velocity.y > 0.0 and me.end.y < them.position.y + 34:
			vikings.erase(viking)
			_effects.append({"kind": "viking", "pos": node.position, "time": 0.0, "color": node.body_color})
			node.queue_free()
			player.velocity.y = -STOMP_BOUNCE
		else:
			_hit(false)


func _hit(fell: bool) -> void:
	if _hurt > 0.0 and not fell:
		return
	lives -= 1
	_hurt = HURT_TIME
	if lives <= 0:
		state = "lost"
		return
	if fell:
		player.position = checkpoint
		player.velocity = Vector2.ZERO
	else:
		player.velocity = Vector2(-_wieslaw.facing * 300.0, -450.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("cancel"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
	elif state == "lost" and (event.is_action("interact") or event is InputEventMouseButton):
		restart()
		get_viewport().set_input_as_handled()


func _redraw() -> void:
	_tiles.queue_redraw()
	_hud.queue_redraw()
	_background.queue_redraw()


func _visible_columns() -> Vector2i:
	var left := _camera.get_screen_center_position().x - SCREEN.x / 2 if _camera else 0.0
	return Vector2i(maxi(floori(left / TILE) - 1, 0), floori((left + SCREEN.x) / TILE) + 2)


func _draw_background() -> void:
	var v := _background
	var scroll := _camera.get_screen_center_position().x if _camera else 0.0
	for i in 12:
		v.draw_rect(Rect2(0, i * 60, SCREEN.x, 61), Color("8ccbe8").lerp(Color("e8f4fa"), i / 11.0))
	for i in 7:
		var x := fposmod(i * 300.0 - scroll * 0.15, SCREEN.x + 300.0) - 150.0
		v.draw_circle(Vector2(x, 700), 300, Color("b5d9a6"))
	for i in 9:
		var x := fposmod(i * 170.0 - scroll * 0.4, SCREEN.x + 170.0) - 85.0
		v.draw_rect(Rect2(x - 10, 470, 20, 200), Color("a89a86"))
		v.draw_circle(Vector2(x, 450), 60, Color("9cc58d"))


func _draw_tiles() -> void:
	var v := _tiles
	var ink := Color("2b1d14")
	var span := _visible_columns()
	# Pits: a dark hole where the bottom row has no ground.
	var bottom := map.size() - 1
	for col in range(span.x, mini(span.y, map[bottom].length())):
		if map[bottom][col] != "#":
			v.draw_rect(Rect2(col * TILE, (bottom - 1) * TILE + 16, TILE, 3 * TILE), Color("3b2a1f"))
	for row in map.size():
		for col in range(span.x, mini(span.y, map[row].length())):
			var at := Vector2(col * TILE, row * TILE)
			var cell := Rect2(at, Vector2(TILE, TILE))
			match map[row][col]:
				"#":
					v.draw_rect(cell, Color("8b5a2b"))
					if row == 0 or map[row - 1][col] != "#":
						v.draw_rect(Rect2(at, Vector2(TILE, 16)), Color("5e9e3f"))
				"B":
					v.draw_rect(cell, Color("c08a4a"))
					v.draw_rect(cell.grow(-3), ink, false, 3.0)
					v.draw_line(at + Vector2(6, 6), at + Vector2(58, 58), ink, 3.0)
				"?":
					var bob := sin(_anim * 4.0) * 2.0
					v.draw_rect(cell, Color("f2c14e"))
					v.draw_rect(cell.grow(-3), ink, false, 3.0)
					v.draw_string(ThemeDB.fallback_font, at + Vector2(0, 46 + bob), "?", HORIZONTAL_ALIGNMENT_CENTER, TILE, 40, ink)
				"X":
					v.draw_rect(cell, Color("a08060"))
					v.draw_rect(cell.grow(-3), ink, false, 3.0)
				"=":
					v.draw_rect(Rect2(at, Vector2(TILE, 16)), Color("a0522d"))
					v.draw_line(at + Vector2(0, 16), at + Vector2(TILE, 16), ink, 2.0)
				"a":
					var center := at + Vector2(32, 34 + sin(_anim * 3.0 + col) * 4.0)
					v.draw_circle(center, 15, Color("d62828"))
					v.draw_line(center + Vector2(0, -13), center + Vector2(3, -21), Color("5a3a1e"), 3.0)
				"x":
					for i in 4:
						var base := at + Vector2(8 + i * 16, TILE)
						v.draw_colored_polygon(PackedVector2Array([base + Vector2(-9, 0), base + Vector2(0, -34), base + Vector2(9, 0)]), Color("3f6b2f"))
						v.draw_line(base + Vector2(0, -34), base + Vector2(0, -40), ink, 2.0)
				"C", "c":
					var pole := at + Vector2(20, TILE)
					v.draw_line(pole, pole + Vector2(0, -90), ink, 4.0)
					var flag := Color("e0a832") if map[row][col] == "c" else Color("9aa3ab")
					v.draw_colored_polygon(PackedVector2Array([pole + Vector2(0, -90), pole + Vector2(36, -78), pole + Vector2(0, -66)]), flag)
	for effect in _effects:
		match effect["kind"]:
			"apple":
				v.draw_circle(effect["pos"] + Vector2(0, -effect["time"] * 160.0), 14, Color(Color("d62828"), 1.0 - effect["time"] * 2.0))
			"viking":
				var flat: Vector2 = effect["pos"]
				v.draw_rect(Rect2(flat + Vector2(-26, -14), Vector2(52, 14)), effect["color"])
				v.draw_string(ThemeDB.fallback_font, flat + Vector2(-30, -24), "BĘC!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)


func _process(delta: float) -> void:
	for effect in _effects.duplicate():
		effect["time"] += delta
		if effect["time"] > 0.5:
			_effects.erase(effect)


func _draw_hud() -> void:
	var v := _hud
	var font := ThemeDB.fallback_font
	var ink := Color("2b1d14")
	for i in LIVES:
		v.draw_circle(Vector2(40 + i * 40, 40), 14, Color("d62828") if i < lives else Color(0, 0, 0, 0.25))
	v.draw_string(font, Vector2(170, 50), "Jabłka: %d" % apples, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, ink)
	var message := ""
	if state == "" and player and player.position.x < 900.0:
		message = "A/D albo strzałki: chodzenie. Spacja albo W: skok (przytrzymaj, a skoczysz wyżej).\nSkacz Wikingom na głowy i rozbijaj skrzynki ze znakiem zapytania!"
	elif state == "lost":
		message = "Ojej, Wiesław stracił wszystkie serduszka!\nSpacja albo klik: jeszcze raz"
	elif state == "won":
		message = "Hop! Wiesław dogonił drakkar!"
	if message != "":
		v.draw_multiline_string(font, Vector2(0, 110), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 26, -1, ink)
