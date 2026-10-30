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
	await _check_platformer()

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


func _check_platformer() -> void:
	var level := PlatformerGame.new()
	level.layout = "mario"
	level.auto_input = true
	add_child(level)
	await _physics(20)
	var player := level.player
	_check(player.is_on_floor() and is_equal_approx(player.position.y, 640.0), "platformer: Wiesław stands on the ground")
	var start_x := player.position.x
	level.input_x = 1.0
	await _physics(20)
	level.input_x = 0.0
	_check(player.position.x > start_x + 60.0, "platformer: walking right")
	level.input_jump = true
	var top := player.position.y
	for i in 60:
		await _physics(1)
		top = minf(top, player.position.y)
	level.input_jump = false
	await _physics(30)
	var rise := 640.0 - top
	_check(rise > 3.0 * PlatformerGame.TILE and rise < 4.0 * PlatformerGame.TILE, "platformer: a full jump clears three tiles (%d px)" % rise)
	# A second press in the air jumps again.
	player.position = Vector2(5.5 * PlatformerGame.TILE, 640.0)
	player.velocity = Vector2.ZERO
	await _physics(5)
	level.input_jump = true
	await _physics(20)
	level.input_jump = false
	await _physics(2)
	var falling_from := player.position.y
	level.input_jump = true
	await _physics(25)
	level.input_jump = false
	_check(player.position.y < falling_from - PlatformerGame.TILE, "platformer: a second press in the air jumps again")
	await _physics(80)
	# Throw two apples at a Viking.
	var viking: Node2D = level.vikings[0]["node"]
	for other in level.vikings:
		if other["node"].position.x < viking.position.x:
			viking = other["node"]
	var count := level.vikings.size()
	var throws := PlatformerGame.VIKING_HEALTH / PlatformerGame.APPLE_DAMAGE
	level.apples = throws
	for throw in throws:
		# Clear of the pit before him.
		viking.position.x = 34.5 * PlatformerGame.TILE
		player.position = viking.position + Vector2(-180, 0)
		player.velocity = Vector2.ZERO
		level._wieslaw.facing = 1
		await _physics(2)
		level.throw_apple()
		await _physics(40)
	_check(level.vikings.size() == count - 1 and level.apples == 0 and level.lives == PlatformerGame.LIVES, "platformer: thrown apples knock a Viking out")
	await _physics(60)
	# Enough sword hits knock a Viking out.
	viking = level.vikings[0]["node"]
	count = level.vikings.size()
	var hit_once := false
	for hit in PlatformerGame.VIKING_HEALTH / level.sword_damage:
		player.position = viking.position + Vector2(-70, 0)
		player.velocity = Vector2.ZERO
		level._wieslaw.facing = 1
		await _physics(2)
		level.attack()
		await _physics(3)
		if hit == 0:
			hit_once = level.vikings.size() == count and level.vikings[0]["health"] == PlatformerGame.VIKING_HEALTH - level.sword_damage
		await _physics(30)
	_check(hit_once and level.vikings.size() == count - 1, "platformer: sword hits knock a Viking out")
	await _physics(60)
	# Walk into a Viking.
	viking = level.vikings[0]["node"]
	player.position = viking.position + Vector2(-10, 0)
	player.velocity = Vector2.ZERO
	await _physics(3)
	_check(level.lives == PlatformerGame.LIVES - 1, "platformer: touching a Viking costs a heart")
	# Fall into the first pit, away from the Vikings.
	await _physics(100)
	level.lives = PlatformerGame.LIVES
	player.position = Vector2(29.5 * PlatformerGame.TILE, 600.0)
	player.velocity = Vector2.ZERO
	await _physics(60)
	_check(level.lives == PlatformerGame.LIVES - 1 and player.position.y <= 640.0, "platformer: falling into a pit costs a heart and goes back (%d, %d)" % [level.lives, player.position.y])
	level.input_x = 1.0
	var before := player.position.x
	await _physics(10)
	level.input_x = 0.0
	_check(player.position.x > before and level._wieslaw.pose == "run", "platformer: Wiesław runs")
	player.position = Vector2((level.LEVEL[9].find("D") + 0.5) * PlatformerGame.TILE, 640.0)
	await _physics(3)
	_check(level.state == "won", "platformer: reaching the drakkar wins")
	# The Apple Knight style map: same width in every row, a start and a drakkar, crates break.
	level.layout = "knight"
	level.restart()
	await _physics(5)
	var widths := {}
	for row in PlatformerGame.LEVEL_KNIGHT:
		widths[row.length()] = true
	var crate_row := -1
	for row in PlatformerGame.LEVEL_KNIGHT.size():
		if PlatformerGame.LEVEL_KNIGHT[row].contains("B"):
			crate_row = row
			break
	var crate := Vector2((PlatformerGame.LEVEL_KNIGHT[crate_row].find("B") + 0.5) * PlatformerGame.TILE, (crate_row + 0.5) * PlatformerGame.TILE)
	var before_apples := level.apples
	level._break_crate(crate)
	_check(widths.size() == 1 and level.player.is_on_floor() and level.tile_at(crate) == " " and level.apples == before_apples + PlatformerGame.CRATE_APPLES, "platformer: the knight map loads and its crates break into apples")
	# The sword leaves a treasure chest shut; F opens it, and it stays open and gives apples and a lost heart back.
	var chest_row := 9
	var chest := Vector2((PlatformerGame.LEVEL_KNIGHT[chest_row].find("T") + 0.5) * PlatformerGame.TILE, (chest_row + 0.5) * PlatformerGame.TILE)
	level.player.position = Vector2(chest.x - 58.0, 640.0)
	level.lives = PlatformerGame.LIVES - 1
	before_apples = level.apples
	await _physics(2)
	level.attack()
	await _physics(10)
	var shut := level.tile_at(chest) == "T"
	level.player.position = Vector2(chest.x - 40.0, 640.0)
	await _physics(2)
	level.use()
	_check(shut and level.tile_at(chest) == "t" and level.apples == before_apples + PlatformerGame.CHEST_APPLES and level.lives == PlatformerGame.LIVES, "platformer: F, not the sword, opens a treasure chest for apples and a heart")
	# The royal chest is two tiles wide; F at its right half opens it and fills every heart.
	var royal_row := 3
	var royal := Vector2((PlatformerGame.LEVEL_KNIGHT[royal_row].find("S") + 1.5) * PlatformerGame.TILE, (royal_row + 0.5) * PlatformerGame.TILE)
	level.lives = 1
	before_apples = level.apples
	level.player.position = Vector2(royal.x, (royal_row + 1) * PlatformerGame.TILE)
	level.use()
	_check(level.tile_at(royal - Vector2(PlatformerGame.TILE, 0)) == "s" and level.apples == before_apples + PlatformerGame.ROYAL_APPLES and level.lives == PlatformerGame.LIVES, "platformer: the royal chest opens from either half for many apples and all hearts")
	level.queue_free()
	await _brothers_shop()
	await _eye_boss()
	# Every campaign level is a rectangle with a start and a drakkar at the end, and loads.
	for spec in PlatformerCampaign.levels():
		var rows: Array = spec["map"]
		var same_width := rows.all(func(row: String) -> bool: return row.length() == rows[0].length())
		var joined := "".join(rows)
		var stage := PlatformerGame.new()
		stage.level_map = rows
		stage.night = spec["night"]
		stage.auto_input = true
		add_child(stage)
		await _physics(5)
		_check(same_width and joined.count("P") == 1 and (joined.contains("D") or joined.contains("O")) and stage.player.is_on_floor(), "platformer: campaign level %s loads" % spec["name"])
		if spec["name"] == "Sad nocą":
			await _climb_to_chest(stage)
		stage.queue_free()


