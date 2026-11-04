class_name PlatformerGame
extends Node2D
## Platformer level in the spirit of Mario: Wiesław walks and jumps through the orchard after the
## Vikings' drakkar. Jump on Vikings to knock them out, bump ? blocks from below for apples,
## avoid thorns and pits. The level is drawn from the text map in LEVEL, so it is easy to edit.

signal finished
signal pause_requested

const TILE := 64
const SCREEN := Vector2(1280, 720)
## The camera is pulled back a little, so more of the level is in view.
const VIEW_ZOOM := 0.8
## In the castle the camera stands further back, so the rooms look taller around Wiesław; at 2/3
## the castle pictures, drawn three times bigger, keep whole pixels.
const DUNGEON_ZOOM := 2.0 / 3.0
## In the castle Wiesław stands this far below the middle of the screen (a share of its height),
## with the room above him in view.
const FRAME_LOW := 0.2
## How far the camera looks down ahead of a fall, at most.
const FALL_LOOK := 2.5 * 64.0
## How long the game stands still when a blow lands, in seconds.
const HIT_FREEZE := 0.06
## Darkness over castle stone by how deep it is from open air: the edge stays as drawn and the
## inside fades to black, so only the places Wiesław can reach catch the eye.
const ROCK_DARK := [0.0, 0.0, 0.6, 0.88, 0.97]
const ROCK_INK := Color(0.02, 0.015, 0.025)
## Dark shapes close to the camera, in front of the castle: hanging chains.
## They slide past faster than the level (NEAR_PARALLAX times), which gives the castle depth.
const NEAR_PARALLAX := 1.5
const NEAR_INK := Color(0.035, 0.03, 0.045)
const NEAR_RIM := Color(0.2, 0.13, 0.1)
## One near shape about every this many tiles.
const NEAR_EVERY := Vector2i(10, 16)
## The back wall is dimmed a little and shaded where it meets the stone, so the stone Wiesław walks
## on stands out in front of it.
const WALL_DIM := 0.18
## How dark the shade on the wall is under a ceiling, over a floor and beside a wall, and how far
## it reaches in tiles.
const WALL_SHADE := {"under": [0.6, 1.1], "over": [0.35, 0.7], "beside": [0.45, 0.8]}
## Where the background pictures expect the ground: two tiles above the bottom of the screen.
const GROUND_LINE := SCREEN.y - 2 * TILE
## Rows of open sky the camera can show above an outdoor level.
const SKY_ROWS := 4
## One character per tile:
## # ground   B crate   = plank (jump through from below)
## a apple   x thorns   V Viking   C checkpoint   P start   D the drakkar (finish)
## T treasure chest (open it with F)   S royal chest, two tiles wide (leave the tile on its right empty)
## H ladder (W and S climb it, A or D steps off)   M one of Wiesław's brothers, who sells things for apples (F)
## O the two Vikings with one eye (catch the eye to win; no drakkar needed)
## Castle furniture, only pictures: k hearth with a cauldron   p wall shelf   j throne   w weapon rack
## h sacks and barrels   i bed   m heap of coins   n feast table   r carved pillar   v barred door
## y brazier (lights the room)   E chest   g shield and antlers on the wall   q roots from the ceiling
## R a rat (runs fast, one hit)
## F hanging banner   G bread oven   I sausages and garlic on a pole (hangs from the top)
## J mail shirt on a stand   N loom
## Castle walls, placed by hand (a map with none of a letter spreads them out itself): o window (its left half, on the floor)   f torch   b banner
## K a key   L a locked door (paint it up to the ceiling, or it can be jumped over; F with a key opens it)
## Z a trapdoor in the floor (paint it through the whole floor)   d a lever: F opens the nearest
## trapdoor
## u a hidden room: paint the room with it, things inside go in as usual; it looks like solid stone
## until Wiesław steps in
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
const SOLID := "#BLZ"
## How long a found hidden room takes to crumble open (seconds, about).
const SECRET_REVEAL := 1.5
## How long each drawn step of a door swinging open shows (seconds).
const DOOR_STEP := 0.16
## Apples inside a broken crate.
const CRATE_APPLES := 2
const NIGHT_TINT := Color(0.5, 0.56, 0.86)
const DUNGEON_TINT := Color(0.92, 0.86, 0.8)
const STONE := Color("6e6a66")
const STONE_LIGHT := Color("8d8882")
const MORTAR := Color("3e3a37")
const WALL := Color("2e2a2c")
const WALL_MORTAR := Color("1f1c1e")
const HALL := Color("5e5651")
const HALL_MORTAR := Color("4a4440")
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
## Rats run fast and go down with one hit.
const RAT_SPEED := 190.0
const PLAYER_SIZE := Vector2(40, 92)
## Ready-made tiles and background layers, one set per folder: level.json names the files and how
## the layers scroll. L switches between the sets that are there; without any the level is drawn
## with plain shapes.
## Keyed by the name kept in Game.level_art. "piksele" is the author's pixel-art sample board.
const LEVEL_ART_SETS := {"kreskowka": "res://art/platformer/level_kreskowka/", "piksele": "res://art/platformer/level_autor/"}
## Music (music.ogg, looped) and sound effects (<name>.ogg) for the level, each used when present.
const AUDIO_DIR := "res://art/platformer/audio/"
## Drawn pictures for things in the level (<name>.png), each used when present.
const ITEMS_DIR := "res://art/platformer/items/"
## Drawn castle stone, used for the dungeon ground when present: tileset.png + tiles.json for the
## halls, lochy.png + lochy.json for the dungeons below the starting ground (the halls' set when
## missing). Each sheet is a dual grid: a tile sits on the corner between four map cells, and the
## json lists the tiles for each mask of solid corners (1 top left, 2 top right, 4 bottom left,
## 8 bottom right).
const CASTLE_DIR := "res://art/platformer/zamek/"
## The same castle pieces drawn finer, used when Game.castle_detail is "drobne".
const CASTLE_DIR_FINE := "res://art/platformer/zamek_drobne/"
## The dungeons are dim; torches and a small glow around Wiesław light them.
const DUNGEON_DARK := Color(0.32, 0.3, 0.38)
const TORCH_LIGHT := Color(1.0, 0.78, 0.5)
## Drawn castle pieces in CASTLE_DIR (<name>.png), each used when present: the back walls (tiled),
## windows, banners, barred windows, cells and chains on the walls, the exit door, ladders, planks,
## spikes and the torch frames (torch_0.png, torch_1.png, ...).
const CASTLE_PIECES := ["wall_hall", "wall_dungeon", "wall_deep", "window", "banner", "door", "ladder", "plank", "spikes", "kociol", "polka", "tron", "stojak", "worki", "lozko", "monety", "stol", "slup", "krata", "ogien", "kufer", "trofeum", "korzenie", "sztandar", "piec", "wedzarnia", "kolczuga", "krosno", "klucz", "drzwi_zamkniete", "drzwi_1", "drzwi_2", "drzwi_3", "drzwi_4", "drzwi_5", "drzwi_6", "drzwi_7", "drzwi_8", "drzwi_otwarte", "zapadnia", "zapadnia_otwarta", "dzwignia"]
## How much darker the hall's back wall is drawn than its picture, so the floor stands out.
## Castle furniture by map letter: a hearth with a cauldron, a wall shelf, the prince's throne and a
## weapon rack. They are only pictures; Wiesław walks past them.
const CASTLE_FURNITURE := {"k": "kociol", "j": "tron", "w": "stojak", "h": "worki", "i": "lozko", "m": "monety", "n": "stol", "r": "slup", "v": "krata", "y": "ogien", "E": "kufer", "G": "piec", "J": "kolczuga", "N": "krosno"}
## Pictures on the wall, centred on their cell, and pictures hanging from the top of their cell.
const CASTLE_WALL_PICTURES := {"p": "polka", "g": "trofeum"}
const CASTLE_HANGING := {"q": "korzenie", "F": "sztandar", "I": "wedzarnia"}
const HALL_WALL_SHADE := Color(0.72, 0.72, 0.78)
const ITEMS := ["apple", "crate", "thorns", "flag", "flag_on", "drakkar", "heart", "heart_empty", "chest", "chest_open", "chest_royal", "chest_royal_open", "ladder"]
## Drawn hearts are small pixel art, shown this many times bigger.
const HEART_SCALE := 3.0
const SOUNDS := ["jump", "apple", "bump", "stomp", "hurt", "checkpoint", "win", "lose"]
const KEY_DIR := "res://art/platformer/ui/"
## How big the key cap is drawn, and how often it is pressed (seconds) while it is shown.
const KEY_SCALE := 2.0
const KEY_PRESS_EVERY := 1.4
## How far past the castle's side walls the camera may look out, in tiles.
const OUTSIDE_SIDES := 3
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
## Castle dungeons: stone walls and floors with torches instead of the outdoor art, and the
## drakkar tile (D) is the way out, a door.
var dungeon := false

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
## A blank key cap pressed down and back up, with the key's letter drawn on it (art/platformer/ui).
var _key_frames: Array[Texture2D] = []
## How far down each key frame's top face starts, so the letter moves with it.
var _key_tops: Array[float] = []
## See CASTLE_DIR: per set ("hall", "dungeon") the sheet and, per corner mask, its tile regions.
var _castle := {}
## See CASTLE_PIECES: the drawn pieces by name, and the torch frames.
var _pieces := {}
var _torch_frames: Array[Texture2D] = []
## The exit door opening, from shut (door_0) to open, when there are drawn frames for it.
var _door_frames: Array[Texture2D] = []
## The night landscape around the castle, seen through the hall windows, over the roof and past
## the side walls: layers from the sky to the meadow, each {"texture", "speed", "horizon"}. Speed 1
## moves with the world and 0 stays on the screen, so the slower a layer, the farther it seems.
## Its "horizon" row lines up with the castle's base when the camera is on the starting floor.
var _outside: Array[Dictionary] = []
## The outline of the window's glass in the window picture.
var _window_glass := PackedVector2Array()
## The colours above the farthest layer and below the nearest one.
var _outside_sky := Color.BLACK
var _outside_ground := Color.BLACK
## How much the landscape moves up and down with the world, like a layer's speed sideways.
var _outside_rise := 0.25
## The earth in front, under the castle's base: a tile repeated every way, and its grassy top
## edge, which stands this many pixels above the base.
var _soil: Texture2D
var _soil_top: Texture2D
var _soil_top_above := 0.0
## Draws the hall windows over the static layer every frame, so the view outside can scroll.
var _windows: Node2D
## See DUNGEON_DARK.
var _darkness: CanvasModulate
var _torch_lights: Array[PointLight2D] = []
var _hand_placed := {}
## The hidden rooms: each a rectangle of cells covered with stone, and how long ago it was found
## (below zero while still hidden).
var _secrets: Array[Dictionary] = []
var _secret_cover: Node2D
## Doors swinging open right now: the lowest cell of each, and the time it started.
var _doors_opening := {}
var _player_light: PointLight2D
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
## While above zero the game stands still for a moment, so a blow lands with weight.
var _freeze := 0.0
## How many cells deep each castle stone cell is from the nearest open cell (1 = on the edge).
var _rock_depth: Array[PackedByteArray] = []
## The near shapes: {"kind": "chain", "pos": where in the level, ...}.
var _near_things: Array[Dictionary] = []
## The wall shading and the stone darkness, each one mesh for the whole level (made when first drawn).
var _wall_mesh: ArrayMesh
var _rock_mesh: ArrayMesh
var _attack := 0.0
var _attack_cooldown := 0.0
var _struck: Array[Node2D] = []
var _throw_cooldown := 0.0
var _solid: StaticBody2D
## Apples in flight: position, velocity, time in the air.
var _thrown: Array[Dictionary] = []
var _look := 0.0
## The height of the floor Wiesław last stood on: in the castle the camera keeps to it during a
## jump instead of bobbing up and down with him.
var _floor_y := 0.0
var _look_down := 0.0
## Time left on the mug of nalewka: nothing hurts Wiesław.
var _shield := 0.0
## Mugs of nalewka bought from the brothers and kept for later; Q drinks one.
var mugs := 0
## Keys picked up and not yet used on a locked door.
var keys := 0
## What Wiesław last drank. A frame set can draw a pose per drink ("drink_mug",
## "drink_potion", ...); one without it uses the plain "drink" pose.
var drinking := "mug"
## Whether Wiesław is holding on to a ladder.
var _climbing := false
## What the player has already done once this session ("walk", "sword", "ladder", "mug"). Until
## then the keys for it are shown where they are first needed, and stay put there.
static var learned := {}
## Where Wiesław starts, and where the first Viking stands, for those key hints.
var _start_at := Vector2.INF
var _first_viking_at := Vector2.INF
## The top of the ground Wiesław starts on: the background stands on it, so the trees grow up
## from there and below it there is only the underground.
var _horizon := 0.0
## See _find_first_ground.
var _first_ground := PackedInt32Array()
## The ground, walls and everything else in the level that does not move. It is drawn in strips of
## STATIC_CHUNK columns (_chunks), each drawn once and again only when a tile changes and it is in
## view: drawing every brick each frame made big levels lag, and redrawing all in view at once
## made the game stutter.
var _static: Node2D
const STATIC_CHUNK := 16
## {"span": its columns, "nodes": its layers, "dirty": to be drawn again when in view}.
var _chunks: Array[Dictionary] = []
## The strip being drawn.
var _drawing: Node2D
## See _brick_texture.
var _bricks := {}


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
	_load_castle()
	while ResourceLoader.exists(KEY_DIR + "key_%d.png" % _key_frames.size()):
		_key_frames.append(load(KEY_DIR + "key_%d.png" % _key_frames.size()))
		_key_tops.append(float(_key_frames[-1].get_image().get_used_rect().position.y))
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
	keys = 0
	_doors_opening.clear()
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
	_find_first_ground()
	_view.modulate = NIGHT_TINT if night else (DUNGEON_TINT if dungeon else Color.WHITE)
	_level = Node2D.new()
	_world.add_child(_level)
	_static = Node2D.new()
	_level.add_child(_static)
	_make_chunks()
	_windows = Node2D.new()
	_windows.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_windows.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_windows.draw.connect(_draw_windows)
	_level.add_child(_windows)
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
					_start_at = at
					_horizon = at.y
				"V":
					_add_viking(at)
				"R":
					_add_rat(at)
				"M":
					_add_merchant(at)
				"O":
					_boss = EyeBoss.new(self, at)
					_level.add_child(_boss)
					_boss.caught.connect(_win)
				"D":
					_add_drakkar(at)
	_measure_rock()
	_wall_mesh = null
	_rock_mesh = null
	_place_near_things()
	_add_player()
	_add_secrets()
	_add_dungeon_lights()
	# The hints sit in the level but on their own layer, so the night and the castle's darkness
	# do not dim them.
	var hint_layer := CanvasLayer.new()
	hint_layer.follow_viewport_enabled = true
	_level.add_child(hint_layer)
	_hints = Node2D.new()
	_hints.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hints.draw.connect(_draw_key_hints)
	hint_layer.add_child(_hints)
	if _music and Game.sound == "all" and not _music.playing:
		_music.play()
	set_physics_process(true)


