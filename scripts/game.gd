extends Node
## Settings and keyboard actions shared by every scene.

## Keyboard actions, bound at startup so every scene (also a level run on its own) has them.
const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"cancel": [KEY_ESCAPE],
	"fullscreen": [KEY_F11],
}
const SETTINGS_PATH := "user://settings.cfg"

## The browser build starts in the page; F11 or the itch.io button goes fullscreen.
var fullscreen := not OS.has_feature("web")
## Platformer sound: "sounds" (no music), "all" (with music) or "silent"; M goes round them.
var sound := "sounds"
## Test mode: comic pages and the flight end at once.
var fast := false


func _ready() -> void:
	_bind_keys()


func _bind_keys() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		fullscreen = config.get_value("game", "fullscreen", fullscreen)
		sound = config.get_value("game", "sound", sound)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "fullscreen", fullscreen)
	config.set_value("game", "sound", sound)
	config.save(SETTINGS_PATH)
