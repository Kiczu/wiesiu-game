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


func reset() -> void:
	inventory.clear()
	flags.clear()
	inventory_changed.emit()
