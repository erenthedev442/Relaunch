# Augment Sage

![Arcane eye](../assets/emblems/augment-sage.svg){ .lgnd-emblem }

The **Augment Sage** is the side-quest progression layer on top of the [Augment Moogle](augments.md). Talk to him in Leafallia (`!leaf`, right next to the Moogle) to pursue **mastery ranks**, **register NM affinities**, and check your boost status. The math he unlocks gets applied automatically the next time you trade catalysts to the Moogle — there's no separate "use this augment" workflow.

!!! warning "What the multipliers actually multiply"
    The "Mastery ×" and crit values on this page boost the **stat numbers written onto your gear** when you augment a piece at the Moogle — they fill an achievement **boost of 0–31** per slot, e.g. an Attack line climbs from **+2/slot fresh to +64/slot** at rank-5 + affinity + crit. They have **no effect on EXP gain, gil drops, or anything outside the augmentation trade itself.** If you want faster leveling, see [Subjob EXP Share](subjob-exp.md) or the EXP rates on [Retail Differences](../changes/index.md#rates-at-a-glance).

!!! tip "Summary"
    Two parallel tracks. **Sage Mastery** (5 ranks) raises the achievement boost + crit chance on _every gear augment_. **NM Affinities** (24 bits) add a per-category bonus on top. Stack both to max the 0–31 boost; do neither and every augment sits at its floor.

## Where to find the Sage

<!-- DOCGEN:BEGIN id="sage-location" -->
**Zone:** Leafallia  
**Coordinates:** x = -16.00, y = 0.00, z = 10.00  
**Same row as:** the Augment Moogle (talk to either to start a trade or pursue a rank).
<!-- DOCGEN:END id="sage-location" -->

## How the boost is calculated

<!-- DOCGEN:BEGIN id="sage-formula" -->
Every augment line is **rolled** at trade time. Your **Augment Tier**
(1–5, gated by custom content) picks a band of the 0–31 roll space, and
every catalyst in the trade rolls its own number inside that band:

```
tier   = your Augment Tier (content ladder below)
band   = T1 0–5 | T2 6–11 | T3 12–17 | T4 18–24 | T5 25–31

floor  = band.min + sageRank              -- mastery rank lifts bad rolls
roll   = random(floor .. band.max)        -- rolled PER SLOT
affinity held (category match)  ->  roll twice, keep the better
crit (5%–30% by rank; Maat's Cap guarantees)  ->  roll = band.max (PERFECT)

per_slot = (base + roll) * multiplier     -- the engine formula
```

**The tier ladder** — every step (including Tier 1) is custom content; your
tier is the highest step you've cleared **consecutively** (you can't skip
ahead). A fresh character is **Tier 0: the Moogle won't augment at all**
until the first gate is cleared:

| Tier | Roll band | Unlock |
|---:|---|---|
| 1 | 0–5 | slay your first 10 custom NMs (Hunting League, Wave Mode, Voidspire...) |
| 2 | 6–11 | reach Hunting League Rank 5 |
| 3 | 12–17 | clear Voidspire floor 10 + every Game Master wave difficulty |
| 4 | 18–24 | clear a Dynamis - Divergence city |
| 5 | 25–31 | defeat Maat's Echo (Ru'Lude Gardens, !maat) |

**Floor** (T1, rank 0): a roll can land 0 — `base × multiplier`, the
augment's minimum value. (At **Tier 0** — before the first gate — the
Moogle refuses the trade entirely.)

