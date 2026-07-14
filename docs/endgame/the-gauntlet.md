# The Gauntlet

!!! tip "Summary"
    A **10-level mandatory solo challenge** inside **Riverne Site A01**. Every level puts you alone against a Legendary NM — no safe route, no skipping. Each boss is harder than the last and carries a full suite of hardcore combat mechanics: enrage timers, stance switching, crowd control, dispels, and a self-heal drain. Defeat all ten to claim one of the largest rewards on the server and a permanent NPC in the **Hall of Champions**.

---

## Where to start

Talk to **The Gauntlet** keeper (sword-and-shield icon) in <!--npc:gauntlet-->Riverne-Site A01<!--/npc-->. Choose *Enter The Gauntlet* and you are warped straight into the arena.

**Rules:**

- **Solo only** — Trusts are automatically dismissed on entry. Pets are allowed.
- **No outside healing.** Players fighting a Gauntlet NM cannot receive healing from anyone outside the arena fight.
- **One death ends the run.** You are expelled immediately, no exceptions.
- **Leaving the arena zone ends the run.** Use `!gauntlet abort` to exit cleanly.

---

## The ten levels

You fight ten bosses in sequence. Defeat each NM to unlock the next. Level 10 (Shinryu) is the final trial — clear it to earn the jackpot and join the Hall of Champions.

<!-- DOCGEN:BEGIN id="gauntlet-levels" -->
| Level | NM | Mob level | HP |
|---:|---|---:|---:|
| 1 | **Aquarius** | 99 | 5.0M |
| 2 | **Serket** | 99 | 5.8M |
| 3 | **Simurgh** | 99 | 6.8M |
| 4 | **Nidhogg** | 99 | 7.9M |
| 5 | **King Behemoth** | 99 | 9.2M |
| 6 | **Vrtra** | 99 | 10.8M |
| 7 | **Kirin** | 99 | 12.6M |
| 8 | **Absolute Virtue** | 99 | 14.7M |
| 9 | **Pandemonium Warden** | 99 | 17.1M |
| 10 | **Shinryu** *(final)* | 99 | 19.9M |

HP grows **16.6%** each level. Every NM is **Lv99**; difficulty scales through stats and hardcore mechanics.
<!-- DOCGEN:END id="gauntlet-levels" -->

---

## Combat mechanics

<!-- DOCGEN:BEGIN id="gauntlet-mechanics" -->
Every Gauntlet NM has the same shared hardcore kit, scaled by level. All of these are real combat interactions — no invisible phantom damage.

| Mechanic | What it does |
|---|---|
| **Massive stats** | ATT, ACC, DEF, MDEF, and MEVA all scale steeply per level. Even gear-capped characters will feel the wall. |
| **Enrage timer** | After a set time the boss gains additional ATT and haste permanently. Ranges from ~155s at low levels to ~80s at level 10. |
| **Stance cycling** | The boss periodically shifts between a physical-resist stance (-50% physical damage) and a magic-resist stance (-50% magic damage). Watch the chat log and adapt. |
| **Hold-fire windows** | A warning announces a danger period. If you deal damage during it, you take a status effect penalty (curse, poison, or blind depending on the boss). Wait for the window to expire to earn a defense-down bonus on the boss. |
| **Crowd control** | Periodic Terror or Silence pulses. Duration scales with level. |
| **Self-heal drain** | The boss heals itself every 15 seconds. Heal amount scales from 1k at level 1 to 10k at level 10. |
| **Phase actions** | At HP thresholds the boss dispels your buffs or enters a fury state (more ATT + haste). Higher levels have more phases. |
| **Ranged penalty** | Ranged damage is reduced by 50% outside of hold-fire weakness windows. Physical ranged is the intended way to use hold-fire timing. |

!!! warning "Silence on Kirin (7) and Pandemonium Warden (9)"
    Both bosses have reduced Silence resistance (-75%). Silence is the intended way to interrupt their spell rotations.
<!-- DOCGEN:END id="gauntlet-mechanics" -->

### Level-specific behaviour

<!-- DOCGEN:BEGIN id="gauntlet-boss-overrides" -->
Some levels also override specific TP moves:

