# UI / UX Design

Mobile-first design. Portrait orientation only. All interactions designed for one thumb.

---

## Screen Map

```
                    ┌─────────────┐
                    │  Splash     │
                    │  Screen     │
                    └──────┬──────┘
                           │ auto (1.5s)
                    ┌──────▼──────┐
                    │    Main     │◄──────────────────┐
                    │    Menu     │                   │
                    └──────┬──────┘                   │
               ┌───────────┼───────────┐              │
               │           │           │              │
        ┌──────▼─────┐  ┌──▼───┐  ┌───▼──────┐       │
        │  Settings  │  │ Play │  │   High   │       │
        │            │  │      │  │  Scores  │       │
        └──────┬─────┘  └──┬───┘  └───┬──────┘       │
               │           │          │ back          │
               └───────────▼──────────┘              │
                    ┌──────▼──────┐                   │
                    │   Chapter   │                   │
                    │    Map      │                   │
                    └──────┬──────┘                   │
                           │ tap chapter              │
                    ┌──────▼──────┐                   │
                    │    Wave     │                   │
                    │    Path     │                   │
                    └──────┬──────┘                   │
                           │ tap wave                 │
                    ┌──────▼──────┐                   │
                    │   Cannon    │ (Wave 8+)          │
                    │   Power     │                   │
                    │  Selection  │                   │
                    └──────┬──────┘                   │
                           │                          │
                    ┌──────▼──────┐                   │
                    │    Game     │                   │
                    │  (Playing)  │                   │
                    └──────┬──────┘                   │
               ┌───────────┼───────────┐              │
               │           │           │              │
        ┌──────▼─────┐  ┌──▼───────┐  ┌▼──────────┐  │
        │   Pause    │  │  Wave    │  │  Game     │  │
        │   Screen   │  │Complete  │  │   Over    │  │
        └──────┬─────┘  └──┬───────┘  └┬──────────┘  │
               │           │           │              │
               │    ┌──────▼──────┐    │              │
               │    │  Milestone  │    │              │
               │    │  Moment     │    │              │
               └────┤  (W10,20..) │    │              │
                    └──────┬──────┘    │              │
                           │           │              │
                           └───────────┘              │
                                  │ Main Menu         │
                                  └───────────────────┘
```

---

## Color System

Game ka visual style — dark background, neon bubble colors. UI follow karta hai isi theme ko.

| Role | Color | Usage |
|---|---|---|
| Background | `#061018` | All screens base |
| Surface | `#0A1E2E` | Cards, panels |
| Surface elevated | `#0F2A3F` | Modal overlays |
| Border subtle | `#8DEED380` (40% opacity) | Panel borders |
| Border accent | `#56EEFF` | Active / focused elements |
| Text primary | `#F7FBFF` | Headings, labels |
| Text secondary | `#9FE8FF` | Sub-labels, hints |
| Text warm | `#FFE9B5` | Score, status messages |
| Accent gold | `#C98B34` | Buttons CTA, milestone highlights |
| Danger | `#FF6B6B` | Lose line, game over |
| Success | `#95E06C` | Board cleared, wave complete |

---

## Typography

Single font throughout — use Godot's default or a clean sans-serif.

| Element | Size | Color | Weight |
|---|---|---|---|
| Screen title | 32px | Primary | Bold |
| Section heading | 24px | Primary | Semi-bold |
| Score / wave | 20px | Warm | Regular |
| Body / status | 16px | Secondary | Regular |
| Hint / caption | 13px | Secondary 60% opacity | Regular |
| FPS debug | 13px | Secondary | Regular — **hidden in release builds** |

---

## Screen Designs

---

### 1. Splash Screen

**Duration:** 1.5s auto-advance, tap to skip