**Ceiling** (T5 + a max roll): `(base + 31) × multiplier` — identical to the old rank-5 + affinity + crit cap, so existing gear is never power-crept. Tier bands never overlap: any T3 roll beats every T2 roll. The [catalog table](augments.md#catalyst--augment-catalog) lists every augment's Fresh (floor) and Max (cap) values per trade size.
<!-- DOCGEN:END id="sage-formula" -->

!!! warning "Item examine window shows garbled values — use !augstats"
    Once Sage multipliers push your per-slot values up, the FFXI client's item examine window will start showing nonsense (commonly a large negative number). **The stat is being applied correctly.** Use **`!augstats`** in-game to see your true augment numbers. See the [Known Display Limitation](augments.md#known-display-limitation) section on the Augment Moogle page for a full explanation.

## Track 1 — Sage Mastery ranks

Promotion is a free, one-time step per rank — gated on **content milestones**, not consumables. The Sage shows your live progress on the in-game menu (e.g. `HL Rank 2/3`, `Prestige 12/15`). Once you reach the required Hunting League Rank and/or Prestige Level, the `>> Promote to {title}` row becomes the actionable step — pick it to bump your rank. No seals, trophies, or augment counts are spent.

<!-- DOCGEN:BEGIN id="sage-ranks" -->
| Rank | Title | Roll floor | Crit chance | Hunting League Rank | Prestige Level |
|---:|---|---:|---:|---:|---:|
| 0 | Unranked | +0 | 5% | — | — |
| 1 | Augment Initiate | +1 | 10% | 2 | — |
| 2 | Augment Adept | +2 | 15% | 3 | — |
| 3 | Augment Magus | +3 | 20% | 5 | 5 |
| 4 | Augment Sage | +4 | 25% | — | 15 |
| 5 | Augment Archon | +5 | 30% | — | 30 |

_Ranks are **content milestones** — each unlocks automatically once you reach the listed Hunting League Rank and/or Prestige Level. Nothing is consumed: no seals, trophies, or augment counts._
<!-- DOCGEN:END id="sage-ranks" -->

The `Augment_Count` charvar is bumped by **+1 every time you confirm an augmentation at the Augment Moogle**. Cancelled trades and failed trades do not count.

## Track 2 — NM Affinities

Each augment in the catalog has a thematic category, unlocked by a **signature NM**. Defeating that NM drops its **unique trophy**; bring the trophy to the Augment Sage's _Register NM Affinity_ menu to permanently unlock the affinity. Registration **costs Hunting League Rank 3 and 1,000 Hunt Marks**, and consumes the trophy. From that point on, any augment whose category matches one of your unlocked affinities gets the bonus multiplier.

You can register affinities in any order once you reach Hunting League Rank 3 — each costs 1,000 Hunt Marks plus the NM's trophy. Affinities are permanent once registered. In the menu, **[ ]** means locked, **[!]** means you're holding that NM's trophy and can register it, and **[*]** means already unlocked.

<!-- DOCGEN:BEGIN id="sage-affinities" -->
Holding an affinity gives augments **in that category** roll advantage: the Moogle **rolls twice and keeps the better** result. It stacks with the Sage-rank roll floor and crits. Each NM drops a unique trophy; register the affinity at the Augment Sage's _Register NM Affinity_ menu — it requires **Hunting League Rank 3** and costs **1,000 Hunt Marks**, and the trophy is consumed.

| Cat | Category | NM | Trophy | Catalysts available |
|---:|---|---|---|---:|
| 1 | STR | Behemoth | Behemoth Hide | 5 |
| 2 | Attack | King_Behemoth | Behemoth Horn | 12 |
| 3 | DEX | King_Arthro | Emperor Arthro's Shell | 8 |
| 4 | Accuracy | Simurgh | Giant Bird Plume | 7 |
| 5 | VIT | Adamantoise | Adamantoise Shell | 1 |
| 6 | Defense | Genbu | Seal of Genbu | 14 |
| 7 | AGI | Roc | Giant Bird Feather | 2 |
| 8 | Evasion | Seiryu | Seal of Seiryu | 3 |
| 9 | Haste | Byakko | Seal of Byakko | 7 |
| 10 | INT | Aspidochelone | Spirit Turtle Shell | 3 |
| 11 | Magic ATK | Ouryu | Dragon Talon | 30 |
| 12 | MND | Bune | Vial of Chimera Blood | 1 |
| 13 | Healing | Phoenix | Phoenix Feather | 8 |
| 14 | CHR | Suzaku | Seal of Suzaku | 7 |
| 15 | Enmity | Kirin | Kirin's Mane | 2 |
| 16 | HP | Fafnir | Fafnir's Scale | 2 |
| 17 | Regen | Nidhogg | Handful of Nidhogg's Scales | 3 |
| 18 | MP | Vrtra | Wyrm Beard | 2 |
| 19 | Refresh | Tiamat | Wyrm Horn | 2 |
| 20 | Pet | King_Vinegarroon | Scorpion Stinger | 54 |
| 21 | Ele Resist | Khimaira | Khimaira Mane | 10 |
| 22 | Status | Cerberus | Cerberus Hide | 1 |
| 23 | Skills | Absolute_Virtue | Attestation of Virtue | 39 |
| 24 | WSD+ | Proto-Omega | Omega Ring | 4 |
<!-- DOCGEN:END id="sage-affinities" -->

## Charvars used

| Name | Range | Purpose |
|---|---|---|
| `Augment_Mastery`    | 0–5            | Highest Sage rank cleared. Drives the global multiplier + crit chance. |
| `Augment_Affinities` | 24-bit field   | One bit per registered NM affinity. Drives the per-category bonus. |
| `Augment_Count`      | 0–N            | Lifetime successful augments. Tracked for reference; no longer gates rank-up. |

These three charvars are independent — nothing else on the server reads or writes them. You can inspect a player's progress with `!charvar Augment_Mastery` etc. from a GM account.

## FAQ

**Do I need to register affinities to use the Augment Moogle?**
No. With every charvar at default 0, the boost is 0 and each augment lands at its floor — `base × multiplier` per slot. The Sage system is purely additive.

**Does the crit affect just one augment in the trade, or all of them?**
All of them. The crit is rolled **once per trade**, before the catalysts are processed. If it lands, the achievement boost jumps sharply for every selection in that trade (a crit is one of the three ingredients of a maxed augment). If it doesn't, none of them get it. The Moogle prints `** Critical augment! **` so you know before you confirm.

**What if I trade 5 catalysts from different categories?**
Each catalyst's augment is calculated independently for affinity (so only the categories you have affinity for get the roll-twice-keep-the-better-result bonus), but the mastery multiplier and crit apply to all of them.

**Can I rank down or unregister an affinity?**
No. Mastery and affinities are one-way. They're permanent rewards for completing the content.

**Are the trophy items consumed?**
Only the **affinity registration** trophy (Track 2) is removed from inventory on success. **Sage Mastery ranks (Track 1) consume nothing** — they unlock automatically from Hunting League Rank and Prestige Level milestones.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 426d06064c84 -->
_Last updated: 2026-06-29 04:48 UTC_
<!-- DOCGEN:END id="last-updated" -->
