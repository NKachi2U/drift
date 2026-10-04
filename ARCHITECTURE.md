# Drift: architecture proposal

Goal: one complete playthrough (intro, about 10 situations, 2 memory events, an ending) that a writer can extend by editing data files only. GDScript only, no C#, no new addons.

## Principles

1. **Content is data, logic is code.** Situations, memories and endings live in JSON. Nobody edits `.tscn` to add a situation.
2. **One source of truth.** `GameState` (autoload) owns every number. UI nodes read it and listen to its signals. They never keep their own copy of a stat.
3. **Derived stats.** A stat is `base + sum of held memories' packages`. Giving up a memory just removes it from the held list, so the total, the beads and the bars all update from one change.
4. **Linear flow.** The run is a list of beats that one controller walks with `await`. No state machine class, no branching.
5. **Dialogue Manager is for prose only** (intro, memory text, "give it up?", endings). Cards, stats and flow are not written in `.dialogue`.

## Runtime picture

```
GameState (autoload)         Content (autoload, loads JSON)
  base{style,sturdiness,size}    situations / memories / endings / run order
  held_memories[]
  signals: stats_changed, memory_lost, run_finished
        ^                                  ^
        | reads / listens                  | reads
Game.tscn  (GameController.gd)  -- walks run.json, one beat at a time
  |-- Background, Raft, Character   (existing art)
  |-- HUD            3 stat bars + bead thread (listens to GameState)
  |-- PromptLabel    situation text
  |-- CardRow        spawns 3 ChoiceCards, emits chosen(index)
  |-- MemoryPicker   tarot cards -> reveal -> give up?
  |-- EndingScreen   text + background + back to menu
```

## Data formats

`data/situations.json`
```json
[{ "id": "stars_relax",
   "text": "You want to relax, easing into your journey...",
   "choices": [
     { "label": "Watch the stars", "style": 7, "sturdiness": 0, "size": 0 },
     { "label": "Run your hand through the water", "sturdiness": 7 },
     { "label": "Take a nap", "size": 7 } ] }]
```
Missing stat keys count as 0.

`data/memories.json`: `id`, `card` (image name in `assets/Cards`), `title`, `dialogue_label` (cue in `memories.dialogue`), and `package` (`style`/`sturdiness`/`size`, the values from the doc, for example the playground memory is 20/10/10).

`data/endings.json`: `id`, `title`, `text`, `background`, `rule` (`highest_style`, `highest_sturdiness`, `highest_size`, `death`).

`data/run.json`: ordered beats, for example `["sit:stars_relax", "sit:check_supplies", "mem", "sit:fishing", "sit:rest", "mem", "end"]`.

## Components

| File | Responsibility |
|---|---|
| `scripts/autoload/game_state.gd` | Holds `base` and `held_memories`. `stat(name)`, `apply(deltas)`, `give_up(memory_id)`, `give_up_all()` (Death card), `beads_left()`, `fool_unlocked()` (no memories held), `pick_ending()`. Emits signals. |
| `scripts/autoload/content.gd` | Loads the four JSON files once and returns plain Dictionaries. |
| `scripts/game/game_controller.gd` | `for beat in run:` runs `show_situation` (set text, `await card_row.chosen`, `GameState.apply`), `show_memory_event` (`await memory_picker.finished`) or `show_ending`. Then fades. |
| `scenes/ui/choice_card.tscn` | Replaces the drag-and-drop card. Label plus stat deltas, hover scale, click emits `picked`. Delete `card_manager.gd`'s drag code. |
| `scenes/ui/card_row.tscn` | `present(choices)`, spawns cards in an HBox, emits `chosen(index)`, tweens them out. |
| `scenes/ui/hud.tscn` | Three `TextureProgressBar`s using `bar.png` and `empty_bar.png`, tweened on `stats_changed`, plus the bead thread bound to `beads_left()`. |
| `scenes/ui/memory_picker.tscn` | Shows the tarot cards you still hold. Pick one, then the memory text plays through the balloon, then a `- Let it go` / `- Keep it` response. Let it go calls `GameState.give_up`. Wheel of Fortune picks a random held memory. Hanged Man skips. Death calls `give_up_all()` then the Fool ending path. |
| `data/dialogue/*.dialogue` | Prose. Choices call `do GameState.give_up("playground")` directly. |

## Ending rules (proposed defaults)

- Death card played, or "jump off the boat" chosen: secret bittersweet ending.
- Otherwise the highest of the three stats at the end of the run decides: Style, Sturdiness or Size ending. Ties go to Style, then Sturdiness.
- Fool (all memories given up) adds +40 style, which usually tips the ending to Style.

## Mapping from what exists

- Keep: main menu, fade scripts, `Game.tscn` art, fullscreen toggle (move it into the HUD), Dialogue Manager.
- Replace: `card.tscn`, `card_manager.gd`, `card.gd` (dragging, hover signals through the parent).
- Delete: `new_script.gd`, the `.DS_Store` files, the template labels in `untitled.dialogue` (`start`, `narration` demo choices, the pasted `game` block, which moves to `situations.json`).
- Kanban: "Speakers", "Choices", "Encounters", "Card Data", "Drawing Cards", "Hand/Deck" and "Card select" all collapse into `Content`, `CardRow` and `ChoiceCard`.

## Build order

1. `GameState` and `Content` with 3 situations (1.5 h). Test by printing stats from a debug key.
2. `ChoiceCard`, `CardRow` and the controller loop on the real Game scene (2 h). First playable.
3. HUD bars (1 h).
4. Memory picker and bead thread (3 h).
5. Endings and results screen (1.5 h).
6. Move all 12 situations into JSON (writer, in parallel from step 1).
7. Export, polish, audio (last 3 h).

## Working in parallel without merge pain

`Game.tscn` is rewritten by the editor on almost every save, so one person owns it. The writer works only in `data/` and the `.dialogue` files. The artist drops files into `assets/` and does not edit scenes.
