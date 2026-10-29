class_name LevelMap
extends Node2D
## A platformer level painted in the editor: the Map child is a TileMapLayer painted with the
## tiles of levels/tiles.tres, one picture per map letter (see PlatformerGame for what they mean).
## The game reads the painted cells back into the same text rows it always used. Run the scene
## (F6) to play it straight away.

## The palette's tiles from left to right, as map letters.
const LETTERS := "#=BaxVCPDTSHM"
## Levels are at least this many rows tall, so the camera always has a full screen.
const MIN_ROWS := 12

@export var level_name := ""
@export var night := false


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
	var spec := {"name": level.level_name, "night": level.night, "map": level.to_rows()}
	level.free()
	return spec


func _ready() -> void:
	if get_parent() != get_tree().root:
		return
	# Run on its own (F6): play the painted level.
	$Map.hide()
	var stage := PlatformerGame.new()
	stage.level_map = to_rows()
	stage.night = night
	stage.level_name = level_name
	add_child(stage)
	stage.finished.connect(stage.restart)
