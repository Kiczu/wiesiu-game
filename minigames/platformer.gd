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
## The castle camera is close, with Wiesław drawn smaller (DUNGEON_WIESLAW) so the rooms and the
## things in them look big around him.
const DUNGEON_ZOOM := 1.0
## In the castle Wiesław stands this far below the middle of the screen (a share of its height),
## with the room above him in view.
const FRAME_LOW := 0.2
## How big Wiesław is drawn: in the castle smaller, outdoors as before.
const WIESLAW_SIZE := 0.84
const DUNGEON_WIESLAW := 0.66
## How far the camera looks down ahead of a fall, at most.
const FALL_LOOK := 2.5 * 64.0
## How quickly the castle camera catches up with a new height (higher is quicker).
const CAMERA_FALL_RATE := 9.0
const CAMERA_RISE_RATE := 4.0
## How long the game stands still when a blow lands, in seconds.
const HIT_FREEZE := 0.06
## Darkness over castle stone by how deep it is from open air: the edge stays as drawn and the
## inside fades to black, so only the places Wiesław can reach catch the eye.
const ROCK_DARK := [0.0, 0.0, 0.6, 0.88, 0.97]
## Around a flame the stone is not darkened: fully lit up to this many tiles, then darker out to
## the edge of the flame's light.
const LAMP_CLEAR := 0.5
const ROCK_INK := Color(0.02, 0.015, 0.025)
## Dark shapes close to the camera, in front of the castle: hanging chains.
## They slide past faster than the level (NEAR_PARALLAX times), which gives the castle depth.
const NEAR_PARALLAX := 1.5
const NEAR_INK := Color(0.035, 0.03, 0.045)
const NEAR_RIM := Color(0.2, 0.13, 0.1)
## One near shape about every this many tiles.
const NEAR_EVERY := Vector2i(10, 16)
## In the castle the rooms Wiesław is not in are dark (this much black over them); the room he is
## in is the open space he can walk to without going through the stone between floors. Climbing a
## ladder shaft or going down a hole, the room ahead lights up as the one behind goes dark.
const ROOM_DARK := 0.97
## How fast a room lights up or goes dark, in shares of the darkness per second.
const ROOM_FADE := 2.5
## Wiesław's own glow lifts the darkness around him this far, in tiles.
const GLOW_REACH := 2.0
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
## How dark a cellar's back wall is drawn under an orchard: the deep ground's stone, shaded.
const CELLAR_WALL := Color(0.3, 0.28, 0.33)
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
## How close in front (px) Wiesław must be for a Viking to swing his axe, and the rest between swings.
const VIKING_REACH := 110.0
const VIKING_SWING_REST := 1.0
## A Viking sees Wiesław this many tiles ahead (and hears him this close behind), stands startled
## for VIKING_NOTICE seconds, runs at him at VIKING_CHASE_SPEED and gives up VIKING_FORGET seconds
## after losing sight of him.
const VIKING_SIGHT := 7.0
const VIKING_HEAR := 2.5
const VIKING_NOTICE := 0.4
const VIKING_CHASE_SPEED := 160.0
const VIKING_FORGET := 2.5
## How long a chasing Viking takes to turn round when Wiesław gets behind him.
const VIKING_TURN := 0.3
## Rats run fast and go down with one hit.
const RAT_SPEED := 190.0
const PLAYER_SIZE := Vector2(40, 92)
## Ready-made tiles and background layers, one set per folder: level.json names the files and how
## the layers scroll. L switches between the sets that are there; without any the level is drawn
## with plain shapes.
## Keyed by the name kept in Game.level_art. "piksele" is the author's pixel-art sample board.
## A set with "night": true in its level.json is the one night levels use, and only they.
const LEVEL_ART_SETS := {"kreskowka": "res://art/platformer/level_kreskowka/", "piksele": "res://art/platformer/level_autor/",
	"sad": "res://art/platformer/sad/"}
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
## Odds and ends scattered at random (the same every time) on the castle's ceilings, floors and
## dungeon walls, listed in ozdoby.json there: see _load_decor and _place_decor.
const DECOR_DIR := CASTLE_DIR + "ozdoby/"
## No two scattered things closer than this many cells in a row.
const DECOR_GAP := 3
## Shades the near chain pictures to dark shapes close to the camera.
const NEAR_TINT := Color(0.16, 0.14, 0.18)
## Near chains show only while the camera is in their storey, fading in over this many px.
const NEAR_FADE := 96.0
## Near chains hang only in dungeon rooms at least this many cells high.
const NEAR_MIN_ROOM := 5
## Near chains swing from a point this far above the screen, the end by about NEAR_SWING px each
## way, once in about NEAR_SWING_TIME seconds.
const NEAR_SWING_FROM := 400.0
const NEAR_SWING := 22.0
const NEAR_SWING_TIME := 4.0
## Seconds between drops of water from a dungeon ceiling (random in this range), how fast they fall
## and how long a splash lasts.
const DRIP_EVERY := Vector2(2.2, 4.5)
const DRIP_FALL := 1800.0
const DRIP_SPLASH := 0.25
## The dungeons are dim; torches and a small glow around Wiesław light them.
const DUNGEON_DARK := Color(0.035, 0.03, 0.05)
const TORCH_LIGHT := Color(1.0, 0.78, 0.5)
## How far the castle lights reach, in tiles, and how strong they are: torches, braziers, the
## moonlight through a window and Wiesław's own small glow.
const LIGHT_TORCH := Vector2(5.5, 1.5)
## The brazier's flame: picture pixels to game pixels, and seconds per frame.
const FIRE_SCALE := 3.0
const FIRE_FRAME := 0.15
## Where the flame is in a wall torch picture (torch_N.png), which is put where the torch's light
## is and drawn TORCH_SCALE times its size.
const TORCH_FLAME := Vector2(93, 33)
const TORCH_SCALE := 0.75
## A torch on a hall column (pochodnia_slup_N.png), drawn this many times its size with its flame
## at PILLAR_FLAME in the picture, in the ring around the column (pochodnia_slup_obrecz.png, drawn
## as big as the column, its middle PILLAR_RING_DROP under the flame).
const PILLAR_TORCH_SCALE := 3.0
## kladka.png drawn this many times bigger, and the parts of it (in its pixels): the board's left
## end, a plain middle, its right end (each as wide as one map cell) and a bracket under the board.
const PLANK_SCALE := 4.0
## The board is drawn grey; this warms it to old wood.
const PLANK_TINT := Color(0.92, 0.74, 0.56)
const PLANK_PARTS := {"left": Rect2(12, 0, 16, 5), "middle": Rect2(22, 0, 16, 5), "right": Rect2(39, 0, 16, 5), "bracket": Rect2(16, 5, 11, 10)}
const PILLAR_FLAME := Vector2(7.5, 18)
const PILLAR_RING_SCALE := 4.0
const PILLAR_RING_DROP := 36.0
## A torch on the wall (pochodnia_sciana_N.png), drawn WALL_TORCH_SCALE times its size with its
## flame at WALL_TORCH_FLAME; beside a dungeon entrance it hangs this far off the arch's edge, when
## painted no further than ENTRANCE_TORCH_REACH from there.
const WALL_TORCH_SCALE := 2.5
const WALL_TORCH_FLAME := Vector2(9.5, 20)
const ENTRANCE_TORCH_GAP := 44.0
const ENTRANCE_TORCH_REACH := 5.0 * TILE
## How many screen pixels a castle window picture's pixel takes, unless window.json gives "scale".
const WINDOW_SCALE := 0.75
## How much lower the landscape shows in a window for each pixel the window is above the start
## ground: from upstairs the village sinks and more sky shows.
const WINDOW_HIGHER_VIEW := 0.06
## The window glass repeats the landscape sideways but stretches its top and bottom rows on,
## so a window up high shows sky above the picture and not its repeat.
const WINDOW_VIEW_SHADER := "shader_type canvas_item;\nvarying vec4 tint;\nvoid vertex() {\n\ttint = COLOR;\n}\nvoid fragment() {\n\tCOLOR = tint * texture(TEXTURE, vec2(fract(UV.x), clamp(UV.y, 0.0, 1.0)));\n}\n"
## With backdrop layers the back wall and what hangs on it (windows, banners, torches, shelves)
## slide this much slower than the level, so the rooms get depth; each wall thing sits where the
## map puts it when the camera is right in front of it.
const WALL_PLANE := 0.85
## Whether the land around the castle shows past its walls and over its roof; when not, all
## around the castle is dark stone and the land is only seen through the windows.
const LAND_AROUND_CASTLE := false
const LIGHT_FIRE := Vector2(11.0, 3.0)
const LIGHT_MOON := Vector2(6.0, 1.2)
const MOON_LIGHT := Color(0.55, 0.66, 1.0)
const LIGHT_PLAYER := Vector2(2.0, 0.35)
## A barrel (for a crate outside the castle) is drawn this many times its picture's size.
const BARREL_SCALE := 2.6
## The castle trunk (for the big chest outside the castle) is drawn at this size; its lid is this top share of the picture.
const TRUNK_SCALE := 0.8
const TRUNK_LID := 0.42
## How long a barrel or trunk rocks when Wiesław runs up to it.
const SHAKE_TIME := 0.6
## How far (level pixels) the black over another floor thins out at its edge.
const FLOOR_FADE := 3.0 * TILE
## Light goes this many pixels into stone; thicker stone stops it (see _add_occluders).
const LIT_EDGE := 96.0
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
const ITEMS := ["apple", "crate", "thorns", "flag", "flag_on", "drakkar", "heart", "heart_empty", "chest", "chest_open", "chest_royal", "chest_royal_open", "ladder", "mug"]
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
## Walking off the left edge of an outdoor level goes back to the level before (see went_back);
## without it the left edge is a wall.
var can_go_back := false
## Set when Wiesław left the level to the left, going back; finished is emitted then too.
var went_back := false
## Start at the level's way out (D) instead of P, as when coming back from the next level.
var start_at_exit := false
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
## Lights placed in the level scene (PointLight2D copies, at their place in the level) and the
## colour of its CanvasModulate (clear when it has none); see LevelMap.scene_lights.
var scene_lights: Array = []
var scene_darkness := Color(0, 0, 0, 0)
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
## The brazier's flame, frame by frame (ogien_N.png), drawn FIRE_SCALE times bigger.
var _fire_frames: Array[Texture2D] = []
## The exit door opening, from shut (door_0) to open, when there are drawn frames for it.
var _door_frames: Array[Texture2D] = []
## The night landscape around the castle, seen through the hall windows, over the roof and past
## the side walls: layers from the sky to the meadow, each {"texture", "speed", "horizon"}. Speed 1
## moves with the world and 0 stays on the screen, so the slower a layer, the farther it seems.
## Its "horizon" row lines up with the castle's base when the camera is on the starting floor.
var _outside: Array[Dictionary] = []
## The outline of the window's glass in the window picture.
var _window_glass: Array[PackedVector2Array] = []
var _window_scale := WINDOW_SCALE
## The colour the window picture is multiplied by (window.json "tint"), like the wall behind it.
var _window_tint := Color.WHITE
## Per backdrop part, where its columns stand: Vector2(spacing, middle of the first one), in the level.
var _pillars := {}
## The parts whose standing layer is columns that reach floor to ceiling (torches go on them).
var _pillar_parts := {}
var _wall_torch_frames: Array[Texture2D] = []
var _pillar_torch_frames: Array[Texture2D] = []
var _pillar_ring: Texture2D
## The plank platform picture (kladka.png): a board on two brackets, cut by PLANK_PARTS.
var _plank_board: Texture2D
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
## Outdoors at night the moon's light, kept high over the camera on the moon's side (see
## _add_night_lights).
var _moon_light: PointLight2D
## Barrel pictures drawn for crates outside the castle (zamek/ozdoby/beczka_N.png).
var _barrels: Array[Texture2D] = []
## Barrels and trunks rocking now: cell -> seconds left; and those already rocked on this approach.
var _shaking := {}
var _shaken := {}
## Black over the cellars seen from the ground, or over the ground seen from a cellar (see _add_cellar_cover).
var _cover: Node2D
## How far Wiesław has gone down into the cellars: 0 up on the ground, 1 down below.
var _below := 0.0
var _outside_dark := Color.WHITE
## The floors of a level with cellars, top to bottom: (top, bottom, where its solid bottom rows start).
var _floors: Array[Vector3] = []
## Which floor Wiesław is on, gliding in between while he goes from one to the next.
var _floor_at := 0.0
## Moonlight shining down through the holes in the surface.
var _hole_lights: Array[PointLight2D] = []
var _outside_glow := Vector2.ZERO
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
## Flames as (column, row, reach) in tiles.
var _lamps: Array[Vector3] = []
## For each lamp, the cells its light reaches: open cells, and stone only near the open side.
var _lamp_cells: Array[Dictionary] = []
## The near shapes: {"kind": "chain", "pos": where in the level, ...}.
var _near_things: Array[Dictionary] = []
## Pictures for the near chains, and how many times bigger they are drawn (ozdoby.json "blisko").
var _near_pictures: Array[Texture2D] = []
var _near_scale := 3.0
## One link of the chain that low-hanging decorations hang on, tiled down from the ceiling.
var _hang_link: Texture2D
var _hang_scale := 2.0
## The kinds of scattered things in ozdoby.json, each with its loaded "pictures".
var _decor_kinds: Array[Dictionary] = []
## The scattered things: {"picture", "rect" in the level, "on" (sufit, podloga, sciana), "col",
## "kind", "seed", "eyes"}.
var _decor: Array[Dictionary] = []
## Where water drips ("kapanie" in ozdoby.json), and the drops: {"x", "from", "to", "period", "phase"}.
var _drip_spec := {}
var _drips: Array[Dictionary] = []
## Things that shine through the dark (candle flames, eyes, water drops), over the dimmed level.
var _glow: Node2D
## The wall shading and the stone darkness, each one mesh for the whole level (made when first drawn).
var _wall_mesh: ArrayMesh
## The half-dark over the other rooms: a small picture with one pixel per cell around the camera,
## drawn stretched and smoothed over the level.
var _room_shade: Node2D
## The castle's backdrop layers by part ("hall", "dungeon"), from tlo/tlo.json (see _load_backdrops).
var _backdrops := {}
## Each backdrop layer's node and its settings, redrawn as the camera moves.
var _backdrop_nodes: Array[Dictionary] = []
## Each room's cells as a rectangle in cells (see _label_rooms).
var _room_boxes := {}
## The back wall's things, drawn every frame at the wall's pace (see WALL_PLANE).
var _wall_decor: Node2D
## The lights of wall torches and windows, which follow the wall.
var _wall_lights: Array[PointLight2D] = []
## Every castle light: only those near the view are on, as a picture takes only so many lights and
## the rest would come and go as Wiesław walks.
var _castle_lights: Array[PointLight2D] = []
var _room_image: Image
var _room_texture: ImageTexture
var _room_window := Rect2i()
## How dark each cell of the level is now.
var _room_dark := PackedFloat32Array()
## Which room or passage each cell is in (-1 for stone), the passages ({"rows", "rooms": {room:
## where it meets it}}) and the room or passage Wiesław is in.
var _room_of := PackedInt32Array()
var _passages := {}
var _room_here := -1
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
## The height the castle camera is at now, gliding to where it should be.
var _camera_y := 0.0
## Time left on the mug of nalewka: nothing hurts Wiesław.
var _shield := 0.0
## Mugs of nalewka bought from the brothers and kept for later; Q drinks one.
var mugs := 0
## F3 shows the frames per second in the corner (kept between levels).
static var show_fps := false
## The stars of a sky drawn in code: place, size, brightness and twinkle speed, made once.
var _stars: Array = []
## Apples brought from the levels before; a lost try starts again with these.
var start_apples := 0
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
	if not dungeon:
		# Outdoors only the art set's own scattered things, if it has any.
		_load_decor(_art.get("decor_dir", ""))
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
	apples = start_apples
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
	_view.modulate = _art.get("night_tint", NIGHT_TINT) if night else (DUNGEON_TINT if dungeon else Color.WHITE)
	_level = Node2D.new()
	_world.add_child(_level)
	_static = Node2D.new()
	_level.add_child(_static)
	_make_chunks()
	_windows = Node2D.new()
	_windows.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_windows.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var view := Shader.new()
	view.code = WINDOW_VIEW_SHADER
	_windows.material = ShaderMaterial.new()
	_windows.material.shader = view
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
	if start_at_exit:
		# Back from the next level: in front of the way out, facing back in.
		for row in map.size():
			var col: int = map[row].find("D")
			if col >= 0:
				checkpoint = Vector2((col - 1.5) * TILE, (row + 1) * TILE)
				_start_at = checkpoint
	_measure_rock()
	_wall_mesh = null
	_rock_mesh = null
	_place_near_things()
	_place_decor()
	_add_player()
	_add_secrets()
	_add_dungeon_lights()
	_add_scene_lights()
	_add_cellar_cover()
	_add_room_shade()
	_add_backdrops()
	# The hints sit in the level but on their own layer, so the night and the castle's darkness
	# do not dim them.
	var hint_layer := CanvasLayer.new()
	hint_layer.follow_viewport_enabled = true
	_level.add_child(hint_layer)
	_glow = Node2D.new()
	_glow.draw.connect(_draw_glow)
	hint_layer.add_child(_glow)
	_hints = Node2D.new()
	_hints.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hints.draw.connect(_draw_key_hints)
	hint_layer.add_child(_hints)
	if _music and Game.sound == "all" and not _music.playing:
		_music.play()
	set_physics_process(true)


## The darkness and lights placed in the level scene, over the ones the level makes itself; a
## light marked "migotanie" flickers like the torches.
func _add_scene_lights() -> void:
	if scene_darkness.a > 0.0:
		if not _darkness:
			_darkness = CanvasModulate.new()
			_level.add_child(_darkness)
		_darkness.color = Color(scene_darkness, 1.0)
	for template: PointLight2D in scene_lights:
		var light: PointLight2D = template.duplicate()
		_level.add_child(light)
		if light.get_meta("migotanie", false):
			light.set_meta("energy", light.energy)
			_torch_lights.append(light)


## The dim dungeon (see DUNGEON_DARK): only with the drawn castle pieces, which are made for it.
func _add_dungeon_lights() -> void:
	_torch_lights.clear()
	_wall_lights.clear()
	_castle_lights.clear()
	_player_light = null
	_moon_light = null
	_darkness = null
	if not dungeon and night:
		_add_night_lights()
		return
	if not dungeon or _pieces.is_empty():
		return
	_darkness = CanvasModulate.new()
	_darkness.color = DUNGEON_DARK
	_level.add_child(_darkness)
	var glow := _light_texture()
	for row in map.size():
		for col in map[row].length():
			if map[row][col] == "y" and _pieces.has("ogien"):
				_add_light(glow, Vector2(col * TILE + 32, row * TILE + 10), LIGHT_FIRE, TORCH_LIGHT, true)
			elif _torch_here(row, col):
				_add_wall_light(_add_light(glow, Vector2(_torch_x(row, col), row * TILE + 10), LIGHT_TORCH, TORCH_LIGHT, true), row, col)
			elif _pieces.has("window") and _hall_window(row, col):
				_add_wall_light(_add_light(glow, Vector2((col + 1) * TILE, (row + 1) * TILE - 150), LIGHT_MOON, MOON_LIGHT, false), row, col)
	for thing in _decor:
		if thing["kind"].has("flames"):
			_add_light(glow, thing["rect"].get_center(), LIGHT_TORCH, TORCH_LIGHT, true)
	_player_light = PointLight2D.new()
	_player_light.texture = glow
	_player_light.texture_scale = LIGHT_PLAYER.x * TILE * 2.0 / glow.get_width()
	_player_light.color = Color(1.0, 0.92, 0.85)
	_player_light.energy = LIGHT_PLAYER.y
	_level.add_child(_player_light)
	_add_occluders()


