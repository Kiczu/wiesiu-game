extends Node
## Plays the whole demo without clicks and checks it can be finished.
## Run: godot --headless --path . res://tests/walkthrough.tscn

var _failed := false
var _main: Node


func _ready() -> void:
	Game.fast = true
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await get_tree().process_frame

	_check(_main.room_id == "sala", "the game starts in the throne room")
	for id in ["okno", "sztandar", "tron", "stol", "drzwi", "ksiaze"]:
		await _main.run(_main.room.do_look.bind(_main.room.find_hotspot(id)))
	Game.test_choices = [0, 1, 2, 3]
	await _do("ksiaze")
	await _do("stol")
	_check(Game.has_item("kubek"), "cup in inventory")

	await _do("drzwi")
	_check(_main.room_id == "sad", "the door leads to the orchard")
	for id in ["jablon", "beczka", "krzaki", "wyjscie", "czeslaw", "leslaw"]:
		await _main.run(_main.room.do_look.bind(_main.room.find_hotspot(id)))
	_check(not _main.room.find_hotspot("wikingowie").visible, "no Vikings before nightfall")

	await _do("wyjscie")
	_check(_main.room_id == "sala", "the orchard exit leads back to the throne room")
	await _do("drzwi")

	await _do("krzaki")
	_check(not Game.flag("noc"), "hiding does not work while Czesław counts")
	Game.test_choices = [0, 1, 2, 3]
	await _do("leslaw")

	await _do("beczka", "kubek")
	_check(Game.has_item("nalewka") and not Game.has_item("kubek"), "cup filled with mead")
	await _do("czeslaw", "nalewka")
	_check(Game.flag("czeslaw_spi"), "Czesław asleep")
	await _do("jablon")
	_check(Game.has_item("jablko"), "apple in inventory")

	await _do("krzaki")
	_check(Game.flag("noc"), "night fell")
	_check(_main.room.find_hotspot("wikingowie").visible, "Vikings arrived")
	await _do("wyjscie")
	_check(_main.room_id == "sad", "cannot leave during the ambush")

	await _do("wikingowie")
	_check(not Game.has_item("oko"), "talking alone does not give the eye")
	await _do("wikingowie", "jablko")
	_check(Game.has_item("oko"), "magic eye in inventory")
	await _do("wikingowie", "oko")
	_check(Game.flag("jablka_odzyskane"), "apples recovered")
	_check(Game.flag("koniec"), "demo finished")
	_check(_main.ui.is_end_shown(), "end screen is shown")

	print("RESULT: " + ("FAIL" if _failed else "OK"))
	get_tree().quit(1 if _failed else 0)


func _do(id: String, item := "") -> void:
	await _main.run(_main.room.do_interact.bind(_main.room.find_hotspot(id), item))


func _check(condition: bool, what: String) -> void:
	print(("  ok    " if condition else "  FAIL  ") + what)
	if not condition:
		_failed = true