## A brother sells a heart and a mug of nalewka for apples; with the mug a Viking does no harm.
func _brothers_shop() -> void:
	var rows: Array[String] = []
	for i in 9:
		rows.append(" ".repeat(20))
	rows.append(" P  M    V       D  ")
	rows.append("#".repeat(20))
	rows.append("#".repeat(20))
	var stage := PlatformerGame.new()
	stage.level_map = rows
	stage.auto_input = true
	add_child(stage)
	await _physics(5)
	stage.player.position = stage.merchants[0]["node"].position - Vector2(50, 0)
	stage.apples = 70
	stage.lives = PlatformerGame.LIVES - 1
	stage.use()
	var open := not stage.shop.is_empty()
	stage.buy("heart")
	stage.buy("mug")
	var bought := stage.lives == PlatformerGame.LIVES and stage.apples == 70 - PlatformerGame.HEART_PRICE - PlatformerGame.MUG_PRICE
	bought = bought and stage.mugs == 1 and stage._shield == 0.0
	stage.drink()
	bought = bought and stage.mugs == 0 and stage._shield > 0.0
	stage.player.position = stage.vikings[0]["node"].position
	await _physics(3)
	_check(open and bought and stage.lives == PlatformerGame.LIVES and stage.shop.is_empty(), "platformer: a brother sells a heart and a mug for the bag, and with the mug drunk a Viking does no harm")
	stage.queue_free()


