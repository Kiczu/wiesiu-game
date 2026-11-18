class_name GameUI
extends CanvasLayer
## The end screen shown after the last comic page, with a way back to the main menu.

signal restart_requested

const SCREEN := Vector2(1280, 720)

var _end_screen: Control
var _end_title: Label
var _end_text: Label


func _ready() -> void:
	_build()


func show_end(title: String, text: String) -> void:
	_end_title.text = title
	_end_text.text = text
	_end_screen.show()


func is_end_shown() -> bool:
	return _end_screen.visible


func _build() -> void:
	_end_screen = ColorRect.new()
	_end_screen.color = Color(0, 0, 0, 0.75)
	_end_screen.size = SCREEN
	_end_screen.hide()
	add_child(_end_screen)
	var towel := UiSkin.towel(Rect2(201, 150, 879, 420))
	if towel:
		_end_screen.add_child(towel)
	var box := VBoxContainer.new()
	if towel:
		box.theme = UiSkin.theme()
	box.position = Vector2(240, 245)
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
	again.text = "Menu główne"
	again.add_theme_font_size_override("font_size", 24)
	again.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(again)
