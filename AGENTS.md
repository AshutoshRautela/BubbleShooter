# Bubble Shooter Agent Rules

These instructions are specific to this repository and should be followed by every agent working on this app.

## Architecture

- Keep `scripts/game.gd` focused on scene orchestration, input handling, HUD updates, and rendering.
- Keep board rules, scoring, wave progression, and bubble matching in `scripts/board_state.gd`.
- Keep shot simulation, aim assist, bounce prediction, and snap targeting in `scripts/shot_planner.gd`.
- Do not collapse the gameplay back into a single large script unless the user explicitly asks for it.

## Change Hygiene

- Review `git status -sb` and the relevant diff before staging or committing.
- Remove dead, duplicate, and stale code introduced by the current change before publishing.
- Stage only files that belong to the requested scope.
- Do not silently include unrelated work.

## Publish Workflow

- If work starts from `main`, create a feature branch before committing.
- Use a clear commit subject and add a body when the change is non-trivial.
- Push the feature branch, not `main`, unless the user explicitly requests otherwise.
- Open a PR after push and summarize validation performed plus any remaining risks.

## Validation

- Run the most relevant checks available before publishing.
- If automated validation is not available, call that out explicitly in the final summary.