## Only the blind Viking can be hit; going for him (out of the other's reach) makes the other
## toss him the eye, and he lunges once he has it. The one who sees only blocks. Beaten, a Viking
## drops the eye, the last one picks it up and can be hit like any Viking, and when he falls too
## Wiesław wins by picking the eye up.
func _eye_boss() -> void:
	var rows: Array[String] = []
	for i in 9:
		rows.append(" ".repeat(30))
	rows.append(" P            O               ")
	rows.append("#".repeat(30))
	rows.append("#".repeat(30))
	var stage := PlatformerGame.new()
	stage.level_map = rows
	stage.auto_input = true
	add_child(stage)
	await _physics(5)
	var boss: EyeBoss = stage._boss
	stage._shield = 99.0
	var seeing: int = boss.holder
	var blind: int = 1 - seeing
	boss.strike(boss.rect_of(seeing), 1.0, stage.sword_damage)
	var blocked: bool = boss.vikings[seeing]["health"] == EyeBoss.HEALTH
	boss.vikings[seeing]["stun"] = 0.0
	# Out of the holder's reach, next to the blind one.
	boss.vikings[seeing]["node"].position.x = boss.vikings[blind]["node"].position.x + 5.0 * PlatformerGame.TILE
	stage.player.position = boss.vikings[blind]["node"].position - Vector2(100, 0)
	boss._cooldown = 0.0
	await _physics(2)
	var tossed: bool = boss.holder == -1
	await _physics(120)
	var lunged: bool = boss.holder == blind
	blind = 1 - boss.holder
	while boss.vikings[blind]["health"] > 0:
		boss.vikings[blind]["stun"] = 0.0
		boss.strike(boss.rect_of(blind), 1.0, stage.sword_damage)
	var last: int = 1 - blind
	var dropped: bool = boss.holder == -1 and boss.alone()
	stage.player.position = Vector2(2.0 * PlatformerGame.TILE, stage.player.position.y)
	await _physics(240)
	var picked: bool = boss.holder == last
	while boss.vikings[last]["health"] > 0:
		boss.vikings[last]["stun"] = 0.0
		boss.strike(boss.rect_of(last), 1.0, stage.sword_damage)
	stage.player.position = boss.eye + Vector2(0, 40)
	await _physics(3)
	_check(blocked and tossed and lunged and dropped and picked and boss.won and stage.state == "won", "platformer: only the blind Viking takes hits, the eye goes to him, the last one picks it up and fights, and Wiesław takes it (%s %s %s %s %s)" % [blocked, tossed, lunged, dropped, picked])
	stage.queue_free()


## In the orchard a ladder goes down through the ground into the cellar, where F opens a chest,
## and another ladder leads back up: S climbs down from the top, W climbs up and hops off.
func _climb_to_chest(stage: PlatformerGame) -> void:
	var rows: Array = stage.level_map
	var tile := float(PlatformerGame.TILE)
	var surface := -1
	for row in rows.size():
		if rows[row].contains("P"):
			surface = row
	var down: int = rows[surface + 1].find("H")
	var up: int = rows[surface + 1].find("H", down + 1)
	var floor_row := surface + 1
	while rows[floor_row + 1][down] != "#":
		floor_row += 1
	stage.player.position = Vector2((down + 0.5) * tile, (surface + 1) * tile)
	await _physics(2)
	stage.input_climb = 1.0
	await _physics(150)
	stage.input_climb = 0.0
	await _physics(20)
	var in_cellar: bool = stage.player.position.y > (floor_row + 0.5) * tile and stage.player.is_on_floor()
	var chest_col: int = rows[floor_row].find("T")
	stage.player.position = Vector2((chest_col - 0.5) * tile, (floor_row + 1) * tile)
	await _physics(5)
	stage.use()
	var opened := stage.tile_at(Vector2((chest_col + 0.5) * tile, (floor_row + 0.5) * tile)) == "t"
	stage.player.position = Vector2((up + 0.5) * tile, (floor_row + 1) * tile)
	await _physics(2)
	stage.input_climb = -1.0
	stage.input_jump = true
	await _physics(150)
	stage.input_climb = 0.0
	stage.input_jump = false
	await _physics(40)
	var top := stage.player.position.y
	_check(in_cellar and opened and not stage._climbing and stage.player.is_on_floor() and top <= (surface + 1) * tile + 1, "platformer: S climbs down into the cellar, F opens its chest, W climbs back up (%d)" % top)


func _physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


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
