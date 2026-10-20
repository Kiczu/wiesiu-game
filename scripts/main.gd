extends Node2D

const FIRST_ROOM := preload("res://rooms/sad.gd")

var room: Room
var ui: GameUI
## True while a cutscene runs; clicks are ignored then.
var busy := false


func _ready() -> void:
	ui = GameUI.new()
	add_child(ui)
	ui.restart_requested.connect(_restart)
	room = FIRST_ROOM.new()
	room.ui = ui
	add_child(room)
	run(room.intro)


func run(scene: Callable) -> void:
	busy = true
	await scene.call()
	busy = false


func _process(_delta: float) -> void:
	var hovered: Hotspot = null
	if not busy and not ui.is_end_shown():
		hovered = room.hotspot_at(get_global_mouse_position())
	for h in room._hotspots():
		h.hovered = h == hovered
	var text := ""
	if ui.selected_item != "":
		text = "Użyj: " + Game.item_name(ui.selected_item)
		if hovered:
			text += " na " + hovered.display_name
	elif hovered:
		text = hovered.display_name
	ui.set_hover(text)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if ui.is_speaking():
		ui.skip_speech()
		return
	if busy or ui.is_end_shown():
		return
	if ui.is_inventory_open():
		ui.toggle_inventory()
		return
	var point := get_global_mouse_position()
	var h := room.hotspot_at(point)
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if ui.selected_item != "":
			ui.select_item("")
		elif h:
			run(room.do_look.bind(h))
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if h:
			var item := ui.selected_item
			ui.select_item("")
			run(room.do_interact.bind(h, item))
		else:
			room.player.walk_to(room.clamp_to_walk_area(point))


func _restart() -> void:
	Game.reset()
	get_tree().reload_current_scene()
