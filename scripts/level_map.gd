@tool
class_name LevelMap
extends Node2D
## A platformer level painted in the editor: the Map child is a TileMapLayer painted with the
## tiles of levels/tiles.tres, one picture per map letter (see PlatformerGame for what they mean).
## The game reads the painted cells back into the same text rows it always used. Run the scene
## (F6) to play it straight away.

## The palette's tiles from left to right, as map letters.
const LETTERS := "#=BaxVCPDTSHMOkpjwofbKLuZdhimnrvyEgqFGIJNR"
## Levels are at least this many rows tall, so the camera always has a full screen.
const MIN_ROWS := 12

@export var level_name := ""
@export var night := false
## Castle dungeons: stone and torches instead of the outdoor art, and D is the way out.
@export var dungeon := false:
	set(value):
		dungeon = value
		queue_redraw()
## In the editor, a castle level shows where the backdrop's columns and arches stand and how much
## wall each window (o) and torch (f) takes, as they look when Wiesław stands in front of them.
@export var wall_guides := true:
	set(value):
		wall_guides = value
		queue_redraw()

const GUIDE_BACKDROP := Color(0.55, 0.75, 1.0, 0.22)
const GUIDE_WINDOW := Color(0.4, 1.0, 0.5, 0.9)
const GUIDE_TORCH := Color(1.0, 0.6, 0.2, 0.9)


## The painted level as text rows, the lowest painted row at the bottom.
func to_rows() -> Array[String]:
	var map: TileMapLayer = $Map
	var used := map.get_used_rect()
	var height := maxi(used.size.y, MIN_ROWS)
	var top := used.end.y - height
	var rows: Array[String] = []
	for y in range(top, used.end.y):
		var row := ""
		for x in range(used.position.x, used.end.x):
			var tile := map.get_cell_atlas_coords(Vector2i(x, y))
			row += LETTERS[tile.x] if tile.x >= 0 and tile.x < LETTERS.length() else " "
		rows.append(row)
	return rows


## Name, night and rows of the level scene at path.
static func read(path: String) -> Dictionary:
	var level: LevelMap = load(path).instantiate()
	var spec := {"name": level.level_name, "night": level.night, "dungeon": level.dungeon, "map": level.to_rows()}
	level.free()
	return spec


func _ready() -> void:
	if Engine.is_editor_hint():
		var map := get_node_or_null("Map") as TileMapLayer
		if map and not map.changed.is_connected(queue_redraw):
			map.changed.connect(queue_redraw)
		return
	if get_parent() != get_tree().root:
		return
	# Run on its own (F6): play the painted level.
	Game.load_settings()
	$Map.hide()
	var stage := PlatformerGame.new()
	stage.level_map = to_rows()
	stage.night = night
	stage.dungeon = dungeon
	stage.level_name = level_name
	add_child(stage)
	stage.finished.connect(stage.restart)