```
┌─────────────────────────┐
│                         │
│                         │
│         ●  ●  ●         │  ← 3 animated bubbles (game colors)
│       ●  ●  ●  ●        │     floating up slowly
│         ●  ●  ●         │
│                         │
│     BUBBLE SHOOTER      │  ← Title, 32px, fade in at 0.8s
│                         │
│                         │
└─────────────────────────┘
```

- Background: `#061018`
- Bubbles float up with slight wobble — reuses game's `draw_bubble()`
- Title fades in at t=0.8s
- Auto-advance to Main Menu at t=1.5s

---

### 2. Main Menu

```
┌─────────────────────────┐
│  ⚙️              🏆     │  ← Settings (top-left), High Scores (top-right)
│                         │
│                         │
│         ●  ●  ●         │  ← Animated bubbles (same as splash)
│       ●  ●  ●  ●        │
│         ●  ●  ●         │
│                         │
│     BUBBLE SHOOTER      │  ← 32px title
│                         │
│   Wave 47 — Contender   │  ← Last played wave + badge (if any)
│                         │
│   ┌─────────────────┐   │
│   │    CONTINUE     │   │  ← Primary CTA — gold button
│   └─────────────────┘   │     (only shown if save exists)
│                         │
│   ┌─────────────────┐   │
│   │    NEW GAME     │   │  ← Secondary button — teal outline
│   └─────────────────┘   │
│                         │
└─────────────────────────┘
```