## The dim dungeon (see DUNGEON_DARK): only with the drawn castle pieces, which are made for it.
func _add_dungeon_lights() -> void:
	_torch_lights.clear()
	_player_light = null
	if not dungeon or _pieces.is_empty():
		return
	_darkness = CanvasModulate.new()
	_darkness.color = DUNGEON_DARK
	_level.add_child(_darkness)
	var glow := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	glow.gradient = gradient
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	glow.width = 128
	glow.height = 128
	for row in map.size():
		for col in map[row].length():
			if _torch_here(row, col) or (map[row][col] == "y" and _pieces.has("ogien")):
				var light := PointLight2D.new()
				light.texture = glow
				light.texture_scale = 4.5
				light.color = TORCH_LIGHT
				light.energy = 1.3
				light.position = Vector2(col * TILE + 32, row * TILE + 10)
				_level.add_child(light)
				_torch_lights.append(light)
	_player_light = PointLight2D.new()
	_player_light.texture = glow
	_player_light.texture_scale = 3.0
	_player_light.color = Color(0.9, 0.85, 1.0)
	_player_light.energy = 0.55
	_level.add_child(_player_light)


func _add_drakkar(at: Vector2) -> void:
	if dungeon:
		var door := Node2D.new()
		door.position = at
		door.draw.connect(_draw_door.bind(door))
		_drakkar = door
	elif _items.has("drakkar"):
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


## The way out of the dungeons: an arched wooden door with daylight around it, two tiles tall.
func _draw_door(door: Node2D) -> void:
	var glow := 0.5 + 0.15 * sin(_anim * 2.0)
	door.draw_circle(Vector2(0, -70), 90, Color(1.0, 0.9, 0.6, 0.18 * glow))
	if _pieces.has("door"):
		var picture: Texture2D = _pieces["door"]
		var size := picture.get_size()
		var left := -size.x / 2.0
		# Once Wiesław is out, the door swings open on its left hinge onto daylight.
		var open := clampf(_end_time / 0.8, 0.0, 1.0) if state == "won" else 0.0
		if open > 0.0:
			# Daylight in the doorway: a box under a half circle, so it follows the arch.
			var arch_top := -size.y + size.x / 2.0
			var light := Color(1.0, 0.95, 0.75, open)
			door.draw_rect(Rect2(left + 12, arch_top, size.x - 24, -arch_top), light)
			door.draw_circle(Vector2(0, arch_top), size.x / 2.0 - 12, light)
			door.draw_circle(Vector2(0, -size.y / 2.0), 120, Color(1.0, 0.9, 0.6, 0.3 * open))
		if not _door_frames.is_empty():
			var frame := _door_frames[mini(int(open * _door_frames.size()), _door_frames.size() - 1)]
			door.draw_texture(frame, Vector2(-frame.get_width() / 2.0, -frame.get_height()))
			return
		var width := size.x * (1.0 - 0.8 * open)
		door.draw_texture_rect(picture, Rect2(left, -size.y, width, size.y), false, Color(1, 1, 1).darkened(0.35 * open))
		return
	var arch := PackedVector2Array()
	for i in 13:
		var angle := PI + PI * i / 12.0
		arch.append(Vector2(cos(angle) * 46, -96 + sin(angle) * 40))
	var frame := PackedVector2Array([Vector2(46, 0), Vector2(-46, 0)])
	frame.append_array(arch)
	door.draw_colored_polygon(frame, MORTAR)
	var wood := PackedVector2Array()
	for point in frame:
		wood.append(point * Vector2(0.82, 1.0) + Vector2(0, 6) * signf(-point.y))
	door.draw_colored_polygon(wood, Color("7a4a26"))
	for x in [-24.0, -8.0, 8.0, 24.0]:
		door.draw_line(Vector2(x, -4), Vector2(x, -120 + absf(x) * 0.6), Color("5a3418"), 3.0)
	for y in [-30.0, -90.0]:
		door.draw_line(Vector2(-37, y), Vector2(37, y), Color("3a2a20"), 6.0)
	door.draw_circle(Vector2(26, -60), 5, Color("c9a24a"))


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
	# Outdoors the camera may rise a little above the highest thing in the level, into open sky.
	# Over the castle's roof the camera may show a little night sky, when there is a view outside.
	_camera.limit_top = 0 if dungeon and _outside.is_empty() else -SKY_ROWS * TILE
	if dungeon and not _outside.is_empty():
		_camera.limit_left = -OUTSIDE_SIDES * TILE
	_camera.limit_right = map[0].length() * TILE + (OUTSIDE_SIDES * TILE if dungeon and not _outside.is_empty() else 0)
	_camera.limit_bottom = map.size() * TILE
	_camera.position_smoothing_enabled = true
	# Moves with the physics steps, which physics interpolation smooths between frames.
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.offset = Vector2(0, -80)
	_camera.zoom = Vector2.ONE * (DUNGEON_ZOOM if dungeon else VIEW_ZOOM)
	_floor_y = player.position.y
	_look_down = 0.0
	player.add_child(_camera)
	_level.add_child(player)
	_camera.make_current()


func _add_viking(at: Vector2) -> void:
	if at.x < _first_viking_at.x:
		_first_viking_at = at
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


## A rat runs along like a Viking, only faster and low to the ground; one hit is enough.
func _add_rat(at: Vector2) -> void:
	var body := Rat.new()
	body.position = at
	body.facing = -1
	_level.add_child(body)
	vikings.append({"node": body, "dir": -1.0, "color": Color.GRAY, "health": 1, "stun": 0.0, "push": 0.0, "kind": "rat"})


## Where an enemy can be hit and can hurt: a tall box for a Viking, a low one for a rat.
func _enemy_box(viking: Dictionary) -> Rect2:
	var node: Node2D = viking["node"]
	if viking.get("kind", "") == "rat":
		return Rect2(node.position - Vector2(34, 44), Vector2(68, 44))
	return Rect2(node.position - Vector2(24, 80), Vector2(48, 80))


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
	_find_first_ground()
	_redraw_static()
	_tiles.queue_redraw()


func _physics_process(delta: float) -> void:
	if _freeze > 0.0:
		_freeze -= delta
		return
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
		learned["ladder"] = true
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
	_update_secrets(delta)
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


## F: talks to the brother Wiesław stands at (or says goodbye), opens the chest he stands at, or
## opens the castle's exit door.
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
		return
	var locked := _locked_door_near()
	if locked != Vector2i(-1, -1):
		_unlock(locked)
		return
	var lever := _lever_near()
	if lever != Vector2i(-1, -1):
		_pull(lever)
		return
	if _door_near():
		_win()


## The cell of a locked door right in front of Wiesław (either side), or (-1, -1).
func _locked_door_near() -> Vector2i:
	for dx in [TILE * 0.7, -TILE * 0.7]:
		for dy in [-TILE * 0.5, -TILE * 1.2]:
			var point: Vector2 = player.position + Vector2(dx, dy)
			if tile_at(point) == "L":
				return Vector2i(floori(point.x / TILE), floori(point.y / TILE))
	return Vector2i(-1, -1)


## A key opens the whole locked door (every L above and below this cell); without one it only rattles.
func _unlock(cell: Vector2i) -> void:
	if keys <= 0:
		_play("bump")
		_shake = maxf(_shake, 0.05)
		_effects.append({"kind": "nokey", "pos": Vector2((cell.x + 0.5) * TILE, cell.y * TILE), "time": 0.0})
		return
	keys -= 1
	var top := cell.y
	while top > 0 and map[top - 1][cell.x] == "L":
		top -= 1
	var row := top
	while row < map.size() and map[row][cell.x] == "L":
		map[row] = map[row].substr(0, cell.x) + "l" + map[row].substr(cell.x + 1)
		row += 1
	_doors_opening[Vector2i(cell.x, row - 1)] = _anim
	_build_collision()
	_redraw_static()
	_tiles.queue_redraw()
	_hud.queue_redraw()
	_play("checkpoint")
	_dust(Vector2((cell.x + 0.5) * TILE, row * TILE), 4)


## Each group of u cells (touching, corners too) is one hidden room: the rectangle around it is
## covered with stone until Wiesław steps into it.
func _add_secrets() -> void:
	_secrets.clear()
	var seen := {}
	for row in map.size():
		for col in map[row].length():
			if map[row][col] != "u" or seen.has(Vector2i(col, row)):
				continue
			var box := Rect2i(col, row, 1, 1)
			var todo: Array[Vector2i] = [Vector2i(col, row)]
			seen[Vector2i(col, row)] = true
			while not todo.is_empty():
				var cell: Vector2i = todo.pop_back()
				box = box.expand(cell).expand(cell + Vector2i.ONE)
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var next: Vector2i = cell + Vector2i(dx, dy)
						if next.y >= 0 and next.y < map.size() and next.x >= 0 and next.x < map[next.y].length() and map[next.y][next.x] == "u" and not seen.has(next):
							seen[next] = true
							todo.append(next)
			_secrets.append({"box": box, "found": -1.0, "from": Vector2.ZERO})
	if _secrets.is_empty():
		return
	_secret_cover = Node2D.new()
	_secret_cover.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_secret_cover.draw.connect(_draw_secrets)
	_level.add_child(_secret_cover)


