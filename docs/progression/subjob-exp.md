# Subjob EXP Share

Your subjob levels up in the background while you grind your main. No party-leader hoops, no separate grinding sessions — just play your main and your sub catches up.

## The mechanic

Every EXP gain you earn — mob kills, FoV / GoV books, Records of Eminence, scripted sources — silently banks **25%** of that EXP toward your current subjob, on top of the EXP you already earned. When the bank crosses the per-level threshold, the sub levels up automatically with a chat message:

> _Your WAR subjob is now level 47, kupo!_

The level-up triggers the full stat recalc — skills, traits, abilities, weapon skills, HP/MP — so the next mob you fight already benefits from the new sub level.

## The numbers

| | Value |
|---|---|
| Sub EXP per main EXP | **0.25× (25%)** |
| EXP per sub level | Same as your main job needs for that level |
| Cap | Sub never exceeds main job's current level |
| EXP sources | Anything that awards main EXP — kills, books, ROE |
| Auto level-up | Yes — a big gain can clear several levels at once |
| Banked EXP | `SubExpBank` char variable (+ `SubExpBankJob`, per-subjob) |

Each sub level costs the **same EXP your main job needs for that level** (the module mirrors the server's real EXP curve), so the sub tracks 25% of your main's pace at every level — both ramp continuously instead of stepping.

## How this differs from `SUBJOB_RATIO`

`SUBJOB_RATIO = 3` on the Relaunch server (see [Retail Differences](../changes/index.md#subjob)) sets the **effective sub level cap** to your main's full level (99 main → sub can be 99 too) — but that setting doesn't grant EXP. Without the Subjob EXP Share module, a never-leveled SAM sub on a WAR/99 main still has actual sub level = 1, and `min(actual sub level, ratio cap)` is what gets used for stats — the cap alone does nothing until the sub has real levels.

This module is what actually fills the gap: as you play, the sub's real stored level climbs, and `SUBJOB_RATIO = 3` lets the sub's full level count once it's there.

## Tracking your sub's progress

Your banked sub EXP lives in a character variable named `SubExpBank` (with `SubExpBankJob` recording which subjob the bank belongs to). You can inspect them with the `!checkvar` GM command (or ask staff if you don't have GM access).

## Subjob switches

The bank is **scoped to your active subjob** — switching subs starts the new sub's bank fresh at 0. If you grind 500 banked EXP toward SAM and then switch to MNK, that 500 is abandoned; it does *not* carry over. (One exception: the very first EXP gain under this system adopts your current sub without wiping anything already banked for it.) If you care about banked overflow, settle on a sub before a long grind.

## What you don't need to do

- **No party requirement.** Works solo, in a party, or trust grinding.
- **No EXP item bands.** EXP rings still help your main, and the sub's share scales with whatever you actually earned.
- **No "rested EXP" mechanic.** It's a flat share of whatever you just earned.

## Edge cases

- **Sub at the cap:** once the sub reaches your main's current level, the share **pauses** — nothing banks while the sub is capped. It resumes as soon as your main outlevels the sub again. (At main 99 the sub simply climbs to 99 and stops.)
- **Dying and being raised:** raise EXP doesn't bank to sub. Only EXP you actually earn does.
- **Limit Break / merit mode:** when main is earning merit points instead of EXP toward a level, sub still receives its share of the raw EXP value.
- **Reborn jobs:** a subjob that has been through [Job Rebirth](job-rebirth.md) is excluded from the share — it's meant to be re-leveled as a main under its rebirth EXP penalty, so it can't ride along for free.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 8d8e5329c5bd -->
_Last updated: 2026-07-12 21:15 PDT_
<!-- DOCGEN:END id="last-updated" -->
