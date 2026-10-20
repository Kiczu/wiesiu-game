extends Room
## Munina, a village somewhere in Podkarpacie, after the start of Book II. A freeloader called Rokita
## won't pay at the inn. Puzzle chain: pot + tar cauldron -> pot of tar, coop -> sack of feathers,
## tar and feathers shown to Rokita -> he joins the crew, the innkeeper pays with three rams, drakkar -> end.

var karczmarz: Character
var rokita: Character
var chlop_a: Character
var chlop_b: Character
var barany: Hotspot


func _ready() -> void:
	walk_area = Rect2(60, 380, 1160, 310)
	far_scale = 0.62
	near_scale = 1.15

	add_hotspot("drakkar", "Drakkar", Vector2(200, 670), Vector2(300, 200), Vector2(410, 650), "drakkar")
	add_hotspot("karczma", "Karczma", Vector2(860, 360), Vector2(300, 300), Vector2(860, 400))
	add_hotspot("garnek", "Wyszczerbiony garnek", Vector2(470, 470), Vector2(36, 36), Vector2(500, 485), "pot")
	add_hotspot("kurnik", "Kurnik", Vector2(1150, 470), Vector2(130, 120), Vector2(1070, 485), "coop")
	add_hotspot("kociol", "Kocioł smoły", Vector2(580, 580), Vector2(70, 80), Vector2(650, 600), "cauldron")
	barany = add_hotspot("barany", "Trzy barany", Vector2(760, 670), Vector2(200, 70), Vector2(640, 660), "sheep")
	find_hotspot("garnek").visible = not Game.flag("garnek_wziety")
	barany.visible = Game.flag("barany")

	chlop_a = add_character("Chłop", Vector2(290, 440), Color("a07850"))
	chlop_a.beard = true
	chlop_b = add_character("Chłop", Vector2(350, 435), Color("8a9a5b"))
	chlop_b.mustache = true
	chlop_b.facing = -1
	add_hotspot("chlopi", "Chłopi", Vector2(320, 442), Vector2(120, 115), Vector2(420, 455))

	karczmarz = add_character("Karczmarz", Vector2(790, 420), Color("d8d0b8"))
	karczmarz.mustache = true
	karczmarz.facing = -1
	add_hotspot("karczmarz", "Karczmarz", karczmarz.position + Vector2(0, 2), Vector2(60, 115), karczmarz.position + Vector2(-80, 15))

	rokita = add_character("Rokita", Vector2(1000, 570), Color("222222"))
	rokita.skin = Color("c0392b")
	rokita.horns = true
	rokita.facing = -1
	add_hotspot("rokita", "Gość w czarnej szacie", rokita.position + Vector2(0, 2), Vector2(80, 160), rokita.position + Vector2(-110, 10))
	if Game.flag("rokita_w_zalodze"):
		rokita.position = Vector2(330, 620)
		rokita.facing = 1
		find_hotspot("rokita").hide()

	player = add_character("Wiesław", Vector2(430, 650), Color("7b5ea7"))
	player.helmet = true


func intro() -> void:
	if Game.flag("munina_odwiedzona"):
		return
	Game.set_flag("munina_odwiedzona")
	await say_as(chlop_a, "Co to za nowe licho? Tfu!")
	await say_as(chlop_b, "Z nieba spadł. Nic dobrego z nieba nie spada, chyba że deszcz.")
	await say("Dzień dobry! Wiesław, syn księcia Jarosława. Przelotem.")
	await say_as(karczmarz, "Panie! Jaśnie panie z latającej łodzi! Ratujcie mnie, bo zbankrutuję!")


