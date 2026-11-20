@tool
class_name LevelDressing
extends Node3D
## The pictures a 2D level is dressed with, laid by hand in 3D:
## flat pictures (Sprite3D) standing between the level and the camera, so nearer ones pass by
## faster and look bigger. The game shows them over the level, seen through a camera that
## follows its own (see PlatformerGame._add_dressing): Wiesław runs on the plane z = 0, behind
## everything here. A level "<name>.tscn" is dressed by "<name>_3d.tscn" when there is one.
## Distances are in metres, 1 m = 100 px of the level (y up, so level y 1000 px is -10 m).
## "Teren" is the level's ground, made from its map, only to lay the pictures by; "Kamera"
## shows in its Preview what the game shows with the camera there. A group's "kolor" meta
## tints every picture in it.

## Across the level plane, the game's view is this many metres high.
static func view_height(zoom: float) -> float:
	return 7.2 / zoom


## How far in front of the level plane a camera with this fov must stand to see it as the game
## does at this zoom.
static func camera_distance(fov: float, zoom: float) -> float:
	return view_height(zoom) / 2.0 / tan(deg_to_rad(fov) / 2.0)


## Readies the pictures for the game: hard pixel edges, cut out where clear, tinted by their
## groups; the ground made to lay them by is left out.
func prepare() -> void:
	var ground := get_node_or_null("Teren") as Node3D
	if ground:
		ground.queue_free()
	for world: WorldEnvironment in find_children("*", "WorldEnvironment", true, false):
		world.queue_free()
	for picture: Sprite3D in find_children("*", "Sprite3D", true, false):
		picture.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		picture.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		picture.shaded = false
		var part: Node = picture
		while part and part != self:
			if part.has_meta("kolor"):
				picture.modulate *= Color(part.get_meta("kolor"))
			part = part.get_parent()
