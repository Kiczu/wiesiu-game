extends Room
## The prince's orchard, after Book I of the comic. Puzzle chain:
## cup + barrel -> mead, mead -> Czesław falls asleep, bushes -> night and the Vikings arrive,
## apple thrown at the Vikings -> magic eye, eye -> the Vikings give up the apples and the drakkar.

const NIGHT_TINT := Color(0.55, 0.6, 0.95)

var ksiaze: Character
var leslaw: Character
var czeslaw: Character
var wiking_a: Character
var wiking_b: Character
var drakkar: Hotspot
var pieniek: Hotspot


func _ready() -> void:
	walk_area = Rect2(60, 490, 1160, 140)

	add_hotspot("jablon", "Jabłoń", Vector2(900, 500), Vector2(280, 400), Vector2(790, 540), "tree")
	add_hotspot("beczka", "Beczułka nalewki", Vector2(230, 490), Vector2(70, 90), Vector2(270, 520), "barrel")
	pieniek = add_hotspot("pieniek", "Pieniek", Vector2(470, 505), Vector2(60, 60), Vector2(420, 530), "stump")
	add_hotspot("krzaki", "Krzaki", Vector2(1160, 520), Vector2(220, 110), Vector2(1070, 560), "bushes")
	add_hotspot("wyjscie", "Do grodu", Vector2(30, 640), Vector2(60, 220), Vector2(70, 560))

	drakkar = add_hotspot("wikingowie", "Wikingowie w latającym drakkarze", Vector2(560, 300), Vector2(320, 230), Vector2(560, 520), "drakkar")
	wiking_a = add_character("Wiking", Vector2(440, 280), Color("4f7a3a"), Color("c8f7a0"))
	wiking_a.braids = true
	wiking_b = add_character("Wiking", Vector2(680, 280), Color("d9692b"), Color("ffc59e"))
	wiking_b.braids = true
	wiking_b.facing = -1

	leslaw = add_character("Lesław", Vector2(330, 560), Color("6f8f2f"), Color("d8f5a2"))
	leslaw.helmet = true
	leslaw.feather = true
	add_hotspot("leslaw", "Lesław Roztropny", leslaw.position + Vector2(0, 2), Vector2(80, 150), leslaw.position + Vector2(-100, 10))

	czeslaw = add_character("Czesław", Vector2(1000, 580), Color("9aa3ab"), Color("e0e6ff"))
	czeslaw.helmet = true
	czeslaw.mustache = true
	czeslaw.chainmail = true
	czeslaw.facing = -1
	add_hotspot("czeslaw", "Czesław Waleczny", czeslaw.position + Vector2(-40, 2), Vector2(170, 150), czeslaw.position + Vector2(-190, -10))

	ksiaze = add_character("Książę Jarosław", Vector2(170, 590), Color("b03a2e"), Color("ffd27f"))
	ksiaze.crown = true
	ksiaze.beard = true

	player = add_character("Wiesław", Vector2(560, 590), Color("7b5ea7"), Color.WHITE)
	player.helmet = true
	player.facing = -1

	_set_night(false)


func intro() -> void:
	await say_as(ksiaze, "Synkowie! Ktoś nocami wykrada jabłka z mojego sadu!")
	await say_as(leslaw, "Myślałem nad tym, ojcze. Długo. Bardzo długo.")
	await say_as(czeslaw, "A ja pilnowałem! Liczyłem jabłka, żeby nie zasnąć.")
	await say_as(ksiaze, "I obaj zasnęliście! Wiesławie, teraz twoja kolej. Złap rabusiów.")
	await say("Spokojnie, ojcze. Mam plan.")
	await ksiaze.walk_to(Vector2(-60, 590))
	ksiaze.hide()
	await say("...Jeszcze nie mam, ale zaraz będę miał.")
	await say_as(czeslaw, "Ja zostaję na warcie! Jeden... dwa... trzy...")