func interact(id: String, verb: String, item: String) -> bool:
	match id:
		"karczmarz":
			if verb == "look":
				await say("Karczmarz. Wygląda, jakby nie spał od tygodnia.")
			elif verb == "use":
				await _talk_to_innkeeper()
			else:
				return false

		"rokita":
			if verb == "look":
				if Game.flag("rokita_w_zalodze"):
					await say("Mój nowy pomocnik. Czerwony, rogaty i z wilczym apetytem.")
				else:
					await say("Czerwona gęba, rogi, czarna szata. I kufel. Raczej nie miejscowy proboszcz.")
			elif verb == "use":
				await _talk_to_rokita()
			elif item == "smola" or item == "pierze":
				await _threaten_rokita()
			else:
				return false

		"garnek":
			if verb == "look":
				await say("Stary garnek. Wyszczerbiony, ale dno ma całe.")
			elif verb == "use":
				Game.set_flag("garnek_wziety")
				find_hotspot("garnek").hide()
				Game.add_item("garnek")
				await say("Nikt nie będzie tęsknił. Garnek zawsze się przyda. Jak kubek.")
			else:
				return false

		"kociol":
			if verb == "look":
				await say("Kocioł z gorącą smołą. Ktoś tu łata dachy. Albo ludzi.")
			elif verb == "use":
				await say("Gołymi rękami? Nie jestem aż tak odważny.")
			elif item == "garnek":
				Game.remove_item("garnek")
				Game.add_item("smola")
				await say("Pełen garnek smoły. Gorąca, lepka i bardzo przekonująca.")
			else:
				return false

		"kurnik":
			if verb == "look":
				if Game.flag("pierze_wziete"):
					await say("Kurnik. Kury patrzą na mnie z wyrzutem.")
				else:
					await say("Kurnik. Obok leży worek pierza. Kury chyba się wyliniały.")
			elif verb == "use":
				if Game.flag("pierze_wziete"):
					await say("Więcej pierza nie trzeba. Kury i tak są już łyse.")
				else:
					Game.set_flag("pierze_wziete")
					find_hotspot("kurnik").queue_redraw()
					Game.add_item("pierze")
					await say("Worek pierza. Miękkie, lekkie i świetnie się klei. Do różnych rzeczy.")
			else:
				return false

		"chlopi":
			if verb == "look":
				await say("Dwóch chłopów. Patrzą na mnie, jakbym był upiorem.")
			elif verb == "use":
				await say("Dobrzy ludzie, co tu się dzieje?")
				await say_as(chlop_a, "Rogaty siedzi w karczmie od tygodnia. Je, pije i nie płaci.")
				await say_as(chlop_b, "U nas na takich jest jeden sposób. Smoła i pierze!")
				await say_as(chlop_a, "Ino nikt nie ma odwagi.")
			else:
				await say_as(chlop_b, "Nie bierzemy nic od obcych. Zwłaszcza z nieba.")

		"karczma":
			if verb == "look":
				await say("Karczma. Pachnie piwem, kapustą i kłopotami.")
			else:
				await say("Najpierw sprawa, potem piwo.")

		"barany":
			if verb == "look":
				await say("Trzy barany. Żywe. Zapłata za moje usługi.")
			else:
				await say_as(karczmarz, "Wszystkie trzy wasze, panie! Proszę je zabrać, zanim zmienię zdanie.")

		"drakkar":
			if verb == "look":
				await say("Mój latający drakkar. Gotowy do drogi.")
			elif verb == "use":
				if Game.flag("barany"):
					await _finale()
				elif Game.flag("rokita_w_zalodze"):
					await say("Najpierw odbiorę zapłatę od karczmarza.")
				else:
					await say("Nie odlecę, zanim nie pomogę karczmarzowi. Nie wypada.")
			else:
				return false

		_:
			return false
	return true


func _talk_to_innkeeper() -> void:
	if Game.flag("barany"):
		await say_as(karczmarz, "Dziękuję, panie! Niech wam się darzy!")
		return
	if Game.flag("rokita_w_zalodze"):
		await say("Gotowe. Wasz gość już nie będzie się tu stołował.")
		await say_as(karczmarz, "Dobrodzieju! Należy się nagroda. Jedzenie na drogę, jak obiecałem!")
		Game.set_flag("barany")
		barany.show()
		await say("...To są trzy żywe barany.")
		await say_as(karczmarz, "Najświeższe w całej Muninie!")
		return
	Game.set_flag("karczmarz_prosil")
	await say("Co was trapi, karczmarzu?")
	await say_as(karczmarz, "Ten tam, rogaty. Siedzi od tygodnia, je za trzech, pije za pięciu i ani grosza nie zapłacił!")
	await say_as(karczmarz, "Kto go przegoni, dostanie jedzenia na drogę, ile udźwignie!")
	await say("Jedzenie na drogę? Brzmi jak umowa.")