## Outdoors at night, when the art set has "moonlight": the level dimmed to half-dark (the sky
## behind it keeps its colours), the moon's light from high up, a faint glow around Wiesław and
## the light of scattered things whose kind has "light": [colour, reach in tiles, strength].
func _add_night_lights() -> void:
	var spec: Dictionary = _art.get("moonlight", {})
	if spec.is_empty():
		return
	_darkness = CanvasModulate.new()
	_darkness.color = Color(spec.get("dark", "6a7396"))
	_level.add_child(_darkness)
	var glow := _light_texture()
	_moon_light = PointLight2D.new()
	_moon_light.texture = glow
	_moon_light.texture_scale = float(spec.get("reach", 16.0)) * TILE * 2.0 / glow.get_width()
	_moon_light.color = Color(spec.get("color", "c8d4ff"))
	_moon_light.energy = float(spec.get("energy", 0.7))
	_moon_light.set_meta("from", Vector2(float(spec.get("from", [0.0, -450.0])[0]), float(spec.get("from", [0.0, -450.0])[1])))
	_level.add_child(_moon_light)
	var near: Array = spec.get("player", [2.5, 0.45])
	_player_light = PointLight2D.new()
	_player_light.texture = glow
	_player_light.texture_scale = float(near[0]) * TILE * 2.0 / glow.get_width()
	_player_light.color = Color(spec.get("color", "c8d4ff"))
	_player_light.energy = float(near[1])
	_level.add_child(_player_light)
	for thing in _decor:
		var light: Array = thing["kind"].get("light", [])
		if light.size() == 3:
			var lamp := _add_light(glow, thing["rect"].get_center(), Vector2(float(light[1]), float(light[2])), Color(str(light[0])),
				thing["kind"].has("flames"))
			lamp.shadow_enabled = false


## Outdoors with "cellar_dark" in the art set the level is cut into floors: the ground and each
## storey of cellars under it, split where whole rows are solid ground. Only the floor Wiesław is
## on shows; the others are black, and on the way between two floors the two cross-fade. Going
## down also darkens everything like the castle dungeon, so only lamps and his own faint glow
## light the cellars, and moonlight falls in through the holes from the surface.
func _add_cellar_cover() -> void:
	_cover = null
	_below = 0.0
	_floors.clear()
	_hole_lights.clear()
	if dungeon or not _art.has("cellar_dark") or not _darkness:
		return
	# A row is a floor's ceiling or bottom when it has no stretch of open cells wider than a hole
	# or a ladder shaft.
	var solid: Array[bool] = []
	for row in map.size():
		var widest := 0
		var run := 0
		for cell in map[row]:
			run = 0 if cell == "#" else run + 1
			widest = maxi(widest, run)
		solid.append(widest < 4)
	# Each floor reaches from halfway through the solid rows above it to halfway through those below.
	var row := 0
	var top := -100000.0
	while row < map.size():
		while row < map.size() and not solid[row]:
			row += 1
		var from := row
		while row < map.size() and solid[row]:
			row += 1
		if from >= map.size():
			break
		var split := (from + row) * TILE / 2.0
		_floors.append(Vector3(top, split, from * TILE))
		top = split
	_floors.append(Vector3(top, 100000.0, 100000.0))
	_floor_at = _floor_of(player.position.y) if player else 0.0
	_cover = Node2D.new()
	_cover.z_index = 100
	# Plain black: no light needs to fall on it.
	_cover.light_mask = 0
	_cover.draw.connect(_draw_cellar_cover)
	_level.add_child(_cover)
	_outside_dark = _darkness.color
	if _player_light:
		_outside_glow = Vector2(_player_light.texture_scale, _player_light.energy)
	# Moonlight falling in through each hole in the surface, onto the cellar under it.
	if _floors.size() > 1:
		var glow := _light_texture()
		var bottom := int(_floors[0].y / TILE)
		var colour := Color(str(_art.get("moonlight", {}).get("color", "c8d4ff")))
		var col := 0
		while col < map[bottom].length():
			if map[bottom][col] == "#":
				col += 1
				continue
			var start := col
			while col < map[bottom].length() and map[bottom][col] != "#":
				col += 1
			var light := _add_light(glow, Vector2((start + col) * TILE / 2.0, (bottom + 2) * TILE), Vector2(4.5, 0.9), colour, false)
			light.shadow_enabled = false
			_hole_lights.append(light)


## Which floor a height is on: a whole number inside a floor, in between while crossing the solid
## rows from one floor to the next.
func _floor_of(y: float) -> float:
	for k in _floors.size() - 1:
		var floor: Vector3 = _floors[k]
		var solid_end := 2.0 * floor.y - floor.z
		if y < floor.z:
			return float(k)
		if y < solid_end:
			return k + (y - floor.z) / maxf(solid_end - floor.z, 1.0)
	return float(_floors.size() - 1)


func _draw_cellar_cover() -> void:
	if not _art.get("cellar_cover", true):
		return
	# Under the level there is only ground.
	_cover.draw_rect(Rect2(-100000.0, map.size() * TILE, 200000.0, 100000.0), Color.BLACK)
	# Each other floor goes black, its edges soft: the black thins out over FLOOR_FADE towards the
	# floor Wiesław is on, so a hole or a ladder leads into the dark instead of up to a line.
	for k in _floors.size():
		var shade := clampf(absf(_floor_at - k), 0.0, 1.0)
		if shade <= 0.0:
			continue
		var floor: Vector3 = _floors[k]
		var top := floor.x
		var bottom := floor.y
		var black := Color(0, 0, 0, shade)
		var clear := Color(0, 0, 0, 0)
		var far := 100000.0
		# The fade stays inside the solid rows between the floors, so nothing of the other floor shows.
		if k > 0 and _floor_at < k:
			# Seen from above: it fades in from its top, over the lower half of the solid rows.
			var fade := minf(FLOOR_FADE, _floors[k - 1].y - _floors[k - 1].z)
			_cover_band(top - fade, top, clear, black)
		if k < _floors.size() - 1 and _floor_at > k:
			# Seen from below: it fades in from its bottom, over the upper half of the solid rows.
			var fade := minf(FLOOR_FADE, floor.y - floor.z)
			bottom = floor.z + (floor.y - floor.z) - fade
			_cover_band(bottom, bottom + fade, black, clear)
		if bottom > top:
			_cover.draw_rect(Rect2(-far, top, far * 2.0, bottom - top), black)


## A band across the whole level, its colour running from "upper" at its top to "lower" at its bottom.
func _cover_band(top: float, bottom: float, upper: Color, lower: Color) -> void:
	var far := 100000.0
	_cover.draw_polygon(PackedVector2Array([Vector2(-far, top), Vector2(far, top), Vector2(far, bottom), Vector2(-far, bottom)]),
		PackedColorArray([upper, upper, lower, lower]))


func _update_cellar_cover(delta: float) -> void:
	if not _cover or not player:
		return
	var was := _floor_at
	_floor_at = move_toward(_floor_at, _floor_of(player.position.y - 40.0), delta * 3.0)
	if is_equal_approx(was, _floor_at):
		return
	_below = clampf(_floor_at, 0.0, 1.0)
	_darkness.color = _outside_dark.lerp(_art["cellar_dark"], _below)
	if _moon_light:
		_moon_light.energy = float(_art.get("moonlight", {}).get("energy", 0.7)) * (1.0 - _below)
	if _player_light:
		var glow := _player_light.texture.get_width()
		var near: Array = _art.get("cellar_glow", [LIGHT_PLAYER.x, LIGHT_PLAYER.y])
		_player_light.texture_scale = lerpf(_outside_glow.x, float(near[0]) * TILE * 2.0 / glow, _below)
		_player_light.energy = lerpf(_outside_glow.y, float(near[1]), _below)
		_player_light.color = Color(str(_art.get("moonlight", {}).get("color", "c8d4ff"))).lerp(Color(1.0, 0.92, 0.85), _below)
	_cover.queue_redraw()


## A light in the castle; a flickering one is a flame. It shines all around, a little into the stone.
func _add_light(glow: Texture2D, at: Vector2, reach: Vector2, color: Color, flame: bool) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = glow
	light.texture_scale = reach.x * TILE * 2.0 / glow.get_width()
	light.color = color
	light.energy = reach.y
	light.position = at
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = 3.0
	light.set_meta("energy", reach.y)
	_level.add_child(light)
	_castle_lights.append(light)
	if flame:
		_torch_lights.append(light)
	return light


## A light on the back wall, which moves with it (see _wall_shift).
func _add_wall_light(light: PointLight2D, row: int, col: int) -> void:
	light.set_meta("home", light.position)
	light.set_meta("anchor", light.position.x if _torch_here(row, col) else (col + 0.5) * TILE)
	var on_pillar := _torch_here(row, col) and not is_nan(_torch_pillar(row, col))
	light.set_meta("plane", _pillar_parts[_backdrop_part(row)] if on_pillar else WALL_PLANE)
	_wall_lights.append(light)


## Light that fades like real light: bright near the flame, then slowly out to nothing at the edge.
func _light_texture() -> Texture2D:
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var away := Vector2(x + 0.5 - size / 2.0, y + 0.5 - size / 2.0).length() / (size / 2.0)
			var fade := clampf(1.0 - away, 0.0, 1.0)
			var value := pow(fade, 1.6)
			image.set_pixel(x, y, Color(1, 1, 1, value))
	return ImageTexture.create_from_image(image)


## Thick stone blocks light, so it never gets through a floor: one occluder per block of stone
## cells, pulled in from the open air by LIT_EDGE so the stone near a flame is still lit.
func _add_occluders() -> void:
	var width := map[0].length()
	var used := PackedByteArray()
	used.resize(map.size() * width)
	for row in map.size():
		for col in width:
			if used[row * width + col] or map[row][col] != "#":
				continue
			var right := col
			while right + 1 < width and map[row][right + 1] == "#" and not used[row * width + right + 1]:
				right += 1
			var bottom := row
			while bottom + 1 < map.size():
				var full := true
				for c in range(col, right + 1):
					if map[bottom + 1][c] != "#" or used[(bottom + 1) * width + c]:
						full = false
						break
				if not full:
					break
				bottom += 1
			for r in range(row, bottom + 1):
				for c in range(col, right + 1):
					used[r * width + c] = 1
			var box := Rect2(col * TILE, row * TILE, (right - col + 1) * TILE, (bottom - row + 1) * TILE)
			# Pull each side in where open air is next to it.
			var top_open := row > 0 and range(col, right + 1).any(func(c: int) -> bool: return map[row - 1][c] != "#")
			var bottom_open := bottom + 1 < map.size() and range(col, right + 1).any(func(c: int) -> bool: return map[bottom + 1][c] != "#")
			var left_open := col > 0 and range(row, bottom + 1).any(func(r: int) -> bool: return map[r][col - 1] != "#")
			var right_open := right + 1 < width and range(row, bottom + 1).any(func(r: int) -> bool: return map[r][right + 1] != "#")
			box = box.grow_individual(-LIT_EDGE if left_open else 0.0, -LIT_EDGE if top_open else 0.0, -LIT_EDGE if right_open else 0.0, -LIT_EDGE if bottom_open else 0.0)
			if box.size.x <= 0.0 or box.size.y <= 0.0:
				continue
			var shape := OccluderPolygon2D.new()
			shape.polygon = PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)])
			var occluder := LightOccluder2D.new()
			occluder.occluder = shape
			_level.add_child(occluder)


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
	_wieslaw.scale = Vector2.ONE * _wieslaw_size()
	player.add_child(_wieslaw)
	_camera = Camera2D.new()
	_camera.limit_left = 0
	# Outdoors the camera may rise a little above the highest thing in the level, into open sky.
	# Over the castle's roof the camera may show a little night sky, when there is a view outside.
	_camera.limit_top = 0 if dungeon and _outside.is_empty() else -SKY_ROWS * TILE
	if dungeon and not _outside.is_empty():
		_camera.limit_left = -OUTSIDE_SIDES * TILE
	_camera.limit_right = map[0].length() * TILE + (OUTSIDE_SIDES * TILE if dungeon and not _outside.is_empty() else 0)
	# Below an outdoor level with the castle's camera there is only black ground: room enough for
	# the camera to keep Wiesław as high in the frame on the bottom floor as on the others.
	_camera.limit_bottom = map.size() * TILE + (8 * TILE if not dungeon and _art.get("castle_camera", false) else 0)
	_camera.position_smoothing_enabled = true
	# Moves with the physics steps, which physics interpolation smooths between frames.
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.offset = Vector2(0, -80)
	_camera.zoom = Vector2.ONE * (DUNGEON_ZOOM if dungeon else VIEW_ZOOM)
	_floor_y = player.position.y
	_camera_y = player.position.y
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
	if not dungeon and not can_go_back:
		# Outdoors without a level before, the way back is closed: a wall past the left edge, from
		# high over the trees to the bottom, so Wiesław cannot walk or fall off the start.
		var wall := CollisionShape2D.new()
		wall.shape = RectangleShape2D.new()
		wall.shape.size = Vector2(TILE, (map.size() + 40) * TILE)
		wall.position = Vector2(-TILE / 2.0, (map.size() - 40) * TILE / 2.0)
		body.add_child(wall)


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
	# Only the strips around the cell are drawn again (each draws a cell past its sides).
	for chunk in _chunks:
		if chunk["span"].x <= col + 1 and chunk["span"].y >= col - 1:
			chunk["dirty"] = true
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
	_wieslaw.scale = Vector2(_wieslaw_size() * _stretch.x * _wieslaw.facing, _wieslaw_size() * _stretch.y)
	# Without a drawn swing, he leans into the blow.
	_wieslaw.rotation = _wieslaw.facing * 0.18 * sin(_attack / ATTACK_TIME * PI) if not _wieslaw.has_pose("attack") else 0.0
	_move_camera(delta)
	# Blinks after the hurt pose, while he cannot be hit again.
	_wieslaw.visible = _hurt > HURT_TIME - 0.4 or fmod(_hurt, 0.2) < 0.12
	if player.position.y > map.size() * TILE + 120:
		_hit(true)
	if can_go_back and not dungeon and player.position.x < -TILE * 0.4 and state == "":
		# Off the left edge: back to the level before.
		went_back = true
		state = "won"
		_stop_music()
		set_physics_process(false)
		finished.emit()
		return


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
	_wieslaw.scale = Vector2(_wieslaw_size() * _wieslaw.facing, _wieslaw_size())
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
		viking.erase("swing")
		node.set("pose", "hurt")
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
		if _viking_attacks(viking, delta):
			continue
		var speed := RAT_SPEED if viking.get("kind", "") == "rat" else VIKING_SPEED
		if viking.get("kind", "") != "rat" and _viking_chases(viking, delta):
			# He goes for Wiesław, but not off a ledge or into a wall: there he waits.
			speed = VIKING_CHASE_SPEED if float(viking["chase"]) <= VIKING_FORGET - VIKING_NOTICE + 0.001 else 0.0
			var front: Vector2 = node.position + Vector2(viking["dir"] * 26.0, 0)
			var below := tile_at(front + Vector2(0, 10))
			if tile_at(front + Vector2(0, -10)) in SOLID or not (below in SOLID or below == "="):
				speed = 0.0
			node.set("running", speed > 0.0)
			if node is PixelViking and node.frames_of("run") > 0:
				node.pose = "run"
				node.anim_speed = 1.0
			else:
				node.set("anim_speed", speed / VIKING_SPEED)
			node.position.x += viking["dir"] * speed * delta
			node.set("facing", int(viking["dir"]))
			continue
		node.set("running", true)
		node.set("anim_speed", 1.0)
		if node is PixelViking and node.pose == "run":
			node.pose = "walk"
		var ahead: Vector2 = node.position + Vector2(viking["dir"] * 26.0, 0)
		var wall := tile_at(ahead + Vector2(0, -10)) in SOLID
		var floor_tile := tile_at(ahead + Vector2(0, 10))
		if wall or not (floor_tile in SOLID or floor_tile == "="):
			viking["dir"] *= -1.0
		node.position.x += viking["dir"] * speed * delta
		node.set("facing", int(viking["dir"]))


## A Viking who sees Wiesław on his floor (far ahead, or close behind him) turns to him and goes
## after him, first with a start (a "!" over his head), and forgets him a while after losing sight.
## Returns whether he is after Wiesław.
func _viking_chases(viking: Dictionary, delta: float) -> bool:
	var node: Node2D = viking["node"]
	var away: Vector2 = player.position - node.position
	var ahead := signf(away.x) == signf(viking["dir"])
	var chasing := float(viking.get("chase", 0.0)) > 0.0
	# Once after Wiesław he keeps track of him all around, also over his head in a jump.
	var reach := VIKING_SIGHT if ahead or chasing else VIKING_HEAR
	var sees := state == "" and absf(away.y) < TILE * (3.0 if chasing else 1.2) and absf(away.x) < reach * TILE
	if sees:
		var row := floori((node.position.y - 10.0) / TILE)
		var from := floori(node.position.x / TILE)
		var to := floori(player.position.x / TILE)
		for col in range(mini(from, to), maxi(from, to) + 1):
			if row >= 0 and row < map.size() and col >= 0 and col < map[row].length() and map[row][col] in SOLID:
				sees = false
				break
	var chase := float(viking.get("chase", 0.0))
	if sees:
		if chase <= 0.0:
			node.set("alert", 0.8)
			chase = VIKING_FORGET
		chase = maxf(chase, VIKING_FORGET - VIKING_NOTICE)
		if absf(away.x) > 12.0 and signf(away.x) != signf(viking["dir"]):
			# Jumped over, Wiesław is behind him: he turns round after a moment.
			viking["turn"] = float(viking.get("turn", 0.0)) + delta
			if not chasing or float(viking["turn"]) >= VIKING_TURN:
				viking["dir"] = signf(away.x)
				viking["turn"] = 0.0
		else:
			viking["turn"] = 0.0
	else:
		chase = maxf(chase - delta, 0.0)
	# The start: he stands for a moment before he runs.
	if chase > VIKING_FORGET - VIKING_NOTICE:
		chase -= delta
	viking["chase"] = chase
	return chase > 0.0