## Finds a hidden room when Wiesław steps in, and plays the stone crumbling away from where he
## came in.
func _update_secrets(delta: float) -> void:
	if _secrets.is_empty():
		return
	var cell := Vector2i(floori(player.position.x / TILE), floori((player.position.y - TILE / 2.0) / TILE))
	for secret in _secrets:
		if secret["found"] < 0.0:
			if secret["box"].has_point(cell):
				secret["found"] = 0.0
				secret["from"] = Vector2(cell)
				_play("win" if _sounds.has("win") else "checkpoint")
				_shake = maxf(_shake, 0.15)
		elif secret["found"] < SECRET_REVEAL + 2.0:
			secret["found"] += delta
	_secret_cover.queue_redraw()


func _draw_secrets() -> void:
	for secret in _secrets:
		var box: Rect2i = secret["box"]
		var found: float = secret["found"]
		for row in range(box.position.y, box.end.y):
			for col in range(box.position.x, box.end.x):
				if map[row][col] == "#":
					continue
				var fade := 0.0
				if found >= 0.0:
					# Stones nearer to where he came in go first; each falls a little as it fades.
					var delay := Vector2(col, row).distance_to(secret["from"]) * 0.06
					fade = clampf((found - delay) / 0.4, 0.0, 1.0)
					if fade >= 1.0:
						continue
				var at := Rect2(col * TILE, row * TILE + fade * fade * 40.0, TILE, TILE)
				var tint := Color(1, 1, 1, 1.0 - fade)
				var part := _castle_part(row)
				if _castle.has(part) and _castle[part]["masks"].get(15, []).size() == 4:
					var rects: Array = _castle[part]["masks"][15]
					_secret_cover.draw_texture_rect_region(_castle[part]["sheet"], at, rects[(row % 2) * 2 + col % 2], tint)
				else:
					_secret_cover.draw_rect(at, Color(0.42, 0.4, 0.38, tint.a))
					_secret_cover.draw_rect(Rect2(at.position + Vector2(0, 30), Vector2(TILE, 3)), Color(0.3, 0.28, 0.26, tint.a))


## The cell of an unpulled lever Wiesław stands at, or (-1, -1).
func _lever_near() -> Vector2i:
	for dx in [0.0, TILE * 0.6, -TILE * 0.6]:
		for dy in [-TILE * 0.5, -TILE * 1.2]:
			var point: Vector2 = player.position + Vector2(dx, dy)
			if tile_at(point) == "d":
				return Vector2i(floori(point.x / TILE), floori(point.y / TILE))
	return Vector2i(-1, -1)


## Pulling a lever opens the trapdoor nearest to it: every Z cell joined to that one.
func _pull(lever: Vector2i) -> void:
	map[lever.y] = map[lever.y].substr(0, lever.x) + "e" + map[lever.y].substr(lever.x + 1)
	var nearest := Vector2i(-1, -1)
	for row in map.size():
		for col in map[row].length():
			if map[row][col] == "Z" and (nearest.x < 0 or Vector2(col, row).distance_to(Vector2(lever)) < Vector2(nearest).distance_to(Vector2(lever))):
				nearest = Vector2i(col, row)
	if nearest.x >= 0:
		var todo: Array[Vector2i] = [nearest]
		while not todo.is_empty():
			var cell: Vector2i = todo.pop_back()
			if cell.y < 0 or cell.y >= map.size() or cell.x < 0 or cell.x >= map[cell.y].length() or map[cell.y][cell.x] != "Z":
				continue
			map[cell.y] = map[cell.y].substr(0, cell.x) + "z" + map[cell.y].substr(cell.x + 1)
			todo.append_array([cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP, cell + Vector2i.DOWN])
		_dust(Vector2((nearest.x + 0.5) * TILE, nearest.y * TILE), 6)
		_shake = maxf(_shake, 0.12)
	_build_collision()
	_redraw_static()
	_play("bump")


## A lever on the wall (d up, e pulled down), or its picture dzwignia, turned upside down once pulled.
func _draw_lever(v: Node2D, at: Vector2, pulled: bool) -> void:
	var base := at + Vector2(TILE / 2.0, TILE - 18)
	if _pieces.has("dzwignia"):
		var texture: Texture2D = _pieces["dzwignia"]
		v.draw_set_transform(base + Vector2(0, -texture.get_height() / 2.0 + 18), 0.0, Vector2(1, -1 if pulled else 1))
		v.draw_texture(texture, -texture.get_size() / 2.0)
		v.draw_set_transform(Vector2.ZERO)
		return
	v.draw_rect(Rect2(base + Vector2(-12, -10), Vector2(24, 20)), Color("5a5a60"))
	var tip := base + (Vector2(14, 26) if pulled else Vector2(14, -34))
	v.draw_line(base, tip, Color("3a3a40"), 6.0)
	v.draw_circle(tip, 7, Color("8a2630"))


## A trapdoor: planks across the floor while shut (Z); once open (z) a dark hole with the door
## hanging down from its hinge in the top cell. Pictures zapadnia and zapadnia_otwarta, when drawn,
## sit in the top cell.
func _draw_trapdoor(v: Node2D, row: int, col: int, at: Vector2) -> void:
	var open := map[row][col] == "z"
	var top := row == 0 or map[row - 1][col] != map[row][col]
	var picture := "zapadnia_otwarta" if open else "zapadnia"
	if open:
		v.draw_rect(Rect2(at, Vector2(TILE, TILE)), Color(0.04, 0.03, 0.03))
	if top and _pieces.has(picture):
		# One picture across the whole trapdoor, from its leftmost cell, as wide as the trapdoor.
		if col > 0 and map[row][col - 1] == map[row][col]:
			return
		var width := 1
		while col + width < map[row].length() and map[row][col + width] == map[row][col]:
			width += 1
		var texture: Texture2D = _pieces[picture]
		var size := Vector2(width * TILE, texture.get_height() * width * TILE / float(texture.get_width()))
		v.draw_texture_rect(texture, Rect2(at, size), false)
		return
	if open:
		if top and (col == 0 or map[row][col - 1] != "z"):
			v.draw_rect(Rect2(at + Vector2(2, 0), Vector2(10, TILE + 30)), Color("6b4423"))
		return
	if top:
		v.draw_rect(Rect2(at, Vector2(TILE, 18)), Color("6b4423"))
		for x in [0.0, 21.0, 42.0]:
			v.draw_rect(Rect2(at + Vector2(x, 0), Vector2(2, 18)), Color("3a2414"))
		v.draw_rect(Rect2(at + Vector2(0, 6), Vector2(TILE, 3)), Color("3a3a40"))
	else:
		v.draw_rect(Rect2(at, Vector2(TILE, TILE)), Color("2a2622"))


## A door just unlocked swings open through its drawn steps (drzwi_1, drzwi_2, ...), then stays
## open with the walls.
func _draw_opening_doors(v: Node2D) -> void:
	for cell: Vector2i in _doors_opening.keys():
		var steps: Array[Texture2D] = []
		for picture in ["drzwi_zamkniete", "drzwi_1", "drzwi_2", "drzwi_3", "drzwi_4", "drzwi_5", "drzwi_6", "drzwi_7", "drzwi_8", "drzwi_otwarte"]:
			if _pieces.has(picture):
				steps.append(_pieces[picture])
		var step := int((_anim - _doors_opening[cell]) / DOOR_STEP)
		if steps.is_empty():
			_doors_opening.erase(cell)
			continue
		if step >= steps.size():
			# The open door is drawn with the walls from now on; this frame still shows it here.
			_doors_opening.erase(cell)
			_redraw_static()
		var texture := steps[mini(step, steps.size() - 1)]
		var at := Vector2(cell.x * TILE, cell.y * TILE)
		v.draw_texture(texture, at + Vector2(TILE / 2.0 - texture.get_width() / 2.0, TILE - texture.get_height()))


## A plain golden key lying on its side, centred on the point.
func _draw_door_key(v: CanvasItem, center: Vector2, scale: float) -> void:
	var gold := Color("e8b93c")
	var dark := Color("7a5a14")
	v.draw_set_transform(center, 0.0, Vector2(scale, scale))
	v.draw_circle(Vector2(-14, 0), 10, dark)
	v.draw_circle(Vector2(-14, 0), 7, gold)
	v.draw_circle(Vector2(-14, 0), 3, dark)
	v.draw_rect(Rect2(-5, -3, 26, 6), gold)
	v.draw_rect(Rect2(12, 3, 4, 7), gold)
	v.draw_rect(Rect2(18, 3, 3, 5), gold)
	v.draw_set_transform(Vector2.ZERO)


## A locked door (L) is a thick slab of oak with iron bands across the doorway, seen from the side;
## an opened one (l) is swung back towards the viewer, so only its hinges and edge show. A drawn
## picture (drzwi_zamkniete, drzwi_otwarte) stands on the door's lowest cell instead.
func _draw_door_cell(v: Node2D, row: int, col: int, at: Vector2) -> void:
	var open := map[row][col] == "l"
	var picture := "drzwi_otwarte" if open else "drzwi_zamkniete"
	if _pieces.has(picture):
		if row + 1 < map.size() and map[row + 1][col] == map[row][col]:
			return
		if _doors_opening.has(Vector2i(col, row)):
			return  # Drawn swinging by _draw_opening_doors.
		var texture: Texture2D = _pieces[picture]
		v.draw_texture(texture, at + Vector2(TILE / 2.0 - texture.get_width() / 2.0, TILE - texture.get_height()))
		return
	var top := row == 0 or map[row - 1][col] != map[row][col]
	var wood := Color("6b4423")
	var iron := Color("3a3a40")
	if open:
		v.draw_rect(Rect2(at + Vector2(4, 0), Vector2(10, TILE)), Color("4a2e18"))
		for y in [12.0, 44.0]:
			v.draw_rect(Rect2(at + Vector2(2, y), Vector2(16, 6)), iron)
		return
	var slab := Rect2(at + Vector2(20, 4 if top else 0), Vector2(24, TILE - (4 if top else 0)))
	v.draw_rect(slab, wood)
	v.draw_rect(Rect2(slab.position, Vector2(4, slab.size.y)), Color("8a5a30"))
	for y in [14.0, 46.0]:
		v.draw_rect(Rect2(at + Vector2(18, y), Vector2(28, 6)), iron)
	if top:
		v.draw_rect(Rect2(at + Vector2(16, 0), Vector2(32, 6)), iron)
	elif row + 1 < map.size() and map[row + 1][col] != "L":
		# The lock, low on the door.
		v.draw_rect(Rect2(at + Vector2(24, 22), Vector2(16, 18)), iron)
		v.draw_circle(at + Vector2(32, 29), 3, Color("e8b93c"))


## Whether Wiesław stands at the castle's exit door, so F opens it.
func _door_near() -> bool:
	if not dungeon or not _drakkar:
		return false
	var offset := _drakkar.position - player.position
	return absf(offset.x) < 100.0 and absf(offset.y) < 50.0


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
	learned["mug"] = true
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
	learned["sword"] = true
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
		if node in _struck or not blade.intersects(_enemy_box(viking)):
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
	_freeze = HIT_FREEZE
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
			if not spent and _enemy_box(viking).grow(10).has_point(at):
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
		node.position.x += viking["dir"] * (RAT_SPEED if viking.get("kind", "") == "rat" else VIKING_SPEED) * delta
		node.set("facing", int(viking["dir"]))


