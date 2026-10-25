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
	"                                     a          ###            a                                                           a   a                        ####              ",
	" P                       ##       V  #         ####          x     C       V        V                                    B   x   B          a      V   #####        D     ",
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
## How many times smaller the level is drawn in pixel mode; bigger gives chunkier pixels.
const PIXEL_SCALE := 2
## Ready-made tiles and background layers, one set per folder: level.json names the files and how
## the layers scroll. L switches between the sets that are there and plain shapes.
const LEVEL_ART_SETS := ["res://art/platformer/level_autor/", "res://art/platformer/level/"]
## Music (music.ogg, looped) and sound effects (<name>.ogg) for the level, each used when present.
const AUDIO_DIR := "res://art/platformer/audio/"
## Drawn pictures for things in the level (<name>.png), each used when present.
const ITEMS_DIR := "res://art/platformer/items/"
const ITEMS := ["apple", "crate", "block", "block_used", "thorns", "flag", "flag_on", "drakkar"]
const SOUNDS := ["jump", "apple", "bump", "stomp", "hurt", "checkpoint", "win", "lose"]
## How far the camera looks ahead in the running direction.
const LOOK_AHEAD := 140.0
const LEAVES := 26
const POLLEN := 40

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
var _wieslaw: CutoutCharacter
var _camera: Camera2D
var _hud: Node2D
var _background: Node2D
## The art set in use: {"scale", "tiles": {name: Texture2D}, "background": [{texture, mirrored, speed, follow, top, bottom, gap}]}.
var _art := {}
var _art_sets: Array[Dictionary] = []
var _art_index := 0
var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _back: CanvasLayer
## The level is drawn into its own viewport, so it can be drawn at half resolution (pixel mode).
var _world: SubViewport
var _view: SubViewportContainer
## Pixel mode: the level is drawn PIXEL_SCALE times smaller (640 x 360) and enlarged without smoothing,
## so even turning parts of the puppet snap to a pixel grid. P switches it, to compare with the smooth look.
var pixel_mode := false
var _drakkar: Node2D
var _items := {}
var _coyote := 0.0
var _buffered := 0.0
var _jump_was_held := false
var _hurt := 0.0
var _end_time := 0.0
var _anim := 0.0
## Short-lived pictures: apples popping out of blocks, knocked-out Vikings.
var _effects: Array[Dictionary] = []
## Depth effects: foreground, haze, leaves and pollen, shadows, light, camera, dust (G turns them off).
var depth_effects := true
var _front: CanvasLayer
var _foreground: Node2D
var _overlay: Node2D
var _vignette: Texture2D
var _particles: Array[Dictionary] = []
var _last_camera := Vector2.ZERO
var _stretch := Vector2.ONE
var _fall_speed := 0.0
var _was_on_floor := true
var _shake := 0.0
var _look := 0.0


func _ready() -> void:
	_view = SubViewportContainer.new()
	_view.stretch = true
	_view.size = SCREEN
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_view)
	_world = SubViewport.new()
	_view.add_child(_world)
	_back = CanvasLayer.new()
	_back.layer = -1
	_world.add_child(_back)
	_background = Node2D.new()
	_back.add_child(_background)
	_background.draw.connect(_draw_background)
	_front = CanvasLayer.new()
	_front.layer = 1
	_world.add_child(_front)
	_foreground = Node2D.new()
	_foreground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_front.add_child(_foreground)
	_foreground.draw.connect(_draw_foreground)
	_load_art()
	_make_particles()
	_load_audio()
	for item in ITEMS:
		if ResourceLoader.exists(ITEMS_DIR + item + ".png"):
			_items[item] = load(ITEMS_DIR + item + ".png")
	var light := CanvasLayer.new()
	light.layer = 1
	add_child(light)
	_overlay = Node2D.new()
	light.add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	_vignette = _make_vignette()
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
		_world.remove_child(_level)
		_level.queue_free()
	lives = LIVES
	apples = 0
	state = ""
	_hurt = 0.0
	_end_time = 0.0
	_effects.clear()
	_stretch = Vector2.ONE
	_shake = 0.0
	_look = 0.0
	vikings.clear()
	map.assign(LEVEL)
	_level = Node2D.new()
	_world.add_child(_level)
	_tiles = Node2D.new()
	_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
					_add_drakkar(at)
	_add_player()
	if _music and not _music.playing:
		_music.play()
	set_physics_process(true)