## A Viking with attack frames swings his axe at Wiesław standing close in front of him, and stands
## still while he does; the blow hurts when the axe comes down. Returns whether he is swinging.
func _viking_attacks(viking: Dictionary, delta: float) -> bool:
	var node: Node2D = viking["node"]
	if not node is PixelViking or node.frames_of("attack") == 0:
		return false
	viking["rest"] = maxf(float(viking.get("rest", 0.0)) - delta, 0.0)
	var strike := PixelViking.STRIKE_FRAME / float(PixelViking.ANIM_FPS["attack"])
	if viking.has("swing"):
		var before := float(viking["swing"])
		viking["swing"] = before + delta
		if before < strike and float(viking["swing"]) >= strike and _in_axe_reach(viking):
			_hit(false)
		if float(viking["swing"]) >= node.frames_of("attack") / float(PixelViking.ANIM_FPS["attack"]):
			viking.erase("swing")
			viking["rest"] = VIKING_SWING_REST
		return true
	if viking["rest"] <= 0.0 and state == "" and _in_axe_reach(viking):
		viking["swing"] = 0.0
		node.pose = "attack"
		return true
	return false


func _in_axe_reach(viking: Dictionary) -> bool:
	var away: Vector2 = player.position - viking["node"].position
	return signf(away.x) == signf(viking["dir"]) and absf(away.x) < VIKING_REACH and absf(away.y) < TILE


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
	if node is PixelViking and node.frames_of("death") > 0:
		node.pose = "death"
		tween.tween_interval(node.frames_of("death") / float(PixelViking.ANIM_FPS["death"]) + 0.6)
	elif node is CutoutCharacter:
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
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		show_fps = not show_fps
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
	if is_instance_valid(_glow):
		_glow.queue_redraw()
	_hud.queue_redraw()
	_background.queue_redraw()
	_foreground.queue_redraw()
	if dungeon and not _outside.is_empty():
		_windows.queue_redraw()
	for light in _wall_lights:
		light.position = light.get_meta("home") + Vector2(_plane_shift_at(light.get_meta("anchor"), light.get_meta("plane")), 0)
	if _camera and not _castle_lights.is_empty():
		var half := SCREEN / _camera.zoom / 2.0
		var view := Rect2(_camera.get_screen_center_position() - half, half * 2.0)
		for light in _castle_lights:
			var reach := light.texture_scale * light.texture.get_width() / 2.0
			light.enabled = view.grow(reach).has_point(light.position)
	_overlay.queue_redraw()
	if dungeon and _drakkar:
		_drakkar.queue_redraw()
	_update_cellar_cover(get_process_delta_time())
	_shake_near(get_process_delta_time())
	if _moon_light and _camera:
		_moon_light.position = _camera.get_screen_center_position() + _moon_light.get_meta("from")
	if _player_light and player:
		_player_light.position = player.position + Vector2(0, -50)
		var flicker := 0.9 + 0.1 * sin(_anim * 9.0) * sin(_anim * 5.3)
		for light in _torch_lights:
			light.energy = float(light.get_meta("energy")) * flicker


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
	var usable := _art_sets.filter(func(art_set: Dictionary) -> bool: return art_set["night"] == night)
	if usable.is_empty():
		usable = _art_sets.filter(func(art_set: Dictionary) -> bool: return not art_set["night"])
	_art_sets.assign(usable)
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
		var entry := {"texture": texture, "mirrored": mirrored, "speed": layer.get("speed", 0.0), "top": layer.get("top", -1.0),
			"bottom": layer.get("bottom", SCREEN.y), "gap": layer.get("gap", 0.0),
			"follow": layer.get("follow", layer.get("speed", 0.0)), "haze": layer.get("haze", 0.0),
			"tint": Color(layer.get("tint", "ffffff")),
			"fill": texture.get_image().get_pixel(0, 0),
			"fill_bottom": texture.get_image().get_pixel(0, texture.get_height() - 1)}
		if layer.has("scale"):
			entry["scale"] = float(layer["scale"])
		if layer.has("mist"):
			entry["mist"] = layer["mist"]
		if layer.get("once", false):
			entry["once"] = true
		if layer.has("shift"):
			entry["shift"] = float(layer["shift"])
		layers.append(entry)
	var front := []
	for layer in spec.get("foreground", []):
		# One picture repeated, or ("files") a few pictures taken in turn at random.
		var pictures: Array[Texture2D] = []
		for file in layer.get("files", [layer.get("file", "")]):
			if ResourceLoader.exists(dir + str(file)):
				pictures.append(load(dir + str(file)))
		if pictures.is_empty():
			continue
		var texture: Texture2D = pictures[0]
		var mirrored: Texture2D = null
		if layer.get("mirror", false):
			var image := texture.get_image()
			image.flip_x()
			mirrored = ImageTexture.create_from_image(image)
		var entry := {"texture": texture, "mirrored": mirrored, "speed": layer.get("speed", 1.4), "top": layer.get("top", -1.0),
			"bottom": layer.get("bottom", SCREEN.y + 60), "gap": layer.get("gap", 0.0), "follow": layer.get("follow", 1.3), "haze": 0.0,
			"scale": layer.get("scale", 1.0), "tint": Color(layer.get("tint", "ffffff")),
			"pin": layer.get("pin", ""), "sink": layer.get("sink", 0.0)}
		if pictures.size() > 1:
			entry["pictures"] = pictures
		front.append(entry)
	var art_set := {"scale": spec.get("scale", 1.0), "tiles": tiles, "background": layers, "foreground": front,
		"haze_color": Color(spec.get("haze_color", "c9dde6")), "night": spec.get("night", false),
		"own_sky": spec.get("own_sky", false)}
	if spec.has("night_tint"):
		art_set["night_tint"] = Color(spec["night_tint"])
	if spec.get("organic", false):
		art_set["organic"] = true
	if spec.get("castle_plank", false):
		art_set["castle_plank"] = true
	if spec.has("moonlight"):
		art_set["moonlight"] = spec["moonlight"]
	# The castle's camera (kept to the floor, Wiesław low in the frame) for this outdoor level too.
	if spec.get("castle_camera", false):
		art_set["castle_camera"] = true
	if spec.get("no_fireflies", false):
		art_set["no_fireflies"] = true
	if spec.has("cellar_dark"):
		art_set["cellar_dark"] = Color(str(spec["cellar_dark"]))
		art_set["cellar_glow"] = spec.get("cellar_glow", [LIGHT_PLAYER.x, LIGHT_PLAYER.y])
		art_set["cellar_cover"] = bool(spec.get("cellar_cover", true))
	# Ground drawn from dual grid sheets like the castle's: "top" near the surface, "under" deeper.
	var ground := {}
	for part in spec.get("ground", {}):
		var sheet := _load_dual_sheet(dir + str(spec["ground"][part]))
		if not sheet.is_empty():
			ground[part] = sheet
	# A big picture tiled over the inside of the ground ("ground_fill" per part), so only the edges
	# come from the sheet and the inside does not repeat every two cells.
	var fills: Dictionary = spec.get("ground_fill", {})
	for part in fills:
		var fill: Dictionary = fills[part]
		if ground.has(part) and ResourceLoader.exists(dir + str(fill.get("file", ""))):
			ground[part]["fill"] = {"picture": load(dir + str(fill["file"])), "scale": float(fill.get("scale", 2.0)),
				"tint": Color(str(fill.get("tint", "ffffff")))}
	if ground.has("top"):
		if not ground.has("under"):
			ground["under"] = ground["top"]
		art_set["ground"] = ground
	if FileAccess.file_exists(dir + "ozdoby/ozdoby.json"):
		art_set["decor_dir"] = dir + "ozdoby/"
	# The back wall of the cellars: a picture tiled across them, its width and height whole cells.
	var wall: Dictionary = spec.get("cellar_wall", {})
	if ResourceLoader.exists(dir + str(wall.get("file", ""))):
		art_set["cellar_wall"] = {"picture": load(dir + str(wall["file"])), "scale": float(wall.get("scale", 2.0)),
			"tint": Color(str(wall.get("tint", "ffffff")))}
	# Grass hanging over the corners of the ground: "right" pictures droop to the right, "left"
	# ones to the left; each is mirrored for the other side too.
	var edges: Dictionary = spec.get("edges", {})
	var corner_pictures := []
	for side in ["right", "left"]:
		for file in edges.get(side, []):
			if ResourceLoader.exists(dir + str(file)):
				corner_pictures.append({"picture": load(dir + str(file)), "right": side == "right"})
	# Hand-drawn rims laid along the outline of soft ground: "top" (grass), "bottom" (hanging
	# roots), "side" (an earth wall, its outer face on the picture's left) and "corner" pictures.
	var rims := {}
	for kind in spec.get("rims", {}):
		var rim: Dictionary = spec["rims"][kind]
		var pictures: Array[Texture2D] = []
		for file in rim.get("files", []):
			if ResourceLoader.exists(dir + str(file)):
				pictures.append(load(dir + str(file)))
		if not pictures.is_empty():
			var at: Array = rim.get("at", [0, 0])
			rims[kind] = {"pictures": pictures, "scale": float(rim.get("scale", 1.0)), "surface": float(rim.get("surface", 0.0)),
				"at": Vector2(float(at[0]), float(at[1]))}
	if not rims.is_empty():
		art_set["rims"] = rims
		art_set["ground_dark"] = Color(str(spec.get("ground_dark", "000000")))
	var branch: Dictionary = spec.get("branch", {})
	if ResourceLoader.exists(dir + str(branch.get("file", ""))):
		var span: Array = branch.get("span", [0, 100])
		art_set["branch"] = {"texture": load(dir + str(branch["file"])), "span": Vector2(float(span[0]), float(span[1])),
			"top": float(branch.get("top", 0))}
	var hole: Dictionary = spec.get("hole", {})
	if ResourceLoader.exists(dir + str(hole.get("file", ""))):
		var at: Array = hole.get("at", [0, 0])
		art_set["hole"] = {"texture": load(dir + str(hole["file"])), "scale": float(hole.get("scale", 1.0)),
			"at": Vector2(float(at[0]), float(at[1]))}
	var near: Dictionary = spec.get("near", {}).duplicate(true)
	if near.has("ground") and ResourceLoader.exists(dir + str(near["ground"].get("file", ""))):
		near["ground"]["texture"] = load(dir + str(near["ground"]["file"]))
	if not near.is_empty():
		art_set["near"] = near
	var sky: Dictionary = spec.get("sky", {}).duplicate(true)
	if sky.has("moon") and ResourceLoader.exists(dir + str(sky["moon"].get("file", ""))):
		sky["moon"]["texture"] = load(dir + str(sky["moon"]["file"]))
	if not sky.is_empty():
		art_set["sky"] = sky
	if not corner_pictures.is_empty():
		art_set["edges"] = {"pictures": corner_pictures, "scale": float(edges.get("scale", 2.0)),
			"over": float(edges.get("over", 0.3)), "lift": float(edges.get("lift", 0.1))}
	return art_set


## A dual grid sheet (<name>.png) and its masks (<name>.json), as the castle's are kept; empty
## when either is missing.
func _load_dual_sheet(path: String) -> Dictionary:
	if not ResourceLoader.exists(path + ".png") or not FileAccess.file_exists(path + ".json"):
		return {}
	var spec = JSON.parse_string(FileAccess.get_file_as_string(path + ".json"))
	if not spec is Dictionary:
		return {}
	var size := float(spec.get("tile", TILE))
	var masks := {}
	for key in spec["masks"]:
		var rects: Array[Rect2] = []
		for cell in spec["masks"][key]:
			rects.append(Rect2(cell[0] * size, cell[1] * size, size, size))
		masks[int(key)] = rects
	return {"sheet": load(path + ".png"), "masks": masks}


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
	if night and _art.get("moonlight", {}).has("shafts"):
		_draw_moon_shafts(_background, _art["moonlight"]["shafts"])


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


## A smooth sky drawn in code: colours running down to the horizon, soft twinkling stars and the moon.
func _draw_night_sky(v: Node2D, scroll: float, sky: Dictionary) -> void:
	var top := Color(str(sky.get("top", "0b1024")))
	var bottom := Color(str(sky.get("bottom", "2a3358")))
	var middle := top.lerp(bottom, 0.45)
	var rows := PackedVector2Array([Vector2(0, 0), Vector2(SCREEN.x, 0), Vector2(SCREEN.x, SCREEN.y * 0.55), Vector2(0, SCREEN.y * 0.55)])
	v.draw_polygon(rows, PackedColorArray([top, top, middle, middle]))
	rows = PackedVector2Array([Vector2(0, SCREEN.y * 0.55), Vector2(SCREEN.x, SCREEN.y * 0.55), Vector2(SCREEN.x, SCREEN.y), Vector2(0, SCREEN.y)])
	v.draw_polygon(rows, PackedColorArray([middle, middle, bottom, bottom]))
	if _stars.is_empty():
		var random := RandomNumberGenerator.new()
		random.seed = 7
		for k in int(sky.get("stars", 140)):
			# Place across the screen (x wraps), size, how bright, how fast it twinkles.
			_stars.append([Vector2(random.randf(), pow(random.randf(), 1.6) * 0.8), pow(random.randf(), 3.0) * 2.2 + 0.8,
				random.randf_range(0.35, 1.0), random.randf_range(0.5, 2.5)])
	var star_colour := Color(str(sky.get("star_color", "fff6e0")))
	for star: Array in _stars:
		var at := Vector2(fposmod(star[0].x * SCREEN.x - scroll * 0.01 * VIEW_ZOOM, SCREEN.x), star[0].y * SCREEN.y)
		var shine: float = star[2] * (0.7 + 0.3 * sin(_anim * star[3] + at.x))
		var size: float = star[1]
		v.draw_circle(at, size * 2.6, Color(star_colour, shine * 0.12))
		v.draw_circle(at, size, Color(star_colour, shine))
		if size > 2.4:
			# The brightest few get a faint cross of light.
			var glint := Color(star_colour, shine * 0.35)
			v.draw_line(at - Vector2(size * 4.0, 0), at + Vector2(size * 4.0, 0), glint, 1.0)
			v.draw_line(at - Vector2(0, size * 4.0), at + Vector2(0, size * 4.0), glint, 1.0)
	if not sky.has("moon"):
		return
	var moon: Dictionary = sky["moon"]
	var place: Array = moon.get("at", [0.5, 0.2])
	var centre := Vector2(float(place[0]) * SCREEN.x, float(place[1]) * SCREEN.y)
	var radius := float(moon.get("radius", 64.0))
	var glow := Color(str(moon.get("glow", "c8d4ff")))
	# A soft glow: many faint circles, so no rings show.
	for ring in 24:
		v.draw_circle(centre, radius * (1.05 + ring * 0.11), Color(glow, 0.014))
	if moon.has("texture"):
		var texture: Texture2D = moon["texture"]
		var width := radius * 2.0 * float(moon.get("picture_size", 1.0))
		var size := texture.get_size() * width / texture.get_width()
		v.draw_texture_rect(texture, Rect2(centre - size / 2.0, size), false)
		return
	var face := Color(str(moon.get("color", "f3ead0")))
	v.draw_circle(centre, radius, face)
	# A few soft darker patches, like the seas on the moon.
	var patch := face.darkened(0.12)
	for spot: Vector3 in [Vector3(-0.3, -0.2, 0.28), Vector3(0.2, -0.35, 0.18), Vector3(0.15, 0.2, 0.32), Vector3(-0.35, 0.35, 0.15)]:
		v.draw_circle(centre + Vector2(spot.x, spot.y) * radius, spot.z * radius, Color(patch, 0.55))


func _draw_layers(v: Node2D, layers: Array, scroll: float, fill_sky: bool) -> void:
	for i in layers.size():
		var layer: Dictionary = layers[i]
		var texture: Texture2D = layer["texture"]
		var size: Vector2 = texture.get_size() * layer.get("scale", _art["scale"])
		var y: float = (layer["top"] if layer["top"] >= 0.0 else layer["bottom"] - size.y)
		y = _layer_ground(layer["follow"]) + (y - GROUND_LINE) * VIEW_ZOOM
		size *= VIEW_ZOOM
		var tint: Color = layer.get("tint", Color.WHITE)
		match layer.get("pin", ""):
			# Held at the screen's edge whatever the camera does, partly off the screen, and gone
			# when the camera is down in the cellars (or, at the bottom, high over the ground).
			"top", "bottom":
				var ground := _layer_ground(1.0)
				var shown := clampf(ground / (SCREEN.y * 0.35), 0.0, 1.0)
				if layer["pin"] == "bottom":
					y = SCREEN.y - size.y + float(layer["sink"]) * VIEW_ZOOM
					shown = minf(shown, clampf((SCREEN.y + 260.0 - ground) / 200.0, 0.0, 1.0))
				else:
					y = -float(layer["sink"]) * VIEW_ZOOM
				if shown <= 0.0:
					continue
				tint.a *= shown
		if i == 0 and fill_sky:
			if _art.has("sky"):
				_draw_night_sky(v, scroll, _art["sky"])
			else:
				v.draw_rect(Rect2(0, 0, SCREEN.x, y + 1), layer["fill"])
			# Below the farthest picture too, when the camera is high and it has risen off the ground.
			v.draw_rect(Rect2(0, y + size.y - 1, SCREEN.x, maxf(SCREEN.y - y - size.y + 1, 0.0)), layer["fill_bottom"])
			if not _art.get("own_sky", false):
				_draw_sky(v, scroll)
		var step: float = size.x + layer["gap"] * VIEW_ZOOM
		var offset: float = scroll * layer["speed"] * VIEW_ZOOM
		var x := -fposmod(offset, step)
		var index := floori(offset / step)
		if layer.has("shift"):
			# Moved sideways from where the copies would stand (screen pixels at the start).
			x -= float(layer["shift"]) * VIEW_ZOOM
			while x > -size.x:
				x -= step
				index -= 1
		while x < SCREEN.x:
			if layer.get("once", false) and index != 0:
				# A layer shown once, at the start of the level (the stronghold Wiesław comes from).
				x += step
				index += 1
				continue
			if layer.has("pictures"):
				# A picture of the set for each place, the same every time, standing on the layer's bottom.
				var pictures: Array = layer["pictures"]
				var picture: Texture2D = pictures[posmod(index * 7 + 3, pictures.size())]
				var shown: Vector2 = picture.get_size() * layer.get("scale", _art["scale"]) * VIEW_ZOOM
				var jitter: float = float(posmod(index * 37, 11)) / 10.0 * float(layer["gap"]) * VIEW_ZOOM * 0.5
				var flip := index % 2 != 0
				v.draw_texture_rect(picture, Rect2(Vector2(x + jitter, y + size.y - shown.y),
					Vector2(-shown.x if flip else shown.x, shown.y)), false, tint)
				x += step
				index += 1
				continue
			# Mirrored every other time, so a picture that does not repeat still joins up.
			var flipped: bool = layer["mirrored"] != null and index % 2 != 0
			v.draw_texture_rect(layer["mirrored"] if flipped else texture, Rect2(Vector2(x, y), size), false, tint)
			x += step
			index += 1
		if layer["haze"] > 0.0:
			v.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(_art["haze_color"], layer["haze"]))
		if layer.has("mist"):
			_draw_mist(v, layer["mist"], y + size.y, scroll * layer["speed"] * VIEW_ZOOM)


