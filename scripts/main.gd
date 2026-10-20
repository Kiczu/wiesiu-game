extends Node2D

const ROOMS := {
	"sala": preload("res://rooms/sala.gd"),
	"sad": preload("res://rooms/sad.gd"),
	"munina": preload("res://rooms/munina.gd"),
}
const FIRST_ROOM := "sala"

var room: Room
var room_id := ""
var ui: GameUI
## True while a cutscene runs; clicks are ignored then.
var busy := false
## Last input came from the keyboard: the hotspot in front of Wiesław is the target, not the one under the mouse.
var keyboard_mode := false

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"look": [KEY_Q],
	"inventory": [KEY_I, KEY_TAB],
	"cancel": [KEY_ESCAPE],
}


func _ready() -> void:
	_bind_keys()
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
		if room.pending_caption != "":
			await ui.show_caption(room.pending_caption)
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


func _bind_keys() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func _can_play() -> bool:
	return not busy and not ui.is_end_shown() and not ui.is_inventory_open()


func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO and _can_play():
		keyboard_mode = true
		room.player.step(direction, delta, room.walk_area)
	var hovered: Hotspot = null
	if not busy and not ui.is_end_shown():
		if keyboard_mode:
			hovered = room.hotspot_in_reach(room.player)
		else:
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
	if keyboard_mode and hovered:
		var top := hovered.rect()
		ui.set_hover(text, Vector2(top.get_center().x, maxf(top.position.y, 40.0)))
	else:
		ui.set_hover(text)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		keyboard_mode = false
	elif event is InputEventKey and event.pressed and not event.echo:
		_on_key(event)
		return
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


func _on_key(event: InputEventKey) -> void:
	var number := event.physical_keycode - KEY_1
	if ui.is_speaking():
		if event.is_action("interact") or event.is_action("cancel"):
			ui.skip_speech()
		return
	if ui.is_choosing():
		if number >= 0 and number < 9:
			ui.pick_choice(number)
		return
	if busy or ui.is_end_shown():
		return
	keyboard_mode = true
	if event.is_action("inventory"):
		ui.toggle_inventory()
	elif event.is_action("cancel"):
		if ui.is_inventory_open():
			ui.toggle_inventory()
		else:
			ui.select_item("")
	elif number >= 0 and number < 9:
		if number < Game.inventory.size():
			var id := Game.inventory[number]
			ui.select_item("" if ui.selected_item == id else id)
	elif ui.is_inventory_open():
		return
	elif event.is_action("interact"):
		var h := room.hotspot_in_reach(room.player)
		if h:
			var item := ui.selected_item
			ui.select_item("")
			run(room.do_interact.bind(h, item))
	elif event.is_action("look"):
		var h := room.hotspot_in_reach(room.player)
		if h:
			run(room.do_look.bind(h))


func _restart() -> void:
	Game.reset()
	get_tree().reload_current_scene()
