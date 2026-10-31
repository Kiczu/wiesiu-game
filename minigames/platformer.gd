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
## # ground   B crate   = plank (jump through from below)
## a apple   x thorns   V Viking   C checkpoint   P start   D the drakkar (finish)
## T treasure chest (open it with F)   S royal chest, two tiles wide (leave the tile on its right empty)
## H ladder (W and S climb it, A or D steps off)   M one of Wiesław's brothers, who sells things for apples (F)
## O the two Vikings with one eye (catch the eye to win; no drakkar needed)
## Crates break under the sword or a thrown apple and give apples.
const LEVEL := [
	"                                                                                                                                                                          ",
	"                                                                                                                                                                          ",
	"                                                                                                                                                                          ",
	"                                                                                                        a a a                                                             ",
	"                                                     a  a  a                                                                                                              ",
	"         BBB                     aaa                                      BBBBB                        =====                        V                                     ",
	"                                                  #  ===  ===                                                                     ######    B             ##              ",
	"    a a        a a              ===              ##                                   a a         ===          ===                                       ###              ",
	"                                     a          ###            a                                                           a   a                        ####              ",
	" P                       ##       V  #         ####          x     C       V        V                                    B   x   B          a      V   #####        D     ",
	"#############################  ####################       ######################################                  ########################################################",
	"#############################  ####################       ######################################                  ########################################################",
]
## A level in the style of Apple Knight: ground at many heights, walls to climb with the double
## jump, spike pits, crates to break with the sword, Vikings on ledges.
const LEVEL_KNIGHT := [
	"                                                                                                                                ",
	"                                                                                                                                ",
	"                                                                                                                                ",
	"                                                                 aaaS                                                           ",
	"                                                   a            ######             a                                            ",
	"                                      TaaaB       ===           ######            ===     V   B                                 ",
	"                  aa      a          ######   a                                       ##########                                ",
	"                     V B ===         ######  ===                              ===     ##########  a  a             B V          ",
	"      a a a      #######         B V ######                                           ##########  #  #           #####          ",
	"  P           ##########     ##############             C    VBB      V   ===         ##########  #  #      V  T #####   C  D   ",
	"########################xxxxx##############            ##################             ##########xx#xx#xxx#######################",
	"###########################################            ##################             ##########################################",
]
const SOLID := "#B"
## Apples inside a broken crate.
const CRATE_APPLES := 2
const NIGHT_TINT := Color(0.5, 0.56, 0.86)
## Apples in a treasure chest; it also gives back a lost heart.
const CHEST_APPLES := 5
## Apples in the royal chest; it also fills every heart.
const ROYAL_APPLES := 15
## What the brothers sell, for apples: a heart, and a mug of nalewka for the bag, which keeps
## Wiesław from harm for a while once he drinks it.
const HEART_PRICE := 25
const MUG_PRICE := 40
const MUG_TIME := 2.0
## How long he stands drinking from the mug, when that is drawn.
const DRINK_TIME := 0.6
const BROTHERS := ["Lesław", "Czesław"]
const LIVES := 3
const WALK_SPEED := 330.0
const ACCELERATION := 2400.0
const GRAVITY := 2400.0
const JUMP_SPEED := 1050.0
## Letting go of jump early cuts the jump short, so small hops are possible.
const JUMP_CUT := 0.45
## A second jump in the air, a little lower than the first.
const AIR_JUMPS := 1
const AIR_JUMP_SPEED := 900.0
## Pressing against a wall in the air he holds on and slides down slowly; jump pushes him off it,
## up and away, and gives the second jump back.
const WALL_SLIDE_SPEED := 160.0
const WALL_JUMP := Vector2(420.0, 980.0)
## After a wall jump the keys do not steer for a moment, so he gets away from the wall.
const WALL_LOCK := 0.18
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const HURT_TIME := 1.5
const VIKING_SPEED := 70.0
const PLAYER_SIZE := Vector2(40, 92)
## Ready-made tiles and background layers, one set per folder: level.json names the files and how
## the layers scroll. L switches between the sets that are there; without any the level is drawn
## with plain shapes.
const LEVEL_ART_SETS := ["res://art/platformer/level_kreskowka/", "res://art/platformer/level_piksele/"]
## Music (music.ogg, looped) and sound effects (<name>.ogg) for the level, each used when present.
const AUDIO_DIR := "res://art/platformer/audio/"
## Drawn pictures for things in the level (<name>.png), each used when present.
const ITEMS_DIR := "res://art/platformer/items/"
const ITEMS := ["apple", "crate", "thorns", "flag", "flag_on", "drakkar", "heart", "heart_empty", "chest", "chest_open", "chest_royal", "chest_royal_open", "ladder"]
## Drawn hearts are small pixel art, shown this many times bigger.
const HEART_SCALE := 3.0
const SOUNDS := ["jump", "apple", "bump", "stomp", "hurt", "checkpoint", "win", "lose"]
## How far the camera looks ahead in the running direction.
const LOOK_AHEAD := 140.0
## Sword: how long a swing lasts, how soon the next one can start, how far it reaches.
const ATTACK_TIME := 0.3
const ATTACK_COOLDOWN := 0.35
const ATTACK_REACH := 84.0
## A Viking's health; the sword and a thrown apple each take away their damage.
const VIKING_HEALTH := 40
const APPLE_DAMAGE := 10
## A thrown apple: speed, how much it drops, how long it flies, and the wait before the next throw.
const APPLE_SPEED := 760.0
const APPLE_GRAVITY := 900.0
const APPLE_FLIGHT := 1.2
const THROW_COOLDOWN := 0.3
## On a ladder: speed up and down, speed sideways, and the hop that gets him onto the ledge at the top.
const CLIMB_SPEED := 260.0
const CLIMB_SIDE := 120.0
const CLIMB_HOP := 620.0
const LEAVES := 26
const POLLEN := 40

var lives := LIVES
var apples := 0
## "" while playing, then "won" or "lost".
var state := ""
## Tests set these instead of the keyboard.
var auto_input := false
## Damage of the sword Wiesław carries (other swords can hit harder).
var sword_damage := 10
var input_x := 0.0
var input_jump := false
var input_attack := false
var input_throw := false
## -1 up, 1 down: climbs a ladder Wiesław is at.
var input_climb := 0.0
## Which map to play: "knight" (LEVEL_KNIGHT) or "mario" (LEVEL); N switches.
var layout := "knight"
## A map from the campaign (PlatformerCampaign); when set, it is played instead of the layout.
var level_map: Array = []
## Night: the level is darker and bluer and there are no sunbeams.
var night := false
## Shown big for a moment when the level starts.
var level_name := ""