## A band of mist lying over a layer's foot ("mist" in level.json: [colour, strength, height]):
## thickest a little above the bottom, thinning upwards, drifting slowly in patches.
func _draw_mist(v: Node2D, mist: Array, bottom: float, offset: float) -> void:
	var colour := Color(str(mist[0]))
	var strength := float(mist[1])
	var height := float(mist[2]) * VIEW_ZOOM
	var strip := 40.0
	var x := -fposmod(offset * 0.6, strip)
	while x < SCREEN.x:
		var world := x + offset * 0.6
		var patch := 0.65 + 0.2 * sin(world * 0.0031 + _anim * 0.15) + 0.15 * sin(world * 0.0107 - _anim * 0.23)
		var thick := Color(colour, strength * patch)
		var clear := Color(colour, 0.0)
		var top := bottom - height
		var mid := bottom - height * 0.3
		v.draw_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + strip, top), Vector2(x + strip, mid), Vector2(x, mid)]),
			PackedColorArray([clear, clear, thick, thick]))
		v.draw_rect(Rect2(x, mid, strip, bottom - mid + 1.0), thick)
		x += strip


func _draw_background() -> void:
	var v := _background
	var scroll := _camera.get_screen_center_position().x if _camera else 0.0
	if dungeon and not _outside.is_empty() and not LAND_AROUND_CASTLE:
		v.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(ROCK_INK, 1.0))
		return
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
			if v == _wall_decor:
				v.draw_set_transform(Vector2(_wall_shift(row, col), 0))
			var hall := (row + 1) * TILE <= _horizon
			var banner_here := map[row][col] == "b" if _by_hand("b") else hall and col % 12 == 0 and map[row - 1][col] == "#" and _open(col, row, row + 3)
			var on_floor := map[row + 1][col] == "#"
			if _hall_window(row, col) and not _outside.is_empty():
				pass  # Drawn by _draw_windows, with the view outside.
			elif _hall_window(row, col) and _pieces.has("window"):
				var window: Texture2D = _pieces["window"]
				# The picture already shows the night outside, so it is not tinted.
				var size := window.get_size() * _window_scale
				v.draw_texture_rect(window, Rect2(at + Vector2(TILE - size.x / 2.0, TILE - 40 - size.y), size), false, _window_tint)
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
	if dungeon and not _fire_frames.is_empty():
		for col in range(span.x, mini(span.y, map[0].length())):
			for row in map.size():
				if map[row][col] != "y":
					continue
				var frame: Texture2D = _fire_frames[int(_anim / FIRE_FRAME + col) % _fire_frames.size()]
				var size := frame.get_size() * FIRE_SCALE
				v.draw_texture_rect(frame, Rect2(Vector2((col + 0.5) * TILE - size.x / 2.0, (row + 1) * TILE - size.y), size), false)
	for col in range(span.x, mini(span.y, map[0].length())):
		if col % 7 != 3 and not _by_hand("f"):
			continue
		for row in range(1, map.size() - 2):
			if not _torch_here(row, col):
				continue
			var at := Vector2(col * TILE, row * TILE)
			var flicker := 0.85 + 0.15 * sin(_anim * 9.0 + col) * sin(_anim * 5.3 + row)
			var torch_x := _torch_x(row, col)
			var base := Vector2(torch_x + _torch_shift(row, col, torch_x), at.y + 40)
			if not _pillar_torch_frames.is_empty() and not is_nan(_torch_pillar(row, col)):
				var flame := base + Vector2(0, -30)
				if _pillar_ring:
					var ring := _pillar_ring.get_size() * PILLAR_RING_SCALE
					v.draw_texture_rect(_pillar_ring, Rect2(flame + Vector2(-ring.x / 2.0, PILLAR_RING_DROP - ring.y / 2.0), ring), false)
				var torch: Texture2D = _pillar_torch_frames[int(_anim / FIRE_FRAME + col) % _pillar_torch_frames.size()]
				v.draw_texture_rect(torch, Rect2(flame - PILLAR_FLAME * PILLAR_TORCH_SCALE, torch.get_size() * PILLAR_TORCH_SCALE), false)
				continue
			if not _wall_torch_frames.is_empty():
				var torch: Texture2D = _wall_torch_frames[int(_anim / FIRE_FRAME + col) % _wall_torch_frames.size()]
				v.draw_texture_rect(torch, Rect2(base + Vector2(0, -30) - WALL_TORCH_FLAME * WALL_TORCH_SCALE, torch.get_size() * WALL_TORCH_SCALE), false)
				continue
			v.draw_circle(base + Vector2(0, -30), 48 * flicker, Color(1.0, 0.6, 0.2, 0.08))
			v.draw_circle(base + Vector2(0, -30), 34 * flicker, Color(1.0, 0.7, 0.3, 0.12))
			if not _torch_frames.is_empty():
				var frame: Texture2D = _torch_frames[int(_anim / FIRE_FRAME + col) % _torch_frames.size()]
				v.draw_texture_rect(frame, Rect2(base + Vector2(0, -30) - TORCH_FLAME * TORCH_SCALE, frame.get_size() * TORCH_SCALE), false)
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
	_pillar_torch_frames.clear()
	_pillar_ring = null
	_wall_torch_frames.clear()
	_fire_frames.clear()
	_door_frames.clear()
	_outside.clear()
	_soil = null
	_soil_top = null
	_soil_top_above = 0.0
	_window_glass.clear()
	_window_scale = WINDOW_SCALE
	_window_tint = Color.WHITE
	_backdrops.clear()
	_pillars.clear()
	_pillar_parts.clear()
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
	_barrels.clear()
	while ResourceLoader.exists(CASTLE_DIR + "ozdoby/beczka_%d.png" % (_barrels.size() + 1)):
		_barrels.append(load(CASTLE_DIR + "ozdoby/beczka_%d.png" % (_barrels.size() + 1)))
	_plank_board = load(CASTLE_DIR + "kladka.png") if ResourceLoader.exists(CASTLE_DIR + "kladka.png") else null
	if ResourceLoader.exists(CASTLE_DIR + "pochodnia_slup_obrecz.png"):
		_pillar_ring = load(CASTLE_DIR + "pochodnia_slup_obrecz.png")
	while ResourceLoader.exists(CASTLE_DIR + "pochodnia_slup_%d.png" % _pillar_torch_frames.size()):
		_pillar_torch_frames.append(load(CASTLE_DIR + "pochodnia_slup_%d.png" % _pillar_torch_frames.size()))
	while ResourceLoader.exists(CASTLE_DIR + "pochodnia_sciana_%d.png" % _wall_torch_frames.size()):
		_wall_torch_frames.append(load(CASTLE_DIR + "pochodnia_sciana_%d.png" % _wall_torch_frames.size()))
	while ResourceLoader.exists(CASTLE_DIR + "torch_%d.png" % _torch_frames.size()):
		_torch_frames.append(load(CASTLE_DIR + "torch_%d.png" % _torch_frames.size()))
	# The fine castle may lack the flame and the backdrop: then the coarse one's are used.
	var fire_dir := dir if ResourceLoader.exists(dir + "ogien_0.png") else CASTLE_DIR
	while ResourceLoader.exists(fire_dir + "ogien_%d.png" % _fire_frames.size()):
		_fire_frames.append(load(fire_dir + "ogien_%d.png" % _fire_frames.size()))
	_load_outside(dir)
	_load_backdrops((dir if FileAccess.file_exists(dir + "tlo/tlo.json") else CASTLE_DIR) + "tlo/")
	_load_decor()
	if _castle.has("hall") and not _castle.has("dungeon"):
		_castle["dungeon"] = _castle["hall"]
	elif _castle.has("dungeon") and not _castle.has("hall"):
		_castle["hall"] = _castle["dungeon"]


## The glass of a window picture: the see-through pixels the frame closes in, as polygons.
static func _glass_of(window: Texture2D) -> Array[PackedVector2Array]:
	var image := window.get_image()
	if image.is_compressed():
		image.decompress()
	var size := image.get_size()
	# See-through pixels reached from the picture's edge are outside the window; the rest is glass.
	var outside := {}
	var todo: Array[Vector2i] = []
	for x in size.x:
		todo.append(Vector2i(x, 0))
		todo.append(Vector2i(x, size.y - 1))
	for y in size.y:
		todo.append(Vector2i(0, y))
		todo.append(Vector2i(size.x - 1, y))
	while not todo.is_empty():
		var at: Vector2i = todo.pop_back()
		if at.x < 0 or at.y < 0 or at.x >= size.x or at.y >= size.y or outside.has(at) or image.get_pixelv(at).a > 0.1:
			continue
		outside[at] = true
		todo.append_array([at + Vector2i.LEFT, at + Vector2i.RIGHT, at + Vector2i.UP, at + Vector2i.DOWN])
	var mask := Image.create(size.x, size.y, false, Image.FORMAT_LA8)
	for y in size.y:
		for x in size.x:
			if image.get_pixel(x, y).a <= 0.1 and not outside.has(Vector2i(x, y)):
				mask.set_pixel(x, y, Color.WHITE)
	var bits := BitMap.new()
	bits.create_from_image_alpha(mask)
	var found: Array[PackedVector2Array] = []
	for polygon in bits.opaque_to_polygons(Rect2i(Vector2i.ZERO, size), 0.5):
		found.append(polygon)
	return found


## The landscape layers listed in outside.json, and the window glass they show through.
func _load_outside(dir: String) -> void:
	if not _pieces.has("window") or not FileAccess.file_exists(dir + "window.json"):
		return
	var glass = JSON.parse_string(FileAccess.get_file_as_string(dir + "window.json"))
	if not glass is Dictionary:
		return
	_window_scale = float(glass.get("scale", WINDOW_SCALE))
	_window_tint = Color(str(glass.get("tint", "ffffff")))
	if not FileAccess.file_exists(dir + "outside.json"):
		return
	var spec = JSON.parse_string(FileAccess.get_file_as_string(dir + "outside.json"))
	if not spec is Dictionary:
		return
	for layer in spec.get("layers", []):
		var path: String = dir + str(layer.get("file", "")) + ".png"
		if ResourceLoader.exists(path):
			_outside.append({"texture": load(path), "speed": float(layer.get("speed", 0.25)), "horizon": float(layer.get("horizon", 0)), "rise": float(layer.get("vertical_speed", -1.0)), "window": bool(layer.get("window", true))})
	if _outside.is_empty():
		return
	if glass.has("glass"):
		var points := PackedVector2Array()
		for point in glass["glass"]:
			points.append(Vector2(point[0], point[1]))
		_window_glass.append(points)
	else:
		_window_glass = _glass_of(_pieces["window"])
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
	if not dungeon or _outside.is_empty() or not window or _window_glass.is_empty():
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
			var size := window.get_size() * _window_scale
			var at := Vector2(col * TILE + _wall_shift(row, col), row * TILE) + Vector2(TILE - size.x / 2.0, TILE - 40 - size.y)
			for glass in _window_glass:
				_draw_glass(glass, at, row, origins)
			_windows.draw_texture_rect(window, Rect2(at, size), false, _window_tint)


## The view outside through one glass polygon of a window whose picture's corner is at.
func _draw_glass(glass: PackedVector2Array, at: Vector2, row: int, origins: Array[Vector2]) -> void:
	var points := PackedVector2Array()
	for point in glass:
		points.append(at + point * _window_scale)
	_windows.draw_colored_polygon(points, _outside_sky)
	# Every window looks out as if it stood on the starting ground, so a window high up
	# shows the same skyline and not the picture's repeat beyond its top.
	var lift := Vector2(0, (row + 1) * TILE - _horizon)
	for i in _outside.size():
		if not _outside[i]["window"]:
			continue
		var texture: Texture2D = _outside[i]["texture"]
		var uvs := PackedVector2Array()
		# The landscape keeps its height on screen by the layer's rise, so a window lifted away from
		# the ground sees it moved by that share of the lift, and a little lower, as seen from higher up.
		var rise: float = _outside[i]["rise"] if _outside[i]["rise"] >= 0.0 else _outside_rise
		for point in points:
			uvs.append((point - origins[i] - lift * (rise - WINDOW_HIGHER_VIEW)) / texture.get_size())
		_windows.draw_colored_polygon(points, Color.WHITE, uvs, texture)


func _stone_at(row: int, col: int) -> bool:
	if row < 0 or col < 0 or row >= map.size() or col >= map[row].length():
		return row >= map.size() or (row >= 0 and (col < 0 or col >= map[row].length()))
	return map[row][col] == "#"


## The drawn castle stone over the columns in view: one sheet tile on each cell corner, picked by
## which of the four cells around it are ground. A missing mask falls back to plain stone.
func _draw_castle(v: Node2D, span: Vector2i) -> void:
	_draw_dual_grid(v, span, func(row: int, _col: int) -> Dictionary: return _castle[_castle_part(row)])


## The sheet for a cell corner outdoors: the "top" one (earth under grass) for the first two rows
## of ground under the open sky, the "under" one (the cellars' stone) deeper down.
func _outdoor_tiles(row: int, col: int) -> Dictionary:
	var surface := map.size()
	for c in [col - 1, col]:
		var r := 0
		while r < map.size() and (c < 0 or c >= map[r].length() or map[r][c] != "#"):
			r += 1
		surface = mini(surface, r)
	return _art["ground"]["top" if row - surface <= 2 else "under"]


## Ground from a dual grid sheet over the columns in view, one sheet tile on each cell corner,
## picked by which of the four cells around it are ground; sheet_at(row, col) gives the sheet.
func _draw_dual_grid(v: Node2D, span: Vector2i, sheet_at: Callable) -> void:
	for row in map.size() + 1:
		for col in range(span.x, mini(span.y, map[0].length() + 1)):
			var mask := int(_stone_at(row - 1, col - 1)) + 2 * int(_stone_at(row - 1, col)) + 4 * int(_stone_at(row, col - 1)) + 8 * int(_stone_at(row, col))
			if mask == 0:
				continue
			var tiles: Dictionary = sheet_at.call(row, col)
			var rects: Array = tiles["masks"].get(mask, tiles["masks"].get(15, []))
			if rects.is_empty():
				continue
			var at := Rect2(col * TILE - TILE / 2.0, row * TILE - TILE / 2.0, TILE, TILE)
			if mask == 15 and tiles.has("fill"):
				_draw_tiled_piece(v, tiles["fill"], at)
				continue
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
	if _wall_mesh.get_surface_count() > 0:
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


## Reads the backdrop layers, farthest first. tlo.json gives for each part ("hall" above the
## starting ground, "dungeon" below it) a list of layers:
##   "file": the picture in tlo/; "parallax": how fast it moves with the camera (1 = with the level,
##   less = farther away); "scale": how many game pixels one picture pixel takes; "fill": true
##   repeats it in every direction (a far wall), otherwise it stands on the floor of every room;
##   "lift": how many pixels above the floor it stands; "tint": a colour it is multiplied by.
## A part with layers draws them instead of its back wall.
func _load_backdrops(dir: String) -> void:
	if not FileAccess.file_exists(dir + "tlo.json"):
		return
	var spec = JSON.parse_string(FileAccess.get_file_as_string(dir + "tlo.json"))
	if not spec is Dictionary:
		return
	for part in spec:
		var layers: Array[Dictionary] = []
		for layer in spec[part]:
			if not layer is Dictionary:
				continue
			# "file" is one picture, or a list of pictures that take turns along the wall.
			var textures: Array[Texture2D] = []
			for file in backdrop_files(layer):
				if ResourceLoader.exists(dir + file):
					textures.append(load(dir + file))
			if textures.is_empty():
				continue
			layers.append({
				"texture": textures[0],
				"textures": textures,
				"parallax": float(layer.get("parallax", 1.0)),
				"scale": float(layer.get("scale", 1.0)),
				"fill": bool(layer.get("fill", false)),
				"lift": float(layer.get("lift", 0.0)),
				"spacing": float(layer.get("spacing", 0.0)),
				"offset": float(layer.get("offset", 0.0)) * TILE,
				"stretch": layer.get("stretch", []),
				"tint": Color(str(layer.get("tint", "ffffff"))),
			})
		if not layers.is_empty():
			_backdrops[part] = layers
			for layer in layers:
				if not layer["fill"] and not _pillars.has(part):
					_pillars[part] = _pillar_spot(layer)
					if layer["stretch"].size() == 2:
						_pillar_parts[part] = float(layer["parallax"])


## Where the copies of a standing layer (columns, entrances) are, in the level as the editor's
## guides show them: Vector3(spacing, left and right edge of the first one's first solid run).
func _pillar_spot(layer: Dictionary) -> Vector3:
	var texture: Texture2D = layer["texture"]
	var scale := float(layer["scale"])
	var parallax := float(layer["parallax"])
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	var run := Vector2(-1, -1)
	for x in image.get_width():
		var solid := false
		for y in image.get_height():
			if image.get_pixel(x, y).a > 0.1:
				solid = true
				break
		if solid and run.x < 0:
			run = Vector2(x, x + 1)
		elif solid and run.y == x:
			run.y = x + 1
		elif not solid and run.x >= 0:
			break
	var spacing := backdrop_spacing(texture.get_width() * scale, parallax, layer["spacing"])
	var offset := float(layer["offset"])
	return Vector3(spacing, offset + run.x * scale / parallax, offset + run.y * scale / parallax)


## Where the flame of a wall torch painted at a cell is, sideways in the level: on the nearest
## column of a hall, or beside the nearest dungeon entrance when one is close, so it looks fixed
## to the backdrop; else on its own cell.
func _torch_x(row: int, col: int) -> float:
	var x := (col + 0.5) * TILE
	var pillar := _torch_pillar(row, col)
	if not is_nan(pillar):
		if not _pillar_torch_frames.is_empty():
			return pillar
		# The picture's middle on the column's middle (the flame is right of the middle).
		var width: float = TORCH_SCALE * (_torch_frames[0].get_width() if not _torch_frames.is_empty() else 0.0)
		return pillar + TORCH_FLAME.x * TORCH_SCALE - width / 2.0
	var mark := _nearest_mark(row, col)
	if mark.size() == 3 and mark[2] == 0.0:
		# Beside an entrance: on the side nearer to the painted cell, a little off its edge.
		var left: float = mark[0] - ENTRANCE_TORCH_GAP
		var right: float = mark[1] + ENTRANCE_TORCH_GAP
		var side := left if absf(x - left) < absf(x - right) else right
		if absf(side - x) <= ENTRANCE_TORCH_REACH and _open_between(row, col, floori(side / TILE)):
			return side
	return x


## How far a wall torch has slid sideways: with its column when it hangs on one, else with the wall.
func _torch_shift(row: int, col: int, x: float) -> float:
	if not is_nan(_torch_pillar(row, col)):
		return _plane_shift_at(x, _pillar_parts[_backdrop_part(row)])
	return _wall_shift_at(x)


## How far something at x in the level has slid sideways on a plane moving at this parallax.
func _plane_shift_at(x: float, parallax: float) -> float:
	if not _wall_moves() or not _camera:
		return 0.0
	return (_camera.get_screen_center_position().x - x) * (1.0 - parallax)


## The middle of the column a wall torch at a cell hangs on, in the level, or NAN for none.
func _torch_pillar(row: int, col: int) -> float:
	var mark := _nearest_mark(row, col)
	if mark.size() != 3 or mark[2] != 1.0:
		return NAN
	var on: float = (mark[0] + mark[1]) / 2.0
	return on if _open_between(row, col, floori(on / TILE)) else NAN


