# Bubble Shooter — Game Design Document

## Overview

A mobile-first bubble shooter with 100 waves of hand-tuned progression, 7 bubble types, and 6 power-ups. Built in Godot 4.6 using code-driven rendering (no sprite assets).

**Platform:** Android (primary), iOS (planned)
**Genre:** Casual / Puzzle
**Target Audience:** Ages 14+ — casual to mid-core players

---

## Core Game Loop

```
Aim → Fire → Match 3+ → Pop cluster → Remove floating bubbles
       ↓ (no match)
  shots_until_shift decrements → Row drops from ceiling
       ↓
  Stack reaches lose line → Game Over
```

---

## Documents

| Document | What's Inside |
|---|---|
| [Roadmap](roadmap.md) | 4 releases — v0.1 Core Ship → v0.2 Content → v0.3 Systems → v0.4 Growth |
| [v0.1 Implementation Plan](v0.1-implementation-plan.md) | Exact build order and file-by-file execution plan for the 25-wave launch |
| [Gameplay Spec](gameplay-spec.md) | Exact deterministic rules — interaction matrix, resolution order, edge cases |
| [Level Design](level-design.md) | 100-wave progression, phases, difficulty curve, milestone waves |
| [Bubble Types](bubble-types.md) | 7 bubble types — mechanics, spawn rates, introduction timeline |
| [Power-Ups](power-ups.md) | 6 board power-ups + 5 cannon powers — effects, how to earn, cooldowns |
| [UI / UX Design](ui-ux.md) | All screens, flows, animations, touch guidelines, color system |
| [BGM Design](bgm-design.md) | Chapter-based BGM plan, stingers, launch-safe music scope |
| [Leaderboard](leaderboard.md) | 3-phase leaderboard plan — local → global → friends + seasonal |
| [Dopamine Design](dopamine-design.md) | Reward psychology, feedback layers, variable rewards, anti-frustration |
| [Architecture](ARCHITECTURE.md) | Technical architecture, code structure, module responsibilities |

---

## Game Constants (Current)

| Parameter | Value |
|---|---|
| Grid columns | 9 |
| Starting rows | 6 |
| Base palette size | 4 colors |
| Max palette size | 6 colors |
| Shots per shift (start) | 5 |
| Min match size | 3 bubbles |

---

## Scoring

| Action | Points |
|---|---|
| No match (bubble placed) | +5 |
| Cluster pop (per bubble) | +20 |
| Floating bubble removed (per bubble) | +25 |
| Stone bubble falls | +40 |
| Board cleared | +150 |
| Multiplier bubble in cluster | ×2 current shot score |
| Chain reaction (10+ bubbles) | ×1.5 |
| Milestone wave clear | ×2 / ×3 / ×4 / ×5 |

---

## Feature Status

| Feature | Status |
|---|---|
| Core gameplay loop | Done |
| Wave progression (basic) | Done |
| Mobile / desktop FX profiles | Done |
| Procedural SFX (all 7 sounds generated) | Done |
| Game design documentation | Done |
| 100-wave config | Planned |
| New bubble types (7) | Planned |
| Board power-up system (6) | Planned |
| Cannon power system (5) | Planned |
| Handcrafted milestone boards | Planned |
| SFX integration in game | Done |
| High score persistence | Planned |
| Pause / resume | Planned |
| Main menu + splash screen | Planned |
| Settings screen | Planned |
| Wave complete screen | Planned |
| Cannon power selection screen | Planned |
| Background music | Planned |
| Tutorial / onboarding | Planned |
| Android signing + release | Planned |
| Leaderboard — local (Phase 1) | Planned |
| Leaderboard — global online (Phase 2) | Last Phase |
| Leaderboard — friends + seasonal (Phase 3) | Last Phase |
