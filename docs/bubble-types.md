# Bubble Types

7 bubble types total. Each type is introduced at a specific wave to control complexity ramp.

---

## Summary Table

| Bubble | Symbol | Introduced | Spawn Rate (late) | Can Stone block? |
|---|---|---|---|---|
| Normal | — | Wave 1 | 74% | No |
| Rainbow | 🌈 | Wave 12 | 5% | No |
| Stone | 🪨 | Wave 18 | 6% | — |
| Multiplier | ✨ | Wave 20 | 5% | No |
| Bomb | 💣 | Wave 25 | 4% | Yes |
| Ice | 🧊 | Wave 35 | 3% | No |
| Chaos | 🔴 | Wave 55 | 3% | No |

---

## Spawn Rates by Phase

| Bubble | Wave 1–17 | Wave 18–34 | Wave 35–54 | Wave 55–100 |
|---|---|---|---|---|
| Normal | 100% | 90% | 82% | 74% |
| Rainbow | 0% | 4% | 5% | 5% |
| Stone | 0% | 4% | 5% | 6% |
| Multiplier | 0% | 2% | 4% | 5% |
| Bomb | 0% | 0% | 2% | 4% |
| Ice | 0% | 0% | 2% | 3% |
| Chaos | 0% | 0% | 0% | 3% |

---

## Detailed Mechanics

---

### 1. Normal Bubble

**Appearance:** Solid color circle (6 colors: red, yellow, teal, blue, purple, green)
**Mechanic:** Match 3+ same-color connected bubbles to pop.
**Introduced:** Wave 1

---

### 2. Rainbow Bubble 🌈

**Appearance:** Cycling hue-rotation glow — animated color shift every frame
**Mechanic:**
- Acts as a wildcard — matches any color cluster
- When placed, joins the nearest 3+ same-color cluster regardless of its own color
- If no cluster of 3+ exists nearby, sits on board as a neutral bubble (can be matched later by any color cluster that reaches it)

**Introduced:** Wave 12 (4% spawn rate)
**Scoring:** Cluster score × 1.5 when Rainbow is part of the pop
**Design note:** Should feel like a gift — visual feedback must be extra juicy when it triggers

---

### 3. Stone Bubble 🪨

**Appearance:** Dark grey circle with white crack lines drawn procedurally
**Mechanic:**
- Cannot be matched or directly popped
- Removed only when ALL its neighbors are cleared (becomes floating → falls)
- Counts as an obstacle — blocks cluster connections through it

**Introduced:** Wave 18 (4% spawn rate)
**Scoring:** +40 points when it falls via floating removal
**Design note:** Placement should feel deliberate in hand-crafted boards — used to create walls and force routing

---

### 4. Multiplier Bubble ✨

**Appearance:** Gold/amber bubble with animated star shimmer
**Mechanic:**
- When included in a popped cluster, the entire shot score is ×2
- No bonus if removed via floating (must be part of an active match)
- Multiple Multiplier bubbles in one cluster: score ×2 per Multiplier (×4 for 2, ×8 for 3 — rare but possible)

**Introduced:** Wave 20 (2% spawn rate, grows to 5%)
**Scoring:** Current shot score ×2 (stacks)
**Design note:** Player should actively aim for these — placement in milestone boards should be at strategic chain reaction trigger points

---

### 5. Bomb Bubble 💣

**Appearance:** Dark red/black bubble with slow red pulse glow
**Mechanic:**
- When popped (via match OR directly adjacent to another pop), triggers a blast
- Blast destroys all bubbles within hex radius 2 (all cells within 2 hex steps from Bomb's cell) — ignores color
- Stone bubbles ARE destroyed by bomb blast
- Bomb can chain-trigger other nearby Bombs

**Introduced:** Wave 25 (2% board spawn rate)
**Scoring:** +30 per bubble destroyed in blast (separate from cluster score)
**Design note:** Chain bomb explosions should have extra particle effects — this is a high-dopamine moment

---

### 6. Ice Bubble 🧊

**Appearance:** Light blue frosted circle with slow pulse, white frost flecks
**Mechanic:**
- If shooter bubble directly hits an Ice bubble without matching it (glancing shot), a debuff triggers:
  - Next 2 shots: aim guide shakes slightly (small random angle offset ±3°)
  - Shot speed reduced by 20%
- Safely removed only by:
  - Floating removal — all 6 neighbors cleared, Ice becomes detached and falls
  - Bomb blast

**Clarification:** Ice bubbles have no color — they cannot be matched directly. Must be isolated and fall, or bombed.

**Introduced:** Wave 35 (2% spawn rate)
**Scoring:** +35 when removed
**Design note:** Teaches players to be more precise — rushing leads to debuffs

---

### 7. Chaos Bubble 🔴

**Appearance:** Rapidly flickering between 3 random available colors — visible color change every 1.5s
**Mechanic:**
- Acts as a normal bubble of whatever color it shows at the moment of a match evaluation
- If a cluster match is triggered at tick boundary (color just changed), the NEW color applies
- Player must time their shot to align with desired color window
- Timing window: 1.5s per color cycle — color is visible, no hidden RNG

**Introduced:** Wave 55 (3% spawn rate)
**Scoring:** +50 bonus if player matches it on the intended color (tracked by aim + timing), normal score otherwise
**Design note:** High skill expression — experienced players will wait for the right moment. Should have an audible tick sound on color change.

---

## Visual Rendering Notes (for `_draw()` implementation)

| Bubble | Render Approach |
|---|---|
| Normal | Existing `draw_bubble()` — no change |
| Rainbow | Hue-rotated color per frame using `Color.from_hsv()`, glow layer |
| Stone | Dark grey base + white line cracks using `draw_line()` |
| Multiplier | Gold base + `draw_arc()` star points + shimmer particle per frame |
| Bomb | Dark red base + pulsing outer glow scaled with `sin(visual_time)` |
| Ice | Light blue + white semi-transparent overlay + frost dots |
| Chaos | Color sampled from 3 random palette colors, switches on timer |