func _check_touches() -> void:
	var me := Rect2(player.position - Vector2(PLAYER_SIZE.x / 2, PLAYER_SIZE.y), PLAYER_SIZE)
	for corner in [me.position, me.position + Vector2(me.size.x, 0), me.position + me.size / 2, me.end - Vector2(me.size.x, 0), me.end - Vector2(0, 1)]:
		match tile_at(corner):
			"a":
				_set_tile(corner, " ")
				apples += 1
				_play("apple")
			"K":
				_set_tile(corner, " ")
				keys += 1
				_play("checkpoint")
				_hud.queue_redraw()
			"x":
				_hit(false)
			"C":
				checkpoint = Vector2((floori(corner.x / TILE) + 0.5) * TILE, (floori(corner.y / TILE) + 1) * TILE)
				_play("checkpoint")
				_set_tile(corner, "c")
			"D":
				# The castle's exit door is opened with F instead (see use()).
				if not dungeon:
					_win()
					return
	for viking in vikings.duplicate():
		var node: Node2D = viking["node"]
		var them := _enemy_box(viking)
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
	if not fell:
		_freeze = HIT_FREEZE * 1.5
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
	elif event is InputEventKey and event.physical_keycode == KEY_L and (_art_sets.size() > 1 or (dungeon and not _pieces.is_empty())):
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
	var span := _visible_columns()
	for chunk in _chunks:
		if chunk["dirty"] and chunk["span"].y > span.x - STATIC_CHUNK and chunk["span"].x < span.y + STATIC_CHUNK:
			chunk["dirty"] = false
			for node in chunk["nodes"]:
				node.queue_redraw()
	_tiles.queue_redraw()
	_hints.queue_redraw()
	_hud.queue_redraw()
	_background.queue_redraw()
	_foreground.queue_redraw()
	if dungeon and not _outside.is_empty():
		_windows.queue_redraw()
	_overlay.queue_redraw()
	if dungeon and _drakkar:
		_drakkar.queue_redraw()
	if _player_light and player:
		_player_light.position = player.position + Vector2(0, -50)
		var flicker := 0.9 + 0.1 * sin(_anim * 9.0) * sin(_anim * 5.3)
		for light in _torch_lights:
			light.energy = 1.3 * flicker


func _visible_columns() -> Vector2i:
	var width := SCREEN.x / (_camera.zoom.x if _camera else VIEW_ZOOM)
	var left := _camera.get_screen_center_position().x - width / 2 if _camera else 0.0
	return Vector2i(maxi(floori(left / TILE) - 1, 0), floori((left + width) / TILE) + 2)


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
	for art_name in LEVEL_ART_SETS:
		var dir: String = LEVEL_ART_SETS[art_name]
		if FileAccess.file_exists(dir + "level.json"):
			var art_set := _load_art_set(dir)
			art_set["name"] = art_name
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
	if dungeon:
		_load_castle()
		if _drakkar:
			_drakkar.queue_redraw()
	if _static:
		_redraw_static()
	_redraw()


## Next art set; the choice is saved with the settings.
func next_art_set() -> void:
	# In the castle L switches between its chunky and its finer pieces.
	if dungeon and not _pieces.is_empty():
		Game.castle_detail = "grube" if Game.castle_detail == "drobne" else "drobne"
		Game.save_settings()
		use_level_art()
		return
	if _art_sets.is_empty():
		return
	_art = _art_sets[(_art_sets.find(_art) + 1) % _art_sets.size()]
	Game.level_art = _art["name"]
	Game.save_settings()
	_redraw_static()
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
			"fill": texture.get_image().get_pixel(0, 0),
			"fill_bottom": texture.get_image().get_pixel(0, texture.get_height() - 1)})
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
	# One pixel bigger than the cell, so at an uneven zoom no hairline of background shows between
	# neighbouring tiles.
	_drawing.draw_texture_rect_region(texture, Rect2(at, Vector2(minf(TILE, size.x), size.y) + Vector2.ONE), Rect2(x, 0, minf(TILE, size.x), size.y))


## Each layer repeats sideways and moves at its own share of the camera's speed; the first one also
## fills the sky above it with its top colour. Up and down the layers stay on the ground Wiesław
## starts on (_horizon): "bottom" and "top" are where they sit when that ground is GROUND_LINE
## from the top of the screen.
## "haze" lays a veil of the haze colour over a layer and all behind it, so far
## things fade into the air.
func _draw_art_background(scroll: float) -> void:
	_draw_layers(_background, _art["background"], scroll, true)


## Where the starting ground is on the screen.
func _ground_line() -> float:
	if not _camera:
		return GROUND_LINE
	return (_horizon - _camera.get_screen_center_position().y) * VIEW_ZOOM + SCREEN.y / 2


## Where a layer's ground is on the screen. Near layers stand on the starting ground; far ones
## (mountains, clouds) move up and down by only their "follow" share, so high up in the sky they
## are still in view.
func _layer_ground(follow: float) -> float:
	var share := 1.0 if follow >= 0.75 else follow
	return GROUND_LINE + (_ground_line() - GROUND_LINE) * share


## Clouds high over the level (and stars at night), seen when the camera goes up above the trees.
func _draw_sky(v: Node2D, scroll: float) -> void:
	var ground := _layer_ground(0.35)
	if night:
		for k in 60:
			var star := Vector2(fposmod(k * 397.0 - scroll * 0.02, SCREEN.x), ground - 900.0 - fposmod(k * 211.0, 900.0) * VIEW_ZOOM)
			if star.y > -4.0 and star.y < SCREEN.y:
				var twinkle := 0.6 + 0.4 * sin(_anim * 2.0 + k)
				v.draw_rect(Rect2(star.round(), Vector2(3, 3)), Color(1.0, 1.0, 0.9, twinkle))
	var light := Color("f4f1ea")
	var shade := Color("cfd3dd")
	for k in 9:
		var width := 180.0 + float((k * 53) % 120)
		var at := Vector2(fposmod(k * 433.0 - scroll * (0.04 + 0.01 * (k % 3)), SCREEN.x + width * 2) - width,
			ground - (720.0 + float((k * 157) % 520)) * VIEW_ZOOM)
		if at.y < -120.0 or at.y > SCREEN.y + 60.0:
			continue
		# A flat-bottomed cloud of a few puffs, its underside a shade darker.
		v.draw_rect(Rect2(at + Vector2(0, -24), Vector2(width, 30)), shade)
		for puff in 4:
			var r := 26.0 + float((k + puff * 7) % 4) * 9.0
			var c := at + Vector2(width * (0.18 + 0.22 * puff), -26.0 - r * 0.4)
			v.draw_circle(c, r, light)
		v.draw_rect(Rect2(at + Vector2(6, -32), Vector2(width - 12, 22)), light)


func _draw_layers(v: Node2D, layers: Array, scroll: float, fill_sky: bool) -> void:
	for i in layers.size():
		var layer: Dictionary = layers[i]
		var texture: Texture2D = layer["texture"]
		var size: Vector2 = texture.get_size() * layer.get("scale", _art["scale"])
		var y: float = (layer["top"] if layer["top"] >= 0.0 else layer["bottom"] - size.y)
		y = _layer_ground(layer["follow"]) + (y - GROUND_LINE) * VIEW_ZOOM
		size *= VIEW_ZOOM
		if i == 0 and fill_sky:
			v.draw_rect(Rect2(0, 0, SCREEN.x, y + 1), layer["fill"])
			# Below the farthest picture too, when the camera is high and it has risen off the ground.
			v.draw_rect(Rect2(0, y + size.y - 1, SCREEN.x, maxf(SCREEN.y - y - size.y + 1, 0.0)), layer["fill_bottom"])
			_draw_sky(v, scroll)
		var step: float = size.x + layer["gap"] * VIEW_ZOOM
		var offset: float = scroll * layer["speed"] * VIEW_ZOOM
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
	if dungeon and not _outside.is_empty() and _camera:
		# The castle stands in the landscape seen through its windows: it shows over the roof and
		# past the side walls.
		_draw_sky_over_castle(v, scroll)
		return
	if dungeon:
		# A far stone wall behind the corridors, scrolling slowly.
		v.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("1c191b"))
		var shift := fposmod(scroll * 0.3, 96.0)
		for row in 16:
			var y := row * 48.0
			var offset := 48.0 if row % 2 else 0.0
			v.draw_line(Vector2(0, y), Vector2(SCREEN.x, y), Color("131113"), 3.0)
			for k in 16:
				var x := k * 96.0 - shift + offset
				v.draw_line(Vector2(x, y), Vector2(x, y + 48), Color("131113"), 3.0)
		return
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


## Where a landscape layer's top left corner is in the level now. A layer lags behind the camera
## sideways by (1 - its speed). Up and down all layers lag the same, so they stay stacked as drawn
## and no gaps open between them, unless a layer has its own "vertical_speed" (1 keeps a near
## layer standing on the ground); at the starting camera height their horizon row is the castle's
## base.
func _layer_origin(layer: Dictionary) -> Vector2:
	var camera := _camera.get_screen_center_position() if _camera else Vector2(0, _horizon - 80.0)
	var lag := 1.0 - float(layer["speed"])
	var rise: float = layer["rise"] if layer["rise"] >= 0.0 else _outside_rise
	return Vector2(lag * camera.x, (1.0 - rise) * (camera.y - (_horizon - 80.0)) + _horizon - float(layer["horizon"]))


## The landscape around the castle, over its roof and past its side walls: the layers far to near,
## each repeated sideways, then the earth in front from the castle's base down.
func _draw_sky_over_castle(v: Node2D, _scroll: float) -> void:
	var zoom := _camera.zoom.x
	var center := _camera.get_screen_center_position()
	var to_screen := func(at: Vector2) -> Vector2: return (at - center) * zoom + SCREEN / 2.0
	v.draw_rect(Rect2(Vector2.ZERO, SCREEN), _outside_sky)
	var bottom := SCREEN.y
	for layer in _outside:
		var texture: Texture2D = layer["texture"]
		var size := texture.get_size() * zoom
		var corner: Vector2 = to_screen.call(_layer_origin(layer))
		var x := fposmod(corner.x, size.x) - size.x
		while x < SCREEN.x:
			v.draw_texture_rect(texture, Rect2(x, corner.y, size.x, size.y), false)
			x += size.x
		bottom = corner.y + size.y
	if bottom < SCREEN.y:
		v.draw_rect(Rect2(0, bottom, SCREEN.x, SCREEN.y - bottom), _outside_ground)
	if not _soil:
		return
	var top: Vector2 = to_screen.call(Vector2(0, _horizon))
	if top.y - _soil_top_above * zoom >= SCREEN.y:
		return
	var tile := _soil.get_size() * zoom
	var y := maxf(top.y, top.y + floorf((0.0 - top.y) / tile.y) * tile.y)
	while y < SCREEN.y:
		var x := fposmod(top.x, tile.x) - tile.x
		while x < SCREEN.x:
			v.draw_texture_rect(_soil, Rect2(x, y, tile.x, tile.y), false)
			x += tile.x
		y += tile.y
	if _soil_top:
		var edge := _soil_top.get_size() * zoom
		var x := fposmod(top.x, edge.x) - edge.x
		while x < SCREEN.x:
			v.draw_texture_rect(_soil_top, Rect2(x, top.y - _soil_top_above * zoom, edge.x, edge.y), false)
			x += edge.x
	# Like the castle stone, the earth fades to black a little under the grass.
	var fade_from := top.y + 1.0 * TILE * zoom
	var fade_to := top.y + 3.5 * TILE * zoom
	if fade_from < SCREEN.y:
		var clear := Color(ROCK_INK, 0.0)
		var dark := Color(ROCK_INK, ROCK_DARK[-1])
		v.draw_polygon(PackedVector2Array([Vector2(0, fade_from), Vector2(SCREEN.x, fade_from), Vector2(SCREEN.x, fade_to), Vector2(0, fade_to)]),
			PackedColorArray([clear, clear, dark, dark]))
		if fade_to < SCREEN.y:
			v.draw_rect(Rect2(0, fade_to, SCREEN.x, SCREEN.y - fade_to), dark)


## Which part of the castle a row of tile corners is in: the halls above the starting ground, the
## dungeons under it, and the deep dungeons in the lower half of what is under it, when they have
## their own sheet.
func _castle_part(row: int) -> String:
	if row * TILE <= _horizon:
		return "hall"
	if _castle.has("deep") and row * TILE > (_horizon + map.size() * TILE) / 2.0:
		return "deep"
	return "dungeon"


