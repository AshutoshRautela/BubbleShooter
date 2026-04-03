# Power-Ups

Two categories: **Board Power-Ups** (affect the grid) and **Cannon Powers** (affect the shooter). Both earned through skill — no pay-to-win.

---

## Board Power-Ups — Summary

| Power-Up | Symbol | Unlocked At | Effect | Duration |
|---|---|---|---|---|
| Aim Assist Pro | 🎯 | Wave 5 | Exact landing cell shown | 5 shots |
| Color Switch | 🎨 | Wave 10 | Choose current bubble color | 1 shot |
| Row Shield | 🛡️ | Wave 18 | Block next row push | 1 push |
| Freeze | ❄️ | Wave 25 | Pause row push counter | 5 shots |
| Color Bomb | 💥 | Wave 30 | Convert current bubble to Bomb | 1 shot |
| Wildcard Rain | 🌟 | Wave 45 | Next 3 bubbles are Rainbow | 3 shots |

---

## How to Earn

Power-ups are earned through skill actions — not purchased or randomly dropped.

| Power-Up | Earn Condition |
|---|---|
| Aim Assist Pro | 3 consecutive matching shots (no misses) |
| Color Switch | Score 200+ points in a single shot |
| Row Shield | Clear board without any row push occurring during the wave |
| Freeze | 5+ floating bubbles removed in a single shot, OR Stone bubble safely isolated |
| Color Bomb | Complete a wave (any wave ≥ 30) |
| Wildcard Rain | Score 150+ points in a single shot that includes a Multiplier bubble |

---

## Cooldowns & Limits

| Power-Up | Max per Wave | Cooldown After Use |
|---|---|---|
| Aim Assist Pro | Unlimited | None |
| Color Switch | Unlimited | 3 shots |
| Row Shield | 1 | — |
| Freeze | Unlimited | 10 shots |
| Color Bomb | 1 | — |
| Wildcard Rain | 1 | — |

---

## Detailed Mechanics

---

### 1. Aim Assist Pro 🎯

**Effect:** The aiming guide becomes enhanced — instead of just showing the path, it highlights the exact grid cell where the bubble will land. Landing cell pulses with a bright ring.

**Duration:** 5 shots from activation

**Earn:** 3 consecutive matches (misfire resets the counter)

**UI:** Slot glows when available. Tap to activate. Counter shows remaining shots (5→4→3→2→1).

**Design note:** Early unlock (Wave 5) to reduce frustration for new players. Falls off in usefulness by Phase 3 — skilled players won't need it.

---

### 2. Color Switch 🎨

**Effect:** A color picker appears above the cannon showing all colors currently on the board. Player taps one — current bubble changes to that color. Fire as normal.

**Duration:** 1 shot (color change persists until fired)

**Earn:** Single shot scores 200+ points (big cluster clear)

**Cooldown:** 3 shots wait before usable again

**UI:** Tap slot → color dots appear as selection UI. Tap color → bubble changes. Tap again to cancel.

**Design note:** Rewarded for skill (big pops), used for precision targeting. Creates satisfying skill loop — do well, get better tools.

---

### 3. Row Shield 🛡️

**Effect:** The next row push from ceiling is blocked entirely. `shots_until_shift` counter resets as if the push happened, but no row is added to the board.

**Duration:** Blocks 1 push event

**Earn:** Clear a wave from start without any row push occurring (pure no-miss wave)

**Limit:** 1 per wave — does not stack

**UI:** Shield icon glows when active. Automatically consumes when row push would trigger.

**Design note:** Hard to earn but powerful reward — encourages clean play. Most useful in Phases 3–5 when push timing gets brutal.

---

### 4. Freeze ❄️

**Effect:** The `shots_until_shift` counter stops decrementing for 5 shots. Existing count is preserved — resumes after the 5 shots.

**Duration:** 5 shots from activation

**Earn:** Remove 5+ floating bubbles in a single shot, OR successfully isolate a Stone bubble (it falls)

**Cooldown:** 10 shots after duration ends

**UI:** Cooldown ring shown on slot. When active, shots_until_shift counter on HUD shows a frost tint.

**Design note:** Rewards creative play — big chain reactions that cause floating cascades earn breathing room.

---

### 5. Color Bomb 💥

