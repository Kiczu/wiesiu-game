# Wiesław – the game

A point-and-click adventure based on the comic series „Wiesław – Baśnie słowiańskie” by Maciej Kisiel.

The current build is a playable prototype with **placeholder art** (simple shapes). The point is to check the gameplay before the real art is drawn.

## Running

1. Download **Godot 4.4.1** (standard build, not .NET): https://godotengine.org/download/archive/4.4.1-stable/
2. In Godot, click **Import** and select `project.godot`.
3. Press **F5**.

## Controls

Keyboard:

- **WASD / arrows**: walk; an object is highlighted when Wiesław stands next to it and faces it
- **E / Space / Enter**: use or talk to the highlighted object (with the selected item, if any); skip a line of dialogue
- **Q**: look at the highlighted object
- **I / Tab**: open the backpack
- **1-9**: select an item from the backpack, or pick a dialogue option
- **Esc**: put the selected item back, close the backpack

Mouse (also for tablets):

- **Left click**: walk, use an object, talk
- **Right click**: look at an object, or put back the selected item
- **Backpack (bottom right)**: open the inventory; pick an item, then click an object to use it on
- **Click during dialogue**: skip the line

## Demo: Book I, "O dwóch takich co ukradli jabłka"

The game starts in the throne room: Prince Jarosław's apples are stolen at night and both older brothers have failed, so Wiesław takes over. Solution (spoiler): take the cup from the table in the throne room, go through the door to the orchard, fill it at the mead barrel and give it to Czesław so he falls asleep, pick an apple, hide in the bushes, throw the apple at the Vikings to grab their shared magic eye, then use the eye on them.

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
| `scripts/ui.gd` | Speech, hover label, inventory, dialogue choices, end screen |
| `tests/walkthrough.gd` | Plays the whole demo automatically |
