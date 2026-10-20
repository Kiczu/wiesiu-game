class_name Room
extends Node2D
## Base class for locations. A location describes its content in `interact`.

var player: Character
var ui: GameUI
var walk_area := Rect2(60, 480, 1160, 150)
## Character scale at the back and at the front of the walk area (fake perspective).
var far_scale := 0.85
var near_scale := 1.05
## The room the player came from; empty on a new game.
var entered_from := ""
## Set by `go_to`; main switches rooms once the current action finishes.
var pending_exit := ""
## Optional narration shown on the black screen while switching rooms.
var pending_caption := ""
## Optional mini-game played on the way (see main.gd MINIGAMES).
var pending_minigame := ""


func _init() -> void:
	y_sort_enabled = true


func intro() -> void:
	pass


## `verb` is "look", "use" or "item" (use `item` on the object).
## Return false to let Wiesław answer with a generic line.
func interact(_id: String, _verb: String, _item: String) -> bool:
	return false


func go_to(room_id: String, caption := "", minigame := "") -> void:
	pending_exit = room_id
	pending_caption = caption
	pending_minigame = minigame


func say(text: String) -> void:
	await ui.say(player, text)


func say_as(who: Character, text: String) -> void:
	await ui.say(who, text)


func add_character(display_name: String, at: Vector2, body: Color) -> Character:
	var c := Character.new()
	c.display_name = display_name
	c.position = at
	c.body_color = body
	add_child(c)
	return c


func add_hotspot(id: String, display_name: String, at: Vector2, size: Vector2, walk_point: Vector2, art := "") -> Hotspot:
	var h := Hotspot.new()
	h.id = id
	h.display_name = display_name
	h.position = at
	h.size = size
	h.walk_point = walk_point
	h.art = art
	add_child(h)
	return h


func find_hotspot(id: String) -> Hotspot:
	for h in _hotspots():
		if h.id == id:
			return h
	return null


## When hotspots overlap, the one closer to the camera wins.
func hotspot_at(point: Vector2) -> Hotspot:
	var found: Hotspot = null
	for h in _hotspots():
		if h.contains(point) and (found == null or h.position.y > found.position.y):
			found = h
	return found


## The hotspot `who` can reach: they stand next to its base or at its walk point, and it is in front of them
## or right above them. Reach is the same from the left and the right. The closest one wins; objects on the
## floor win over ones hanging on the wall or in the sky above them.
func hotspot_in_reach(who: Character, reach := Vector2(40, 60), walk_point_reach := 50.0) -> Hotspot:
	var best: Hotspot = null
	var best_score := INF
	for h in _hotspots():
		if not h.visible:
			continue
		var dx := h.global_position.x - who.position.x
		var gap_x := maxf(absf(dx) - h.size.x / 2, 0.0)
		if gap_x > 0.0 and signf(dx) != who.facing:
			continue
		var base_y := clampf(h.global_position.y, walk_area.position.y, walk_area.end.y)
		var gap_y := absf(base_y - who.position.y)
		var near_base := gap_x <= reach.x and gap_y <= reach.y
		var walk_distance := who.position.distance_to(clamp_to_walk_area(h.walk_point))
		if not near_base and walk_distance > walk_point_reach:
			continue
		var score := minf(gap_x + gap_y if near_base else INF, walk_distance)
		score += absf(h.global_position.y - base_y) * 0.3 + absf(dx) * 0.1
		if score < best_score:
			best = h
			best_score = score
	return best


func depth_scale(y: float) -> float:
	var depth := clampf(inverse_lerp(walk_area.position.y, walk_area.end.y, y), 0.0, 1.0)
	return lerpf(far_scale, near_scale, depth)


func clamp_to_walk_area(point: Vector2) -> Vector2:
	return point.clamp(walk_area.position, walk_area.end)


func do_interact(h: Hotspot, item: String) -> void:
	await player.walk_to(clamp_to_walk_area(h.walk_point))
	player.face(h.global_position)
	var verb := "item" if item != "" else "use"
	if not await interact(h.id, verb, item):
		await say(_fallback(verb))


func do_look(h: Hotspot) -> void:
	player.face(h.global_position)
	if not await interact(h.id, "look", ""):
		await say(_fallback("look"))


func _fallback(verb: String) -> String:
	var lines: Array = {
		"look": ["Nic ciekawego.", "Hmm. No jest."],
		"use": ["Nie wiem, co miałbym z tym zrobić.", "Wolałbym nie."],
		"item": ["To chyba tak nie działa.", "Nie widzę związku."],
	}[verb]
	return lines.pick_random()


func _hotspots() -> Array[Hotspot]:
	var result: Array[Hotspot] = []
	for child in get_children():
		if child is Hotspot:
			result.append(child)
	return result