func _talk_to_rokita() -> void:
	if Game.flag("rokita_w_zalodze"):
		await say_as(rokita, "Rozkazy, szefie? Trzy, nie więcej. Taka umowa.")
		return
	await say("Przepraszam, szanowny pan płaci za ten posiłek?")
	await say_as(rokita, "Jestem Rokita i w ogóle nie wiem, o czym pan mówi.")
	if Game.flag("karczmarz_prosil"):
		await say("Karczmarz mówi co innego.")
		await say_as(rokita, "Żądam adwokata.")
		await say("Ze słów nic tu nie wskóram. Trzeba czegoś bardziej... przekonującego.")


func _threaten_rokita() -> void:
	if not Game.flag("karczmarz_prosil"):
		await say("Nie znam gościa. Najpierw dowiem się, o co tu chodzi.")
		return
	if not (Game.has_item("smola") and Game.has_item("pierze")):
		await say("Samo to nie wystarczy. Smoła i pierze idą w parze, jak mówią chłopi.")
		return
	await say("Panie Rokita. Mam tu garnek gorącej smoły. I worek pierza.")
	await say_as(rokita, "Eee... to chyba nie dla mnie?")
	await say("Zobaczymy. Wszystko zależy od tego, czy spłacisz dług.")
	await say_as(rokita, "Nie mam pieniędzy! Ale... mogę odpracować. Trzy rozkazy, cokolwiek zechcesz!")
	await say("Trzy rozkazy. Umowa stoi. Pierwszy: wskakuj na pokład.")
	Game.remove_item("smola")
	Game.remove_item("pierze")
	Game.set_flag("rokita_w_zalodze")
	find_hotspot("rokita").hide()
	await rokita.walk_to(Vector2(330, 620))
	await say_as(karczmarz, "Odchodzi! Naprawdę odchodzi!")


func _finale() -> void:
	await say("Rozkaz numer dwa: załaduj barany.")
	barany.hide()
	await say_as(rokita, "Przyznaj, że prosząc o żarcie, nie miałeś na myśli trzech żywych baranów.")
	await say("Nie. Ale jak to mówią, darowanemu baranowi nie zagląda się w zęby.")
	await say_as(rokita, "Tak się nie mówi.")
	await say("Od dziś się mówi. W drogę!")
	Game.set_flag("koniec")
	ui.show_end("Koniec dema",
		"Wiesław przegonił darmozjada z Muniny i zyskał pierwszego pomocnika.\nRokita ma jeszcze dwa rozkazy do wykonania...")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("bfe3f2"))
	draw_circle(Vector2(1100, 120), 50, Color("ffe08a"))
	draw_circle(Vector2(300, 590), 520, Color("8fbf6a"))
	draw_circle(Vector2(1100, 650), 560, Color("86b862"))
	# Thatched huts on the hill.
	for x in [120, 380, 1080]:
		draw_rect(Rect2(x, 220, 130, 110), Color("c9a77a"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 20, 230), Vector2(x + 65, 150), Vector2(x + 150, 230)]), Color("d8b45a"))
		draw_rect(Rect2(x + 50, 270, 30, 60), Color("5a3a1e"))
	# The inn, bigger, with a sign.
	draw_rect(Rect2(710, 130, 300, 230), Color("a57a4c"))
	draw_colored_polygon(PackedVector2Array([Vector2(690, 140), Vector2(860, 50), Vector2(1030, 140)]), Color("d8b45a"))
	draw_rect(Rect2(830, 270, 60, 90), Color("5a3a1e"))
	draw_rect(Rect2(800, 170, 120, 40), Color("e8d8b0"))
	draw_rect(Rect2(800, 170, 120, 40), Color("3b2a1a"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(812, 198), "KARCZMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("3b2a1a"))
	draw_rect(Rect2(0, 340, 1280, 380), Color("9a8a5a"))
	draw_rect(Rect2(0, 340, 1280, 12), Color("7d6f48"))
	for y in [420, 510, 610]:
		draw_line(Vector2(0, y), Vector2(1280, y), Color("8e7f52"), 2.0)
