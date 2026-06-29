# Weekly Hunt Board

A rotating set of weekly objectives that *amplify* your normal hunting. Every Monday at midnight UTC, **5 random objectives** roll from a larger pool. Just play — kills, augments, rank-ups, and Game Master clears all push your progress automatically. Completion pays the reward instantly. Sweep all 5 in one week for a meta-bonus and a permanent sweep counter.

!!! tip "Summary"
    Talk to the **Hunt Board** NPC in **Celennia Memorial Library** (or type `!weekly` anywhere). See your 5 weekly objectives. Hunt as you normally would — progress is automatic. Each completion auto-claims its reward. Clear all 5 in a week for +5,000 Hunt Marks and a +1 to your lifetime sweep counter (leaderboard-tracked).

## How it works

1. **Talk to the Hunt Board** NPC in **Celennia Memorial Library** — or type `!weekly` anywhere to see your objectives without traveling.
2. The board shows your 5 active objectives with progress bars.
3. **Progress is automatic** — every NM kill, augment, rank-up, and Game Master clear that matches an active objective ticks up the counter.
4. Hit an objective's target → instant completion + reward in chat. No menu interaction needed.
5. Clear all 5 → "Weekly Sweep" — bonus payout and your lifetime sweep counter increments.

## Configuration

<!-- DOCGEN:BEGIN id="weekly-hunts-config" -->
| Setting | Value |
|---|---|
| Objectives rolled per week | 5 |
| Reset cadence | Every Monday 00:00 UTC (ISO week) |
| All-cleared bonus | **5,000 Hunt Marks** + lifetime sweep counter |
| Reset trigger | Lazy — first player interaction in a new week auto-rolls |
<!-- DOCGEN:END id="weekly-hunts-config" -->

## The pool

<!-- DOCGEN:BEGIN id="weekly-hunts-pool" -->
_The pool has **11 objectives**. Each week, **5** are rolled randomly per player — your set may differ from your friends' sets._

| Objective | Target | Source | Min HL Rank | Reward |
|---|---:|---|---|---:|
| **NM Slayer**<br><sub>Kill 25 custom NMs this week (any system).</sub> | 25 | Any NM kill (Hunting League + Reforge) | HL 2 | 1,500 Hunt Marks |
| **Apex Hunter**<br><sub>Slay 5 Lv250 apex NMs this week.</sub> | 5 | Any NM kill (Hunting League + Reforge) | HL 5 | 2,000 AF Marks |
| **Guild Climber**<br><sub>Earn one Hunter's Guild rank-up this week.</sub> | 1 | Hunter's Guild rank-up | HL 1 | 1,000 Hunt Marks |
| **Wave Master**<br><sub>Complete a GM wave session, OR kill 20 custom NMs this week.</sub> | 1 | Game Master wave session complete | HL 2 | 1,000 Hunt Marks |
| **Sage's Hand**<br><sub>Successfully augment 10 items this week.</sub> | 10 | Successful augment at Augment Moogle | HL 3 | 500 Hunt Marks |
| **Reforge Devotee**<br><sub>Kill 10 Reforge NMs this week (any set).</sub> | 10 | Any NM kill (Hunting League + Reforge) | HL 3 | 1,000 AF Marks |
| **League Devotee**<br><sub>Kill 10 Hunting League NMs this week.</sub> | 10 | Any NM kill (Hunting League + Reforge) | HL 2 | 1,000 Hunt Marks |
| **Climbing Force**<br><sub>Kill 15 Lv175+ NMs this week.</sub> | 15 | Any NM kill (Hunting League + Reforge) | HL 3 | 1,500 Relic Marks |
| **Pack Hunter**<br><sub>Slay 10 NMs while partied with another player.</sub> | 10 | Any NM kill (Hunting League + Reforge) | HL 2 | 1,500 Hunt Marks |
| **Speed Demon**<br><sub>Kill an apex (Lv250) NM within 60 seconds of its spawn.</sub> | 1 | Any NM kill (Hunting League + Reforge) | HL 5 | 2,000 Empy Marks |
| **Untouchable**<br><sub>Kill 15 custom NMs in a row without dying.</sub> | 15 | Any NM kill (Hunting League + Reforge) | HL 2 | 2,500 Hunt Marks |
<!-- DOCGEN:END id="weekly-hunts-pool" -->

## How weeks reset

Reset is **lazy** — there's no scheduled job. The first time you interact with the system after midnight UTC on Monday (talking to the NPC, killing an NM, running `!weekly`, etc.), the system detects the week change and rolls fresh objectives. You'll see:

```
[Hunt Board] New week! 5 fresh objectives are available — talk to the Hunt Board NPC to view.
```

If you don't play during a given week, you simply skip that week — no missed objectives stack up. Your *previous* week's completed objectives stay on your character (the all-cleared counter is monotonic and never decreases).

## Streaks and the Untouchable objective

The **Untouchable** objective tracks your *current* kill streak — the count resets to zero on death and grows by 1 per NM kill. The objective uses the highest streak you reach in the current week (max aggregation, not a count).

```
[Hunt Board] Kill streak broken.
```

…fires in chat the moment you go down, so you'll know to start over. The streak persists across logouts and zone changes — only an actual death resets it.

## Leaderboards

The **Weekly Hunt Sweeps** leaderboard on the [Leaderboards page](../community/leaderboards.md) ranks players by lifetime sweep counts. Consistency beats first-to-the-top — the player who clears all 5 every week for a year outscores the player who burned through every objective once and stopped logging in.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 0974f147435e -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