## A dungeon wall cell: dark bricks below the starting ground, the castle's lighter halls above it.
## Which castle wall picture a row has ("" when the castle has no drawn walls).
func _wall_picture(row: int) -> String:
	var hall := (row + 1) * TILE <= _horizon
	var deep := not hall and _castle_part(row + 1) == "deep" and _pieces.has("wall_deep")
	var kind := "wall_hall" if hall else ("wall_deep" if deep else "wall_dungeon")
	return kind if _pieces.has(kind) else ""


## A column of castle wall cells from row run.x to run.y, all with the same picture.
func _draw_wall_run(v: Node2D, col: int, run: Vector2i) -> void:
	var kind := _wall_picture(run.x)
	var picture: Texture2D = _pieces[kind]
	var at := Vector2(col * TILE, run.x * TILE)
	var size := picture.get_size()
	var height := (run.y - run.x + 1) * TILE
	var region := Rect2(fposmod(at.x, size.x), fposmod(at.y, size.y), TILE, height)
	v.draw_texture_rect_region(picture, Rect2(at, Vector2(TILE + 1, height + 1)), region, HALL_WALL_SHADE if kind == "wall_hall" else Color.WHITE)


func _draw_wall(v: Node2D, row: int, col: int) -> void:
	var hall := (row + 1) * TILE <= _horizon
	var at := Vector2(col * TILE, row * TILE)
	var deep := not hall and _castle_part(row + 1) == "deep" and _pieces.has("wall_deep")
	var picture: Texture2D = _pieces.get("wall_hall" if hall else ("wall_deep" if deep else "wall_dungeon"))
	if picture:
		# The picture repeats every few cells; each cell shows its own part of it.
		var size := picture.get_size()
		var region := Rect2(fposmod(at.x, size.x), fposmod(at.y, size.y), TILE, TILE)
		v.draw_texture_rect_region(picture, Rect2(at, Vector2(TILE + 1, TILE + 1)), region, HALL_WALL_SHADE if hall else Color.WHITE)
		return
	v.draw_texture(_brick_texture("hall" if hall else "wall", 0), at)


## A 64 x 64 picture of a wall or stone cell, made once: one picture drawn per cell is far
## cheaper than its bricks drawn line by line. "stone" comes in two, its joints offset by column.
func _brick_texture(kind: String, variant: int) -> Texture2D:
	var key := "%s%d" % [kind, variant]
	if _bricks.has(key):
		return _bricks[key]
	var fill: Color = {"hall": HALL, "wall": WALL, "stone": STONE}[kind]
	var mortar: Color = {"hall": HALL_MORTAR, "wall": WALL_MORTAR, "stone": MORTAR}[kind]
	var width := 3 if kind == "stone" else 2
	var image := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(fill)
	for half in 2:
		var y := half * 32
		image.fill_rect(Rect2i(0, y, TILE, width), mortar)
		var x: int
		if kind == "stone":
			x = 20 if (half + variant) % 2 else 44
		else:
			x = 16 if half % 2 else 48
		image.fill_rect(Rect2i(x - width / 2, y, width, 32), mortar)
	_bricks[key] = ImageTexture.create_from_image(image)
	return _bricks[key]


## Whether these cells of a column are all open (not ground).
func _open(col: int, from_row: int, to_row: int) -> bool:
	if from_row < 0 or to_row >= map.size():
		return false
	for row in range(from_row, to_row + 1):
		if map[row][col] == "#":
			return false
	return true


## Things on the dungeon walls, drawn over the bricks: big arched windows and banners in the halls.
func _draw_wall_things(v: Node2D, span: Vector2i) -> void:
	for col in range(span.x, mini(span.y, map[0].length())):
		for row in range(1, map.size() - 1):
			if map[row][col] == "#" or not (_ground_above(row, col) or map[row][col] in ["o", "b"]):
				continue
			var at := Vector2(col * TILE, row * TILE)
			var hall := (row + 1) * TILE <= _horizon
			var banner_here := map[row][col] == "b" if _by_hand("b") else hall and col % 12 == 0 and map[row - 1][col] == "#" and _open(col, row, row + 3)
			var on_floor := map[row + 1][col] == "#"
			if _hall_window(row, col) and not _outside.is_empty():
				pass  # Drawn by _draw_windows, with the view outside.
			elif _hall_window(row, col) and _pieces.has("window"):
				var window: Texture2D = _pieces["window"]
				# The picture already shows the night outside, so it is not tinted.
				v.draw_texture(window, at + Vector2(TILE - window.get_width() / 2.0, TILE - 40 - window.get_height()))
			elif hall and col % 12 == 6 and on_floor and not _by_hand("o") and _open(col, row - 5, row) and _open(col + 1, row - 5, row):
				# A tall arched window, two tiles wide, a step above the floor.
				var sky := Color("2a3a66") if night else Color("9fc6e0")
				var frame := Color("2a2622")
				var box := Rect2(at + Vector2(8, -4 * TILE + 40), Vector2(2 * TILE - 16, 3 * TILE))
				v.draw_rect(box.grow(8), frame)
				v.draw_circle(Vector2(box.get_center().x, box.position.y), box.size.x / 2 + 8, frame)
				v.draw_rect(box, sky)
				v.draw_circle(Vector2(box.get_center().x, box.position.y), box.size.x / 2, sky)
				v.draw_line(Vector2(box.get_center().x, box.position.y - box.size.x / 2), Vector2(box.get_center().x, box.end.y), frame, 5.0)
				for k in [1.0, 2.0]:
					var y: float = box.position.y + box.size.y * k / 3.0
					v.draw_line(Vector2(box.position.x, y), Vector2(box.end.x, y), frame, 5.0)
				v.draw_rect(Rect2(box.position.x - 14, box.end.y + 8, box.size.x + 28, 10), Color("4a4440"))
			elif banner_here and _pieces.has("banner"):
				var banner: Texture2D = _pieces["banner"]
				# Hung a little below the ceiling, so the rod is not hidden in the stone.
				v.draw_texture(banner, at + Vector2(TILE / 2.0 - banner.get_width() / 2.0, 40))
			elif banner_here:
				# A long banner of the prince's house, hanging from the ceiling.
				var top := at + Vector2(32, 6)
				v.draw_rect(Rect2(top + Vector2(-28, -4), Vector2(56, 6)), Color("4a3020"))
				v.draw_colored_polygon(PackedVector2Array([top + Vector2(-22, 0), top + Vector2(22, 0), top + Vector2(22, 150), top + Vector2(0, 130), top + Vector2(-22, 150)]), Color("8a2630"))
				v.draw_rect(Rect2(top + Vector2(-22, 0), Vector2(44, 6)), Color("f2c14e"))
				v.draw_circle(top + Vector2(0, 55), 12, Color("f2c14e"))
				v.draw_circle(top + Vector2(0, 55), 6, Color("8a2630"))


## The torches on the dungeon walls, a step above the floor; they flicker, so they are drawn every
## frame, not with the walls.
func _torch_here(row: int, col: int) -> bool:
	if _by_hand("f"):
		return map[row][col] == "f"
	if col % 7 != 3 or row < 1 or row + 2 >= map.size():
		return false
	if map[row][col] == "#" or map[row + 1][col] == "#" or map[row + 2][col] != "#" or not _ground_above(row, col):
		return false
	# None over a hall window or banner (see _draw_wall_things).
	return not ((row + 2) * TILE <= _horizon and col % 12 in [11, 0, 1, 5, 6, 7, 8] and not _pieces.is_empty())


func _draw_torches(v: Node2D, span: Vector2i) -> void:
	for col in range(span.x, mini(span.y, map[0].length())):
		if col % 7 != 3 and not _by_hand("f"):
			continue
		for row in range(1, map.size() - 2):
			if not _torch_here(row, col):
				continue
			var at := Vector2(col * TILE, row * TILE)
			var flicker := 0.85 + 0.15 * sin(_anim * 9.0 + col) * sin(_anim * 5.3 + row)
			var base := at + Vector2(32, 40)
			v.draw_circle(base + Vector2(0, -18), 70 * flicker, Color(1.0, 0.6, 0.2, 0.08))
			v.draw_circle(base + Vector2(0, -18), 34 * flicker, Color(1.0, 0.7, 0.3, 0.12))
			if not _torch_frames.is_empty():
				var frame: Texture2D = _torch_frames[int(_anim * 10.0 + col) % _torch_frames.size()]
				v.draw_texture(frame, base + Vector2(-frame.get_width() / 2.0, 30 - frame.get_height()))
				continue
			v.draw_rect(Rect2(base + Vector2(-4, -6), Vector2(8, 22)), Color("4a3020"))
			v.draw_rect(Rect2(base + Vector2(-9, -8), Vector2(18, 5)), Color("2a2a2a"))
			var tip := base + Vector2(sin(_anim * 7.0 + col) * 2.0, -26 * flicker)
			v.draw_colored_polygon(PackedVector2Array([base + Vector2(-8, -8), tip, base + Vector2(8, -8)]), Color("ff9a2e"))
			v.draw_colored_polygon(PackedVector2Array([base + Vector2(-4, -8), base.lerp(tip, 0.7), base + Vector2(4, -8)]), Color("ffe08a"))


func _load_castle() -> void:
	_hand_placed.clear()
	_castle.clear()
	_pieces.clear()
	_torch_frames.clear()
	_door_frames.clear()
	_outside.clear()
	_soil = null
	_soil_top = null
	_soil_top_above = 0.0
	_window_glass.clear()
	var dir := CASTLE_DIR
	if Game.castle_detail == "drobne" and ResourceLoader.exists(CASTLE_DIR_FINE + "tileset.png"):
		dir = CASTLE_DIR_FINE
	# The halls, the dungeons under them and, when there is a sheet for it, the deepest dungeons.
	for set_name in ["hall", "dungeon", "deep"]:
		var file: String = {"hall": "tileset", "dungeon": "lochy", "deep": "gleboko"}[set_name]
		var spec_path: String = dir + ("tiles" if set_name == "hall" else file) + ".json"
		if not ResourceLoader.exists(dir + file + ".png") or not FileAccess.file_exists(spec_path):
			continue
		var spec = JSON.parse_string(FileAccess.get_file_as_string(spec_path))
		if not spec is Dictionary:
			continue
		var size := float(spec.get("tile", TILE))
		var masks := {}
		for key in spec["masks"]:
			var rects: Array[Rect2] = []
			for cell in spec["masks"][key]:
				rects.append(Rect2(cell[0] * size, cell[1] * size, size, size))
			masks[int(key)] = rects
		_castle[set_name] = {"sheet": load(dir + file + ".png"), "masks": masks}
	for piece in CASTLE_PIECES:
		if ResourceLoader.exists(dir + piece + ".png"):
			_pieces[piece] = load(dir + piece + ".png")
	while ResourceLoader.exists(dir + "door_%d.png" % _door_frames.size()):
		_door_frames.append(load(dir + "door_%d.png" % _door_frames.size()))
	while ResourceLoader.exists(dir + "torch_%d.png" % _torch_frames.size()):
		_torch_frames.append(load(dir + "torch_%d.png" % _torch_frames.size()))
	_load_outside(dir)
	if _castle.has("hall") and not _castle.has("dungeon"):
		_castle["dungeon"] = _castle["hall"]
	elif _castle.has("dungeon") and not _castle.has("hall"):
		_castle["hall"] = _castle["dungeon"]


## The landscape layers listed in outside.json, and the window glass they show through.
func _load_outside(dir: String) -> void:
	if not _pieces.has("window") or not FileAccess.file_exists(dir + "window.json") or not FileAccess.file_exists(dir + "outside.json"):
		return
	var glass = JSON.parse_string(FileAccess.get_file_as_string(dir + "window.json"))
	var spec = JSON.parse_string(FileAccess.get_file_as_string(dir + "outside.json"))
	if not glass is Dictionary or not glass.has("glass") or not spec is Dictionary:
		return
	for layer in spec.get("layers", []):
		var path: String = dir + str(layer.get("file", "")) + ".png"
		if ResourceLoader.exists(path):
			_outside.append({"texture": load(path), "speed": float(layer.get("speed", 0.25)), "horizon": float(layer.get("horizon", 0)), "rise": float(layer.get("vertical_speed", -1.0))})
	if _outside.is_empty():
		return
	for point in glass["glass"]:
		_window_glass.append(Vector2(point[0], point[1]))
	var far: Image = _outside[0]["texture"].get_image()
	var near: Image = _outside[-1]["texture"].get_image()
	_outside_sky = far.get_pixel(0, 0)
	_outside_ground = near.get_pixel(0, near.get_height() - 1)
	for key in ["soil", "soil_top"]:
		var path: String = dir + str(spec.get(key, "")) + ".png"
		if spec.has(key) and ResourceLoader.exists(path):
			if key == "soil":
				_soil = load(path)
			else:
				_soil_top = load(path)
	_soil_top_above = float(spec.get("soil_top_above", 0))
	_outside_rise = float(spec.get("vertical_speed", 0.25))


