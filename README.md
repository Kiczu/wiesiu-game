# Wiesław – the game

A side-view platformer for kids based on the comic series „Wiesław – Baśnie słowiańskie” by Maciej Kisiel.

The current build is a trial version of Book I („O dwóch takich co ukradli jabłka”). The art is a stand-in until the final art is drawn.

## Running

1. Download **Godot 4.4.1** (standard build, not .NET): https://godotengine.org/download/archive/4.4.1-stable/
2. In Godot, click **Import** and select `project.godot`.
3. Press **F5**.

The art lives in `art/`, which is kept out of the repository. Without it the game falls back to placeholder shapes.

## Browser build (itch.io)

1. In Godot: **Project → Export → Web → Export Project**, save as `build/web/index.html` (the Web export templates must be installed: **Editor → Manage Export Templates**).
2. Zip the contents of `build/web` (the files, not the folder).
3. On itch.io create a project with *Kind of project: HTML*, upload the zip, tick *This file will be played in the browser*, set the viewport to 1280 x 720 and enable the fullscreen button.

The Web preset is single-threaded, so itch.io's *SharedArrayBuffer support* option is not needed. In the browser the game starts inside the page; F11 or the itch.io button switches to fullscreen.

## Menu and settings

The game opens on the main menu (new game, settings). Esc opens the pause menu. Settings (fullscreen, sound) are stored in Godot's user folder (on Windows `%APPDATA%\Godot\app_userdata\<project name>`).

## Controls

- **A/D or arrows**: walk
- **W or up**: jump, hold for a higher jump, press again in the air for a second jump; against a wall in the air Wiesław slides down slowly and W pushes him off it
- **W/S at a ladder**: climb; A or D steps off
- **Space or left click**: attack
- **E or right click**: use the thing chosen in the bar at the bottom (throw an apple, drink a mug, light the torch)
- **1-5, the mouse wheel or a tap on the bar**: choose a thing; a slot dragged onto another swaps them
- **F**: open chests and doors, talk, pull levers
- **M**: sounds, silence, sounds with music
- **Esc**: pause menu
- **F11**: fullscreen or window
- **F3**: frames per second

## The story so far

**Nowa gra** plays the levels of `PlatformerCampaign` (`minigames/platformer_campaign.gd`) in story order, each after its comic pages (`minigames/book_one_story.gd`):

1. **The castle dungeons** (`levels/01_lochy_zamku.tscn`): halls above the start, two levels of dungeons below, joined by holes and ladders; a torch lies under the start ladder, and the door out opens with F.
2. **The orchard at night** (`levels/02_sad_noca.tscn`): the trees above, cellars and tunnels under the ground reached by ladder shafts, crumbling floors, and Wiesław's brothers Lesław and Czesław selling a heart and a mug of nalewka for apples.
3. **The fight for the magic eye** (`levels/03_oko_wikingow.tscn`): two Vikings share one eye and only the blind one can be hit; a beaten Viking drops the eye, and Wiesław wins by picking it up. The drakkar hangs above with a rope ladder to its deck.

Then come the comic ending and the end screen. Apples, mugs, the torch and the bar go on from level to level, and going left out of a level leads back to the one before.

Vikings and rats chase Wiesław; Vikings take four hits, rats one. Thorns, rat bites and Viking axe blows cost one of three hearts (running into a Viking is safe, and the sword reaches further than his axe; each weapon's reach is "reach" in `bron/bronie.json`), and a pit sends him back to the last flag. Crates break into apples, a treasure chest gives apples and a lost heart, the big royal chest fifteen apples and every heart. A mug of nalewka keeps him from harm for two seconds.

`minigames/flight.gd` is a drakkar flight mini-game (dodge birds and clouds, catch apples), kept as the way from the eye fight to the next place once there is one. To try it, open `minigames/flight.tscn` and press **F6**.

## Making levels

Levels are scenes painted in the editor, in `levels/`. Open one, pick a tile from the TileMap palette at the bottom (`levels/tiles.tres`, one picture per map letter; the legend is at the top of `minigames/platformer.gd`) and paint on the `Map` node; the right button erases. The level's name, night and dungeon are set on its root node (`scripts/level_map.gd`), and **F6** plays the open level. A new level is a copy of a level scene added to `SCENES` in `platformer_campaign.gd`; `levels/palette.png` holds the palette pictures.

Pictures can be laid by hand in Node2D groups directly under the level root: `Tył` (behind the ground), `Ziemia` (over it), `Przód` and `Pierwszy plan` (in front). Each moves with its own depth; a `glebia` meta on a picture or group overrides it, and hidden pictures are left out. Lights from `levels/swiatla/` can be placed in the scene too. A level `<name>.tscn` can be dressed by a 3D scene `<name>_3d.tscn` beside it (`scripts/level_dressing.gd`).

Opened on its own (`minigames/platformer.tscn` and **F6**), the platformer plays the campaign's first level.

## Art folders

| Folder in `art/platformer/` | Contents |
|---|---|
| `wieslaw_klatki_chibi/` | Wiesław's frames and `frames.json` (poses, speed, feet, hand points) |
| `zamek/` | Castle tiles, pieces, decorations (`ozdoby/`) and backdrops (`tlo/`) |
| `sad/` | Orchard art set (`level.json`), grass, trees, props and cellar pieces |
| `boss/` | The brothers, the eye and the drakkar |
| `viking/wiking/`, `szczur/` | Viking and rat frames |
| `ui/wyszywanka/` | The embroidered linen of the menus, the item bar, the shop and the level name (nine-patches, edges in `scripts/ui_skin.gd`) |
| `items/`, `ui/`, `bron/`, `audio/` | Item pictures, key caps, weapons, music and sounds |

## Layout

| Path | Contents |
|---|---|
| `scripts/main.gd` | Main menu, then the campaign levels and the end screen |
| `scripts/game.gd` | Settings and keyboard actions; autoloaded as `Game` |
| `scripts/menu.gd` | Main menu, pause menu and settings |
| `scripts/ui.gd` | End screen |
| `scripts/ui_skin.gd` | The embroidered look of menus, the item bar, the shop and the level name |
| `scripts/comic.gd` | Comic pages: panels with characters, speech bubbles and captions |
| `scripts/level_map.gd` | A level painted in the editor, read back as text rows |
| `scripts/level_dressing.gd` | The 3D dressing of a level |
| `scripts/cutout_character.gd` | Wiesław from frames (or a placeholder puppet) |
| `scripts/pixel_viking.gd`, `scripts/rat.gd` | Viking and rat drawing |
| `scripts/character.gd`, `scripts/hotspot.gd`, `scripts/placeholder_art.gd` | Placeholder shapes for characters and the drakkar |
| `minigames/platformer.gd` | The platformer: map legend, movement, enemies, items, drawing |
| `minigames/platformer_campaign.gd` | Level order |
| `minigames/eye_boss.gd`, `minigames/flying_ship.gd`, `minigames/crumbling_floor.gd` | The eye fight, the drakkar over it, floors that break |
| `minigames/book_one_story.gd` | Comic pages before and after the levels |
| `minigames/flight.gd` | The drakkar flight mini-game |
| `tests/walkthrough.gd` | Automatic checks of the menu, the flight and the platformer |