| Level | NM | Notable override |
|---|---|---|
| 2 | Serket | Earthbreaker → magical earth damage + stun (10s), capped at 4,500 |
| 4 | Nidhogg | Spike Flail → 3-hit physical, minimum 12,000 per use; Absolute Terror → 10–15s Terror |
| 5 | King Behemoth | Meteor → magical damage capped at 6,500, on a 60s recast |
| 6 | Vrtra | Spike Flail → 3-hit physical, minimum 12,000 per use; Sable Breath → dark breath damage to the front arc (~20% max HP), capped at 7,000 |
| 7 | Kirin | Deadly Hold and Tail-type moves bypass parry; Stonega IV / Stone V / Quake capped at 5,000 |
| 8 | Absolute Virtue | Medusa Javelin → physical + Bind 8s (replaces retail Petrify) |
<!-- DOCGEN:END id="gauntlet-boss-overrides" -->

---

## Per-level rewards

Defeating an NM at levels 1–9 pays out immediately. You do **not** need to clear level 10 to keep these.

<!-- DOCGEN:BEGIN id="gauntlet-level-rewards" -->
| Level | NM | Gil | PP | Infamy | Milestone bonus |
|---:|---|---:|---:|---:|---|
| 1 | Aquarius | 50k | 1 | 10 | — |
| 2 | Serket | 100k | 2 | 20 | — |
| 3 | Simurgh | 150k | 3 | 30 | +250k gil, +25 PP, +25 Infamy |
| 4 | Nidhogg | 200k | 4 | 40 | — |
| 5 | King Behemoth | 250k | 5 | 50 | — |
| 6 | Vrtra | 300k | 6 | 60 | +750k gil, +75 PP, +75 Infamy |
| 7 | Kirin | 350k | 7 | 70 | — |
| 8 | Absolute Virtue | 400k | 8 | 80 | — |
| 9 | Pandemonium Warden | 450k | 9 | 90 | +1.5M gil, +150 PP, +150 Infamy |

Each NM kill in levels 1–9 grants a per-level reward. Milestone bonuses stack on top at levels 3, 6, and 9.
<!-- DOCGEN:END id="gauntlet-level-rewards" -->

---

## Milestone bonuses

<!-- DOCGEN:BEGIN id="gauntlet-milestones" -->
| Milestone | NM | Bonus gil | Bonus PP | Bonus Infamy |
|---:|---|---:|---:|---:|
| Level 3 | Simurgh | 250k | 25 | 25 |
| Level 6 | Vrtra | 750k | 75 | 75 |
| Level 9 | Pandemonium Warden | 1.5M | 150 | 150 |

Milestone bonuses are paid immediately after the per-level reward when you defeat the milestone NM.
<!-- DOCGEN:END id="gauntlet-milestones" -->

---

## Level 10: Shinryu

After clearing all nine levels Shinryu is the only thing left. Approach the **Final Trial** NPC in the arena to summon it.

Shinryu carries the full mechCfg kit at maximum intensity: a short enrage (~80s), rapid stance cycling, CC, heavy drain, and multiple phase thresholds including a 10% berserker state. It has **~19.9M HP** and its physical TP moves bypass parry.

There is no clock, no time limit beyond the enrage timer. Defeat it to trigger the jackpot reward and warp back to Purgonorgo Isle.

---

## Final clear reward

<!-- DOCGEN:BEGIN id="gauntlet-rewards" -->
| Reward | Amount |
|---|---:|
| **Gil** | 5,000,000 (5M) |
| **Paragon Points** | 500 |
| **Infamy** | 500 |
| **Hall of Champions NPC** | Permanent |
<!-- DOCGEN:END id="gauntlet-rewards" -->

The reward repeats on every clear — your champion NPC's inscription updates with each new clear count.

---

## Hall of Champions

Every player who defeats Shinryu is memorialized as a named NPC in **Riverne Site B01** — the Hall of Champions. Talk to any champion NPC to see their name and how many times they've cleared The Gauntlet. The hall is visible to all players at any time.

The Hall updates after the next map restart following a clear.

---

!!! info "Commands"
    `!gauntlet abort` — exit your current run (no penalty, just ends the run)  
    `!gauntlet status` *(GM)* — list all active runs  
    `!gauntlet fix <name>` *(GM)* — clear a stuck session and teleport the player home  
    `!gauntlet set <name> <level>` *(GM)* — place a player at a specific level

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 030b1bdd03c7 -->
_Last updated: 2026-07-13 21:48 PDT_
<!-- DOCGEN:END id="last-updated" -->
