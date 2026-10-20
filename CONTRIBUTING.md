# Contributing

## Code conventions

- Godot 4.4, GDScript only. Use static typing (`var x := ...`, typed parameters and return types).
- Follow the [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): tabs, `snake_case` for functions and variables, `PascalCase` for `class_name`, two blank lines between functions, `_` prefix for private members.
- Each room lives in `rooms/` and extends `Room`. Its objects, dialogue and puzzles stay in that room's `interact`, not in shared scripts.
- Items are defined once in `Game.ITEMS`. Story progress goes through `Game.set_flag` / `Game.flag`, not through variables scattered across nodes.
- Placeholder drawing stays in `scripts/placeholder_art.gd` (and the room's background `_draw`), so it can be swapped for real art without touching game logic.
- In-game text (dialogue, item names, UI) is Polish and keeps the comic's tone; code, comments, commits and docs are English.
- Share behaviour once it has more than one real caller. Do not build a general framework for a single use case.
- Follow the surrounding formatting and naming.
- Add a comment only when the code cannot explain the reason on its own. Do not add comments that restate what the code does.

## Branches and commits

- One branch per feature or fix, named `feat/…`, `fix/…`, `refactor/…` or `chore/…`. Unrelated changes go to separate branches, even when they come up during the same work.
- Use short [Conventional Commits](https://www.conventionalcommits.org/) subjects with a scope, e.g. `feat(orchard): let the guard react to the rake`.
- Keep each commit focused and runnable.
- A branch that builds on another unmerged branch starts from it; merge them in that order.
- Merge into `main` through a pull request with a merge commit (no squash).

## Verification

Before merging, run the walkthrough test and play the changed part of the game:

```bash
godot --headless --path . --import
godot --headless --path . res://tests/walkthrough.tscn
```

The test must print `RESULT: OK`. When a change adds or alters a puzzle, update `tests/walkthrough.gd` so it still plays the demo from start to finish.
