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

## Platformer version (trial)

**Nowa gra** in the main menu starts the platformer. Wiesław uses a frame set found in `CutoutCharacter.ANIM_DIRS`, **K** switching between them (chibi and full-size frames made from the author's drawing, the side view cut from it, else the chibi; a set drawn bigger than shown sets `smooth` in frames.json, a `drink` pose plays when he drinks a mug, and a `drink_<item>` pose such as `drink_mug`, when drawn, is used instead for that drink; `drinking` names it) (the adventure above is set aside for now and no longer in the menu; its code and tests stay). It is a Mario-style take: a few comic pages, then one level where the player walks (A/D or arrows) and jumps (W or up, hold for a higher jump, press again in the air for a second jump; in the air against a wall he holds on and slides down slowly, and W pushes him off it, up and away, with the second jump back) after the drakkar, swings his sword (space or a click), throws gathered apples (E or a right click), uses things such as chests and the brothers' stalls (F) and climbs ladders (W and S at a ladder, A or D steps off; past the top he hops onto the ledge). Four hits from the sword or apples knock a Viking out (`VIKING_HEALTH`), thorns and Vikings cost one of three hearts, a pit sends Wiesław back to the last flag. Crates break under the sword or a thrown apple and give apples, Wiesław's brothers Lesław and Czesław (`M` on the map) sell a heart for 25 apples and a mug of nalewka for 40 in a stall window with one card per item (1 and 2 buy, F leaves); they stand by the drakkar at the end of the chase, when Wiesław has gathered enough apples to pay; mugs go in the bag and carry on to the next levels, and Q drinks one for two seconds when nothing can hurt him, a treasure chest opens with F for five apples and a lost heart back, and the big royal chest hidden on the knight map gives fifteen apples and every heart. The `O` tile starts the fight for the magic eye (`minigames/eye_boss.gd`): two Vikings share one eye, and only the blind one can be hit. Going for him makes the other toss him the eye; hits land while it flies, and once he catches it he lunges. A beaten Viking drops the eye and the last one runs for it, then fights like any Viking; Wiesław wins the level as soon as he picks up the eye from the ground, whether or not a Viking is still standing; an apple can also knock the flying eye down. Vikings show a health bar once hit; `sword_damage` and `APPLE_DAMAGE` set how much a hit takes. From the main menu the platformer plays the levels of `PlatformerCampaign` (`minigames/platformer_campaign.gd`) in story order, each after its comic pages: first the orchard at night (tall: a road over the tree crowns, and a cellar under the ground reached by a ladder down a shaft or a hole), then the chase after the drakkar (the knight map), then the fight for the eye. Campaign levels are scenes painted in the editor, in `levels/`: open one, pick a tile from the TileMap palette at the bottom (`levels/tiles.tres`, one picture per map letter: ground, plank, crate, apple, thorns, Viking, flag, start, drakkar, chest, royal chest, ladder, brother, eye fight) and paint on the `Map` node; the right button erases. The level's name and night are set on its root node, and **F6** plays the open level. The royal chest is two tiles wide, so leave the cell on its right empty. A level can be as tall as you like and the camera follows up and down; a ladder painted down through the ground makes a shaft whose top can be stood on, and empty cells under the ground get a dark cave wall. A new level is a copy of a level scene added to `SCENES` in `platformer_campaign.gd`; `levels/palette.png` holds the palette pictures (`LevelMap.LETTERS` gives their letters, left to right). Opened on its own, it has two maps: `LEVEL_KNIGHT`, in the style of Apple Knight (ground at many heights, walls for the double jump, spike pits, Vikings on ledges), played by default, and the first, Mario-style `LEVEL`; **N** switches between them. To try only the level, open `minigames/platformer.tscn` and press **F6**.

Wiesław here is a cutout puppet (`scripts/cutout_character.gd`): separate parts turned at their joints, so the author draws each part once. The author's drawn parts go in `art/platformer/wieslaw/`: one PNG per part plus `rig.json` with where each part sits and where its joint is. Ready-made tiles and background layers for the level go in `art/platformer/level_kreskowka/` (a flat cartoon test set) or `art/platformer/level_piksele/` (a pixel-art test set on one 4 x 4 pixel grid; L or "Grafika" in the settings switches between them, and the choice is saved as `level_art`), each with `level.json`, which names the ground-top, ground, deeper ground and plank tiles (a tile wider than 64 px is a strip that runs on across cells) and lists the background layers with how fast each scrolls, where its bottom sits, how far it follows the camera up, whether every other copy is mirrored and how much haze lies over it; `foreground` lists layers drawn in front of the level (blurred bushes passing by faster than the ground), and `haze_color` sets the colour of the air. Without them the level is drawn from plain shapes. Depth effects are always on: foreground, haze, falling leaves and pollen, shadows under characters, sunbeams and a darker edge, the camera looking ahead and shaking on a hit, and dust and squash on jumps and landings. Drawn pictures for things in the level (`apple`, `crate`, `thorns`, `flag`, `flag_on`, `drakkar` as `.png`) go in `art/platformer/items/`; `chest` and `chest_open` there draw the treasure chests (`chest_royal` and `chest_royal_open` the royal one, two tiles wide), `ladder` draws a ladder tile, `heart` and `heart_empty` replace the lives circles, drawn small and shown 3 times bigger. Music (`music.ogg`, looped) and sound effects (`jump`, `apple`, `bump`, `stomp`, `hurt`, `checkpoint`, `win`, `lose` as `.ogg`) go in `art/platformer/audio/`; the level starts with sounds but no music, and **M** goes round silence, sounds with music and sounds alone. Ready-made frame-by-frame animations take over from the puppet when they are in `art/platformer/wieslaw_chibi/` (a small pixel-art Wiesław shown at 3 x 3 screen pixels per drawn pixel, like the Vikings): PNG frames plus `frames.json`, which lists for each pose (idle, run, jump, fall, hurt, win, death, and attack and climb when there are) its speed, whether it loops (climb holds its frame while Wiesław rests on a ladder), its own height when it was drawn at another size, and for each frame the point that stands on the ground. Without any of them the puppet is drawn from placeholder shapes. Vikings drawn as small pixel art go in `art/platformer/viking/` as `<colour>_walk_<n>.png` (green, red and blue, four frames each, drawn facing right with the feet at the bottom middle); each drawn pixel is shown as 3 x 3 screen pixels (`scripts/pixel_viking.gd`).

The level is the text map `LEVEL` at the top of `minigames/platformer.gd`, one character per 64 px tile (the legend is above it). To change the level, edit the map: every row must stay the same length.

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
| `minigames/platformer.gd` | The platformer level and its text map (platformer version) |
| `minigames/book_one_story.gd` | Comic pages before and after the platformer level |
| `scripts/cutout_character.gd` | Cutout puppet: parts, joints and poses (idle, run, jump, fall, hurt, win) |
| `scripts/comic.gd` | Comic pages: panels with characters, speech bubbles and captions |
| `scripts/ui.gd` | Speech, hover label, inventory, dialogue choices, end screen |
| `tests/walkthrough.gd` | Plays the whole demo automatically |
