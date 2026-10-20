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

	for id in ["jablon", "grabie", "studnia", "wyjscie", "straznik", "ksiaze"]:
		await room.do_look(room.find_hotspot(id))

	await room.do_interact(room.find_hotspot("jablon"), "")
	_check(not Game.has_item("pioro"), "feather cannot be taken without the rake")

	await room.do_interact(room.find_hotspot("grabie"), "")
	_check(Game.has_item("grabie"), "rake in inventory")
	_check(not room.find_hotspot("grabie").visible, "rake removed from the room")

	await room.do_interact(room.find_hotspot("jablon"), "grabie")
	_check(Game.has_item("pioro"), "golden feather in inventory")

	await room.do_interact(room.find_hotspot("straznik"), "pioro")
	_check(Game.flag("straznik_przesluchany"), "guard gave the hint")

	# Where to look, dinner, then "never mind" (four options because the feather is held).
	Game.test_choices = [0, 1, 3]
	await room.do_interact(room.find_hotspot("ksiaze"), "")
	_check(not Game.flag("koniec"), "talking without proof does not end the game")

	Game.test_choices = [2]
	await room.do_interact(room.find_hotspot("ksiaze"), "")
	_check(Game.flag("koniec"), "showing the feather ends the demo")
	_check(main.ui.is_end_shown(), "end screen is shown")

	print("RESULT: " + ("FAIL" if _failed else "OK"))
	get_tree().quit(1 if _failed else 0)


func _check(condition: bool, what: String) -> void:
	print(("  ok    " if condition else "  FAIL  ") + what)
	if not condition:
		_failed = true
