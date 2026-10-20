extends Node
## Plays the whole demo without clicks and checks it can be finished.
## Run: godot --headless --path . res://tests/walkthrough.tscn

var _failed := false


func _ready() -> void:
	Game.fast = true
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var room: Room = main.room

	for id in ["jablon", "beczka", "pieniek", "krzaki", "wyjscie", "czeslaw", "leslaw"]:
		await room.do_look(room.find_hotspot(id))
	_check(not room.find_hotspot("wikingowie").visible, "no Vikings before nightfall")

	await room.do_interact(room.find_hotspot("krzaki"), "")
	_check(not Game.flag("noc"), "hiding does not work while Czesław counts")

	Game.test_choices = [0, 1, 2, 3]
	await room.do_interact(room.find_hotspot("leslaw"), "")

	await room.do_interact(room.find_hotspot("pieniek"), "")
	_check(Game.has_item("kubek"), "cup in inventory")
	await room.do_interact(room.find_hotspot("beczka"), "kubek")
	_check(Game.has_item("nalewka") and not Game.has_item("kubek"), "cup filled with mead")
	await room.do_interact(room.find_hotspot("czeslaw"), "nalewka")
	_check(Game.flag("czeslaw_spi"), "Czesław asleep")

	await room.do_interact(room.find_hotspot("jablon"), "")
	_check(Game.has_item("jablko"), "apple in inventory")

	await room.do_interact(room.find_hotspot("krzaki"), "")
	_check(Game.flag("noc"), "night fell")
	_check(room.find_hotspot("wikingowie").visible, "Vikings arrived")

	await room.do_interact(room.find_hotspot("wikingowie"), "")
	_check(not Game.has_item("oko"), "talking alone does not give the eye")
	await room.do_interact(room.find_hotspot("wikingowie"), "jablko")
	_check(Game.has_item("oko"), "magic eye in inventory")

	await room.do_interact(room.find_hotspot("wikingowie"), "oko")
	_check(Game.flag("jablka_odzyskane"), "apples recovered")
	_check(Game.flag("koniec"), "demo finished")
	_check(main.ui.is_end_shown(), "end screen is shown")

	print("RESULT: " + ("FAIL" if _failed else "OK"))
	get_tree().quit(1 if _failed else 0)


func _check(condition: bool, what: String) -> void:
	print(("  ok    " if condition else "  FAIL  ") + what)
	if not condition:
		_failed = true
