class_name GameUI
extends CanvasLayer

signal restart_requested
signal choice_made(index: int)

const SCREEN := Vector2(1280, 720)
const BACKPACK_SIZE := Vector2(84, 84)

var selected_item := ""

var _hover_label: Label
var _speech: Label
var _backpack: BackpackButton
var _inventory_panel: PanelContainer
var _inventory_grid: GridContainer
var _choices: VBoxContainer
var _end_screen: Control
var _end_title: Label
var _end_text: Label
var _speaking := false
var _skip := false


func _ready() -> void:
	_build()
	Game.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()


func say(who: Character, text: String) -> void:
	_speech.text = text
	_speech.add_theme_color_override("font_color", who.speech_color)
	var head := who.head_position()
	_speech.position = Vector2(
		clampf(head.x - _speech.size.x / 2, 10, SCREEN.x - _speech.size.x - 10),
		maxf(head.y - _speech.size.y, -80))
	_speech.show()
	who.talking = true
	_speaking = true
	_skip = false
	var duration := 0.0 if Game.fast else 1.5 + text.length() * 0.06
	var elapsed := 0.0
	while elapsed < duration and not _skip:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_speaking = false
	who.talking = false
	_speech.hide()


func is_speaking() -> bool:
	return _speaking


func skip_speech() -> void:
	_skip = true


func choose(options: Array) -> int:
	if Game.fast and not Game.test_choices.is_empty():
		return Game.test_choices.pop_front()
	for child in _choices.get_children():
		child.queue_free()
	for i in options.size():
		var button := Button.new()
		button.text = options[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(func() -> void: choice_made.emit(i))
		_choices.add_child(button)
	_choices.show()
	var index: int = await choice_made
	_choices.hide()
	return index


func set_hover(text: String) -> void:
	_hover_label.text = text


func select_item(id: String) -> void:
	selected_item = id
	if id != "":
		_inventory_panel.hide()
	_refresh_inventory()


func is_inventory_open() -> bool:
	return _inventory_panel.visible


func toggle_inventory() -> void:
	_inventory_panel.visible = not _inventory_panel.visible


func _process(_delta: float) -> void:
	_hover_label.position = get_viewport().get_mouse_position() + Vector2(18, 12)


func _refresh_inventory() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()
	for id in Game.inventory:
		var button := Button.new()
		button.text = Game.item_name(id)
		button.icon = _color_icon(Game.ITEMS[id]["color"])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size = Vector2(150, 110)
		button.toggle_mode = true
		button.button_pressed = id == selected_item
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(func() -> void: select_item("" if selected_item == id else id))
		_inventory_grid.add_child(button)
	if Game.inventory.is_empty():
		var empty := Label.new()
		empty.text = "Pusto. Nawet okruszków nie ma."
		empty.add_theme_font_size_override("font_size", 18)
		_inventory_grid.add_child(empty)
	_backpack.count = Game.inventory.size()
	_backpack.selected_color = Game.ITEMS[selected_item]["color"] if selected_item != "" else Color.TRANSPARENT


func _color_icon(color: Color) -> Texture2D:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func show_end(title: String, text: String) -> void:
	_end_title.text = title
	_end_text.text = text
	_end_screen.show()


func is_end_shown() -> bool:
	return _end_screen.visible


func _build() -> void:
	var hint := Label.new()
	hint.text = "Lewy przycisk: idź / użyj    Prawy: obejrzyj (albo odłóż przedmiot)    Plecak: prawy dolny róg"
	hint.position = Vector2(12, 8)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	_backpack = BackpackButton.new()
	_backpack.position = SCREEN - BACKPACK_SIZE - Vector2(16, 16)
	_backpack.size = BACKPACK_SIZE
	_backpack.tooltip_text = "Plecak"
	_backpack.pressed.connect(toggle_inventory)
	add_child(_backpack)

	_inventory_panel = PanelContainer.new()
	_inventory_panel.hide()
	add_child(_inventory_panel)
	var padding := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 14)
	_inventory_panel.add_child(padding)
	var inventory_box := VBoxContainer.new()
	inventory_box.add_theme_constant_override("separation", 10)
	padding.add_child(inventory_box)
	var title := Label.new()
	title.text = "Plecak Wiesława"
	title.add_theme_font_size_override("font_size", 22)
	inventory_box.add_child(title)
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 4
	_inventory_grid.add_theme_constant_override("h_separation", 8)
	_inventory_grid.add_theme_constant_override("v_separation", 8)
	inventory_box.add_child(_inventory_grid)
	_inventory_panel.resized.connect(func() -> void:
		_inventory_panel.position = _backpack.position + Vector2(BACKPACK_SIZE.x, 0) - _inventory_panel.size - Vector2(0, 12))

	_speech = Label.new()
	_speech.size = Vector2(560, 160)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_speech.add_theme_font_size_override("font_size", 26)
	_speech.add_theme_constant_override("outline_size", 10)
	_speech.add_theme_color_override("font_outline_color", Color.BLACK)
	_speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech.hide()
	add_child(_speech)

	_choices = VBoxContainer.new()
	_choices.position = Vector2(40, 380)
	_choices.add_theme_constant_override("separation", 6)
	_choices.hide()
	add_child(_choices)

	_hover_label = Label.new()
	_hover_label.add_theme_font_size_override("font_size", 20)
	_hover_label.add_theme_constant_override("outline_size", 8)
	_hover_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_label)

	_end_screen = ColorRect.new()
	_end_screen.color = Color(0, 0, 0, 0.75)
	_end_screen.size = SCREEN
	_end_screen.hide()
	add_child(_end_screen)
	var box := VBoxContainer.new()
	box.position = Vector2(240, 220)
	box.custom_minimum_size = Vector2(800, 0)
	box.add_theme_constant_override("separation", 24)
	_end_screen.add_child(box)
	_end_title = Label.new()
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.add_theme_font_size_override("font_size", 48)
	box.add_child(_end_title)
	_end_text = Label.new()
	_end_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_text.add_theme_font_size_override("font_size", 24)
	box.add_child(_end_text)
	var again := Button.new()
	again.text = "Zagraj jeszcze raz"
	again.add_theme_font_size_override("font_size", 24)
	again.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(again)


class BackpackButton extends Button:
	var count := 0:
		set(value):
			count = value
			queue_redraw()
	var selected_color := Color.TRANSPARENT:
		set(value):
			selected_color = value
			queue_redraw()

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var outline := Color("2b1d14")
		var lift := -4.0 if is_hovered() else 0.0
		var body := Rect2(Vector2(14, 22 + lift), Vector2(56, 58))
		draw_arc(Vector2(42, 22 + lift), 14, PI, TAU, 16, outline, 5.0)
		draw_rect(body, Color("8b5a2b"))
		draw_rect(body, outline, false, 3.0)
		draw_rect(Rect2(Vector2(14, 22 + lift), Vector2(56, 22)), Color("6b4423"))
		draw_rect(Rect2(Vector2(14, 22 + lift), Vector2(56, 22)), outline, false, 3.0)
		draw_rect(Rect2(Vector2(36, 38 + lift), Vector2(12, 10)), Color("e0a832"))
		if selected_color.a > 0:
			draw_circle(Vector2(18, 74), 12, selected_color)
			draw_arc(Vector2(18, 74), 12, 0, TAU, 16, outline, 2.0)
		if count > 0:
			draw_circle(Vector2(70, 18), 13, Color("d62828"))
			draw_string(ThemeDB.fallback_font, Vector2(64, 25), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
