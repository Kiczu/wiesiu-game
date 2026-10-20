extends Room
## The prince's orchard. Puzzle: take the rake, knock the golden feather off the apple tree
## and show it to the prince. Optional: tickle the sleeping guard with the feather for a hint.

var ksiaze: Character
var straznik: Character
var jablon: Hotspot
var grabie: Hotspot


func _ready() -> void:
	walk_area = Rect2(60, 490, 1160, 140)

	jablon = add_hotspot("jablon", "Jabłoń", Vector2(900, 500), Vector2(280, 400), Vector2(790, 540), "tree")
	grabie = add_hotspot("grabie", "Grabie", Vector2(160, 470), Vector2(44, 150), Vector2(210, 510), "rake")
	add_hotspot("studnia", "Studnia", Vector2(420, 480), Vector2(120, 140), Vector2(420, 530), "well")
	add_hotspot("wyjscie", "Do zamku", Vector2(30, 640), Vector2(60, 220), Vector2(70, 560))

	ksiaze = add_character("Książę", Vector2(600, 530), Color("b03a2e"), Color("ffd27f"))
	ksiaze.crown = true
	ksiaze.facing = -1
	add_hotspot("ksiaze", "Książę", ksiaze.position + Vector2(0, 2), Vector2(80, 150), ksiaze.position + Vector2(-100, 20))

	straznik = add_character("Strażnik", Vector2(1150, 610), Color("4a6b8a"), Color("aee3ff"))
	straznik.helmet = true
	straznik.asleep = true
	add_hotspot("straznik", "Strażnik (śpi)", straznik.position + Vector2(-50, 2), Vector2(180, 70), straznik.position + Vector2(-230, 0))

	player = add_character("Wiesław", Vector2(300, 580), Color("7b5ea7"), Color.WHITE)
	player.helmet = true


func intro() -> void:
	await say_as(ksiaze, "Wiesławie! Ktoś znowu wykradł jabłka z mojego ogrodu!")
	await say("Może same spadły, książę? Jabłka tak mają.")
	await say_as(ksiaze, "Złote jabłka? Same? Z samego czubka jabłoni?")
	await say_as(ksiaze, "Znajdź złodzieja. Inaczej żadnego obiadu przez tydzień!")
	await say("...Już szukam.")


func interact(id: String, verb: String, item: String) -> bool:
	match id:
		"jablon":
			if verb == "look":
				await say("Książęca jabłoń. Złotych jabłek zostało tyle, co kot napłakał.")
				if not Game.flag("pioro_zdobyte"):
					await say("Coś błyszczy wysoko w gałęziach...")
			elif verb == "use":
				if Game.flag("pioro_zdobyte"):
					await say("Nic już tam nie błyszczy. Oprócz mojego geniuszu.")
				else:
					await say("Za wysoko. Wspinaczka to wysiłek, a wysiłek to... no, wysiłek.")
			elif item == "grabie":
				if Game.flag("pioro_zdobyte"):
					await say("Więcej nie strącę. Grabie też mają swoje granice.")
				else:
					await say("Hop! ...Hop! ...HOP!")
					Game.set_flag("pioro_zdobyte")
					jablon.queue_redraw()
					Game.add_item("pioro")
					await say("Złote pióro! Albo złodziej nosi bardzo elegancki kapelusz...")
			else:
				return false

		"grabie":
			if verb == "look":
				await say("Grabie. Narzędzie pracy. Brrr.")
			elif verb == "use":
				await say("Wezmę. Nie do pracy, broń Perunie.")
				grabie.hide()
				Game.add_item("grabie")
			else:
				return false

		"studnia":
			if verb == "look":
				await say("Studnia. Gdyby była w niej żywa woda, nie zdziwiłbym się. Ale to chyba zwykła.")
			elif verb == "use":
				await say("Nie chce mi się pić. Ani niczego innego, prawdę mówiąc.")
			elif item == "grabie":
				await say("Grabie do studni? Książę by mi tego nie darował.")
			else:
				return false

		"wyjscie":
			if verb == "look":
				await say("Droga do zamku. Tam jest kuchnia. A w kuchni obiad.")
			else:
				await say("Książę wyraźnie powiedział: bez złodzieja nie ma obiadu.")

		"straznik":
			if verb == "look":
				await say("Strażnik sadu. Pilnuje go z zamkniętymi oczami. Szanuję.")
			elif verb == "use":
				await say_as(straznik, "Chrrr... jeszcze pięć minutek, mamo...")
				await say("Kolega po fachu.")
			elif item == "pioro":
				await _wake_guard()
			elif item == "grabie":
				await say("Lepiej nie. Śpiący strażnik to szczęśliwy strażnik.")
			else:
				return false

		"ksiaze":
			if verb == "look":
				await say("Książę. Bardzo przejęty swoimi jabłkami.")
			elif verb == "use":
				await _talk_to_prince()
			elif item == "pioro":
				await _finale()
			elif item == "grabie":
				await say_as(ksiaze, "Grabisz? Wreszcie jakaś praca!")
				await say("To nie tak, jak wygląda.")
			else:
				return false

		_:
			return false
	return true


