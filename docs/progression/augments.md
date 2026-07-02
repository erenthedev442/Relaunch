# Augment Moogle

![Augment gem](../assets/emblems/augment.svg){ .lgnd-emblem }

The **Augment Moogle** at <!--npc:augment_moogle-->Leafallia<!--/npc--> lets you stamp custom augments onto any piece of equipment by trading a catalyst item that maps 1:1 to a specific augment.

!!! tip "Summary"
    Talk to the **Augment Moogle** at <!--npc:augment_moogle-->Leafallia<!--/npc--> (z = -15, in the row with the other moogles). Trade **1 gear piece + 1-5 catalyst items + 10,000 gil**. Each catalyst writes one augment line onto the gear. Up to 5 augments per piece — the engine's 5 augment slots.

## How it works

1. **Pick the augments** you want from the catalog table below.
2. **Acquire the catalyst items** for those augments. Each augment has a unique catalyst — for example, `bismuth_ingot` maps to `HP+1`.
3. **Talk to the Augment Moogle** with the gear piece, the catalysts, and at least **10,000 gil** in your inventory.
4. **Trade** the gear + catalysts. The moogle holds them and shows you what's about to be applied.
5. **Confirm** in the menu. The moogle deducts 10,000 gil and hands the gear back with the augments stamped on it.

Cancel at any time during the confirm menu to get everything (gear + catalysts) back.

## Rules and limits

- **Maximum 5 catalysts per trade.** This matches the engine cap of 5 augment slots per item.
- **Duplicates are allowed — and encouraged.** Each catalyst writes one augment line, so stacking the same catalyst multiplies that stat (5 of one catalyst = 5 lines of that augment), or mix different catalysts on one piece.
- **The catalyst is consumed** on apply. Gear is not consumed; it's stamped and returned.
- **Stacks with existing augments**: the moogle replaces the equipment's exdata block, so any augments already on the piece are overwritten. Bring fresh gear or expect a replacement.

## Known display limitation

!!! warning "Item examine window shows garbled values for boosted augments"
    The FFXI client reads augment data from the packet and looks up each augment ID in its own retail data tables. the Relaunch server uses custom augment IDs whose entries in the retail client table do not match the server's definitions — so the item examine window displays **incorrect values** (often a large negative number) on any piece augmented through the Moogle, especially after Augment Sage multipliers are in play.

    **The actual stat bonus is applied correctly.** Use **`!augstats`** to see your true augment contributions:

    ```
    !augstats
    ```

    This prints every augmented item slot with the real per-slot and total values — for example, 5 × `Attack` catalysts at max Sage rank might display a garbled negative number in the examine window, but `!augstats` will correctly report **+320 Attack total** (64 per slot × 5 slots).

    For total gear stats, use **`!getstats offensive`** / **`!getstats defensive`** / **`!getstats base`** to see your accumulated numbers across all equipment.

## How augment power scales

Custom augments don't apply a fixed value — each one **scales with your [Augment Sage](augment-sage.md) progress**. Every catalyst you trade fills one of a gear piece's augment slots, and each slot's bonus climbs from a low **floor** (no achievements) up to a **cap** (everything maxed), driven by an achievement **boost of 0 → 31** built from three sources:

- **Augment Mastery rank** — the Sage quest, ranks 1–5 (the global multiplier).
- **Category affinity** — defeat the category's signature NM and turn in its trophy at the Sage.
- **A critical augment** — a per-trade roll (5% → 20% as your rank rises) that doubles the boost.

A brand-new augment sits at the floor; only a **rank-5, affinity-unlocked, *critical*** augment reaches the cap. Stack the same catalyst across slots to multiply the result.

| Augment | Per slot (floor → cap) | A full piece (×5 slots) |
|---|---:|---:|
| **HP, MP, Weapon Damage, Regen, Pet: Regen, resting HP/MP recovery** | 4 → **128** | 20 → **640** |
| **Attack, Rng.Attack, Accuracy, Rng.Accuracy, Magic Acc., Magic Acc.+Atk., HP+MP, TP Bonus, Refresh** | 2 → **64** | 10 → **320** |
| *All other augments* | 1 → **32** | 5 → **160** |

*Haste and the damage-taken family display as **percentages** (Haste ≈ 6.25%/slot maxed). Some stats have hard engine ceilings no amount of slots can pass — gear Haste caps at **25%**, total damage taken at **−50%** — see the **Cap** column in the catalog below.*

So a maxed tank reaches **+640 HP on a single body piece**, and a sustain build can stack **+640 Regen** (or **+320 Refresh**) on a piece — but only after grinding the Sage's mastery ranks, unlocking the stat's affinity NM, and landing a crit. The retail-style flat "+97" numbers are gone; power is **earned** through the Sage now.

!!! note "Why a fresh augment looks weak — and what to do about it"
    Your first stamp on a piece gives the **floor** (e.g. HP +4/slot). That's intentional. As your mastery rank climbs, **re-augment the same gear** to push every slot toward its cap. Augment early, augment often, re-augment as you rank up.

!!! tip "See your real values with `!augstats`"
    The item examine window shows garbled numbers (above); `!augstats` reports the true per-slot and total bonus on every augmented piece.

## Catalyst → augment catalog