## The backdrop copy (column or entrance) nearest a cell: [left, right, 1 for a column], in the
## level, or [] when the room's wall has none.
func _nearest_mark(row: int, col: int) -> Array:
	var part := _backdrop_part(row)
	if not _wall_moves() or not _pillars.has(part):
		return []
	var spot: Vector3 = _pillars[part]
	var middle := (spot.y + spot.z) / 2.0
	var n := roundf(((col + 0.5) * TILE - middle) / spot.x)
	return [spot.y + n * spot.x, spot.z + n * spot.x, 1.0 if _pillar_parts.has(part) else 0.0]


## Whether a row is open from one cell to another (no stone between).
func _open_between(row: int, from: int, to: int) -> bool:
	if to < 0 or to >= map[row].length():
		return false
	for between in range(mini(from, to), maxi(from, to) + 1):
		if map[row][between] == "#":
			return false
	return true


## How far the back wall at x in the level has slid sideways from there.
func _wall_shift_at(x: float) -> float:
	if not _wall_moves() or not _camera:
		return 0.0
	return (_camera.get_screen_center_position().x - x) * (1.0 - WALL_PLANE)


## The picture files of a backdrop layer in tlo.json.
static func backdrop_files(layer: Dictionary) -> Array[String]:
	var files: Array[String] = []
	var file = layer.get("file", "")
	for name in (file if file is Array else [file]):
		if str(name) != "":
			files.append(str(name))
	return files


## Which backdrop part a row belongs to.
func _backdrop_part(row: int) -> String:
	return "hall" if (row + 1) * TILE <= _horizon else "dungeon"


## Whether open land lies beside the level above the starting ground (see LAND_AROUND_CASTLE).
func _land_around() -> bool:
	return LAND_AROUND_CASTLE or not dungeon


## The back wall slides with backdrop layers in the castle (see WALL_PLANE).
func _wall_moves() -> bool:
	return dungeon and not _backdrops.is_empty()


## How far the back wall at a cell has slid sideways from where the map puts it.
func _wall_shift(_row: int, col: int) -> float:
	if not _wall_moves() or not _camera:
		return 0.0
	return (_camera.get_screen_center_position().x - (col + 0.5) * TILE) * (1.0 - WALL_PLANE)


## The back wall's things, each moved with its room's wall.
func _draw_wall_decor() -> void:
	var span := _visible_columns()
	span = Vector2i(maxi(span.x - 4, 0), mini(span.y + 4, map[0].length()))
	_draw_wall_things(_wall_decor, span)
	for col in range(span.x, span.y):
		for row in map.size():
			if not _pieces.has(CASTLE_WALL_PICTURES.get(map[row][col], "")):
				continue
			var on_wall: Texture2D = _pieces[CASTLE_WALL_PICTURES[map[row][col]]]
			_wall_decor.draw_set_transform(Vector2(_wall_shift(row, col), 0))
			_wall_decor.draw_texture(on_wall, Vector2(col * TILE, row * TILE) + (Vector2(TILE, TILE) - on_wall.get_size()) / 2.0)
	for thing in _decor:
		if thing["on"] == "sciana" and thing["col"] >= span.x and thing["col"] < span.y:
			var rect: Rect2 = thing["rect"]
			_wall_decor.draw_set_transform(Vector2(_wall_shift_at(rect.get_center().x), 0))
			_wall_decor.draw_texture_rect(thing["picture"], rect, false)
	_wall_decor.draw_set_transform(Vector2.ZERO)


## Puts the backdrop layers behind the level: each part's layers show only through its open cells.
func _add_backdrops() -> void:
	_backdrop_nodes.clear()
	_wall_decor = null
	if not dungeon or _backdrops.is_empty() or _room_of.is_empty():
		return
	var width := map[0].length()
	_room_boxes.clear()
	for row in map.size():
		for col in width:
			var room := _room_of[row * width + col]
			if room < 0 or _passages.has(room):
				continue
			var cell := Rect2i(col, row, 1, 1)
			_room_boxes[room] = _room_boxes[room].merge(cell) if _room_boxes.has(room) else cell
	var order := 0
	for part in _backdrops:
		var mask := Node2D.new()
		mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		mask.draw.connect(_draw_backdrop_mask.bind(mask, part))
		_static.add_child(mask)
		_static.move_child(mask, order)
		order += 1
		for layer in _backdrops[part]:
			if not _in_front_of_wall(layer):
				_add_backdrop_layer(mask, layer, part)
	# The wall's things slide too, so the stone around a room cuts them off like the wall.
	var decor_mask := Node2D.new()
	decor_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	decor_mask.draw.connect(_draw_backdrop_mask.bind(decor_mask, ""))
	_static.add_child(decor_mask)
	_static.move_child(decor_mask, order)
	_wall_decor = Node2D.new()
	_wall_decor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wall_decor.draw.connect(_draw_wall_decor)
	decor_mask.add_child(_wall_decor)
	_backdrop_nodes.append({"node": _wall_decor})
	# The windows are on that wall too, behind the furniture that stands in the room.
	_level.remove_child(_windows)
	_static.add_child(_windows)
	_static.move_child(_windows, order + 1)
	order += 2
	# The columns stand out from the wall, in front of what hangs on it.
	for part in _backdrops:
		var mask := Node2D.new()
		mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		mask.draw.connect(_draw_backdrop_mask.bind(mask, part))
		_static.add_child(mask)
		_static.move_child(mask, order)
		order += 1
		for layer in _backdrops[part]:
			if _in_front_of_wall(layer):
				_add_backdrop_layer(mask, layer, part)


func _add_backdrop_layer(mask: Node2D, layer: Dictionary, part: String) -> void:
	var node := Node2D.new()
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.modulate = layer["tint"]
	node.draw.connect(_draw_backdrop_layer.bind(node, layer, part))
	mask.add_child(node)
	_backdrop_nodes.append({"node": node})


## Columns (layers stretched to the room's height) stand in front of the wall and its things.
func _in_front_of_wall(layer: Dictionary) -> bool:
	return layer["stretch"].size() == 2


## The open cells of a part (or of the whole level, for ""), where its backdrop shows.
func _draw_backdrop_mask(v: Node2D, part: String) -> void:
	for row in map.size():
		if part != "" and _backdrop_part(row) != part:
			continue
		var start := -1
		for col in map[row].length() + 1:
			var open := col < map[row].length() and map[row][col] != "#"
			if open and start < 0:
				start = col
			elif not open and start >= 0:
				v.draw_rect(Rect2(start * TILE, row * TILE, (col - start) * TILE, TILE), Color.WHITE)
				start = -1


## One backdrop layer, moved by its parallax against the camera.
func _draw_backdrop_layer(v: Node2D, layer: Dictionary, part: String) -> void:
	if not _camera:
		return
	var center := _camera.get_screen_center_position()
	var half := SCREEN / _camera.zoom / 2.0 + Vector2(TILE, TILE)
	var view := Rect2(center - half, half * 2.0)
	var texture: Texture2D = layer["texture"]
	var size: Vector2 = texture.get_size() * float(layer["scale"])
	var parallax := float(layer["parallax"])
	# Only sideways: the wall's things hang at fixed heights, so the wall must not slide up or down.
	var shift := Vector2(center.x * (1.0 - parallax), 0.0)
	if layer["fill"]:
		var start := shift + ((view.position - shift) / size).floor() * size
		_draw_tiled(v, texture, Rect2(start, view.end - start), float(layer["scale"]))
		return
	for room in _room_boxes:
		var box: Rect2i = _room_boxes[room]
		var area := Rect2(Vector2(box.position) * TILE, Vector2(box.size) * TILE)
		if not area.intersects(view) or _backdrop_part(box.end.y - 1) != part:
			continue
		var left := maxf(area.position.x, view.position.x)
		var right := minf(area.end.x, view.end.x)
		var y := area.end.y - size.y - float(layer["lift"])
		# Copy n belongs at n * spacing in the level and is there when the camera looks right at
		# it, like the things on the wall, so the editor's guides (LevelMap) show where it stands.
		var spacing := backdrop_spacing(size.x, parallax, layer["spacing"])
		var offset: float = layer["offset"]
		var first := ceili((left - size.x - shift.x - parallax * offset) / (parallax * spacing))
		var last := floori((right - shift.x - parallax * offset) / (parallax * spacing))
		var textures: Array = layer["textures"]
		var scale := float(layer["scale"])
		for n in range(first, last + 1):
			texture = textures[posmod(n, textures.size())]
			var x := shift.x + parallax * (spacing * n + offset)
			var from := maxf(x, area.position.x)
			var to := minf(x + size.x, area.end.x)
			if to <= from:
				continue
			var columns := Vector2((from - x) / scale, (to - from) / scale)
			if layer["stretch"].size() == 2:
				_draw_stretched(v, texture, Rect2(from, area.position.y, to - from, area.size.y - float(layer["lift"])), columns, layer["stretch"], scale)
			else:
				v.draw_texture_rect_region(texture, Rect2(from, y, to - from, size.y), Rect2(columns.x, 0.0, columns.y, size.y / scale))


## A picture standing the whole height of rect: its rows above stretch[0] at the top, its rows from
## stretch[1] down at the bottom, and the rows between repeated down the middle (a column's shaft).
## columns are the picture's columns drawn: first and how many.
func _draw_stretched(v: Node2D, texture: Texture2D, rect: Rect2, columns: Vector2, stretch: Array, scale: float) -> void:
	var top := float(stretch[0])
	var bottom := float(stretch[1])
	var height := texture.get_height()
	var top_px := top * scale
	var bottom_px := (height - bottom) * scale
	v.draw_texture_rect_region(texture, Rect2(rect.position.x, rect.end.y - bottom_px, rect.size.x, bottom_px), Rect2(columns.x, bottom, columns.y, height - bottom))
	v.draw_texture_rect_region(texture, Rect2(rect.position, Vector2(rect.size.x, top_px)), Rect2(columns.x, 0.0, columns.y, top))
	var y := rect.position.y + top_px
	var end := rect.end.y - bottom_px
	var shaft := (bottom - top) * scale
	while y < end:
		var piece := minf(shaft, end - y)
		v.draw_texture_rect_region(texture, Rect2(rect.position.x, y, rect.size.x, piece), Rect2(columns.x, top, columns.y, piece / scale))
		y += shaft


## How far apart, in the level, the copies of a backdrop picture size wide stand: whole tiles, far
## enough that the copies do not touch when they slide together by the parallax, or the layer's
## own spacing in tiles when that is further.
static func backdrop_spacing(width: float, parallax: float, tiles := 0.0) -> float:
	return maxf(ceilf(width / parallax / TILE), tiles) * TILE


## A picture repeated over a rectangle from its top left corner, each picture pixel scale pixels big.
func _draw_tiled(v: Node2D, texture: Texture2D, rect: Rect2, scale: float) -> void:
	v.draw_texture_rect_region(texture, rect, Rect2(Vector2.ZERO, rect.size / scale))


func _add_room_shade() -> void:
	_room_shade = null
	_room_of.clear()
	if not dungeon:
		return
	_room_dark = PackedFloat32Array()
	_room_dark.resize(map.size() * map[0].length())
	_room_dark.fill(ROOM_DARK)
	_label_rooms()
	_room_shade = Node2D.new()
	_room_shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_room_shade.draw.connect(_draw_room_shade)
	_level.add_child(_room_shade)


## Wiesław's size for the level (see DUNGEON_WIESLAW).
func _wieslaw_size() -> float:
	return DUNGEON_WIESLAW if dungeon else WIESLAW_SIZE


## A cell in a narrow upright passage through stone (a ladder shaft or a hole between floors): open,
## with at most two open cells side by side in its row.
func _in_passage(row: int, col: int) -> bool:
	var width := 1
	for dir in [-1, 1]:
		var at: int = col + dir
		while width <= 3 and not _stone_or_hidden(row, at):
			width += 1
			at += dir
	return width <= 2


## Splits the open cells into rooms and passages (_room_of), and notes for each passage the rooms it
## joins and where it meets them (_passages).
func _label_rooms() -> void:
	_room_of.clear()
	_passages.clear()
	var width := map[0].length()
	_room_of.resize(map.size() * width)
	_room_of.fill(-1)
	var passage := PackedByteArray()
	passage.resize(map.size() * width)
	for row in map.size():
		for col in width:
			passage[row * width + col] = 1 if not _stone_or_hidden(row, col) and _in_passage(row, col) else 0
	var count := 0
	for row in map.size():
		for col in width:
			if _stone_or_hidden(row, col) or _room_of[row * width + col] >= 0:
				continue
			var kind := passage[row * width + col]
			var queue: Array[Vector2i] = [Vector2i(col, row)]
			_room_of[row * width + col] = count
			var rows := Vector2i(row, row)
			while not queue.is_empty():
				var cell: Vector2i = queue.pop_back()
				rows = Vector2i(mini(rows.x, cell.y), maxi(rows.y, cell.y))
				for side in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = cell + side
					if next.x < 0 or next.x >= width or next.y < 0 or next.y >= map.size() or _stone_or_hidden(next.y, next.x):
						continue
					var k := next.y * width + next.x
					if _room_of[k] >= 0 or passage[k] != kind:
						continue
					_room_of[k] = count
					queue.append(next)
			if kind == 1:
				_passages[count] = {"rows": rows, "rooms": {}}
			count += 1
	for row in map.size():
		for col in width:
			var here := _room_of[row * width + col]
			if not _passages.has(here):
				continue
			for dir in [-1, 1]:
				var next_row: int = row + dir
				if next_row < 0 or next_row >= map.size():
					continue
				var there := _room_of[next_row * width + col]
				if there >= 0 and not _passages.has(there):
					# Where the passage meets the room, in level pixels.
					_passages[here]["rooms"][there] = float(row * TILE if dir < 0 else (row + 1) * TILE)


## How lit each room and passage is now: the one Wiesław is in fully; from inside a passage the
## rooms it joins more the closer he is to them; a passage as much as the room it opens into.
func _room_light() -> Dictionary:
	var width := map[0].length()
	var eye := player.position - Vector2(0, 40)
	var cell := Vector2i(floori(eye.x / TILE), floori(eye.y / TILE))
	if cell.y >= 0 and cell.y < map.size() and cell.x >= 0 and cell.x < width and _room_of[cell.y * width + cell.x] >= 0:
		_room_here = _room_of[cell.y * width + cell.x]
	var light := {_room_here: 1.0}
	if _passages.has(_room_here):
		var info: Dictionary = _passages[_room_here]
		var span := float(info["rows"].y - info["rows"].x + 1) * TILE
		for room in info["rooms"]:
			var near := 1.0 - absf(eye.y - float(info["rooms"][room])) / span
			light[room] = clampf(near, 0.0, 1.0)
	else:
		for passage in _passages:
			var rooms: Dictionary = _passages[passage]["rooms"]
			if rooms.has(_room_here):
				light[passage] = 0.6
	return light


func _update_room_shade(delta: float) -> void:
	if not _room_shade or not player or not _camera:
		return
	var columns := _visible_columns()
	var center := _camera.get_screen_center_position()
	var half_rows := ceili(SCREEN.y / _camera.zoom.y / TILE / 2.0) + 2
	var top := clampi(floori(center.y / TILE) - half_rows, 0, map.size() - 1)
	var bottom := clampi(floori(center.y / TILE) + half_rows, 0, map.size() - 1)
	var left := clampi(columns.x, 0, map[0].length() - 1)
	var right := clampi(columns.y, 0, map[0].length() - 1)
	_room_window = Rect2i(left, top, right - left + 1, bottom - top + 1)
	var light := _room_light()
	var width := map[0].length()
	if not _room_image or _room_image.get_size() != _room_window.size:
		_room_image = Image.create(_room_window.size.x, _room_window.size.y, false, Image.FORMAT_RGBA8)
		_room_texture = null
	# How dark each open cell should be; stone takes the lightest open cell around it.
	var wanted := PackedFloat32Array()
	wanted.resize(_room_window.size.x * _room_window.size.y)
	for row in range(top, bottom + 1):
		for col in range(left, right + 1):
			var room := _room_of[row * width + col]
			wanted[(row - top) * _room_window.size.x + col - left] = ROOM_DARK * (1.0 - float(light.get(room, 0.0))) if room >= 0 else -1.0
	var eye := player.position - Vector2(0, 40)
	for row in range(top, bottom + 1):
		for col in range(left, right + 1):
			var k := (row - top) * _room_window.size.x + col - left
			var dark := wanted[k]
			if dark < 0.0:
				dark = ROOM_DARK
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var y: int = row - top + dy
						var x: int = col - left + dx
						if y >= 0 and y < _room_window.size.y and x >= 0 and x < _room_window.size.x and wanted[y * _room_window.size.x + x] >= 0.0:
							dark = minf(dark, wanted[y * _room_window.size.x + x])
				dark *= _lamp_shade(Vector2(col + 0.5, row + 0.5), light)
			# Wiesław's glow.
			var away := eye.distance_to((Vector2(col, row) + Vector2(0.5, 0.5)) * TILE) / TILE
			dark *= clampf(away / GLOW_REACH, 0.0, 1.0)
			var at := row * width + col
			_room_dark[at] = move_toward(_room_dark[at], dark, delta * ROOM_FADE)
			_room_image.set_pixel(col - left, row - top, Color(ROCK_INK, _room_dark[at]))
	if not _room_texture:
		_room_texture = ImageTexture.create_from_image(_room_image)
	else:
		_room_texture.update(_room_image)
	_room_shade.queue_redraw()


## How much of the shade is left on stone near a flame (1 = all of it). With rooms given, only the
## flames in a lit room count.
func _lamp_shade(at: Vector2, rooms: Dictionary) -> float:
	var width := map[0].length()
	var shade := 1.0
	var cell := Vector2i(floori(at.x), floori(at.y))
	for i in _lamps.size():
		var lamp := _lamps[i]
		if not rooms.is_empty() and float(rooms.get(_room_of[int(lamp.y) * width + int(lamp.x)], 0.0)) < 0.5:
			continue
		var cells := _lamp_cells[i]
		if not (cells.has(cell) or cells.has(cell - Vector2i(1, 0)) or cells.has(cell - Vector2i(0, 1)) or cells.has(cell - Vector2i(1, 1))):
			continue
		var away := Vector2(lamp.x, lamp.y).distance_to(at)
		shade = minf(shade, clampf((away - LAMP_CLEAR) / (lamp.z - LAMP_CLEAR), 0.0, 1.0))
	return shade


func _draw_room_shade() -> void:
	if _room_texture:
		_room_shade.draw_texture_rect(_room_texture, Rect2(Vector2(_room_window.position) * TILE, Vector2(_room_window.size) * TILE), false)


## Works out _rock_depth: how far each stone cell is from open air, counting a hidden room as stone
## (it must not give itself away) and the land outside the map as stone below the starting ground.
func _measure_rock() -> void:
	_rock_depth.clear()
	_lamps.clear()
	_lamp_cells.clear()
	var deepest := ROCK_DARK.size() - 1
	var open: Array[Vector2i] = []
	for row in map.size():
		var depths := PackedByteArray()
		depths.resize(map[row].length())
		for col in map[row].length():
			var rock: bool = map[row][col] == "#" or map[row][col] == "u"
			depths[col] = deepest if rock else 0
			if map[row][col] == "y":
				_lamps.append(Vector3(col + 0.5, row + 0.2, LIGHT_FIRE.x))
			elif _torch_here(row, col):
				_lamps.append(Vector3(col + 0.5, row + 0.2, LIGHT_TORCH.x))
			if not rock:
				open.append(Vector2i(col, row))
		_rock_depth.append(depths)
	for row in map.size():
		if row * TILE < _horizon and _land_around():
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
	for lamp in _lamps:
		_lamp_cells.append(_lamp_reach(lamp))