**Interactions:**
- CONTINUE → Chapter Map (opens on player's current chapter, current wave highlighted)
- NEW GAME → confirmation dialog if save exists ("Start over? Current progress will be lost")
- ⚙️ → Settings overlay slides up
- 🏆 → High Scores overlay slides up

---

### 3. Chapter Map Screen

Main level progression screen. Replaces "Play" as the primary entry point.

```
┌─────────────────────────┐
│  ←        CHAPTERS      │
│                         │
│  ┌─────────────────┐    │
│  │ 🏆  ROOKIE       │    │  ← Completed chapter (gold border)
│  │  Waves 1–15     │    │
│  │  ★★★★★ ★★★★★ ★  │    │  ← 15 stars (one per wave, filled if cleared)
│  │  15 / 15 done   │    │
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ ▶  CONTENDER    │    │  ← Current chapter (cyan border, pulsing)
│  │  Waves 16–30    │    │
│  │  ★★★★★ ★★★      │    │  ← 8/15 cleared
│  │  8 / 15 done    │    │
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ 🔒  WARRIOR     │    │  ← Locked (dark, lock icon)
│  │  Waves 31–50    │    │
│  │  Clear Wave 30  │    │  ← Unlock condition hint
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ 🔒  ELITE       │    │
│  │  Waves 51–70    │    │
│  └─────────────────┘    │
│                         │
│  [ scroll down for more ]│
└─────────────────────────┘
```

**6 Chapters:**

| Chapter | Waves | Unlock condition |
|---|---|---|
| Rookie | 1–15 | Always open |
| Contender | 16–30 | Clear Wave 15 |
| Warrior | 31–50 | Clear Wave 30 |
| Elite | 51–70 | Clear Wave 50 |
| Master | 71–90 | Clear Wave 70 |
| Legend | 91–100 | Clear Wave 90 |

**Chapter card states:**

| State | Visual |
|---|---|
| Locked | Dark overlay, 🔒 icon, unlock hint text |
| Available (not started) | Normal border, "START" label |
| In Progress | Cyan pulsing border, ▶ icon, X/Y waves done |
| Completed | Gold border, 🏆 icon, star count |

**Interactions:**
- Tap unlocked chapter → Wave Path screen for that chapter
- Tap locked chapter → nothing (subtle shake animation to indicate locked)
- Scroll vertically to see all 6 chapters

---

### 4. Wave Path Screen

Opens after tapping a chapter. Shows all waves in that chapter as a scrollable path.

```
┌─────────────────────────┐
│  ←      CONTENDER       │
│         Waves 16–30     │
│                         │
│         ★ 16            │  ← Cleared wave (gold star + number)
│        /                │
│      ★ 17               │
│        \                │
│         ★ 18  🪨         │  ← Stone bubble icon = Stone introduced
│        /                │
│      ★ 19               │
│        \                │
│         ☆ 20  ★BOSS     │  ← Current wave (hollow star, BOSS label)
│        /                │     pulsing glow
│      ○ 21               │  ← Not yet reached (empty circle)
│        \                │
│         ○ 22            │
│        /                │
│      ○ 23               │
│        \                │
│         ○ 24            │
│        /                │
│      ○ 25  💣            │  ← Bomb bubble icon = Bomb introduced here
│        \                │
│         ○ 26            │
│        /                │
│      ○ 27               │
│        \                │
│         ○ 28            │
│        /                │
│      ○ 29               │
│        \                │
│         ○ 30  👑BOSS     │  ← Boss wave indicator
│                         │
│  [ TAP A WAVE TO PLAY ] │
└─────────────────────────┘
```

**Wave node states:**

| State | Visual |
|---|---|
| Cleared | ★ Gold star |
| Current | ☆ Hollow star, pulsing cyan glow |
| Locked (future) | ○ Empty circle, greyed out |
| Sub-milestone | ★ + subtle shimmer border |
| Boss/Milestone | ★ or ☆ + 👑 crown icon + gold ring |

**Icons on wave nodes** — small badge showing what's new that wave:

| Wave | Badge |
|---|---|
| 12 | 🌈 Rainbow introduced |
| 18 | 🪨 Stone introduced |
| 20 | ✨ Multiplier introduced |
| 25 | 💣 Bomb introduced |
| 35 | 🧊 Ice introduced |
| 55 | 🔴 Chaos introduced |
| All power unlock waves | ⚡🎯🎨🛡️❄️💥🌟 relevant icon |

**Path shape:** Zigzag left-right, flows downward. Milestone waves slightly larger node. Scroll vertically.

**Interactions:**
- Tap any cleared wave → replay it (score not overwritten unless better)
- Tap current wave → goes to Cannon Power Selection (or directly to game if < Wave 8)
- Tap future locked wave → node shakes, tooltip: "Clear Wave X to unlock"
- Back arrow → Chapter Map

---

### 5. Settings Screen

Slides up as a bottom sheet — doesn't replace main menu.

```
┌─────────────────────────┐
│  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌   │  ← Drag handle
│                         │
│       SETTINGS          │
│                         │
│  Sound Effects   [ ON ] │  ← Toggle
│  Music           [OFF ] │  ← Toggle
│  Volume          ━━●━━  │  ← Slider
│                         │
│  Graphics                │
│  Quality         [HIGH] │  ← Low / High toggle
│                         │
│  Display                 │
│  Show FPS        [OFF ] │  ← Debug toggle
│                         │
│  ┌─────────────────┐    │
│  │      CLOSE      │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

- Drag down or tap CLOSE to dismiss
- Settings saved to `user://settings.cfg` immediately on change
- Graphics quality = Low forces `mobile_low_fx = true` even on desktop

---

### 4. High Scores Screen

```
┌─────────────────────────┐
│  ←                      │  ← Back button
│       HIGH SCORES       │
│                         │
│  ┌───────────────────┐  │
│  │ 🏆  Wave 100       │  │  ← Best wave reached
│  │     Score: 48,200  │  │
│  └───────────────────┘  │
│                         │
│  Personal Bests          │
│  ┌───────────────────┐  │
│  │ #1  48,200  W-100 │  │
│  │ #2  31,450  W-73  │  │
│  │ #3  28,900  W-68  │  │
│  │ #4  19,200  W-51  │  │
│  │ #5  14,800  W-44  │  │
│  └───────────────────┘  │
│                         │
│  Badges Earned           │
│  🏅 Contender  🏅 Elite  │
│                         │
└─────────────────────────┘
```

- Top 5 runs saved locally
- Badges displayed as a grid
- Locked badges shown as greyed out silhouettes

---

### 5. Cannon Power Selection Screen

Appears after every wave complete (Wave 8+). Full screen takeover.

```
┌─────────────────────────┐
│                         │
│   Wave 24 Complete! ✓   │  ← Wave number, green checkmark
│   Score: 12,450         │
│                         │
│  Choose your cannon:    │
│                         │
│  ┌───────┐ ┌───────┐ ┌───────┐ │
│  │  ⚡   │ │  🎱   │ │  ✂️   │ │  ← 3 random options
│  │ Rapid │ │Bouncy │ │Split  │ │
│  │ Fire  │ │ Mode  │ │ Shot  │ │
│  │       │ │       │ │       │ │
│  │3 shots│ │5 shots│ │1 shot │ │
│  └───────┘ └───────┘ └───────┘ │
│                         │
│      [ Skip / None ]    │  ← Always available
│                         │
│   ┌─────────────────┐   │
│   │   START WAVE 25 │   │  ← Active after selection
│   └─────────────────┘   │
└─────────────────────────┘
```

**Interactions:**
- Tap a card → it highlights, START button activates
- Tap again to deselect (goes back to Skip)
- Locked powers shown greyed out with lock icon + "Unlocks at Wave X"
- Auto-advance if no tap within 8s (Skip is selected)

---

### 6. In-Game HUD

Minimal — game canvas gets maximum space.

```
┌─────────────────────────┐
│ ┌─────────────────────┐ │
│ │ Score: 12,450  W:24 │ │  ← Score + Wave, top panel
│ │ Match 3 bubbles     │ │  ← Status message
│ └─────────────────────┘ │
│  ⏸️                      │  ← Pause button, top-right corner
│                         │
│  [ GAME GRID ]          │
│                         │
│                         │
│                         │
│  ┌──────┐ ┌──────┐ ┌──────┐  │
│  │  💥  │ │  🎨  │ │  ❄️  │  │  ← Power-up slots (3 visible)
│  │READY │ │ 3s   │ │READY │  │
│  └──────┘ └──────┘ └──────┘  │
│                         │
│      [ CANNON ]         │
│                         │
└─────────────────────────┘
```

**HUD Rules:**
- Score panel: top, semi-transparent dark background
- Pause: top-right, small icon button — no label
- Power-up slots: bottom strip, above cannon
- FPS label: hidden in release, visible only in debug mode
- Status message: 1 line max, fades out after 2.5s if not updated
- Row countdown ("Row in 3 shots"): subtle, inside status area — not a separate element

---

### 7. Pause Screen

Slides down as overlay — game frozen underneath (blurred).

```
┌─────────────────────────┐
│                         │
│   [ blurred game ]      │
│                         │
│  ┌───────────────────┐  │
│  │      PAUSED       │  │
│  │                   │  │
│  │  Wave 24          │  │
│  │  Score: 12,450    │  │
│  │                   │  │
│  │  ┌─────────────┐  │  │
│  │  │   RESUME    │  │  │  ← Primary
│  │  └─────────────┘  │  │
│  │  ┌─────────────┐  │  │
│  │  │  SETTINGS   │  │  │  ← Opens settings without leaving pause
│  │  └─────────────┘  │  │
│  │  ┌─────────────┐  │  │
│  │  │  MAIN MENU  │  │  │  ← Confirmation dialog first
│  │  └─────────────┘  │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

- Game pauses completely — no animations, no timers
- Back button (Android) = pause toggle
- Tap outside panel = resume

---

### 8. Wave Complete Screen

Brief — shown for 2s then goes to Cannon Power Selection (or next wave if < Wave 8).

```
┌─────────────────────────┐
│                         │
│         ✨ ✨ ✨          │  ← Particle burst
│                         │
│    WAVE 24 COMPLETE!    │  ← Large, animated scale-in
│                         │
│    Score:   +4,200      │
│    Bonus:   +150        │  ← Board clear bonus
│    Total:  12,450       │
│                         │
│    ⚡ Rapid Fire earned  │  ← If power-up earned this wave
│                         │
│   [ auto-advancing... ] │  ← Progress bar, 2s
│   [ TAP TO SKIP ]       │
│                         │
└─────────────────────────┘
```

---

### 9. Milestone Moment Screen

Full screen takeover at Wave 10, 20, 30, 50, 70, 90, 100. Big emotional beat.

```
┌─────────────────────────┐
│                         │
│   ✨✨✨✨✨✨✨✨✨✨        │  ← Big particle burst
│                         │
│        WAVE 50          │
│    HALFWAY LEGEND       │  ← Badge name, large
│                         │
│  ┌───────────────────┐  │
│  │    🏅 HALFWAY     │  │  ← Badge graphic, animated reveal
│  │      LEGEND       │  │
│  └───────────────────┘  │
│                         │
│   Score: 28,900         │
│   Best:  31,450  ← PR!  │  ← Personal record indicator
│                         │
│  ┌─────────────────┐    │
│  │    SHARE 📤     │    │  ← Share button — screenshot + text
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │    CONTINUE     │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

- Share button generates: screenshot of badge + "I reached Wave 50 in Bubble Shooter! 🏅"
- Auto-advance only on CONTINUE tap — no timer here

---

### 10. Game Over Screen

```
┌─────────────────────────┐
│                         │
│       GAME OVER         │  ← 30px, fade in
│                         │
│  The stack crossed      │
│  the warning line.      │  ← Loss reason message
│                         │
│  ┌───────────────────┐  │
│  │  Wave Reached: 24 │  │
│  │  Final Score:     │  │
│  │     12,450        │  │
│  │                   │  │
│  │  Best: 31,450  💔 │  │  ← Not a PR (sad indicator)
│  │  Best: 48,200  🏆 │  │  ← OR: New PR (trophy)
│  └───────────────────┘  │
│                         │
│  ┌─────────────────┐    │
│  │   PLAY AGAIN    │    │  ← Starts from Wave 1
│  └─────────────────┘    │
│  ┌─────────────────┐    │
│  │   MAIN MENU     │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

---

## Touch Interaction Guidelines

Mobile-first. Entire UI designed for **right thumb** (primary hand).

| Zone | What Lives Here |
|---|---|
| Top strip | Score, wave, status — read-only, no taps needed |
| Center | Game grid — primary play area |
| Bottom strip | Power-up slots — tap to activate |
| Bottom center | Cannon — drag to aim, tap/release to fire |

**Tap targets:** Minimum 44×44px for all interactive elements.

**Gestures:**
- Drag on game area → aim
- Release → fire (touch) OR click → fire (mouse)
- Tap power-up slot → activate
- Swipe up on power-up strip → see all available (if > 3)
- Tap pause icon → pause
- Swipe down on pause panel → resume

---

## Animation Guidelines

### Timing Tokens

Reusable durations — reference these everywhere instead of hardcoding.

| Token | Duration | Use case |
|---|---|---|
| `INSTANT` | 80ms | Button press feedback, micro-interactions |
| `FAST` | 150ms | Tooltips, small state changes |
| `NORMAL` | 220ms | Screen transitions, card reveals |
| `SLOW` | 400ms | Celebrations, badge reveals |
| `DRAMATIC` | 600ms | Milestone moments, score countups |

### Easing Curves

| Name | Curve | When to use |
|---|---|---|
| `ease-out` | Fast start, slow finish | Most UI movement — feels responsive |
| `ease-in-out` | Slow start, fast middle, slow finish | Overlay slides |
| `spring` | Overshoot + settle | Badge reveal, card selection, pop feedback |
| `linear` | Constant | Progress bars, timers only |

---

### Screen Transitions

| Transition | From → To | Animation |
|---|---|---|
| App launch | Splash → Main Menu | Bubbles float up, title fades in. Auto advance. |
| Start game | Main Menu → Cannon Select | Slide up — 220ms ease-out |
| Start game (< W8) | Main Menu → Game | Slide up — 220ms ease-out |
| Wave complete | Game → Cannon Select | Score panel expands full screen — 300ms ease-out |
| Cannon select → Game | Cannon Select → Game | Slide up — 220ms ease-out |
| Pause | Game → Pause overlay | Blur background (gaussian, 6px) + overlay slides down — 200ms ease-out |
| Resume | Pause → Game | Reverse slide up — 180ms ease-in |
| Game over | Game → Game Over | Overlay fades in — 300ms. Score counts up after 400ms delay. |
| Main Menu | Any screen → Main Menu | Slide down — 220ms ease-out |

---

### In-Game Animations

#### Bubble Pop

The most important animation — must feel deeply satisfying.

```
Frame 0:    Bubble at normal size
Frame 1-3:  Scale to 1.18 (quick squash-stretch outward)
Frame 4-6:  Scale to 0.0 + alpha fade to 0
Frame 4-8:  Particle burst (6-10 dots fly outward)
Frame 4-12: Ring ripple expands outward from center, fades
```

- Duration: 120ms total
- Easing: spring on scale (overshoot to 1.18, collapse to 0)
- Each bubble in a cluster pops with a 20ms stagger (not all at once)
- Stagger direction: outward from shooter impact point

#### Floating Bubble Fall

Bubbles that float after a cluster pop:

```
Frame 0:    Normal position
Frame 1-4:  Slight upward bounce (+8px) — "surprised" reaction
Frame 5-15: Fall down and off screen (gravity acceleration)
Frame 5-15: Alpha fades from 1.0 to 0.0
```

- Duration: 250ms
- Easing: ease-in on fall (accelerating)
- Delay: 80ms after cluster pop finishes (clear visual separation)

#### Cluster Match Cascade

When 10+ bubbles pop (chain bonus):

- All bubbles flash white simultaneously before popping
- Flash duration: 60ms
- Then normal staggered pop animation
- Screen micro-shake: ±3px, 80ms, 2 oscillations

#### New Row Drop (stack animation)

```
Frame 0:    New row appears at top (alpha 0, slightly above position)
Frame 1-5:  Row slides down into position + alpha 1.0 — 150ms ease-out
Frame 0-8:  Existing board bounces down slightly (spring: -12px → settle)
             Spring: strength 54 (mobile) / 38 (desktop), damping 13.5 / 10.5
```

- Row flash: top row glows cyan briefly (row_arrival_flash = 0.34)
- Flash decay: 2.2× per second

#### Bubble Land (no match)

```
Frame 0:    Bubble snaps to grid position
Frame 1-3:  Scale 1.0 → 1.12 → 1.0 (quick bounce)
Frame 1-4:  Neighbor bubbles nudge outward 4px → return (ripple)
```

- Duration: 140ms
- Communicates "placed but not matched"

#### Flying Bubble Trail

Already implemented — document exact values for consistency:

- Trail length: `bubble_radius × (1.6 + launch_burst × 4.2)`
- Trail alpha: `0.16 + launch_burst × 0.32`
- Smear count: 3 (mobile) / 4 (desktop)
- Launch burst decays: `exp(-launch_age × 8.5)`

#### Cannon Fire

```
Frame 0:     Fire input received
Frame 0-80ms: Launcher recoil — cannon moves back along aim axis by bubble_radius × 0.22
Frame 0-80ms: Flash glow expands around cannon (launcher_flash = 1.0, decays at 7.2×/s)
Frame 0-140ms: Recoil recovers (launcher_recoil decays at 8.8×/s)
```

#### Wall Bounce Spark

```
At bounce point:
- 1 spark particle fires perpendicular to wall
- Velocity: 110 px/s away from wall
- Life: 0.16s
- Size: bubble_radius × 0.16
```

---

### Power-Up Animations

#### Power-Up Earned

```
Frame 0:     Slot was empty/cooldown
Frame 0-80ms: Slot border flashes white
Frame 80-280ms: Gold glow pulses inward (3 pulses)
Frame 280-400ms: Icon scales 0.8 → 1.0 with spring overshoot
```

#### Power-Up Activated

```
Frame 0:     Player taps slot
Frame 0-80ms: Slot scales 0.92 → 1.0 (press feedback)
Frame 0-200ms: Ripple expands from slot outward across HUD strip
Frame 200ms+: Slot enters "active" state — continuous glow pulse
```

#### Power-Up Expired

```
Final shot of duration:
- Slot flashes 3× rapidly (40ms interval)
- Then slot fades to empty state — 200ms fade
```

---

### Score Animations

#### Score Popup (floating text)

Every pop spawns a floating "+N" text at bubble position:

```
Frame 0:    Text appears at bubble center, scale 0 → 1.2 → 1.0 (spring, 200ms)
Frame 0-800ms: Text floats upward 40px
Frame 400-800ms: Alpha fades 1.0 → 0.0
```

- Text color: warm gold `#FFE9B5`
- Big pops (200+): larger text, faster spring, brighter color
- Multiplier indicator: separate "+BONUS ×2" text in accent gold

#### HUD Score Counter

- Score in HUD does NOT jump instantly — counts up
- Count rate: 500 points per second
- If new score arrives before count finishes: accelerates to catch up
- Easing: linear (score counting should feel mechanical/satisfying)

#### Wave Complete Score Breakdown

```
Sequence (auto-plays, each line appears after previous):
1. "Wave X Complete!" — scale in, 300ms spring
2. Base score line — count up, 400ms
3. Bonus line (if any) — count up, 200ms
4. "Total:" line — count up, 300ms, larger text
5. Power-up earned badge (if any) — slide in from right, 250ms
6. Progress bar fills to 100% — 600ms linear
```

---

### Milestone Moment Animations

For waves 10, 20, 30, 50, 70, 90, 100:

```
1. Game complete flash: screen flashes white, 80ms
2. Screen transitions to Milestone screen: 300ms ease-out
3. Particles burst from center: 40-80 particles, radial, 1.2s life
4. Wave number appears: scale 0 → 1.3 → 1.0, 400ms spring
5. Badge graphic: revealed with circular wipe animation, 500ms
6. Badge name: letter-by-letter typewriter effect, 600ms
7. Score line: count up, 400ms
8. Share + Continue buttons: slide up from bottom, 300ms ease-out, 200ms stagger
```

For Wave 100 only — additional:
- Board spells "100" → each bubble pops in sequence spelling out the number
- Pop sequence delay: 30ms per bubble
- Fireworks particles (extra burst) at end of sequence

---

### Error / Feedback Animations

| Event | Animation |
|---|---|
| Invalid aim (too low) | Aim guide flashes red, 200ms |
| Ice debuff applied | Screen edge vignette blue flash, 300ms fade |
| Stack near lose line | Lose line pulses red, frequency increases as stack gets closer |
| Game over | Screen desaturates to grayscale, 400ms ease-in |
| New PR (personal record) | Gold trophy bounces in on game over screen, 500ms spring |

---

## What Needs to Be Built

| Screen | Exists Now | Needs |
|---|---|---|
| Splash | No | New scene |
| Main Menu | No | New scene |
| Settings | No | New scene (bottom sheet) |
| High Scores | No | New scene + persistence |
| Cannon Power Selection | No | New scene |
| In-Game HUD | Partial | Redesign — add power-up slots, pause button |
| Pause Screen | No | New overlay |
| Wave Complete | No | New overlay |
| Milestone Moment | No | New overlay |
| Game Over | Partial | Redesign — add score breakdown, share |