func _add_drakkar(at: Vector2) -> void:
	if _items.has("drakkar"):
		var sprite := Sprite2D.new()
		sprite.texture = _items["drakkar"]
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(1.5, 1.5)
		sprite.position = at + Vector2(60, 12) - Vector2(sprite.texture.get_width() / 2.0, sprite.texture.get_height()) * sprite.scale
		_drakkar = sprite
	else:
		var hotspot := Hotspot.new()
		hotspot.art = "drakkar"
		hotspot.size = Vector2(320, 230)
		hotspot.position = at + Vector2(60, 0)
		_drakkar = hotspot
	_level.add_child(_drakkar)


func _add_player() -> void:
	player = CharacterBody2D.new()
	player.position = checkpoint
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = PLAYER_SIZE
	shape.position = Vector2(0, -PLAYER_SIZE.y / 2)
	player.add_child(shape)
	_wieslaw = CutoutCharacter.new()
	_wieslaw.scale = Vector2(0.84, 0.84)
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
	set_pixel_mode(pixel_mode)


func set_pixel_mode(on: bool) -> void:
	pixel_mode = on
	_view.stretch_shrink = PIXEL_SCALE if on else 1
	_world.snap_2d_transforms_to_pixel = on
	_world.snap_2d_vertices_to_pixel = on
	_back.scale = Vector2.ONE / _view.stretch_shrink
	_front.scale = _back.scale
	if _wieslaw:
		_wieslaw.pixel_art = on
	if _camera:
		_camera.zoom = Vector2.ONE / _view.stretch_shrink
		_camera.reset_smoothing()


func _add_viking(at: Vector2) -> void:
	var color := Color("4f7a3a") if vikings.size() % 2 == 0 else Color("d9692b")
	var body: Node2D
	# With drawn frames for Wiesław, Vikings are Wiesław in another colour until they get their own.
	if CutoutCharacter.has_frames():
		var drawn := CutoutCharacter.new()
		drawn.robe_color = color
		drawn.pose = "run"
		drawn.scale = Vector2(0.66, 0.66)
		body = drawn
	else:
		var placeholder := Character.new()
		placeholder.braids = true
		placeholder.body_color = color
		placeholder.scale = Vector2(0.6, 0.6)
		placeholder.running = true
		body = placeholder
	body.position = at
	body.set("facing", -1)
	_level.add_child(body)
	vikings.append({"node": body, "dir": -1.0, "color": color})


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
		_wieslaw.pose = "win"
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
		_play("jump")
		_stretch = Vector2(0.8, 1.2)
		_dust(player.position, 3)
		_buffered = 0.0
		_coyote = 0.0
	if not jump_held and v.y < 0.0:
		v.y = maxf(v.y, -JUMP_SPEED * JUMP_CUT)
	player.velocity = v
	_fall_speed = maxf(v.y, 0.0)
	player.move_and_slide()
	var on_floor := player.is_on_floor()
	if on_floor and not _was_on_floor and _fall_speed > 500.0:
		var hard := clampf((_fall_speed - 500.0) / 900.0, 0.0, 1.0)
		_stretch = Vector2(1.0 + 0.25 * hard + 0.08, 1.0 - 0.3 * hard - 0.08)
		_dust(player.position, 4 + roundi(hard * 4))
	elif on_floor and absf(v.x) > WALK_SPEED * 0.9 and absf(steer) > 0.1 and signf(steer) != signf(v.x):
		_dust(player.position, 1)
	_was_on_floor = on_floor
	if player.is_on_ceiling():
		_bump_block(player.position + Vector2(0, -PLAYER_SIZE.y - 4))
		_play("bump")
	if absf(steer) > 0.1:
		_wieslaw.facing = 1 if steer > 0 else -1
	if _hurt > HURT_TIME - 0.4:
		_wieslaw.pose = "hurt"
	elif not player.is_on_floor():
		_wieslaw.pose = "jump" if player.velocity.y < 0.0 else "fall"
	else:
		_wieslaw.pose = "run" if absf(player.velocity.x) > 20.0 else "idle"
	_stretch = _stretch.lerp(Vector2.ONE, minf(delta * 12.0, 1.0)) if depth_effects else Vector2.ONE
	_wieslaw.scale = Vector2(0.84 * _stretch.x * _wieslaw.facing, 0.84 * _stretch.y)
	_move_camera(delta)
	# Blinks after the hurt pose, while he cannot be hit again.
	_wieslaw.visible = _hurt > HURT_TIME - 0.4 or fmod(_hurt, 0.2) < 0.12
	if player.position.y > map.size() * TILE + 120:
		_hit(true)


