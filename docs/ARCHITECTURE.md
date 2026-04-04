# Architecture Notes

The project uses a modular script split. The scene controller lives in `scripts/gameplay/game.gd`, while gameplay rules, shot planning, coordinate conversion, particles, and burst animation are in dedicated helper scripts.

## Main Modules

- `scripts/gameplay/game.gd`: scene orchestration, input handling, HUD updates, resolution sequencing, and custom `_draw()` rendering
- `scripts/gameplay/board_state.gd`: board data, match resolution, floating-bubble cleanup, scoring, wave spawning, grid compaction, and reserve row management
- `scripts/gameplay/shot_planner.gd`: aim assist, wall-bounce path simulation, and snap targeting
- `scripts/gameplay/grid_layout.gd`: single source of truth for `cell_center()`, `cell_center_static()`, and `playfield_rect()` — shared by game, shot planner, and board state
- `scripts/gameplay/particle_pool.gd`: particle lifecycle (`spawn_burst`, `spawn_spark`, `spawn_impact_sparks`, `update`) — game.gd calls pool methods and draws results
- `scripts/gameplay/burst_phase_builder.gd`: static `build_phases()` for ordering cluster and floating burst animations — pure data logic, no rendering dependency
- `scripts/gameplay/burst_sequence_guard.gd`: guards phase transitions (cluster → floating) during animated burst sequences
- `scripts/gameplay/hex_grid.gd`: hex neighbor topology — stagger deltas, row parity, neighbor enumeration
- `scripts/gameplay/stack_settle.gd`: post-pop anchor slide math (`compute_anchor_slide_delta`, `deepest_occupied_row`)

## Supporting Modules

- `scripts/audio/sfx_controller.gd`: procedural gameplay sound effects
- `scripts/data/wave_config.gd`: loads and normalizes per-wave parameter tables from JSON
- `scripts/data/save_manager.gd`: checkpoint, high score, settings, and onboarding persistence
- `scripts/ui/`: main menu, splash, settings panel, shared UI theme

## Core State

- `grid`: 2D array of bubble color IDs, with `-1` representing an empty cell
- `reserve_rows`: rows not yet visible, fed to the grid via baseline refill or (future) shift push
- `active_bubble`: in-flight shot state, including the precomputed path and snap target
- `score`, `wave`: progression state
- `row_parity_offset`: flips row staggering when rows are inserted or removed

## Coordinate Conversion

All coordinate math goes through `BubbleGridLayout`:

- `cell_center(row, col, parity_offset)` — world position including `stack_visual_offset` (for rendering and collision)
- `cell_center_static(row, col, parity_offset)` — world position without visual offset (for logic checks like loss detection and float adjacency)
- `playfield_rect()` — axis-aligned rectangle encompassing the active play area

`game.gd`, `shot_planner.gd`, and `board_state.gd` all reference the same `BubbleGridLayout` instance. No duplicate coordinate formulas.

## Board Model

The board uses staggered rows so each bubble has up to 6 hex neighbors.

- `hex_grid.gd` defines neighbor deltas for even/odd row parity
- `board_state.get_neighbors()` returns adjacency based on row parity
- `shot_planner.find_best_snap_cell()` decides where a bubble should land after a hit
- Float adjacency uses distance-based checks via `grid_layout.cell_center_static()` when viewport info is available

## Shot Lifecycle

1. `fire_bubble()` clamps the aim direction and applies a small aim assist.
2. `BubbleShotPlanner.simulate_shot_path()` traces the future path, including wall bounces.
3. `update_active_bubble()` moves the in-flight bubble along the precomputed path.
4. `place_active_bubble()` snaps the shot into the board and hands resolution to `BubbleBoardState`.

This pre-simulated approach keeps the guide path and the actual shot behavior aligned.

## Match Resolution

- `BubbleBoardState.collect_cluster()` performs a flood-fill for same-color neighbors.
- `BubbleBoardState.pop_cluster_from()` removes clusters of size 3 or more.
- `BubbleBoardState.remove_floating_bubbles()` performs a top-connected BFS and clears unsupported bubbles.
- `BubbleBoardState.compact_grid()` removes fully empty rows and adjusts parity.
- `BubbleBoardState._refill_to_baseline()` pulls reserve rows into the grid (inserted at ceiling) to maintain `initial_visible_rows()`.

The floating-bubble cleanup creates the classic "hanging group falls after support is removed" behavior.

## Row Management

The wave spawns `TOTAL_WAVE_DEPTH_ROWS` (100) rows. The first `initial_visible_rows()` (~6) are placed in `grid`; the rest go to `reserve_rows`.

- **Baseline refill**: after every resolution, if `grid.size() < initial_visible_rows()` and reserve has rows, new rows are inserted at position 0 (ceiling), pushing the stack down. This maintains a minimum visible board after chain reactions.
- **Shift push** (currently disabled): a shot counter that would insert 1 extra row every N shots for gradual pressure. The mechanic exists in `try_push_shift_row()` but is not called from the game loop.

New rows always enter at the ceiling (position 0) with a parity flip, matching classic bubble-shooter top-down pressure.

## Visual Animation

Grid offset animation uses a single exponential decay:

```gdscript
stack_visual_offset *= exp(-8.0 * delta)
```

This handles all visual transitions (baseline refill, future shift push) with consistent ease-out behavior regardless of offset magnitude. No tweens, no spring physics.

## Rendering Strategy

`_draw()` renders all visuals in a single pass:

- background accents and ambient stars
- playfield frame and grid slot hints
- placed bubbles (PNG textures via `draw_texture_rect`)
- flying bubble with trail effects
- burst animation bubbles
- particles (pop bursts, sparks)
- launcher, aim guide, and next-bubble preview

Bubble textures are in `assets/bubbles/png/`. Code-driven glow and trail effects complement the textures.

## Test Infrastructure

- `tests/run_tests.gd`: headless runner for all unit tests (44 cases)
- `tests/gameplay_harness.gd`: multi-seed gameplay simulation — fires thousands of shots per seed, validates grid invariants (no blank rows, row-0 occupied, parity valid, baseline row count, ceiling-insert ordering) after every shot
- `tests/unit/`: individual test suites for board_state, wave_spawn, wave_config, shot_planner, burst_sequence_guard, burst_phases, save_manager, stack_settle
- `tests/helpers/`: test case base class and factory utilities

Run tests:
```bash
godot --headless -s res://tests/run_tests.gd
godot --headless -s res://tests/gameplay_harness.gd
```