var player: CharacterBody2D
var vikings: Array[Dictionary] = []
## The brothers in the level: {"node", "name"}.
var merchants: Array[Dictionary] = []
## The brother whose offer is shown, or empty.
var shop := {}
## The fight for the magic eye, when the level has one.
var _boss: EyeBoss
var map: Array[String] = []
var checkpoint := Vector2.ZERO

var _level: Node2D
var _tiles: Node2D
## Key hints over chests and ladders, drawn in front of the characters.
var _hints: Node2D
var _wieslaw: CutoutCharacter
var _camera: Camera2D
var _hud: Node2D
var _background: Node2D
## The art set in use: {"scale", "tiles": {name: Texture2D}, "background": [{texture, mirrored, speed, follow, top, bottom, gap}]}.
var _art := {}
var _art_sets: Array[Dictionary] = []
var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _back: CanvasLayer
## The level is drawn into its own viewport, so it can be tinted as a whole (night).
var _world: SubViewport
var _view: SubViewportContainer
var _drakkar: Node2D
var _items := {}
var _coyote := 0.0
var _air_jumps := 0
## The side of the wall he is holding on to (-1 left, 1 right), 0 when none.
var _wall := 0
var _wall_lock := 0.0
var _buffered := 0.0
var _jump_was_held := false
var _hurt := 0.0
var _end_time := 0.0
var _anim := 0.0
## Short-lived pictures: apples popping out of blocks, knocked-out Vikings.
var _effects: Array[Dictionary] = []
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
var _attack := 0.0
var _attack_cooldown := 0.0
var _struck: Array[Node2D] = []
var _throw_cooldown := 0.0
var _solid: StaticBody2D
## Apples in flight: position, velocity, time in the air.
var _thrown: Array[Dictionary] = []
var _look := 0.0
## Time left on the mug of nalewka: nothing hurts Wiesław.
var _shield := 0.0
## Mugs of nalewka bought from the brothers and kept for later; Q drinks one.
var mugs := 0
## What Wiesław last drank. A frame set can draw a pose per drink ("drink_mug",
## "drink_potion", ...); one without it uses the plain "drink" pose.
var drinking := "mug"
## Whether Wiesław is holding on to a ladder.
var _climbing := false


func _ready() -> void:
	add_to_group("platformer")
	_view = SubViewportContainer.new()
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_view)
	_world = SubViewport.new()
	# Whole pixels only: with the camera between pixels, tiles could show thin gaps between them.
	_world.snap_2d_transforms_to_pixel = true
	_world.snap_2d_vertices_to_pixel = true
	_world.size_2d_override = Vector2i(SCREEN)
	_world.size_2d_override_stretch = true
	_view.add_child(_world)
	_fit_view()
	get_viewport().size_changed.connect(_fit_view)
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
	_hud.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(_hud)
	_hud.draw.connect(_draw_hud)
	if Game.fast and not auto_input:
		state = "won"
		set_physics_process(false)
		finished.emit.call_deferred()
		return
	if get_parent() == get_tree().root:
		# Run on its own (F6 in the editor): play again after the finish.
		Game.load_settings()
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
	_attack = 0.0
	_attack_cooldown = 0.0
	_throw_cooldown = 0.0
	_thrown.clear()
	_climbing = false
	_shield = 0.0
	shop = {}
	_boss = null
	merchants.clear()
	vikings.clear()
	if not level_map.is_empty():
		map.assign(level_map)
	else:
		map.assign(LEVEL_KNIGHT if layout == "knight" else LEVEL)
	_view.modulate = NIGHT_TINT if night else Color.WHITE
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
				"M":
					_add_merchant(at)
				"O":
					_boss = EyeBoss.new(self, at)
					_level.add_child(_boss)
					_boss.caught.connect(_win)
				"D":
					_add_drakkar(at)
	_add_player()
	_hints = Node2D.new()
	_hints.draw.connect(_draw_key_hints)
	_level.add_child(_hints)
	if _music and Game.sound == "all" and not _music.playing:
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


## The level is drawn at the screen's own resolution, not at 1280x720 and blown up, so on a big
## screen it moves in fine steps instead of jumping a few screen pixels at a time.
func _fit_view() -> void:
	var window := Vector2(get_window().size)
	var zoom := Vector2.ONE * maxf(minf(window.x / SCREEN.x, window.y / SCREEN.y), 1.0)
	_world.size = Vector2i((SCREEN * zoom).round())
	_view.size = Vector2(_world.size)
	_view.scale = Vector2.ONE / zoom


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
	# Moves with the physics steps, which physics interpolation smooths between frames.
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.offset = Vector2(0, -80)
	player.add_child(_camera)
	_level.add_child(player)
	_camera.make_current()


func _add_viking(at: Vector2) -> void:
	var color := Color("4f7a3a") if vikings.size() % 2 == 0 else Color("d9692b")
	var body: Node2D
	if PixelViking.has_art():
		var pixel := PixelViking.new()
		pixel.colour = PixelViking.COLOURS[vikings.size() % PixelViking.COLOURS.size()]
		body = pixel
	# With drawn frames for Wiesław, Vikings are Wiesław in another colour until they get their own.
	elif CutoutCharacter.has_frames():
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
	vikings.append({"node": body, "dir": -1.0, "color": color, "health": VIKING_HEALTH, "stun": 0.0, "push": 0.0})


## Rows of solid tiles become one static box each; planks become one-way boxes.
func _build_collision() -> void:
	if is_instance_valid(_solid):
		_solid.queue_free()
	var body := StaticBody2D.new()
	_solid = body
	_level.add_child(body)
	for row in map.size():
		var col := 0
		while col < map[row].length():
			var kind := map[row][col]
			var plank := _is_plank(row, col)
			if not (plank or kind in SOLID):
				col += 1
				continue
			var start := col
			while col < map[row].length() and (_is_plank(row, col) if plank else map[row][col] in SOLID):
				col += 1
			var shape := CollisionShape2D.new()
			shape.shape = RectangleShape2D.new()
			var height := 16.0 if plank else float(TILE)
			shape.shape.size = Vector2((col - start) * TILE, height)
			shape.position = Vector2((start + col) * TILE / 2.0, row * TILE + height / 2)
			shape.one_way_collision = plank
			body.add_child(shape)