func _bump_block(point: Vector2) -> void:
	if tile_at(point) != "?":
		return
	_set_tile(point, "X")
	apples += 1
	_play("apple")
	var center := Vector2((floori(point.x / TILE) + 0.5) * TILE, floori(point.y / TILE) * TILE)
	_effects.append({"kind": "apple", "pos": center, "time": 0.0})


## Vikings walk back and forth and turn at walls and ledges.
func _move_vikings(delta: float) -> void:
	for viking in vikings:
		var node: Node2D = viking["node"]
		var ahead: Vector2 = node.position + Vector2(viking["dir"] * 26.0, 0)
		var wall := tile_at(ahead + Vector2(0, -10)) in SOLID
		var floor_tile := tile_at(ahead + Vector2(0, 10))
		if wall or not (floor_tile in SOLID or floor_tile == "="):
			viking["dir"] *= -1.0
		node.position.x += viking["dir"] * VIKING_SPEED * delta
		node.set("facing", int(viking["dir"]))


func _check_touches() -> void:
	var me := Rect2(player.position - Vector2(PLAYER_SIZE.x / 2, PLAYER_SIZE.y), PLAYER_SIZE)
	for corner in [me.position, me.position + Vector2(me.size.x, 0), me.position + me.size / 2, me.end - Vector2(me.size.x, 0), me.end - Vector2(0, 1)]:
		match tile_at(corner):
			"a":
				_set_tile(corner, " ")
				apples += 1
				_play("apple")
			"x":
				_hit(false)
			"C":
				checkpoint = Vector2((floori(corner.x / TILE) + 0.5) * TILE, (floori(corner.y / TILE) + 1) * TILE)
				_play("checkpoint")
				_set_tile(corner, "c")
			"D":
				state = "won"
				_stop_music()
				_play("win")
				Game.set_flag("jablka_proba", apples)
				return
	for viking in vikings.duplicate():
		var node: Node2D = viking["node"]
		var them := Rect2(node.position - Vector2(24, 80), Vector2(48, 80))
		if not me.intersects(them):
			continue
		# Coming down onto the head knocks the Viking out; anything else hurts.
		if player.velocity.y > 0.0 and me.end.y < them.position.y + 34:
			vikings.erase(viking)
			_effects.append({"kind": "viking", "pos": node.position, "time": 0.0})
			_squash(node)
			_shake = maxf(_shake, 0.12)
			_dust(node.position, 4)
			player.velocity.y = -STOMP_BOUNCE
			_play("stomp")
		else:
			_hit(false)


## A knocked-out Viking falls over backwards (or, as a placeholder, is flattened), then fades away.
func _squash(node: Node2D) -> void:
	node.set("running", false)
	var tween := node.create_tween()
	if node is CutoutCharacter:
		node.pose = "death"
		tween.tween_interval(1.0)
	else:
		node.set("pose", "hurt")
		tween.tween_property(node, "scale:y", node.scale.y * 0.3, 0.08)
		tween.tween_interval(0.25)
	tween.tween_property(node, "modulate:a", 0.0, 0.3)
	tween.tween_callback(node.queue_free)


func _hit(fell: bool) -> void:
	if _hurt > 0.0 and not fell:
		return
	lives -= 1
	_hurt = HURT_TIME
	_shake = 0.35
	if lives <= 0:
		state = "lost"
		_wieslaw.pose = "death"
		_wieslaw.visible = true
		_stop_music()
		_play("lose")
		return
	_play("hurt")
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
	elif event is InputEventKey and event.physical_keycode == KEY_P:
		set_pixel_mode(not pixel_mode)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_L:
		next_art_set()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_G:
		set_depth_effects(not depth_effects)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_M:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
		_hud.queue_redraw()
		get_viewport().set_input_as_handled()
	elif state == "lost" and (event.is_action("interact") or event is InputEventMouseButton):
		restart()
		get_viewport().set_input_as_handled()


