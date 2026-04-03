# Dopamine Design

How the game keeps players engaged shot-by-shot, wave-by-wave, and session-by-session. Every mechanic here is intentional — rooted in reward psychology.

---

## The Core Loop — Why It Feels Good

Bubble shooters work because they hit 3 psychological triggers simultaneously:

```
1. CLEAR GOAL        → "Match 3 of the same color"
2. IMMEDIATE FEEDBACK → Pop sound + visual burst, instant score
3. VARIABLE REWARD   → Sometimes 3 bubbles pop, sometimes 15 cascade
```

Variable reward is the most important. If every shot removed exactly 3 bubbles, the game would feel mechanical. The unpredictability of chain reactions is what makes it addictive — same reason slot machines work.

---

## Dopamine Intensity Scale

Every reward moment is rated 1–5:

| Level | Name | Examples |
|---|---|---|
| 1 | Micro | Bubble lands satisfyingly, aim guide reacts |
| 2 | Small | 3-bubble pop, placement sound |
| 3 | Medium | 6–9 bubble cluster, power-up earned |
| 4 | Large | Chain cascade 10+, board nearly cleared |
| 5 | Peak | Board clear, milestone wave, personal record |

A good session should hit levels 1–2 every shot, level 3 every 3–5 shots, level 4 every wave, and level 5 every 3–5 waves.

---

## Layer 1 — Shot-by-Shot (Every 2–5 seconds)

These fire on every single shot. The baseline dopamine that keeps players shooting.

### The Pop Feel
**What:** Bubble pop animation + SFX
**Why it works:** Immediate audio-visual confirmation. The `bubble_pop_sparkle.wav` (triple ping cascade) is specifically tuned for this — 3 rapid ascending tones hit reward centers stronger than a single pop.
**Enhancement:** Each bubble in a cluster pops with 20ms stagger + outward particle burst. Not simultaneous — the *ripple* through the cluster feels alive.

### Aim Satisfaction
**What:** The moment the aiming guide aligns perfectly and player commits the shot
**Why it works:** Anticipation phase before the reward. The pullback animation (loaded bubble moves back along aim axis) adds physical tension — like pulling a bowstring.
**Enhancement:** Aim guide glows brighter as it approaches a valid cluster. Subtle — player feels it subconsciously.

### Landing Thud
**What:** Bubble snaps to grid + neighbor nudge animation
**Why it works:** Even a miss has satisfying feedback. The micro-bounce on landing + neighbor ripple says "something happened" even without a pop.

### Cannon Recoil
**What:** Cannon kicks back on fire, recovers with spring
**Why it works:** Physical cause-effect. Body knows it fired something real.

---

## Layer 2 — Match Moments (Every 3–8 shots)

### The Cluster Pop
**The single most important moment in the game.**

**Intensity: 2–4 depending on size**

Size ladder — each step feels noticeably better:

| Cluster Size | Feel | Extra Effect |
|---|---|---|
| 3 | "Nice" | Normal pop |
| 4–5 | "Good shot" | Slightly bigger particle burst |
| 6–8 | "Great!" | Screen micro-shake, louder pop pitch |
| 9–12 | "Combo!" | Flash white before pop, floating text "+COMBO" |
| 13+ | "MASSIVE!" | Screen shake, slow-motion 0.3s, chain bonus indicator |

**Implementation:** `bubble_pop_sparkle.wav` pitch scales up with cluster size. `pitch_scale = 1.0 + (cluster_size - 3) * 0.04` — subtle but noticeable.

### The Cascade (Floating Removal)
**The second most important moment.**

When a cluster pops and 5+ bubbles above it become floating → they all fall. This is the "jackpot" moment.

**Why it works:** Player did something local (popped 3 bubbles) but got a disproportionate reward (10 more fall for free). Unexpected reward = stronger dopamine than expected reward.