## The cells a lamp lights: open cells within its reach, and stone up to LIT_EDGE deep from
## the side the lamp is on (so never the far side of a floor).
func _lamp_reach(lamp: Vector3) -> Dictionary:
	var deepest := ceili(LIT_EDGE / TILE)
	var start := Vector2i(int(lamp.x), int(lamp.y))
	var seen := {start: 0}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var cell: Vector2i = todo.pop_back()
		var steps: int = seen[cell]
		for side in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var at: Vector2i = cell + side
			if at.y < 0 or at.y >= map.size() or at.x < 0 or at.x >= map[at.y].length():
				continue
			if Vector2(at.x + 0.5, at.y + 0.5).distance_to(Vector2(lamp.x, lamp.y)) > lamp.z:
				continue
			var rock: bool = map[at.y][at.x] == "#" or map[at.y][at.x] == "u"
			if not rock and steps > 0:
				continue
			var next := steps + 1 if rock else 0
			if next > deepest or (seen.has(at) and seen[at] <= next):
				continue
			seen[at] = next
			todo.append(at)
	return seen


## How dark the stone is at a cell corner: the four cells around it averaged, so the darkness
## changes smoothly from cell to cell.
func _rock_dark_at(row: int, col: int) -> float:
	var sum := 0.0
	for cell in [Vector2i(col - 1, row - 1), Vector2i(col, row - 1), Vector2i(col - 1, row), Vector2i(col, row)]:
		var r: int = clampi(cell.y, 0, map.size() - 1)
		var c: int = cell.x
		if c < 0 or c >= map[r].length():
			sum += 0.0 if r * TILE < _horizon and _land_around() else ROCK_DARK[-1]
		else:
			sum += ROCK_DARK[_rock_depth[r][c]]
	return sum / 4.0 * _lamp_shade(Vector2(col, row), {})


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
	if _rock_mesh.get_surface_count() > 0:
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
	if not dungeon and not _art.has("ground"):
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
				if not _wall_moves():
					_draw_wall_things(v, span)
			if dungeon and not _castle.is_empty():
				_draw_castle(v, span)
			elif not dungeon and _art.has("ground") and _art.get("organic", false):
				_draw_organic_ground(v, span)
				_draw_holes(v, span)
			elif not dungeon and _art.has("ground"):
				if _art.has("edges"):
					_draw_ground_corners(v, span)
				_draw_dual_grid(v, span, _outdoor_tiles)
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
				# Soft ground shapes leave gaps at their edges: the cellar wall shows through there.
				if under_ground and _art.get("organic", false):
					_draw_cellar_wall(v, row, col)
				under_ground = true
			elif under_ground or _shaft(row, col) or _in_hole(row, col):
				under_ground = true
				if dungeon and _backdrops.has(_backdrop_part(row)):
					continue
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
				elif _art.has("ground"):
					_draw_cellar_wall(v, row, col)
				else:
					v.draw_rect(Rect2(col * TILE, row * TILE, TILE + 1, TILE + 1), Color("2a1d16"))
		if run.x >= 0:
			_draw_wall_run(v, col, run)


## Ground drawn as soft shapes instead of square tiles: each cell is a polygon filled with its
## part's big picture ("ground_fill"), its open sides wobbling a little in and out and its outer
## corners rounded, so the edge of the ground is irregular. The wobble depends only on the place,
## so neighbouring cells join without seams. Moss lies along the tops.
func _draw_organic_ground(v: Node2D, span: Vector2i) -> void:
	v.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var moss: Array[PackedVector2Array] = []
	var rims: Dictionary = _art.get("rims", {})
	# Open cell sides by side (top, right, bottom, left): [edge points, outward, row, col].
	var edges := [[], [], [], []]
	var corner_spots := []
	var dark_batch := {}
	for row in map.size():
		# The first strip also fills a few cells past the left edge with the first column's ground,
		# where the camera's look-ahead can show past the level's start.
		for col in range(span.x - 4 if span.x == 0 else span.x - 1, mini(span.y + 1, map[row].length())):
			if map[row][maxi(col, 0)] != "#":
				continue
			var tiles: Dictionary = _outdoor_tiles(row, maxi(col, 0) + 1)
			var fill: Dictionary = tiles.get("fill", {})
			if fill.is_empty():
				continue
			var open := [not _stone_at(row - 1, col), not _stone_at(row, col + 1), not _stone_at(row + 1, col), not _stone_at(row, col - 1)]
			var shape := _cell_shape(row, col, open)
			var picture: Texture2D = fill["picture"]
			var size := picture.get_size() * float(fill["scale"])
			var uvs := PackedVector2Array()
			for point in shape:
				uvs.append(point / size)
			if not rims.is_empty():
				# With rims the inside of the ground is one dark mass; only the rims show its edge.
				# All of it goes into one batch, drawn at once.
				var triangles := Geometry2D.triangulate_polygon(shape)
				if triangles.is_empty():
					shape = PackedVector2Array([Vector2(col, row) * TILE, Vector2(col + 1, row) * TILE, Vector2(col + 1, row + 1) * TILE, Vector2(col, row + 1) * TILE])
					triangles = PackedInt32Array([0, 1, 2, 0, 2, 3])
				_batch_add(dark_batch, shape, PackedVector2Array(), triangles)
			elif Geometry2D.triangulate_polygon(shape).is_empty():
				# A shape that folded over itself: the plain square instead.
				_draw_tiled_piece(v, fill, Rect2(col * TILE, row * TILE, TILE, TILE))
			else:
				v.draw_colored_polygon(shape, fill["tint"], uvs, picture)
			for side in 4:
				if not open[side]:
					continue
				var corners := [Vector2(0, 0), Vector2(TILE, 0), Vector2(TILE, TILE), Vector2(0, TILE)]
				var from: Vector2 = Vector2(col * TILE, row * TILE) + corners[side]
				var along: Vector2 = corners[(side + 1) % 4] - corners[side]
				var out := Vector2(along.y, -along.x).normalized()
				var edge := _edge_points(from, along, out, open[(side + 3) % 4], open[(side + 1) % 4])
				if rims.is_empty():
					if side == 0:
						moss.append(edge)
					# A dark rim just inside each open side.
					v.draw_polyline(edge, Color(0.05, 0.04, 0.05, 0.85), 5.0)
				else:
					edges[side].append([edge, out, row, col])
			if not rims.is_empty() and open[0]:
				for right in [false, true]:
					if open[1 if right else 3]:
						corner_spots.append([Vector2((col + (1 if right else 0)) * TILE, row * TILE), right, row * 7 + col])
	for edge in moss:
		_draw_moss(v, edge)
	if not dark_batch.is_empty():
		_batch_draw(v, dark_batch, null, _art.get("ground_dark", Color.BLACK))
	# Rims: the sides and undersides first, the grassy tops over them, the corners on top. Each
	# kind's quads are batched by picture and drawn in one go per picture.
	for group: Array in [[1, 3], [2], [0]]:
		var batches := {}
		for side: int in group:
			var kind: String = ["top", "side", "bottom", "side"][side]
			if not rims.has(kind):
				continue
			for item: Array in edges[side]:
				_draw_rim(batches, rims[kind], item[0], item[1], item[2], item[3], side)
		for picture: Texture2D in batches:
			_batch_draw(v, batches[picture], picture, Color.WHITE)
	if rims.has("corner"):
		var corner: Dictionary = rims["corner"]
		for spot: Array in corner_spots:
			var pictures: Array = corner["pictures"]
			var picture: Texture2D = pictures[posmod(spot[2], pictures.size())]
			var size: Vector2 = picture.get_size() * float(corner["scale"])
			var at: Vector2 = corner["at"] * float(corner["scale"])
			var place: Vector2 = spot[0]
			if spot[1]:
				# The right corner: the picture mirrored, its anchor mirrored with it.
				v.draw_texture_rect(picture, Rect2(Vector2(place.x - (size.x - at.x), place.y - at.y), Vector2(-size.x, size.y)), false)
			else:
				v.draw_texture_rect(picture, Rect2(place - at, size), false)


## One cell side's rim: the rim picture laid as a band along the wobbling edge, its "surface"
## (picture pixels in from its outer side) on the edge. Along the edge the picture follows the
## place in the level, so neighbouring cells join; each ledge or wall starts at another part of it.
## Adds a shape (its points, picture places and triangles) to a batch of triangles drawn at once.
func _batch_add(batch: Dictionary, points: PackedVector2Array, uvs: PackedVector2Array, triangles: PackedInt32Array) -> void:
	if batch.is_empty():
		batch["points"] = PackedVector2Array()
		batch["uvs"] = PackedVector2Array()
		batch["indices"] = PackedInt32Array()
	var base: int = batch["points"].size()
	batch["points"].append_array(points)
	batch["uvs"].append_array(uvs)
	for index in triangles:
		batch["indices"].append(base + index)


## Draws a batch of triangles in one call, with a picture (repeating) or in a plain colour.
func _batch_draw(v: Node2D, batch: Dictionary, picture: Texture2D, colour: Color) -> void:
	var colours := PackedColorArray()
	colours.resize(batch["points"].size())
	colours.fill(colour)
	RenderingServer.canvas_item_add_triangle_array(v.get_canvas_item(), batch["indices"], batch["points"], colours,
		batch["uvs"] if picture else PackedVector2Array(), PackedInt32Array(), PackedFloat32Array(), picture.get_rid() if picture else RID())


func _draw_rim(batches: Dictionary, rim: Dictionary, edge: PackedVector2Array, out: Vector2, row: int, col: int, side: int) -> void:
	var pictures: Array = rim["pictures"]
	var scale: float = rim["scale"]
	var upright := side == 1 or side == 3
	var pick := posmod(col * 13 + side * 5, pictures.size()) if upright else posmod(row * 11 + side, pictures.size())
	var picture: Texture2D = pictures[pick]
	var size := picture.get_size()
	# Along the edge: the picture's width for tops and bottoms, its height for walls.
	var length: float = (size.y if upright else size.x) * scale
	var across: float = (size.x if upright else size.y) * scale
	var surface: float = rim["surface"] * scale
	var shift := float(posmod((row * 97 + col * 61 + side * 29) if upright else (row * 97 + side * 29), 13)) / 13.0
	var mirror := 1.0 if posmod(row + col * (1 if upright else 0) + side, 2) == 0 else -1.0
	# Which way the picture's outer side lies: top pictures and walls start outside, bottoms inside.
	var outer_first := side != 2
	for k in edge.size() - 1:
		var quad := PackedVector2Array()
		var uvs := PackedVector2Array()
		var ends := [edge[k], edge[k + 1]]
		for corner in 4:
			var p: Vector2 = ends[0 if corner == 0 or corner == 3 else 1]
			var outside := corner < 2
			var place := p + out * (surface if outside else surface - across)
			quad.append(place)
			var u := mirror * ((p.y if upright else p.x) / length + shift)
			var w := 0.0 if outside == outer_first else 1.0
			uvs.append(Vector2(w, u) if upright else Vector2(u, w))
		if not batches.has(picture):
			batches[picture] = {}
		_batch_add(batches[picture], quad, uvs, PackedInt32Array([0, 1, 2, 0, 2, 3]))


## The outline of a ground cell, clockwise from its top left; open sides wobble (see _edge_points).
func _cell_shape(row: int, col: int, open: Array) -> PackedVector2Array:
	var at := Vector2(col * TILE, row * TILE)
	var corners := [Vector2(0, 0), Vector2(TILE, 0), Vector2(TILE, TILE), Vector2(0, TILE)]
	var shape := PackedVector2Array()
	for side in 4:
		var from: Vector2 = at + corners[side]
		var along: Vector2 = corners[(side + 1) % 4] - corners[side]
		if open[side]:
			var out := Vector2(along.y, -along.x).normalized()
			var points := _edge_points(from, along, out, open[(side + 3) % 4], open[(side + 1) % 4])
			points.remove_at(points.size() - 1)
			shape.append_array(points)
		else:
			shape.append(from)
	return shape