func _redraw() -> void:
	_tiles.queue_redraw()
	_hud.queue_redraw()
	_background.queue_redraw()
	_foreground.queue_redraw()
	_overlay.queue_redraw()


func _visible_columns() -> Vector2i:
	var left := _camera.get_screen_center_position().x - SCREEN.x / 2 if _camera else 0.0
	return Vector2i(maxi(floori(left / TILE) - 1, 0), floori((left + SCREEN.x) / TILE) + 2)


func _load_audio() -> void:
	for sound in SOUNDS:
		if ResourceLoader.exists(AUDIO_DIR + sound + ".ogg"):
			_sounds[sound] = load(AUDIO_DIR + sound + ".ogg")
	# A few players, so sounds close together do not cut each other off.
	for i in 4:
		var player_node := AudioStreamPlayer.new()
		player_node.volume_db = -4.0
		add_child(player_node)
		_players.append(player_node)
	if ResourceLoader.exists(AUDIO_DIR + "music.ogg"):
		var stream: AudioStreamOggVorbis = load(AUDIO_DIR + "music.ogg")
		stream.loop = true
		_music = AudioStreamPlayer.new()
		_music.stream = stream
		_music.volume_db = -10.0
		add_child(_music)


func _play(sound: String) -> void:
	if not _sounds.has(sound):
		return
	for player_node in _players:
		if not player_node.playing:
			player_node.stream = _sounds[sound]
			player_node.play()
			return
	_players[0].stream = _sounds[sound]
	_players[0].play()


func _stop_music() -> void:
	if _music:
		_music.stop()


func _load_art() -> void:
	for dir in LEVEL_ART_SETS:
		if FileAccess.file_exists(dir + "level.json"):
			_art_sets.append(_load_art_set(dir))
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _art_sets.is_empty():
		_art = _art_sets[0]


func _load_art_set(dir: String) -> Dictionary:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "level.json"))
	var tiles := {}
	for tile_name in spec["tiles"]:
		tiles[tile_name] = load(dir + spec["tiles"][tile_name])
	var layers := []
	for layer in spec["background"]:
		var texture: Texture2D = load(dir + layer["file"])
		var mirrored: Texture2D = null
		if layer.get("mirror", false):
			var image := texture.get_image()
			image.flip_x()
			mirrored = ImageTexture.create_from_image(image)
		layers.append({"texture": texture, "mirrored": mirrored, "speed": layer.get("speed", 0.0), "top": layer.get("top", -1.0),
			"bottom": layer.get("bottom", SCREEN.y), "gap": layer.get("gap", 0.0),
			"follow": layer.get("follow", layer.get("speed", 0.0)), "haze": layer.get("haze", 0.0),
			"fill": texture.get_image().get_pixel(0, 0)})
	var front := []
	for layer in spec.get("foreground", []):
		front.append({"texture": load(dir + layer["file"]), "mirrored": null, "speed": layer.get("speed", 1.4), "top": -1.0,
			"bottom": layer.get("bottom", SCREEN.y + 60), "gap": layer.get("gap", 0.0), "follow": layer.get("follow", 1.3), "haze": 0.0,
			"scale": layer.get("scale", 1.0)})
	return {"scale": spec.get("scale", 1.0), "tiles": tiles, "background": layers, "foreground": front,
		"haze_color": Color(spec.get("haze_color", "c9dde6"))}


## Next art set. Without any art the level is drawn with plain shapes.
func next_art_set() -> void:
	if _art_sets.is_empty():
		return
	_art_index = (_art_index + 1) % _art_sets.size()
	_art = _art_sets[_art_index]
	_redraw()


func set_depth_effects(on: bool) -> void:
	depth_effects = on
	_shake = 0.0
	if _camera:
		_camera.offset = Vector2(0, -80)
	_redraw()


## A tile wider than TILE is a strip: each cell shows the part of it under the cell, so the
## pattern runs on without seams.
func _draw_tile(tile_name: String, at: Vector2) -> void:
	var texture: Texture2D = _art["tiles"][tile_name]
	var size := texture.get_size()
	var x := fposmod(at.x, size.x) if size.x > TILE else 0.0
	_tiles.draw_texture_rect_region(texture, Rect2(at, Vector2(minf(TILE, size.x), size.y)), Rect2(x, 0, minf(TILE, size.x), size.y))