## Whether the map places this kind of wall thing by hand (o window, f torch, b banner); a map
## without any of that letter gets them spread out on its own.
func _by_hand(letter: String) -> bool:
	if not _hand_placed.has(letter):
		_hand_placed[letter] = map.any(func(line: String) -> bool: return line.contains(letter))
	return _hand_placed[letter]


## Whether a hall window, two tiles wide, stands on the floor at this cell.
func _hall_window(row: int, col: int) -> bool:
	if _by_hand("o"):
		return map[row][col] == "o"
	return (row + 1) * TILE <= _horizon and col % 12 == 6 and map[row + 1][col] == "#" and _open(col, row - 5, row) and _open(col + 1, row - 5, row)


## The hall windows in view, each with its own part of the landscape outside behind the glass.
## The landscape lags behind the camera, so it seems far away.
func _draw_windows() -> void:
	var window: Texture2D = _pieces.get("window")
	if not dungeon or _outside.is_empty() or not window or _window_glass.size() < 3:
		return
	var span := _visible_columns()
	var origins: Array[Vector2] = []
	for layer in _outside:
		origins.append(_layer_origin(layer))
	for col in range(maxi(span.x - 3, 0), mini(span.y + 2, map[0].length())):
		if col % 12 != 6 and not _by_hand("o"):
			continue
		for row in range(1, map.size() - 1):
			if map[row][col] == "#" or not _hall_window(row, col):
				continue
			var at := Vector2(col * TILE, row * TILE) + Vector2(TILE - window.get_width() / 2.0, TILE - 40 - window.get_height())
			var points := PackedVector2Array()
			for point in _window_glass:
				points.append(at + point)
			_windows.draw_colored_polygon(points, _outside_sky)
			for i in _outside.size():
				var texture: Texture2D = _outside[i]["texture"]
				var uvs := PackedVector2Array()
				for point in points:
					uvs.append((point - origins[i]) / texture.get_size())
				_windows.draw_colored_polygon(points, Color.WHITE, uvs, texture)
			_windows.draw_texture(window, at)


func _stone_at(row: int, col: int) -> bool:
	if row < 0 or col < 0 or row >= map.size() or col >= map[row].length():
		return row >= map.size() or (row >= 0 and (col < 0 or col >= map[row].length()))
	return map[row][col] == "#"


## The drawn castle stone over the columns in view: one sheet tile on each cell corner, picked by
## which of the four cells around it are ground. A missing mask falls back to plain stone.
func _draw_castle(v: Node2D, span: Vector2i) -> void:
	for row in map.size() + 1:
		for col in range(span.x, mini(span.y, map[0].length() + 1)):
			var mask := int(_stone_at(row - 1, col - 1)) + 2 * int(_stone_at(row - 1, col)) + 4 * int(_stone_at(row, col - 1)) + 8 * int(_stone_at(row, col))
			if mask == 0:
				continue
			var tiles: Dictionary = _castle[_castle_part(row)]
			var rects: Array = tiles["masks"].get(mask, tiles["masks"].get(15, []))
			if rects.is_empty():
				continue
			var at := Rect2(col * TILE - TILE / 2.0, row * TILE - TILE / 2.0, TILE, TILE)
			if mask == 15 and rects.size() == 4:
				# The middle of the sheet is one block of 2 x 2 tiles: laid in order its stones join
				# up. Some blocks are mirrored sideways, so the wall does not look stamped; mirrored
				# sideways the rows of stones still meet the next block's.
				var flip_x := posmod(floori(col / 2.0) * 73 + floori(row / 2.0) * 151, 4) >= 2
				var flip_y := false
				var part := ((row % 2) ^ int(flip_y)) * 2 + ((col % 2) ^ int(flip_x))
				var mirror := Vector2(-1.0 if flip_x else 1.0, -1.0 if flip_y else 1.0)
				v.draw_set_transform(at.get_center(), 0.0, mirror)
				v.draw_texture_rect_region(tiles["sheet"], Rect2(-TILE / 2.0, -TILE / 2.0, TILE, TILE), rects[part])
				v.draw_set_transform(Vector2.ZERO)
				continue
			v.draw_texture_rect_region(tiles["sheet"], at, rects[(row * 7 + col * 13) % rects.size()])


## Dims the back wall and shades it next to the stone (see WALL_DIM and WALL_SHADE).
func _draw_wall_depth(v: Node2D) -> void:
	if not _wall_mesh:
		_wall_mesh = _shade_mesh(_wall_shapes())
	v.draw_mesh(_wall_mesh, null)


## The shapes of the wall shading as [corners, colours] pairs. They are worked out once per level
## and drawn as one mesh: drawn one by one they made the game stutter when the view moved on.
func _wall_shapes() -> Array:
	var shapes := []
	var clear := Color(ROCK_INK, 0.0)
	for col in map[0].length():
		for row in map.size():
			if _stone_or_hidden(row, col) or not _ground_above(row, col):
				continue
			var cell := Rect2(col * TILE, row * TILE, TILE, TILE)
			var dim := Color(ROCK_INK, WALL_DIM)
			shapes.append([PackedVector2Array([cell.position, Vector2(cell.end.x, cell.position.y), cell.end, Vector2(cell.position.x, cell.end.y)]),
				PackedColorArray([dim, dim, dim, dim])])
			var sides := {"under": _stone_or_hidden(row - 1, col), "over": _stone_or_hidden(row + 1, col)}
			for side in ["under", "over"]:
				if not sides[side]:
					continue
				var dark := Color(ROCK_INK, WALL_SHADE[side][0])
				var reach: float = WALL_SHADE[side][1] * TILE
				var edge := cell.position.y if side == "under" else cell.end.y
				var far: float = edge + reach if side == "under" else edge - reach
				shapes.append([PackedVector2Array([Vector2(cell.position.x, edge), Vector2(cell.end.x, edge), Vector2(cell.end.x, far), Vector2(cell.position.x, far)]),
					PackedColorArray([dark, dark, clear, clear])])
			for dir in [-1, 1]:
				if not _stone_or_hidden(row, col + dir):
					continue
				var dark := Color(ROCK_INK, WALL_SHADE["beside"][0])
				var edge := cell.position.x if dir < 0 else cell.end.x
				var far: float = edge - dir * WALL_SHADE["beside"][1] * TILE
				shapes.append([PackedVector2Array([Vector2(edge, cell.position.y), Vector2(far, cell.position.y), Vector2(far, cell.end.y), Vector2(edge, cell.end.y)]),
					PackedColorArray([dark, clear, clear, dark])])
	return shapes


## One mesh from four-cornered shapes with a colour on each corner.
func _shade_mesh(shapes: Array) -> ArrayMesh:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for shape in shapes:
		var corners: PackedVector2Array = shape[0]
		var tints: PackedColorArray = shape[1]
		for k in [0, 1, 2, 0, 2, 3]:
			points.append(corners[k])
			colors.append(tints[k])
	var mesh := ArrayMesh.new()
	if points.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Castle stone, or a hidden room that looks like it; outside the map counts as stone.
func _stone_or_hidden(row: int, col: int) -> bool:
	if row < 0 or row >= map.size() or col < 0 or col >= map[row].length():
		return true
	return map[row][col] == "#" or map[row][col] == "u"


## Works out _rock_depth: how far each stone cell is from open air, counting a hidden room as stone
## (it must not give itself away) and the land outside the map as stone below the starting ground.
func _measure_rock() -> void:
	_rock_depth.clear()
	var deepest := ROCK_DARK.size() - 1
	var open: Array[Vector2i] = []
	for row in map.size():
		var depths := PackedByteArray()
		depths.resize(map[row].length())
		for col in map[row].length():
			var rock: bool = map[row][col] == "#" or map[row][col] == "u"
			depths[col] = deepest if rock else 0
			if not rock:
				open.append(Vector2i(col, row))
		_rock_depth.append(depths)
	for row in map.size():
		if row * TILE < _horizon:
			for col in [-1, map[row].length()]:
				open.append(Vector2i(col, row))
	for step in range(1, deepest):
		var next: Array[Vector2i] = []
		for cell in open:
			for side in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var at: Vector2i = cell + side
				if at.y >= 0 and at.y < map.size() and at.x >= 0 and at.x < map[at.y].length() and _rock_depth[at.y][at.x] > step:
					_rock_depth[at.y][at.x] = step
					next.append(at)
		open = next


## How dark the stone is at a cell corner: the four cells around it averaged, so the darkness
## changes smoothly from cell to cell.
func _rock_dark_at(row: int, col: int) -> float:
	var sum := 0.0
	for cell in [Vector2i(col - 1, row - 1), Vector2i(col, row - 1), Vector2i(col - 1, row), Vector2i(col, row)]:
		var r: int = clampi(cell.y, 0, map.size() - 1)
		var c: int = cell.x
		if c < 0 or c >= map[r].length():
			sum += 0.0 if r * TILE < _horizon else ROCK_DARK[-1]
		else:
			sum += ROCK_DARK[_rock_depth[r][c]]
	return sum / 4.0


## Darkens the inside of the castle stone (see ROCK_DARK).
func _draw_rock_dark(v: Node2D) -> void:
	if _rock_depth.size() != map.size():
		return
	if not _rock_mesh:
		var shapes := []
		for row in map.size():
			for col in map[row].length():
				if _rock_depth[row][col] == 0:
					continue
				var corners := PackedVector2Array([Vector2(col, row), Vector2(col + 1, row), Vector2(col + 1, row + 1), Vector2(col, row + 1)])
				var colors := PackedColorArray()
				var darkest := 0.0
				for corner in corners:
					var dark := _rock_dark_at(int(corner.y), int(corner.x))
					darkest = maxf(darkest, dark)
					colors.append(Color(ROCK_INK, dark))
				if darkest <= 0.0:
					continue
				for k in 4:
					corners[k] *= TILE
				shapes.append([corners, colors])
		_rock_mesh = _shade_mesh(shapes)
	v.draw_mesh(_rock_mesh, null)


## A dungeon floor or ceiling block: grey stones, lit on the edge that faces open air.
func _draw_stone(v: Node2D, row: int, col: int) -> void:
	var at := Vector2(col * TILE, row * TILE)
	var shade := 1.0 - 0.06 * float((row * 7 + col * 13) % 3)
	v.draw_texture(_brick_texture("stone", (row * 2 + col) % 2), at, Color(shade, shade, shade))
	if row == 0 or map[row - 1][col] != "#":
		v.draw_rect(Rect2(at, Vector2(TILE, 8)), STONE_LIGHT)


## Whether there is ground in this column at or above the row.
func _ground_above(row: int, col: int) -> bool:
	if _first_ground.size() != map[0].length():
		_find_first_ground()
	return _first_ground[col] <= row


## For each column the highest row with ground (or a ladder shaft through it). The tiles are drawn
## every frame and ask this a lot, so it is worked out once per map.
func _find_first_ground() -> void:
	_first_ground.resize(map[0].length())
	for col in map[0].length():
		_first_ground[col] = map.size()
		for row in map.size():
			if col < map[row].length() and (map[row][col] == "#" or _shaft(row, col)):
				_first_ground[col] = row
				break


## A cell of a narrow hole down into a cave: ground beside it or overhead close by on the left and
## on the right, and ground at the bottom of the map under it.
func _in_hole(row: int, col: int) -> bool:
	if map[map.size() - 1][col] != "#" or row == 0:
		return false
	var left := false
	var right := false
	for side in [1, 2]:
		left = left or (col - side >= 0 and _ground_above(row, col - side))
		right = right or (col + side < map[row].length() and _ground_above(row, col + side))
	return left and right


