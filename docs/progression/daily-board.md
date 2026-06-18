# Daily Board

Talk to the **Daily Board** NPC at GM Home to pick up 3 objectives that reset every UTC midnight. Complete them and return to the NPC to claim marks. All 3 done in the same day? Grab a bonus reward on top.

!!! tip "Summary"
    Type **`!gmhome`** to get there. The **Daily Board** NPC is at the Activities cluster (z=−21, furthest west at x=−7.5). Talk to it, see today's 3 objectives, go do them, come back to claim. Resets at **00:00 UTC** every day.

## How it works

1. **Talk to the Daily Board NPC** on your first visit of the day. It snapshots your current kill counts, dungeon clears, and infamy so it can measure progress from that moment forward.
2. **Three objectives appear** — drawn from five metric groups (kills / dungeons / infamy / waves / augments), so the board has variety every day.
3. **Do the activities.** Objectives track automatically as you play — kills, dungeon clears, and infamy are all counted for you.
4. **Return to claim each reward** individually. The NPC shows real-time progress (`3/5`), and a **Claim** button appears once you hit the target.
5. **Clear all 3 in one calendar day** to earn the bonus all-cleared reward on top of the three individual payouts.

!!! note "Snapshot-based tracking"
    Progress is measured as **current value − baseline**, where the baseline is snapped the first time you talk to the NPC each day. Activities completed before your first visit that day don't count toward today's objectives. Just talk to the NPC before you start grinding.

## Objectives rotate daily

Every player on the server sees the **same 3 objectives** on the same day. Rotation is deterministic — three of the five metric groups (kills, dungeons, infamy, waves, augments) are picked and cycle based on the UTC Julian day number, so the board is always predictable. You can plan your day's activities in advance.

## Objective pool

<!-- DOCGEN:BEGIN id="daily-board-pool" -->
**NM Kills (any system)**

| Objective | Target | Reward |
|---|---:|---|
| NM Slayer | 5 kills | 400 Hunt Marks |
| NM Veteran | 10 kills | 1,000 Hunt Marks |
| NM Rampage | 20 kills | 1,500 Relic Marks |

**Dungeon Infamy**

| Objective | Target | Reward |
|---|---:|---|
| Infamy Earner | 50 Infamy | 400 Hunt Marks |
| Infamy Collector | 100 Infamy | 900 Hunt Marks |
| Infamy Hoarder | 250 Infamy | 1,200 Empy Marks |

**Wave Fights**

| Objective | Target | Reward |
|---|---:|---|
| Wave Warrior | 1 wins | 700 Hunt Marks |
| Wave Runner | 2 wins | 850 Relic Marks |
| Wave Dominator | 3 wins | 1,100 Empy Marks |

**Augmentation Trades**

| Objective | Target | Reward |
|---|---:|---|
| Forgemaster | 1 trades | 400 Hunt Marks |
| Augment Artisan | 2 trades | 700 Hunt Marks |
| Augment Adept | 3 trades | 1,200 AF Marks |
<!-- DOCGEN:END id="daily-board-pool" -->

## All-cleared bonus

<!-- DOCGEN:BEGIN id="daily-board-all-cleared" -->
Claim all 3 objectives in the same UTC calendar day for a bonus **500 Hunt Marks + 100 AF Marks** on top of the individual payouts.
<!-- DOCGEN:END id="daily-board-all-cleared" -->

Your lifetime all-cleared day count is tracked and shown in [`!progress`](../reference/commands.md).

## Currencies

The Daily Board pays out the same four currencies used across the rest of Legendary's progression:

| Currency | How it's spent |
|---|---|
| Hunt Marks | Hunting League seals, Hunter's Guild rep, misc rewards |
| AF Marks | AF reforge armor track |
| Relic Marks | Relic reforge armor track |
| Empy Marks | Empyrean reforge armor track |

## NPC location

The Daily Board NPC stands at GM Home, Activities cluster:

| NPC | Position | Zone |
|---|---|---|
| **Daily Board** | `(-4.5, 0, -25)` | GM Home (zone 210) |

It's the westernmost NPC in the row — just past the EXP Camp Moogle heading west.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 8f7d607d5a2a -->
_Last updated: 2026-06-18 01:47 UTC_
<!-- DOCGEN:END id="last-updated" -->
