class_name GameUI
extends CanvasLayer

signal restart_requested
signal choice_made(index: int)

const SCREEN := Vector2(1280, 720)
const BACKPACK_SIZE := Vector2(84, 84)
const BUBBLE_MAX_WIDTH := 460.0
const BUBBLE_FONT_SIZE := 21
const INK := Color("1a1a1a")

var selected_item := ""

var _hover_label: Label
var _bubble: PanelContainer
var _bubble_text: Label
var _tail: Polygon2D
var _tail_outline: Line2D
var _backpack: BackpackButton
var _inventory_panel: PanelContainer
var _inventory_grid: GridContainer
var _choices: VBoxContainer
var _end_screen: Control
var _end_title: Label
var _end_text: Label
var _fade: ColorRect
var _speaking := false
var _skip := false


func _ready() -> void:
	_build()
	Game.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()


func say(who: Character, text: String) -> void:
	await _show_bubble(who.head_position(), text)
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
	_bubble.hide()
	_tail.hide()
	_tail_outline.hide()


## Comic-style balloon above the speaker, with a tail pointing at their head.
func _show_bubble(head: Vector2, text: String) -> void:
	_bubble_text.text = text.to_upper()
	var font := _bubble_text.get_theme_font("font")
	var text_width := font.get_string_size(_bubble_text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_FONT_SIZE).x
	var width := minf(text_width + 4, BUBBLE_MAX_WIDTH)
	_bubble_text.custom_minimum_size.x = width
	_bubble_text.size = Vector2(width, 0)
	_bubble.modulate.a = 0.0
	_bubble.show()
	_bubble.reset_size()
	# Let the containers settle so the wrapped height is known before placing the balloon.
	if not Game.fast:
		for i in 3:
			await get_tree().process_frame
			_bubble.reset_size()
	var size := _bubble.size
	var bottom := maxf(head.y - 36, size.y + 10)
	var left := clampf(head.x - size.x / 2, 10, SCREEN.x - size.x - 10)
	_bubble.position = Vector2(left, bottom - size.y)
	var base_x := clampf(head.x, left + 30, left + size.x - 30)
	var tip := Vector2(head.x, maxf(head.y - 6, bottom + 14))
	var base_left := Vector2(base_x - 14, bottom - 3)
	var base_right := Vector2(base_x + 14, bottom - 3)
	_tail.polygon = PackedVector2Array([base_left, tip, base_right])
	_tail_outline.points = PackedVector2Array([base_left, tip, base_right])
	_bubble.modulate.a = 1.0
	_tail.show()
	_tail_outline.show()


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


func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	if Game.fast:
		_fade.modulate.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, 0.35)
	await tween.finished


func show_end(title: String, text: String) -> void:
	_end_title.text = title
	_end_text.text = text
	_end_screen.show()


func is_end_shown() -> bool:
	return _end_screen.visible


func _build() -> void:
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.size = SCREEN
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

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

	_bubble = PanelContainer.new()
	var balloon := StyleBoxFlat.new()
	balloon.bg_color = Color.WHITE
	balloon.border_color = INK
	balloon.set_border_width_all(3)
	balloon.set_corner_radius_all(24)
	balloon.content_margin_left = 18
	balloon.content_margin_right = 18
	balloon.content_margin_top = 10
	balloon.content_margin_bottom = 12
	_bubble.add_theme_stylebox_override("panel", balloon)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.hide()
	add_child(_bubble)
	_bubble_text = Label.new()
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_text.add_theme_font_size_override("font_size", BUBBLE_FONT_SIZE)
	_bubble_text.add_theme_color_override("font_color", INK)
	_bubble_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_bubble_text)
	_tail = Polygon2D.new()
	_tail.color = Color.WHITE
	_tail.hide()
	add_child(_tail)
	_tail_outline = Line2D.new()
	_tail_outline.width = 3.0
	_tail_outline.default_color = INK
	_tail_outline.hide()
	add_child(_tail_outline)

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
