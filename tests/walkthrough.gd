extends Node
## Plays the whole demo without clicks and checks it can be finished.
## Run: godot --headless --path . res://tests/walkthrough.tscn

var _failed := false
var _main: Node


func _ready() -> void:
	Game.fast = true
	Game.save_prefix = "user://test_save_"
	_main = load("res://scenes/main.tscn").instantiate()
	_main.skip_menu = true
	add_child(_main)
	await get_tree().process_frame

	_check(_main.room_id == "sala", "the game starts in the throne room")
	for id in ["okno", "sztandar", "tron", "stol", "drzwi", "ksiaze"]:
		await _main.run(_main.room.do_look.bind(_main.room.find_hotspot(id)))
	Game.test_choices = [0, 1, 2, 3]
	await _do("ksiaze")
	var player: Character = _main.room.player
	player.step(Vector2.LEFT, 100.0, _main.room.walk_area)
	_check(player.position.x == _main.room.walk_area.position.x, "keyboard walking stays inside the walk area")
	player.position = Vector2(540, 600)
	player.facing = -1
	var reached: Hotspot = _main.room.hotspot_in_reach(player)
	_check(reached == null or reached.id != "stol", "the table is out of reach from further away on the same line")
	player.position = Vector2(420, 600)
	player.facing = 1
	_check(_main.room.hotspot_in_reach(player) == null, "the table is not highlighted behind Wiesław's back")
	player.facing = -1
	_check(_main.room.hotspot_in_reach(player).id == "stol", "the table is in reach when facing it")
	player.position = Vector2(230, 600)
	player.facing = 1
	_check(_main.room.hotspot_in_reach(player).id == "stol", "the table is in reach from the left side too")
	player.position = Vector2(420, 600)
	player.facing = -1
	await _press(KEY_E)
	_check(Game.has_item("kubek"), "cup taken with the E key")
	await _press(KEY_1)
	_check(_main.ui.selected_item == "kubek", "key 1 selects the first item")
	await _press(KEY_ESCAPE)
	_check(_main.ui.selected_item == "", "Esc puts the item back")
	await _press(KEY_ESCAPE)
	_check(_main.menu.is_open() and get_tree().paused, "Esc with nothing selected opens the pause menu")
	_main.menu.resume_requested.emit()
	_check(not _main.menu.is_open() and not get_tree().paused, "resuming closes the menu")
	_main.menu.save_requested.emit(1)
	var saved := Game.read_save(1)
	_check(saved.get("room") == "sala" and "kubek" in saved.get("inventory", []), "the game is saved to slot 1")

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
	_check(_main.room_id == "munina", "the drakkar flies to Munina, through the flight mini-game")
	_check(not _main.ui.is_end_shown(), "Book I does not end the demo")

	for id in ["drakkar", "karczma", "garnek", "kurnik", "kociol", "chlopi", "karczmarz", "rokita"]:
		await _main.run(_main.room.do_look.bind(_main.room.find_hotspot(id)))
	await _do("drakkar")
	_check(_main.room_id == "munina" and not Game.flag("koniec"), "cannot leave before helping the innkeeper")
	await _do("chlopi")
	await _do("rokita")
	await _do("karczmarz")
	_check(Game.flag("karczmarz_prosil"), "innkeeper asked for help")
	await _do("garnek")
	await _do("kociol", "garnek")
	_check(Game.has_item("smola"), "pot of tar in inventory")
	await _do("rokita", "smola")
	_check(not Game.flag("rokita_w_zalodze"), "tar alone is not enough")
	await _do("kurnik")
	_check(Game.has_item("pierze"), "feathers in inventory")
	await _do("rokita", "pierze")
	_check(Game.flag("rokita_w_zalodze"), "Rokita joins the crew")
	await _do("drakkar")
	_check(not Game.flag("koniec"), "cannot leave before the reward")
	await _do("karczmarz")
	_check(Game.flag("barany"), "three rams as the reward")
	await _do("drakkar")
	_check(Game.flag("koniec"), "demo finished")
	_check(_main.ui.is_end_shown(), "end screen is shown")

	await _check_flight_game()

	_check(Game.load_game(1) == "sala", "loading slot 1 returns the throne room")
	_check(Game.has_item("kubek") and not Game.flag("koniec"), "loading restores the inventory and progress")
	_check(Game.load_game(2) == "", "an empty slot loads nothing")
	for slot in Game.SAVE_SLOTS + 1:
		DirAccess.remove_absolute(Game.save_prefix + str(slot) + ".json")

	print("RESULT: " + ("FAIL" if _failed else "OK"))
	get_tree().quit(1 if _failed else 0)


func _check_flight_game() -> void:
	Game.fast = false
	var flight := FlightGame.new()
	add_child(flight)
	flight.set_process(false)
	Game.fast = true
	var ship := Vector2(FlightGame.SHIP_X, flight.ship_y)
	flight.objects.append({"kind": "apple", "pos": ship, "speed": 0.0})
	flight.step(0.016, 0.0)
	_check(flight.apples == 1 and flight.lives == FlightGame.LIVES, "flight: catching an apple")
	flight.objects.append({"kind": "bird", "pos": ship, "speed": 0.0})
	flight.step(0.016, 0.0)
	_check(flight.lives == FlightGame.LIVES - 1, "flight: a bird costs a life")
	for i in 2:
		flight.objects.append({"kind": "cloud", "pos": ship, "speed": 0.0})
		flight.step(0.016, 0.0)
	_check(flight.state == "lost", "flight: three hits and the flight is lost")
	flight._restart()
	_check(flight.state == "" and flight.lives == FlightGame.LIVES, "flight: starting over")
	flight.step(1.0, -1.0)
	_check(flight.ship_y >= 90.0, "flight: the ship stays on screen")
	while flight.state == "":
		flight.objects.clear()
		flight.step(0.5, 0.0)
	_check(flight.state == "won", "flight: reaching the end wins")
	flight.queue_free()


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	_main._unhandled_input(event)
	while _main.busy:
		await get_tree().process_frame


func _do(id: String, item := "") -> void:
	await _main.run(_main.room.do_interact.bind(_main.room.find_hotspot(id), item))


func _check(condition: bool, what: String) -> void:
	print(("  ok    " if condition else "  FAIL  ") + what)
	if not condition:
		_failed = true