func interact(id: String, verb: String, item: String) -> bool:
	match id:
		"jablon":
			if verb == "look":
				await say("Ojcowska jabłoń. Jabłek jakby mniej niż wczoraj.")
			elif verb == "use":
				if Game.has_item("jablko"):
					await say("Jedno w kieszeni wystarczy. Na razie.")
				else:
					await say("Kilka jabłek mniej nikomu nie zrobi różnicy. Najwyżej zwali się na rabusiów.")
					Game.add_item("jablko")
			else:
				return false

		"pieniek":
			if verb == "look":
				if Game.flag("kubek_wziety"):
					await say("Zwykły pieniek.")
				else:
					await say("Pieniek. Ktoś zostawił na nim kubek. Pewnie Lesław, w przerwie od myślenia.")
			elif verb == "use":
				if Game.flag("kubek_wziety"):
					await say("Nic tu już nie ma.")
				else:
					Game.set_flag("kubek_wziety")
					pieniek.queue_redraw()
					Game.add_item("kubek")
					await say("Kubek się przyda. Kubek zawsze się przyda.")
			else:
				return false

		"beczka":
			if verb == "look":
				await say("Beczułka ojcowskiej nalewki. Według tajnej receptury, z piwnic kasztelu.")
			elif verb == "use":
				await say("Prosto z beczki? Nie jestem wikingiem. Potrzebuję naczynia.")
			elif item == "kubek":
				Game.remove_item("kubek")
				Game.add_item("nalewka")
				await say("Pełen kubek. Pachnie jak dobry pomysł.")
			else:
				return false

		"czeslaw":
			if Game.flag("czeslaw_spi"):
				if verb == "look":
					await say("Czesław Waleczny. Walczy ze snem i przegrywa.")
				else:
					await say("Niech śpi. Śpiący brat to cichy brat.")
			elif verb == "look":
				await say("Mój brat Czesław, zwany Walecznym. Liczy jabłka na głos, żeby nie zasnąć.")
			elif verb == "use":
				await say_as(czeslaw, "Nie przeszkadzaj, gubię rachubę! Czterdzieści... czterdzieści...")
				await say("Przy takim liczeniu żaden złodziej się tu nie pokaże.")
			elif item == "nalewka":
				await say("Ojciec przysyła ci coś na rozgrzewkę. Długa noc przed tobą.")
				Game.remove_item("nalewka")
				await say_as(czeslaw, "No, skoro ojciec... Pięćdziesiąt jeden... pięćdziesiąt... dwa...")
				czeslaw.asleep = true
				Game.set_flag("czeslaw_spi")
				await say_as(czeslaw, "CHRRR...")
				await say("Cisza. Teraz złodzieje mogą przyjść. Wystarczy się dobrze schować.")
			elif item == "jablko":
				await say("Mam mu dać jabłko? Przecież on je liczy. Jeszcze się pomyli.")
			else:
				return false

		"leslaw":
			if verb == "look":
				await say("Lesław, zwany Roztropnym. Myśli. Od wczoraj.")
			elif verb == "use":
				await _talk_to_leslaw()
			elif item == "nalewka":
				await say_as(leslaw, "Nie piję, kiedy myślę. A myślę zawsze.")
			else:
				return false

		"krzaki":
			if verb == "look":
				await say("Gęste krzaki. Idealne na zasadzkę.")
			elif verb == "use":
				if Game.flag("noc"):
					await say("Wikingowie są tutaj. Nie czas na chowanie się.")
				elif not Game.flag("czeslaw_spi"):
					await say("Przy tym liczeniu nikt nie przyjdzie. Najpierw trzeba uciszyć Czesława.")
				else:
					await _night_falls()
			else:
				return false

		"wikingowie":
			if verb == "look":
				await say("Dwóch wikingów, latający drakkar i jedno oko na spółkę. Ciekawe, kto tu steruje.")
			elif (verb == "use" and Game.has_item("oko")) or item == "oko":
				await _finale()
			elif verb == "use":
				await say("Hej, wy tam! Co robicie w sadzie mojego ojca?")
				await say_as(wiking_a, "Daj mi oko, nic nie widzę! Kto to gada?")
				await say_as(wiking_b, "Nie dam, teraz moja kolej!")
				await say("Kłócą się o to oko. Gdyby ich czymś rozproszyć...")
			elif item == "jablko":
				await _steal_the_eye()
			elif item == "nalewka":
				await say("Szkoda ojcowskiej nalewki na złodziei.")
			else:
				return false

		"wyjscie":
			if verb == "look":
				await say("Droga do grodu.")
			else:
				await say("Bez rabusiów nie mam po co wracać. Ojciec by mnie zjadł. Razem z jabłkami.")

		_:
			return false
	return true


func _talk_to_leslaw() -> void:
	await say("Lesławie...")
	while true:
		var options := ["Masz jakiś pomysł?", "Kto kradnie jabłka?", "Jak złapać złodzieja?", "Nic, myśl dalej."]
		var picked := await ui.choose(options)
		match picked:
			0:
				await say("Masz jakiś pomysł?")
				await say_as(leslaw, "Pracuję nad tym. Pomysły nie lubią pośpiechu.")
			1:
				await say("Kto kradnie jabłka?")
				await say_as(leslaw, "Ktoś, kto lubi jabłka. Tyle wymyśliłem.")
			2:
				await say("Jak złapać złodzieja?")
				await say_as(leslaw, "Złodziej nie przyjdzie, gdy ktoś hałasuje. A Czesław hałasuje.")
				await say_as(leslaw, "Trzeba by go uciszyć. I schować się. Tylko nie mów nikomu, że to mój pomysł.")
			_:
				await say("Nic, myśl dalej.")
				return


