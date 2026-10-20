extends Node

signal inventory_changed

const ITEMS := {
	"kubek": {"name": "Kubek", "color": Color("a0522d")},
	"nalewka": {"name": "Kubek nalewki", "color": Color("8e1b3a")},
	"jablko": {"name": "Jabłko", "color": Color("d62828")},
	"oko": {"name": "Magiczne oko", "color": Color("6fd3ff")},
	"garnek": {"name": "Wyszczerbiony garnek", "color": Color("7a4a2a")},
	"smola": {"name": "Garnek smoły", "color": Color("1b1b1b")},
	"pierze": {"name": "Worek pierza", "color": Color("f4f4f4")},
}

var inventory: Array[String] = []
var flags := {}

## Save slot 0 is the autosave made on every room change; 1-3 are the player's.
const SAVE_SLOTS := 3
const SETTINGS_PATH := "user://settings.cfg"

var save_prefix := "user://save_"
## Settings: speech bubbles stay on screen 1 / text_speed as long.
var text_speed := 1.0
var fullscreen := true
## Slot to load after the scene reloads (loading from the pause menu).
var pending_load := -1

## Test mode: speech ends instantly and characters teleport instead of walking.
var fast := false
## Test mode: dialogue choices to pick, in order.
var test_choices: Array[int] = []


func add_item(id: String) -> void:
	if id not in inventory:
		inventory.append(id)
		inventory_changed.emit()


func remove_item(id: String) -> void:
	inventory.erase(id)
	inventory_changed.emit()


func has_item(id: String) -> bool:
	return id in inventory


func item_name(id: String) -> String:
	return ITEMS[id]["name"]


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func flag(key: String) -> Variant:
	return flags.get(key, false)


func save_game(slot: int, room_id: String) -> void:
	var data := {
		"room": room_id,
		"inventory": inventory,
		"flags": flags,
		"time": Time.get_datetime_string_from_system(false, true),
	}
	var file := FileAccess.open(save_prefix + str(slot) + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


## The save's contents, or an empty dictionary when the slot is empty or broken.
func read_save(slot: int) -> Dictionary:
	var path := save_prefix + str(slot) + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary and data.has("room") else {}


## Restores the inventory and flags; returns the room to enter, or "" if the slot is empty.
func load_game(slot: int) -> String:
	var data := read_save(slot)
	if data.is_empty():
		return ""
	inventory.assign(data["inventory"])
	flags = data["flags"]
	inventory_changed.emit()
	return data["room"]


## The slot with the newest save, or -1 when there are none.
func latest_save() -> int:
	var best := -1
	var best_time := ""
	for slot in SAVE_SLOTS + 1:
		var data := read_save(slot)
		if not data.is_empty() and data["time"] > best_time:
			best = slot
			best_time = data["time"]
	return best


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		text_speed = config.get_value("game", "text_speed", text_speed)
		fullscreen = config.get_value("game", "fullscreen", fullscreen)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "text_speed", text_speed)
	config.set_value("game", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)


func reset() -> void:
	inventory.clear()
	flags.clear()
	inventory_changed.emit()
