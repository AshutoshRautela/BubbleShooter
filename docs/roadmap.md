# Roadmap

4 releases planned. Each release is independently shippable — not a branch that sits waiting.

---

## Release Overview

| Release | Name | Goal | Target |
|---|---|---|---|
| v0.1 | **Core Ship** | Playable, shippable 25-wave launch on Play Store | — |
| v0.2 | **Content & Feel** | 100 waves, dopamine polish, new bubbles | After v0.1 feedback |
| v0.3 | **Systems** | Power-ups, cannon powers, chapter map | After v0.2 stabilizes |
| v0.4 | **Growth** | Leaderboard, social, seasonal | When DAU is stable |

---

---

## v0.1 — Core Ship

> Goal: Get a real, complete 25-wave game on the Play Store. Nothing fancy — just solid.

### Must Have (blocking release)

- [ ] `wave_config.gd` — first 25-wave parameter table (colors, shots/shift, density per wave)
- [ ] High score persistence — top 5 runs saved to `user://scores.cfg`
- [ ] Pause / resume — pause button, overlay, Android back-button support
- [ ] Main menu — title, Continue, New Game, High Scores
- [ ] Game over screen redesign — score breakdown, wave reached, PR indicator
- [ ] FPS label hidden in release builds (`fps_label.visible = OS.is_debug_build()`)
- [ ] Android keystore signing setup
- [ ] Privacy policy URL / compliance setup for Play Store listing
- [ ] Tutorial / onboarding — first launch flow that gets player through Wave 1 cleanly

### Should Have (not blocking, but ship with it)

- [ ] Splash screen — 1.5s animated bubbles
- [ ] Settings screen — SFX toggle, volume slider
- [ ] Status message polish — "Row in X shots" always visible, not just on no-match
- [ ] High Scores screen — personal top 5 with wave + date

### Definition of Done

```
✓ Installs on Android without crash
✓ Game loop works start to finish (Wave 1 → Wave 25 / Game Over → Restart)
✓ First session is understandable without external explanation
✓ Score saves and loads correctly
✓ Pause works mid-game
✓ No FPS label visible
✓ Listed on Play Store (even internal testing track)
```

---

---

## v0.2 — Content & Feel

> Goal: Game feels alive. 100 waves of actual progression. Dopamine moments land.

### Must Have

- [ ] Expand `wave_config.gd` from 25 waves to full 100-wave curve
- [ ] Wave difficulty curve live — shots/shift drops at W25, W45, W65
- [ ] Milestone wave detection — W10, W20, W30... get score multipliers
- [ ] Wave complete screen — score breakdown, auto-advance to next wave
- [ ] Board clear sequence — 80ms pause → flash → count-up (dopamine-design.md)
- [ ] Cluster size → pitch scaling on pop SFX
- [ ] Cascade fall animation — staggered floating bubble removal
- [ ] Near-miss "Close call!" detection + message
- [ ] Consecutive match streak system — ON FIRE / UNSTOPPABLE / LEGEND MODE
- [ ] Soft hint after 4 consecutive misses
- [ ] Haptic feedback — fire, pop, board clear, game over
- [ ] Background music — Menu + Chapter 1–3 loops + Board Clear Sting (bgm-design.md)

### Should Have

- [ ] Lucky shot detection — wall bounce → big cluster → "LUCKY! 🍀"
- [ ] Row countdown warning — "Row dropping next shot" amber message
- [ ] Milestone moment screen (W10, W20...) — badge reveal sequence
- [ ] Wave path teaser on wave complete — "Next: first wave with Bomb bubbles"
- [ ] PR fanfare SFX (generate new procedural sound)
- [ ] Chapter 4–6 BGM loops deferred to later release

### Definition of Done

```
✓ Wave 1 and Wave 50 feel noticeably different in difficulty
✓ Board clear always feels satisfying (the pause + flash)
✓ Player can see their streak on HUD
✓ Milestone waves (W10, W20...) have distinct celebratory moment
✓ 100-wave progression is playable end-to-end
✓ No regression from v0.1
```

---

---

## v0.3 — Systems

> Goal: Deep game. New bubble types, power-ups, chapter map. Replayability goes up.

### Must Have

#### New Bubble Types (bubble-types.md)
- [ ] Stone bubble — render + isolation logic
- [ ] Rainbow bubble — wildcard match logic
- [ ] Multiplier bubble — ×2 score logic + render
- [ ] Bomb bubble — blast radius logic (hex radius 2) + chain trigger
- [ ] Ice bubble — debuff on direct hit + render
- [ ] Chaos bubble — color cycle timer + timing bonus
- [ ] Spawn rate tables per wave phase