func _draw() -> void:
	if not Engine.is_editor_hint() or not dungeon or not wall_guides:
		return
	var map := get_node_or_null("Map") as TileMapLayer
	if not map:
		return
	var used := map.get_used_rect()
	if used.size.x == 0:
		return
	var tile := float(PlatformerGame.TILE)
	var origin := Vector2(used.position) * tile
	# The halls are above the starting ground (P), the dungeons below it.
	var ground := used.end.y
	for cell in map.get_used_cells():
		if _letter(map, cell) == "P":
			ground = cell.y + 1
	var parts := {"hall": Vector2(used.position.y, ground), "dungeon": Vector2(ground, used.end.y)}
	var dir: String = PlatformerGame.CASTLE_DIR + "tlo/"
	if FileAccess.file_exists(dir + "tlo.json"):
		var spec = JSON.parse_string(FileAccess.get_file_as_string(dir + "tlo.json"))
		if spec is Dictionary:
			for part in spec:
				if parts.has(part):
					for layer in spec[part]:
						_draw_backdrop_guides(layer, dir, origin.x, used.end.x * tile, parts[part] * tile)
	var window_size := Vector2(256, 256)
	if ResourceLoader.exists(PlatformerGame.CASTLE_DIR + "window.png"):
		window_size = load(PlatformerGame.CASTLE_DIR + "window.png").get_size()
	var window_scale := PlatformerGame.WINDOW_SCALE
	if FileAccess.file_exists(PlatformerGame.CASTLE_DIR + "window.json"):
		var spec = JSON.parse_string(FileAccess.get_file_as_string(PlatformerGame.CASTLE_DIR + "window.json"))
		if spec is Dictionary:
			window_scale = float(spec.get("scale", window_scale))
	window_size *= window_scale
	var torch_size := Vector2(114, 120)
	if ResourceLoader.exists(PlatformerGame.CASTLE_DIR + "torch_0.png"):
		torch_size = load(PlatformerGame.CASTLE_DIR + "torch_0.png").get_size()
	var wall := PlatformerGame.WALL_PLANE
	for cell in map.get_used_cells():
		var at := Vector2(cell) * tile
		match _letter(map, cell):
			"o":
				# Things on the wall slide closer together by the wall's parallax around their
				# cell's middle, so in the level they take their width divided by it.
				var middle := at.x + tile / 2.0
				var left := middle + (at.x + tile - window_size.x / 2.0 - middle) / wall
				draw_rect(Rect2(left, at.y + tile - 40 - window_size.y, window_size.x / wall, window_size.y), GUIDE_WINDOW, false, 3.0)
			"f":
				var scale := PlatformerGame.TORCH_SCALE
				var flame := at + Vector2(tile / 2.0, 10)
				var left := flame - PlatformerGame.TORCH_FLAME * scale
				draw_rect(Rect2(flame.x + (left.x - flame.x) / wall, left.y, torch_size.x * scale / wall, torch_size.y * scale), GUIDE_TORCH, false, 3.0)


## Bands where a backdrop layer's pictures are not empty, in the rows between span.x and span.y.
func _draw_backdrop_guides(layer: Dictionary, dir: String, from: float, to: float, span: Vector2) -> void:
	if layer.get("fill", false):
		return
	var scale := float(layer.get("scale", 1.0))
	var parallax := float(layer.get("parallax", 1.0))
	# Each picture's columns that have something in them, as runs [start, end).
	var pictures: Array = []
	var width := 0.0
	for file in PlatformerGame.backdrop_files(layer):
		var texture := load(dir + file) as Texture2D if ResourceLoader.exists(dir + file) else null
		var image := texture.get_image() if texture else null
		if not image:
			continue
		if image.is_compressed():
			image.decompress()
		if pictures.is_empty():
			width = image.get_width() * scale
		pictures.append(_solid_runs(image))
	var spacing := PlatformerGame.backdrop_spacing(width, parallax, float(layer.get("spacing", 0.0)))
	if pictures.is_empty() or spacing <= 0.0:
		return
	from += float(layer.get("offset", 0.0)) * PlatformerGame.TILE
	var n := 0
	while from + n * spacing < to:
		for run in pictures[n % pictures.size()]:
			var left: float = from + n * spacing + run.x * scale / parallax
			var right: float = minf(from + n * spacing + run.y * scale / parallax, to)
			if right > left:
				draw_rect(Rect2(left, span.x, right - left, span.y - span.x), GUIDE_BACKDROP)
		n += 1


func _solid_runs(image: Image) -> Array[Vector2]:
	var runs: Array[Vector2] = []
	for x in image.get_width():
		var solid := false
		for y in image.get_height():
			if image.get_pixel(x, y).a > 0.1:
				solid = true
				break
		if solid and not runs.is_empty() and runs[-1].y == x:
			runs[-1].y = x + 1
		elif solid:
			runs.append(Vector2(x, x + 1))
	return runs


func _letter(map: TileMapLayer, cell: Vector2i) -> String:
	var tile := map.get_cell_atlas_coords(cell)
	return LETTERS[tile.x] if tile.x >= 0 and tile.x < LETTERS.length() else " "