## Planks, and the top of a ladder that goes down through the ground, can be stood on and passed
## from below.
func _is_plank(row: int, col: int) -> bool:
	if map[row][col] == "=":
		return true
	if map[row][col] != "H" or (row > 0 and map[row - 1][col] == "H"):
		return false
	return (col > 0 and map[row][col - 1] == "#") or (col + 1 < map[row].length() and map[row][col + 1] == "#")


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
	var jump_held := input_jump if auto_input else Input.is_action_pressed("move_up")
	if jump_held and not _jump_was_held:
		_buffered = JUMP_BUFFER
	var up_down := input_climb if auto_input else Input.get_axis("move_up", "move_down")
	if not _climbing and _ladder_ahead(up_down):
		_climbing = true
		player.velocity = Vector2.ZERO
		player.position.x = (floori(player.position.x / TILE) + 0.5) * TILE
		_buffered = 0.0
	if _climbing:
		_climb(delta, steer, up_down)
	else:
		_wieslaw.paused = false
		_move_player(delta, steer, jump_held)
	_jump_was_held = jump_held
	if auto_input and input_attack:
		attack()
	if auto_input and input_throw:
		throw_apple()
	_swing(delta)
	_shield = maxf(_shield - delta, 0.0)
	_wieslaw.modulate = Color(1.35, 1.2, 0.6) if _shield > 0.0 else Color.WHITE
	if not shop.is_empty() and _merchant_near() != shop:
		shop = {}
	for merchant in merchants:
		merchant["node"].set("facing", 1 if player.position.x > merchant["node"].position.x else -1)
	_fly_apples(delta)
	_move_vikings(delta)
	if _boss:
		_boss.step(delta)
	_check_touches()
	_redraw()


func _move_player(delta: float, steer: float, jump_held: bool) -> void:
	var v := player.velocity
	_wall_lock = maxf(_wall_lock - delta, 0.0)
	if _wall_lock <= 0.0:
		v.x = move_toward(v.x, steer * WALK_SPEED, ACCELERATION * delta)
	v.y += GRAVITY * delta
	_coyote = COYOTE_TIME if player.is_on_floor() else maxf(_coyote - delta, 0.0)
	if player.is_on_floor():
		_air_jumps = AIR_JUMPS
	_wall = 0
	if not player.is_on_floor() and v.y > 0.0 and absf(steer) > 0.1 and _wall_lock <= 0.0:
		var side := 1 if steer > 0.0 else -1
		if tile_at(player.position + Vector2(side * (PLAYER_SIZE.x / 2 + 4), -PLAYER_SIZE.y / 2)) in SOLID:
			_wall = side
			v.y = minf(v.y, WALL_SLIDE_SPEED)
			if randf() < 0.15:
				_dust(player.position + Vector2(side * PLAYER_SIZE.x / 2, -PLAYER_SIZE.y / 2), 1)
	if _buffered > 0.0 and _coyote > 0.0:
		v.y = -JUMP_SPEED
		_play("jump")
		_stretch = Vector2(0.8, 1.2)
		_dust(player.position, 3)
		_buffered = 0.0
		_coyote = 0.0
	elif _buffered > 0.0 and _wall != 0:
		v = Vector2(-_wall * WALL_JUMP.x, -WALL_JUMP.y)
		_wieslaw.facing = -_wall
		_wall = 0
		_wall_lock = WALL_LOCK
		_air_jumps = AIR_JUMPS
		_play("jump")
		_stretch = Vector2(0.8, 1.2)
		_buffered = 0.0
	elif _buffered > 0.0 and _air_jumps > 0 and jump_held and not _jump_was_held:
		v.y = -AIR_JUMP_SPEED
		_air_jumps -= 1
		_play("jump")
		_stretch = Vector2(0.85, 1.15)
		_buffered = 0.0
		_effects.append({"kind": "puff", "pos": player.position, "time": 0.0})
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
		_play("bump")
	if absf(steer) > 0.1 and _wall_lock <= 0.0:
		_wieslaw.facing = 1 if steer > 0 else -1
	if _hurt > HURT_TIME - 0.4:
		_wieslaw.pose = "hurt"
	elif _attack > 0.0 and _wieslaw.has_pose("attack"):
		_wieslaw.pose = "attack"
	elif _shield > MUG_TIME - DRINK_TIME and _drink_pose() != "" and player.is_on_floor() and absf(player.get_real_velocity().x) < 20.0:
		_wieslaw.pose = _drink_pose()
	elif _wall != 0 and _wieslaw.has_drawn_pose("wall"):
		_wieslaw.pose = "wall"
	elif not player.is_on_floor():
		_wieslaw.pose = "jump" if player.velocity.y < 0.0 else "fall"
	else:
		# Pushing against a wall he stands still, so the run stops too.
		_wieslaw.pose = "run" if absf(player.get_real_velocity().x) > 20.0 else "idle"
	_stretch = _stretch.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	_wieslaw.scale = Vector2(0.84 * _stretch.x * _wieslaw.facing, 0.84 * _stretch.y)
	# Without a drawn swing, he leans into the blow.
	_wieslaw.rotation = _wieslaw.facing * 0.18 * sin(_attack / ATTACK_TIME * PI) if not _wieslaw.has_pose("attack") else 0.0
	_move_camera(delta)
	# Blinks after the hurt pose, while he cannot be hit again.
	_wieslaw.visible = _hurt > HURT_TIME - 0.4 or fmod(_hurt, 0.2) < 0.12
	if player.position.y > map.size() * TILE + 120:
		_hit(true)


## Whether there is a ladder where Wiesław stands, or just under his feet (to climb down from a ledge).
func _ladder_here() -> bool:
	for dy in [-PLAYER_SIZE.y / 2, -8.0, 8.0]:
		if tile_at(player.position + Vector2(0, dy)) == "H":
			return true
	return false


## W at a ladder (or S on top of one) grabs it instead of jumping.
func _ladder_ahead(up_down: float) -> bool:
	if up_down < -0.5:
		return tile_at(player.position + Vector2(0, -PLAYER_SIZE.y / 2)) == "H" or tile_at(player.position + Vector2(0, -8)) == "H"
	if up_down > 0.5:
		return tile_at(player.position + Vector2(0, 8)) == "H"
	return false


## On a ladder he goes up and down without gravity, through planks but not through ground. At the
## bottom he steps off; past the top he hops onto the ledge; A or D takes him off the side.
func _climb(delta: float, steer: float, up_down: float) -> void:
	var step := Vector2(steer * CLIMB_SIDE, up_down * CLIMB_SPEED) * delta
	var feet := player.position + step
	if step.y > 0.0 and tile_at(feet + Vector2(0, 1)) in SOLID:
		player.position.y = floori(feet.y / TILE) * TILE
		_climbing = false
		return
	if step.y < 0.0 and tile_at(feet - Vector2(0, PLAYER_SIZE.y)) in SOLID:
		step.y = 0.0
	if tile_at(feet + Vector2(signf(step.x) * PLAYER_SIZE.x / 2, -PLAYER_SIZE.y / 2)) in SOLID:
		step.x = 0.0
	player.position += step
	player.velocity = Vector2.ZERO
	if absf(steer) > 0.1:
		_wieslaw.facing = 1 if steer > 0 else -1
	_wieslaw.pose = "climb" if _wieslaw.has_drawn_pose("climb") else ("run" if step != Vector2.ZERO else "idle")
	_wieslaw.paused = _wieslaw.pose == "climb" and step.y == 0.0
	_wieslaw.scale = Vector2(0.84 * _wieslaw.facing, 0.84)
	_wieslaw.rotation = 0.0
	_wieslaw.visible = _hurt > HURT_TIME - 0.4 or fmod(_hurt, 0.2) < 0.12
	_move_camera(delta)
	if not _ladder_here():
		_climbing = false
		if up_down < 0.0:
			player.velocity.y = -CLIMB_HOP


