class_name GameMenu
extends CanvasLayer
## Main menu and pause menu: new game, save and load slots, settings.
## While it is open the game is paused; the menu itself keeps running.

signal new_game_requested
signal load_requested(slot: int)
signal save_requested(slot: int)
signal resume_requested
signal main_menu_requested

const SCREEN := Vector2(1280, 720)
const TEXT_SPEEDS := {"wolno": 0.7, "normalnie": 1.0, "szybko": 1.5}

var _background: ColorRect
var _box: VBoxContainer
## "main" or "pause": where Back on a sub-page leads.
var _home := "main"
var _page := ""
## Off during mini-games and cutscenes that a save could not restore.
var can_save := true


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_background = ColorRect.new()
	_background.size = SCREEN
	add_child(_background)
	_box = VBoxContainer.new()
	_box.position = Vector2(440, 0)
	_box.custom_minimum_size = Vector2(400, SCREEN.y)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 12)
	add_child(_box)
	hide()


func show_main() -> void:
	_home = "main"
	_background.color = Color("2b1d14")
	_open(_main_page)


func show_pause() -> void:
	_home = "pause"
	_background.color = Color(0, 0, 0, 0.8)
	_open(_pause_page)


func close() -> void:
	hide()
	_page = ""
	get_tree().paused = false


func is_open() -> bool:
	return visible


func _open(page: Callable) -> void:
	show()
	get_tree().paused = true
	page.call()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode != KEY_ESCAPE:
		return
	get_viewport().set_input_as_handled()
	if _page in ["save", "load", "settings"]:
		_back()
	elif _page == "pause":
		resume_requested.emit()


func _back() -> void:
	if _home == "main":
		_main_page()
	else:
		_pause_page()


func _main_page() -> void:
	_start_page("main", "Wiesław", "Baśnie słowiańskie")
	var latest := Game.latest_save()
	if latest >= 0:
		_button("Kontynuuj", func() -> void: load_requested.emit(latest))
	_button("Nowa gra", func() -> void: new_game_requested.emit())
	_button("Wczytaj grę", _slots_page.bind(false), latest < 0)
	_button("Ustawienia", _settings_page)
	if not OS.has_feature("web"):
		_button("Wyjście", func() -> void: get_tree().quit())
	_focus_first()


func _pause_page() -> void:
	_start_page("pause", "Pauza")
	_button("Wróć do gry", func() -> void: resume_requested.emit())
	_button("Zapisz grę", _slots_page.bind(true), not can_save)
	_button("Wczytaj grę", _slots_page.bind(false), Game.latest_save() < 0)
	_button("Ustawienia", _settings_page)
	_button("Menu główne", func() -> void: main_menu_requested.emit())
	_focus_first()


func _slots_page(saving: bool) -> void:
	_start_page("save" if saving else "load", "Zapisz grę" if saving else "Wczytaj grę")
	for slot in Game.SAVE_SLOTS + 1:
		if saving and slot == 0:
			continue
		var data := Game.read_save(slot)
		var slot_name := "Autozapis" if slot == 0 else "Zapis %d" % slot
		var info := "pusty" if data.is_empty() else "%s, %s" % [_room_name(data["room"]), _format_time(data["time"])]
		var on_press: Callable
		if saving:
			on_press = func() -> void:
				save_requested.emit(slot)
				_slots_page(true)
		else:
			on_press = func() -> void: load_requested.emit(slot)
		_button("%s: %s" % [slot_name, info], on_press, not saving and data.is_empty())
	_button("Wstecz", _back)
	_focus_first()


func _settings_page() -> void:
	_start_page("settings", "Ustawienia")
	_button("Pełny ekran: " + ("tak" if Game.fullscreen else "nie"), func() -> void:
		Game.fullscreen = not Game.fullscreen
		apply_fullscreen()
		Game.save_settings()
		_settings_page())
	var speed_name := "normalnie"
	for key in TEXT_SPEEDS:
		if is_equal_approx(TEXT_SPEEDS[key], Game.text_speed):
			speed_name = key
	_button("Szybkość dymków: " + speed_name, func() -> void:
		var names := TEXT_SPEEDS.keys()
		Game.text_speed = TEXT_SPEEDS[names[(names.find(speed_name) + 1) % names.size()]]
		Game.save_settings()
		_settings_page())
	_button("Wstecz", _back)
	_focus_first()


static func apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if Game.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _start_page(page: String, title: String, subtitle := "") -> void:
	_page = page
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	_label(title, 56)
	if subtitle != "":
		_label(subtitle, 24)
	_box.add_child(Control.new())


func _label(text: String, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	_box.add_child(label)


func _button(text: String, on_press: Callable, disabled := false) -> void:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(400, 52)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(on_press)
	_box.add_child(button)


func _focus_first() -> void:
	for child in _box.get_children():
		if child is Button and not child.disabled:
			_grab_focus.call_deferred(child)
			return


## Deferred: the page may have been rebuilt by then and the button freed.
func _grab_focus(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree():
		button.grab_focus()


static func _room_name(id: String) -> String:
	return {"sala": "Sala tronowa", "sad": "Sad", "munina": "Munina"}.get(id, id)


## "2026-10-20 22:15:03" -> "20.10 22:15"
static func _format_time(time: String) -> String:
	if time.length() < 16:
		return time
	return "%s.%s %s" % [time.substr(8, 2), time.substr(5, 2), time.substr(11, 5)]