**Enhancement:**
- Floating bubbles don't just disappear — they *fall* with gravity + alpha fade
- 80ms delay after cluster pop so both animations are visually distinct
- Each falling bubble has its own slight rotation
- SFX: `floating_fall.wav` plays per-bubble with tiny pitch variance — cascade sounds like "whooshwhooshwhoosh"

### Near-Miss Save
**What:** Stack is 1–2 rows from the lose line. Player clears enough to push it back.
**Why it works:** Relief after tension = strong dopamine. The brain releases more reward chemicals after stress than after no stress.
**Enhancement:**
- Lose line pulses red faster as stack approaches — builds anxiety
- When player clears a row and stack retreats: lose line flash goes green briefly
- Status message: "Close call!" — acknowledges the moment

---

## Layer 3 — Wave-Level Rewards (Every 1–5 minutes)

### Board Clear
**Intensity: 5**

The peak moment of each wave.

**Enhancement sequence (500ms total):**
1. Last bubble pops — normal pop animation
2. 80ms pause — silence (anticipation)
3. Full screen white flash — 60ms
4. "WAVE CLEAR!" text erupts from center — spring animation
5. All remaining empty cells briefly glow cyan
6. Score count-up with satisfying click sounds
7. Particle confetti from top of screen — 1.5s

**Why the 80ms pause matters:** It's a "breath" before the explosion. Without it, the clear feels rushed. With it, the brain registers "something big is about to happen."

### Power-Up Earned
**Intensity: 3**

**Enhancement:**
- Slot flashes gold 3× — like a notification you want to tap
- Floating text appears briefly: "⚡ RAPID FIRE READY"
- SFX: ascending 3-tone chime (not the pop sound — distinct audio identity)
- Player must consciously choose to activate — the anticipation of using it is its own reward

### Cannon Power Selection
**Intensity: 3**

The choice between 3 options before a wave is itself a dopamine hit — not just the choice, but the *anticipation* of reading options.

**Enhancement:**
- Cards slide in with stagger (50ms between each)
- Hovering/selecting a card shows a brief preview animation of the power's effect
- The "skip" option is visually de-emphasized — nudges player toward engagement

---

## Layer 4 — Milestone Moments (Every 10–30 minutes)

### Milestone Wave Complete (W10, W20, W30...)
**Intensity: 5**

Designed as a "screenshot moment."

**Full sequence:**
1. Board clears — normal board clear effect
2. 200ms pause
3. Screen darkens — spotlight effect on center
4. Wave number counts UP dramatically: "10... 20... 30..."
5. Badge animates in — circular reveal wipe
6. Badge name letter-by-letter: "C O N T E N D E R"
7. Confetti burst — heavier than normal wave clear
8. Score with multiplier displayed: "×2 BONUS!"
9. Share button appears — social proof opportunity

**Why this works:** The sequence is long enough to feel *earned*, but every step has its own micro-reward. It's a reward sandwich.

### Personal Record
**Intensity: 4–5**

**Enhancement:**
- Gold trophy icon bounces into game over screen
- "NEW BEST!" flashes in gold
- Score counter goes gold color during count-up
- SFX: distinct fanfare (not the regular wave-clear sound)
- Subtle confetti — less than board clear, more than normal

**Why distinct SFX matters:** Players learn to associate sounds with rewards. If the PR sound is unique, hearing it triggers a conditioned response over time.

---

## Layer 5 — Session-Level Hooks (Daily/Weekly)

### Weekly Leaderboard
**Why it works:** Weekly reset means every Monday is a fresh chance. Player who is rank #2,400 globally can be rank #12 on Week 1 of a new season. Achievable targets = more engagement.

**Notification timing:**
- Sunday evening: "Season ends in 12 hours — you're ranked #847"
- Monday morning: "New week! Your rank resets. First to play gets an early lead."

### Wave Streak
**What:** Track consecutive days player reached a new wave
**Display:** "3-day streak 🔥" on main menu
**Why it works:** Streak loss aversion — "I don't want to break my 7-day streak" pulls players back even when they don't feel like playing.