**Effect:** The current bubble in the cannon is converted into a Bomb bubble for one shot. Fires and behaves exactly like a board-spawned Bomb (7-cell blast radius, destroys Stone bubbles).

**Duration:** 1 shot

**Earn:** Complete any wave (wave number ≥ 30)

**Limit:** 1 per wave — awarded at wave complete, usable next wave

**UI:** Cannon bubble visually changes to Bomb appearance when active. Slot shows "READY" state.

**Design note:** Wave completion reward creates a carrot for struggling players — "clear this wave and you get a bomb for next one." Helps with pacing in Phases 3–4.

---

### 6. Wildcard Rain 🌟

**Effect:** The next 3 bubbles queued in the cannon are all Rainbow bubbles, regardless of what they would have been. Score multiplier from Rainbow (×1.5) applies to each.

**Duration:** 3 shots

**Earn:** Score 150+ points in a single shot that includes at least one Multiplier bubble in the cluster

**Limit:** 1 per wave

**UI:** Cannon preview and next-bubble indicator both show rainbow animation when active. Bubble count shows (3→2→1).

**Design note:** Requires skill to trigger (hit a Multiplier in a big cluster), then rewards with a powerful 3-shot window. Creates exciting mid-game momentum swings.

---

## UI Layout

```
[ Bottom Right Corner — 3 Power-Up Slots ]

┌──────┐  ┌──────┐  ┌──────┐
│  🎯  │  │  🎨  │  │  ❄️  │
│  ●●● │  │ COOL │  │  5s  │
└──────┘  └──────┘  └──────┘
  READY    3 shots    READY
```

- 3 slots visible at a time — cycle through with swipe if more are available
- Glow pulse animation when newly earned
- Tap to activate — no confirmation dialog (reduces friction)
- Greyed out when on cooldown, progress ring shows cooldown

---

## Power-Up Introduction Timeline

```
Wave 5  →  Aim Assist Pro unlocks
Wave 10 →  Color Switch unlocks
Wave 18 →  Row Shield unlocks
Wave 25 →  Freeze unlocks
Wave 30 →  Color Bomb unlocks
Wave 45 →  Wildcard Rain unlocks
```

---

---

# Cannon Powers

5 powers that modify how the cannon fires — separate from board power-ups. Where board power-ups affect *what's on the grid*, cannon powers affect *how you shoot*.

**Key difference from board power-ups:**
- Board power-ups are earned mid-wave and used tactically
- Cannon powers are **equipped before a wave starts** — player picks one per wave from a selection of 3 (like a roguelite pick)

---

## Cannon Powers — Summary

| Power | Symbol | Unlocked At | Effect | Duration |
|---|---|---|---|---|
| Rapid Fire | ⚡ | Wave 8 | 3 quick shots, no aim reset | 3 shots |
| Guided Shot | 🧲 | Wave 15 | Steer bubble mid-air | 1 shot |
| Split Shot | ✂️ | Wave 28 | Bubble splits into 2 on fire | 1 shot |
| Charged Shot | 🔋 | Wave 38 | Hold to charge — faster + blast on impact | 1 shot |
| Bouncy Mode | 🎱 | Wave 52 | Extra wall bounces (up to 4) | 5 shots |

---

## How Cannon Power Selection Works

```
Wave Complete Screen
        ↓
"Choose your cannon power for Wave X"
        ↓
[ Power A ]   [ Power B ]   [ Power C ]   [ No Power ]
  (random 3 from unlocked pool)
        ↓
Player picks one → Active for entire next wave
```

- Options are 3 random picks from the unlocked pool + always one "No Power" option
- Chosen power stays active the entire wave — cannot be changed mid-wave
- Wave 1–7: No selection (cannon powers not yet unlocked)
- From Wave 8 onwards: Selection screen appears after every wave complete

---

## Detailed Mechanics

---

### 1. Rapid Fire ⚡

**Effect:** The aim guide disappears. Player fires 3 bubbles in quick succession — each shot fires as soon as the previous one lands. No waiting, no re-aim.

**How it plays:** Tap once → first shot fires. Tap again quickly → second shot fires from same angle OR from wherever the aim moved. Fast rhythm, high risk.

**Duration:** 3 shot burst (then normal mode resumes for remaining shots in the wave)

**Unlocked:** Wave 8

**Earn condition to unlock:** Pop a cluster of 8+ bubbles in a single shot

