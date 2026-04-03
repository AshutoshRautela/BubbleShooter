# Architecture Notes

This project is intentionally small. Nearly all gameplay and rendering logic lives in `scripts/game.gd`, attached to `scenes/game.tscn`.

## Core State

- `grid`: 2D array of bubble color IDs, with `-1` representing an empty cell
- `active_bubble`: in-flight shot state, including the precomputed path and snap target
- `score`, `wave`, `shots_until_shift`: progression state
- `row_parity_offset`: flips row staggering when a new ceiling row is inserted

## Board Model

The board is not a square grid. It uses staggered rows so each bubble has up to 6 neighbors, which matches classic bubble-shooter behavior.

- `get_neighbors()` returns adjacency based on row parity
- `cell_to_world()` converts board cells into screen positions
- `find_best_snap_cell()` decides where a bubble should land after a hit

## Shot Lifecycle

1. `fire_bubble()` clamps the aim direction and applies a small aim assist.
2. `simulate_shot_path()` traces the future path, including wall bounces.
3. `update_active_bubble()` moves the in-flight bubble along the precomputed path.
4. `place_active_bubble()` snaps the shot into the board and resolves the result.

This pre-simulated approach keeps the guide path and the actual shot behavior aligned.

## Match Resolution

- `collect_cluster()` performs a flood-fill for same-color neighbors.
- `pop_cluster_from()` removes clusters of size 3 or more.
- `remove_floating_bubbles()` performs a top-connected search and clears unsupported bubbles.

The floating-bubble cleanup is what creates the classic “hanging group falls after support is removed” behavior.

## Progression And Failure

- The board starts with `START_ROWS` rows.
- Every non-clearing shot decreases `shots_until_shift`.
- When the counter reaches zero, `push_row_from_ceiling()` inserts a fresh row at the top.
- `check_loss_condition()` ends the game once the stack crosses the warning line.
- If the board is fully cleared, `spawn_wave()` starts the next wave with the current difficulty palette.

## Rendering Strategy

The game does not rely on bubble sprites. Instead, `_draw()` renders:

- background accents
- playfield frame
- placed bubbles
- flying bubble
- particles and hit waves
- launcher and aiming guide

This keeps the repository asset-light and makes visual iteration straightforward.

## Commit Hygiene

The repository ignores editor cache, generated Android output, logs, and exported binaries. The intended first commit should focus on source files and project configuration rather than local artifacts.
