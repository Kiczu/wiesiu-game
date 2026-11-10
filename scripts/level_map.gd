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

## In the editor, a grid of boxes as big as what the camera shows (SCREEN_CELLS), so rooms can be
## made one screen tall and wide.
@export var screen_guides := true:
	set(value):
		screen_guides = value
		queue_redraw()

## How many cells the camera shows across and down.
const SCREEN_CELLS := Vector2i(25, 14)
const GUIDE_SCREEN := Color(1.0, 0.9, 0.3, 0.35)
const GUIDE_BACKDROP := Color(0.55, 0.75, 1.0, 0.22)
const GUIDE_WINDOW := Color(0.4, 1.0, 0.5, 0.9)
const GUIDE_TORCH := Color(1.0, 0.6, 0.2, 0.9)


## Where the first text row's first cell is, in cells of the Map.
func _first_cell() -> Vector2i:
	var used := ($Map as TileMapLayer).get_used_rect()
	return Vector2i(used.position.x, used.end.y - maxi(used.size.y, MIN_ROWS))


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


## The lights placed in the scene: copies of every PointLight2D under the level (the ready ones
## are in levels/swiatla/), moved to where they stand over the text rows. A light with the
## "migotanie" meta flickers like a flame.
func scene_lights() -> Array:
	var origin := Vector2(_first_cell() * ($Map as TileMapLayer).tile_set.tile_size)
	var lights := []
	for light: PointLight2D in find_children("*", "PointLight2D", true, false):
		var copy: PointLight2D = light.duplicate()
		copy.position = _place_of(light) - origin
		lights.append(copy)
	return lights


## How dark the scene is: the colour of a CanvasModulate placed in it, or clear when there is none.
func scene_darkness() -> Color:
	for shade: CanvasModulate in find_children("*", "CanvasModulate", true, false):
		return shade.color
	return Color(0, 0, 0, 0)


## The groups of pictures laid by hand in the scene, by node name, and the layer each becomes in
## the game: "back" behind the ground, "ground" the ground itself (its drawn rims give way under
## it), "front" in front of Wiesław and "near" right at the screen. Nearer layers move faster
## (see LAYER_DEPTHS); a group inside a group may set its own "glebia".
## A group's colour (modulate) tints everything in it, like a farther or nearer layer.
## How much faster than the level each layer moves, so nearer ones pass by faster, like in depth.
const LAYER_DEPTHS := {"back": -0.15, "ground": 0.0, "front": 0.6, "near": 2.0}
const PICTURE_GROUPS := {"Tył": "back", "Tyl": "back", "Ziemia": "ground", "Przód": "front", "Przod": "front",
	"Pierwszy plan": "near", "Pierwszy_plan": "near", "Blisko": "near"}


## The pictures laid in the scene's picture groups (see PICTURE_GROUPS): for each Sprite2D, a copy
## standing where it stands over the text rows, tinted by the groups it is in, as
## {"layer", "node", "depth"}; "depth" is how much faster than the level it moves (see _depth_of).
func scene_pictures() -> Array:
	var origin := Vector2(_first_cell() * ($Map as TileMapLayer).tile_set.tile_size)
	var pictures := []
	for group in get_children():
		var layer: String = PICTURE_GROUPS.get(String(group.name), "")
		if layer == "" or not group is CanvasItem:
			continue
		for sprite: Sprite2D in group.find_children("*", "Sprite2D", true, false):
			if not sprite.texture or _tint_of(sprite).a <= 0.0:
				continue
			var copy: Sprite2D = sprite.duplicate(0)
			for child in copy.get_children():
				copy.remove_child(child)
				child.free()
			copy.transform = _transform_of(sprite)
			copy.position -= origin
			copy.modulate = _tint_of(sprite)
			pictures.append({"layer": layer, "node": copy, "depth": _depth_of(sprite, LAYER_DEPTHS[layer])})
	return pictures


## How much faster than the level a laid picture moves (slower when below 0): the "glebia" meta
## of the picture or of the nearest group it is in, or the layer's own.
func _depth_of(node: Node, layer_depth: float) -> float:
	var part := node
	while part and part != self:
		if part.has_meta("glebia"):
			return float(part.get_meta("glebia"))
		part = part.get_parent()
	return layer_depth


## How a node under the level is placed in the level: moved, turned and scaled.
func _transform_of(node: Node2D) -> Transform2D:
	var at := Transform2D()
	var part: Node = node
	while part and part != self:
		if part is Node2D:
			at = (part as Node2D).transform * at
		part = part.get_parent()
	return at


## The colour a node under the level is drawn with: its own times every group's it is in, clear
## when it or a group it is in is hidden.
func _tint_of(node: CanvasItem) -> Color:
	var tint := Color.WHITE
	var part: Node = node
	while part and part != self:
		if part is CanvasItem:
			# A hidden group or picture is left out: clear.
			tint *= (part as CanvasItem).modulate if (part as CanvasItem).visible else Color.TRANSPARENT
		part = part.get_parent()
	return tint


## Where a node under the level stands in the level, whatever it is placed in.
func _place_of(node: Node2D) -> Vector2:
	return _transform_of(node).origin


## The scene of pictures laid in 3D in front of the level scene at path (see LevelDressing):
## "<name>_3d.tscn" beside it, or "" when there is none.
static func dressing_of(path: String) -> String:
	var dressing := path.get_basename() + "_3d.tscn"
	return dressing if ResourceLoader.exists(dressing) else ""


## Name, night, rows, lights, darkness and pictures of the level scene at path.
static func read(path: String) -> Dictionary:
	var level: LevelMap = load(path).instantiate()
	var spec := {"name": level.level_name, "night": level.night, "dungeon": level.dungeon, "map": level.to_rows(),
		"lights": level.scene_lights(), "darkness": level.scene_darkness(), "pictures": level.scene_pictures(),
		"dressing": dressing_of(path)}
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
	stage.scene_lights = scene_lights()
	stage.scene_darkness = scene_darkness()
	stage.scene_pictures = scene_pictures()
	stage.dressing_path = dressing_of(scene_file_path)
	# The placed lights, darkness and pictures go into the game; here they would stand in the
	# wrong places.
	for node in find_children("*", "PointLight2D", true, false) + find_children("*", "CanvasModulate", true, false):
		node.queue_free()
	for group in get_children():
		if PICTURE_GROUPS.has(String(group.name)):
			group.queue_free()
	add_child(stage)
	stage.finished.connect(stage.restart)


func _draw() -> void:
	if Engine.is_editor_hint() and screen_guides:
		_draw_screen_guides()
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


## Boxes of one screen each over the painted cells, counted from the left and the bottom.
func _draw_screen_guides() -> void:
	var map := get_node_or_null("Map") as TileMapLayer
	if not map:
		return
	var used := map.get_used_rect()
	if used.size.x == 0:
		return
	var tile := float(PlatformerGame.TILE)
	var left := used.position.x * tile
	var right := used.end.x * tile
	var bottom := used.end.y * tile
	var top := used.position.y * tile
	var x := left
	while x <= right:
		draw_dashed_line(Vector2(x, top), Vector2(x, bottom), GUIDE_SCREEN, 4.0, 24.0)
		x += SCREEN_CELLS.x * tile
	var y := bottom
	while y >= top:
		draw_dashed_line(Vector2(left, y), Vector2(right, y), GUIDE_SCREEN, 4.0, 24.0)
		y -= SCREEN_CELLS.y * tile
