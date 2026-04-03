# BGM Design

Background music plan for Bubble Shooter.

This document is intentionally practical. The goal is not "maximum audio system sophistication." The goal is music that supports dopamine, stays out of the way of SFX, and is realistic to ship.

---

## Core Philosophy

> In this game, SFX carries the hit. BGM carries the atmosphere.

3 rules:

1. **SFX wins over music**
   Pop, bounce, board clear, haptics, and reward sounds are the primary feel layer.

2. **Music should support, not distract**
   If players notice the melody more than the pop feedback, the BGM is too loud or too busy.

3. **Progress should sound different by chapter, not by wave**
   The player remembers broad emotional phases, not 100 separate tracks.

---

## Recommended Structure

Do **not** make a unique track for every wave.

Do:

- 1 `Main Menu` theme
- 6 `Chapter` gameplay loops
- 3 to 4 short `stingers`

That is enough to make the game feel rich without creating an audio production problem.

---

## Why Not Wave-Based Music

Changing BGM every wave is the wrong tradeoff for this game.

Problems:

- too much content to create and maintain
- player will not meaningfully remember wave-level tracks
- music transitions will become noisy and fatiguing
- dopamine from SFX gets diluted
- implementation complexity goes up for very little payoff

Better:

- chapter-level identity
- milestone stingers
- danger-state layering only if really needed later

---

## Chapter-Based Plan

Each chapter gets one clear musical identity.

| Track | Scope | Mood | Notes |
|---|---|---|---|
| Menu Theme | Main Menu, High Scores, idle shell | inviting, magical, calm | should make the game feel alive before play |
| Chapter 1 | Waves 1–15 | playful, bright, lightweight | beginner confidence, low pressure |
| Chapter 2 | Waves 16–30 | confident, rhythmic, slightly sharper | player feels "I know this now" |
| Chapter 3 | Waves 31–50 | focused, tense, forward-driving | challenge is now real |
| Chapter 4 | Waves 51–70 | urgent, darker, tighter pulse | pressure phase |
| Chapter 5 | Waves 71–90 | heavy, high-stakes, controlled | mastery gauntlet |
| Chapter 6 | Waves 91–100 | epic, restrained, final-run energy | should feel like late-game prestige, not noise |

This aligns directly with progression and is easy for the player to feel subconsciously.

---

## Tone Direction

The game is not:

- sleepy ambient
- cinematic orchestral overload
- aggressive EDM
- lo-fi study music

The target zone is:

- **playful**
- **rhythmic**
- **slightly hypnotic**
- **clean**
- **mobile-friendly**

The music should feel like it belongs behind popping, chain reactions, and short-session play.

---

## Musical Characteristics

### Menu Theme

**Mood:** Warm, slightly magical, welcoming.

**Should feel like:**
- "This game has charm"
- "Come in, play one round"

**Should avoid:**
- tension
- heavy percussion
- dramatic stakes

### Chapter 1 — Rookie

**Mood:** Light, buoyant, optimistic.

**BPM:** ~105–112

**Texture:**
- soft synth plucks
- light bass pulse
- spacious percussion

### Chapter 2 — Contender

**Mood:** More momentum, still clean.

**BPM:** ~112–118

**Texture:**
- stronger rhythm
- more defined bass
- subtle arpeggio movement

### Chapter 3 — Warrior

**Mood:** Focused and rising.

**BPM:** ~118–124

**Texture:**
- tighter groove
- darker harmony
- more forward energy

### Chapter 4 — Elite

**Mood:** Pressure without chaos.

**BPM:** ~124–130

**Texture:**
- sharper pulse
- more tension in low end
- restrained melodic content

### Chapter 5 — Master

**Mood:** Heavy, controlled, high-stakes.

**BPM:** ~126–132

**Texture:**
- dense bass support
- stronger percussion
- fewer cute elements, more intensity

### Chapter 6 — Legend

**Mood:** Final-run prestige.

**BPM:** ~128–134

**Texture:**
- bigger stereo width
- richer pads or synth harmony
- still leave headroom for board clear / milestone stings

This should feel special, not cluttered.

---

## SFX vs BGM Hierarchy

This matters more than track quality.

| Audio Layer | Role | Priority |
|---|---|---|
| Pop / reward SFX | Primary dopamine hits | Highest |
| Board clear / milestone stings | Big payoff markers | Very high |
| Haptics | Physical reinforcement | Very high |
| BGM | Atmosphere + pacing | Medium |