## Each layer repeats sideways and moves at its own share of the camera's speed; the first one also
## fills the sky above it with its top colour. When the camera goes up, a layer goes down by its
## "follow" share of that, so the nearest trees stay standing on the ground.
## With depth effects, "haze" lays a veil of the haze colour over a layer and all behind it, so far
## things fade into the air.
func _draw_art_background(scroll: float) -> void:
	_draw_layers(_background, _art["background"], scroll, true)


func _camera_rise() -> float:
	if not _camera:
		return 0.0
	return map.size() * TILE - SCREEN.y / 2 - _camera.get_screen_center_position().y


func _draw_layers(v: Node2D, layers: Array, scroll: float, fill_sky: bool) -> void:
	var rise := _camera_rise()
	for i in layers.size():
		var layer: Dictionary = layers[i]
		var texture: Texture2D = layer["texture"]
		var size: Vector2 = texture.get_size() * layer.get("scale", _art["scale"])
		var y: float = (layer["top"] if layer["top"] >= 0.0 else layer["bottom"] - size.y) + rise * layer["follow"]
		if i == 0 and fill_sky:
			v.draw_rect(Rect2(0, 0, SCREEN.x, y + 1), layer["fill"])
		var step: float = size.x + layer["gap"]
		var offset: float = scroll * layer["speed"]
		var x := -fposmod(offset, step)
		var index := floori(offset / step)
		while x < SCREEN.x:
			# Mirrored every other time, so a picture that does not repeat still joins up.
			var flipped: bool = layer["mirrored"] != null and index % 2 != 0
			v.draw_texture_rect(layer["mirrored"] if flipped else texture, Rect2(Vector2(x, y), size), false)
			x += step
			index += 1
		if depth_effects and layer["haze"] > 0.0:
			v.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(_art["haze_color"], layer["haze"]))


