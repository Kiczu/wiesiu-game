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

## Demo: Book I, "O dwóch takich co ukradli jabłka"

Prince Jarosław's apples are stolen at night and both older brothers have failed, so Wiesław takes over. Solution (spoiler): take the cup from the stump, fill it at the mead barrel and give it to Czesław so he falls asleep, pick an apple, hide in the bushes, throw the apple at the Vikings to grab their shared magic eye, then use the eye on them.

## Layout

| Path | Contents |
|---|---|
| `rooms/sad.gd` | The orchard from Book I: objects, dialogue and puzzles |
| `scripts/game.gd` | Item list and game state (inventory, flags); autoloaded as `Game` |
| `scripts/room.gd` | Base class for rooms |
| `scripts/character.gd` | Characters (placeholder drawing) |
| `scripts/hotspot.gd` | Clickable objects |
| `scripts/placeholder_art.gd` | Placeholder drawings, to be replaced by the author's art |
| `scripts/ui.gd` | Speech, hover label, inventory, dialogue choices, end screen |
| `tests/walkthrough.gd` | Plays the whole demo automatically |