## A ladder going down through the ground.
func _shaft(row: int, col: int) -> bool:
	return map[row][col] == "H" and col > 0 and map[row][col - 1] == "#"


## Draws one strip of the level's unmoving pictures (see _chunks): "back" the pits and the back
## walls, "middle" the things on the walls and the castle stone, "front" everything else.
## Fills _static: every strip's back layer, the wall shading, every strip's middle layer, the
## stone darkness, then every strip's front layer, so all walls are under all wall things.
func _make_chunks() -> void:
	_chunks.clear()
	var spans: Array[Vector2i] = []
	var col := 0
	while col < map[0].length():
		spans.append(Vector2i(col, col + STATIC_CHUNK))
		_chunks.append({"span": spans[-1], "nodes": [], "dirty": false})
		col += STATIC_CHUNK
	for part in ["back", "shade", "middle", "dark", "front"]:
		if part in ["shade", "dark"]:
			var whole := Node2D.new()
			whole.draw.connect(_draw_whole_level.bind(whole, part))
			_static.add_child(whole)
			continue
		for k in spans.size():
			var strip := Node2D.new()
			strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			# A run of castle wall repeats its picture downwards.
			strip.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			strip.draw.connect(_draw_static_part.bind(strip, part, spans[k]))
			_static.add_child(strip)
			_chunks[k]["nodes"].append(strip)


## The wall shading or the stone darkness, each one mesh over the whole level.
func _draw_whole_level(v: Node2D, part: String) -> void:
	if not dungeon:
		return
	if part == "shade":
		_draw_wall_depth(v)
	else:
		_draw_rock_dark(v)


## Marks every strip to be drawn again, as soon as it is in view.
func _redraw_static() -> void:
	for chunk in _chunks:
		chunk["dirty"] = true


func _draw_static_part(v: Node2D, part: String, span: Vector2i) -> void:
	_drawing = v
	match part:
		"back":
			_draw_static_back(v, span)
		"middle":
			if dungeon:
				# A window or banner reaching into the next strip is drawn whole by its own strip.
				_draw_wall_things(v, span)
			if dungeon and not _castle.is_empty():
				_draw_castle(v, span)
		"front":
			_draw_static_front(v, span)


func _draw_static_back(v: Node2D, span: Vector2i) -> void:
	# Pits: a dark hole where the bottom row has no ground.
	var bottom := map.size() - 1
	for col in range(span.x, mini(span.y, map[bottom].length())):
		if map[bottom][col] != "#":
			v.draw_rect(Rect2(col * TILE, (bottom - 1) * TILE + 16, TILE, 3 * TILE), Color("3b2a1f"))
	# Caves: a dark back wall wherever there is ground somewhere overhead, and down a hole into a
	# cave (ground overhead on both sides and the bottom closed).
	for col in range(span.x, mini(span.y, map[0].length())):
		var under_ground := false
		# Castle wall cells one above the other are drawn as one run.
		var run := Vector2i(-1, -1)
		for row in map.size():
			if map[row][col] == "#":
				under_ground = true
			elif under_ground or _shaft(row, col) or _in_hole(row, col):
				under_ground = true
				if dungeon and _wall_picture(row) != "":
					if run.x >= 0 and run.y == row - 1 and _wall_picture(run.x) == _wall_picture(row):
						run.y = row
						continue
					if run.x >= 0:
						_draw_wall_run(v, col, run)
					run = Vector2i(row, row)
					continue
				if dungeon:
					_draw_wall(v, row, col)
				else:
					v.draw_rect(Rect2(col * TILE, row * TILE, TILE + 1, TILE + 1), Color("2a1d16"))
		if run.x >= 0:
			_draw_wall_run(v, col, run)


func _draw_static_front(v: Node2D, span: Vector2i) -> void:
	var ink := Color("2b1d14")
	for row in map.size():
		for col in range(span.x, mini(span.y, map[row].length())):
			var at := Vector2(col * TILE, row * TILE)
			var cell := Rect2(at, Vector2(TILE, TILE))
			match map[row][col]:
				"#" when dungeon:
					if _castle.is_empty():
						_draw_stone(v, row, col)
				"#":
					# Grass only under the open sky, not on a cave floor.
					var top := row == 0 or (map[row - 1][col] != "#" and not _ground_above(row - 1, col) and not _in_hole(row - 1, col))
					if not _art.is_empty():
						# The deeper tile only from the third row down, where it is mostly off screen,
						# so it does not show as a dark band in a cliff.
						var deep := row >= 3 and map[row - 1][col] == "#" and map[row - 2][col] == "#" and map[row - 3][col] == "#"
						var fill := "ground_deep" if deep and _art["tiles"].has("ground_deep") else "ground"
						# Solid earth behind the tile: a drawn tile may be partly see-through, and the
						# sky must not show through the ground.
						var backing := Rect2(at + Vector2(0, 24 if top else 0), Vector2(TILE + 1, TILE + 1 - (24 if top else 0)))
						v.draw_rect(backing, Color("27161a"))
						_draw_tile("ground_top" if top else fill, at)
						continue
					v.draw_rect(cell, Color("8b5a2b"))
					if top:
						v.draw_rect(Rect2(at, Vector2(TILE, 16)), Color("5e9e3f"))
				"B" when _items.has("crate"):
					v.draw_texture(_items["crate"], at)
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
				_ when dungeon and _pieces.has(CASTLE_FURNITURE.get(map[row][col], "")):
					# Furniture stands on the floor, centred on its cell.
					var piece: Texture2D = _pieces[CASTLE_FURNITURE[map[row][col]]]
					v.draw_texture(piece, at + Vector2(TILE / 2.0 - piece.get_width() / 2.0, TILE - piece.get_height()))
				_ when dungeon and _pieces.has(CASTLE_WALL_PICTURES.get(map[row][col], "")):
					var on_wall: Texture2D = _pieces[CASTLE_WALL_PICTURES[map[row][col]]]
					v.draw_texture(on_wall, at + (Vector2(TILE, TILE) - on_wall.get_size()) / 2.0)
				_ when dungeon and _pieces.has(CASTLE_HANGING.get(map[row][col], "")):
					var hanging: Texture2D = _pieces[CASTLE_HANGING[map[row][col]]]
					v.draw_texture(hanging, at + Vector2(TILE / 2.0 - hanging.get_width() / 2.0, 0))
				"K" when _pieces.has("klucz"):
					var key_picture: Texture2D = _pieces["klucz"]
					v.draw_texture(key_picture, at + (Vector2(TILE, TILE) - key_picture.get_size()) / 2.0)
				"K":
					_draw_door_key(v, at + Vector2(TILE / 2.0, TILE / 2.0), 1.0)
				"L", "l":
					_draw_door_cell(v, row, col, at)
				"Z", "z":
					_draw_trapdoor(v, row, col, at)
				"d", "e":
					_draw_lever(v, at, map[row][col] == "e")
				"x" when dungeon and _pieces.has("spikes"):
					v.draw_texture(_pieces["spikes"], at + Vector2(0, TILE - _pieces["spikes"].get_height()))
				"x" when _items.has("thorns"):
					v.draw_texture(_items["thorns"], at + Vector2(0, TILE - _items["thorns"].get_height()))
				"C", "c" when _items.has("flag"):
					var texture: Texture2D = _items["flag_on" if map[row][col] == "c" else "flag"]
					v.draw_texture(texture, at + Vector2(8, TILE - texture.get_height()))
				"H" when dungeon and _pieces.has("ladder"):
					var ladder: Texture2D = _pieces["ladder"]
					v.draw_texture_rect_region(ladder, Rect2(at, Vector2(TILE, TILE)), Rect2(0, fposmod(at.y, ladder.get_height()), ladder.get_width(), TILE))
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
				"=" when dungeon and _pieces.has("plank"):
					v.draw_texture(_pieces["plank"], at)
				"=" when dungeon:
					v.draw_rect(Rect2(at, Vector2(TILE, 14)), Color("7a4a26"))
					v.draw_rect(Rect2(at, Vector2(TILE, 3)), Color("9a6a3a"))
					v.draw_line(at + Vector2(0, 14), at + Vector2(TILE, 14), ink, 2.0)
					v.draw_circle(at + Vector2(8, 7), 2, Color("3a2a20"))
					v.draw_circle(at + Vector2(56, 7), 2, Color("3a2a20"))
				"=":
					if not _art.is_empty():
						_draw_tile("plank", at)
						continue
					v.draw_rect(Rect2(at, Vector2(TILE, 16)), Color("a0522d"))
					v.draw_line(at + Vector2(0, 16), at + Vector2(TILE, 16), ink, 2.0)
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