The table below lists **which catalyst maps to which augment**, organized by tier (T0–T5). Higher tiers drop from tougher monsters and open up as you progress — the top tier (T5) additionally requires a victory in [Maat's Challenge](../endgame/maats-challenge.md). The **Cap** column shows the hard in-game ceiling where one exists — see [how scaling works](#how-augment-power-scales) above.

<!-- DOCGEN:BEGIN id="augment-catalog" -->
_227 catalyst items across 5 tiers. Each drops (~50%) from a specific monster; trade it to the **Augment Moogle in Leafallia** (`!leaf`) to apply the augment. Cost is **10,000 gil flat per trade** plus the catalyst itself. Every line is **rolled** within your [Augment Tier's band](augment-sage.md) — higher tiers roll strictly higher values. The **T1–T5 columns** show the value range of a **full 5-catalyst stack** rolled at that Augment Tier (divide by 5 for one catalyst); an — means that catalyst can't be traded below its own tier. The **Cap** column is the hard engine ceiling for that stat where one exists (e.g. Haste caps at 25%, damage-taken floors at -50%), or **no cap** for additive stats._

### T0 — First 10 NMs slain

Requires **Augment Tier 1** — the Moogle won't augment at all until you **slay your first 10 custom NMs** (Hunting League, Wave Mode, and Voidspire kills all count). These are **job-specific or class-specific** utilities that only meaningfully help a single playstyle: ability delays, pet-ability extensions, proc-chance passives most jobs ignore. Catalysts drop from low-level overworld mobs.

| Augment | Catalyst | Drops from | T1 ×5 | T2 ×5 | T3 ×5 | T4 ×5 | T5 ×5 | Cap | Affinity Category |
|---|---|---|--:|--:|--:|--:|--:|:--:|---|
| Evasion | <a class="item-link" href="https://www.ffxiah.com/item/1617" data-img="https://static.ffxiah.com/images/icon/1617.png" target="_blank" rel="noopener">Flytrap Leaf</a> | — | 15–40 | 45–70 | 75–100 | 105–135 | 140–170 | no cap | Evasion |
| Elemental Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/849" data-img="https://static.ffxiah.com/images/icon/849.png" target="_blank" rel="noopener">Undead Skin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Elemental / Enfeebling / Enhancing magic recast delays |
| Enfeebling Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/859" data-img="https://static.ffxiah.com/images/icon/859.png" target="_blank" rel="noopener">Ram Skin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Elemental / Enfeebling / Enhancing magic recast delays |
| Enhancing Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/868" data-img="https://static.ffxiah.com/images/icon/868.png" target="_blank" rel="noopener">Handful Of Pugil Scales</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Elemental / Enfeebling / Enhancing magic recast delays |
| HP recovered while healing | <a class="item-link" href="https://www.ffxiah.com/item/1122" data-img="https://static.ffxiah.com/images/icon/1122.png" target="_blank" rel="noopener">Wyvern Skin</a> | — | 20–120 | 140–240 | 260–360 | 380–500 | 520–640 | no cap | Regen |
| MP recovered while healing | <a class="item-link" href="https://www.ffxiah.com/item/791" data-img="https://static.ffxiah.com/images/icon/791.png" target="_blank" rel="noopener">Aquamarine</a> | — | 20–120 | 140–240 | 260–360 | 380–500 | 520–640 | no cap | MP |
| Pet TP Bonus | <a class="item-link" href="https://www.ffxiah.com/item/856" data-img="https://static.ffxiah.com/images/icon/856.png" target="_blank" rel="noopener">Rabbit Hide</a> | — | 100–125 | 130–155 | 160–185 | 190–220 | 225–255 | no cap | Pet stats pulled from old cat 1 |
| Pet Enmity | <a class="item-link" href="https://www.ffxiah.com/item/1408" data-img="https://static.ffxiah.com/images/icon/1408.png" target="_blank" rel="noopener">Bottle Of Illuminink</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 7 |
| Pet Enmity | <a class="item-link" href="https://www.ffxiah.com/item/1453" data-img="https://static.ffxiah.com/images/icon/1453.png" target="_blank" rel="noopener">Montiont Silverpiece</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 7 |
| Blood Boon | <a class="item-link" href="https://www.ffxiah.com/item/852" data-img="https://static.ffxiah.com/images/icon/852.png" target="_blank" rel="noopener">Lizard Skin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Core pet utilities (old cat 10) |
| Avatar perpetuation cost | <a class="item-link" href="https://www.ffxiah.com/item/1156" data-img="https://static.ffxiah.com/images/icon/1156.png" target="_blank" rel="noopener">Crawler Calculus</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Core pet utilities (old cat 10) |
| Elemental Siphon | <a class="item-link" href="https://www.ffxiah.com/item/1272" data-img="https://static.ffxiah.com/images/icon/1272.png" target="_blank" rel="noopener">Arioch Fang</a> | — | 25–150 | 175–300 | 325–450 | 475–625 | 650–800 | no cap | Core pet utilities (old cat 10) |
| All elemental resists | <a class="item-link" href="https://www.ffxiah.com/item/1132" data-img="https://static.ffxiah.com/images/icon/1132.png" target="_blank" rel="noopener">Square Of Raxa</a> | — | 50–75 | 80–105 | 110–135 | 140–170 | 175–205 | no cap | Ele Resist |
| Enhances | <a class="item-link" href="https://www.ffxiah.com/item/1850" data-img="https://static.ffxiah.com/images/icon/1850.png" target="_blank" rel="noopener">First Virtue</a> | — | 50–300 | 350–600 | 650–900 | 950–1250 | 1300–1600 | no cap | Element affinities (passive elemental identity, not resists) |
| Exp. Point +33% | <a class="item-link" href="https://www.ffxiah.com/item/2523" data-img="https://static.ffxiah.com/images/icon/2523.png" target="_blank" rel="noopener">Peiste Skin</a> | — | 165–190 | 195–220 | 225–250 | 255–285 | 290–320 | no cap | Exp/Cap points |
| Ninja tool expertise | <a class="item-link" href="https://www.ffxiah.com/item/1269" data-img="https://static.ffxiah.com/images/icon/1269.png" target="_blank" rel="noopener">Mana Barrel</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Job-specific niche utilities |
| Repair potency | <a class="item-link" href="https://www.ffxiah.com/item/2729" data-img="https://static.ffxiah.com/images/icon/2729.png" target="_blank" rel="noopener">Hydrangea</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Job-specific niche utilities |
| Indi Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2641" data-img="https://static.ffxiah.com/images/icon/2641.png" target="_blank" rel="noopener">Amoeban Pseudopod</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Job-specific niche utilities |
| Treasure Hunter | <a class="item-link" href="https://www.ffxiah.com/item/908" data-img="https://static.ffxiah.com/images/icon/908.png" target="_blank" rel="noopener">Adamantoise Shell</a> | — | 5 | 5 | 5 | 5 | 5 | no cap | Job-specific niche utilities |

### T1 — First 10 NMs slain

Requires **Augment Tier 1** — slay your first 10 custom NMs. Practical job abilities and defensive options useful to a wider range of jobs — counter/parry/evasion, spell interruption, elemental affinities, shield tech. Catalysts drop from mid-level mobs.

| Augment | Catalyst | Drops from | T1 ×5 | T2 ×5 | T3 ×5 | T4 ×5 | T5 ×5 | Cap | Affinity Category |
|---|---|---|--:|--:|--:|--:|--:|:--:|---|
| STR | <a class="item-link" href="https://www.ffxiah.com/item/1620" data-img="https://static.ffxiah.com/images/icon/1620.png" target="_blank" rel="noopener">Taurus Horn</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | STR |
| Attack | <a class="item-link" href="https://www.ffxiah.com/item/861" data-img="https://static.ffxiah.com/images/icon/861.png" target="_blank" rel="noopener">Black Tiger Hide</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Attack |
| Rng.Attack | <a class="item-link" href="https://www.ffxiah.com/item/883" data-img="https://static.ffxiah.com/images/icon/883.png" target="_blank" rel="noopener">Behemoth Horn</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Attack |
| Attack Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/874" data-img="https://static.ffxiah.com/images/icon/874.png" target="_blank" rel="noopener">Amaltheia Hide</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Attack |
| Reverse Flourish | <a class="item-link" href="https://www.ffxiah.com/item/1591" data-img="https://static.ffxiah.com/images/icon/1591.png" target="_blank" rel="noopener">High-Quality Coeurl Hide</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Attack |
| DEX | <a class="item-link" href="https://www.ffxiah.com/item/2150" data-img="https://static.ffxiah.com/images/icon/2150.png" target="_blank" rel="noopener">Colibri Feather</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | DEX |
| Zanshin | <a class="item-link" href="https://www.ffxiah.com/item/926" data-img="https://static.ffxiah.com/images/icon/926.png" target="_blank" rel="noopener">Lizard Tail</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | DEX |
| Daken | <a class="item-link" href="https://www.ffxiah.com/item/947" data-img="https://static.ffxiah.com/images/icon/947.png" target="_blank" rel="noopener">Jar Of Firesand</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | DEX |
| Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/846" data-img="https://static.ffxiah.com/images/icon/846.png" target="_blank" rel="noopener">Insect Wing</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Accuracy |
| Rng.Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/847" data-img="https://static.ffxiah.com/images/icon/847.png" target="_blank" rel="noopener">Bird Feather</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Accuracy |
| VIT | <a class="item-link" href="https://www.ffxiah.com/item/773" data-img="https://static.ffxiah.com/images/icon/773.png" target="_blank" rel="noopener">Translucent Rock</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | VIT |
| DEF | <a class="item-link" href="https://www.ffxiah.com/item/881" data-img="https://static.ffxiah.com/images/icon/881.png" target="_blank" rel="noopener">Crab Shell</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Defense |
| DEF | <a class="item-link" href="https://www.ffxiah.com/item/774" data-img="https://static.ffxiah.com/images/icon/774.png" target="_blank" rel="noopener">Purple Rock</a> | — | 50–300 | 350–600 | 650–900 | 950–1250 | 1300–1600 | no cap | Defense |
| Enemy crit. hit rate | <a class="item-link" href="https://www.ffxiah.com/item/3504" data-img="https://static.ffxiah.com/images/icon/3504.png" target="_blank" rel="noopener">Peapuk Wing</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Defense |
| AGI | <a class="item-link" href="https://www.ffxiah.com/item/878" data-img="https://static.ffxiah.com/images/icon/878.png" target="_blank" rel="noopener">Karakul Skin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | AGI |
| Recycle | <a class="item-link" href="https://www.ffxiah.com/item/834" data-img="https://static.ffxiah.com/images/icon/834.png" target="_blank" rel="noopener">Ball Of Saruta Cotton</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | AGI |
| Mag. Evasion | <a class="item-link" href="https://www.ffxiah.com/item/1713" data-img="https://static.ffxiah.com/images/icon/1713.png" target="_blank" rel="noopener">Spool Of Cashmere Thread</a> | — | 15–40 | 45–70 | 75–100 | 105–135 | 140–170 | no cap | Evasion |
| Haste | <a class="item-link" href="https://www.ffxiah.com/item/820" data-img="https://static.ffxiah.com/images/icon/820.png" target="_blank" rel="noopener">Spool Of Wool Thread</a> | — | 0–5 | 5–10 | 15–20 | 20–25 | 25–30 | +25% | Haste |
| INT | <a class="item-link" href="https://www.ffxiah.com/item/921" data-img="https://static.ffxiah.com/images/icon/921.png" target="_blank" rel="noopener">Bottle Of Ahriman Tears</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | INT |
| Enhancing Magic Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2510" data-img="https://static.ffxiah.com/images/icon/2510.png" target="_blank" rel="noopener">Orc Helmet</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | INT |
| Mag. Acc | <a class="item-link" href="https://www.ffxiah.com/item/886" data-img="https://static.ffxiah.com/images/icon/886.png" target="_blank" rel="noopener">Demon Skull</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Magic ATK |
| Fast Cast | <a class="item-link" href="https://www.ffxiah.com/item/2427" data-img="https://static.ffxiah.com/images/icon/2427.png" target="_blank" rel="noopener">Wivre Maul</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Drain/Aspir Potency | <a class="item-link" href="https://www.ffxiah.com/item/2943" data-img="https://static.ffxiah.com/images/icon/2943.png" target="_blank" rel="noopener">Balaur Skull</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Spell interruption rate down 1% | <a class="item-link" href="https://www.ffxiah.com/item/854" data-img="https://static.ffxiah.com/images/icon/854.png" target="_blank" rel="noopener">Cockatrice Skin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Spell Interruption Rate Down 2% | <a class="item-link" href="https://www.ffxiah.com/item/2834" data-img="https://static.ffxiah.com/images/icon/2834.png" target="_blank" rel="noopener">Immortal Molt</a> | — | 10–35 | 40–65 | 70–95 | 100–130 | 135–165 | no cap | Magic ATK |
| MND | <a class="item-link" href="https://www.ffxiah.com/item/888" data-img="https://static.ffxiah.com/images/icon/888.png" target="_blank" rel="noopener">Seashell</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | MND |
| Cure potency | <a class="item-link" href="https://www.ffxiah.com/item/833" data-img="https://static.ffxiah.com/images/icon/833.png" target="_blank" rel="noopener">Clump Of Moko Grass</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Healing |
| Potency of Cure received | <a class="item-link" href="https://www.ffxiah.com/item/887" data-img="https://static.ffxiah.com/images/icon/887.png" target="_blank" rel="noopener">Coral Fragment</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Healing |
| Healing magic skill | <a class="item-link" href="https://www.ffxiah.com/item/792" data-img="https://static.ffxiah.com/images/icon/792.png" target="_blank" rel="noopener">Pearl</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Healing |
| Waltz potency | <a class="item-link" href="https://www.ffxiah.com/item/1741" data-img="https://static.ffxiah.com/images/icon/1741.png" target="_blank" rel="noopener">High-Quality Eft Skin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Healing |
| Healing Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/838" data-img="https://static.ffxiah.com/images/icon/838.png" target="_blank" rel="noopener">Spider Web</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Healing |
| CHR | <a class="item-link" href="https://www.ffxiah.com/item/2841" data-img="https://static.ffxiah.com/images/icon/2841.png" target="_blank" rel="noopener">Ingot Of Quadav Silver</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | CHR |
| Charm | <a class="item-link" href="https://www.ffxiah.com/item/902" data-img="https://static.ffxiah.com/images/icon/902.png" target="_blank" rel="noopener">Demon Horn</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | CHR |
| Resist Charm | <a class="item-link" href="https://www.ffxiah.com/item/2372" data-img="https://static.ffxiah.com/images/icon/2372.png" target="_blank" rel="noopener">Khimaira Mane</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | CHR |
| Song recast delay | <a class="item-link" href="https://www.ffxiah.com/item/817" data-img="https://static.ffxiah.com/images/icon/817.png" target="_blank" rel="noopener">Spool Of Grass Thread</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | CHR |
| Song spellcasting time | <a class="item-link" href="https://www.ffxiah.com/item/2827" data-img="https://static.ffxiah.com/images/icon/2827.png" target="_blank" rel="noopener">Spool Of Rugged Gold Thread</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | CHR |
| Gilfinder | <a class="item-link" href="https://www.ffxiah.com/item/1858" data-img="https://static.ffxiah.com/images/icon/1858.png" target="_blank" rel="noopener">Moblumin Ingot</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | CHR |
| Enmity | <a class="item-link" href="https://www.ffxiah.com/item/787" data-img="https://static.ffxiah.com/images/icon/787.png" target="_blank" rel="noopener">Diamond</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Enmity |
| Enmity | <a class="item-link" href="https://www.ffxiah.com/item/901" data-img="https://static.ffxiah.com/images/icon/901.png" target="_blank" rel="noopener">Venomous Claw</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Enmity |
| HP | <a class="item-link" href="https://www.ffxiah.com/item/860" data-img="https://static.ffxiah.com/images/icon/860.png" target="_blank" rel="noopener">Behemoth Hide</a> | — | 20–120 | 140–240 | 260–360 | 380–500 | 520–640 | no cap | HP |
| Regen Potency | <a class="item-link" href="https://www.ffxiah.com/item/850" data-img="https://static.ffxiah.com/images/icon/850.png" target="_blank" rel="noopener">Square Of Sheep Leather</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Regen |
| MP | <a class="item-link" href="https://www.ffxiah.com/item/841" data-img="https://static.ffxiah.com/images/icon/841.png" target="_blank" rel="noopener">Yagudo Feather</a> | — | 20–120 | 140–240 | 260–360 | 380–500 | 520–640 | no cap | MP |
| Refresh | <a class="item-link" href="https://www.ffxiah.com/item/919" data-img="https://static.ffxiah.com/images/icon/919.png" target="_blank" rel="noopener">Clump Of Boyahda Moss</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Refresh |
| Conserve MP | <a class="item-link" href="https://www.ffxiah.com/item/1119" data-img="https://static.ffxiah.com/images/icon/1119.png" target="_blank" rel="noopener">Tonberry Coat</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Refresh |
| Pet Attack Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/1615" data-img="https://static.ffxiah.com/images/icon/1615.png" target="_blank" rel="noopener">Buffalo Horn</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet Dbl.Atk. Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/1718" data-img="https://static.ffxiah.com/images/icon/1718.png" target="_blank" rel="noopener">Megalobugard Tusk</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet Damage taken | <a class="item-link" href="https://www.ffxiah.com/item/786" data-img="https://static.ffxiah.com/images/icon/786.png" target="_blank" rel="noopener">Ruby</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/853" data-img="https://static.ffxiah.com/images/icon/853.png" target="_blank" rel="noopener">Raptor Skin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet Phys. dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/855" data-img="https://static.ffxiah.com/images/icon/855.png" target="_blank" rel="noopener">Square Of Black Tiger Leather</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet Dbl.Att | <a class="item-link" href="https://www.ffxiah.com/item/857" data-img="https://static.ffxiah.com/images/icon/857.png" target="_blank" rel="noopener">Dhalmel Hide</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet Magic Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/863" data-img="https://static.ffxiah.com/images/icon/863.png" target="_blank" rel="noopener">Coeurl Hide</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet STR DEX VIT | <a class="item-link" href="https://www.ffxiah.com/item/2169" data-img="https://static.ffxiah.com/images/icon/2169.png" target="_blank" rel="noopener">Cerberus Hide</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 1 |
| Pet Accuracy Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/922" data-img="https://static.ffxiah.com/images/icon/922.png" target="_blank" rel="noopener">Bat Wing</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/935" data-img="https://static.ffxiah.com/images/icon/935.png" target="_blank" rel="noopener">Ahriman Wing</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet Enemy crit. hit rate | <a class="item-link" href="https://www.ffxiah.com/item/939" data-img="https://static.ffxiah.com/images/icon/939.png" target="_blank" rel="noopener">Hecteyes Eye</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet Accuracy Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/1124" data-img="https://static.ffxiah.com/images/icon/1124.png" target="_blank" rel="noopener">Wyvern Wing</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/1288" data-img="https://static.ffxiah.com/images/icon/1288.png" target="_blank" rel="noopener">Wooden Hakutaku Eye</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet Store TP | <a class="item-link" href="https://www.ffxiah.com/item/1289" data-img="https://static.ffxiah.com/images/icon/1289.png" target="_blank" rel="noopener">Burning Hakutaku Eye</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet Subtle Blow | <a class="item-link" href="https://www.ffxiah.com/item/1290" data-img="https://static.ffxiah.com/images/icon/1290.png" target="_blank" rel="noopener">Earthen Hakutaku Eye</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet DEX | <a class="item-link" href="https://www.ffxiah.com/item/2842" data-img="https://static.ffxiah.com/images/icon/2842.png" target="_blank" rel="noopener">Flawed Garnet</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 2 |
| Pet DEF | <a class="item-link" href="https://www.ffxiah.com/item/2854" data-img="https://static.ffxiah.com/images/icon/2854.png" target="_blank" rel="noopener">Stately Crab Shell</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 3 |
| Pet Mag.Def.Bns | <a class="item-link" href="https://www.ffxiah.com/item/768" data-img="https://static.ffxiah.com/images/icon/768.png" target="_blank" rel="noopener">Flint Stone</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 3 |
| Pet Magic Dmg. Taken | <a class="item-link" href="https://www.ffxiah.com/item/775" data-img="https://static.ffxiah.com/images/icon/775.png" target="_blank" rel="noopener">Black Rock</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Pet stats pulled from old cat 3 |
| Pet VIT | <a class="item-link" href="https://www.ffxiah.com/item/803" data-img="https://static.ffxiah.com/images/icon/803.png" target="_blank" rel="noopener">Sunstone</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 3 |
| Pet Evasion | <a class="item-link" href="https://www.ffxiah.com/item/825" data-img="https://static.ffxiah.com/images/icon/825.png" target="_blank" rel="noopener">Square Of Cotton Cloth</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 4 |
| Pet Mag. Evasion | <a class="item-link" href="https://www.ffxiah.com/item/827" data-img="https://static.ffxiah.com/images/icon/827.png" target="_blank" rel="noopener">Square Of Wool Cloth</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 4 |
| Pet AGI | <a class="item-link" href="https://www.ffxiah.com/item/1861" data-img="https://static.ffxiah.com/images/icon/1861.png" target="_blank" rel="noopener">Moblin Sheepskin</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 4 |
| Pet Mag.Acc | <a class="item-link" href="https://www.ffxiah.com/item/914" data-img="https://static.ffxiah.com/images/icon/914.png" target="_blank" rel="noopener">Vial Of Mercury</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 5 |
| Pet Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/954" data-img="https://static.ffxiah.com/images/icon/954.png" target="_blank" rel="noopener">Magic Pot Shard</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 5 |
| Pet Mag.Acc. Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/1518" data-img="https://static.ffxiah.com/images/icon/1518.png" target="_blank" rel="noopener">Colossal Skull</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 5 |
| Avatar Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/1521" data-img="https://static.ffxiah.com/images/icon/1521.png" target="_blank" rel="noopener">Vial Of Slime Juice</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 5 |
| Pet Mag.Acc. Mag.Dmg | <a class="item-link" href="https://www.ffxiah.com/item/2157" data-img="https://static.ffxiah.com/images/icon/2157.png" target="_blank" rel="noopener">Imp Horn</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 5 |
| Pet Magic Damage | <a class="item-link" href="https://www.ffxiah.com/item/2163" data-img="https://static.ffxiah.com/images/icon/2163.png" target="_blank" rel="noopener">Imp Wing</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 5 |
| Pet INT | <a class="item-link" href="https://www.ffxiah.com/item/2847" data-img="https://static.ffxiah.com/images/icon/2847.png" target="_blank" rel="noopener">Blue Jasper</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 5 |
| Pet MND | <a class="item-link" href="https://www.ffxiah.com/item/2198" data-img="https://static.ffxiah.com/images/icon/2198.png" target="_blank" rel="noopener">Water Spiders Web</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 6 |
| Pet CHR | <a class="item-link" href="https://www.ffxiah.com/item/2850" data-img="https://static.ffxiah.com/images/icon/2850.png" target="_blank" rel="noopener">Ingot Of Sahagin Gold</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 7 |
| Pet Regen | <a class="item-link" href="https://www.ffxiah.com/item/1133" data-img="https://static.ffxiah.com/images/icon/1133.png" target="_blank" rel="noopener">Vial Of Dragon Blood</a> | — | 20–120 | 140–240 | 260–360 | 380–500 | 520–640 | no cap | Pet stats pulled from old cat 8 |
| Pet Acc R.Acc Atk. R.Atk | <a class="item-link" href="https://www.ffxiah.com/item/839" data-img="https://static.ffxiah.com/images/icon/839.png" target="_blank" rel="noopener">Piece Of Crawler Cocoon</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Core pet utilities (old cat 10) |
| Summoning magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1015" data-img="https://static.ffxiah.com/images/icon/1015.png" target="_blank" rel="noopener">Sand Bat Fang</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Core pet utilities (old cat 10) |
| Avatar Blood Pact Dmg | <a class="item-link" href="https://www.ffxiah.com/item/1445" data-img="https://static.ffxiah.com/images/icon/1445.png" target="_blank" rel="noopener">Freyas Tear</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Core pet utilities (old cat 10) |
| Pet Phy. Dmg. Taken | <a class="item-link" href="https://www.ffxiah.com/item/1979" data-img="https://static.ffxiah.com/images/icon/1979.png" target="_blank" rel="noopener">Cup Of Leech Saliva</a> | — | 10–60 | 70–120 | 130–180 | 190–250 | 260–320 | no cap | Core pet utilities (old cat 10) |
| Hand-to-Hand skill | <a class="item-link" href="https://www.ffxiah.com/item/923" data-img="https://static.ffxiah.com/images/icon/923.png" target="_blank" rel="noopener">Dryad Root</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Dagger skill | <a class="item-link" href="https://www.ffxiah.com/item/864" data-img="https://static.ffxiah.com/images/icon/864.png" target="_blank" rel="noopener">Handful Of Fish Scales</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Sword skill | <a class="item-link" href="https://www.ffxiah.com/item/894" data-img="https://static.ffxiah.com/images/icon/894.png" target="_blank" rel="noopener">Beetle Jaw</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Great Sword skill | <a class="item-link" href="https://www.ffxiah.com/item/916" data-img="https://static.ffxiah.com/images/icon/916.png" target="_blank" rel="noopener">Cactuar Needle</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Axe skill | <a class="item-link" href="https://www.ffxiah.com/item/920" data-img="https://static.ffxiah.com/images/icon/920.png" target="_blank" rel="noopener">Malboro Vine</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Great Axe skill | <a class="item-link" href="https://www.ffxiah.com/item/925" data-img="https://static.ffxiah.com/images/icon/925.png" target="_blank" rel="noopener">Giant Stinger</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Scythe skill | <a class="item-link" href="https://www.ffxiah.com/item/940" data-img="https://static.ffxiah.com/images/icon/940.png" target="_blank" rel="noopener">Revival Tree Root</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Polearm skill | <a class="item-link" href="https://www.ffxiah.com/item/944" data-img="https://static.ffxiah.com/images/icon/944.png" target="_blank" rel="noopener">Pinch Of Venom Dust</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Katana skill | <a class="item-link" href="https://www.ffxiah.com/item/953" data-img="https://static.ffxiah.com/images/icon/953.png" target="_blank" rel="noopener">Treant Bulb</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Great Katana skill | <a class="item-link" href="https://www.ffxiah.com/item/1264" data-img="https://static.ffxiah.com/images/icon/1264.png" target="_blank" rel="noopener">Clump Of Great Boyahda Moss</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Club skill | <a class="item-link" href="https://www.ffxiah.com/item/1446" data-img="https://static.ffxiah.com/images/icon/1446.png" target="_blank" rel="noopener">Lacquer Tree Log</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Staff skill | <a class="item-link" href="https://www.ffxiah.com/item/1592" data-img="https://static.ffxiah.com/images/icon/1592.png" target="_blank" rel="noopener">Cactuar Root</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Melee skill | <a class="item-link" href="https://www.ffxiah.com/item/1616" data-img="https://static.ffxiah.com/images/icon/1616.png" target="_blank" rel="noopener">Antlion Jaw</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Ranged skill | <a class="item-link" href="https://www.ffxiah.com/item/1663" data-img="https://static.ffxiah.com/images/icon/1663.png" target="_blank" rel="noopener">Arnica Root</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1864" data-img="https://static.ffxiah.com/images/icon/1864.png" target="_blank" rel="noopener">High-Quality Antlion Jaw</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Archery skill | <a class="item-link" href="https://www.ffxiah.com/item/2361" data-img="https://static.ffxiah.com/images/icon/2361.png" target="_blank" rel="noopener">Ameretat Vine</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Marksmanship skill | <a class="item-link" href="https://www.ffxiah.com/item/2513" data-img="https://static.ffxiah.com/images/icon/2513.png" target="_blank" rel="noopener">Rafflesia Vine</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Throwing skill | <a class="item-link" href="https://www.ffxiah.com/item/2524" data-img="https://static.ffxiah.com/images/icon/2524.png" target="_blank" rel="noopener">Peiste Stinger</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Shield skill | <a class="item-link" href="https://www.ffxiah.com/item/2936" data-img="https://static.ffxiah.com/images/icon/2936.png" target="_blank" rel="noopener">Chasmic Stinger</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Parrying Skill | <a class="item-link" href="https://www.ffxiah.com/item/2937" data-img="https://static.ffxiah.com/images/icon/2937.png" target="_blank" rel="noopener">Raskovnik Vine</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Weapon skills |
| Divine magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1725" data-img="https://static.ffxiah.com/images/icon/1725.png" target="_blank" rel="noopener">Snow Lily</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Dark magic skill | <a class="item-link" href="https://www.ffxiah.com/item/824" data-img="https://static.ffxiah.com/images/icon/824.png" target="_blank" rel="noopener">Square Of Grass Cloth</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Enha.mag. skill | <a class="item-link" href="https://www.ffxiah.com/item/1740" data-img="https://static.ffxiah.com/images/icon/1740.png" target="_blank" rel="noopener">Iolite</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Enfb.mag. skill | <a class="item-link" href="https://www.ffxiah.com/item/1817" data-img="https://static.ffxiah.com/images/icon/1817.png" target="_blank" rel="noopener">Cactus Arm</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Elem. magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1854" data-img="https://static.ffxiah.com/images/icon/1854.png" target="_blank" rel="noopener">Deed Of Moderation</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Ninjutsu skill | <a class="item-link" href="https://www.ffxiah.com/item/2154" data-img="https://static.ffxiah.com/images/icon/2154.png" target="_blank" rel="noopener">Orobon Lure</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Singing skill | <a class="item-link" href="https://www.ffxiah.com/item/2155" data-img="https://static.ffxiah.com/images/icon/2155.png" target="_blank" rel="noopener">Lesser Chigoe</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| String instrument skill | <a class="item-link" href="https://www.ffxiah.com/item/2161" data-img="https://static.ffxiah.com/images/icon/2161.png" target="_blank" rel="noopener">Troll Vambrace</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Wind instrument skill | <a class="item-link" href="https://www.ffxiah.com/item/831" data-img="https://static.ffxiah.com/images/icon/831.png" target="_blank" rel="noopener">Square Of Shining Cloth</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Blue Magic skill | <a class="item-link" href="https://www.ffxiah.com/item/2171" data-img="https://static.ffxiah.com/images/icon/2171.png" target="_blank" rel="noopener">Colibri Beak</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Geomancy Skill | <a class="item-link" href="https://www.ffxiah.com/item/2212" data-img="https://static.ffxiah.com/images/icon/2212.png" target="_blank" rel="noopener">Gunpowder Swathe</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |
| Handbell Skill | <a class="item-link" href="https://www.ffxiah.com/item/2334" data-img="https://static.ffxiah.com/images/icon/2334.png" target="_blank" rel="noopener">Poroggo Hat</a> | — | 5–30 | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic skills |

### T2 — Hunting League Rank 5

Requires **Augment Tier 2** — reach **Hunting League Rank 5**. Core combat stats that nearly every job cares about — base attributes (STR/DEX/VIT/AGI/INT), Accuracy, DEF, Store TP, Fast Cast, Mag.Acc., Snapshot. Catalysts drop from high-level mobs.

| Augment | Catalyst | Drops from | T1 ×5 | T2 ×5 | T3 ×5 | T4 ×5 | T5 ×5 | Cap | Affinity Category |
|---|---|---|--:|--:|--:|--:|--:|:--:|---|
| Counter | <a class="item-link" href="https://www.ffxiah.com/item/895" data-img="https://static.ffxiah.com/images/icon/895.png" target="_blank" rel="noopener">Ram Horn</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | STR |
| Martial Arts | <a class="item-link" href="https://www.ffxiah.com/item/897" data-img="https://static.ffxiah.com/images/icon/897.png" target="_blank" rel="noopener">Scorpion Claw</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | STR |
| Kick Attacks Rate or Damage | <a class="item-link" href="https://www.ffxiah.com/item/903" data-img="https://static.ffxiah.com/images/icon/903.png" target="_blank" rel="noopener">Dragon Talon</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | STR |
| Counter | <a class="item-link" href="https://www.ffxiah.com/item/2147" data-img="https://static.ffxiah.com/images/icon/2147.png" target="_blank" rel="noopener">Marid Tusk</a> | — | — | 70–120 | 130–180 | 190–250 | 260–320 | no cap | STR |
| Dbl.Atk | <a class="item-link" href="https://www.ffxiah.com/item/882" data-img="https://static.ffxiah.com/images/icon/882.png" target="_blank" rel="noopener">Sheep Tooth</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | 100%/swing | Attack |
| Conserve TP | <a class="item-link" href="https://www.ffxiah.com/item/1108" data-img="https://static.ffxiah.com/images/icon/1108.png" target="_blank" rel="noopener">Pinch Of Sulfur</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Attack |
| Save TP | <a class="item-link" href="https://www.ffxiah.com/item/1516" data-img="https://static.ffxiah.com/images/icon/1516.png" target="_blank" rel="noopener">Griffon Hide</a> | — | — | 80–105 | 110–135 | 140–170 | 175–205 | no cap | Attack |
| Accuracy Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/1292" data-img="https://static.ffxiah.com/images/icon/1292.png" target="_blank" rel="noopener">Damp Hakutaku Eye</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Accuracy |
| Accuracy Attack | <a class="item-link" href="https://www.ffxiah.com/item/884" data-img="https://static.ffxiah.com/images/icon/884.png" target="_blank" rel="noopener">Black Tiger Fang</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Accuracy |
| Rng.Acc. Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/1116" data-img="https://static.ffxiah.com/images/icon/1116.png" target="_blank" rel="noopener">Manticore Hide</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Accuracy |
| Mag.Def.Bns | <a class="item-link" href="https://www.ffxiah.com/item/769" data-img="https://static.ffxiah.com/images/icon/769.png" target="_blank" rel="noopener">Red Rock</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Defense |
| Snapshot | <a class="item-link" href="https://www.ffxiah.com/item/829" data-img="https://static.ffxiah.com/images/icon/829.png" target="_blank" rel="noopener">Square Of Silk Cloth</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Evasion |
| Mag. Acc./Mag. Dmg | <a class="item-link" href="https://www.ffxiah.com/item/909" data-img="https://static.ffxiah.com/images/icon/909.png" target="_blank" rel="noopener">Guivres Skull</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Enspell Dmg | <a class="item-link" href="https://www.ffxiah.com/item/2338" data-img="https://static.ffxiah.com/images/icon/2338.png" target="_blank" rel="noopener">Wamoura Scale</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Pet Haste | <a class="item-link" href="https://www.ffxiah.com/item/826" data-img="https://static.ffxiah.com/images/icon/826.png" target="_blank" rel="noopener">Square Of Linen Cloth</a> | — | — | 5–10 | 15–20 | 20–25 | 25–30 | no cap | Pet stats pulled from old cat 4 |
| Occ. inc. resist to stat ailments | <a class="item-link" href="https://www.ffxiah.com/item/2831" data-img="https://static.ffxiah.com/images/icon/2831.png" target="_blank" rel="noopener">Yellow Brass Chain</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | Status |
| Cap. Point +33% | <a class="item-link" href="https://www.ffxiah.com/item/942" data-img="https://static.ffxiah.com/images/icon/942.png" target="_blank" rel="noopener">Philosophers Stone</a> | — | — | 195–220 | 225–250 | 255–285 | 290–320 | no cap | Exp/Cap points |
| Weapon Skill Acc | <a class="item-link" href="https://www.ffxiah.com/item/1110" data-img="https://static.ffxiah.com/images/icon/1110.png" target="_blank" rel="noopener">Vial Of Black Beetle Blood</a> | — | — | 35–60 | 65–90 | 95–125 | 130–160 | no cap | WSD+ |

### T3 — Voidspire floor 10 + all Game Master waves

Requires **Augment Tier 3** — clear **[Voidspire](../endgame/voidspire.md) floor 10** *and* full-clear **every [Game Master](game-master.md) wave difficulty** (Easy through Nightmare). Damage multipliers and sustain — Double Attack, Crit rate, Magic burst damage, Mag.crit hit damage, weapon delay reductions, HP/MP pool expansions, Regen, Refresh. Catalysts drop from Prestige-tier (Nightmare Court) bosses.

| Augment | Catalyst | Drops from | T1 ×5 | T2 ×5 | T3 ×5 | T4 ×5 | T5 ×5 | Cap | Affinity Category |
|---|---|---|--:|--:|--:|--:|--:|:--:|---|
| Dbl.Atk. Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/880" data-img="https://static.ffxiah.com/images/icon/880.png" target="_blank" rel="noopener">Bone Chip</a> | — | — | — | 65–90 | 95–125 | 130–160 | 100%/swing | Attack |
| Triple Atk | <a class="item-link" href="https://www.ffxiah.com/item/891" data-img="https://static.ffxiah.com/images/icon/891.png" target="_blank" rel="noopener">Bat Fang</a> | — | — | — | 65–90 | 95–125 | 130–160 | 100%/swing | Attack |
| Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/2148" data-img="https://static.ffxiah.com/images/icon/2148.png" target="_blank" rel="noopener">Puk Wing</a> | — | — | — | 65–90 | 95–125 | 130–160 | 100%/swing | DEX |
| Store TP | <a class="item-link" href="https://www.ffxiah.com/item/1621" data-img="https://static.ffxiah.com/images/icon/1621.png" target="_blank" rel="noopener">Taurus Wing</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | DEX |
| Subtle Blow | <a class="item-link" href="https://www.ffxiah.com/item/1690" data-img="https://static.ffxiah.com/images/icon/1690.png" target="_blank" rel="noopener">Hippogryph Tailfeather</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | DEX |
| Magic dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/936" data-img="https://static.ffxiah.com/images/icon/936.png" target="_blank" rel="noopener">Chunk Of Rock Salt</a> | — | — | — | 65–90 | 95–125 | 130–160 | -50% | Defense |
| Phys. dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/858" data-img="https://static.ffxiah.com/images/icon/858.png" target="_blank" rel="noopener">Wolf Hide</a> | — | — | — | 65–90 | 95–125 | 130–160 | -50% | Defense |
| Physical Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/2151" data-img="https://static.ffxiah.com/images/icon/2151.png" target="_blank" rel="noopener">Marid Hide</a> | — | — | — | 130–180 | 190–250 | 260–320 | -50% | Defense |
| Magic Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/2158" data-img="https://static.ffxiah.com/images/icon/2158.png" target="_blank" rel="noopener">Hydra Fang</a> | — | — | — | 130–180 | 190–250 | 260–320 | -50% | Defense |
| Parrying rate | <a class="item-link" href="https://www.ffxiah.com/item/776" data-img="https://static.ffxiah.com/images/icon/776.png" target="_blank" rel="noopener">White Rock</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | Defense |
| Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/2426" data-img="https://static.ffxiah.com/images/icon/2426.png" target="_blank" rel="noopener">Wivre Horn</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Magic Damage | <a class="item-link" href="https://www.ffxiah.com/item/2498" data-img="https://static.ffxiah.com/images/icon/2498.png" target="_blank" rel="noopener">Briareuss Sash</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Magic burst dmg | <a class="item-link" href="https://www.ffxiah.com/item/2776" data-img="https://static.ffxiah.com/images/icon/2776.png" target="_blank" rel="noopener">Pumice Stone</a> | — | — | — | 65–90 | 95–125 | 130–160 | +40% | Magic ATK |
| Mag. crit. hit dmg | <a class="item-link" href="https://www.ffxiah.com/item/2777" data-img="https://static.ffxiah.com/images/icon/2777.png" target="_blank" rel="noopener">Vial Of Magicked Blood</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| Magic crit. hit rate | <a class="item-link" href="https://www.ffxiah.com/item/842" data-img="https://static.ffxiah.com/images/icon/842.png" target="_blank" rel="noopener">Giant Bird Feather</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | Magic ATK |
| HP MP | <a class="item-link" href="https://www.ffxiah.com/item/867" data-img="https://static.ffxiah.com/images/icon/867.png" target="_blank" rel="noopener">Handful Of Dragon Scales</a> | — | — | — | 130–180 | 190–250 | 260–320 | no cap | HP |
| Sic and Ready ability delay | <a class="item-link" href="https://www.ffxiah.com/item/810" data-img="https://static.ffxiah.com/images/icon/810.png" target="_blank" rel="noopener">Fluorite</a> | — | — | — | 65–90 | 95–125 | 130–160 | no cap | Pet stats pulled from old cat 4 |

### T4 — Dynamis - Divergence clear

Requires **Augment Tier 4** — clear a **[Dynamis - Divergence](../endgame/dynamis-divergence.md) city**. Top-tier universals that benefit every job without exception: Haste, Triple Attack, Quadruple Attack, TP Bonus, critical hit damage, physical/magic/all damage-taken percentage reductions. Catalysts drop from Shinryu- and Abyssea-tier NMs.

| Augment | Catalyst | Drops from | T1 ×5 | T2 ×5 | T3 ×5 | T4 ×5 | T5 ×5 | Cap | Affinity Category |
|---|---|---|--:|--:|--:|--:|--:|:--:|---|
| TP Bonus | <a class="item-link" href="https://www.ffxiah.com/item/1271" data-img="https://static.ffxiah.com/images/icon/1271.png" target="_blank" rel="noopener">Pigeons Blood Ruby</a> | — | — | — | — | 380–500 | 520–640 | no cap | Attack |
| Quadruple Attack | <a class="item-link" href="https://www.ffxiah.com/item/1293" data-img="https://static.ffxiah.com/images/icon/1293.png" target="_blank" rel="noopener">Narasimha Hide</a> | — | — | — | — | 95–125 | 130–160 | 100%/swing | Attack |
| Meditate Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2711" data-img="https://static.ffxiah.com/images/icon/2711.png" target="_blank" rel="noopener">Khroma Nugget</a> | — | — | — | — | 95–125 | 130–160 | no cap | Attack |
| Crit. hit damage | <a class="item-link" href="https://www.ffxiah.com/item/2149" data-img="https://static.ffxiah.com/images/icon/2149.png" target="_blank" rel="noopener">Apkallu Feather</a> | — | — | — | — | 95–125 | 130–160 | +100% | DEX |
| Store TP Subtle Blow | <a class="item-link" href="https://www.ffxiah.com/item/840" data-img="https://static.ffxiah.com/images/icon/840.png" target="_blank" rel="noopener">Chocobo Feather</a> | — | — | — | — | 95–125 | 130–160 | no cap | DEX |
| Rapid Shot | <a class="item-link" href="https://www.ffxiah.com/item/1619" data-img="https://static.ffxiah.com/images/icon/1619.png" target="_blank" rel="noopener">Hippogryph Feather</a> | — | — | — | — | 95–125 | 130–160 | no cap | Accuracy |
| Barrage | <a class="item-link" href="https://www.ffxiah.com/item/1199" data-img="https://static.ffxiah.com/images/icon/1199.png" target="_blank" rel="noopener">Northern Fur</a> | — | — | — | — | 95–125 | 130–160 | no cap | Accuracy |
| Breath dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/1193" data-img="https://static.ffxiah.com/images/icon/1193.png" target="_blank" rel="noopener">High-Quality Crab Shell</a> | — | — | — | — | 95–125 | 130–160 | -50% | Defense |
| Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/1123" data-img="https://static.ffxiah.com/images/icon/1123.png" target="_blank" rel="noopener">Manticore Fang</a> | — | — | — | — | 95–125 | 130–160 | -50% | Defense |
| Shield Mastery | <a class="item-link" href="https://www.ffxiah.com/item/770" data-img="https://static.ffxiah.com/images/icon/770.png" target="_blank" rel="noopener">Blue Rock</a> | — | — | — | — | 95–125 | 130–160 | no cap | Defense |
| Chance of successful block | <a class="item-link" href="https://www.ffxiah.com/item/771" data-img="https://static.ffxiah.com/images/icon/771.png" target="_blank" rel="noopener">Yellow Rock</a> | — | — | — | — | 95–125 | 130–160 | no cap | Defense |
| Phalanx Received | <a class="item-link" href="https://www.ffxiah.com/item/772" data-img="https://static.ffxiah.com/images/icon/772.png" target="_blank" rel="noopener">Green Rock</a> | — | — | — | — | 95–125 | 130–160 | no cap | Defense |
| Slow | <a class="item-link" href="https://www.ffxiah.com/item/821" data-img="https://static.ffxiah.com/images/icon/821.png" target="_blank" rel="noopener">Spool Of Rainbow Thread</a> | — | — | — | — | 20–25 | 25–30 | +25% | Haste |
| Resist Slow | <a class="item-link" href="https://www.ffxiah.com/item/828" data-img="https://static.ffxiah.com/images/icon/828.png" target="_blank" rel="noopener">Square Of Velvet Cloth</a> | — | — | — | — | 95–125 | 130–160 | no cap | Haste |
| Blood Pact ability delay | <a class="item-link" href="https://www.ffxiah.com/item/876" data-img="https://static.ffxiah.com/images/icon/876.png" target="_blank" rel="noopener">Manta Skin</a> | — | — | — | — | 95–125 | 130–160 | no cap | Ability delays |
| Call Beast ability delay | <a class="item-link" href="https://www.ffxiah.com/item/912" data-img="https://static.ffxiah.com/images/icon/912.png" target="_blank" rel="noopener">Beehive Chip</a> | — | — | — | — | 95–125 | 130–160 | no cap | Ability delays |
| Quick Draw ability delay | <a class="item-link" href="https://www.ffxiah.com/item/1623" data-img="https://static.ffxiah.com/images/icon/1623.png" target="_blank" rel="noopener">Eft Skin</a> | — | — | — | — | 95–125 | 130–160 | no cap | Ability delays |
| Phantom Roll ability delay | <a class="item-link" href="https://www.ffxiah.com/item/832" data-img="https://static.ffxiah.com/images/icon/832.png" target="_blank" rel="noopener">Clump Of Sheep Wool</a> | — | — | — | — | 95–125 | 130–160 | no cap | Ability delays |
| Helix Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2640" data-img="https://static.ffxiah.com/images/icon/2640.png" target="_blank" rel="noopener">Murex Spicule</a> | — | — | — | — | 95–125 | 130–160 | no cap | INT |
| Mag. Acc. Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/905" data-img="https://static.ffxiah.com/images/icon/905.png" target="_blank" rel="noopener">Wyvern Skull</a> | — | — | — | — | 190–250 | 260–320 | no cap | Magic ATK |
| Occult Acumen | <a class="item-link" href="https://www.ffxiah.com/item/2428" data-img="https://static.ffxiah.com/images/icon/2428.png" target="_blank" rel="noopener">Wivre Hide</a> | — | — | — | — | 95–125 | 130–160 | no cap | Magic ATK |
| Occ. quickens spellcasting | <a class="item-link" href="https://www.ffxiah.com/item/2507" data-img="https://static.ffxiah.com/images/icon/2507.png" target="_blank" rel="noopener">Lycopodium Flower</a> | — | — | — | — | 95–125 | 130–160 | no cap | Magic ATK |
| Fire Affinity Magic Accuracy Recast time | <a class="item-link" href="https://www.ffxiah.com/item/3941" data-img="https://static.ffxiah.com/images/icon/3941.png" target="_blank" rel="noopener">Chapuli Wing</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinity + magic accuracy |
| Helix Damage | <a class="item-link" href="https://www.ffxiah.com/item/2335" data-img="https://static.ffxiah.com/images/icon/2335.png" target="_blank" rel="noopener">Soulflayer Tentacle</a> | — | — | — | — | 1425–1875 | 1950–2400 | no cap | Custom magic augments |
| Cure spellcasting time | <a class="item-link" href="https://www.ffxiah.com/item/793" data-img="https://static.ffxiah.com/images/icon/793.png" target="_blank" rel="noopener">Black Pearl</a> | — | — | — | — | 95–125 | 130–160 | no cap | Healing |
| Waltz ability delay | <a class="item-link" href="https://www.ffxiah.com/item/801" data-img="https://static.ffxiah.com/images/icon/801.png" target="_blank" rel="noopener">Chrysoberyl</a> | — | — | — | — | 95–125 | 130–160 | no cap | Healing |
| Waltz TP cost | <a class="item-link" href="https://www.ffxiah.com/item/836" data-img="https://static.ffxiah.com/images/icon/836.png" target="_blank" rel="noopener">Square Of Damascene Cloth</a> | — | — | — | — | 95–125 | 130–160 | no cap | Healing |
| Regen | <a class="item-link" href="https://www.ffxiah.com/item/848" data-img="https://static.ffxiah.com/images/icon/848.png" target="_blank" rel="noopener">Square Of Dhalmel Leather</a> | — | — | — | — | 380–500 | 520–640 | no cap | Regen |
| Fire Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1268" data-img="https://static.ffxiah.com/images/icon/1268.png" target="_blank" rel="noopener">Doll Gizmo</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Ice Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1270" data-img="https://static.ffxiah.com/images/icon/1270.png" target="_blank" rel="noopener">Arachne Web</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Wind Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1295" data-img="https://static.ffxiah.com/images/icon/1295.png" target="_blank" rel="noopener">Twincoon</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Earth Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1311" data-img="https://static.ffxiah.com/images/icon/1311.png" target="_blank" rel="noopener">Piece Of Oxblood</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Water Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1313" data-img="https://static.ffxiah.com/images/icon/1313.png" target="_blank" rel="noopener">Lock Of Sirens Hair</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Light Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1414" data-img="https://static.ffxiah.com/images/icon/1414.png" target="_blank" rel="noopener">Piece Of Wisteria Lumber</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Dark Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1443" data-img="https://static.ffxiah.com/images/icon/1443.png" target="_blank" rel="noopener">Pinch Of Dried Mugwort</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Thunder Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1830" data-img="https://static.ffxiah.com/images/icon/1830.png" target="_blank" rel="noopener">Sack Of Lugworm Sand</a> | — | — | — | — | 95–125 | 130–160 | no cap | Avatar element affinities (old cat 11) |
| Beast Affinity | <a class="item-link" href="https://www.ffxiah.com/item/2518" data-img="https://static.ffxiah.com/images/icon/2518.png" target="_blank" rel="noopener">Smilodon Hide</a> | — | — | — | — | 115–145 | 150–180 | no cap | Beast affinity |
| Fire Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1165" data-img="https://static.ffxiah.com/images/icon/1165.png" target="_blank" rel="noopener">Doll Shard</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Ice Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1186" data-img="https://static.ffxiah.com/images/icon/1186.png" target="_blank" rel="noopener">Bomb Queen Core</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Wind Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1187" data-img="https://static.ffxiah.com/images/icon/1187.png" target="_blank" rel="noopener">Pinch Of Bomb Queen Ash</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Earth Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1200" data-img="https://static.ffxiah.com/images/icon/1200.png" target="_blank" rel="noopener">Piece Of Eastern Pottery</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Lightning Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1201" data-img="https://static.ffxiah.com/images/icon/1201.png" target="_blank" rel="noopener">Southern Mummy</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Water Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1236" data-img="https://static.ffxiah.com/images/icon/1236.png" target="_blank" rel="noopener">Bag Of Cactus Stems</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Light Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1237" data-img="https://static.ffxiah.com/images/icon/1237.png" target="_blank" rel="noopener">Bag Of Tree Cuttings</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Dark Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1263" data-img="https://static.ffxiah.com/images/icon/1263.png" target="_blank" rel="noopener">Leshonki Bulb</a> | — | — | — | — | 95–125 | 130–160 | no cap | Element affinities (passive elemental identity, not resists) |
| Sklchn.dmg | <a class="item-link" href="https://www.ffxiah.com/item/865" data-img="https://static.ffxiah.com/images/icon/865.png" target="_blank" rel="noopener">Handful Of Nidhoggs Scales</a> | — | — | — | — | 95–125 | 130–160 | no cap | WSD+ |
| Dmg (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/889" data-img="https://static.ffxiah.com/images/icon/889.png" target="_blank" rel="noopener">Beetle Shell</a> | — | — | — | — | 95–125 | 130–160 | no cap | WSD+ |

### T5 — Maat's Echo

Requires **Augment Tier 5** — defeat **Maat's Echo** in [Maat's Challenge](../endgame/maats-challenge.md) (`!maat`). Highly specialised endgame augments: per-element Magic Accuracy, Weapon Skill Damage, Phantom Roll effect, All Songs, Spikes Dmg, and Immunobreak Chance+. Catalysts drop from the hardest endgame NMs.

| Augment | Catalyst | Drops from | T1 ×5 | T2 ×5 | T3 ×5 | T4 ×5 | T5 ×5 | Cap | Affinity Category |
|---|---|---|--:|--:|--:|--:|--:|:--:|---|
| Fire Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2506" data-img="https://static.ffxiah.com/images/icon/2506.png" target="_blank" rel="noopener">Ladybug Wing</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Ice Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2509" data-img="https://static.ffxiah.com/images/icon/2509.png" target="_blank" rel="noopener">Slug Eye</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Wind Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2522" data-img="https://static.ffxiah.com/images/icon/2522.png" target="_blank" rel="noopener">Gnat Wing</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Earth Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2749" data-img="https://static.ffxiah.com/images/icon/2749.png" target="_blank" rel="noopener">Gargouille Eye</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Lightning Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2890" data-img="https://static.ffxiah.com/images/icon/2890.png" target="_blank" rel="noopener">Clionid Wing</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Water Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2938" data-img="https://static.ffxiah.com/images/icon/2938.png" target="_blank" rel="noopener">Bakkas Wing</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Light Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/3502" data-img="https://static.ffxiah.com/images/icon/3502.png" target="_blank" rel="noopener">Vial Of Umbral Marrow</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Dark Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/3930" data-img="https://static.ffxiah.com/images/icon/3930.png" target="_blank" rel="noopener">Twitherym Wing</a> | — | — | — | — | — | 130–160 | no cap | Element affinity + magic accuracy |
| Spikes Dmg | <a class="item-link" href="https://www.ffxiah.com/item/2531" data-img="https://static.ffxiah.com/images/icon/2531.png" target="_blank" rel="noopener">Shard Of Obsidian</a> | — | — | — | — | — | 130–160 | no cap | Custom magic augments |
| Immunobreak Chance+ | <a class="item-link" href="https://www.ffxiah.com/item/2875" data-img="https://static.ffxiah.com/images/icon/2875.png" target="_blank" rel="noopener">Ethereal Squama</a> | — | — | — | — | — | 130–160 | no cap | Custom magic augments |
| All songs | <a class="item-link" href="https://www.ffxiah.com/item/1291" data-img="https://static.ffxiah.com/images/icon/1291.png" target="_blank" rel="noopener">Golden Hakutaku Eye</a> | — | — | — | — | — | 10 | no cap | CHR |
| Phantom Roll effect | <a class="item-link" href="https://www.ffxiah.com/item/1875" data-img="https://static.ffxiah.com/images/icon/1875.png" target="_blank" rel="noopener">Ancient Beastcoin</a> | — | — | — | — | — | 5 | no cap | Job-specific niche utilities |
| Weapon skill damage | <a class="item-link" href="https://www.ffxiah.com/item/1473" data-img="https://static.ffxiah.com/images/icon/1473.png" target="_blank" rel="noopener">High-Quality Scorpion Shell</a> | — | — | — | — | — | 130–160 | no cap | WSD+ |
<!-- DOCGEN:END id="augment-catalog" -->

## Notes

- Catalyst items are existing FFXI items (synth materials, mob drops, vouchers) selected from a non-consumable, non-equippable pool. Trading them at the Augment Moogle is a *new* use; their other functions in crafting and quests still work.
- Augments with `modId=0` in the SQL data (server no-ops) are filtered out — they wouldn't do anything anyway.
- Negative augments on stats that are "good when high" (e.g. `HP-33`) are filtered out. Useful negatives like `Enmity-1`, `Phys.dmg.taken -1%`, and `Spell interruption rate down 1%` are kept.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 5d7d0fc989fe -->
_Last updated: 2026-06-29 04:52 UTC_
<!-- DOCGEN:END id="last-updated" -->
