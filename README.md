# Bubble Shooter

A compact Bubble Shooter game built with Godot 4.6 for portrait mobile play. The project currently lives in a single gameplay scene and a single script, which makes the rules and rendering pipeline easy to inspect before the first public commit.

## Highlights

- Portrait-first layout tuned for phone screens
- Wall-bounce aiming with a projected shot guide
- Staggered bubble grid with match-3 popping
- Floating bubble cleanup after supported clusters are removed
- Wave progression with ceiling drops after a fixed number of shots
- Lightweight mobile/desktop visual profile switching

## Gameplay Rules

1. Aim from the bottom launcher using mouse or touch.
2. Fire a colored bubble into the staggered board.
3. If the placed bubble creates a connected group of 3 or more of the same color, that cluster pops.
4. Any bubbles no longer connected to the top row are removed as floating bubbles.
5. If a shot does not clear a cluster, the ceiling advances after every 5 shots.
6. Clearing the whole board starts the next wave.
7. The game ends if the stack crosses the warning line above the launcher.

## Controls

- Desktop: move the mouse to aim, left-click to fire
- Mobile: drag to aim, release touch to fire
- Restart: use the in-game restart button or the game-over overlay button

## Project Structure

- `project.godot`: project configuration and main scene entrypoint
- `scenes/game.tscn`: single gameplay scene and UI layout
- `scripts/game.gd`: gameplay state, shot simulation, matching, scoring, and custom drawing
- `export_presets.cfg`: Android export preset

## Running The Project

### Godot Editor

1. Open the folder in Godot 4.6.
2. Load `project.godot`.
3. Run the main scene or press play.

### Android Export

The repository includes an Android export preset that writes the APK to `build/BubbleShooter.apk`. The `build/` directory is intentionally ignored so generated binaries do not end up in source control.

## Implementation Notes

- The board uses a staggered 9-column grid to emulate classic bubble-shooter adjacency.
- Shot placement is pre-simulated so aiming, wall bounces, and snapping stay deterministic.
- New shots are restricted to colors currently present on the board, which keeps the game solvable and reduces dead draws.
- Rendering is code-driven in `scripts/game.gd`, including the board, particles, launcher, and HUD effects.

More detailed gameplay internals are documented in `docs/ARCHITECTURE.md`.
