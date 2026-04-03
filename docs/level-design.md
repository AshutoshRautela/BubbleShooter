# Level Design

100 waves across 6 phases. Difficulty scales across 5 parameters — no single spike, gradual ramp with intentional breathing room after every milestone.

---

## Design Philosophy

> Har 10 waves ek "chapter" hai. Chapter ke andar tension badhti hai, chapter end pe ek satisfying release moment aata hai. Player ko lagta rahe — *"ek aur wave."*

**Three types of waves:**
- **Normal waves** — procedurally generated, parameters from table below
- **Sub-milestone waves** (every 5) — semi-handcrafted pattern, slight score bonus
- **Milestone / Boss waves** (every 10) — fully handcrafted board, score multiplier, badge at major points

---

## Difficulty Parameters

| Parameter | Wave 1 | Wave 25 | Wave 50 | Wave 75 | Wave 100 |
|---|---|---|---|---|---|
| Colors | 4 | 5 | 6 | 6 | 6 |
| Shots/Shift | 5 | 5 | 4 | 3 | 2 |
| Start Rows | 6 | 7 | 8 | 9 | 10 |
| Board Density | 78% | 88% | 93% | 97% | 100% |
| Row Push Density | 88% | 92% | 96% | 99% | 100% |

---

## Shots Per Shift Progression

| Waves | Shots/Shift |
|---|---|
| 1–24 | 5 |
| 25–44 | 4 |
| 45–64 | 3 |
| 65–100 | 2 |

---

## Color Palette Progression

| Waves | Colors Available |
|---|---|
| 1–10 | 4 |
| 11–24 | 5 |
| 25–100 | 6 |

---

## Phases

---

### Phase 1 — "Rookie" (Waves 1–15)

**Goal:** Player learns controls, earns first wins, baseline dopamine established.
**New unlocks:** Aim Assist Pro (W5), Color Switch (W10), Rainbow bubble (W12)

| Wave | Colors | Shots/Shift | Rows | Density | Type |
|---|---|---|---|---|---|
| 1 | 4 | 5 | 6 | 78% | Tutorial-feel — sparse, big same-color clusters |
| 2–4 | 4 | 5 | 6 | 80% | Normal |
| **5** | 4 | 5 | 6 | 80% | **Sub-milestone** — Checkerboard pattern |
| 6–9 | 4 | 5 | 6 | 83% | Normal |
| **10** | 4 | 5 | 7 | 85% | **Milestone** — Pyramid board |
| 11–11 | 5 | 5 | 7 | 87% | 5th color enters |
| 12–14 | 5 | 5 | 7 | 88% | Rainbow bubbles start appearing |
| **15** | 5 | 5 | 7 | 90% | **Sub-milestone** — Stripe board |

**Wave 5 — Checkerboard**
Alternating 2-color blocks across the full board. Pop one cluster → 3-4 others become floating. Player's first big cascade moment.

**Wave 10 — Pyramid**
Dense cluster at the top tapering down. Clearing the tip causes a cascade. Reward: 2× board clear bonus. Aim Assist Pro and Color Switch both available here.

---

### Phase 2 — "Contender" (Waves 16–30)

**Goal:** Real challenge begins. Stone bubbles, Multiplier bubbles, and 6th color all enter.
**New unlocks:** Row Shield (W18), Stone bubble (W18), Multiplier bubble (W20), Bomb bubble (W25), Color Bomb (W30)

| Wave | Colors | Shots/Shift | Rows | Density | Type |
|---|---|---|---|---|---|
| 16–17 | 5 | 5 | 7 | 90% | Normal |
| **18** | 5 | 5 | 8 | 91% | Stone bubble enters. Row Shield unlocks. |
| 19 | 5 | 5 | 8 | 92% | Normal |
| **20** | 5 | 5 | 8 | 92% | **Milestone** — Multiplier bubble enters. Stripe board variant. |
| **25** | 6 | 4 | 8 | 93% | **Sub-milestone** — Bomb bubble enters. Shots/shift drops to 4. |
| 21–24 | 6 | 5 | 8 | 93% | 6th color enters |
| 26–29 | 6 | 4 | 8 | 94% | Dense |
| **30** | 6 | 4 | 8 | 95% | **BOSS WAVE** — Mirror board |

**Wave 20 — Stripe + Multiplier intro**
Horizontal color bands. Multiplier bubbles placed at chain reaction trigger points. Reward: 2× bonus.

**Wave 25 — Bomb intro**
Bomb bubbles appear. Board has a dense center — bomb placement is the intended solve.

