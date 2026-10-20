class_name Hotspot
extends Node2D
## A clickable object. The origin is at its base and `size` extends upwards,
## so y-sorting puts characters correctly in front of or behind it.

@export var id := ""
@export var display_name := ""
@export var size := Vector2(100, 100)
@export var walk_point := Vector2.ZERO
## Placeholder drawing from placeholder_art.gd; empty means invisible.
@export var art := ""

var hovered := false:
	set(value):
		if hovered != value:
			hovered = value
			queue_redraw()


func rect() -> Rect2:
	return Rect2(global_position + Vector2(-size.x / 2, -size.y), size)


func contains(point: Vector2) -> bool:
	return visible and rect().has_point(point)


func _draw() -> void:
	PlaceholderArt.draw(self, art)
	if hovered:
		draw_rect(Rect2(Vector2(-size.x / 2, -size.y), size), Color(1, 1, 0.5, 0.7), false, 2.0)