Default mix target:

- `SFX Bus`: foreground
- `BGM Bus`: around `-12 dB` to `-16 dB` under SFX
- Stingers can briefly sit above BGM but below main gameplay SFX

If anything has to lose volume, BGM loses first.

---

## Dynamic Behavior

Keep this simple at launch.

### Launch Version

- one looping track per chapter
- hard switch only between chapters or screens
- smooth fade between tracks: `1.0s - 1.5s`
- no full adaptive stem system yet

### Later Upgrade

Only after the base game is stable:

- optional danger layer when stack nears lose line
- optional menu idle variation
- optional chapter intro sting

Do **not** build a complex stem mixer before core game systems are finished.

---

## Stingers

Short one-shot musical events matter more than complex adaptive BGM.

Recommended stingers:

| Sting | Trigger | Purpose |
|---|---|---|
| Board Clear Sting | board fully cleared | strongest regular reward moment |
| Milestone Sting | W10, W20, W30... | makes milestone waves feel special |
| Personal Record Sting | new best score / best wave | identity reward |
| Chapter Unlock Sting | first time chapter opens | progress celebration |

These should duck BGM briefly and get out of the way.

Rule:

- BGM dips `4–6 dB`
- sting plays
- BGM restores smoothly

---

## Screen Mapping

| Screen | Music Behavior |
|---|---|
| Splash | silence or very soft menu fade-in |
| Main Menu | Menu Theme |
| High Scores | Menu Theme or softer menu variant |
| Settings | continue current track |
| Cannon Power Selection | current chapter track, slightly dipped |
| Gameplay | current chapter track |
| Wave Complete | current chapter track resumes after sting |
| Milestone Moment | current chapter track ducked under milestone sting |
| Game Over | fade BGM out over `1.0s - 1.5s` |

---

## Source Strategy

### Best Practical Approach

For now:

- use temporary procedural / placeholder SFX
- delay final premium SFX until the game shape is stable
- do the same logic for BGM: **placeholder first, final pass later**

### Recommended Music Source Options

1. **Free music libraries**
   Good for first shipping versions.
   Sources:
   - `pixabay.com/music`
   - `freemusicarchive.org`
   - `opengameart.org`

2. **AI-generated / assisted loops**
   Useful only after chapter moods are frozen.

3. **Commissioned music**
   Best long-term quality, but not needed before the game proves itself.

---

## Release Plan

### v0.1

- No BGM is acceptable
- SFX + game feel are enough
- do not delay launch for music

### v0.2

- add `Menu Theme`
- add `Chapter 1`, `Chapter 2`, `Chapter 3` loops
- add `Board Clear Sting`

### v0.3

- complete all 6 chapter loops
- add `Milestone Sting`
- add `PR Sting`
- add `Chapter Unlock Sting`

### v0.4+

- optional danger layer
- optional alternate menu variation
- upgrade tracks if better custom/AI/composer options become available

---

## Implementation Shape

Minimal node setup:

```text
Game / Shell Scene
├── BGMPlayer
└── StingPlayer
```

Minimal manager responsibilities:

- detect current chapter
- load corresponding loop
- fade between menu/game/chapter states
- play stingers with temporary BGM ducking

Suggested file:

- `scripts/bgm_manager.gd`

This should stay simple. It is a routing layer, not a music engine.

---

## What Good BGM Means For This Game

Good BGM here means:

- player does not mute it immediately
- player still clearly hears every pop and reward sound
- chapter shifts feel emotionally distinct
- long sessions do not become tiring
- board clear and milestone moments feel bigger because music makes room for them

If all of that is true, the BGM is doing its job.

---

## Build Priority

| Item | Priority |
|---|---|
| SFX-first mix discipline | Highest |
| Menu Theme | High |
| 6 chapter loops | High |
| Board Clear Sting | High |
| Milestone / PR / Chapter Unlock stings | Medium |
| Dynamic danger layer | Low |
| Advanced adaptive stem system | Very low |

---

## Final Recommendation

The right music plan for Bubble Shooter is:

- **not 100 wave tracks**
- **not a complicated adaptive music engine**
- **not music louder than SFX**

It is:

- **1 menu loop**
- **6 chapter loops**
- **3–4 short stingers**
- **simple fades**
- **SFX always in front**

That is the cleanest, most realistic, and most effective direction for this game.
