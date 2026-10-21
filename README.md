# Wiesław – the game

A point-and-click adventure based on the comic series „Wiesław – Baśnie słowiańskie” by Maciej Kisiel.

The current build is a playable prototype with **placeholder art** (simple shapes). The point is to check the gameplay before the real art is drawn.

## Running

1. Download **Godot 4.4.1** (standard build, not .NET): https://godotengine.org/download/archive/4.4.1-stable/
2. In Godot, click **Import** and select `project.godot`.
3. Press **F5**.

## Browser build (itch.io)

1. In Godot: **Project → Export → Web → Export Project**, save as `build/web/index.html` (the Web export templates must be installed: **Editor → Manage Export Templates**).
2. Zip the contents of `build/web` (the files, not the folder).
3. On itch.io create a project with *Kind of project: HTML*, upload the zip, tick *This file will be played in the browser*, set the viewport to 1280 x 720 and enable the fullscreen button.

The Web preset is single-threaded, so itch.io's *SharedArrayBuffer support* option is not needed. In the browser the game starts inside the page; F11 or the itch.io button switches to fullscreen.

## Menu and saving

The game opens on the main menu (continue, new game, load, settings). Esc opens the pause menu, where the game can be saved to one of 3 slots. The game also autosaves on every room change. Saves and settings are stored in Godot's user folder (on Windows `%APPDATA%\Godot\app_userdata\<project name>`).

## Controls

Keyboard:

- **WASD / arrows**: walk; an object is highlighted when Wiesław stands next to it and faces it
- **E / Space / Enter**: use or talk to the highlighted object (with the selected item, if any); skip a line of dialogue
- **Q**: look at the highlighted object
- **I / Tab**: open the backpack
- **1-9**: select an item from the backpack, or pick a dialogue option
- **Esc**: put the selected item back, close the backpack; with nothing selected it opens the pause menu
- **F11**: switch between full screen (the default) and a window

Mouse (also for tablets):

- **Left click**: walk, use an object, talk
- **Right click**: look at an object, or put back the selected item
- **Backpack (bottom right)**: open the inventory; pick an item, then click an object to use it on
- **Click during dialogue**: skip the line

## Demo: Book I, "O dwóch takich co ukradli jabłka"

The game starts in the throne room: Prince Jarosław's apples are stolen at night and both older brothers have failed, so Wiesław takes over. Solution (spoiler): take the cup from the table in the throne room, go through the door to the orchard, fill it at the mead barrel and give it to Czesław so he falls asleep, pick an apple, hide in the bushes, throw the apple at the Vikings to grab their shared magic eye, then use the eye on them.

## Mini-game: the flight to Munina

After the orchard the drakkar flies to Munina as a short mini-game (40 s): steer up and down with W/S, the arrows or by holding the mouse, dodge birds and storm clouds and catch apples. Three hits and the flight starts over. To try it alone, open `minigames/flight.tscn` in Godot and press **F6** (it loops after landing). More mini-games go in `minigames/` and are started with `go_to(room, caption, minigame)`.

## Demo: Book II, Munina

The drakkar takes Wiesław to Munina, a village where a horned guest called Rokita eats and drinks at the inn without paying. Solution (spoiler): talk to the innkeeper, fill the chipped pot at the tar cauldron, take the sack of feathers by the coop, show the tar and feathers to Rokita, collect the reward from the innkeeper and board the drakkar.

## Layout

| Path | Contents |
|---|---|
| `rooms/sala.gd` | The throne room where Book I starts |
| `rooms/sad.gd` | The orchard from Book I: objects, dialogue and puzzles |
| `rooms/munina.gd` | Munina village from the start of Book II |
| `scripts/game.gd` | Item list and game state (inventory, flags); autoloaded as `Game` |
| `scripts/room.gd` | Base class for rooms; `go_to` switches to another room |
| `scripts/character.gd` | Characters (placeholder drawing) |
| `scripts/hotspot.gd` | Clickable objects |
| `scripts/placeholder_art.gd` | Placeholder drawings, to be replaced by the author's art |
| `scripts/menu.gd` | Main menu, pause menu, save/load slots and settings |
| `minigames/flight.gd` | The drakkar flight mini-game between Book I and Munina |
| `scripts/ui.gd` | Speech, hover label, inventory, dialogue choices, end screen |
| `tests/walkthrough.gd` | Plays the whole demo automatically |
