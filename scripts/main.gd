extends Node2D

const ROOMS := {
	"sala": preload("res://rooms/sala.gd"),
	"sad": preload("res://rooms/sad.gd"),
}
const FIRST_ROOM := "sala"

var room: Room
var room_id := ""
var ui: GameUI
## True while a cutscene runs; clicks are ignored then.
var busy := false


func _ready() -> void:
	ui = GameUI.new()
	add_child(ui)
	ui.restart_requested.connect(_restart)
	_enter_room(FIRST_ROOM)
	run(room.intro)


func run(scene: Callable) -> void:
	busy = true
	await scene.call()
	while room.pending_exit != "":
		await ui.fade_out()
		_enter_room(room.pending_exit)
		await ui.fade_in()
		await room.intro()
	busy = false


func _enter_room(id: String) -> void:
	var from := room_id
	if room:
		remove_child(room)
		room.queue_free()
	room = ROOMS[id].new()
	room.ui = ui
	room.entered_from = from
	room_id = id
	add_child(room)


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