#### Board Power-Ups (power-ups.md)
- [ ] `powerup_manager.gd` — earn conditions, cooldowns, slot UI
- [ ] Aim Assist Pro
- [ ] Color Switch
- [ ] Row Shield
- [ ] Freeze
- [ ] Color Bomb
- [ ] Wildcard Rain

#### Cannon Powers (power-ups.md)
- [ ] Cannon power selection screen (ui-ux.md)
- [ ] Rapid Fire
- [ ] Guided Shot
- [ ] Split Shot
- [ ] Charged Shot
- [ ] Bouncy Mode

#### Navigation
- [ ] Chapter Map screen — 6 chapters, lock/unlock states
- [ ] Wave Path screen — zigzag path, star states, bubble type intro badges
- [ ] Chapter unlock moment animation

### Should Have

- [ ] Handcrafted milestone boards (W10, W20, W30, W50) — `level_data.gd`
- [ ] Daily challenge mode
- [ ] Background music — Chapter 4–6 loops + milestone / PR / chapter unlock stings
- [ ] iOS export preset + Game Center stub

### Definition of Done

```
✓ All 7 bubble types spawn correctly per wave phase
✓ All 6 board power-ups earnable and usable
✓ All 5 cannon powers selectable and functional
✓ Chapter Map shows correct lock/unlock state
✓ Wave Path navigable — tap wave → starts that wave
✓ No regression from v0.2
```

---

---

## v0.4 — Growth

> Goal: Social hooks. Retention via leaderboard + seasons. Organic sharing.

### Must Have

#### Online Leaderboard (leaderboard.md)
- [ ] Google Play Games Services integration (Android)
- [ ] Global All-Time Score board
- [ ] Global Highest Wave board
- [ ] Weekly Score board (resets Monday)
- [ ] Leaderboard screen — rank, surrounding players, player's own rank pinned
- [ ] Rank delta display (+X ranks this session)
- [ ] "Play to beat #X" CTA

#### Retention
- [ ] Day streak tracking — consecutive days played
- [ ] Push notifications — weekly board end reminder, streak reminder
- [ ] Share moment on milestone waves — screenshot + text

### Should Have

- [ ] Game Center integration (iOS)
- [ ] Friends leaderboard (Phase 3 from leaderboard.md)
- [ ] Seasonal leaderboard + season badges
- [ ] Wave 100 "LEGEND" share moment — board spells "100"

### Definition of Done

```
✓ Score submits to Play Store leaderboard after game over
✓ Weekly board resets correctly
✓ Player can see their global rank
✓ Share button works on milestone screens
✓ Day streak shows on main menu
✓ No regression from v0.3
```

---

---

## Dependency Map

```
v0.1 (Core Ship)
  └── wave_config.gd          ← needed by everything below
  └── persistence             ← needed by leaderboard (v0.4)
  └── main menu               ← needed by chapter map (v0.3)
  └── onboarding              ← needed for first-session retention

v0.2 (Content & Feel)
  └── full 100-wave curve     ← needed by new bubble timing (v0.3)
  └── wave complete screen    ← needed by cannon power selection (v0.3)
  └── milestone detection     ← needed by handcrafted boards (v0.3)

v0.3 (Systems)
  └── bubble types            ← needed by level_data boards
  └── power-up system         ← needs powerup_manager.gd first
  └── chapter map             ← needs wave_config + persistence

v0.4 (Growth)
  └── leaderboard             ← needs persistence + score system
  └── share moments           ← needs milestone screens (v0.2)
```

---

## New Files Per Release

| File | Release |
|---|---|
| `scripts/wave_config.gd` | v0.1 |
| `user://scores.cfg` (runtime) | v0.1 |
| `scripts/powerup_manager.gd` | v0.3 |
| `scripts/level_data.gd` | v0.3 |
| `scenes/main_menu.tscn` | v0.1 |
| `scenes/chapter_map.tscn` | v0.3 |
| `scenes/wave_path.tscn` | v0.3 |
| `scenes/cannon_select.tscn` | v0.3 |

---

## What v0.1 Does NOT Include

Intentionally deferred — scope creep kills launches:

- New bubble types → v0.3
- Power-ups → v0.3
- Chapter map → v0.3
- Leaderboard → v0.4
- Background music → v0.2
- Full 100-wave progression → v0.2
- iOS → v0.3 (stub), v0.4 (full)