func _talk_to_prince() -> void:
	await say("Książę...")
	while true:
		var options := ["Gdzie mam szukać złodzieja?", "A może najpierw obiad?"]
		if Game.has_item("pioro"):
			options.append("Mam dowód! (pokaż złote pióro)")
		options.append("Nic, nic. Już idę.")
		var picked: String = options[await ui.choose(options)]
		match picked:
			"Gdzie mam szukać złodzieja?":
				await say("Gdzie mam szukać złodzieja?")
				await say_as(ksiaze, "Przy jabłoni, rzecz jasna! Ty naprawdę jesteś wojem?")
			"A może najpierw obiad?":
				await say("A może najpierw obiad? Na pełny brzuch lepiej się myśli.")
				await say_as(ksiaze, "Najpierw złodziej!")
			"Mam dowód! (pokaż złote pióro)":
				await _finale()
				return
			_:
				await say("Nic, nic. Już idę.")
				return


func _wake_guard() -> void:
	await say("Kici kici...")
	straznik.asleep = false
	await say_as(straznik, "Hi hi hi! Co?! Nie śpię! Pilnuję!")
	await say("Widziałeś w nocy złodzieja?")
	await say_as(straznik, "W nocy? Widziałem tylko jasność nad jabłonią, jakby słońce wzeszło. Ładny to był sen.")
	straznik.asleep = true
	await say_as(straznik, "Chrrr...")
	Game.set_flag("straznik_przesluchany")


func _finale() -> void:
	await say("Książę, spójrz, co znalazłem na jabłoni!")
	await say_as(ksiaze, "Złote pióro... To Żar-ptak! To on kradnie moje jabłka!")
	await say("No to sprawa rozwiązana. Idę na obiad.")
	await say_as(ksiaze, "Rozwiązana? Teraz musisz go jeszcze złapać!")
	await say("...Wiedziałem, że w tym planie jest jakiś haczyk.")
	Game.set_flag("koniec")
	ui.show_end("Koniec dema",
		"Wiesław odkrył, kto kradnie złote jabłka.\nCzy złapie Żar-ptaka? Okaże się... jak się wyśpi.")


## Placeholder background until the author's art arrives.
func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("9fd3f0"))
	draw_circle(Vector2(1120, 90), 50, Color("fff3b0"))
	draw_circle(Vector2(250, 640), 380, Color("a8d58c"))
	draw_circle(Vector2(1000, 700), 420, Color("98cc7c"))
	var castle := Color("c9b8a6")
	draw_rect(Rect2(140, 230, 220, 200), castle)
	for x in [120, 330]:
		draw_rect(Rect2(x, 170, 50, 260), castle)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 172), Vector2(x + 25, 110), Vector2(x + 58, 172)]), Color("b0413e"))
	draw_rect(Rect2(225, 340, 50, 90), Color("6b4423"))
	draw_rect(Rect2(0, 440, 1280, 280), Color("7cbf5a"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 520), Vector2(300, 540), Vector2(700, 600), Vector2(700, 650), Vector2(0, 650)]), Color("d8c08a"))
	var wood := Color("8b5a2b")
	draw_rect(Rect2(0, 395, 1280, 10), wood)
	draw_rect(Rect2(0, 425, 1280, 10), wood)
	for x in range(10, 1280, 55):
		draw_rect(Rect2(x, 380, 14, 70), wood)