## The closed chest Wiesław stands at or right next to, or Vector2.INF when there is none.
func _chest_near() -> Vector2:
	var middle := player.position + Vector2(0, -TILE / 2.0)
	for dx in [0.0, -TILE * 0.6, TILE * 0.6]:
		var point: Vector2 = middle + Vector2(dx, 0)
		var kind := tile_at(point)
		if kind == "T" or kind == "S" or (kind == " " and tile_at(point - Vector2(TILE, 0)) == "S"):
			return point
	return Vector2.INF


## F: talks to the brother Wiesław stands at (or says goodbye), or opens the chest he stands at.
func use() -> void:
	if state != "" or not player:
		return
	var merchant := _merchant_near()
	if not merchant.is_empty():
		shop = {} if shop == merchant else merchant
		return
	var chest := _chest_near()
	if chest != Vector2.INF:
		_open_chest(chest)


## The brother Wiesław stands next to, or an empty dictionary.
func _merchant_near() -> Dictionary:
	for merchant in merchants:
		var offset: Vector2 = merchant["node"].position - player.position
		if absf(offset.x) < 90.0 and absf(offset.y) < 40.0:
			return merchant
	return {}


## Buys from the brother whose offer is shown: "heart" (only with a heart to fill) or "mug".
func buy(item: String) -> void:
	if shop.is_empty():
		return
	var price := HEART_PRICE if item == "heart" else MUG_PRICE
	if apples < price or (item == "heart" and lives >= LIVES):
		_play("bump")
		return
	apples -= price
	if item == "heart":
		lives += 1
	else:
		mugs += 1
	_play("checkpoint")
	_hud.queue_redraw()


func _win() -> void:
	if state != "":
		return
	state = "won"
	_stop_music()
	_play("win")
	Game.set_flag("jablka_proba", apples)


## A Viking of the eye fight runs into Wiesław.
func hurt_by_boss() -> void:
	_hit(false)


## Q: drinks a mug of nalewka from the bag, and for a while nothing hurts Wiesław.
func drink() -> void:
	if state != "" or mugs <= 0 or _shield > 0.0:
		return
	mugs -= 1
	drinking = "mug"
	_shield = MUG_TIME
	_play("checkpoint")
	_hud.queue_redraw()


## The pose for what Wiesław is drinking, or "" when the frame set draws no drinking at all.
func _drink_pose() -> String:
	for name in ["drink_" + drinking, "drink"]:
		if _wieslaw.has_drawn_pose(name):
			return name
	return ""


## A brother stands at his stall facing the way Wiesław comes from, with his name over him.
func _add_merchant(at: Vector2) -> void:
	var color := Color("4f7a3a") if merchants.size() % 2 == 0 else Color("b0302a")
	var body: Node2D
	if CutoutCharacter.has_frames():
		var drawn := CutoutCharacter.new()
		drawn.robe_color = color
		drawn.scale = Vector2(0.84, 0.84)
		body = drawn
	else:
		var placeholder := Character.new()
		placeholder.body_color = color
		placeholder.scale = Vector2(0.6, 0.6)
		body = placeholder
	body.position = at
	body.set("facing", -1)
	_level.add_child(body)
	_level.move_child(body, _tiles.get_index() + 1)
	merchants.append({"node": body, "name": BROTHERS[merchants.size() % BROTHERS.size()]})


## A crate hit by the sword or an apple breaks and lets its apples out.
func _break_crate(point: Vector2) -> void:
	if tile_at(point) != "B":
		return
	_set_tile(point, " ")
	_build_collision()
	apples += CRATE_APPLES
	_play("apple")
	_shake = maxf(_shake, 0.08)
	var center := Vector2((floori(point.x / TILE) + 0.5) * TILE, (floori(point.y / TILE) + 0.5) * TILE)
	_dust(center + Vector2(0, TILE / 2.0), 5)
	for i in CRATE_APPLES:
		_effects.append({"kind": "apple", "pos": center + Vector2((i - 0.5) * 24.0, 0), "time": 0.0})


## A small four-pointed star that blinks now and then somewhere on a closed royal chest.
func _draw_glint(v: Node2D, at: Vector2, size: Vector2, phase: int) -> void:
	var t := fmod(_anim * 0.8 + phase * 0.37, 1.0)
	if t > 0.35:
		return
	var spot := floori(_anim * 0.8 + phase * 0.37)
	var pos := at + size * Vector2(0.2 + 0.6 * fposmod(spot * 0.618, 1.0), 0.15 + 0.5 * fposmod(spot * 0.382, 1.0))
	var r := sin(t / 0.35 * PI) * 10.0
	var shine := Color(1, 1, 0.85, 0.95)
	v.draw_line(pos - Vector2(r, 0), pos + Vector2(r, 0), shine, 3.0)
	v.draw_line(pos - Vector2(0, r), pos + Vector2(0, r), shine, 3.0)
	v.draw_circle(pos, r * 0.25, Color.WHITE)


## A chest opened with F stays open and gives apples and a heart.
## The royal chest does the same with more apples and every heart, and shakes the screen.
func _open_chest(point: Vector2) -> void:
	# The royal chest covers two tiles; standing at its right half counts too.
	if tile_at(point) == " " and tile_at(point - Vector2(TILE, 0)) == "S":
		point -= Vector2(TILE, 0)
	var kind := tile_at(point)
	if kind != "T" and kind != "S":
		return
	var royal := kind == "S"
	_set_tile(point, kind.to_lower())
	var count := ROYAL_APPLES if royal else CHEST_APPLES
	apples += count
	lives = LIVES if royal else mini(lives + 1, LIVES)
	_play("win" if royal and _sounds.has("win") else "checkpoint")
	if royal:
		_shake = maxf(_shake, 0.3)
	var center := Vector2((floori(point.x / TILE) + (1.0 if royal else 0.5)) * TILE, floori(point.y / TILE) * TILE)
	for i in count:
		var spread := Vector2((i - (count - 1) / 2.0) * (10.0 if royal else 18.0), (i % 3) * -14.0)
		_effects.append({"kind": "apple", "pos": center + spread, "time": 0.0})
	_hud.queue_redraw()


