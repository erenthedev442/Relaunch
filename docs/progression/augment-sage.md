# Augment Sage

![Arcane eye](../assets/emblems/augment-sage.svg){ .lgnd-emblem }

The **Augment Sage** is the side-quest progression layer on top of the [Augment Moogle](augments.md). Talk to him in GM Home (right next to the Moogle) to pursue **mastery ranks**, **register NM affinities**, and check your boost status. The math he unlocks gets applied automatically the next time you trade catalysts to the Moogle — there's no separate "use this augment" workflow.

!!! warning "What the multipliers actually multiply"
    The "Mastery ×" and crit values on this page boost the **stat numbers written onto your gear** when you augment a piece at the Moogle — they fill an achievement **boost of 0–31** per slot, e.g. an Attack line climbs from **+2/slot fresh to +64/slot** at rank-5 + affinity + crit. They have **no effect on EXP gain, gil drops, or anything outside the augmentation trade itself.** If you want faster leveling, see [Subjob EXP Share](subjob-exp.md) or the EXP rates on [What's Custom](../changes/index.md#rates-at-a-glance).

!!! tip "Summary"
    Two parallel tracks. **Sage Mastery** (5 ranks) raises the achievement boost + crit chance on _every gear augment_. **NM Affinities** (13 bits) add a per-category bonus on top. Stack both to max the 0–31 boost; do neither and every augment sits at its floor.

## Where to find the Sage

<!-- DOCGEN:BEGIN id="sage-location" -->
**Zone:** GM Home  
**Coordinates:** x = -1.50, y = 0.00, z = -25.00  
**Same row as:** the Augment Moogle (talk to either to start a trade or pursue a rank).
<!-- DOCGEN:END id="sage-location" -->

## How the boost is calculated

<!-- DOCGEN:BEGIN id="sage-formula" -->
Every successful augment runs through this math at trade time. The three
Sage ingredients combine into an **achievement boost of 0–31** that is
written onto every augment slot in the trade:

```
mastery   = masteryMult[Augment_Mastery + 1]      -- from Sage rank
affinity  = hasAffinity(category) ? 1.5 : 1.0     -- from NM kills
crit_pct  = critChance[Augment_Mastery + 1]       -- chance per trade
crit      = random() < crit_pct ? 2.0 : 1.0

totalMult = mastery * affinity * crit
progress  = (totalMult - 1) / (6.0 - 1)        -- 0.0 .. 1.0
boost     = round(progress * 31)                  -- written per slot

per_slot  = (base + boost) * multiplier           -- the engine formula
```

**Floor** (rank 0, no affinity, no crit): boost = 0, so each slot lands at
`base × multiplier` — the augment's minimum value.

**Cap** (rank 5, affinity held, crit lands): `2.0 × 1.5 × 2.0 = 6.0` maxes the boost at **31**, so each slot lands at `(base + 31) × multiplier` — the augment's ceiling. The [catalog table](augments.md#catalyst--augment-catalog) lists every augment's Fresh (floor) and Max (cap) values per trade size.
<!-- DOCGEN:END id="sage-formula" -->

!!! warning "Item examine window shows garbled values — use !augstats"
    Once Sage multipliers push your per-slot values up, the FFXI client's item examine window will start showing nonsense (commonly a large negative number). **The stat is being applied correctly.** Use **`!augstats`** in-game to see your true augment numbers. See the [Known Display Limitation](augments.md#known-display-limitation) section on the Augment Moogle page for a full explanation.

## Track 1 — Sage Mastery ranks

Promotion is a one-time trade per rank. The Sage shows your live progress on the in-game menu (e.g. `Augs 12/10`, `Bronze 7/5`, `Behemoth Horn 1/1`). When all three requirements are met, the `>> Promote to {title}` row becomes the actionable step — pick it to consume the seal + trophy and bump your rank.

<!-- DOCGEN:BEGIN id="sage-ranks" -->
| Rank | Title | Mastery × | Crit chance | Augments | Seals | NM Trophy |
|---:|---|---:|---:|---:|---|---|
| 0 | Unranked | 1.00x | 5% | — | — | — |
| 1 | Augment Initiate | 1.20x | 8% | 10 lifetime | 5 × Beastmens Medal (Bronze) | 1 × Behemoth Horn (drops from **Behemoth**) |
| 2 | Augment Adept | 1.40x | 11% | 20 lifetime | 10 × Kindreds Medal (Silver) | 1 × Handful of Nidhogg's Scales (drops from **Nidhogg**) |
| 3 | Augment Magus | 1.60x | 14% | 50 lifetime | 25 × Kindreds Medal (Silver) | 1 × Khimaira Horn (drops from **Khimaira (Tiamat-tier dragon)**) |
| 4 | Augment Sage | 1.80x | 17% | 120 lifetime | 50 × Demons Medal (Gold) | 1 × Fafnir's Scale (drops from **Fafnir**) |
| 5 | Augment Archon | 2.00x | 20% | 250 lifetime | 100 × Demons Medal (Gold) | 1 × Kirin's Mane (drops from **Kirin (sky-god proxy for Absolute Virtue)**) |

_Augments-required counts the **total lifetime successful augments** the player has crafted at the Augment Moogle (tracked via `Augment_Count` charvar). Trophies + seals are **consumed** on promotion._
<!-- DOCGEN:END id="sage-ranks" -->

The `Augment_Count` charvar is bumped by **+1 every time you confirm an augmentation at the Augment Moogle**. Cancelled trades and failed trades do not count.

## Track 2 — NM Affinities

Each augment in the catalog has a thematic `cat` (1–13). Defeating the signature NM for that category and trading its trophy at the Sage's _Register NM Affinity_ menu permanently sets the matching bit in your `Augment_Affinities` charvar. From that point on, any augment whose category matches one of your held affinities gets the bonus multiplier.

You can register affinities in any order, at any rank. The trophy is single-use per affinity — once the bit is yours, the same NM's drops behave normally again (no double-registering).

<!-- DOCGEN:BEGIN id="sage-affinities" -->
Holding an affinity multiplies augments **in that category** by **1.5×**. Affinities stack with Sage Mastery and crit. Register an affinity by trading the corresponding NM drop to the Augment Sage's _Register NM Affinity_ menu — the trophy is consumed and the bit is yours forever.

| Cat | Category | NM | Trophy | Catalysts available |
|---:|---|---|---|---:|
| 1 | Strength / Attack | Behemoth | Giant Femur | 37 |
| 2 | Dexterity / Accuracy | King Arthro | Emperor Arthro's Shell | 29 |
| 3 | Vitality / Defense | Adamantoise | Adamantoise Shell | 14 |
| 4 | Agility / Evasion / Haste | Roc | Giant Bird Plume | 44 |
| 5 | Intelligence / Magic offense | Ouryu (Guivre-tier wyrm) | Guivre's Skull | 27 |
| 6 | Mind / Healing / Cure | Phoenix | Phoenix Feather | 7 |
| 7 | Charisma / Charm / Enmity | Lady Lilith (Khimaira-tier charmer) | Khimaira Mane | 12 |
| 8 | HP / Regen | Fafnir | Wyvern Skin | 6 |
| 9 | MP / Refresh | Vrtra | Vial of Dragon Blood | 3 |
| 10 | Pet | King Vinegarroon | Sand Bat Fang | 10 |
| 11 | Elemental resistance | Khimaira | Khimaira Horn | 71 |
| 12 | Skill+ | Maat (proxy: a king-tier predator) | Gargantuan Black Tiger Fang | 33 |
| 13 | Weaponskill DMG+ | Tiamat | High-Quality Scorpion Shell | 5 |
<!-- DOCGEN:END id="sage-affinities" -->

## Charvars used

| Name | Range | Purpose |
|---|---|---|
| `Augment_Mastery`    | 0–5            | Highest Sage rank cleared. Drives the global multiplier + crit chance. |
| `Augment_Affinities` | 13-bit field   | One bit per registered NM affinity. Drives the per-category bonus. |
| `Augment_Count`      | 0–N            | Lifetime successful augments. Drives rank-up eligibility. |

These three charvars are independent — nothing else on the server reads or writes them. You can inspect a player's progress with `!charvar Augment_Mastery` etc. from a GM account.

## FAQ

**Do I need to register affinities to use the Augment Moogle?**
No. With every charvar at default 0, the boost is 0 and each augment lands at its floor — `base × multiplier` per slot. The Sage system is purely additive.

**Does the crit affect just one augment in the trade, or all of them?**
All of them. The crit is rolled **once per trade**, before the catalysts are processed. If it lands, the achievement boost jumps sharply for every selection in that trade (a crit is one of the three ingredients of a maxed augment). If it doesn't, none of them get it. The Moogle prints `** Critical augment! **` so you know before you confirm.

**What if I trade 5 catalysts from different categories?**
Each catalyst's augment is calculated independently for affinity (so only the categories you have affinity for get the 1.5× boost), but the mastery multiplier and crit apply to all of them.

**Can I rank down or unregister an affinity?**
No. Mastery and affinities are one-way. They're permanent rewards for completing the content.

**Are the trophy items consumed?**
Yes — both the Sage rank trophy and the affinity registration trophy are removed from inventory on success. You'll need to farm the NM again to do anything else with those items.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 38b7c4416eb8 -->
_Last updated: 2026-06-23 08:54 UTC_
<!-- DOCGEN:END id="last-updated" -->