## Points along a cell side from "from" over "along", pushed out by a wobble that depends only on
## the place; an end where the next side is open too is an outer corner and is rounded in.
func _edge_points(from: Vector2, along: Vector2, out: Vector2, round_start: bool, round_end: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 8
	var top := out.y < -0.5
	for k in steps + 1:
		var t := float(k) / steps
		var at := from + along * t
		var key := at.x * 0.9 + at.y * 1.3
		var wobble := 6.0 * sin(key * 0.045 + 1.7) + 4.0 * sin(key * 0.11 + 0.4) + 2.0 * sin(key * 0.29)
		var push := (wobble * 0.3 + 1.0) if top else wobble
		# Rounding: the last quarter towards an outer corner bends inwards.
		var bend := 0.0
		if round_start and t < 0.3:
			bend = (0.3 - t) / 0.3
		if round_end and t > 0.7:
			bend = (t - 0.7) / 0.3
		push -= 14.0 * bend * bend
		points.append(at + out * push)
	return points


## Moss along the top of the ground: a dark green band with rounded tufts and a few lit tips.
func _draw_moss(v: Node2D, edge: PackedVector2Array) -> void:
	var dark := Color("173a24")
	var mid := Color("2c6a3a")
	var light := Color("5f9e52")
	for k in edge.size() - 1:
		var a := edge[k]
		var b := edge[k + 1]
		v.draw_colored_polygon(PackedVector2Array([a + Vector2(0, -2), b + Vector2(0, -2), b + Vector2(0, 9), a + Vector2(0, 9)]), dark)
	for k in edge.size():
		var p := edge[k]
		var seed := int(absf(p.x * 7.0 + p.y * 3.0)) % 97
		var r := 4.0 + float(seed % 5)
		v.draw_circle(p + Vector2(0, 1), r, mid)
		v.draw_circle(p + Vector2(-1, -1), r * 0.55, light if seed % 3 == 0 else mid)
		if seed % 4 == 0:
			v.draw_line(p, p + Vector2(float(seed % 7) - 3.0, -8.0 - float(seed % 6)), light, 2.0)


## One cell's piece of a big picture tiled over the level ({"picture", "scale", "tint"}): the part
## of the picture under that cell, so the pieces join up. The picture's sides are whole cells.
func _draw_tiled_piece(v: Node2D, tiled: Dictionary, at: Rect2) -> void:
	var picture: Texture2D = tiled["picture"]
	var scale: float = tiled["scale"]
	var from := Vector2(fposmod(at.position.x / scale, picture.get_width()), fposmod(at.position.y / scale, picture.get_height()))
	v.draw_texture_rect_region(picture, Rect2(at.position, at.size + Vector2.ONE), Rect2(from, at.size / scale), tiled["tint"])


## A cellar's back wall: the deep ground's stone, darkened, so the cellar reads as a room
## behind Wiesław and not as more ground.
func _draw_cellar_wall(v: Node2D, row: int, col: int) -> void:
	if _art.has("cellar_wall"):
		_draw_tiled_piece(v, _art["cellar_wall"], Rect2(col * TILE, row * TILE, TILE, TILE))
		return
	var tiles: Dictionary = _art["ground"]["under"]
	var rects: Array = tiles["masks"].get(15, [])
	if rects.size() != 4:
		v.draw_rect(Rect2(col * TILE, row * TILE, TILE + 1, TILE + 1), Color("2a1d16"))
		return
	v.draw_texture_rect_region(tiles["sheet"], Rect2(col * TILE, row * TILE, TILE + 1, TILE + 1), rects[(row % 2) * 2 + col % 2], CELLAR_WALL)


## One cell of a plank platform: the board's end at either end of a run of "=", the plain middle
## between, and a bracket under each end.
## Up over the ground outdoors a run of planks is one apple tree branch ("branch" in the art set:
## the picture, where along it the branch can be walked on, "span" in picture pixels, and the
## height of its top, "top"), stretched over the run and drawn from the run's first cell.
func _draw_branch(v: Node2D, row: int, col: int) -> void:
	if col > 0 and map[row][col - 1] == "=":
		return
	var cells := 0
	while col + cells < map[row].length() and map[row][col + cells] == "=":
		cells += 1
	var branch: Dictionary = _art["branch"]
	var picture: Texture2D = branch["texture"]
	var span: Vector2 = branch["span"]
	var scale := (cells * TILE + 40.0) / (span.y - span.x)
	var at := Vector2(col * TILE - 20.0 - span.x * scale, row * TILE + 6.0 - float(branch["top"]) * scale)
	# Every other branch faces the other way.
	if (row + col) % 2 == 1:
		at.x = col * TILE - 20.0 - (picture.get_width() - span.y) * scale
		v.draw_texture_rect(picture, Rect2(at, Vector2(-picture.get_width(), picture.get_height()) * scale), false)
	else:
		v.draw_texture_rect(picture, Rect2(at, picture.get_size() * scale), false)


## A hole in the ground over each way down from the surface ("hole" in the art set: the picture,
## its size and where in it the opening's middle and the ground line are).
func _draw_holes(v: Node2D, span: Vector2i) -> void:
	if _floors.size() < 2 or not _art.has("hole"):
		return
	var hole: Dictionary = _art["hole"]
	var picture: Texture2D = hole["texture"]
	var scale := float(hole["scale"])
	var anchor: Vector2 = hole["at"]
	var row := int(_floors[0].z / TILE)
	for col in range(maxi(span.x, 1), mini(span.y, map[row].length())):
		if map[row][col] == "#" or map[row][col - 1] != "#":
			continue
		var end := col
		while end < map[row].length() and map[row][end] != "#":
			end += 1
		var middle := (col + end) * TILE / 2.0
		v.draw_texture_rect(picture, Rect2(Vector2(middle, row * TILE) - anchor * scale, picture.get_size() * scale), false)


func _draw_plank(v: Node2D, row: int, col: int, at: Vector2) -> void:
	var left := col == 0 or map[row][col - 1] != "="
	var right := col + 1 >= map[row].length() or map[row][col + 1] != "="
	var parts: Dictionary = PLANK_PARTS
	if left and right:
		# A single cell: both ends, half a cell each.
		var half := Vector2(8, 5)
		v.draw_texture_rect_region(_plank_board, Rect2(at, half * PLANK_SCALE), Rect2(parts["left"].position, half), PLANK_TINT)
		v.draw_texture_rect_region(_plank_board, Rect2(at + Vector2(TILE / 2.0, 0), half * PLANK_SCALE),
			Rect2(parts["right"].position + Vector2(8, 0), half), PLANK_TINT)
	else:
		var part: Rect2 = parts["left"] if left else parts["right"] if right else parts["middle"]
		v.draw_texture_rect_region(_plank_board, Rect2(at, part.size * PLANK_SCALE), part, PLANK_TINT)
	if left or right:
		var bracket: Rect2 = parts["bracket"]
		var x := at.x + (TILE - bracket.size.x * PLANK_SCALE) / 2.0
		if not (left and right):
			x = at.x + 4.0 * PLANK_SCALE if left else at.x
		var shown := Rect2(Vector2(x, at.y + parts["left"].size.y * PLANK_SCALE), bracket.size * PLANK_SCALE)
		if right and not left:
			# The right bracket is the left one mirrored.
			shown.position.x = at.x + TILE - 4.0 * PLANK_SCALE - shown.size.x
			shown.size.x = -shown.size.x
			shown.position.x -= shown.size.x
		v.draw_texture_rect_region(_plank_board, shown, bracket, PLANK_TINT)


## Grass and moss hanging over each top corner of the ground, where the surface ends at a drop
## (the art set's "edges"), so the edge is not a straight line. Drawn under the ground tiles: only
## what hangs over the drop and the blades above the grass show. The same corner always gets the
## same picture.
func _draw_ground_corners(v: Node2D, span: Vector2i) -> void:
	var edges: Dictionary = _art["edges"]
	var pictures: Array = edges["pictures"]
	for row in range(1, map.size()):
		for col in range(maxi(span.x, 1), mini(span.y, map[row].length() - 1)):
			if map[row][col] != "#" or map[row - 1][col] == "#":
				continue
			for right in [true, false]:
				var beside := col + (1 if right else -1)
				if map[row][beside] == "#" or map[row - 1][beside] == "#":
					continue
				var pick: Dictionary = pictures[posmod(row * 31 + col * 17 + (5 if right else 0), pictures.size())]
				var picture: Texture2D = pick["picture"]
				var size: Vector2 = picture.get_size() * float(edges["scale"])
				var over: float = size.x * float(edges["over"])
				var x: float = (col + 1) * TILE + over - size.x if right else col * TILE - over
				var y: float = row * TILE - size.y * float(edges["lift"])
				var flip: bool = pick["right"] != right
				# A negative width mirrors the picture in the same place.
				v.draw_texture_rect(picture, Rect2(Vector2(x, y), Vector2(-size.x if flip else size.x, size.y)), false)


func _draw_static_front(v: Node2D, span: Vector2i) -> void:
	var ink := Color("2b1d14")
	for thing in _decor:
		if thing["on"] != "sciana" and thing["col"] >= span.x and thing["col"] < span.y:
			var rect: Rect2 = thing["rect"]
			if thing["on"] == "sufit" and rect.position.y > thing["hang"] + 8.0:
				# A chain from the ceiling down to what hangs low.
				var x := snappedf(rect.get_center().x, 2.0)
				var y: float = thing["hang"]
				if _hang_link:
					# The chain picture's links, tiled down to the top of what hangs.
					var size := _hang_link.get_size() * _hang_scale
					x = snappedf(x - size.x / 2.0, _hang_scale)
					while y < rect.position.y + 4.0:
						var part := minf(size.y, rect.position.y + 4.0 - y)
						v.draw_texture_rect_region(_hang_link, Rect2(x, y, size.x, part),
							Rect2(Vector2.ZERO, Vector2(_hang_link.get_width(), part / _hang_scale)))
						y += size.y
				var k := 0
				while not _hang_link and y < rect.position.y + 4.0:
					v.draw_rect(Rect2(x - (4.0 if k % 2 == 0 else 1.0), y, 8.0 if k % 2 == 0 else 2.0, 12.0), Color("2e2a27"))
					y += 10.0
					k += 1
			v.draw_texture_rect(thing["picture"], rect, false)
	for row in map.size():
		for col in range(span.x, mini(span.y, map[row].length())):
			var at := Vector2(col * TILE, row * TILE)
			var cell := Rect2(at, Vector2(TILE, TILE))
			match map[row][col]:
				"#" when dungeon:
					if _castle.is_empty():
						_draw_stone(v, row, col)
				"#" when _art.has("ground"):
					pass
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
				"B" when _barrel_here():
					pass
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
					if map[row][col] == "y" and not _fire_frames.is_empty():
						continue
					var piece: Texture2D = _pieces[CASTLE_FURNITURE[map[row][col]]]
					v.draw_texture(piece, at + Vector2(TILE / 2.0 - piece.get_width() / 2.0, TILE - piece.get_height()))
				_ when dungeon and not _wall_moves() and _pieces.has(CASTLE_WALL_PICTURES.get(map[row][col], "")):
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
				"H" when (dungeon or _art.has("castle_plank")) and _pieces.has("ladder"):
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
				"=" when not dungeon and _art.has("branch") and (row + 1) * TILE <= _horizon:
					_draw_branch(v, row, col)
				"=" when (dungeon or _art.has("castle_plank")) and _plank_board:
					_draw_plank(v, row, col, at)
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


## Outside the castle crates are drawn as the castle's barrels, when there are barrel pictures.
func _barrel_here() -> bool:
	return not dungeon and not _barrels.is_empty()


## A picture standing on the floor that rocks for a moment when Wiesław runs up to it (see _shake_near).
func _draw_shaking(v: Node2D, picture: Texture2D, rect: Rect2, cell: Vector2i) -> void:
	var left: float = _shaking.get(cell, 0.0)
	if left <= 0.0:
		v.draw_texture_rect(picture, rect, false)
		return
	var foot := rect.position + Vector2(rect.size.x / 2.0, rect.size.y)
	var angle := sin(left * 28.0) * 0.07 * left / SHAKE_TIME
	v.draw_set_transform(foot, angle)
	v.draw_texture_rect(picture, Rect2(rect.position - foot, rect.size), false)
	v.draw_set_transform(Vector2.ZERO)


## The castle's trunk for the big chest (two cells wide); opened, its lid stands up and gold shines inside.
func _draw_trunk(v: Node2D, at: Vector2, opened: bool, col: int, row: int) -> void:
	var trunk: Texture2D = _pieces["kufer"]
	var size := trunk.get_size() * TRUNK_SCALE
	var rect := Rect2(at + Vector2(TILE - size.x / 2.0, TILE - size.y), size)
	if not opened:
		_draw_shaking(v, trunk, rect, Vector2i(col, row))
		_draw_glint(v, rect.position, rect.size, col)
		return
	# The lid is the top part of the picture: lifted on its back edge, gold glowing in the gap.
	var lid := TRUNK_LID * trunk.get_height()
	var body := Rect2(rect.position + Vector2(0, lid * TRUNK_SCALE), Vector2(size.x, size.y - lid * TRUNK_SCALE))
	v.draw_rect(Rect2(body.position + Vector2(10, -8), Vector2(size.x - 20, 14)), Color("f2c14e"))
	v.draw_texture_rect_region(trunk, body, Rect2(0, lid, trunk.get_width(), trunk.get_height() - lid))
	v.draw_set_transform(body.position + Vector2(size.x / 2.0, 0), 0.0, Vector2(1.0, -0.55))
	v.draw_texture_rect_region(trunk, Rect2(Vector2(-size.x / 2.0, 0), Vector2(size.x, lid * TRUNK_SCALE)), Rect2(0, 0, trunk.get_width(), lid), Color(0.75, 0.75, 0.75))
	v.draw_set_transform(Vector2.ZERO)


## Barrels and trunks next to Wiesław start rocking when he runs up to them.
func _shake_near(delta: float) -> void:
	for cell in _shaking.keys():
		_shaking[cell] = maxf(float(_shaking[cell]) - delta, 0.0)
	if dungeon or not player or absf(player.velocity.x) < 60.0:
		return
	var here := Vector2i(floori(player.position.x / TILE), floori((player.position.y - 1.0) / TILE))
	for col in range(here.x - 2, here.x + 3):
		if here.y < 0 or here.y >= map.size() or col < 0 or col >= map[here.y].length():
			continue
		var kind := map[here.y][col]
		if not (kind == "B" or kind == "S"):
			continue
		var middle := (col + (1.0 if kind == "S" else 0.5)) * TILE
		var reach := TILE * (1.6 if kind == "S" else 1.1)
		var cell := Vector2i(col, here.y)
		if absf(player.position.x - middle) < reach and float(_shaking.get(cell, 0.0)) <= 0.0 and not _shaken.has(cell):
			_shaking[cell] = SHAKE_TIME
			_shaken[cell] = true
	# Once he has walked away, the next run up shakes it again.
	for cell in _shaken.keys():
		if absf(player.position.x - (cell.x + 0.5) * TILE) > TILE * 3.0 or cell.y != here.y:
			_shaken.erase(cell)


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
				"B" when _barrel_here():
					var barrel: Texture2D = _barrels[posmod(col * 7 + row * 3, _barrels.size())]
					var size := barrel.get_size() * BARREL_SCALE
					_draw_shaking(v, barrel, Rect2(at + Vector2(TILE / 2.0 - size.x / 2.0, TILE - size.y), size), Vector2i(col, row))
				"S", "s" when not dungeon and _pieces.has("kufer"):
					_draw_trunk(v, at, map[row][col] == "s", col, row)
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
	_update_room_shade(delta)
	for layer in _backdrop_nodes:
		layer["node"].queue_redraw()
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


## Until Wiesław first climbs, W and S over the end of the first ladder he stands at, and an
## arrow blinking along the ladder from that end.
func _draw_ladder_hint() -> void:
	if learned.has("ladder"):
		return
	var col := -1
	for row in map.size():
		var at := map[row].find("H")
		if at >= 0 and (col < 0 or at < col):
			col = at
	# Only once Wiesław stands at the ladder.
	if col < 0 or absf((col + 0.5) * TILE - player.position.x) > 0.8 * TILE:
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
	# Walking and jumping over the start from the first moment, gone once Wiesław moves.
	if _start_at != Vector2.INF:
		if absf(player.position.x - _start_at.x) > TILE / 2.0:
			learned["walk"] = true
		if not learned.has("walk"):
			var over := Vector2(maxf(_start_at.x, 480.0), _start_at.y - 300.0)
			_draw_key_line(_hints, [["A", "D"], "albo", ["<", ">"], "chodzenie"], over)
			_draw_key_line(_hints, [["W"], "albo", ["^"], "skok, w powietrzu jeszcze raz"], over + Vector2(0, 72))
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
		elif _items.has("mug"):
			var picture: Texture2D = _items["mug"]
			var size := picture.get_size()
			v.draw_texture_rect(picture, Rect2(icon - size / 2, size), false, tint)
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
	if not dungeon and not _art.get("castle_camera", false):
		_camera.offset = Vector2(_look, -80) + jolt
		return
	# In the castle: kept to the floor, looking down ahead of a fall, Wiesław low in the frame.
	var on_floor := player.is_on_floor() or _climbing
	if on_floor:
		_floor_y = player.position.y
	elif player.position.y < _floor_y - 2.0 * TILE:
		_floor_y = player.position.y + 2.0 * TILE
	var falling := not on_floor and player.position.y > _floor_y + 8.0
	var look := clampf(player.velocity.y / 900.0, 0.0, 1.0) * FALL_LOOK if falling else 0.0
	_look_down = move_toward(_look_down, look, delta * 600.0)
	var target := (player.position.y if falling else _floor_y) + _look_down
	# The camera glides to its height: quickly in a fall, gently going up.
	var rate := CAMERA_FALL_RATE if target > _camera_y else CAMERA_RISE_RATE
	_camera_y = lerpf(_camera_y, target, 1.0 - exp(-rate * delta))
	_camera.position = Vector2(0, _camera_y - player.position.y)
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
			var top := ceilings[dice.randi() % ceilings.size()]
			var floor_row := int(top / TILE)
			while floor_row < map.size() - 1 and map[floor_row][col] != "#":
				floor_row += 1
			# Only in rooms tall enough that a long chain does not hide the way.
			if floor_row * TILE - top >= NEAR_MIN_ROOM * TILE and _castle_part(int(top / TILE)) != "hall":
				# "hook": where on the screen the hook hangs while Wiesław stands on the floor.
				_near_things.append({"kind": "chain", "pos": Vector2((col + 0.5) * TILE, top),
					"seed": dice.randi(), "size": dice.randf_range(0.8, 1.25), "room": floor_row * TILE - top,
					"rest": floor_row * TILE, "hook": dice.randf_range(0.3, 0.48)})
		col += dice.randi_range(NEAR_EVERY.x, NEAR_EVERY.y)


## Reads ozdoby.json (see DECOR_DIR): "blisko" for the near chains, "ozdoby" for the kinds of
## scattered things ({"files", "on": sufit/podloga/sciana, "parts", "chance" per cell, "scale",
## optional "flames" and "eyes" as picture pixels}) and "kapanie" for the dripping water.
func _load_decor(dir := DECOR_DIR) -> void:
	_decor_kinds.clear()
	_near_pictures.clear()
	_drip_spec = {}
	if not FileAccess.file_exists(dir + "ozdoby.json"):
		return
	var spec = JSON.parse_string(FileAccess.get_file_as_string(dir + "ozdoby.json"))
	if not spec is Dictionary:
		return
	var near: Dictionary = spec.get("blisko", {})
	for file in near.get("files", []):
		if ResourceLoader.exists(dir + str(file)):
			_near_pictures.append(load(dir + str(file)))
	_near_scale = float(near.get("scale", 3))
	_hang_link = null
	var link: Dictionary = spec.get("ogniwo", {})
	if ResourceLoader.exists(dir + str(link.get("file", ""))):
		_hang_link = load(dir + str(link["file"]))
		_hang_scale = float(link.get("scale", 2))
	for entry in spec.get("ozdoby", []):
		var pictures: Array[Texture2D] = []
		for file in entry.get("files", []):
			if ResourceLoader.exists(dir + str(file)):
				pictures.append(load(dir + str(file)))
		if pictures.is_empty():
			continue
		var kind: Dictionary = entry.duplicate()
		kind["pictures"] = pictures
		_decor_kinds.append(kind)
	_drip_spec = spec.get("kapanie", {})


## Scatters the things of ozdoby.json over the castle: each free cell under a ceiling, on a floor
## or (in the dungeons) on the wall a step above the floor gets one with its kind's chance, when
## it fits there without touching anything painted on the map. The same level always gets the
## same things.
func _place_decor() -> void:
	_decor.clear()
	_drips.clear()
	if map.is_empty() or (not dungeon and _decor_kinds.is_empty()):
		return
	var dice := RandomNumberGenerator.new()
	dice.seed = map[0].length() * 17 + map.size() * 7 + 3
	# Cells to keep clear: everything painted, with a cell around it, and more around the start.
	var taken := {}
	for row in map.size():
		for col in map[row].length():
			var letter := map[row][col]
			if letter == " " or letter == "#":
				continue
			var around := 3 if letter == "P" else 1
			for r in range(row - 1, row + 2):
				for c in range(col - around, col + around + 1):
					taken[Vector2i(c, r)] = true
	for row in range(1, map.size() - 2):
		var part := "dungeon" if _castle_part(row) == "deep" else _castle_part(row)
		for col in range(1, map[row].length() - 1):
			if map[row][col] != " " or taken.has(Vector2i(col, row)):
				continue
			if not dungeon:
				# Outdoors: the orchard under the open sky, the cellars under the ground.
				part = "piwnica" if _ground_above(row, col) else "sad"
			var on := ""
			if map[row - 1][col] == "#":
				on = "sufit"
			elif map[row + 1][col] == "#":
				on = "podloga"
			elif map[row + 2][col] == "#" and _wall_moves():
				on = "sciana"
			else:
				continue
			# One roll for the cell, then a kind by its share of the chances, so no kind crowds out
			# the others.
			var roll := dice.randf()
			var kind := {}
			for candidate in _decor_kinds:
				if candidate.get("on", "") != on or not candidate.get("parts", ["hall", "dungeon"]).has(part):
					continue
				roll -= float(candidate.get("chance", 0.0))
				if roll < 0.0:
					kind = candidate
					break
			if kind.is_empty():
				continue
			var pictures: Array = kind["pictures"]
			var picture: Texture2D = pictures[dice.randi() % pictures.size()]
			var thing := _fit_decor(row, col, on, picture.get_size() * float(kind.get("scale", 2)), taken, float(kind.get("nad_podloga", 0.0)))
			if thing.is_empty():
				continue
			thing["picture"] = picture
			thing["kind"] = kind
			thing["seed"] = dice.randi()
			thing["eyes"] = kind.has("eyes") and part != "hall" and dice.randf() < 0.7
			_decor.append(thing)
	_place_drips(dice, taken)


## Where a scattered thing of a size goes when it hangs from, stands on or hangs on the wall at a
## cell: {"rect", "on", "col"}, its cells (and DECOR_GAP beside them) marked taken; empty when it
## does not fit there.
## A thing with "nad_podloga" in its kind hangs on a chain low enough to be seen, its bottom that
## many cells above the floor under it.
func _fit_decor(row: int, col: int, on: String, size: Vector2, taken: Dictionary, above := 0.0) -> Dictionary:
	var cells := maxi(ceili(size.x / TILE), 1)
	var x := col * TILE + cells * TILE / 2.0 - size.x / 2.0
	var top: float
	match on:
		"sufit":
			top = row * TILE - 2.0
			if above > 0.0:
				var floor_row := row
				while floor_row < map.size() - 1 and map[floor_row][col] != "#":
					floor_row += 1
				top = maxf(top, floor_row * TILE - above * TILE - size.y)
		"podloga":
			top = (row + 1) * TILE - size.y
		_:
			top = (row + 2) * TILE - 0.7 * TILE - size.y
	var rows := Vector2i(floori((top + 4.0) / TILE), floori((top + size.y - 1.0) / TILE))
	# A low hanging thing keeps clear of the banners and windows hanging over the room.
	for r in range(row, rows.y + 1):
		for c in range(maxi(col - 1, 0), mini(col + cells + 1, map[r].length())):
			if map[r][c] != " " and map[r][c] != "#":
				return {}
	for c in range(col, col + cells):
		if c >= map[row].length():
			return {}
		for r in range(maxi(rows.x, 0), mini(rows.y, map.size() - 1) + 1):
			if map[r][c] != " " or taken.has(Vector2i(c, r)):
				return {}
		match on:
			"sufit":
				if map[row - 1][c] != "#":
					return {}
			"podloga":
				if map[row + 1][c] != "#":
					return {}
			_:
				if map[row + 1][c] != " " or map[row + 2][c] != "#":
					return {}
	if on == "sciana":
		# Not over a column or an entrance of the back wall, nor near a torch or a window.
		var mark := _nearest_mark(row, col)
		if mark.size() == 3 and x < mark[1] + TILE / 2.0 and x + size.x > mark[0] - TILE / 2.0:
			return {}
		for r in range(maxi(rows.x - 2, 0), row + 2):
			for c in range(maxi(col - 3, 0), mini(col + cells + 3, map[r].length())):
				if map[r][c] == "f" or map[r][c] == "o":
					return {}
	for r in range(mini(row, rows.x), rows.y + 1):
		for c in range(col - DECOR_GAP, col + cells + DECOR_GAP):
			taken[Vector2i(c, r)] = true
	return {"rect": Rect2(Vector2(x, top), size), "on": on, "col": col, "hang": row * TILE - 4.0}


## Picks the ceiling cells water drips from, each over a floor not too far down.
func _place_drips(dice: RandomNumberGenerator, taken: Dictionary) -> void:
	if _drip_spec.is_empty():
		return
	var parts: Array = _drip_spec.get("parts", ["dungeon"])
	var chance := float(_drip_spec.get("chance", 0.03))
	for row in range(1, map.size() - 1):
		var part := "dungeon" if _castle_part(row) == "deep" else _castle_part(row)
		if not parts.has(part):
			continue
		for col in range(map[row].length()):
			if map[row][col] != " " or map[row - 1][col] != "#" or taken.has(Vector2i(col, row)):
				continue
			if dice.randf() >= chance:
				continue
			var floor_row := row
			while floor_row < map.size() and floor_row - row < 12 and map[floor_row][col] == " ":
				floor_row += 1
			if floor_row >= map.size() or map[floor_row][col] != "#":
				continue
			var period := dice.randf_range(DRIP_EVERY.x, DRIP_EVERY.y)
			_drips.append({"x": col * TILE + 4.0 * dice.randi_range(4, 12), "from": row * TILE, "to": floor_row * TILE,
				"period": period, "phase": dice.randf() * period})


## Candle flames on the scattered things, eyes in the dark and dripping water, over the dimmed
## level so they shine.
func _draw_glow() -> void:
	if _decor.is_empty() and _drips.is_empty():
		return
	var v := _glow
	var span := _visible_columns()
	for thing in _decor:
		if thing["col"] < span.x - 4 or thing["col"] > span.y + 4:
			continue
		var rect: Rect2 = thing["rect"]
		var scale: float = rect.size.x / thing["picture"].get_width()
		var kind: Dictionary = thing["kind"]
		var phase := float(int(thing["seed"]) % 1000) / 100.0
		var k := 0
		for flame in kind.get("flames", []):
			var at := rect.position + Vector2(flame[0] + 0.5, flame[1] + 0.5) * scale
			var flicker := 0.7 + 0.3 * sin(_anim * 9.0 + k * 1.7 + phase) * sin(_anim * 5.3 + k)
			v.draw_circle(at, 14.0, Color(1.0, 0.7, 0.3, 0.12 * flicker))
			v.draw_circle(at, 6.0, Color(1.0, 0.82, 0.45, 0.3 * flicker))
			v.draw_rect(Rect2(at - Vector2(scale, scale) / 2.0, Vector2(scale, scale * 1.5)), Color(1.0, 0.95, 0.75, 0.8 * flicker))
			k += 1
		if thing["eyes"]:
			# They look out for a while, blink now and then, and hide again.
			var t := fmod(_anim + phase, 7.0)
			if t < 5.0 and absf(t - 2.4) > 0.07 and absf(t - 4.1) > 0.07:
				var eyes: Array = kind["eyes"]
				var middle := rect.position + Vector2(eyes[0], eyes[1]) * scale
				var look := Vector2(roundf(sin(_anim * 0.7 + phase)) * scale, 0)
				for side in [-1.0, 1.0]:
					var eye := middle + look + Vector2(side * 2.0 * scale, 0)
					v.draw_circle(eye, 8.0, Color(1.0, 0.85, 0.3, 0.15))
					v.draw_rect(Rect2(eye - Vector2(scale, scale), Vector2(scale, scale) * 2.0), Color(1.0, 0.9, 0.4, 0.9))
	for drip in _drips:
		var col := int(drip["x"] / TILE)
		if col < span.x - 1 or col > span.y + 1:
			continue
		var t := fmod(_anim + float(drip["phase"]), float(drip["period"]))
		var fall := sqrt(2.0 * (float(drip["to"]) - float(drip["from"])) / DRIP_FALL)
		var water := Color(0.7, 0.85, 1.0, 0.55)
		var x: float = drip["x"]
		if t < 0.6:
			# A drop gathers on the ceiling.
			var grown := 4.0 * ceilf(t / 0.3)
			v.draw_rect(Rect2(x - 2.0, drip["from"], 4.0, grown), water)
		elif t < 0.6 + fall:
			var y: float = drip["from"] + 0.5 * DRIP_FALL * pow(t - 0.6, 2.0)
			v.draw_rect(Rect2(x - 2.0, snappedf(y, 4.0), 4.0, 8.0), water)
		elif t < 0.6 + fall + DRIP_SPLASH:
			var s: float = (t - 0.6 - fall) / DRIP_SPLASH
			var up := snappedf(sin(s * PI) * 10.0, 2.0)
			var fade := Color(water, water.a * (1.0 - s))
			for side in [-1.0, 1.0]:
				v.draw_rect(Rect2(x - 2.0 + side * snappedf(4.0 + 14.0 * s, 2.0), drip["to"] - 4.0 - up, 4.0, 4.0), fade)


## The near shapes, drawn on the screen over the level (see NEAR_PARALLAX).
func _draw_near_things() -> void:
	var v := _foreground
	var zoom := _camera.zoom.x * NEAR_PARALLAX
	var center := _camera.get_screen_center_position()
	for thing in _near_things:
		# Close to the camera, so they slide faster than the level both ways. A chain comes down
		# from above the top of the screen, and only shows while the camera is in its storey.
		var at: Vector2 = (thing["pos"] - center) * zoom + SCREEN / 2.0
		var size: float = thing["size"] * zoom
		if at.x < -300.0 * size or at.x > SCREEN.x + 300.0 * size:
			continue
		var into: float = center.y - thing["pos"].y
		var shade := clampf(into / NEAR_FADE, 0.0, 1.0) * clampf((float(thing["room"]) - into) / NEAR_FADE, 0.0, 1.0)
		if shade <= 0.0:
			continue
		# The camera follows the floor Wiesław stands on (_camera_y), so on the chain's own floor
		# the hook is at its height on the screen, and it slides away as the camera leaves.
		var hook: float = float(thing["hook"]) * SCREEN.y + (float(thing["rest"]) - _camera_y) * _camera.zoom.y * NEAR_PARALLAX
		var top := -10.0
		if hook <= top + 20.0:
			continue
		var dice := RandomNumberGenerator.new()
		dice.seed = thing["seed"]
		if thing["kind"] == "chain" and not _near_pictures.is_empty():
			# A long chain picture with its end at the bottom, swinging slowly from a point high
			# above the screen.
			var picture: Texture2D = _near_pictures[int(thing["seed"]) % _near_pictures.size()]
			var scale := size * _near_scale
			var pivot := Vector2(at.x, -NEAR_SWING_FROM)
			var length := hook - pivot.y
			var shown := minf(length / scale, picture.get_height())
			var tint := NEAR_TINT
			tint.a = shade
			var phase := float(int(thing["seed"]) % 1000)
			var period := NEAR_SWING_TIME * (0.85 + 0.3 * fposmod(phase * 0.618, 1.0))
			var swing := sin(_anim * TAU / period + phase) * NEAR_SWING / length
			v.draw_set_transform(pivot, swing, Vector2.ONE * scale)
			v.draw_texture_rect_region(picture, Rect2(-picture.get_width() / 2.0, (length - shown * scale) / scale, picture.get_width(), shown),
				Rect2(0.0, picture.get_height() - shown, picture.get_width(), shown), tint)
			v.draw_set_transform(Vector2.ZERO)
			continue
		at.y = top
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


## Outdoors, things nearer than Wiesław that slide past faster than the level ("near" in the art
## set): a dark band of ground in front at the bottom of the screen ("ground": a rim picture tiled
## along it) and rare big black mushrooms ("mushrooms"). Both are gone down in the cellars.
func _draw_near_ground(v: Node2D, near: Dictionary) -> void:
	var shown := 1.0 - _below
	if shown <= 0.01:
		return
	var camera_x := _camera.get_screen_center_position().x
	var ground := _layer_ground(1.0)
	var band: Dictionary = near.get("ground", {})
	var picture: Texture2D = band.get("texture")
	var depth := float(band.get("parallax", 1.2))
	var scale := float(band.get("scale", 1.7)) * VIEW_ZOOM
	# Without a band picture the mushrooms grow from just under the screen's bottom edge.
	var top := ground + float(band.get("drop", 70.0)) if picture else ground + float(near.get("mushrooms", {}).get("drop", 200.0))
	if top > SCREEN.y + 40.0:
		return
	# Mushrooms stand on the band, behind its grass, moving with it.
	var mushrooms: Dictionary = near.get("mushrooms", {})
	if not mushrooms.is_empty():
		var ink := Color(str(mushrooms.get("color", "06070c")), shown)
		var rim := Color(str(mushrooms.get("rim", "39456e")), 0.55 * shown)
		var every: Array = mushrooms.get("every", [14, 26])
		var base_y := top + float(band.get("surface", 16.0)) * scale + 30.0
		var grow := float(mushrooms.get("size", 1.0))
		# Clumps along the level, each a few cells on from the last by a fixed dice: one big
		# mushroom, right in front of the camera, with up to two smaller ones beside it.
		var dice := RandomNumberGenerator.new()
		dice.seed = 11
		var x := float(every[0]) * TILE
		var level_end := float(map[0].length() + 10) * TILE
		while x < level_end:
			var at := SCREEN.x / 2.0 + (x - camera_x) * VIEW_ZOOM * depth
			var count := dice.randi_range(1, 3)
			if _near_opening(x):
				# Not in front of a way down: a mushroom there would hide it.
				count = 0
			var size := dice.randf_range(0.8, 1.2) * grow
			for k in 3:
				var small := 1.0 if k == 0 else dice.randf_range(0.4, 0.65)
				var tall := 460.0 * size * small
				var cap := 330.0 * size * small * dice.randf_range(0.85, 1.15)
				var spot := at + (0.0 if k == 0 else dice.randf_range(-1.0, 1.0) * 220.0 * size)
				var lean := dice.randf_range(-0.2, 0.2)
				if k < count and spot > -cap and spot < SCREEN.x + cap:
					_draw_mushroom(v, Vector2(spot, base_y + (0.0 if k == 0 else 20.0)), tall, cap, lean, ink, rim)
			x += dice.randf_range(float(every[0]), float(every[1])) * TILE
	if picture:
		var size := picture.get_size() * scale
		var tint := Color(str(band.get("tint", "2a3048")), shown)
		var x := -fposmod(camera_x * VIEW_ZOOM * depth, size.x)
		while x < SCREEN.x:
			v.draw_texture_rect(picture, Rect2(Vector2(x, top), size), false, tint)
			x += size.x
		# Below the picture, the band goes on dark to the screen's bottom.
		var under := top + size.y * 0.85
		if under < SCREEN.y:
			v.draw_rect(Rect2(0, under, SCREEN.x, SCREEN.y - under), Color(0.01, 0.01, 0.02, shown))


## Whether there is a hole or a ladder in the ground near a place on the surface.
func _near_opening(x: float) -> bool:
	if _floors.size() < 2:
		return false
	var row := int(_floors[0].z / TILE)
	var col := int(x / TILE)
	for c in range(col - 4, col + 5):
		if c >= 0 and c < map[row].length() and map[row][c] != "#":
			return true
	return false


## A big mushroom in silhouette: a slightly bent stem and a domed cap, its top edge faintly lit.
func _draw_mushroom(v: Node2D, foot: Vector2, tall: float, cap: float, lean: float, ink: Color, rim: Color) -> void:
	var top := foot + Vector2(tall * lean, -tall)
	var stem := PackedVector2Array()
	var width := cap * 0.13
	for k in 9:
		var t := k / 8.0
		var p := foot.lerp(top, t) + Vector2(sin(t * PI) * tall * 0.08 * signf(lean + 0.01), 0)
		stem.append(p + Vector2(-width * (1.25 - 0.4 * t), 0))
	for k in range(8, -1, -1):
		var t := k / 8.0
		var p := foot.lerp(top, t) + Vector2(sin(t * PI) * tall * 0.08 * signf(lean + 0.01), 0)
		stem.append(p + Vector2(width * (1.25 - 0.4 * t), 0))
	v.draw_colored_polygon(stem, ink)
	var dome := PackedVector2Array()
	var arc := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		var p := top + Vector2(cos(a) * cap / 2.0, sin(a) * cap * 0.32 + cap * 0.05)
		dome.append(p)
		arc.append(p)
	# A wavy underside of the cap.
	for k in range(6, -1, -1):
		var t := k / 6.0
		dome.append(top + Vector2((t - 0.5) * cap, cap * 0.07 + sin(t * PI * 3.0) * 3.0))
	v.draw_colored_polygon(dome, ink)
	v.draw_polyline(arc, rim, 3.0)


func _draw_foreground() -> void:
	if dungeon and _camera:
		_draw_near_things()
	if not dungeon and not _art.is_empty() and _camera:
		_draw_layers(_foreground, _art["foreground"], _camera.get_screen_center_position().x, false)
		if _art.has("near"):
			_draw_near_ground(_foreground, _art["near"])
	for p in _particles:
		# No leaves fall in the dungeon or down in the cellars.
		if (dungeon or _below > 0.5) and p["leaf"]:
			continue
		var at: Vector2 = p["pos"] - Vector2(20, 20)
		var depth: float = p["depth"]
		if p["leaf"]:
			var turn: float = p["phase"] * 1.3
			_foreground.draw_set_transform(at, turn, Vector2(1.0, absf(sin(turn)) * 0.8 + 0.2) * depth)
			_foreground.draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(0, -3), Vector2(6, 0), Vector2(0, 3)]), p["color"])
		elif night and not dungeon and not _art.get("no_fireflies", false):
			# Fireflies: a slow blink, now and then out for a while.
			var blink := clampf(sin(p["phase"] * 2.1) * 1.6 - 0.2, 0.0, 1.0)
			var firefly := Color(0.78, 1.0, 0.5)
			_foreground.draw_circle(at, 7.0 * depth, Color(firefly, 0.10 * blink))
			_foreground.draw_circle(at, 3.0 * depth, Color(firefly, 0.25 * blink))
			_foreground.draw_circle(at, 1.4 * depth, Color(firefly, 0.95 * blink))
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