**Design note:** Rewards aggressive fast players. Works great on dense boards. Terrible on sparse boards where placement precision matters. Player must read the board before choosing this.

---

### 2. Guided Shot 🧲

**Effect:** After firing, the bubble can be steered left/right by dragging finger/mouse while it's in flight. Steering range: ±25° from original trajectory. Wall bounce physics still apply to the guided path.

**Duration:** 1 shot per activation. Can be triggered once per wave.

**Unlocked:** Wave 15

**Earn condition to unlock:** Complete Wave 15 milestone (Stripe board)

**Activate:** Tap cannon power slot before firing. Next shot is guided.

**Design note:** High skill ceiling — master players can thread bubbles through gaps with this. Beginners might find it disorienting. Must have visual indicator on bubble showing the steering arc.

---

### 3. Split Shot ✂️

**Effect:** One bubble is fired but splits into 2 identical bubbles mid-air at the halfway point of the trajectory. Both bubbles travel to separate positions on the board — left split goes to nearest valid cell left of original path, right split goes right.

Both bubbles are the same color as the original. Both can trigger matches independently.

**Duration:** 1 shot

**Unlocked:** Wave 28

**Earn condition to unlock:** Score 300+ points in a single shot (big cluster + floating cascade)

**Design note:** Extremely powerful when aimed at a cluster that has same-color neighbors on both sides. Animation should be visually spectacular — split moment must feel satisfying.

---

### 4. Charged Shot 🔋

**Effect:** Hold the fire button to charge. Charge meter fills over 1.5 seconds.

| Charge Level | Effect |
|---|---|
| No charge (tap) | Normal shot |
| Half charge (0.75s hold) | 2× shot speed, no special effect |
| Full charge (1.5s hold) | 3× shot speed + small blast on impact (3-cell radius) — like a mini bomb |

Full charge blast destroys adjacent bubbles of ANY color within 3-cell radius, then normal match check runs on what remains.

**Duration:** 1 charged shot available per wave (charge meter recharges after 8 shots)

**Unlocked:** Wave 38

**Earn condition to unlock:** Successfully isolate and drop 2 Stone bubbles in the same wave

**Design note:** Visual charge-up glow on cannon is critical feedback. Adds tension — player decides when to spend their charge. Most effective against Stone bubble clusters.

---

### 5. Bouncy Mode 🎱

**Effect:** The bubble ricochets off walls up to 4 times (default is effectively 2). Extended bouncing allows reaching positions behind clusters or at extreme angles.

**Duration:** Active for 5 shots

**Unlocked:** Wave 52

**Earn condition to unlock:** Land 3 wall-bounce shots in a row (all 3 must bounce at least once AND match)

**Design note:** Late-game positioning tool. By Wave 52 the board is dense — direct shots are often blocked. Bouncing behind clusters to hit isolated same-color bubbles becomes a key skill. Aim guide extends to show all 4 bounce points.

---

## Cannon Power Introduction Timeline

```
Wave 8  →  Rapid Fire unlocks (first selection screen appears)
Wave 15 →  Guided Shot unlocks
Wave 28 →  Split Shot unlocks
Wave 38 →  Charged Shot unlocks
Wave 52 →  Bouncy Mode unlocks
```

---

## Combined Power-Up + Cannon Power Strategy Examples

| Situation | Board Power | Cannon Power |
|---|---|---|
| Dense board, low shots left | Color Bomb | Charged Shot — double blast |
| Board full of Stone bubbles | Freeze (buy time) | Charged Shot — breaks stone clusters |
| Isolated same-color bubbles everywhere | Wildcard Rain | Bouncy Mode — reach everything |
| Big open board, easy clusters | — | Rapid Fire — clear fast |
| Single hard-to-reach bubble | Color Switch | Guided Shot — thread the needle |

---

## Full Introduction Timeline (Both Systems)

```
Wave 5  →  Aim Assist Pro (board)
Wave 8  →  Rapid Fire (cannon)
Wave 10 →  Color Switch (board)
Wave 15 →  Guided Shot (cannon)
Wave 18 →  Row Shield (board)
Wave 25 →  Freeze (board)
Wave 28 →  Split Shot (cannon)
Wave 30 →  Color Bomb (board)
Wave 38 →  Charged Shot (cannon)
Wave 45 →  Wildcard Rain (board)
Wave 52 →  Bouncy Mode (cannon)
```
