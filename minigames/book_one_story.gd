class_name BookOneStory
extends RefCounted
## Comic pages for the platformer version, after Book I of the comic.

const WIESLAW := {"display_name": "Wiesław", "body_color": Color("7b5ea7"), "helmet": true}
const KSIAZE := {"body_color": Color("b03a2e"), "crown": true, "beard": true}
const LESLAW := {"body_color": Color("6f8f2f"), "helmet": true, "feather": true, "asleep": true}
const CZESLAW := {"body_color": Color("9aa3ab"), "helmet": true, "mustache": true, "chainmail": true, "asleep": true}
const WIKING_A := {"body_color": Color("4f7a3a"), "braids": true}
const WIKING_B := {"body_color": Color("d9692b"), "braids": true, "facing": -1}
const NIGHT := Color("2d3561")
const NIGHT_GROUND := Color("3b5a3a")


static func _with(spec: Dictionary, extra: Dictionary) -> Dictionary:
	var merged := spec.duplicate()
	merged.merge(extra, true)
	return merged


## Comic pages before the level.
static func intro_pages() -> Array:
	return [
		[
			{"caption": "W grodzie księcia Jarosława działo się coś niedobrego...",
				"chars": [_with(KSIAZE, {"pos": Vector2(190, 500)})],
				"say": {"who": 0, "text": "Znowu ktoś ukradł moje złote jabłka!"}},
			{"caption": "Lesław i Czesław pilnowali sadu. Obaj zasnęli.", "bg": NIGHT, "ground": NIGHT_GROUND,
				"chars": [_with(LESLAW, {"pos": Vector2(200, 430)}), _with(CZESLAW, {"pos": Vector2(330, 520)})]},
			{"chars": [_with(WIESLAW, {"pos": Vector2(190, 500)})],
				"say": {"who": 0, "text": "Spokojnie, tato. Tego złodzieja złapię ja!"}},
		],
		[
			{"caption": "O świcie nad sadem przemknął latający drakkar!",
				"chars": [_with(WIKING_A, {"pos": Vector2(220, 500)}), _with(WIKING_B, {"pos": Vector2(380, 500)})],
				"say": {"who": 0, "text": "Jabłka nasze! Uciekamy!"}},
			{"caption": "Wiesław ruszył w pościg.",
				"chars": [_with(WIESLAW, {"pos": Vector2(290, 500)})],
				"say": {"who": 0, "text": "A wy dokąd?! Stać, złodzieje!"}},
		],
	]


## Comic page after the level.
static func outro_pages() -> Array:
	return [
		[
			{"caption": "Jednym susem Wiesław wskoczył na pokład.",
				"chars": [_with(WIKING_A, {"pos": Vector2(180, 500)}), _with(WIESLAW, {"pos": Vector2(330, 500), "facing": -1})],
				"say": {"who": 0, "text": "Ratunku! Ten chłopak skacze jak kozioł!"}},
			{"caption": "Ciąg dalszy nastąpi...",
				"chars": [_with(WIESLAW, {"pos": Vector2(290, 500)})],
				"say": {"who": 0, "text": "Jabłka wracają do taty. A tę łódkę... chyba sobie pożyczę!"}},
		],
	]
