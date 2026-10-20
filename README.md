# Wiesław – the game

A point-and-click adventure based on the comic series „Wiesław – Baśnie słowiańskie” by Maciej Kisiel.

The current build is a playable prototype with **placeholder art** (simple shapes). The point is to check the gameplay before the real art is drawn.

## Running

1. Download **Godot 4.4.1** (standard build, not .NET): https://godotengine.org/download/archive/4.4.1-stable/
2. In Godot, click **Import** and select `project.godot`.
3. Press **F5**.

## Controls

- **Left click**: walk, use an object, talk
- **Right click**: look at an object, or put back the selected item
- **Click an inventory item, then an object**: use the item on it
- **Click during dialogue**: skip the line

## Demo: who stole the prince's apples?

The prince tells Wiesław to find the thief of the golden apples. Solution (spoiler): take the rake, use it on the apple tree, and show the golden feather to the prince. Optionally, tickle the sleeping guard with the feather.

## Layout

| Path | Contents |
|---|---|
| `rooms/sad.gd` | The orchard: objects, dialogue and puzzle |
| `scripts/game.gd` | Item list and game state (inventory, flags); autoloaded as `Game` |
| `scripts/room.gd` | Base class for rooms |
| `scripts/character.gd` | Characters (placeholder drawing) |
| `scripts/hotspot.gd` | Clickable objects |
| `scripts/placeholder_art.gd` | Placeholder drawings, to be replaced by the author's art |
| `scripts/ui.gd` | Speech, hover label, inventory, dialogue choices, end screen |
| `tests/walkthrough.gd` | Plays the whole demo automatically |
