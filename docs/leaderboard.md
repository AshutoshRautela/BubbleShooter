# Leaderboard

Last-phase feature. Implemented in 3 tiers — local first, then online, then social.

---

## Phased Rollout

| Phase | What | When |
|---|---|---|
| Phase 1 | Local personal bests (already in ui-ux.md) | MVP launch |
| Phase 2 | Global online leaderboard (platform-native) | Post-launch update |
| Phase 3 | Friends leaderboard + seasonal boards | Growth phase |

---

## Phase 1 — Local Leaderboard (MVP)

Already designed in ui-ux.md. Stored in `user://scores.cfg`.

**Tracks per run:**
- Final score
- Wave reached
- Date

**Top 5 runs saved.** Shown on High Scores screen.

---

## Phase 2 — Global Online Leaderboard

### Platform

| Platform | Service | Notes |
|---|---|---|
| Android | Google Play Games Services | Free, built-in, no backend needed |
| iOS | Apple Game Center | Free, built-in |
| Both | Firebase Firestore (custom) | Full control, cross-platform, but needs backend work |

**Recommendation:** Start with Google Play Games (Android first) + Game Center (iOS) — zero backend cost, trusted by players, handles auth automatically.

---

### Leaderboard Categories

3 separate boards — not one single score:

| Board | Metric | Why |
|---|---|---|
| **All-Time High Score** | Highest score ever in a single run | Core competitive board |
| **Highest Wave Reached** | Furthest wave cleared | Skill/progression board |
| **Weekly High Score** | Best score in current week | Re-engagement — resets every Monday |

Weekly board is the most important for **retention** — even if a player can't beat the all-time board, they can compete weekly.

---

### Score Submission Rules

- Score submitted **only on game over or wave 100 complete** — not mid-run
- Score = final score at time of submission
- Wave = last wave fully cleared (not wave where loss happened)
- Cheat detection: server-side validation via score-per-wave ratio check
  - Max possible score per wave is calculable — flag outliers automatically

---

### UI — Global Leaderboard Screen

Accessed from: Main Menu → 🏆 High Scores → "Global" tab

```
┌─────────────────────────┐
│  ←      LEADERBOARD     │
│                         │
│  [ All-Time ][ Wave ][ Weekly ]  │  ← 3 tabs
│                         │
│  ┌───────────────────┐  │
│  │ YOUR RANK         │  │
│  │ #1,204  48,200    │  │  ← Player's own rank (always visible)
│  └───────────────────┘  │
│                         │
│  TOP PLAYERS            │
│  ┌───────────────────┐  │
│  │ 🥇 #1   PlayerA  342,100 │
│  │ 🥈 #2   PlayerB  298,500 │
│  │ 🥉 #3   PlayerC  271,200 │
│  │    #4   PlayerD  254,800 │
│  │    #5   PlayerE  241,300 │
│  │    ···             ··· │
│  │  #1202  PlayerX   48,400│
│  │ ▶#1204  YOU       48,200│  ← Player row highlighted
│  │  #1205  PlayerY   48,050│
│  └───────────────────┘  │
│                         │
│  ┌─────────────────┐    │
│  │   PLAY TO BEAT  │    │  ← CTA — goes directly to game
│  │   #1,203        │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

**Key UX decisions:**
- Player's own row always pinned — even if rank #50,000, they see themselves
- Top 3 + surrounding 3 rows (above/below player) shown by default
- "PLAY TO BEAT #X" CTA — specific target, not generic "Play Again"
- Scores are anonymized display names — no real names by default

---

### High Scores Screen — Updated (with Global tab)

```
┌─────────────────────────┐
│  ←       HIGH SCORES    │
│                         │
│    [ Personal ][ Global ]│  ← Tab switcher
│                         │
│  Personal tab → existing design (ui-ux.md)
│  Global tab   → leaderboard screen above
│                         │
└─────────────────────────┘
```

---

## Phase 3 — Friends Leaderboard + Seasonal

### Friends Board

- Pull friends list from Google Play Games / Game Center
- Show friends-only ranking — more achievable, more motivating than global
- Same 3 categories (All-Time, Wave, Weekly)

```
┌─────────────────────────┐
│  [ All-Time ][ Wave ][ Weekly ]  │
│  [ Friends  ]                    │  ← 4th tab added in Phase 3
│                         │
│  FRIENDS (8)            │
│  🥇 #1  @akshay   91,200│
│  🥈 #2  @priya    72,400│
│  🥉 #3  @rohan    68,100│
│  ▶ #4  YOU        48,200│
│     #5  @ankit    41,800│
│     ···                 │
└─────────────────────────┘
```

### Seasonal Leaderboard

- New season every 4 weeks — resets completely
- Season-specific badge awarded to top 100 at season end
- Example: "Season 3 — Top 50" badge, displayed on player profile

**Season schedule:**
```
Season 1: Launch → 4 weeks later
Season 2: Week 5 → Week 8
...and so on
```

**End-of-season notification** (push notification):
> "Season 3 ends in 2 days! You're ranked #847. Play now to climb."

---

## What Needs to Be Built

| Feature | Phase | Complexity | Notes |
|---|---|---|---|
| Local top-5 save/load | 1 | Low | `user://scores.cfg` |
| Google Play Games integration | 2 | Medium | Godot plugin: `godot-play-game-services` |
| Game Center integration | 2 | Medium | Godot plugin: `godot-ios-plugins` |
| Leaderboard UI screen | 2 | Medium | New scene |
| Weekly board reset logic | 2 | Low | Server-side timestamp check |
| Score cheat detection | 2 | Medium | Max-score-per-wave validation |
| Friends leaderboard | 3 | High | Requires platform friend APIs |
| Seasonal board + badges | 3 | High | Backend needed for season tracking |
| Push notifications | 3 | Medium | Godot notification plugin |

---

## Godot Plugins Required

| Plugin | Purpose | Platform |
|---|---|---|
| `godot-play-game-services` | Google Play leaderboards, achievements | Android |
| `godot-ios-plugins` (GameKit) | Game Center leaderboards | iOS |
| Firebase Firestore SDK | Custom backend (Phase 3 only if needed) | Both |
