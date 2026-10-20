extends Room
## The throne room of the gród, where Book I starts. The prince sends his sons after the apple thieves;
## the cup on the table is needed in the orchard.

var ksiaze: Character
var leslaw: Character
var czeslaw: Character


func _ready() -> void:
	walk_area = Rect2(80, 500, 1060, 130)

	add_hotspot("okno", "Okno", Vector2(200, 330), Vector2(120, 150), Vector2(220, 540))
	add_hotspot("sztandar", "Sztandar", Vector2(640, 330), Vector2(160, 260), Vector2(560, 540))
	add_hotspot("tron", "Tron", Vector2(640, 490), Vector2(130, 200), Vector2(560, 540), "throne")
	add_hotspot("stol", "Stół", Vector2(330, 520), Vector2(130, 90), Vector2(400, 550), "table")
	add_hotspot("drzwi", "Drzwi do sadu", Vector2(1200, 560), Vector2(110, 230), Vector2(1110, 570), "door")

	ksiaze = add_character("Książę Jarosław", Vector2(740, 540), Color("b03a2e"))
	ksiaze.crown = true
	ksiaze.beard = true
	ksiaze.facing = -1
	add_hotspot("ksiaze", "Książę Jarosław", ksiaze.position + Vector2(0, 2), Vector2(80, 160), ksiaze.position + Vector2(-110, 30))

	leslaw = add_character("Lesław", Vector2(850, 590), Color("6f8f2f"))
	leslaw.helmet = true
	leslaw.feather = true
	leslaw.facing = -1
	czeslaw = add_character("Czesław", Vector2(960, 600), Color("9aa3ab"))
	czeslaw.helmet = true
	czeslaw.mustache = true
	czeslaw.chainmail = true
	czeslaw.facing = -1
	if Game.flag("sala_odwiedzona"):
		leslaw.hide()
		czeslaw.hide()

	player = add_character("Wiesław", Vector2(560, 600), Color("7b5ea7"))
	player.helmet = true
	if entered_from == "sad":
		player.position = Vector2(1110, 580)
		player.facing = -1


func intro() -> void:
	if Game.flag("sala_odwiedzona"):
		return
	Game.set_flag("sala_odwiedzona")
	await say_as(ksiaze, "Synkowie! Stała się rzecz straszna. Ktoś nocami wykrada jabłka z mojego sadu!")
	await say_as(leslaw, "Zastawmy pułapkę, ojcze. Wszystko dokładnie przemyślę.")
	await say_as(czeslaw, "Złapać, obwiesić i ciach!")
	await say_as(ksiaze, "To samo mówiliście wczoraj. I obaj zasnęliście na warcie!")
	await say_as(ksiaze, "Wiesławie, teraz twoja kolej. Kto rozwiąże zagadkę, może liczyć na moją przychylność... a nawet nagrodę.")
	await say("Spokojnie, ojcze. Mam plan.")
	await say_as(czeslaw, "Ja i tak idę pilnować!")
	await say_as(leslaw, "A ja idę myśleć.")
	leslaw.walk_to(Vector2(1260, 590))
	await czeslaw.walk_to(Vector2(1260, 600))
	leslaw.hide()
	czeslaw.hide()
	await say("...Jeszcze nie mam, ale zaraz będę miał.")


func interact(id: String, verb: String, item: String) -> bool:
	match id:
		"ksiaze":
			if verb == "look":
				await say("Ojciec. Książę Jarosław, miłujący prawo, sprawiedliwość i jabłka.")
			elif verb == "use":
				await _talk_to_prince()
			elif item == "kubek":
				await say_as(ksiaze, "Nie teraz, synu. Najpierw złodzieje, potem toasty.")
			else:
				return false

		"stol":
			if verb == "look":
				if Game.flag("kubek_wziety"):
					await say("Pusty stół. Jak po uczcie.")
				else:
					await say("Stół. Stoi na nim kubek. Bezpański, jak sądzę.")
			elif verb == "use":
				if Game.flag("kubek_wziety"):
					await say("Nic tu już nie ma.")
				else:
					Game.set_flag("kubek_wziety")
					find_hotspot("stol").queue_redraw()
					Game.add_item("kubek")
					await say("Kubek się przyda. Kubek zawsze się przyda.")
			else:
				return false

		"tron":
			if verb == "look":
				await say("Ojcowski tron. Nie wolno na nim siadać. Sprawdzałem.")
			else:
				await say("Ojciec patrzy.")

		"sztandar":
			if verb == "look":
				await say("Rodowy sztandar. Skrzyżowane miecze na czerwonym. Groźnie, ale gustownie.")
			else:
				return false

		"okno":
			if verb == "look":
				await say("Za oknem gród, palisada, a dalej puszcza. Gdzieś tam jest przygoda. I obiad.")
			else:
				await say("Ładny widok, ale nie po to tu jestem.")

		"drzwi":
			if verb == "look":
				await say("Drzwi do sadu.")
			else:
				go_to("sad")

		_:
			return false
	return true


func _talk_to_prince() -> void:
	await say("Ojcze...")
	while true:
		var options := ["Jaka nagroda?", "Skąd się wzięła beczułka w sadzie?", "Masz jakąś radę?", "Już idę."]
		var picked := await ui.choose(options)
		match picked:
			0:
				await say("Jaka nagroda?")
				await say_as(ksiaze, "Najpierw złodzieje, potem nagroda. Taka jest kolejność w porządnym księstwie.")
			1:
				await say("Skąd się wzięła beczułka w sadzie?")
				await say_as(ksiaze, "To moja nalewka! Trzymam ją pod jabłonią, żeby była pod ręką.")
				await say_as(ksiaze, "Według tajnej receptury. Jeden kubek i nawet Czesław śpi jak dziecko.")
			2:
				await say("Masz jakąś radę?")
				await say_as(ksiaze, "Złodziej przychodzi nocą, kiedy jest cicho. Tyle wiem.")
			_:
				await say("Już idę.")
				return


func _draw() -> void:
	# Log walls, a plank floor, a red banner with crossed swords and a window.
	draw_rect(Rect2(0, 0, 1280, 720), Color("8a6239"))
	for y in range(0, 470, 36):
		draw_line(Vector2(0, y), Vector2(1280, y), Color("5e4024"), 4.0)
	draw_rect(Rect2(0, 470, 1280, 250), Color("a37b4c"))
	for x in range(-200, 1280, 120):
		draw_line(Vector2(x, 720), Vector2(x + 200, 470), Color("7d5a35"), 2.0)
	draw_rect(Rect2(140, 180, 120, 150), Color("9fd3f0"))
	draw_rect(Rect2(140, 180, 120, 150), Color("3b2a1a"), false, 6.0)
	draw_line(Vector2(200, 180), Vector2(200, 330), Color("3b2a1a"), 5.0)
	draw_rect(Rect2(560, 70, 160, 260), Color("b0202a"))
	draw_line(Vector2(590, 110), Vector2(690, 230), Color("d8d8d8"), 8.0)
	draw_line(Vector2(690, 110), Vector2(590, 230), Color("d8d8d8"), 8.0)
	draw_rect(Rect2(560, 70, 160, 260), Color("3b2a1a"), false, 3.0)
