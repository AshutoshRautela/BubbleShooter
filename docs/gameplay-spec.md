# Gameplay Spec

Exact deterministic rules for all game mechanics. This is the engineering handoff document — every ambiguity resolved here. When in doubt, this doc wins over GDD or level-design.

---

## 1. Resolution Order

When a bubble lands, the following steps execute **in strict order**. No step starts before the previous completes.

```
1. Place bubble on grid at snap_cell
2. Evaluate Bomb trigger (if placed bubble is Bomb OR adjacent to Bomb)
3. Evaluate cluster match (flood-fill from snap_cell)
4. If cluster size >= 3:
     a. Remove cluster from grid
     b. Run floating bubble detection (BFS from top row)
     c. Remove floating bubbles
     d. Compact grid (trim empty trailing rows)
     e. Calculate score
5. Check board-cleared condition (if grid empty → wave complete, skip steps 6–7)
6. ~~Decrement shots_until_shift~~ *(currently disabled — shift counter is not called from the game loop)*
     ~~a. If shots_until_shift <= 0: push new row from ceiling, reset counter~~
7. Check loss condition
8. Advance shot queue (next_color → current_color, generate new next_color)
```

---

## 2. Bubble Interaction Matrix

Rows = shooter bubble type. Columns = what it hits/joins.

| Shooter \ Board | Normal | Rainbow | Stone | Multiplier | Bomb | Ice | Chaos |
|---|---|---|---|---|---|---|---|
| **Normal** | Match if same color | Rainbow joins cluster | No effect (sits next to it) | Normal match, ×2 score if Multiplier in cluster | Triggers Bomb | **Debuff if direct hit** | Chaos counts as its current color at impact moment |
| **Rainbow** | Joins nearest 3+ cluster of any color | Joins any cluster | No effect | Match + ×2 if Multiplier in cluster | Triggers Bomb | No debuff | Joins Chaos as its current color |
| **Stone** | Cannot be fired — only on board | — | — | — | — | — | — |
| **Multiplier** | Match if same color, ×2 score | Joins any cluster, ×2 | No effect | Two Multipliers = ×4 | Triggers Bomb | Debuff if direct hit | Chaos = current color |
| **Bomb** | Blast hex radius 2 (all cells within 2 hex steps), ignores color | Destroyed in blast | **Destroyed in blast** | Destroyed in blast | Chain explosion | Destroyed in blast | Destroyed in blast |
| **Ice** | Cannot be fired — only on board | — | — | — | — | — | — |
| **Chaos** | Match if color matches at impact | Joins any cluster | No effect | ×2 if in cluster | Triggers Bomb | Debuff if direct hit | Both count as current colors at impact |

---

## 3. Bubble Type Exact Rules

### 3.1 Rainbow Bubble

**Exact cluster-join rule:**
1. On placement, scan all 6 hex neighbors
2. For each neighbor that is occupied, collect its color
3. From all colors found, pick the one with the **largest connected cluster size** (BFS each)
4. Rainbow joins that cluster as if it were that color
5. Tie-break: pick the color with the **lowest color index** (consistent determinism)
6. If no neighbors are occupied: Rainbow sits on board as a neutral bubble. It can be matched by ANY color cluster that expands adjacent to it in future shots — it joins whichever cluster reaches it first

**Rainbow + Multiplier in same cluster:** Both effects apply. Score = cluster_score × 1.5 (Rainbow) × 2 (Multiplier) = × 3.0 total.

---

### 3.2 Stone Bubble

**Exact removal rule:**
- Stone has no color value (-2 in grid, distinct from EMPTY_CELL = -1)
- Stone is never included in flood-fill cluster checks
- Stone is never matched
- After every cluster pop + floating removal pass, run a second check:
  - For each Stone cell: if ALL 6 hex neighbors are either EMPTY or out-of-bounds → Stone is floating → remove it
  - This check runs **after** normal floating removal, not during
- Bomb blast: Stone IS removed by Bomb (only exception to its immunity)