## Starts a sword swing in front of Wiesław.
func attack() -> void:
	if state != "" or _attack_cooldown > 0.0:
		return
	_attack = ATTACK_TIME
	_attack_cooldown = ATTACK_COOLDOWN
	_struck.clear()
	_stretch = Vector2(1.12, 0.92)
	_play("jump")
	_effects.append({"kind": "slash", "dir": _wieslaw.facing, "time": 0.0})


## While the swing lasts, the blade hits Vikings and ? blocks in front of Wiesław, each once.
func _swing(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack <= 0.0:
		return
	_attack = maxf(_attack - delta, 0.0)
	var facing := float(_wieslaw.facing)
	var blade := Rect2(player.position + Vector2(-20.0 if facing > 0 else 20.0 - ATTACK_REACH - 20.0, -PLAYER_SIZE.y), Vector2(ATTACK_REACH + 20.0, PLAYER_SIZE.y - 6))
	for viking in vikings.duplicate():
		var node: Node2D = viking["node"]
		if node in _struck or not blade.intersects(Rect2(node.position - Vector2(24, 80), Vector2(48, 80))):
			continue
		_struck.append(node)
		_strike(viking, facing, sword_damage)
	if _boss:
		_boss.strike(blade, facing, sword_damage)
	# The far end of the blade, whichever way he faces.
	var reach := 0.75 if facing > 0 else 0.25
	for point in [blade.position + blade.size * Vector2(reach, 0.2), blade.position + blade.size * Vector2(reach, 0.6)]:
		_break_crate(point)


## A Viking hit by the sword or an apple flashes and slides back; out of health, he falls over.
func _strike(viking: Dictionary, from_dir: float, damage: int) -> void:
	var node: Node2D = viking["node"]
	viking["health"] -= damage
	_shake = maxf(_shake, 0.1)
	_play("stomp")
	node.modulate = Color(3, 3, 3)
	node.create_tween().tween_property(node, "modulate", Color.WHITE, 0.2)
	if viking["health"] <= 0:
		vikings.erase(viking)
		_effects.append({"kind": "viking", "pos": node.position, "time": 0.0})
		_squash(node)
	else:
		viking["stun"] = 0.4
		viking["push"] = from_dir * 420.0
		viking["dir"] = -from_dir


## Throws one of the gathered apples forward in a low arc.
func throw_apple() -> void:
	if state != "" or _throw_cooldown > 0.0:
		return
	if apples <= 0:
		_play("bump")
		return
	apples -= 1
	_throw_cooldown = THROW_COOLDOWN
	_stretch = Vector2(1.08, 0.95)
	_play("jump")
	var facing := float(_wieslaw.facing)
	_thrown.append({"pos": player.position + Vector2(facing * 26.0, -62), "vel": Vector2(facing * APPLE_SPEED, -220.0), "time": 0.0})


## An apple flies until it hits a Viking, a wall or a ? block, or until it has flown too long.
func _fly_apples(delta: float) -> void:
	_throw_cooldown = maxf(_throw_cooldown - delta, 0.0)
	for apple in _thrown.duplicate():
		apple["time"] += delta
		apple["vel"].y += APPLE_GRAVITY * delta
		apple["pos"] += apple["vel"] * delta
		var at: Vector2 = apple["pos"]
		var spent: bool = apple["time"] > APPLE_FLIGHT
		for viking in vikings.duplicate():
			if not spent and Rect2(viking["node"].position - Vector2(24, 80), Vector2(48, 80)).grow(10).has_point(at):
				_strike(viking, signf(apple["vel"].x), APPLE_DAMAGE)
				spent = true
		if not spent and _boss and not _boss.won:
			spent = _boss.knock_eye(at) or _boss.strike(Rect2(at - Vector2(10, 10), Vector2(20, 20)), signf(apple["vel"].x), APPLE_DAMAGE)
		var tile := tile_at(at)
		if not spent and tile in SOLID:
			_break_crate(at)
			spent = true
		if spent:
			_thrown.erase(apple)
			_dust(at, 3)
			_effects.append({"kind": "splat", "pos": at, "time": 0.0})


## Vikings walk back and forth and turn at walls and ledges; a hit Viking slides back for a moment.
func _move_vikings(delta: float) -> void:
	for viking in vikings:
		var node: Node2D = viking["node"]
		if viking["stun"] > 0.0:
			viking["stun"] -= delta
			var back := node.position + Vector2(viking["push"] * delta, 0)
			if not tile_at(back + Vector2(signf(viking["push"]) * 24.0, -10)) in SOLID and tile_at(back + Vector2(0, 10)) in SOLID + "=":
				node.position = back
			viking["push"] *= 0.85
			continue
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
				_win()
				return
	for viking in vikings.duplicate():
		var node: Node2D = viking["node"]
		var them := Rect2(node.position - Vector2(24, 80), Vector2(48, 80))
		if not me.intersects(them) or viking["stun"] > 0.0:
			continue
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
	if (_hurt > 0.0 or _shield > 0.0) and not fell:
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
		player.reset_physics_interpolation()
	else:
		player.velocity = Vector2(-_wieslaw.facing * 300.0, -450.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("cancel"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
	elif state == "" and ((event is InputEventKey and event.physical_keycode == KEY_SPACE) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)):
		attack()
		get_viewport().set_input_as_handled()
	elif state == "" and ((event is InputEventKey and event.physical_keycode == KEY_E) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT)):
		throw_apple()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_L and _art_sets.size() > 1:
		next_art_set()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_K and CutoutCharacter.anim_dirs().size() > 1:
		# Another look for Wiesław: the level starts over with him.
		CutoutCharacter.anim_choice += 1
		restart()
		get_viewport().set_input_as_handled()
	elif not shop.is_empty() and event is InputEventKey and event.physical_keycode in [KEY_1, KEY_2]:
		buy("heart" if event.physical_keycode == KEY_1 else "mug")
		get_viewport().set_input_as_handled()
	elif state == "" and event is InputEventKey and event.physical_keycode == KEY_Q:
		drink()
		get_viewport().set_input_as_handled()
	elif state == "" and event is InputEventKey and event.physical_keycode == KEY_F:
		use()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_N and level_map.is_empty():
		layout = "mario" if layout == "knight" else "knight"
		restart()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_M and (_music or not _sounds.is_empty()):
		# Sounds alone, then silence, then sounds with music (when there is music), and round again.
		var order := ["sounds", "silent", "all"] if _music else ["sounds", "silent"]
		Game.sound = order[(order.find(Game.sound) + 1) % order.size()]
		Game.save_settings()
		if _music and Game.sound == "all" and state == "":
			_music.play()
		elif _music:
			_music.stop()
		_hud.queue_redraw()
		get_viewport().set_input_as_handled()
	elif state == "lost" and (event.is_action("interact") or event is InputEventMouseButton):
		restart()
		get_viewport().set_input_as_handled()


func _redraw() -> void:
	_tiles.queue_redraw()
	_hints.queue_redraw()
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
	if Game.sound == "silent" or not _sounds.has(sound):
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
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for dir in LEVEL_ART_SETS:
		if FileAccess.file_exists(dir + "level.json"):
			var art_set := _load_art_set(dir)
			art_set["name"] = dir.trim_suffix("/").get_file().trim_prefix("level_")
			_art_sets.append(art_set)
	if not _art_sets.is_empty():
		_art = _art_sets[0]
		for art_set in _art_sets:
			if art_set["name"] == Game.level_art:
				_art = art_set


## Switches to the art set named in Game.level_art (the settings menu changed it).
func use_level_art() -> void:
	for art_set in _art_sets:
		if art_set["name"] == Game.level_art:
			_art = art_set
	_redraw()


## Next art set; the choice is saved with the settings.
func next_art_set() -> void:
	if _art_sets.is_empty():
		return
	_art = _art_sets[(_art_sets.find(_art) + 1) % _art_sets.size()]
	Game.level_art = _art["name"]
	Game.save_settings()
	_redraw()


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
## "haze" lays a veil of the haze colour over a layer and all behind it, so far
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
		if layer["haze"] > 0.0:
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


## Whether there is ground in this column at or above the row.
func _ground_above(row: int, col: int) -> bool:
	for above in range(row, -1, -1):
		if map[above][col] == "#" or _shaft(above, col):
			return true
	return false


## A ladder going down through the ground.
func _shaft(row: int, col: int) -> bool:
	return map[row][col] == "H" and col > 0 and map[row][col - 1] == "#"


func _draw_tiles() -> void:
	var v := _tiles
	var ink := Color("2b1d14")
	var span := _visible_columns()
	# Pits: a dark hole where the bottom row has no ground.
	var bottom := map.size() - 1
	for col in range(span.x, mini(span.y, map[bottom].length())):
		if map[bottom][col] != "#":
			v.draw_rect(Rect2(col * TILE, (bottom - 1) * TILE + 16, TILE, 3 * TILE), Color("3b2a1f"))
	# Caves: a dark back wall wherever there is ground somewhere overhead.
	for col in range(span.x, mini(span.y, map[0].length())):
		var under_ground := false
		for row in map.size():
			if map[row][col] == "#":
				under_ground = true
			elif under_ground or _shaft(row, col):
				under_ground = true
				v.draw_rect(Rect2(col * TILE, row * TILE, TILE, TILE), Color("2a1d16"))
	for row in map.size():
		for col in range(span.x, mini(span.y, map[row].length())):
			var at := Vector2(col * TILE, row * TILE)
			var cell := Rect2(at, Vector2(TILE, TILE))
			match map[row][col]:
				"#":
					# Grass only under the open sky, not on a cave floor.
					var top := row == 0 or (map[row - 1][col] != "#" and not _ground_above(row - 1, col))
					if not _art.is_empty():
						# The deeper tile only from the third row down, where it is mostly off screen,
						# so it does not show as a dark band in a cliff.
						var deep := row >= 3 and map[row - 1][col] == "#" and map[row - 2][col] == "#" and map[row - 3][col] == "#"
						var fill := "ground_deep" if deep and _art["tiles"].has("ground_deep") else "ground"
						_draw_tile("ground_top" if top else fill, at)
						continue
					v.draw_rect(cell, Color("8b5a2b"))
					if top:
						v.draw_rect(Rect2(at, Vector2(TILE, 16)), Color("5e9e3f"))
				"B" when _items.has("crate"):
					v.draw_texture(_items["crate"], at)
				"S", "s" when _items.has("chest_royal"):
					var texture: Texture2D = _items["chest_royal_open" if map[row][col] == "s" and _items.has("chest_royal_open") else "chest_royal"]
					v.draw_texture(texture, at + Vector2(0, TILE - texture.get_height()))
					if map[row][col] == "S":
						_draw_glint(v, at + Vector2(0, TILE - texture.get_height()), texture.get_size(), col)
				"S", "s":
					var box := Rect2(at + Vector2(4, 16), Vector2(TILE * 2 - 8, TILE - 16))
					v.draw_rect(box, Color("8a2630"))
					v.draw_rect(box, Color("f2c14e"), false, 4.0)
					if map[row][col] == "S":
						_draw_glint(v, box.position, box.size, col)
				"T", "t" when _items.has("chest"):
					var texture: Texture2D = _items["chest_open" if map[row][col] == "t" and _items.has("chest_open") else "chest"]
					v.draw_texture(texture, at + Vector2(0, TILE - texture.get_height()))
				"T", "t":
					var lid := Rect2(at + Vector2(6, 14), Vector2(52, 16))
					if map[row][col] == "t":
						lid.position.y -= 14
					v.draw_rect(Rect2(at + Vector2(6, 30), Vector2(52, 34)), Color("9a5a2e"))
					v.draw_rect(lid, Color("c08a4a"))
					v.draw_rect(Rect2(at + Vector2(27, 28), Vector2(10, 12)), Color("f2c14e"))
				"a" when _items.has("apple"):
					var texture: Texture2D = _items["apple"]
					v.draw_texture(texture, at + (Vector2(TILE, TILE) - texture.get_size()) / 2 + Vector2(0, sin(_anim * 3.0 + col) * 4.0))
				"x" when _items.has("thorns"):
					v.draw_texture(_items["thorns"], at + Vector2(0, TILE - _items["thorns"].get_height()))
				"C", "c" when _items.has("flag"):
					var texture: Texture2D = _items["flag_on" if map[row][col] == "c" else "flag"]
					v.draw_texture(texture, at + Vector2(8, TILE - texture.get_height()))
				"H" when _items.has("ladder"):
					v.draw_texture(_items["ladder"], at)
				"H":
					for side in [12.0, 52.0]:
						v.draw_line(at + Vector2(side, 0), at + Vector2(side, TILE), Color("6b4423"), 6.0)
					for k in 3:
						v.draw_line(at + Vector2(12, 10 + k * 21), at + Vector2(52, 10 + k * 21), Color("8a5a2e"), 5.0)
				"B":
					v.draw_rect(cell, Color("c08a4a"))
					v.draw_rect(cell.grow(-3), ink, false, 3.0)
					v.draw_line(at + Vector2(6, 6), at + Vector2(58, 58), ink, 3.0)
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
	_draw_shadows()
	for apple in _thrown:
		var spin: float = apple["time"] * 14.0 * signf(apple["vel"].x)
		v.draw_set_transform(apple["pos"], spin, Vector2(0.7, 0.7))
		if _items.has("apple"):
			var texture: Texture2D = _items["apple"]
			v.draw_texture(texture, -texture.get_size() / 2)
		else:
			v.draw_circle(Vector2.ZERO, 15, Color("d62828"))
		v.draw_set_transform(Vector2.ZERO)
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
			"slash":
				# A stand-in for a drawn sword swing: a white arc sweeping down in front of Wiesław.
				var t: float = effect["time"] / ATTACK_TIME
				# With a drawn swing, the arc only trails the blade as it comes down.
				if _wieslaw.has_drawn_pose("attack"):
					t = (t - 0.5) * 2.0
				if t >= 0.0 and t < 1.0:
					var dir: float = effect["dir"]
					var start := -PI * 0.55 + t * PI * 0.5
					var arc_from := start if dir > 0 else PI - start - PI * 0.6
					var center := player.position + Vector2(dir * 24.0, -48)
					v.draw_arc(center, 62.0, arc_from, arc_from + PI * 0.6, 20, Color(1, 1, 1, 0.95 * (1.0 - t)), 14.0)
					v.draw_arc(center, 74.0, arc_from + 0.1, arc_from + PI * 0.6, 20, Color(1, 0.93, 0.6, 0.6 * (1.0 - t)), 5.0)
			"puff":
				# A ring of air under his feet for the jump in mid-air.
				var t: float = effect["time"] / 0.5
				v.draw_set_transform(effect["pos"], 0.0, Vector2(1.0, 0.35))
				v.draw_arc(Vector2.ZERO, 14.0 + t * 40.0, 0.0, TAU, 24, Color(1, 1, 1, 0.7 * (1.0 - t)), 5.0)
				v.draw_set_transform(Vector2.ZERO)
			"splat":
				var t: float = effect["time"] / 0.5
				for k in 6:
					var bit: Vector2 = effect["pos"] + Vector2.from_angle(k * TAU / 6.0 + 0.3) * (8.0 + t * 30.0) + Vector2(0, t * t * 30.0)
					v.draw_circle(bit, 4.0 * (1.0 - t), Color(Color("d62828") if k % 2 == 0 else Color("f3e6b3"), 1.0 - t))
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


## A small key in a bubble over a chest Wiesław can open or a brother he can talk to with F,
## the brother's offer while it is open, and a golden glow while the nalewka works.
func _draw_key_hints() -> void:
	if state != "" or not player:
		return
	# A health bar over every Viking who has been hit.
	for viking in vikings:
		if viking["health"] < VIKING_HEALTH:
			draw_health_bar(_hints, viking["node"].position + Vector2(0, -100), float(viking["health"]) / VIKING_HEALTH)
	if _shield > 0.0:
		var glow := player.position + Vector2(0, -PLAYER_SIZE.y / 2)
		_hints.draw_arc(glow, 70.0 + sin(_anim * 12.0) * 4.0, 0.0, TAU, 40, Color(1, 0.85, 0.3, 0.35 + 0.25 * minf(_shield, 1.0)), 6.0)
	var hints := []
	var merchant := _merchant_near()
	if shop.is_empty() and not merchant.is_empty():
		hints.append(["F", merchant["node"].position + Vector2(0, -150)])
	var chest := _chest_near()
	if chest != Vector2.INF:
		# Over the chest, or over Wiesław's head when he stands in front of it.
		hints.append(["F", Vector2((floori(chest.x / TILE) + 0.5) * TILE, minf(floori(chest.y / TILE) * TILE - 20, player.position.y - 150))])
	for hint in hints:
		var at: Vector2 = hint[1] + Vector2(0, sin(_anim * 5.0) * 3.0)
		_hints.draw_circle(at, 17, Color(1, 1, 1, 0.9))
		_hints.draw_arc(at, 17, 0.0, TAU, 24, Color("2b1d14"), 3.0)
		_hints.draw_string(ThemeDB.fallback_font, at + Vector2(-17, 8), hint[0], HORIZONTAL_ALIGNMENT_CENTER, 34, 22, Color("2b1d14"))


static func draw_health_bar(canvas: CanvasItem, center: Vector2, share: float, width := 56.0) -> void:
	var bar := Rect2(center - Vector2(width / 2, 4), Vector2(width, 8))
	canvas.draw_rect(bar.grow(2), Color("2b1d14"))
	canvas.draw_rect(bar, Color("5a1a14"))
	canvas.draw_rect(Rect2(bar.position, Vector2(width * clampf(share, 0.0, 1.0), 8)), Color("e04a32"))


## The brother's stall as a window in the middle of the screen: one card per thing, each with
## its picture, what it does, its price in apples and the key that buys it.
func _draw_shop(v: Node2D) -> void:
	var ink := Color("2b1d14")
	var paper := Color(1, 0.98, 0.9, 0.97)
	var font := ThemeDB.fallback_font
	var panel := Rect2(Vector2(340, 190), Vector2(600, 340))
	v.draw_rect(panel.grow(4), ink)
	v.draw_rect(panel, Color("c08a4a"))
	v.draw_string(font, panel.position + Vector2(0, 42), "%s sprzedaje" % shop["name"], HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 30, ink)
	var offers := [
		{"key": "1", "name": "Serce", "about": "+1 serduszko od razu", "price": HEART_PRICE,
			"why": "Masz wszystkie serca" if lives >= LIVES else ""},
		{"key": "2", "name": "Kufel nalewki", "about": "Do torby. Q: 2 s nietykalności", "price": MUG_PRICE, "why": ""},
	]
	for i in offers.size():
		var offer: Dictionary = offers[i]
		if offer["why"] == "" and apples < int(offer["price"]):
			offer["why"] = "Za mało jabłek"
		var card := Rect2(panel.position + Vector2(24 + i * 284, 64), Vector2(268, 214))
		v.draw_rect(card, paper)
		v.draw_rect(card, ink, false, 3.0)
		var faded: bool = offer["why"] != ""
		var tint := Color(1, 1, 1, 0.4) if faded else Color.WHITE
		# The picture.
		var icon := card.position + Vector2(card.size.x / 2, 52)
		if i == 0 and _items.has("heart"):
			var heart: Texture2D = _items["heart"]
			var size := heart.get_size() * HEART_SCALE
			v.draw_texture_rect(heart, Rect2(icon - size / 2, size), false, tint)
		elif i == 0:
			v.draw_circle(icon, 22, Color(Color("d62828"), tint.a))
		else:
			v.draw_rect(Rect2(icon - Vector2(18, 16), Vector2(36, 40)), Color(Color("c08a4a"), tint.a))
			v.draw_rect(Rect2(icon - Vector2(18, 26), Vector2(36, 11)), Color(Color("f4f0e0"), tint.a))
			v.draw_rect(Rect2(icon - Vector2(18, 16), Vector2(36, 40)), Color(ink, tint.a), false, 3.0)
			v.draw_arc(icon + Vector2(21, 4), 10, -PI / 2, PI / 2, 10, Color(ink, tint.a), 4.0)
		v.draw_string(font, card.position + Vector2(0, 112), offer["name"], HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 26, Color(ink, tint.a))
		v.draw_string(font, card.position + Vector2(0, 140), offer["about"], HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 17, Color(ink, 0.8 * tint.a))
		# Price in apples, and the key in a little box.
		var price := card.position + Vector2(20, 186)
		if _items.has("apple"):
			v.draw_texture_rect(_items["apple"], Rect2(price - Vector2(0, 26), Vector2(32, 32)), false, tint)
		else:
			v.draw_circle(price + Vector2(16, -10), 13, Color(Color("d62828"), tint.a))
		v.draw_string(font, price + Vector2(40, 0), str(offer["price"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(ink, tint.a))
		var key := Rect2(card.end - Vector2(58, 52), Vector2(40, 38))
		v.draw_rect(key, Color(Color("f2c14e"), tint.a))
		v.draw_rect(key, Color(ink, tint.a), false, 3.0)
		v.draw_string(font, key.position + Vector2(0, 29), offer["key"], HORIZONTAL_ALIGNMENT_CENTER, key.size.x, 26, Color(ink, tint.a))
		if faded:
			v.draw_string(font, card.position + Vector2(0, card.size.y + 22), offer["why"], HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 18, Color("7a1010"))
	v.draw_string(font, panel.position + Vector2(0, panel.size.y - 10), "F: wyjście", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 20, ink)


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
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		_effects.append({"kind": "dust", "pos": at + Vector2(side * randf_range(6, 18), -4),
			"vel": Vector2(side * randf_range(40, 110), randf_range(-30, -5)), "time": randf_range(0.0, 0.1)})


## The camera looks ahead where Wiesław runs and shakes for a moment when he is hit.
func _move_camera(delta: float) -> void:
	if not _camera:
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
	if night:
		_overlay.draw_texture_rect(_vignette, Rect2(Vector2.ZERO, SCREEN), false)
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
		if _items.has("heart"):
			# A lost life shows the empty heart, or the full one darkened when there is none.
			var lost := i >= lives
			var texture: Texture2D = _items["heart_empty"] if lost and _items.has("heart_empty") else _items["heart"]
			var size := texture.get_size() * HEART_SCALE
			var tint := Color(0.2, 0.2, 0.2, 0.6) if lost and not _items.has("heart_empty") else Color.WHITE
			v.draw_texture_rect(texture, Rect2(Vector2(22 + i * (size.x + 6), 40 - size.y / 2), size), false, tint)
		else:
			v.draw_circle(Vector2(40 + i * 40, 40), 14, Color("d62828") if i < lives else Color(0, 0, 0, 0.25))
	# A light outline keeps the text readable on a drawn background.
	var halo := Color(1, 1, 1, 0.85)
	var apples_at := Vector2(40 + LIVES * 54, 50) if _items.has("heart") else Vector2(170, 50)
	v.draw_string_outline(font, apples_at, "Jabłka: %d" % apples, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, halo)
	v.draw_string(font, apples_at, "Jabłka: %d" % apples, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, ink)
	if mugs > 0:
		# A little mug with its foam, and how many are in the bag.
		var mug := apples_at + Vector2(170, -26)
		v.draw_rect(Rect2(mug, Vector2(22, 26)), Color("c08a4a"))
		v.draw_rect(Rect2(mug, Vector2(22, 26)), ink, false, 2.0)
		v.draw_rect(Rect2(mug + Vector2(0, -6), Vector2(22, 7)), Color("f4f0e0"))
		v.draw_arc(mug + Vector2(24, 13), 7, -PI / 2, PI / 2, 8, ink, 3.0)
		var count := "x%d (Q)" % mugs
		v.draw_string_outline(font, mug + Vector2(38, 24), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, halo)
		v.draw_string(font, mug + Vector2(38, 24), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ink)
	var modes: Array[String] = []
	if _music or not _sounds.is_empty():
		modes.append("M: %s" % {"silent": "cisza", "all": "muzyka i dźwięki"}.get(Game.sound, "same dźwięki"))
	if _art_sets.size() > 1:
		modes.append("L: grafika")
	if CutoutCharacter.anim_dirs().size() > 1:
		modes.append("K: postać")
	if level_map.is_empty():
		modes.append("N: plansza %s" % ("rycerska" if layout == "knight" else "mario"))
	var mode := "     ".join(modes)
	v.draw_string_outline(font, Vector2(0, 48), mode, HORIZONTAL_ALIGNMENT_RIGHT, SCREEN.x - 30, 20, 6, halo)
	v.draw_string(font, Vector2(0, 48), mode, HORIZONTAL_ALIGNMENT_RIGHT, SCREEN.x - 30, 20, ink)
	if not shop.is_empty():
		_draw_shop(v)
	if level_name != "" and _anim < 3.0:
		var fade := clampf(3.0 - _anim, 0.0, 1.0)
		v.draw_string_outline(font, Vector2(0, 300), level_name, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 56, 10, Color(halo, fade))
		v.draw_string(font, Vector2(0, 300), level_name, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 56, Color(ink, fade))
	var message := ""
	if state == "" and _boss:
		message = "Dwaj Wikingowie i jedno oko! Bij tego, który nie ma oka.\nKto złapie oko, od razu atakuje. Pokonaj obu i podnieś oko!"
	elif state == "" and player and player.position.x < 900.0:
		message = "A/D: chodzenie     W: skok, w powietrzu jeszcze raz     W/S przy drabinie: wspinanie\nSpacja albo klik: miecz     E albo prawy klik: rzut jabłkiem     F: skrzynie i rozmowa     Q: kufel"
	elif state == "lost":
		message = "Ojej, Wiesław stracił wszystkie serduszka!\nSpacja albo klik: jeszcze raz"
	elif state == "won" and _boss:
		message = "Oko jest Wieśka! Wikingowie oddają jabłka i drakkar."
	elif state == "won":
		message = "Hop! Wiesław dogonił drakkar!"
	if message != "":
		v.draw_multiline_string_outline(font, Vector2(0, 110), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 26, -1, 6, halo)
		v.draw_multiline_string(font, Vector2(0, 110), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 26, -1, ink)