**Wave 30 — First Boss (Mirror)**
Left-right symmetric board. 9 rows. Stone bubbles on the vertical axis as obstacles. Reward: 2× bonus + "Contender" badge. Color Bomb unlocks.

---

### Phase 3 — "Warrior" (Waves 31–50)

**Goal:** Player needs strategy, not just reflexes. Ice bubbles add a new penalty layer.
**New unlocks:** Ice bubble (W35), Freeze (W35), Wildcard Rain (W45)

| Wave | Colors | Shots/Shift | Rows | Density | Type |
|---|---|---|---|---|---|
| 31–34 | 6 | 4 | 8 | 94% | Normal + new bubble mix |
| **35** | 6 | 4 | 9 | 95% | **Sub-milestone** — Ice bubble enters. Freeze unlocks. |
| 36–39 | 6 | 4 | 9 | 95% | 9 rows begin |
| **40** | 6 | 4 | 9 | 96% | **Milestone** — Fortress board |
| 41–44 | 6 | 3 | 9 | 96% | Shots/shift drops to 3 |
| **45** | 6 | 3 | 9 | 97% | **Sub-milestone** — Wildcard Rain unlocks. Cascade board. |
| 46–49 | 6 | 3 | 9 | 97% | All bubble types active |
| **50** | 6 | 3 | 9 | 98% | **HALFWAY BOSS** — Spiral board |

**Wave 40 — Fortress**
Dense center mass of bubbles surrounded by a ring of Stone bubbles. Player must shoot through gaps or isolate Stone bubbles first. Reward: 2× bonus.

**Wave 45 — Cascade**
Board designed so one good center shot causes a chain cascade of 15+ floating bubbles. Wildcard Rain — newly unlocked — trivializes it if used. Intentional relief wave.

**Wave 50 — Halfway Boss (Spiral)**
10-row spiral color layout — same color follows a spiral path from outside in. Reward: **3× bonus** + "Halfway Legend" badge. This is the emotional midpoint — must feel huge.

---

### Phase 4 — "Elite" (Waves 51–70)

**Goal:** Only skilled players reach here. Chaos bubbles test timing mastery.
**New unlocks:** Chaos bubble (W55). All power-ups now available.

| Wave | Colors | Shots/Shift | Rows | Density | Type |
|---|---|---|---|---|---|
| 51–54 | 6 | 3 | 9 | 97% | All elements active |
| **55** | 6 | 3 | 10 | 97% | **Sub-milestone** — Chaos bubble enters. 10 rows begin. |
| 56–59 | 6 | 3 | 10 | 98% | Near-solid |
| **60** | 6 | 3 | 10 | 98% | **Milestone** — Color Drought board |
| 61–64 | 6 | 3 | 10 | 98% | High density |
| **65** | 6 | 2 | 10 | 98% | **Sub-milestone** — Shots/shift drops to 2. Mono Wall board. |
| 66–69 | 6 | 2 | 10 | 99% | Maximum pressure |
| **70** | 6 | 2 | 10 | 99% | **BOSS WAVE** — Color Block board |

**Wave 60 — Color Drought**
6 colors present but extremely uneven distribution — 60% board is one color, rest are singletons. Hard to match because isolated bubbles everywhere. Reward: 3× bonus.

**Wave 65 — Mono Wall**
Top 3 rows are all one color. Pop the top layer → massive floating cascade underneath. shots/shift = 2 makes it tense. New "2-shot" pressure reality check.

**Wave 70 — Color Block Boss**
Board divided into 3×3 same-color blocks — compact, no floating easy wins. Reward: 3× bonus + "Elite" badge.

---

### Phase 5 — "Master" (Waves 71–90)

**Goal:** Every shot matters. Power-ups become critical survival tools.

| Wave | Colors | Shots/Shift | Rows | Density | Type |
|---|---|---|---|---|---|
| 71–74 | 6 | 2 | 10 | 98% | Dense random + heavy special bubbles |
| **75** | 6 | 2 | 10 | 99% | **Sub-milestone** — Chessboard. 3× bonus. |
| 76–79 | 6 | 2 | 10 | 99% | Solid + all bubble types |
| **80** | 6 | 2 | 10 | 99% | **Milestone** — Chaos Flood board |
| 81–84 | 6 | 2 | 10 | 100% | 100% density begins |
| **85** | 6 | 2 | 10 | 100% | **Sub-milestone** — Alternating band board |
| 86–89 | 6 | 2 | 10 | 100% | Solid + Ice + Stone heavy |
| **90** | 6 | 2 | 10 | 100% | **BOSS WAVE** — Stone Fortress |

