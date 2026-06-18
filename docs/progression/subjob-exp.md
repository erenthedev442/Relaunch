# Subjob EXP Share

Your subjob levels up in the background while you grind your main. No party-leader hoops, no separate grinding sessions — just play your main and your sub catches up.

## The mechanic

Every EXP gain you earn — mob kills, FoV / GoV books, Records of Eminence, scripted sources — silently banks **half** of that EXP toward your current subjob (the `SHARE_RATE = 0.5` share of the EXP you already earned — there is no extra multiplier on top). When the bank crosses the per-level threshold, the sub levels up automatically with a chat message:

> _Subjob WAR reached level 47, kupo!_

The level-up triggers the full stat recalc — skills, traits, abilities, weapon skills, HP/MP — so the next mob you fight already benefits from the new sub level.

## The numbers

| | Value |
|---|---|
| Sub EXP per main EXP | **0.5×** |
| Cap | Sub never exceeds main job's current level |
| EXP sources | Anything that awards main EXP — kills, books, ROE |
| Auto level-up | Yes, in the background |

So whatever mob EXP you earn on main, your sub banks half of that same amount per kill — no separate multiplier is applied. Roughly: every two main level-ups, your sub gains one level — except both ramp continuously instead of stepping.

## How this differs from `SUBJOB_RATIO`

`SUBJOB_RATIO = 3` on Legendary (see [What's Custom](../changes/index.md#subjob)) raises the **effective sub level cap** to match main — but that setting doesn't grant EXP. Without the Subjob EXP Share module, a never-leveled SAM sub on a WAR/99 main still has actual sub level = 1, and `min(actual_sub_level, main_level) = 1` is what gets used for stats.

This module is what actually fills the gap: as you play, the sub's real stored level climbs, and `SUBJOB_RATIO = 3` lets the full level apply once it's there.

## Tracking your sub's progress

Your banked sub EXP lives in a character variable named `SubExpBank`. You can inspect it with the `!checkvar` GM command (or ask staff if you don't have GM access).

## Subjob switches

The bank is shared across subjobs — it doesn't reset when you change your sub. If you grind 500 bank toward SAM, then switch to MNK, that 500 carries over and counts toward MNK. In practice this just means you don't lose progress when experimenting, and the very first level-up after a switch may fire on the first kill if you had a near-full bank from a previous sub.

## What you don't need to do

- **No party requirement.** Retail required you to be in a party for full sub EXP; this works solo, party, or trust grinding.
- **No EXP item bands.** EXP rings still help your main but your sub gets its share regardless.
- **No claim of "rested EXP" mechanic.** It's a flat share of whatever you just earned.

## Edge cases

- **Main capped at 99:** sub still levels until it reaches 99. EXP still gets banked from every kill, the cap just keeps sub from outrunning main (which it can't anyway since main is at the ceiling).
- **Dying and being raised:** raise EXP doesn't bank to sub. Only EXP you actually earn does.
- **Limit Break / merit mode:** when main is earning merit points instead of EXP toward a level, sub still receives its share of the raw EXP value.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: d199dd677369 -->
_Last updated: 2026-06-12 23:32 UTC_
<!-- DOCGEN:END id="last-updated" -->
