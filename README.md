# Bubble Shooter

A compact Bubble Shooter game built with Godot 4.6 for portrait mobile play. The project uses a modular script split so gameplay rules, shot planning, rendering, and visual effects stay isolated and testable.

## Highlights

- Portrait-first layout tuned for phone screens
- Wall-bounce aiming with a projected shot guide
- Staggered hex bubble grid with match-3 popping
- Floating bubble cleanup after supported clusters are removed
- 25-wave data-driven progression with per-wave difficulty tuning
- Baseline row refill from reserve after chain reactions
- Lightweight mobile/desktop visual profile switching

## Gameplay Rules

1. Aim from the bottom launcher using mouse or touch.
2. Fire a colored bubble into the staggered board.
3. If the placed bubble creates a connected group of 3 or more of the same color, that cluster pops.
4. Any bubbles no longer connected to the top row are removed as floating bubbles.
5. When chain reactions clear rows, reserve rows refill the grid from the ceiling to maintain a playable board.
6. Clearing the whole board starts the next wave.
7. The game ends if the stack crosses the warning line above the launcher.

## Controls

- Desktop: move the mouse to aim, left-click to fire
- Mobile: drag to aim, release touch to fire
- Restart: use the in-game restart button or the game-over overlay button

## Project Structure

```
scripts/gameplay/
  game.gd              — scene orchestration, input, HUD, rendering
  board_state.gd       — board rules, matching, floating cleanup, scoring, wave spawn
  shot_planner.gd      — aim assist, wall-bounce path, snap targeting
  grid_layout.gd       — unified coordinate conversion (cell_center, playfield_rect)
  particle_pool.gd     — particle lifecycle (spawn, update)
  burst_phase_builder.gd — burst animation ordering (cluster/floating phases)
  burst_sequence_guard.gd — guards phase transitions during burst animations
  hex_grid.gd          — hex neighbor topology (stagger deltas, parity)
  stack_settle.gd      — post-pop anchor slide math

scripts/audio/
  sfx_controller.gd    — procedural gameplay SFX

scripts/ui/
  main_menu.gd         — main menu scene controller
  splash.gd            — splash/intro screen
  settings_panel.gd    — settings UI
  ui_theme.gd          — shared UI styling

scripts/data/
  wave_config.gd       — wave parameter table loader
  save_manager.gd      — checkpoint, scores, settings persistence

data/
  waves_v0_1.json      — first 25 waves authored

tests/
  run_tests.gd         — headless unit test runner
  gameplay_harness.gd   — multi-seed gameplay simulation (grid invariant checks)
  unit/                — unit tests (board, wave, shot planner, burst, save, etc.)
  helpers/             — test factories and assertions
```

## Running The Project

### Godot Editor

1. Open the folder in Godot 4.6.
2. Load `project.godot`.
3. Run the main scene or press play.

### Tests

```bash
# Unit tests (44 cases)
godot --headless -s res://tests/run_tests.gd

# Gameplay simulation (5 seeds × 4000 shots, grid invariant checks)
godot --headless -s res://tests/gameplay_harness.gd
```

### Android Export

The repository includes an Android export preset that writes the APK to `build/BubbleShooter.apk`. The `build/` directory is intentionally ignored so generated binaries do not end up in source control.

## Implementation Notes

- The board uses a staggered 9-column hex grid to emulate classic bubble-shooter adjacency.
- Shot placement is pre-simulated so aiming, wall bounces, and snapping stay deterministic.
- New shots are restricted to colors currently present on the board, keeping the game solvable.
- Coordinate conversion is centralized in `BubbleGridLayout`, shared by game, shot planner, and board state.
- Bubbles are rendered using PNG textures with code-driven glow/trail effects.

More detailed gameplay internals are documented in `docs/ARCHITECTURE.md`.