func _draw_tiles() -> void:
	var v := _tiles
	var ink := Color("2b1d14")
	var span := _visible_columns()
	if dungeon:
		_draw_torches(v, span)
	_draw_opening_doors(v)
	for row in map.size():
		for col in range(span.x, mini(span.y, map[row].length())):
			var at := Vector2(col * TILE, row * TILE)
			match map[row][col]:
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
				"a" when _items.has("apple"):
					var texture: Texture2D = _items["apple"]
					v.draw_texture(texture, at + (Vector2(TILE, TILE) - texture.get_size()) / 2 + Vector2(0, sin(_anim * 3.0 + col) * 4.0))
				"a":
					var center := at + Vector2(32, 34 + sin(_anim * 3.0 + col) * 4.0)
					v.draw_circle(center, 15, Color("d62828"))
					v.draw_line(center + Vector2(0, -13), center + Vector2(3, -21), Color("5a3a1e"), 3.0)
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
			"nokey":
				var t: float = effect["time"] / 1.5
				var at: Vector2 = effect["pos"] + Vector2(-90, -30 - t * 20.0)
				var fade := Color(1, 1, 1, 1.0 - t * t)
				v.draw_string_outline(ThemeDB.fallback_font, at, "Potrzebny klucz!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, Color(1, 1, 1, 0.85 * fade.a))
				v.draw_string(ThemeDB.fallback_font, at, "Potrzebny klucz!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(Color("2b1d14"), fade.a))
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
		if effect["time"] > (1.5 if effect["kind"] == "nokey" else 0.5):
			_effects.erase(effect)
	_move_particles(delta)


## A small key in a bubble over a chest, a brother or the castle door Wiesław can use with F,
## the brother's offer while it is open, and a golden glow while the nalewka works.
func _draw_key_hints() -> void:
	if state != "" or not player:
		return
	# A health bar over every Viking who has been hit.
	for viking in vikings:
		if viking["health"] < VIKING_HEALTH and viking.get("kind", "") != "rat":
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
	elif _lever_near() != Vector2i(-1, -1):
		var lever := _lever_near()
		hints.append(["F", Vector2((lever.x + 0.5) * TILE, lever.y * TILE - 20)])
	elif _locked_door_near() != Vector2i(-1, -1):
		var cell := _locked_door_near()
		var top := cell.y
		while top > 0 and map[top - 1][cell.x] == "L":
			top -= 1
		hints.append(["F", Vector2((cell.x + 0.5) * TILE, top * TILE - 30)])
	elif _door_near():
		var door: Texture2D = _pieces.get("door")
		hints.append(["F", _drakkar.position + Vector2(0, -(door.get_height() if door else 140) - 30)])
	if not _key_frames.is_empty():
		for hint in hints:
			_draw_key_cap(hint[0], hint[1])
		_draw_ladder_hint()
		_draw_first_keys()
		return
	for hint in hints:
		var at: Vector2 = hint[1] + Vector2(0, sin(_anim * 5.0) * 3.0)
		_hints.draw_circle(at, 17, Color(1, 1, 1, 0.9))
		_hints.draw_arc(at, 17, 0.0, TAU, 24, Color("2b1d14"), 3.0)
		_hints.draw_string(ThemeDB.fallback_font, at + Vector2(-17, 8), hint[0], HORIZONTAL_ALIGNMENT_CENTER, 34, 22, Color("2b1d14"))


## Until Wiesław first climbs, W and S over the end of the first ladder he comes near, and an
## arrow blinking along the ladder from that end.
func _draw_ladder_hint() -> void:
	if learned.has("ladder"):
		return
	var col := -1
	for row in map.size():
		var at := map[row].find("H")
		if at >= 0 and (col < 0 or at < col):
			col = at
	if col < 0 or absf((col + 0.5) * TILE - player.position.x) > 5 * TILE:
		return
	var rows := []
	for row in map.size():
		if map[row][col] == "H":
			rows.append(row)
	var top := float(rows.front() * TILE)
	var bottom := float((rows.back() + 1) * TILE)
	var x := (col + 0.5) * TILE
	# Wiesław at the top sees the arrow point down the ladder, at the bottom it points up.
	var down := absf(player.position.y - top) < absf(player.position.y - bottom)
	var end := top if down else bottom
	var key := _key_frames[0].get_size() * KEY_SCALE
	var keys_at := Vector2(x, (end if down else player.position.y) - 150.0)
	_draw_key(_hints, "W", keys_at - Vector2(key.x + 2.0, key.y / 2.0), key.x, _anim)
	_draw_key(_hints, "S", keys_at - Vector2(-2.0, key.y / 2.0), key.x, _anim - 0.35)
	if fmod(_anim, 0.8) < 0.5:
		var tip := Vector2(x, end + (70.0 if down else -70.0))
		var back := -1.0 if down else 1.0
		var arrow := PackedVector2Array([tip, tip + Vector2(-20, 24 * back), tip + Vector2(-8, 24 * back), tip + Vector2(-8, 50 * back), tip + Vector2(8, 50 * back), tip + Vector2(8, 24 * back), tip + Vector2(20, 24 * back)])
		_hints.draw_colored_polygon(arrow, Color(1, 0.9, 0.5, 0.95))
		_hints.draw_polyline(arrow + PackedVector2Array([tip]), Color("3a2c1e"), 3.0)


## A key cap centred on the spot, pressed now and then, with the letter on its top moving with it.
func _draw_key_cap(letter: String, at: Vector2) -> void:
	var size := _key_frames[0].get_size() * KEY_SCALE
	_draw_key(_hints, letter, at - size / 2.0, size.x, _anim)


## One key cap with its top-left corner at the spot, stretched in the middle to the width, so a
## long key like the space bar keeps its edges. "<", ">" and "^" are drawn as arrows. While the
## time runs through the start of each KEY_PRESS_EVERY, the key goes down and back up.
func _draw_key(canvas: CanvasItem, label: String, corner: Vector2, width: float, time: float) -> void:
	var press := fposmod(time, KEY_PRESS_EVERY) / 0.5
	var index := mini(int(press * _key_frames.size()), _key_frames.size() - 1) if press < 1.0 else 0
	var frame := _key_frames[index]
	var size := frame.get_size()
	var edge := size.x * 0.375
	var height := size.y * KEY_SCALE
	var side := edge * KEY_SCALE
	canvas.draw_texture_rect_region(frame, Rect2(corner, Vector2(side, height)), Rect2(0, 0, edge, size.y))
	canvas.draw_texture_rect_region(frame, Rect2(corner + Vector2(side, 0), Vector2(width - 2 * side, height)), Rect2(edge, 0, size.x - 2 * edge, size.y))
	canvas.draw_texture_rect_region(frame, Rect2(corner + Vector2(width - side, 0), Vector2(side, height)), Rect2(size.x - edge, 0, edge, size.y))
	# The top face sits a little lower while the key is pressed.
	var middle := corner + Vector2(width / 2.0, (_key_tops[index] + 7.0) * KEY_SCALE)
	var ink := Color("3a2c1e")
	match label:
		"<", ">", "^":
			var turn: float = {"<": PI, ">": 0.0, "^": -PI / 2.0}[label]
			var arrow := PackedVector2Array([Vector2(8, 0), Vector2(-6, -8), Vector2(-6, 8)])
			for i in arrow.size():
				arrow[i] = middle + arrow[i].rotated(turn)
			canvas.draw_colored_polygon(arrow, ink)
		_:
			canvas.draw_string(ThemeDB.fallback_font, Vector2(corner.x, middle.y + 8.0), label, HORIZONTAL_ALIGNMENT_CENTER, width, 22 if label.length() == 1 else 16, ink)


## One line of key caps and what they do, centred on the spot (its top edge): groups of keys
## (an array of labels) and words. Each key is pressed a little after the one before it.
func _draw_key_line(canvas: CanvasItem, line: Array, center: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var key := _key_frames[0].get_size() * KEY_SCALE
	var ink := Color("2b1d14")
	var halo := Color(1, 1, 1, 0.85)
	var parts := []
	var total := 0.0
	for piece in line:
		if piece is Array:
			for label in piece:
				var w: float = key.x * (2.2 if label.length() > 1 else 1.0)
				parts.append(["key", label, w])
				total += w + 4.0
		elif piece == "|":
			parts.append(["gap", "", 36.0])
			total += 36.0
		else:
			var w := font.get_string_size(piece, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			parts.append(["text", piece, w])
			total += w + 10.0
	var x := center.x - total / 2.0
	var count := 0
	for part in parts:
		if part[0] == "key":
			_draw_key(canvas, part[1], Vector2(x, center.y), part[2], _anim - count * 0.35)
			count += 1
			x += part[2] + 4.0
		elif part[0] == "text":
			x += 6.0
			canvas.draw_string_outline(font, Vector2(x, center.y + key.y * 0.62), part[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, halo)
			canvas.draw_string(font, Vector2(x, center.y + key.y * 0.62), part[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
			x += part[2] + 4.0
		else:
			x += part[2]


## Keys shown the first time they are needed, standing still in the level where that is: walking
## and jumping over the start, the sword (and apples) before the first Viking, the mug at the
## brother who sold it. Each goes once it has been used.
func _draw_first_keys() -> void:
	if _start_at != Vector2.INF:
		if absf(player.position.x - _start_at.x) > 6 * TILE:
			learned["walk"] = true
		if not learned.has("walk"):
			var middle := Vector2(maxf(_start_at.x, 480.0), _start_at.y - 300.0)
			_draw_key_line(_hints, [["A", "D"], "albo", ["<", ">"], "chodzenie"], middle)
			_draw_key_line(_hints, [["W"], "albo", ["^"], "skok, w powietrzu jeszcze raz"], middle + Vector2(0, 72))
	if _first_viking_at != Vector2.INF and not learned.has("sword"):
		var line := [["Spacja"], "miecz"]
		if apples > 0:
			line.append_array(["|", ["E"], "rzut jabłkiem"])
		_draw_key_line(_hints, line, _first_viking_at + Vector2(-4 * TILE, -260))
	if mugs > 0 and not learned.has("mug"):
		for merchant in merchants:
			_draw_key_line(_hints, [["Q"], "wypij kufel"], merchant["node"].position + Vector2(0, -260))


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
	if not dungeon:
		_camera.offset = Vector2(_look, -80) + jolt
		return
	# In the castle: kept to the floor, looking down ahead of a fall, Wiesław low in the frame.
	var on_floor := player.is_on_floor() or _climbing
	# Stepping up onto a shelf, a crate or a chest does not move the camera; only stone floor does,
	# or going higher than that.
	var on_stone := tile_at(player.position + Vector2(0, 8)) == "#" or _climbing
	if on_floor and (on_stone or player.position.y > _floor_y or player.position.y < _floor_y - 3.0 * TILE):
		_floor_y = player.position.y
	elif player.position.y < _floor_y - 3.0 * TILE:
		_floor_y = player.position.y + 3.0 * TILE
	var falling := not on_floor and player.position.y > _floor_y + 8.0
	var look := clampf(player.velocity.y / 900.0, 0.0, 1.0) * FALL_LOOK if falling else 0.0
	_look_down = move_toward(_look_down, look, delta * 600.0)
	var target := (player.position.y if falling else _floor_y) + _look_down
	_camera.position = Vector2(0, target - player.position.y)
	_camera.offset = Vector2(_look, -FRAME_LOW * SCREEN.y / _camera.zoom.y) + jolt


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


## Spreads the near shapes along the level: a chain hangs from one of the ceilings in the column
## it is placed at. The same level always gets the same shapes.
func _place_near_things() -> void:
	_near_things.clear()
	if not dungeon:
		return
	var dice := RandomNumberGenerator.new()
	dice.seed = map[0].length() * 31 + map.size()
	var col := dice.randi_range(4, NEAR_EVERY.y)
	while col < map[0].length():
		var ceilings: Array[float] = []
		for row in range(1, map.size() - 1):
			if map[row][col] == "#" and map[row + 1][col] != "#":
				ceilings.append((row + 1) * TILE)
		if not ceilings.is_empty():
			_near_things.append({"kind": "chain", "pos": Vector2((col + 0.5) * TILE, ceilings[dice.randi() % ceilings.size()]),
				"seed": dice.randi(), "size": dice.randf_range(0.8, 1.25)})
		col += dice.randi_range(NEAR_EVERY.x, NEAR_EVERY.y)


## The near shapes, drawn on the screen over the level (see NEAR_PARALLAX).
func _draw_near_things() -> void:
	var v := _foreground
	var zoom := _camera.zoom.x * NEAR_PARALLAX
	var center := _camera.get_screen_center_position()
	for thing in _near_things:
		var at: Vector2 = (thing["pos"] - center) * zoom + SCREEN / 2.0
		var size: float = thing["size"] * zoom
		if at.x < -300.0 * size or at.x > SCREEN.x + 300.0 * size:
			continue
		var dice := RandomNumberGenerator.new()
		dice.seed = thing["seed"]
		match thing["kind"]:
			"chain":
				var links := dice.randi_range(7, 14)
				var sway := sin(_anim * 0.9 + float(thing["seed"] % 100)) * 0.05
				# Near chains are thick, so they read as close to the camera.
				v.draw_set_transform(at, sway, Vector2.ONE * size * 2.0)
				for k in links:
					var link := Rect2(-5.0, k * 16.0, 10.0, 20.0) if k % 2 == 0 else Rect2(-2.0, k * 16.0, 4.0, 20.0)
					v.draw_rect(link, NEAR_INK)
					v.draw_rect(Rect2(link.position.x + link.size.x - 2.0, link.position.y + 2.0, 2.0, link.size.y - 4.0), NEAR_RIM)
				# A hook at the end of the chain.
				var end := links * 16.0 + 4.0
				v.draw_arc(Vector2(0, end + 10.0), 10.0, -PI * 0.1, PI * 1.2, 10, NEAR_INK, 5.0)
				v.draw_set_transform(Vector2.ZERO)


func _draw_foreground() -> void:
	if dungeon and _camera:
		_draw_near_things()
	for p in _particles:
		if dungeon and p["leaf"]:
			continue
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
	if night or dungeon:
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
	if keys > 0:
		# The keys in hand, under the apples.
		var key_at := apples_at + Vector2(20, 34)
		_draw_door_key(v, key_at, 0.8)
		v.draw_string_outline(font, key_at + Vector2(26, 9), "x%d" % keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, halo)
		v.draw_string(font, key_at + Vector2(26, 9), "x%d" % keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ink)
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
	elif state == "" and player and player.position.x < 900.0 and _key_frames.is_empty():
		message = "A/D: chodzenie     W: skok, w powietrzu jeszcze raz     W/S przy drabinie: wspinanie\nSpacja albo klik: miecz     E albo prawy klik: rzut jabłkiem     F: skrzynie, rozmowa i drzwi     Q: kufel"
	elif state == "lost":
		message = "Ojej, Wiesław stracił wszystkie serduszka!\nSpacja albo klik: jeszcze raz"
	elif state == "won" and _boss:
		message = "Oko jest Wieśka! Wikingowie oddają jabłka i drakkar."
	elif state == "won" and dungeon:
		message = "Wiesław wydostał się z lochów!"
	elif state == "won":
		message = "Hop! Wiesław dogonił drakkar!"
	if message != "":
		v.draw_multiline_string_outline(font, Vector2(0, 110), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 26, -1, 6, halo)
		v.draw_multiline_string(font, Vector2(0, 110), message, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 26, -1, ink)