**Edge case — Stone at top row:**
- Stone at row 0 with no neighbors → still attached (top row = always attached, same as normal bubbles)
- Stone at row 0 cannot fall unless Bombed

---

### 3.3 Bomb Bubble

**Exact blast radius:**
Hexagonal radius of 2 cells (all cells within 2 hex steps from Bomb's cell).

For a Bomb at position (r, c), cells destroyed = all (row, col) where `hex_distance(r, c, row, col) <= 2`.

Hex distance formula (offset grid with row parity):
```
cube_x = col - (row - (row & 1)) / 2
cube_z = row
cube_y = -cube_x - cube_z
# same for target
hex_dist = max(abs(ax - bx), abs(ay - by), abs(az - bz))
```

**Blast triggers when:**
- A Bomb bubble is placed on the grid (after placement, before cluster check)
- A Bomb bubble is included in a cluster pop (detonates during removal)
- A Bomb bubble is hit by another Bomb's blast (chain explosion)

**Blast order for chains:**
- All Bombs detonate simultaneously in the same resolution step
- Collect all Bombs in blast radius first, then all blast simultaneously
- No infinite recursion risk — each Bomb detonates at most once per resolution

**Bomb + cluster match:** If shooter matches 3+ Bombs → cluster removal triggers each Bomb's blast. All blasts resolve simultaneously.

---

### 3.4 Ice Bubble

**Exact debuff trigger:**
- Debuff triggers ONLY when the shooter bubble's final position is within `bubble_diameter` distance of an Ice bubble center AND no cluster match occurred
- If a cluster match removes the Ice bubble → no debuff (it was safely cleared)
- Debuff does NOT trigger from floating removal of Ice bubble

**Debuff effect — exact values:**
- Duration: next 2 shots
- Aim angle noise: ± 0.05 radians added to `clamped_aim_direction()` output (random each shot)
- Shot speed multiplier: × 0.80 (20% slower)
- Visual: aim guide line renders with a slight shake animation

**Debuff stacking:**
- Hitting a second Ice bubble while debuffed: resets duration to 2 shots (does not stack to 4)
- One active debuff at a time

---

### 3.5 Chaos Bubble

**Exact color cycle:**
- Each Chaos bubble has its own independent timer, initialized at spawn with a random offset `[0, 1.5)`
- Color cycle period: 1.5 seconds per color
- Colors cycle through exactly 3 colors, sampled randomly from current palette at spawn time — fixed for that bubble's lifetime
- Color at impact = color active at the exact moment the shooter bubble's position overlaps the Chaos bubble center (within `bubble_radius` distance)

**Chaos + cluster evaluation:**
- After color is locked at impact, Chaos behaves identically to a Normal bubble of that color
- If locked color forms a 3+ cluster → normal pop
- If not → sits on board as that color permanently (stops cycling)

**+50 timing bonus rule:**
- Bonus awarded if: player's aimed snap_cell contains a Chaos bubble AND the Chaos bubble's current color matches the shooter bubble's color at fire time
- "At fire time" = when `fire_bubble()` is called, not when it lands
- Bonus is informational only — shown as floating text "+50 TIMED!" — added to score normally

---

### 3.6 Multiplier Bubble

**Score calculation order:**
```
base_score = cluster_size × 20 + floating_count × 25
multiplier_count = number of Multiplier bubbles in cluster
final_score = base_score × (2 ^ multiplier_count)
```

Examples:
- 1 Multiplier in cluster: × 2
- 2 Multipliers: × 4
- 3 Multipliers: × 8

**Multiplier + Rainbow:**
- Rainbow ×1.5 applies AFTER Multiplier doubling
- `final_score = base_score × (2 ^ multiplier_count) × 1.5`
- Result is floor'd to integer

---

## 4. Power-Up Interaction Rules

### 4.1 Board Power-Up Stacking

Only one board power-up can be active at a time. If a second is earned while one is active:
- Aim Assist Pro: extends duration (adds 5 more shots)
- All others: queued — activates immediately when current expires

### 4.2 Color Switch + Special Bubbles

- Color Switch cannot produce Stone, Ice, or Chaos bubbles — only Normal colors currently on board
- Color Switch CAN produce Rainbow if Rainbow is currently on the board
- Color Switch cannot produce Bomb via this power-up (Bomb is only via Color Bomb cannon power)

### 4.3 Wildcard Rain + Multiplier

- If Wildcard Rain is active (3 Rainbow shots) and a Rainbow bubble pops a Multiplier:
  - Rainbow ×1.5 AND Multiplier ×2 both apply
  - Total multiplier: × 3.0

### 4.4 Row Shield Timing

- Shield is consumed the moment `shots_until_shift` would reach 0
- `shots_until_shift` is NOT decremented that shot — it stays at 1
- Next shot decrements normally (no free extra shot — shield just blocks the push)

### 4.5 Freeze + Row Push Already Pending

- If Freeze is activated when `shots_until_shift` is already 0 (push is overdue):
  - The pending push executes immediately before Freeze activates
  - Freeze then holds the counter for 5 shots
  - This prevents Freeze from skipping an already-triggered push

---

## 5. Cannon Power Rules

### 5.1 Rapid Fire

- Aim direction locks at first shot
- Second and third shots fire from same locked direction automatically after 0.3s each
- Player can adjust aim between shots by dragging — lock updates if drag detected
- If board is cleared mid-burst: burst stops, wave complete triggers

### 5.2 Guided Shot

- Steering input: horizontal drag/mouse movement after fire
- Steering range: ± 25° from original direction (hard clamp)
- Steering rate: 60°/second maximum (smooth, not instant snap)
- Wall bounce physics apply to the steered path in real-time
- Guidance window: from fire until bubble travels 60% of total path — last 40% is unguided

### 5.3 Split Shot

- Split occurs at exactly 50% of total path length
- Left split: original direction rotated −22°
- Right split: original direction rotated +22°
- Each split bubble is an independent full-size bubble (same color as original)
- Each split runs full resolution independently — two separate resolve calls
- Resolution order: left split resolves fully first, then right split
- If left split clears the board: right split is cancelled

### 5.4 Charged Shot

**Charge levels — exact thresholds:**

| Hold Duration | Level | Speed Multiplier | Blast Radius |
|---|---|---|---|
| 0–0.4s (tap) | None | 1.0× | None |
| 0.4–0.9s | Half | 1.8× | None |
| 0.9–1.5s | Full | 3.0× | 2-cell hex radius |

- Full charge blast = same rules as Bomb bubble blast EXCEPT: does not chain-trigger other Bombs
- Charge is lost if player releases during aiming without firing — must re-hold
- Visual: cannon glows progressively brighter, full charge triggers a distinct pulse + sound

### 5.5 Bouncy Mode

- Max bounces increased from 2 to 4
- Aim guide extends to show all 4 bounce points
- Each bounce: `x velocity = -x velocity` (same as current)
- If bubble reaches max bounce count without hitting stack or ceiling: treated as miss, `shots_until_shift` decrements

---

## 6. Scoring — Full Order of Operations

```
1. Base cluster score     = cluster_size × 20
2. Floating score         = floating_count × 25
3. Stone fall score       = stone_fall_count × 40
4. Subtotal               = (1) + (2) + (3)
5. Multiplier bubble ×    = subtotal × (2 ^ multiplier_count_in_cluster)
6. Rainbow ×              = result × 1.5  (only if Rainbow in cluster)
7. Chain bonus ×          = result × 1.5  (only if total_removed >= 10)
8. Milestone wave bonus × = result × wave_multiplier (2× / 3× / 4× / 5×)
9. Chaos timing bonus +   = +50 flat (added after all multipliers)
10. Final score           = floor(result of step 8) + step 9
```

**No match shot:**
- `score += 5` flat — no multipliers apply

---

## 7. Loss Condition — Exact Check

Loss is evaluated AFTER full resolution (after floating removal, after row push if triggered).

```
for each occupied cell (row, col) in grid:
    world_y = board_top + bubble_radius + row × row_height
    # NOTE: uses logic world position — NOT visual offset
    if world_y + bubble_radius >= lose_line_y:
        trigger game over
```

`stack_visual_offset` is intentionally excluded — visual animation does not affect loss detection.

---

## 8. Wave Progression — Exact Logic

```
on bubble placed:
  run resolution (steps 1–8 from Resolution Order above)

  if board is empty after resolution:
    score += 150
    wave += 1
    shots_until_shift = shots_per_shift_for_wave(wave)
    spawn new wave board
    → Wave Complete screen

  else:
    # Shift mechanic (currently disabled — try_push_shift_row is not called from game loop)
    # shots_until_shift -= 1
    # if shots_until_shift <= 0:
    #   push_row_from_ceiling()
    #   shots_until_shift = shots_per_shift_for_wave(wave)
    #
    # Baseline refill: if grid.size() < initial_visible_rows(),
    # reserve rows are inserted at position 0 (ceiling) to maintain minimum board.
    pass
```

**`shots_per_shift_for_wave(wave)` lookup** *(for future re-enablement)*:

| Wave Range | Shots/Shift |
|---|---|
| 1–24 | 5 |
| 25–44 | 4 |
| 45–64 | 3 |
| 65–100 | 2 |

---

## 9. Per-Wave Data Format (for `wave_config.gd`)

Each wave entry is a Dictionary:

```gdscript
{
  "wave": int,              # wave number 1–100
  "colors": int,            # palette size (4–6)
  "shots_per_shift": int,   # 2–5
  "start_rows": int,        # 6–10
  "board_density": float,   # 0.78–1.0 (% cells filled)
  "push_density": float,    # 0.88–1.0 (% cells in pushed row)
  "board_type": String,     # "random" | "checkerboard" | "stripes" | "pyramid" |
                            #  "mirror" | "fortress" | "spiral" | "cascade" |
                            #  "mono_wall" | "color_drought" | "color_blocks" |
                            #  "chessboard" | "chaos_flood" | "stone_maze" | "legend_100"
  "score_multiplier": float, # 1.0 default, 2.0/3.0/4.0/5.0 on milestones
  "badge": String,           # "" or badge name for milestone waves
  "cannon_power_pool": Array[String], # which powers can appear in selection screen
                                      # empty = all unlocked powers
}
```

---

## 10. Floating Bubble Detection — Exact Algorithm

```
1. Build attached set:
   - Start with all cells in row 0 that are occupied
   - BFS outward through hex neighbors
   - A cell is attached if reachable from any row-0 cell

2. Any occupied cell NOT in attached set = floating

3. Remove all floating cells simultaneously

4. compact_grid() — trim empty trailing rows

5. Return list of removed cells (for scoring + visual effects)
```

**Stone bubbles in floating check:**
- Stone bubbles ARE included in BFS traversal (they can support other bubbles)
- Stone bubbles CAN become floating and fall (if detached from top row)
- Exception: Stone at row 0 is always attached

---

## 11. Edge Cases

| Situation | Behavior |
|---|---|
| Shooter bubble placed outside grid bounds | Snap to nearest valid cell — never goes out of bounds |
| Two bubbles placed in same cell (race condition) | Impossible — `STATE_FLYING` prevents firing while bubble is in flight |
| Entire top row filled, new bubble hits ceiling | Snaps to row 0, first empty column nearest impact point |
| Board completely empty when row push triggers | Push generates a new row with current wave's palette — game continues |
| Bomb blast destroys all bubbles | Board-cleared condition triggers after blast resolution |
| Rainbow with no neighbors and no future matches | Sits permanently until game over — does not affect loss condition by itself |
| Chaos bubble color cycles to same color 3 times | Allowed — random selection can repeat colors |
| Multiple power-ups earned in same shot | All are awarded — queued if needed per stacking rules |
| Wave 100 complete — what happens? | "LEGEND" screen shown. No Wave 101. Game enters "Legacy Mode" — endless procedural waves with Wave 100 parameters and a Legacy score suffix |
