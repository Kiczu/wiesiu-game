extends Node2D
## The game: the main menu, then the platformer levels of PlatformerCampaign, each after its comic
## pages, the comic ending and the end screen.

var ui: GameUI
var menu: GameMenu


func _ready() -> void:
	Game.load_settings()
	GameMenu.apply_fullscreen()
	ui = GameUI.new()
	add_child(ui)
	ui.restart_requested.connect(_to_main_menu)
	menu = GameMenu.new()
	add_child(menu)
	menu.play_requested.connect(_play)
	menu.resume_requested.connect(menu.close)
	menu.main_menu_requested.connect(_to_main_menu)
	menu.show_main()


func _play() -> void:
	menu.close()
	# Apples, mugs, the torch and the bar go on from level to level, until the drakkar is won back.
	var apples := 0
	var mugs := 0
	var torch := false
	var torch_lit := false
	var bar: Array[String] = ["", "", "", "", ""]
	var levels := PlatformerCampaign.levels()
	var index := 0
	var back := false
	var seen := {}
	while index < levels.size():
		var spec: Dictionary = levels[index]
		var stage := PlatformerGame.new()
		stage.mugs = mugs
		stage.torch = torch
		stage.torch_lit = torch_lit
		stage.bar = bar.duplicate()
		stage.start_apples = apples
		stage.level_map = spec["map"]
		stage.night = spec["night"]
		stage.dungeon = spec["dungeon"]
		stage.level_name = spec["name"]
		stage.scene_lights = spec.get("lights", [])
		stage.scene_darkness = spec.get("darkness", Color(0, 0, 0, 0))
		stage.scene_pictures = spec.get("pictures", [])
		stage.dressing_path = spec.get("dressing", "")
		# Going left out of a level leads back to the one before, in front of its way out.
		stage.can_go_back = index > 0
		stage.start_at_exit = back
		var parts: Array[Node] = [stage]
		# A level added without comic pages starts straight away; the pages show only the first time.
		if not spec["pages"].is_empty() and not seen.has(index):
			parts.push_front(ComicStrip.new(spec["pages"]))
		seen[index] = true
		for part: Node in parts:
			part.pause_requested.connect(menu.show_pause)
			add_child(part)
			await part.finished
			part.queue_free()
		mugs = stage.mugs
		torch = stage.torch
		torch_lit = stage.torch_lit
		bar = stage.bar.duplicate()
		apples = stage.apples
		back = stage.went_back
		index += -1 if back else 1
	var outro := ComicStrip.new(BookOneStory.outro_pages())
	outro.pause_requested.connect(menu.show_pause)
	add_child(outro)
	await outro.finished
	outro.queue_free()
	ui.show_end("Koniec wersji próbnej", "Złapane jabłka: %d. Dalsze przygody czekają w kolejnych księgach!" % apples)


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.is_action("fullscreen"):
		Game.fullscreen = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
		GameMenu.apply_fullscreen()
		Game.save_settings()