func _draw_background() -> void:
	var v := _background
	var scroll := _camera.get_screen_center_position().x if _camera else 0.0
	if not _art.is_empty():
		_draw_art_background(scroll)
		return
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
					var top := row == 0 or map[row - 1][col] != "#"
					if not _art.is_empty():
						var under_top := row > 0 and map[row - 1][col] == "#" and (row < 2 or map[row - 2][col] != "#")
						var fill := "ground" if under_top or not _art["tiles"].has("ground_deep") else "ground_deep"
						_draw_tile("ground_top" if top else fill, at)
						continue
					v.draw_rect(cell, Color("8b5a2b"))
					if top:
						v.draw_rect(Rect2(at, Vector2(TILE, 16)), Color("5e9e3f"))
				"B" when _items.has("crate"):
					v.draw_texture(_items["crate"], at)
				"?" when _items.has("block"):
					v.draw_texture(_items["block"], at + Vector2(0, sin(_anim * 4.0) * 2.0))
				"X" when _items.has("block_used"):
					v.draw_texture(_items["block_used"], at)
				"a" when _items.has("apple"):
					var texture: Texture2D = _items["apple"]
					v.draw_texture(texture, at + (Vector2(TILE, TILE) - texture.get_size()) / 2 + Vector2(0, sin(_anim * 3.0 + col) * 4.0))
				"x" when _items.has("thorns"):
					v.draw_texture(_items["thorns"], at + Vector2(0, TILE - _items["thorns"].get_height()))
				"C", "c" when _items.has("flag"):
					var texture: Texture2D = _items["flag_on" if map[row][col] == "c" else "flag"]
					v.draw_texture(texture, at + Vector2(8, TILE - texture.get_height()))
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
					if not _art.is_empty():
						_draw_tile("plank", at)
						continue
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
	if depth_effects:
		_draw_shadows()
	for effect in _effects:
		match effect["kind"]:
			"apple":
				var rise: Vector2 = effect["pos"] + Vector2(0, -effect["time"] * 160.0)
				if _items.has("apple"):
					var texture: Texture2D = _items["apple"]
					v.draw_texture(texture, rise - texture.get_size() / 2, Color(1, 1, 1, 1.0 - effect["time"] * 2.0))
				else:
					v.draw_circle(rise, 14, Color(Color("d62828"), 1.0 - effect["time"] * 2.0))
			"viking":
				var flat: Vector2 = effect["pos"]
				v.draw_string(ThemeDB.fallback_font, flat + Vector2(-30, -24), "BĘC!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
			"dust":
				var t: float = effect["time"] / 0.5
				var puff: Vector2 = effect["pos"] + effect["vel"] * effect["time"] + Vector2(0, -t * 10.0)
				v.draw_circle(puff, lerpf(5.0, 14.0, t), Color(0.93, 0.88, 0.78, 0.55 * (1.0 - t)))


func _process(delta: float) -> void:
	for effect in _effects.duplicate():
		effect["time"] += delta
		if effect["time"] > 0.5:
			_effects.erase(effect)
	_move_particles(delta)


## A soft round shadow on the ground under a character; smaller and fainter the higher it is.
func _draw_shadows() -> void:
	var feet: Array[Vector2] = []
	if player:
		feet.append(player.position)
	for viking in vikings:
		feet.append(viking["node"].position)
	for foot in feet:
		var ground := foot.y
		while ground < foot.y + 6 * TILE and not (tile_at(Vector2(foot.x, ground + 2)) in SOLID or tile_at(Vector2(foot.x, ground + 2)) == "="):
			ground = (floori(ground / TILE) + 1) * TILE
		if ground >= foot.y + 6 * TILE:
			continue
		var near := 1.0 - clampf((ground - foot.y) / (4.0 * TILE), 0.0, 1.0)
		var size := Vector2(30, 7) * lerpf(0.5, 1.0, near)
		for k in 3:
			var grow := 1.0 + k * 0.35
			_tiles.draw_set_transform(Vector2(foot.x, ground - 2), 0.0, Vector2(size.x * grow, size.y * grow) / 10.0)
			_tiles.draw_circle(Vector2.ZERO, 10.0, Color(0.08, 0.06, 0.04, 0.16 * near))
		_tiles.draw_set_transform(Vector2.ZERO)


func _dust(at: Vector2, count: int) -> void:
	if not depth_effects:
		return
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		_effects.append({"kind": "dust", "pos": at + Vector2(side * randf_range(6, 18), -4),
			"vel": Vector2(side * randf_range(40, 110), randf_range(-30, -5)), "time": randf_range(0.0, 0.1)})


## The camera looks ahead where Wiesław runs and shakes for a moment when he is hit.
func _move_camera(delta: float) -> void:
	if not depth_effects or not _camera:
		return
	if absf(player.velocity.x) > 40.0:
		_look = move_toward(_look, signf(player.velocity.x) * LOOK_AHEAD, delta * 260.0)
	_shake = maxf(_shake - delta, 0.0)
	var jolt := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 14.0 * _shake / 0.35 if _shake > 0.0 else Vector2.ZERO
	_camera.offset = Vector2(_look, -80) + jolt


## Leaves and pollen drift through the air in front of and behind the level, at different depths.
func _make_particles() -> void:
	_particles.clear()
	for i in LEAVES + POLLEN:
		var leaf := i < LEAVES
		_particles.append({"leaf": leaf, "pos": Vector2(randf() * SCREEN.x, randf() * SCREEN.y),
			"depth": randf_range(0.5, 1.4), "phase": randf() * TAU,
			"color": [Color("c98a2b"), Color("a7b23a"), Color("d9a441"), Color("8e9a2e")][i % 4] if leaf else Color(1.0, 0.96, 0.7)})


func _move_particles(delta: float) -> void:
	if not depth_effects:
		return
	var center := _camera.get_screen_center_position() if _camera else Vector2.ZERO
	var moved := center - _last_camera if _last_camera != Vector2.ZERO else Vector2.ZERO
	_last_camera = center
	for p in _particles:
		var depth: float = p["depth"]
		p["phase"] += delta * (1.6 if p["leaf"] else 0.7)
		var drift := Vector2(-28.0 + sin(p["phase"]) * 30.0, 38.0) if p["leaf"] else Vector2(sin(p["phase"]) * 10.0, -6.0 + cos(p["phase"] * 1.3) * 8.0)
		p["pos"] += drift * depth * delta - moved * depth
		p["pos"] = Vector2(fposmod(p["pos"].x, SCREEN.x + 40.0), fposmod(p["pos"].y, SCREEN.y + 40.0))


func _draw_foreground() -> void:
	if not depth_effects:
		return
	var scroll := _camera.get_screen_center_position().x if _camera else 0.0
	if not _art.is_empty():
		_draw_layers(_foreground, _art["foreground"], scroll, false)
	for p in _particles:
		var at: Vector2 = p["pos"] - Vector2(20, 20)
		var depth: float = p["depth"]
		if p["leaf"]:
			var turn: float = p["phase"] * 1.3
			_foreground.draw_set_transform(at, turn, Vector2(1.0, absf(sin(turn)) * 0.8 + 0.2) * depth)
			_foreground.draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(0, -3), Vector2(6, 0), Vector2(0, 3)]), p["color"])
		else:
			var glow: float = 0.45 + 0.35 * sin(p["phase"] * 3.0)
			_foreground.draw_circle(at, 3.0 * depth, Color(p["color"], 0.18 * glow))
			_foreground.draw_circle(at, 1.2 * depth, Color(p["color"], 0.8 * glow))
	_foreground.draw_set_transform(Vector2.ZERO)