## Pale shafts of moonlight fanning down from the moon ("shafts" in the art set's moonlight:
## {"from": [x, y] as screen shares, "color", "strength"}), swaying slowly, over the background
## and behind the level; they fade out when the camera goes down into the cellars.
func _draw_moon_shafts(v: Node2D, shafts: Dictionary) -> void:
	var outside := clampf(_layer_ground(1.0) / (SCREEN.y * 0.35), 0.0, 1.0)
	if outside <= 0.0:
		return
	if shafts.get("world", false):
		_draw_world_shafts(v, shafts, outside)
		return
	# From the moon of a sky drawn in code when there is one, starting right at its edge.
	var moon: Dictionary = _art.get("sky", {}).get("moon", {})
	var from: Array = moon.get("at", shafts.get("from", [0.5, 0.2]))
	var origin := Vector2(float(from[0]) * SCREEN.x, float(from[1]) * SCREEN.y)
	var start := float(moon.get("radius", 120.0)) * 0.95
	var colour := Color(str(shafts.get("color", "c8d4ff")))
	var strength := float(shafts.get("strength", 0.06)) * outside
	# Angle off straight down (radians), width at the far end, share of the strength.
	var beams := [[-0.75, 160.0, 0.7], [-0.42, 90.0, 1.0], [-0.12, 130.0, 0.6], [0.2, 70.0, 0.9], [0.5, 150.0, 0.65], [0.85, 100.0, 0.5]]
	var reach := SCREEN.y * 1.3
	for k in beams.size():
		var beam: Array = beams[k]
		var angle: float = beam[0] + sin(_anim * 0.11 + k * 1.7) * 0.03
		var pulse := 0.75 + 0.25 * sin(_anim * 0.4 + k * 2.3)
		var dir := Vector2(sin(angle), cos(angle))
		var side := Vector2(dir.y, -dir.x)
		var near := origin + dir * start
		var far := origin + dir * reach
		var half: float = beam[1] / 2.0
		var lit := Color(colour, strength * float(beam[2]) * pulse)
		var clear := Color(colour, 0.0)
		v.draw_polygon(PackedVector2Array([near - side * 8.0, near + side * 8.0, far + side * half, far - side * half]),
			PackedColorArray([lit, lit, clear, clear]))


## Moonlight falling between the trees in slanted shafts that stand at places in the level (they
## slide by a little slower than the level, being a little behind it) instead of hanging on the screen.
func _draw_world_shafts(v: Node2D, shafts: Dictionary, outside: float) -> void:
	var colour := Color(str(shafts.get("color", "c8d4ff")))
	var strength := float(shafts.get("strength", 0.06)) * outside
	var depth := float(shafts.get("parallax", 0.9))
	var spacing := float(shafts.get("every", 9)) * TILE
	var lean := float(shafts.get("lean", 0.25))
	var ground := _layer_ground(1.0)
	# The moon is far away, so its light comes down in parallel bands from above the screen's top:
	# no point they start from, all leaning the same way, each a little stronger in its middle.
	var top := -60.0
	var bottom := ground + 30.0
	if bottom <= top:
		return
	var camera_x := _camera.get_screen_center_position().x
	var first := floori((camera_x - SCREEN.x / VIEW_ZOOM / depth) / spacing)
	var drop := (bottom - top) * lean
	for k in range(first, first + int(SCREEN.x / VIEW_ZOOM / depth * 2.0 / spacing) + 3):
		# Each band its own place, width and strength, the same every time.
		var seed := posmod(k * 7919, 1000) / 1000.0
		if posmod(k * 31, 5) == 0:
			continue
		var x := k * spacing + seed * spacing * 0.6
		# Where the band reaches the ground, so it stays at its place there.
		var at := SCREEN.x / 2.0 + (x - camera_x) * VIEW_ZOOM * depth
		var width := 40.0 + seed * 70.0
		var pulse := 0.75 + 0.25 * sin(_anim * 0.35 + k * 2.3)
		for soft in 3:
			var w := width * (1.0 + soft * 0.6)
			var lit := Color(colour, strength * (0.5 + 0.5 * seed) * pulse / 3.0)
			var faint := Color(colour, lit.a * 0.25)
			v.draw_polygon(PackedVector2Array([Vector2(at - drop - w, top), Vector2(at - drop + w, top),
				Vector2(at + w, bottom), Vector2(at - w, bottom)]), PackedColorArray([lit, lit, faint, faint]))


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
	if show_fps:
		# F3: frames per second and draw calls, to see what slows a level down.
		var line := "FPS %d  draw %d" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
		v.draw_string_outline(font, Vector2(SCREEN.x / 2.0 - 90.0, 40), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color.BLACK)
		v.draw_string(font, Vector2(SCREEN.x / 2.0 - 90.0, 40), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
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
		var count_x := 38.0
		if _items.has("mug"):
			var picture: Texture2D = _items["mug"]
			var size := picture.get_size() * (40.0 / picture.get_height())
			v.draw_texture_rect(picture, Rect2(mug + Vector2(0, 26 - size.y), size), false)
			count_x = size.x + 10.0
		else:
			v.draw_rect(Rect2(mug, Vector2(22, 26)), Color("c08a4a"))
			v.draw_rect(Rect2(mug, Vector2(22, 26)), ink, false, 2.0)
			v.draw_rect(Rect2(mug + Vector2(0, -6), Vector2(22, 7)), Color("f4f0e0"))
			v.draw_arc(mug + Vector2(24, 13), 7, -PI / 2, PI / 2, 8, ink, 3.0)
		var count := "x%d (Q)" % mugs
		v.draw_string_outline(font, mug + Vector2(count_x, 24), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, halo)
		v.draw_string(font, mug + Vector2(count_x, 24), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ink)
	var modes: Array[String] = []
	if _music or not _sounds.is_empty():
		modes.append("M: %s" % {"silent": "cisza", "all": "muzyka i dźwięki"}.get(Game.sound, "same dźwięki"))
	if _art_sets.size() > 1:
		modes.append("L: grafika")
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