func _night_falls() -> void:
	await say("Zasadzka. Czyli leżę w krzakach i czekam. To akurat umiem.")
	_set_night(true)
	await say_as(wiking_a, "Na Odyna! W końcu jesteśmy na miejscu. Szykuj skrzynki!")
	await say_as(wiking_b, "Zrobię to szybciej, jak dasz mi nasze wspólne oko.")
	await say_as(wiking_a, "Oko jest moje do północy. Taka umowa.")
	await say("Wikingowie? W latającej łodzi? I z jednym okiem na dwóch?")


func _steal_the_eye() -> void:
	Game.remove_item("jablko")
	await say("Hej, łapcie! Świeże, prosto z drzewa!")
	await say_as(wiking_a, "Jabłko! Moje!")
	await say_as(wiking_b, "Puszczaj, moje!")
	await say("BRZDĘK!")
	Game.add_item("oko")
	await say("Ups. Ktoś tu zgubił oko. Ja je tylko znalazłem.")
	await say_as(wiking_b, "Nic nie widzę! Gdzie oko?!")


func _finale() -> void:
	await say("Mam was, psubraty! Myśleliście, że ujdzie wam na sucho ta grabież?")
	await say_as(wiking_a, "Zlituj się! Mamy żony i dzieci!")
	await say_as(wiking_b, "Zrobimy, co zechcesz, ale oddaj nam oko!")
	await say("Po pierwsze, oddacie jabłka. Wszystkie, co do sztuki.")
	await say("Po drugie, łódź zostaje u mnie. Jako rekompensata za straty moralne.")
	await say_as(wiking_a, "A jak wrócimy do domu?")
	await say("Pieszo. Ruch na świeżym powietrzu dobrze wam zrobi.")
	Game.remove_item("oko")
	Game.set_flag("jablka_odzyskane")
	wiking_a.hide()
	wiking_b.hide()
	_set_night(false)
	czeslaw.asleep = false
	ksiaze.position = Vector2(-60, 590)
	ksiaze.show()
	await ksiaze.walk_to(Vector2(240, 590))
	await say_as(czeslaw, "To ciekawe.")
	await say_as(leslaw, "Śmieszna sprawa.")
	await say_as(ksiaze, "Czary mary? Synu, nie tylko powstrzymałeś rabusiów, ale odzyskałeś jabłka!")
	await say_as(ksiaze, "Żądaj, czego chcesz!")
	await say("Chciałbym zatrzymać latający statek i ruszyć w świat.")
	await say_as(ksiaze, "A po co?")
	await say("W poszukiwaniu przygód.")
	Game.set_flag("koniec")
	ui.show_end("Koniec Księgi I",
		"Wiesław złapał rabusiów, odzyskał jabłka i zdobył latający drakkar.\nPrzygoda dopiero się zaczyna...")


func _set_night(night: bool) -> void:
	Game.set_flag("noc", night)
	modulate = NIGHT_TINT if night else Color.WHITE
	drakkar.visible = night or Game.flag("jablka_odzyskane")
	wiking_a.visible = night
	wiking_b.visible = night
	queue_redraw()


func _draw() -> void:
	var night: bool = Game.flag("noc")
	draw_rect(Rect2(0, 0, 1280, 720), Color("1d2b5a") if night else Color("f6c48a"))
	if night:
		draw_circle(Vector2(1120, 90), 40, Color("fff6c8"))
		draw_circle(Vector2(1138, 80), 36, Color("1d2b5a"))
	else:
		draw_circle(Vector2(1120, 130), 55, Color("ffe08a"))
	draw_circle(Vector2(250, 640), 380, Color("a8d58c"))
	draw_circle(Vector2(1000, 700), 420, Color("98cc7c"))
	# Distant gród behind the palisade.
	var tower := Color("8fa6c8")
	draw_rect(Rect2(150, 180, 90, 250), tower)
	draw_colored_polygon(PackedVector2Array([Vector2(130, 185), Vector2(195, 120), Vector2(260, 185)]), Color("e0a832"))
	for x in range(0, 420, 18):
		draw_rect(Rect2(x, 330, 16, 110), Color("7a5230"))
	draw_rect(Rect2(0, 440, 1280, 280), Color("7cbf5a"))
	var wood := Color("8b5a2b")
	draw_rect(Rect2(420, 395, 860, 10), wood)
	draw_rect(Rect2(420, 425, 860, 10), wood)
	for x in range(430, 1280, 55):
		draw_rect(Rect2(x, 380, 14, 70), wood)