## Light over the whole picture: slow sunbeams from the top left and a darker edge.
func _draw_overlay() -> void:
	if not depth_effects:
		return
	var sway := sin(_anim * 0.3) * 30.0
	var beams := [[180.0, 90.0, 0.10], [360.0, 50.0, 0.07], [520.0, 120.0, 0.06], [760.0, 60.0, 0.05]]
	for beam in beams:
		var top := Vector2(beam[0] + sway, -20)
		var spread: float = beam[1]
		var bottom := top + Vector2(340, SCREEN.y + 40)
		var warm := Color(1.0, 0.93, 0.7, beam[2])
		var clear := Color(1.0, 0.93, 0.7, 0.0)
		_overlay.draw_polygon(PackedVector2Array([top, top + Vector2(spread, 0), bottom + Vector2(spread * 2.2, 0), bottom]),
			PackedColorArray([warm, warm, clear, clear]))
	_overlay.draw_texture_rect(_vignette, Rect2(Vector2.ZERO, SCREEN), false)


func _make_vignette() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.05, 0.04, 0.03, 0.0))
	gradient.set_color(1, Color(0.05, 0.04, 0.03, 0.55))
	gradient.add_point(0.55, Color(0.05, 0.04, 0.03, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	texture.width = 256
	texture.height = 144
	return texture


func _draw_hud() -> void:
	var v := _hud
	var font := ThemeDB.fallback_font
	var ink := Color("2b1d14")
	for i in LIVES:
		v.draw_circle(Vector2(40 + i * 40, 40), 14, Color("d62828") if i < lives else Color(0, 0, 0, 0.25))
	# A light outline keeps the text readable on a drawn background.
	var halo := Color(1, 1, 1, 0.85)
	v.draw_string_outline(font, Vector2(170, 50), "Jabłka: %d" % apples, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, halo)
	v.draw_string(font, Vector2(170, 50), "Jabłka: %d" % apples, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, ink)
	var mode := "P: tryb %s" % ("pikselowy" if pixel_mode else "gładki")
	mode = "G: efekty %s     %s" % ["wł." if depth_effects else "wył.", mode]
	if _art_sets.size() > 1:
		mode = "L: grafika     " + mode
	if _music or not _sounds.is_empty():
		mode = "M: dźwięk %s     %s" % ["wył." if AudioServer.is_bus_mute(0) else "wł.", mode]
	v.draw_string_outline(font, Vector2(0, 50), mode, HORIZONTAL_ALIGNMENT_RIGHT, SCREEN.x - 30, 24, 6, halo)
	v.draw_string(font, Vector2(0, 50), mode, HORIZONTAL_ALIGNMENT_RIGHT, SCREEN.x - 30, 24, ink)
	var message := ""
	if state == "" and player and player.position.x < 900.0:
		message = "A/D albo strzałki: chodzenie. Spacja albo W: skok (przytrzymaj, a skoczysz wyżej).\nSkacz Wikingom na głowy i rozbijaj skrzynki ze znakiem zapytania!"
	elif state == "lost":
		message = "Ojej, Wiesław stracił wszystkie serduszka!\nSpacja albo klik: jeszcze raz"
	elif state == "won":
		message = "Hop! Wiesław dogonił drakkar!"
	if message != "":
		v.draw_multiline_string_outline(font, Vector2(0, 110), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 26, -1, 6, halo)
		v.draw_multiline_string(font, Vector2(0, 110), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 26, -1, ink)