**Wave 75 — Chessboard**
6-color chessboard alternation. Every bubble is surrounded by different colors — very hard to find cluster entry points. Reward: 3× bonus.

**Wave 80 — Chaos Flood**
30% of board is Chaos bubbles. Player must time shots around multiple cycling colors simultaneously. Reward: 3× bonus.

**Wave 90 — Stone Fortress Boss**
Stone bubbles form walls dividing the board into sections. Each section has a different color. Player must isolate Stone walls section by section. Hardest handcrafted board to this point. Reward: **4× bonus** + "Master" badge.

---

### Phase 6 — "Legend" (Waves 91–100)

**Goal:** Hall of fame. Visual spectacle on Wave 100 must be screenshot-worthy.

| Wave | Colors | Shots/Shift | Rows | Density | Type |
|---|---|---|---|---|---|
| 91–93 | 6 | 2 | 10 | 100% | Maximum everything, puzzle-like |
| 94 | 6 | 2 | 10 | 100% | Chaos Flood extreme (40% chaos) |
| **95** | 6 | 2 | 10 | 100% | **Sub-milestone** — All bubble types equal spawn |
| 96–97 | 6 | 2 | 10 | 100% | Handcrafted puzzle |
| 98 | 6 | 2 | 10 | 100% | Stone Maze — Stone walls form a maze |
| 99 | 6 | 2 | 10 | 100% | Highest random difficulty |
| **100** | 6 | 2 | 10 | 100% | **THE LEGEND WAVE** |

**Wave 95 — All Types Equal**
All 7 bubble types spawn at roughly equal rates. Pure chaos — tests mastery of every mechanic. Reward: 4× bonus.

**Wave 98 — Stone Maze**
Stone bubbles arranged as a maze. Only narrow color-cluster paths to exploit. Possibly the hardest non-milestone board.

**Wave 100 — The Legend Wave**
Board spells "100" using color blocks. Stone bubbles outline the numbers. Multiplier bubbles placed at each digit's key pop point. Clearing it causes a massive cascade. Reward: **5× bonus** + "LEGEND" permanent badge + share prompt.

---

## Milestone Summary

| Wave | Name | Pattern | Bonus | Badge |
|---|---|---|---|---|
| 5 | First Rush | Checkerboard | 1× | — |
| 10 | First Test | Pyramid | 2× | — |
| 20 | Color Chaos | Stripes + Multipliers | 2× | — |
| 25 | Bomb Intro | Dense center | 1× | — |
| 30 | First Boss | Mirror | 2× | Contender |
| 40 | Fortress | Stone ring | 2× | — |
| 50 | Halfway Boss | Spiral | 3× | Halfway Legend |
| 60 | Color Drought | Uneven palette | 3× | — |
| 65 | Mono Wall | Top-row flood | 1× | — |
| 70 | Color Block | 3×3 blocks | 3× | Elite |
| 75 | Chessboard | 6-color chess | 3× | — |
| 80 | Chaos Flood | 30% chaos | 3× | — |
| 90 | Stone Fortress | Stone walls | 4× | Master |
| 95 | All Types | Equal spawn | 4× | — |
| 100 | THE LEGEND | "100" board | 5× | LEGEND |

---

## Retention Design

```
Wave 1–15   →  Casual players — comfort zone, big early wins
Wave 16–30  →  "I'm getting good" feel
Wave 31–50  →  Core engaged player — spends most time here
Wave 51–70  →  Hardcore territory — power-ups become crucial
Wave 71–90  →  Top 5% — bragging rights zone
Wave 91–100 →  Top 1% — legendary status
```

**Social moments (designed for share):**
- Wave 50 clear — "Halfway Legend" badge + score screen
- Wave 100 clear — "LEGEND" badge + "100" board screenshot moment

---

## What Needs to Be Built

| Feature | File | Notes |
|---|---|---|
| Wave config table (100 entries) | `wave_config.gd` (new) | Per-wave: colors, shots/shift, rows, density |
| Handcrafted board loader | `level_data.gd` (new) | Milestone wave patterns as 2D arrays |
| Bubble type spawn logic | `board_state.gd` | Weighted random per phase |
| Milestone detection + bonus | `game.gd` | Check wave number, apply multiplier |
| Badge system | `game.gd` | Persistent, shown on game over screen |