### Daily Challenge
**What:** One specific board layout per day, same for all players. Score posted to a daily-only leaderboard.
**Why it works:** FOMO — challenge expires at midnight. Creates urgency without feeling manipulative (it's skill-based, not pay-to-win).

---

## Variable Reward Schedule

The most important dopamine mechanic — NOT what rewards you get, but WHEN.

Current game: reward is semi-predictable (cluster pop = pop sound). Needs variation.

**Proposed: Score Multiplier Streaks**

```
3 consecutive matches  → "ON FIRE 🔥" — next pop score ×1.25
5 consecutive matches  → "UNSTOPPABLE" — next pop score ×1.5
7 consecutive matches  → "LEGEND MODE" — next pop score ×2.0 + visual effect
Miss resets streak to 0
```

**Why:** Players will start trying to maintain streaks even when a miss might be "safer." The anticipation of maintaining a streak + the disappointment of breaking it = deep engagement.

**Proposed: Lucky Shot Detection**

If a wall-bounce shot creates a cluster of 6+ that the player clearly didn't aim at (detected by: bounce occurred + cluster center is far from original aim target):

- Show "LUCKY! 🍀" floating text
- Play a distinct surprised SFX
- No score bonus — the acknowledgment itself is the reward

**Why:** Unexpected positive surprise releases more dopamine than expected reward. Also creates a story the player wants to share ("you won't believe this lucky shot I got").

---

## Anti-Frustration Design

Dopamine design isn't just about highs — it's about managing lows. Frustration kills sessions.

| Frustration Point | Current State | Fix |
|---|---|---|
| Row drops right after a good shot | No warning | "Row dropping in 1 shot" warning — amber status text |
| Stack too dense to find a match | Player feels stuck | Fire Assist quietly adjusts aim — already implemented |
| Same bad colors keep appearing | Feels unfair | `pick_shoot_color()` uses grid colors — already biased toward what's on board |
| Game over feels sudden | No ramp-up | Lose line pulse frequency increases as stack approaches — build dread slowly |
| Long miss streak | Demoralizing | After 4 consecutive no-match shots: soft glow on best cluster opportunity |

**The "soft hint" after 4 misses:**
- NOT a forced aim assist
- Just a subtle golden glow on the bubble cluster that would give the best pop
- Player can ignore it — but it reduces rage-quit probability significantly

---

## Sound Design as Dopamine

Sound is 50% of the dopamine experience. Each sound event needs its own identity:

| Moment | Sound | Why |
|---|---|---|
| Bubble fire | `shoot_whoosh.wav` — short, crisp | Confirms action immediately |
| Bubble pop (small) | `bubble_pop.wav` — soft | Neutral, non-fatiguing |
| Bubble pop (big cluster) | `bubble_pop_juicy.wav` — fat, punchy | Scaled to cluster size |
| Cascade fall | `floating_fall.wav` × N with pitch variance | Feels like rain — satisfying quantity |
| Wall bounce | `wall_bounce.wav` — quick chirp | Physical feedback |
| Board clear | `board_cleared.wav` — ascending arpeggio | Musical resolution — brain loves it |
| Game over | `game_over.wav` — descending tones | Acknowledges loss without punishing |
| Power-up earned | 3-tone chime (to be generated) | Distinct from all gameplay sounds |
| PR achieved | Fanfare (to be generated) | Unique — pavlovian conditioning |
| Milestone wave | Full arpeggio + reverb (to be generated) | Bigger than board clear |

**Pitch scaling rule:** Same base sound, different pitch = player learns the reward hierarchy without thinking. Higher pitch = bigger reward.

```
Small pop:     pitch_scale = 1.0
Medium cluster: pitch_scale = 1.1
Large cluster:  pitch_scale = 1.2
Board clear:    pitch_scale = 1.35
Milestone:      pitch_scale = 1.5
```

---

## UX-Driven Dopamine

Game mechanics alag hai — yeh section pure UX design se aane wale dopamine triggers hain. Koi gameplay change nahi, sirf screens aur flows se milta hai.

---

### 1. Progress Visibility — "I can see how far I've come"

**Wave Path ke stars** (ui-ux.md se):
```
★★★★★ ★★★★★ ★★★     ← 13/15 waves cleared
```
Yeh sirf data nahi hai — yeh incomplete pattern hai. Human brain incomplete patterns ko complete karna chahta hai (Zeigarnik Effect). 2 missing stars = pull to come back.

**Enhancement:** Stars fill with a brief glow animation every time screen opens. Even seeing old progress gives a small dopamine hit.

---

### 2. Locked Chapters — Desire by Design

Chapter Map mein locked chapters deliberately visible hain — unka naam, silhouette, wave count sab dikhta hai. Player jo nahi pa sakta woh dekh sakta hai.

```
┌─────────────────┐
│ 🔒  MASTER      │   ← Naam visible
│  Waves 71–90    │   ← Scope visible
│  Clear Wave 70  │   ← Goal clear
└─────────────────┘
```

**Psychology:** IKEA Effect + Loss Aversion. Jo cheez dikhti hai lekin milti nahi, uski value zyada lagti hai. Locked chapter = future reward already mentally "owned."

**Enhancement:** Locked chapter card mein blurred preview of wave 71's board pattern — player can almost see it. Makes it tangible.

---

### 3. Score Count-Up Animation

Score kabhi instantly nahi jump karta — hamesha count karta hai. `500 points/second` rate pe.

**Psychology:** Watching numbers go up is intrinsically rewarding — same reason people watch investment portfolios. The journey to the number matters, not just the number.

**Enhancement for milestone waves:**
- Count-up rate starts slow (100/s), accelerates (2000/s), then slows near final number
- "Easing" the count — like a car decelerating into a parking spot
- Final number lands with a subtle thud SFX + number scale pulse

---

### 4. Cannon Power Selection — The Anticipation Screen

3 cards sliding in with stagger. Player pauses, reads, thinks, chooses.

**Psychology:** Anticipation of a reward activates dopamine MORE than receiving the reward itself (Wolfram Schultz research). The selection screen is a dopamine moment before the wave even starts.

**Enhancement:**
- Cards slide in one by one (50ms stagger) — not all at once
- Each card has a 1-line teaser: "Pop 3 shots in rapid succession"
- Hovering a card shows a 0.5s preview animation of the power in action
- The chosen card "locks in" with a satisfying click + border glow

---

### 5. Chapter Unlock Moment

When Wave 30 clears and "CONTENDER" chapter unlocks for the first time:

```
Normal wave-clear sequence plays...
    ↓
Chapter Map auto-opens
    ↓
"WARRIOR" card animates from locked → unlocked:
  - Lock icon breaks apart (particle burst)
  - Card border changes dark → cyan
  - Card slides forward slightly (z-depth)
  - "NEW CHAPTER UNLOCKED" banner sweeps across
    ↓
Player is now looking at a new chapter they've never seen
```

**Psychology:** New territory = exploration reward. Same as opening a new area in an RPG. First time is always the strongest hit.

**Enhancement:** Unlocked chapter shows a "FIRST ENTRY" badge first time player taps it — acknowledges the milestone exists.

---

### 6. Personal Rank Number — Competitive Identity

On the leaderboard: "#1,204" is not just a number — it becomes the player's identity target.

**Psychology:** Specific goals are more motivating than vague ones. "I want to beat rank #1,204" > "I want to do better."

**Enhancement — Rank Delta Display:**
```
Last session:  #1,847
This session:  #1,204
              ↑ +643 ranks climbed  ← Show this prominently
```

Green arrow up = instant dopamine. Even if absolute rank is still bad, the *improvement* is rewarding.

---

### 7. Wave Path Scroll — The "Behind Me" Effect

When player opens Wave Path and scrolls back to see cleared waves:

```
○ 31  (upcoming)
○ 30  BOSS 👑  (upcoming)
★ 29  (cleared)
★ 28  (cleared)
★ 27  (cleared)
```

Seeing cleared waves *below* the current position creates a "I've come so far" feeling — separate from looking ahead.

**Enhancement:** Cleared wave stars have a subtle golden shimmer when Wave Path is first opened. Celebrates past progress passively.

---

### 8. The "One More Wave" Trap — Designed Entry Points

Every natural stopping point has a hook that pulls into the next thing:

| Stopping Point | Hook |
|---|---|
| Wave complete screen | "Wave 26 → 27 — first wave with Bomb bubbles" (preview) |
| Game over screen | "You were 2 waves from unlocking WARRIOR chapter" |
| Chapter complete | "WARRIOR chapter unlocks — 20 new waves" |
| Leaderboard view | "Play to beat #1,203" CTA button |
| Main menu idle 3s | Animated bubbles float up behind title — game looks alive |

**Psychology:** Each hook is a specific, near goal — not a vague "play more." The brain responds to concrete next steps.

---

### 9. Haptic Feedback (Mobile)

Sound + visual covers eyes and ears. Haptics cover the body — triple sensory confirmation.

| Moment | Haptic Type |
|---|---|
| Bubble fire | Light tap (`HapticFeedback.LIGHT`) |
| Small pop (3–5) | Medium tap |
| Large pop (9+) | Heavy burst |
| Board clear | Double pulse |
| Milestone wave | Long rumble (500ms) |
| Game over | Slow double tap |
| Power-up earned | Short buzz |

**Implementation:** Godot — `Input.vibrate_handheld(duration_ms)`. Android supports intensity levels via Java plugin; iOS via UIImpactFeedbackGenerator.

**Why haptics matter more than expected:** Research shows haptic feedback increases perceived quality of an interaction by ~30%. A pop that you *feel* is more satisfying than one you only see and hear.

---

### 10. Empty State Design — First Launch

First time player opens the app — no progress, no score, no rank. This is a critical moment. Boredom or confusion here = uninstall.

**Current state:** Game starts immediately (no main menu).
**Problem:** No context, no goal, no identity.

**Fix — First Launch Sequence:**
```
Splash screen
    ↓
Animated tutorial bubble pops 3 at once (no input needed — just watch)
    ↓
"Match 3 bubbles to pop them"
    ↓
Wave 1 starts — first board is extra sparse, clusters obvious
    ↓
After first board clear: "Wave 1 cleared! You're a natural." (status message)
    ↓
Chapter Map opens for first time — Rookie chapter highlighted
```

Player's first 60 seconds must deliver at least 2 dopamine hits before they even reach Wave 2.

---

## UX Dopamine Summary

| UX Pattern | Trigger | Intensity |
|---|---|---|
| Incomplete stars (Zeigarnik) | Every Chapter Map open | 2 |
| Locked chapter visible | Every Chapter Map open | 2 |
| Score count-up | Every wave/game over | 3 |
| Cannon power anticipation | Every wave start (W8+) | 3 |
| Chapter unlock moment | First time only, per chapter | 5 |
| Rank delta display | After every online session | 3 |
| Wave path "behind me" scroll | Manual — player initiated | 2 |
| "One more wave" hooks | Every natural exit point | 3 |
| Haptic feedback | Every significant game moment | 2–4 |
| First launch sequence | Once only | 4 |

---

## What Needs to Be Built

| Feature | Doc Reference | Priority |
|---|---|---|
| Cluster size → pitch scaling | This doc | High |
| Cascade fall animation (staggered) | This doc + ui-ux.md | High |
| Near-miss "close call" detection | This doc | Medium |
| Consecutive match streak system | This doc | Medium |
| "Lucky shot" detection | This doc | Medium |
| 80ms pause before board clear | This doc + ui-ux.md | High |
| Soft hint after 4 misses | This doc | Medium |
| Daily challenge mode | This doc | Low (post-launch) |
| Day streak tracking | This doc | Low (post-launch) |
| Additional SFX (PR fanfare, milestone) | This doc | Medium |
