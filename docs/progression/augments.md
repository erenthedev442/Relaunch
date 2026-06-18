# Augment Moogle

![Augment gem](../assets/emblems/augment.svg){ .lgnd-emblem }

The **Augment Moogle** at GM Home lets you stamp custom augments onto any piece of equipment by trading a catalyst item that maps 1:1 to a specific augment.

!!! tip "Summary"
    Talk to the **Augment Moogle** at **GM Home** (z = -15, in the row with the other GM Home moogles). Trade **1 gear piece + 1-5 catalyst items + 10,000 gil**. Each catalyst writes one augment line onto the gear. Up to 5 augments per piece — the engine's 5 augment slots.

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
    The FFXI client reads augment data from the packet and looks up each augment ID in its own retail data tables. Legendary uses custom augment IDs whose entries in the retail client table do not match the server's definitions — so the item examine window displays **incorrect values** (often a large negative number) on any piece augmented through the Moogle, especially after Augment Sage multipliers are in play.

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

The table below lists **which catalyst maps to which augment**, grouped by stat family. **Fresh ×1–×5** is the total stat from trading that many catalysts with no Sage progress; **Max ×1–×5** is the same trade at full [Augment Sage](augment-sage.md) progress (rank 5 + affinity + a crit); **Cap** is the hard in-game ceiling where one exists — see [how scaling works](#how-augment-power-scales) above.

<!-- DOCGEN:BEGIN id="augment-catalog" -->
_313 catalyst items across 14 categories. Trade the catalyst to the Augment Moogle to apply the matching augment. Cost is **10,000 gil flat per trade** plus the catalyst items themselves._

Each augment **scales with [Augment Sage](augment-sage.md) progress** and with how many catalysts you trade (**×N** = that many, 1–5; an item has 5 augment slots). **Fresh ×N** is a brand-new augment with **no Sage progress**; **Max ×N** is the ceiling at **rank-5 mastery + full affinity + a crit**. Your live value starts near Fresh and climbs toward Max as you rank Augment Sage up. Percentage augments (damage-taken, haste, etc.) show the raw value; the **Cap** column is the hard in-game ceiling for that stat (e.g. Phys. dmg. taken floors at -50%), or **no cap** for additive stats like Attack/HP — values above the Cap can't be reached no matter how many catalysts you stack.

### Strength / Attack / Phys.dmg.taken

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/858" data-img="https://www.bg-wiki.com/images/e/e8/Wolf_Hide_description.png" target="_blank" rel="noopener">Wolf Hide</a> | 858 | Phys. dmg. taken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | -50% |
| <a class="item-link" href="https://www.ffxiah.com/item/861" data-img="https://www.bg-wiki.com/images/f/f8/Tiger_Hide_description.png" target="_blank" rel="noopener">Black Tiger Hide</a> | 861 | Attack | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/883" data-img="https://www.bg-wiki.com/images/d/d3/Behemoth_Horn_description.png" target="_blank" rel="noopener">Behemoth Horn</a> | 883 | Rng.Attack | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/884" data-img="https://www.bg-wiki.com/images/3/30/Blk._Tiger_Fang_description.png" target="_blank" rel="noopener">Black Tiger Fang</a> | 884 | Accuracy Attack | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1116" data-img="https://www.bg-wiki.com/images/9/97/Manticore_Hide_description.png" target="_blank" rel="noopener">Manticore Hide</a> | 1116 | Rng.Acc. Rng.Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1123" data-img="https://www.bg-wiki.com/images/e/ec/Manticore_Fang_description.png" target="_blank" rel="noopener">Manticore Fang</a> | 1123 | Damage Taken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | -50% |
| <a class="item-link" href="https://www.ffxiah.com/item/1615" data-img="https://www.bg-wiki.com/images/f/f1/Buffalo_Horn_description.png" target="_blank" rel="noopener">Buffalo Horn</a> | 1615 | Pet Attack Rng.Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1622" data-img="https://www.bg-wiki.com/images/4/48/Bugard_Tusk_description.png" target="_blank" rel="noopener">Bugard Tusk</a> | 1622 | Pet Attack Rng.Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1718" data-img="https://www.bg-wiki.com/images/6/64/M-bugard_Tusk_description.png" target="_blank" rel="noopener">Megalobugard Tusk</a> | 1718 | Pet Dbl.Atk. Crit.hit rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/786" data-img="https://www.bg-wiki.com/images/8/88/Ruby_description.png" target="_blank" rel="noopener">Ruby</a> | 786 | Pet Damage taken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/853" data-img="https://www.bg-wiki.com/images/4/40/Raptor_Skin_description.png" target="_blank" rel="noopener">Raptor Skin</a> | 853 | Pet Rng.Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/855" data-img="https://static.ffxiah.com/images/icon/855.png" target="_blank" rel="noopener">Square Of Black Tiger Leather</a> | 855 | Pet Phys. dmg. taken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/856" data-img="https://www.bg-wiki.com/images/d/d0/Rabbit_Hide_description.png" target="_blank" rel="noopener">Rabbit Hide</a> | 856 | Pet TP Bonus | 20 | 40 | 60 | 80 | 100 | 51 | 102 | 153 | 204 | 255 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/857" data-img="https://www.bg-wiki.com/images/c/c4/Dhalmel_Hide_description.png" target="_blank" rel="noopener">Dhalmel Hide</a> | 857 | Pet Dbl.Att | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/863" data-img="https://www.bg-wiki.com/images/8/8a/Coeurl_Hide_description.png" target="_blank" rel="noopener">Coeurl Hide</a> | 863 | Pet Magic Damage Taken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/874" data-img="https://www.bg-wiki.com/images/4/4c/Amaltheia_Hide_description.png" target="_blank" rel="noopener">Amaltheia Hide</a> | 874 | Attack Rng.Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/880" data-img="https://www.bg-wiki.com/images/d/de/Bone_Chip_description.png" target="_blank" rel="noopener">Bone Chip</a> | 880 | Dbl.Atk. Crit.hit rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | 100%/swing |
| <a class="item-link" href="https://www.ffxiah.com/item/882" data-img="https://www.bg-wiki.com/images/5/56/Sheep_Tooth_description.png" target="_blank" rel="noopener">Sheep Tooth</a> | 882 | Dbl.Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | 100%/swing |
| <a class="item-link" href="https://www.ffxiah.com/item/891" data-img="https://www.bg-wiki.com/images/f/fe/Bat_Fang_description.png" target="_blank" rel="noopener">Bat Fang</a> | 891 | Triple Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | 100%/swing |
| <a class="item-link" href="https://www.ffxiah.com/item/895" data-img="https://www.bg-wiki.com/images/b/bb/Ram_Horn_description.png" target="_blank" rel="noopener">Ram Horn</a> | 895 | Counter | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/897" data-img="https://www.bg-wiki.com/images/9/92/Scorpion_Claw_description.png" target="_blank" rel="noopener">Scorpion Claw</a> | 897 | Dual Wield | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/903" data-img="https://www.bg-wiki.com/images/3/30/Dragon_Talon_description.png" target="_blank" rel="noopener">Dragon Talon</a> | 903 | Martial Arts | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/926" data-img="https://www.bg-wiki.com/images/0/0a/Lizard_Tail_description.png" target="_blank" rel="noopener">Lizard Tail</a> | 926 | Kick Attacks Rate or Damage | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/947" data-img="https://static.ffxiah.com/images/icon/947.png" target="_blank" rel="noopener">Jar Of Firesand</a> | 947 | Zanshin | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1015" data-img="https://www.bg-wiki.com/images/1/1b/Sand_Bat_Fang_description.png" target="_blank" rel="noopener">Sand Bat Fang</a> | 1015 | Daken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1108" data-img="https://static.ffxiah.com/images/icon/1108.png" target="_blank" rel="noopener">Pinch Of Sulfur</a> | 1108 | Conserve TP | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1199" data-img="https://www.bg-wiki.com/images/f/f2/Northern_Fur_description.png" target="_blank" rel="noopener">Northern Fur</a> | 1199 | Barrage | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1271" data-img="https://www.bg-wiki.com/images/8/8a/Pigeon%27s_Blood_description.png" target="_blank" rel="noopener">Pigeons Blood Ruby</a> | 1271 | TP Bonus | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1293" data-img="https://www.bg-wiki.com/images/1/1f/Narasimha_Hide_description.png" target="_blank" rel="noopener">Narasimha Hide</a> | 1293 | Quadruple Attack | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | 100%/swing |
| <a class="item-link" href="https://www.ffxiah.com/item/1516" data-img="https://www.bg-wiki.com/images/4/49/Griffon_Hide_description.png" target="_blank" rel="noopener">Griffon Hide</a> | 1516 | Save TP | 10 | 20 | 30 | 40 | 50 | 41 | 82 | 123 | 164 | 205 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1591" data-img="https://www.bg-wiki.com/images/c/c9/H.Q._Coeurl_Hide_description.png" target="_blank" rel="noopener">High-Quality Coeurl Hide</a> | 1591 | Reverse Flourish | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1620" data-img="https://www.bg-wiki.com/images/7/7f/Taurus_Horn_description.png" target="_blank" rel="noopener">Taurus Horn</a> | 1620 | STR | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1628" data-img="https://www.bg-wiki.com/images/2/27/Buffalo_Hide_description.png" target="_blank" rel="noopener">Buffalo Hide</a> | 1628 | STR DEX | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1640" data-img="https://www.bg-wiki.com/images/a/af/Bugard_Skin_description.png" target="_blank" rel="noopener">Bugard Skin</a> | 1640 | STR VIT | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1680" data-img="https://www.bg-wiki.com/images/5/51/H.Q._Bugard_Skin_description.png" target="_blank" rel="noopener">High-Quality Bugard Skin</a> | 1680 | STR AGI | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1816" data-img="https://www.bg-wiki.com/images/a/a3/Wyrm_Horn_description.png" target="_blank" rel="noopener">Wyrm Horn</a> | 1816 | STR CHR | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2121" data-img="https://www.bg-wiki.com/images/9/93/Ovinnik_Hide_description.png" target="_blank" rel="noopener">Ovinnik Hide</a> | 2121 | STR INT | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2123" data-img="https://www.bg-wiki.com/images/7/75/Catoblepas_Hide_description.png" target="_blank" rel="noopener">Catoblepas Hide</a> | 2123 | STR MND | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2147" data-img="https://www.bg-wiki.com/images/4/4b/Marid_Tusk_description.png" target="_blank" rel="noopener">Marid Tusk</a> | 2147 | Counter | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2151" data-img="https://www.bg-wiki.com/images/d/d3/Marid_Hide_description.png" target="_blank" rel="noopener">Marid Hide</a> | 2151 | Physical Damage Taken | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | -50% |
| <a class="item-link" href="https://www.ffxiah.com/item/2158" data-img="https://www.bg-wiki.com/images/0/0e/Hydra_Fang_description.png" target="_blank" rel="noopener">Hydra Fang</a> | 2158 | Magic Damage Taken | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | -50% |
| <a class="item-link" href="https://www.ffxiah.com/item/2168" data-img="https://www.bg-wiki.com/images/9/9f/Cerberus_Claw_description.png" target="_blank" rel="noopener">Cerberus Claw</a> | 2168 | Pet STR | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2169" data-img="https://www.bg-wiki.com/images/0/05/Cerberus_Hide_description.png" target="_blank" rel="noopener">Cerberus Hide</a> | 2169 | Pet STR DEX VIT | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Dexterity / Accuracy / Crit

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/2148" data-img="https://www.bg-wiki.com/images/2/2b/Puk_Wing_description.png" target="_blank" rel="noopener">Puk Wing</a> | 2148 | Crit.hit rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | 100%/swing |
| <a class="item-link" href="https://www.ffxiah.com/item/3504" data-img="https://www.bg-wiki.com/images/b/bb/Peapuk_Wing_description.png" target="_blank" rel="noopener">Peapuk Wing</a> | 3504 | Enemy crit. hit rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/840" data-img="https://www.bg-wiki.com/images/4/4c/Chocobo_Fthr._description.png" target="_blank" rel="noopener">Chocobo Feather</a> | 840 | Store TP Subtle Blow | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/842" data-img="https://www.bg-wiki.com/images/8/80/Giant_Bird_Fthr._description.png" target="_blank" rel="noopener">Giant Bird Feather</a> | 842 | Magic crit. hit rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/846" data-img="https://www.bg-wiki.com/images/9/92/Insect_Wing_description.png" target="_blank" rel="noopener">Insect Wing</a> | 846 | Accuracy | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/847" data-img="https://www.bg-wiki.com/images/8/8c/Bird_Feather_description.png" target="_blank" rel="noopener">Bird Feather</a> | 847 | Rng.Accuracy | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/922" data-img="https://www.bg-wiki.com/images/0/0c/Bat_Wing_description.png" target="_blank" rel="noopener">Bat Wing</a> | 922 | Pet Accuracy Rng.Acc | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/935" data-img="https://www.bg-wiki.com/images/6/6a/Ahriman_Wing_description.png" target="_blank" rel="noopener">Ahriman Wing</a> | 935 | Pet Crit.hit rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/939" data-img="https://www.bg-wiki.com/images/3/33/Hecteyes_Eye_description.png" target="_blank" rel="noopener">Hecteyes Eye</a> | 939 | Pet Enemy crit. hit rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1124" data-img="https://www.bg-wiki.com/images/7/75/Wyvern_Wing_description.png" target="_blank" rel="noopener">Wyvern Wing</a> | 1124 | Pet Accuracy Rng.Acc | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1288" data-img="https://www.bg-wiki.com/images/0/0e/Wooden_Hktk._Eye_description.png" target="_blank" rel="noopener">Wooden Hakutaku Eye</a> | 1288 | Pet Rng.Acc | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1289" data-img="https://www.bg-wiki.com/images/2/2d/Burning_Hktk._Eye_description.png" target="_blank" rel="noopener">Burning Hakutaku Eye</a> | 1289 | Pet Store TP | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1290" data-img="https://www.bg-wiki.com/images/9/93/Earthen_Hktk._Eye_description.png" target="_blank" rel="noopener">Earthen Hakutaku Eye</a> | 1290 | Pet Subtle Blow | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1292" data-img="https://www.bg-wiki.com/images/b/bc/Damp_Hktk._Eye_description.png" target="_blank" rel="noopener">Damp Hakutaku Eye</a> | 1292 | Accuracy Rng.Acc | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1619" data-img="https://www.bg-wiki.com/images/8/8b/Hippogryph_Fthr._description.png" target="_blank" rel="noopener">Hippogryph Feather</a> | 1619 | Rapid Shot | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1621" data-img="https://www.bg-wiki.com/images/5/53/Taurus_Wing_description.png" target="_blank" rel="noopener">Taurus Wing</a> | 1621 | Store TP | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1690" data-img="https://www.bg-wiki.com/images/5/59/Hippogryph_Tf._description.png" target="_blank" rel="noopener">Hippogryph Tailfeather</a> | 1690 | Subtle Blow | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2149" data-img="https://www.bg-wiki.com/images/4/4e/Apkallu_Feather_description.png" target="_blank" rel="noopener">Apkallu Feather</a> | 2149 | Crit. hit damage | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | +100% |
| <a class="item-link" href="https://www.ffxiah.com/item/2150" data-img="https://www.bg-wiki.com/images/e/e1/Colibri_Feather_description.png" target="_blank" rel="noopener">Colibri Feather</a> | 2150 | DEX | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2499" data-img="https://www.bg-wiki.com/images/c/c4/Regurg._Wing_description.png" target="_blank" rel="noopener">Regurgitated Wing</a> | 2499 | DEX AGI | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2506" data-img="https://www.bg-wiki.com/images/1/1a/Ladybug_Wing_description.png" target="_blank" rel="noopener">Ladybug Wing</a> | 2506 | Fire Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2509" data-img="https://www.bg-wiki.com/images/3/3a/Slug_Eye_description.png" target="_blank" rel="noopener">Slug Eye</a> | 2509 | Ice Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2522" data-img="https://www.bg-wiki.com/images/0/08/Gnat_Wing_description.png" target="_blank" rel="noopener">Gnat Wing</a> | 2522 | Wind Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2749" data-img="https://www.bg-wiki.com/images/f/f0/Gargouille_Eye_description.png" target="_blank" rel="noopener">Gargouille Eye</a> | 2749 | Earth Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2890" data-img="https://www.bg-wiki.com/images/3/30/Clionid_Wing_description.png" target="_blank" rel="noopener">Clionid Wing</a> | 2890 | Lightning Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2938" data-img="https://www.bg-wiki.com/images/f/ff/Bakka%27s_Wing_description.png" target="_blank" rel="noopener">Bakkas Wing</a> | 2938 | Water Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/3502" data-img="https://static.ffxiah.com/images/icon/3502.png" target="_blank" rel="noopener">Vial Of Umbral Marrow</a> | 3502 | Light Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/3930" data-img="https://www.bg-wiki.com/images/6/67/Twitherym_Wing_description.png" target="_blank" rel="noopener">Twitherym Wing</a> | 3930 | Dark Affinity Magic Accuracy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/3941" data-img="https://www.bg-wiki.com/images/f/f7/Chapuli_Wing_description.png" target="_blank" rel="noopener">Chapuli Wing</a> | 3941 | Fire Affinity Magic Accuracy Recast time | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Vitality / Defense / Stoneskin

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/881" data-img="https://www.bg-wiki.com/images/5/57/Crab_Shell_description.png" target="_blank" rel="noopener">Crab Shell</a> | 881 | DEF | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/936" data-img="https://static.ffxiah.com/images/icon/936.png" target="_blank" rel="noopener">Chunk Of Rock Salt</a> | 936 | Magic dmg. taken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | -50% |
| <a class="item-link" href="https://www.ffxiah.com/item/1193" data-img="https://www.bg-wiki.com/images/2/29/H.Q._Crab_Shell_description.png" target="_blank" rel="noopener">High-Quality Crab Shell</a> | 1193 | Breath dmg. taken | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | -50% |
| <a class="item-link" href="https://www.ffxiah.com/item/2854" data-img="https://www.bg-wiki.com/images/c/c8/Stately_Crab_Sh._description.png" target="_blank" rel="noopener">Stately Crab Shell</a> | 2854 | Pet DEF | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/768" data-img="https://www.bg-wiki.com/images/3/37/Flint_Stone_description.png" target="_blank" rel="noopener">Flint Stone</a> | 768 | Pet Mag.Def.Bns | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/769" data-img="https://www.bg-wiki.com/images/0/01/Red_Rock_description.png" target="_blank" rel="noopener">Red Rock</a> | 769 | Mag.Def.Bns | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/770" data-img="https://www.bg-wiki.com/images/e/e5/Blue_Rock_description.png" target="_blank" rel="noopener">Blue Rock</a> | 770 | Shield Mastery | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/771" data-img="https://www.bg-wiki.com/images/b/b1/Yellow_Rock_description.png" target="_blank" rel="noopener">Yellow Rock</a> | 771 | Chance of successful block | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/772" data-img="https://www.bg-wiki.com/images/1/17/Green_Rock_description.png" target="_blank" rel="noopener">Green Rock</a> | 772 | Phalanx Received | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/773" data-img="https://www.bg-wiki.com/images/6/61/Translucent_Rock_description.png" target="_blank" rel="noopener">Translucent Rock</a> | 773 | VIT | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/774" data-img="https://www.bg-wiki.com/images/2/23/Purple_Rock_description.png" target="_blank" rel="noopener">Purple Rock</a> | 774 | DEF | 10 | 20 | 30 | 40 | 50 | 320 | 640 | 960 | 1280 | 1600 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/775" data-img="https://www.bg-wiki.com/images/2/21/Black_Rock_description.png" target="_blank" rel="noopener">Black Rock</a> | 775 | Pet Magic Dmg. Taken | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/776" data-img="https://www.bg-wiki.com/images/e/e9/White_Rock_description.png" target="_blank" rel="noopener">White Rock</a> | 776 | Parrying rate | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/803" data-img="https://www.bg-wiki.com/images/f/f7/Sunstone_description.png" target="_blank" rel="noopener">Sunstone</a> | 803 | Pet VIT | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Agility / Evasion / Haste

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/816" data-img="https://static.ffxiah.com/images/icon/816.png" target="_blank" rel="noopener">Spool Of Silk Thread</a> | 816 | Delay (melee,not ranged) | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/818" data-img="https://static.ffxiah.com/images/icon/818.png" target="_blank" rel="noopener">Spool Of Cotton Thread</a> | 818 | Delay (melee,not ranged) | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/820" data-img="https://static.ffxiah.com/images/icon/820.png" target="_blank" rel="noopener">Spool Of Wool Thread</a> | 820 | Haste | 0 | 0 | 1 | 1 | 1 | 6 | 13 | 19 | 25 | 31 | +25% |
| <a class="item-link" href="https://www.ffxiah.com/item/821" data-img="https://static.ffxiah.com/images/icon/821.png" target="_blank" rel="noopener">Spool Of Rainbow Thread</a> | 821 | Slow | 0 | 0 | 1 | 1 | 1 | 6 | 13 | 19 | 25 | 31 | +25% |
| <a class="item-link" href="https://www.ffxiah.com/item/825" data-img="https://static.ffxiah.com/images/icon/825.png" target="_blank" rel="noopener">Square Of Cotton Cloth</a> | 825 | Pet Evasion | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/826" data-img="https://static.ffxiah.com/images/icon/826.png" target="_blank" rel="noopener">Square Of Linen Cloth</a> | 826 | Pet Haste | 0 | 0 | 1 | 1 | 1 | 6 | 13 | 19 | 25 | 31 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/827" data-img="https://static.ffxiah.com/images/icon/827.png" target="_blank" rel="noopener">Square Of Wool Cloth</a> | 827 | Pet Mag. Evasion | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/828" data-img="https://static.ffxiah.com/images/icon/828.png" target="_blank" rel="noopener">Square Of Velvet Cloth</a> | 828 | Resist Slow | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/829" data-img="https://static.ffxiah.com/images/icon/829.png" target="_blank" rel="noopener">Square Of Silk Cloth</a> | 829 | Snapshot | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/834" data-img="https://static.ffxiah.com/images/icon/834.png" target="_blank" rel="noopener">Ball Of Saruta Cotton</a> | 834 | Recycle | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/876" data-img="https://www.bg-wiki.com/images/7/73/Manta_Skin_description.png" target="_blank" rel="noopener">Manta Skin</a> | 876 | Blood Pact ability delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/912" data-img="https://www.bg-wiki.com/images/9/9d/Beehive_Chip_description.png" target="_blank" rel="noopener">Beehive Chip</a> | 912 | Call Beast ability delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1623" data-img="https://www.bg-wiki.com/images/3/3d/Eft_Skin_description.png" target="_blank" rel="noopener">Eft Skin</a> | 1623 | Quick Draw ability delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1741" data-img="https://www.bg-wiki.com/images/5/5c/H.Q._Eft_Skin_description.png" target="_blank" rel="noopener">High-Quality Eft Skin</a> | 1741 | Waltz potency | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/801" data-img="https://www.bg-wiki.com/images/7/7a/Chrysoberyl_description.png" target="_blank" rel="noopener">Chrysoberyl</a> | 801 | Waltz ability delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/810" data-img="https://www.bg-wiki.com/images/a/ad/Fluorite_description.png" target="_blank" rel="noopener">Fluorite</a> | 810 | Sic and Ready ability delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/817" data-img="https://static.ffxiah.com/images/icon/817.png" target="_blank" rel="noopener">Spool Of Grass Thread</a> | 817 | Song recast delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/832" data-img="https://static.ffxiah.com/images/icon/832.png" target="_blank" rel="noopener">Clump Of Sheep Wool</a> | 832 | Phantom Roll ability delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/836" data-img="https://static.ffxiah.com/images/icon/836.png" target="_blank" rel="noopener">Square Of Damascene Cloth</a> | 836 | Waltz TP cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/838" data-img="https://www.bg-wiki.com/images/b/bd/Spider_Web_description.png" target="_blank" rel="noopener">Spider Web</a> | 838 | Healing Magic Recast Delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/849" data-img="https://www.bg-wiki.com/images/1/17/Undead_Skin_description.png" target="_blank" rel="noopener">Undead Skin</a> | 849 | Elemental Magic Recast Delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/859" data-img="https://www.bg-wiki.com/images/8/80/Ram_Skin_description.png" target="_blank" rel="noopener">Ram Skin</a> | 859 | Enfeebling Magic Recast Delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/868" data-img="https://static.ffxiah.com/images/icon/868.png" target="_blank" rel="noopener">Handful Of Pugil Scales</a> | 868 | Enhancing Magic Recast Delay | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/878" data-img="https://www.bg-wiki.com/images/4/49/Karakul_Skin_description.png" target="_blank" rel="noopener">Karakul Skin</a> | 878 | AGI | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/927" data-img="https://www.bg-wiki.com/images/3/34/Coeurl_Whisker_description.png" target="_blank" rel="noopener">Coeurl Whisker</a> | 927 | Delay (melee,not ranged) | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1118" data-img="https://www.bg-wiki.com/images/5/5c/Antican_Pauldron_description.png" target="_blank" rel="noopener">Antican Pauldron</a> | 1118 | Delay (melee,not ranged) | 33 | 66 | 99 | 132 | 165 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1121" data-img="https://www.bg-wiki.com/images/6/65/Antican_Robe_description.png" target="_blank" rel="noopener">Antican Robe</a> | 1121 | Delay (melee,not ranged) | 65 | 130 | 195 | 260 | 325 | 96 | 192 | 288 | 384 | 480 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1196" data-img="https://www.bg-wiki.com/images/1/11/Qiqirn_Cape_description.png" target="_blank" rel="noopener">Qiqirn Cape</a> | 1196 | Delay (melee,not ranged) | 97 | 194 | 291 | 388 | 485 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1265" data-img="https://www.bg-wiki.com/images/2/2c/4Lf._Korrin_Bud_description.png" target="_blank" rel="noopener">Four-Leaf Korrigan Bud</a> | 1265 | Delay (melee,not ranged) | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1275" data-img="https://www.bg-wiki.com/images/a/a1/Amemet_Skin_description.png" target="_blank" rel="noopener">Amemet Skin</a> | 1275 | Delay (melee,not ranged) | 33 | 66 | 99 | 132 | 165 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1276" data-img="https://www.bg-wiki.com/images/9/92/Tarasque_Skin_description.png" target="_blank" rel="noopener">Tarasque Skin</a> | 1276 | Delay (melee,not ranged) | 65 | 130 | 195 | 260 | 325 | 96 | 192 | 288 | 384 | 480 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1277" data-img="https://www.bg-wiki.com/images/9/97/Lindwurm_Skin_description.png" target="_blank" rel="noopener">Lindwurm Skin</a> | 1277 | Delay (melee,not ranged) | 97 | 194 | 291 | 388 | 485 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1279" data-img="https://static.ffxiah.com/images/icon/1279.png" target="_blank" rel="noopener">Square Of Taffeta Cloth</a> | 1279 | Delay (ranged,not melee) | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1280" data-img="https://static.ffxiah.com/images/icon/1280.png" target="_blank" rel="noopener">Square Of Sarcenet Cloth</a> | 1280 | Delay (ranged,not melee) | 33 | 66 | 99 | 132 | 165 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1281" data-img="https://static.ffxiah.com/images/icon/1281.png" target="_blank" rel="noopener">Square Of Cheviot Cloth</a> | 1281 | Delay (ranged,not melee) | 65 | 130 | 195 | 260 | 325 | 96 | 192 | 288 | 384 | 480 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1282" data-img="https://www.bg-wiki.com/images/5/5e/Flauros_Whisker_description.png" target="_blank" rel="noopener">Flauros Whisker</a> | 1282 | Delay (ranged,not melee) | 97 | 194 | 291 | 388 | 485 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1283" data-img="https://www.bg-wiki.com/images/8/8f/Ose_Whisker_description.png" target="_blank" rel="noopener">Ose Whisker</a> | 1283 | Delay (ranged,not melee) | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1296" data-img="https://www.bg-wiki.com/images/d/d8/Yowie_Skin_description.png" target="_blank" rel="noopener">Yowie Skin</a> | 1296 | Delay (ranged,not melee) | 33 | 66 | 99 | 132 | 165 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1312" data-img="https://static.ffxiah.com/images/icon/1312.png" target="_blank" rel="noopener">Piece Of Angel Skin</a> | 1312 | Delay (ranged,not melee) | 65 | 130 | 195 | 260 | 325 | 96 | 192 | 288 | 384 | 480 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1470" data-img="https://www.bg-wiki.com/images/3/3f/Sparkling_Stone_description.png" target="_blank" rel="noopener">Sparkling Stone</a> | 1470 | Delay (ranged,not melee) | 97 | 194 | 291 | 388 | 485 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1617" data-img="https://www.bg-wiki.com/images/b/bd/Flytrap_Leaf_description.png" target="_blank" rel="noopener">Flytrap Leaf</a> | 1617 | Evasion | 3 | 6 | 9 | 12 | 15 | 34 | 68 | 102 | 136 | 170 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1713" data-img="https://static.ffxiah.com/images/icon/1713.png" target="_blank" rel="noopener">Spool Of Cashmere Thread</a> | 1713 | Mag. Evasion | 3 | 6 | 9 | 12 | 15 | 34 | 68 | 102 | 136 | 170 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1861" data-img="https://www.bg-wiki.com/images/c/cc/Moblin_Sheepskin_description.png" target="_blank" rel="noopener">Moblin Sheepskin</a> | 1861 | Pet AGI | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Intelligence / Magic offense

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/854" data-img="https://www.bg-wiki.com/images/6/6d/Cockatrice_Skin_description.png" target="_blank" rel="noopener">Cockatrice Skin</a> | 854 | Spell interruption rate down 1% | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/886" data-img="https://www.bg-wiki.com/images/2/26/Demon_Skull_description.png" target="_blank" rel="noopener">Demon Skull</a> | 886 | Mag. Acc | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/905" data-img="https://www.bg-wiki.com/images/5/5e/Wyvern_Skull_description.png" target="_blank" rel="noopener">Wyvern Skull</a> | 905 | Mag. Acc. Mag.Atk.Bns | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/909" data-img="https://www.bg-wiki.com/images/7/73/Guivre%27s_Skull_description.png" target="_blank" rel="noopener">Guivres Skull</a> | 909 | Mag. Acc./Mag. Dmg | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/914" data-img="https://static.ffxiah.com/images/icon/914.png" target="_blank" rel="noopener">Vial Of Mercury</a> | 914 | Pet Mag.Acc | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/954" data-img="https://www.bg-wiki.com/images/c/c6/Magic_Pot_Shard_description.png" target="_blank" rel="noopener">Magic Pot Shard</a> | 954 | Pet Mag.Atk.Bns | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1518" data-img="https://www.bg-wiki.com/images/b/b3/Colossal_Skull_description.png" target="_blank" rel="noopener">Colossal Skull</a> | 1518 | Pet Mag.Acc. Mag.Atk.Bns | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1521" data-img="https://static.ffxiah.com/images/icon/1521.png" target="_blank" rel="noopener">Vial Of Slime Juice</a> | 1521 | Avatar Mag.Atk.Bns | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2157" data-img="https://www.bg-wiki.com/images/d/d4/Imp_Horn_description.png" target="_blank" rel="noopener">Imp Horn</a> | 2157 | Pet Mag.Acc. Mag.Dmg | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2163" data-img="https://www.bg-wiki.com/images/c/cb/Imp_Wing_description.png" target="_blank" rel="noopener">Imp Wing</a> | 2163 | Pet Magic Damage | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2426" data-img="https://www.bg-wiki.com/images/7/76/Wivre_Horn_description.png" target="_blank" rel="noopener">Wivre Horn</a> | 2426 | Mag.Atk.Bns | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2427" data-img="https://www.bg-wiki.com/images/2/25/Wivre_Maul_description.png" target="_blank" rel="noopener">Wivre Maul</a> | 2427 | Fast Cast | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2428" data-img="https://www.bg-wiki.com/images/d/d2/Wivre_Hide_description.png" target="_blank" rel="noopener">Wivre Hide</a> | 2428 | Occult Acumen | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2776" data-img="https://www.bg-wiki.com/images/5/5d/Pumice_Stone_description.png" target="_blank" rel="noopener">Pumice Stone</a> | 2776 | Magic burst dmg | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | +40% |
| <a class="item-link" href="https://www.ffxiah.com/item/2777" data-img="https://static.ffxiah.com/images/icon/2777.png" target="_blank" rel="noopener">Vial Of Magicked Blood</a> | 2777 | Mag. crit. hit dmg | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2943" data-img="https://www.bg-wiki.com/images/5/57/Balaur_Skull_description.png" target="_blank" rel="noopener">Balaur Skull</a> | 2943 | Augment | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2338" data-img="https://www.bg-wiki.com/images/0/0d/Wamoura_Scale_description.png" target="_blank" rel="noopener">Wamoura Scale</a> | 2338 | Enspell Dmg | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Mind / Healing / Cure

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/791" data-img="https://www.bg-wiki.com/images/7/77/Aquamarine_description.png" target="_blank" rel="noopener">Aquamarine</a> | 791 | MP recovered while healing | 4 | 8 | 12 | 16 | 20 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/792" data-img="https://www.bg-wiki.com/images/9/9d/Pearl_description.png" target="_blank" rel="noopener">Pearl</a> | 792 | Healing magic skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/793" data-img="https://www.bg-wiki.com/images/e/e7/Black_Pearl_description.png" target="_blank" rel="noopener">Black Pearl</a> | 793 | Cure spellcasting time | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/833" data-img="https://static.ffxiah.com/images/icon/833.png" target="_blank" rel="noopener">Clump Of Moko Grass</a> | 833 | Cure potency | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/887" data-img="https://www.bg-wiki.com/images/9/9a/Coral_Fragment_description.png" target="_blank" rel="noopener">Coral Fragment</a> | 887 | Potency of Cure received | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/888" data-img="https://www.bg-wiki.com/images/b/b4/Seashell_description.png" target="_blank" rel="noopener">Seashell</a> | 888 | MND | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1274" data-img="https://www.bg-wiki.com/images/4/40/Southern_Pearl_description.png" target="_blank" rel="noopener">Southern Pearl</a> | 1274 | MND CHR | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2198" data-img="https://www.bg-wiki.com/images/0/04/W._Spider%27s_Web_description.png" target="_blank" rel="noopener">Water Spiders Web</a> | 2198 | Pet MND | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Charisma / Charm / Enmity

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/787" data-img="https://www.bg-wiki.com/images/6/6e/Diamond_description.png" target="_blank" rel="noopener">Diamond</a> | 787 | Enmity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/901" data-img="https://www.bg-wiki.com/images/f/fb/Venomous_Claw_description.png" target="_blank" rel="noopener">Venomous Claw</a> | 901 | Enmity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/902" data-img="https://www.bg-wiki.com/images/1/19/Demon_Horn_description.png" target="_blank" rel="noopener">Demon Horn</a> | 902 | Charm | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1291" data-img="https://www.bg-wiki.com/images/9/96/Golden_Hktk._Eye_description.png" target="_blank" rel="noopener">Golden Hakutaku Eye</a> | 1291 | All songs | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1408" data-img="https://static.ffxiah.com/images/icon/1408.png" target="_blank" rel="noopener">Bottle Of Illuminink</a> | 1408 | Pet Enmity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1453" data-img="https://www.bg-wiki.com/images/c/c6/M._Silverpiece_description.png" target="_blank" rel="noopener">Montiont Silverpiece</a> | 1453 | Pet Enmity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1844" data-img="https://static.ffxiah.com/images/icon/1844.png" target="_blank" rel="noopener">Square Of Spectral Goldenrod</a> | 1844 | Treasure Hunter | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2372" data-img="https://www.bg-wiki.com/images/6/65/Khimaira_Mane_description.png" target="_blank" rel="noopener">Khimaira Mane</a> | 2372 | Resist Charm | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2827" data-img="https://static.ffxiah.com/images/icon/2827.png" target="_blank" rel="noopener">Spool Of Rugged Gold Thread</a> | 2827 | Song spellcasting time | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2841" data-img="https://static.ffxiah.com/images/icon/2841.png" target="_blank" rel="noopener">Ingot Of Quadav Silver</a> | 2841 | CHR | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2850" data-img="https://static.ffxiah.com/images/icon/2850.png" target="_blank" rel="noopener">Ingot Of Sahagin Gold</a> | 2850 | Pet CHR | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### HP / Regen

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/860" data-img="https://www.bg-wiki.com/images/a/ad/Behemoth_Hide_description.png" target="_blank" rel="noopener">Behemoth Hide</a> | 860 | HP | 4 | 8 | 12 | 16 | 20 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/867" data-img="https://static.ffxiah.com/images/icon/867.png" target="_blank" rel="noopener">Handful Of Dragon Scales</a> | 867 | HP MP | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1122" data-img="https://www.bg-wiki.com/images/e/e5/Wyvern_Skin_description.png" target="_blank" rel="noopener">Wyvern Skin</a> | 1122 | HP recovered while healing | 4 | 8 | 12 | 16 | 20 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1133" data-img="https://static.ffxiah.com/images/icon/1133.png" target="_blank" rel="noopener">Vial Of Dragon Blood</a> | 1133 | Pet Regen | 4 | 8 | 12 | 16 | 20 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/848" data-img="https://static.ffxiah.com/images/icon/848.png" target="_blank" rel="noopener">Square Of Dhalmel Leather</a> | 848 | Regen | 4 | 8 | 12 | 16 | 20 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/850" data-img="https://static.ffxiah.com/images/icon/850.png" target="_blank" rel="noopener">Square Of Sheep Leather</a> | 850 | Regen Potency | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### MP / Refresh

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/841" data-img="https://www.bg-wiki.com/images/9/98/Yagudo_Feather_description.png" target="_blank" rel="noopener">Yagudo Feather</a> | 841 | MP | 4 | 8 | 12 | 16 | 20 | 128 | 256 | 384 | 512 | 640 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/919" data-img="https://static.ffxiah.com/images/icon/919.png" target="_blank" rel="noopener">Clump Of Boyahda Moss</a> | 919 | Refresh | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/921" data-img="https://static.ffxiah.com/images/icon/921.png" target="_blank" rel="noopener">Bottle Of Ahriman Tears</a> | 921 | Conserve MP | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Pet

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/839" data-img="https://static.ffxiah.com/images/icon/839.png" target="_blank" rel="noopener">Piece Of Crawler Cocoon</a> | 839 | Pet Acc R.Acc Atk. R.Atk | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/852" data-img="https://www.bg-wiki.com/images/8/88/Lizard_Skin_description.png" target="_blank" rel="noopener">Lizard Skin</a> | 852 | Blood Boon | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1156" data-img="https://www.bg-wiki.com/images/f/fb/Crawler_Calculus_description.png" target="_blank" rel="noopener">Crawler Calculus</a> | 1156 | Summoning magic skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1272" data-img="https://www.bg-wiki.com/images/e/e7/Arioch_Fang_description.png" target="_blank" rel="noopener">Arioch Fang</a> | 1272 | Avatar perpetuation cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1445" data-img="https://www.bg-wiki.com/images/9/9f/Freya%27s_Tear_description.png" target="_blank" rel="noopener">Freyas Tear</a> | 1445 | Elemental Siphon | 5 | 10 | 15 | 20 | 25 | 160 | 320 | 480 | 640 | 800 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1830" data-img="https://static.ffxiah.com/images/icon/1830.png" target="_blank" rel="noopener">Sack Of Lugworm Sand</a> | 1830 | Avatar Blood Pact Dmg | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1831" data-img="https://static.ffxiah.com/images/icon/1831.png" target="_blank" rel="noopener">Sack Of Little Worm Mulch</a> | 1831 | Thunder Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1979" data-img="https://static.ffxiah.com/images/icon/1979.png" target="_blank" rel="noopener">Cup Of Leech Saliva</a> | 1979 | Pet Phy. Dmg. Taken | 2 | 4 | 6 | 8 | 10 | 64 | 128 | 192 | 256 | 320 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2173" data-img="https://www.bg-wiki.com/images/2/24/Wam._Cocoon_description.png" target="_blank" rel="noopener">Wamoura Cocoon</a> | 2173 | Thunder Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Elemental resistance

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/1163" data-img="https://static.ffxiah.com/images/icon/1163.png" target="_blank" rel="noopener">Lock Of Manticore Hair</a> | 1163 | Resist Sleep | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1452" data-img="https://www.bg-wiki.com/images/4/48/O._Bronzepiece_description.png" target="_blank" rel="noopener">Ordelle Bronzepiece</a> | 1452 | Resist Poison | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1630" data-img="https://static.ffxiah.com/images/icon/1630.png" target="_blank" rel="noopener">Pinch Of Cluster Ash</a> | 1630 | Resist Paralyze | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1638" data-img="https://www.bg-wiki.com/images/7/73/Moblin_Mask_description.png" target="_blank" rel="noopener">Moblin Mask</a> | 1638 | Resist Blind | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1667" data-img="https://www.bg-wiki.com/images/a/af/Cluster_Core_description.png" target="_blank" rel="noopener">Cluster Core</a> | 1667 | Resist Silence | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2337" data-img="https://static.ffxiah.com/images/icon/2337.png" target="_blank" rel="noopener">Clump Of Wamoura Hair</a> | 2337 | Resist Virus | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2549" data-img="https://static.ffxiah.com/images/icon/2549.png" target="_blank" rel="noopener">Pinch Of Djinn Ash</a> | 2549 | Resist Petrify | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2860" data-img="https://static.ffxiah.com/images/icon/2860.png" target="_blank" rel="noopener">Slab Of Plumbago</a> | 2860 | Resist Bind | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/784" data-img="https://www.bg-wiki.com/images/e/eb/Jadeite_description.png" target="_blank" rel="noopener">Jadeite</a> | 784 | Resist Curse | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/797" data-img="https://www.bg-wiki.com/images/f/f9/Painite_description.png" target="_blank" rel="noopener">Painite</a> | 797 | Resist Gravity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/805" data-img="https://www.bg-wiki.com/images/0/0b/Zircon_description.png" target="_blank" rel="noopener">Zircon</a> | 805 | Resist Stun | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/824" data-img="https://static.ffxiah.com/images/icon/824.png" target="_blank" rel="noopener">Square Of Grass Cloth</a> | 824 | Dark magic skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/831" data-img="https://static.ffxiah.com/images/icon/831.png" target="_blank" rel="noopener">Square Of Shining Cloth</a> | 831 | Wind instrument skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/837" data-img="https://static.ffxiah.com/images/icon/837.png" target="_blank" rel="noopener">Spool Of Malboro Fiber</a> | 837 | Fire resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/918" data-img="https://static.ffxiah.com/images/icon/918.png" target="_blank" rel="noopener">Sprig Of Mistletoe</a> | 918 | Ice resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/928" data-img="https://static.ffxiah.com/images/icon/928.png" target="_blank" rel="noopener">Pinch Of Bomb Ash</a> | 928 | Wind resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/937" data-img="https://static.ffxiah.com/images/icon/937.png" target="_blank" rel="noopener">Block Of Animal Glue</a> | 937 | Earth resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/938" data-img="https://static.ffxiah.com/images/icon/938.png" target="_blank" rel="noopener">Sprig Of Papaka Grass</a> | 938 | Lightning resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/943" data-img="https://static.ffxiah.com/images/icon/943.png" target="_blank" rel="noopener">Pinch Of Poison Dust</a> | 943 | Water resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/948" data-img="https://www.bg-wiki.com/images/5/5f/Carnation_description.png" target="_blank" rel="noopener">Carnation</a> | 948 | Light resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/952" data-img="https://static.ffxiah.com/images/icon/952.png" target="_blank" rel="noopener">Bag Of Poison Flour</a> | 952 | Dark resist | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/955" data-img="https://www.bg-wiki.com/images/6/62/Golem_Shard_description.png" target="_blank" rel="noopener">Golem Shard</a> | 955 | Fire,Wind,Lightning,Light resists | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/959" data-img="https://www.bg-wiki.com/images/f/f6/Dahlia_description.png" target="_blank" rel="noopener">Dahlia</a> | 959 | Ice,Earth,Water,Dark resists | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1132" data-img="https://static.ffxiah.com/images/icon/1132.png" target="_blank" rel="noopener">Square Of Raxa</a> | 1132 | All elemental resists | 10 | 20 | 30 | 40 | 50 | 41 | 82 | 123 | 164 | 205 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1158" data-img="https://www.bg-wiki.com/images/8/8a/Wandering_Bulb_description.png" target="_blank" rel="noopener">Wandering Bulb</a> | 1158 | All elemental resists | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1165" data-img="https://www.bg-wiki.com/images/1/16/Doll_Shard_description.png" target="_blank" rel="noopener">Doll Shard</a> | 1165 | Fire Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1186" data-img="https://www.bg-wiki.com/images/7/70/Bomb_Queen_Core_description.png" target="_blank" rel="noopener">Bomb Queen Core</a> | 1186 | Ice Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1187" data-img="https://static.ffxiah.com/images/icon/1187.png" target="_blank" rel="noopener">Pinch Of Bomb Queen Ash</a> | 1187 | Wind Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1200" data-img="https://static.ffxiah.com/images/icon/1200.png" target="_blank" rel="noopener">Piece Of Eastern Pottery</a> | 1200 | Earth Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1201" data-img="https://www.bg-wiki.com/images/f/f2/Southern_Mummy_description.png" target="_blank" rel="noopener">Southern Mummy</a> | 1201 | Lightning Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1236" data-img="https://static.ffxiah.com/images/icon/1236.png" target="_blank" rel="noopener">Bag Of Cactus Stems</a> | 1236 | Water Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1237" data-img="https://static.ffxiah.com/images/icon/1237.png" target="_blank" rel="noopener">Bag Of Tree Cuttings</a> | 1237 | Light Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1263" data-img="https://www.bg-wiki.com/images/d/d3/Leshonki_Bulb_description.png" target="_blank" rel="noopener">Leshonki Bulb</a> | 1263 | Dark Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1268" data-img="https://www.bg-wiki.com/images/b/ba/Doll_Gizmo_description.png" target="_blank" rel="noopener">Doll Gizmo</a> | 1268 | Fire Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1270" data-img="https://www.bg-wiki.com/images/5/51/Arachne_Web_description.png" target="_blank" rel="noopener">Arachne Web</a> | 1270 | Ice Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1295" data-img="https://www.bg-wiki.com/images/3/36/Twincoon_description.png" target="_blank" rel="noopener">Twincoon</a> | 1295 | Wind Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1311" data-img="https://static.ffxiah.com/images/icon/1311.png" target="_blank" rel="noopener">Piece Of Oxblood</a> | 1311 | Earth Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1313" data-img="https://static.ffxiah.com/images/icon/1313.png" target="_blank" rel="noopener">Lock Of Sirens Hair</a> | 1313 | Water Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1414" data-img="https://static.ffxiah.com/images/icon/1414.png" target="_blank" rel="noopener">Piece Of Wisteria Lumber</a> | 1414 | Light Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1443" data-img="https://static.ffxiah.com/images/icon/1443.png" target="_blank" rel="noopener">Pinch Of Dried Mugwort</a> | 1443 | Dark Affinity Avatar perp. cost | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1449" data-img="https://www.bg-wiki.com/images/1/19/T._Whiteshell_description.png" target="_blank" rel="noopener">Tukuku Whiteshell</a> | 1449 | Ice Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1450" data-img="https://www.bg-wiki.com/images/1/1c/L._Jadeshell_description.png" target="_blank" rel="noopener">Lungo-Nango Jadeshell</a> | 1450 | Wind Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1464" data-img="https://www.bg-wiki.com/images/6/6f/Lancewood_Log_description.png" target="_blank" rel="noopener">Lancewood Log</a> | 1464 | Earth Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1465" data-img="https://static.ffxiah.com/images/icon/1465.png" target="_blank" rel="noopener">Slab Of Granite</a> | 1465 | Lightning Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1474" data-img="https://www.bg-wiki.com/images/1/11/Infinity_Core_description.png" target="_blank" rel="noopener">Infinity Core</a> | 1474 | Water Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1520" data-img="https://static.ffxiah.com/images/icon/1520.png" target="_blank" rel="noopener">Jar Of Goblin Grease</a> | 1520 | Light Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1614" data-img="https://www.bg-wiki.com/images/3/36/Corse_Bracelet_description.png" target="_blank" rel="noopener">Corse Bracelet</a> | 1614 | Dark Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1624" data-img="https://www.bg-wiki.com/images/0/08/Bugbear_Mask_description.png" target="_blank" rel="noopener">Bugbear Mask</a> | 1624 | Ice Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1625" data-img="https://www.bg-wiki.com/images/f/f3/Moblin_Helm_description.png" target="_blank" rel="noopener">Moblin Helm</a> | 1625 | Wind Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1631" data-img="https://www.bg-wiki.com/images/e/e0/Moblin_Armor_description.png" target="_blank" rel="noopener">Moblin Armor</a> | 1631 | Earth Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1632" data-img="https://www.bg-wiki.com/images/6/67/Moblin_Mail_description.png" target="_blank" rel="noopener">Moblin Mail</a> | 1632 | Lightning Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1639" data-img="https://www.bg-wiki.com/images/3/30/Corse_Robe_description.png" target="_blank" rel="noopener">Corse Robe</a> | 1639 | Water Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1651" data-img="https://static.ffxiah.com/images/icon/1651.png" target="_blank" rel="noopener">Spool Of Moblin Thread</a> | 1651 | Light Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1664" data-img="https://www.bg-wiki.com/images/d/df/Eastern_Gem_description.png" target="_blank" rel="noopener">Eastern Gem</a> | 1664 | Dark Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1669" data-img="https://static.ffxiah.com/images/icon/1669.png" target="_blank" rel="noopener">Pinch Of Hoary Bomb Ash</a> | 1669 | Ice Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1687" data-img="https://static.ffxiah.com/images/icon/1687.png" target="_blank" rel="noopener">Recollection Of Fear</a> | 1687 | Wind Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1688" data-img="https://static.ffxiah.com/images/icon/1688.png" target="_blank" rel="noopener">Recollection Of Pain</a> | 1688 | Earth Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1689" data-img="https://static.ffxiah.com/images/icon/1689.png" target="_blank" rel="noopener">Recollection Of Guilt</a> | 1689 | Lightning Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1712" data-img="https://static.ffxiah.com/images/icon/1712.png" target="_blank" rel="noopener">Clump Of Cashmere Wool</a> | 1712 | Water Affintiy | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1714" data-img="https://static.ffxiah.com/images/icon/1714.png" target="_blank" rel="noopener">Square Of Cashmere Cloth</a> | 1714 | Light Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1724" data-img="https://www.bg-wiki.com/images/d/d8/Soulflayer_Robe_description.png" target="_blank" rel="noopener">Soulflayer Robe</a> | 1724 | Dark Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1738" data-img="https://www.bg-wiki.com/images/1/1b/Shakudo_Ingot_description.png" target="_blank" rel="noopener">Shakudo Ingot</a> | 1738 | Ice Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1739" data-img="https://static.ffxiah.com/images/icon/1739.png" target="_blank" rel="noopener">Square Of Balloon Cloth</a> | 1739 | Wind Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1836" data-img="https://www.bg-wiki.com/images/6/69/Marble_description.png" target="_blank" rel="noopener">Marble Slab</a> | 1836 | Earth Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1843" data-img="https://static.ffxiah.com/images/icon/1843.png" target="_blank" rel="noopener">Square Of Spectral Crimson</a> | 1843 | Lightning Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1847" data-img="https://www.bg-wiki.com/images/1/12/Fifth_Virtue_description.png" target="_blank" rel="noopener">Fifth Virtue</a> | 1847 | Water Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1848" data-img="https://www.bg-wiki.com/images/e/e4/Fourth_Virtue_description.png" target="_blank" rel="noopener">Fourth Virtue</a> | 1848 | Light Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1849" data-img="https://www.bg-wiki.com/images/2/27/Sixth_Virtue_description.png" target="_blank" rel="noopener">Sixth Virtue</a> | 1849 | Dark Affinity | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1850" data-img="https://www.bg-wiki.com/images/1/1b/First_Virtue_description.png" target="_blank" rel="noopener">First Virtue</a> | 1850 | Occ. Resistance to Status Ailments | 2 | 4 | 6 | 8 | 10 | 33 | 66 | 99 | 132 | 165 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1853" data-img="https://www.bg-wiki.com/images/8/8a/Second_Virtue_description.png" target="_blank" rel="noopener">Second Virtue</a> | 1853 | Enhances | 10 | 20 | 30 | 40 | 50 | 320 | 640 | 960 | 1280 | 1600 | no cap |

### Skill+

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/923" data-img="https://www.bg-wiki.com/images/7/7a/Dryad_Root_description.png" target="_blank" rel="noopener">Dryad Root</a> | 923 | Hand-to-Hand skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/864" data-img="https://static.ffxiah.com/images/icon/864.png" target="_blank" rel="noopener">Handful Of Fish Scales</a> | 864 | Dagger skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/894" data-img="https://www.bg-wiki.com/images/1/18/Beetle_Jaw_description.png" target="_blank" rel="noopener">Beetle Jaw</a> | 894 | Sword skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/916" data-img="https://www.bg-wiki.com/images/e/ee/Cactuar_Needle_description.png" target="_blank" rel="noopener">Cactuar Needle</a> | 916 | Great Sword skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/920" data-img="https://www.bg-wiki.com/images/f/f4/Malboro_Vine_description.png" target="_blank" rel="noopener">Malboro Vine</a> | 920 | Axe skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/925" data-img="https://www.bg-wiki.com/images/f/f8/Giant_Stinger_description.png" target="_blank" rel="noopener">Giant Stinger</a> | 925 | Great Axe skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/940" data-img="https://www.bg-wiki.com/images/9/96/Revival_Root_description.png" target="_blank" rel="noopener">Revival Tree Root</a> | 940 | Scythe skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/944" data-img="https://static.ffxiah.com/images/icon/944.png" target="_blank" rel="noopener">Pinch Of Venom Dust</a> | 944 | Polearm skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/953" data-img="https://www.bg-wiki.com/images/0/06/Treant_Bulb_description.png" target="_blank" rel="noopener">Treant Bulb</a> | 953 | Katana skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1264" data-img="https://static.ffxiah.com/images/icon/1264.png" target="_blank" rel="noopener">Clump Of Great Boyahda Moss</a> | 1264 | Great Katana skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1446" data-img="https://www.bg-wiki.com/images/d/d7/Lacquer_Tree_Log_description.png" target="_blank" rel="noopener">Lacquer Tree Log</a> | 1446 | Club skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1592" data-img="https://www.bg-wiki.com/images/4/4a/Cactuar_Root_description.png" target="_blank" rel="noopener">Cactuar Root</a> | 1592 | Staff skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1616" data-img="https://www.bg-wiki.com/images/9/9e/Antlion_Jaw_description.png" target="_blank" rel="noopener">Antlion Jaw</a> | 1616 | Melee skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1663" data-img="https://www.bg-wiki.com/images/0/08/Arnica_Root_description.png" target="_blank" rel="noopener">Arnica Root</a> | 1663 | Ranged skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1864" data-img="https://www.bg-wiki.com/images/b/ba/H.Q._Antlion_Jaw_description.png" target="_blank" rel="noopener">High-Quality Antlion Jaw</a> | 1864 | Magic skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2361" data-img="https://www.bg-wiki.com/images/c/cd/Ameretat_Vine_description.png" target="_blank" rel="noopener">Ameretat Vine</a> | 2361 | Archery skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2513" data-img="https://www.bg-wiki.com/images/2/2f/Rafflesia_Vine_description.png" target="_blank" rel="noopener">Rafflesia Vine</a> | 2513 | Marksmanship skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2524" data-img="https://www.bg-wiki.com/images/e/e4/Peiste_Stinger_description.png" target="_blank" rel="noopener">Peiste Stinger</a> | 2524 | Throwing skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2936" data-img="https://www.bg-wiki.com/images/8/87/Chasmic_Stinger_description.png" target="_blank" rel="noopener">Chasmic Stinger</a> | 2936 | Shield skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2937" data-img="https://www.bg-wiki.com/images/d/d3/Raskovnik_Vine_description.png" target="_blank" rel="noopener">Raskovnik Vine</a> | 2937 | Parrying Skill | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |

### Weaponskill DMG+

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/1110" data-img="https://static.ffxiah.com/images/icon/1110.png" target="_blank" rel="noopener">Vial Of Black Beetle Blood</a> | 1110 | Weapon Skill Acc | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1473" data-img="https://www.bg-wiki.com/images/5/5d/H.Q._Scp._Shell_description.png" target="_blank" rel="noopener">High-Quality Scorpion Shell</a> | 1473 | Weapon skill damage | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/865" data-img="https://static.ffxiah.com/images/icon/865.png" target="_blank" rel="noopener">Handful Of Nidhoggs Scales</a> | 865 | Sklchn.dmg | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1016" data-img="https://www.bg-wiki.com/images/1/1d/Remi_Shell_description.png" target="_blank" rel="noopener">Remi Shell</a> | 1016 | Backhand Blow DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2013" data-img="https://static.ffxiah.com/images/icon/2013.png" target="_blank" rel="noopener">Vial Of Lizard Blood</a> | 2013 | Spinning Attack DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2014" data-img="https://static.ffxiah.com/images/icon/2014.png" target="_blank" rel="noopener">Vial Of Bird Blood</a> | 2014 | Howling Fist DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2015" data-img="https://static.ffxiah.com/images/icon/2015.png" target="_blank" rel="noopener">Vial Of Beast Blood</a> | 2015 | Dragon Kick DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2229" data-img="https://static.ffxiah.com/images/icon/2229.png" target="_blank" rel="noopener">Vial Of Chimera Blood</a> | 2229 | Viper Bite DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2365" data-img="https://static.ffxiah.com/images/icon/2365.png" target="_blank" rel="noopener">Vial Of Demon Blood</a> | 2365 | Shadowstitch DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/843" data-img="https://www.bg-wiki.com/images/b/b6/G._Bird_Plume_description.png" target="_blank" rel="noopener">Giant Bird Plume</a> | 843 | Cyclone DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/866" data-img="https://static.ffxiah.com/images/icon/866.png" target="_blank" rel="noopener">Handful Of Wyvern Scales</a> | 866 | Evisceration DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1155" data-img="https://static.ffxiah.com/images/icon/1155.png" target="_blank" rel="noopener">Handful Of Iron Sand</a> | 1155 | Burning Blade DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1157" data-img="https://static.ffxiah.com/images/icon/1157.png" target="_blank" rel="noopener">Handful Of The Sands Of Silence</a> | 1157 | Shining Blade DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1455" data-img="https://www.bg-wiki.com/images/3/32/1_Byne_Bill_description.png" target="_blank" rel="noopener">One Byne Bill</a> | 1455 | Circle Blade DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1456" data-img="https://www.bg-wiki.com/images/1/13/100_Byne_Bill_description.png" target="_blank" rel="noopener">One Hundred Byne Bill</a> | 1456 | Savage Blade DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1466" data-img="https://static.ffxiah.com/images/icon/1466.png" target="_blank" rel="noopener">Pile Of Relic Iron</a> | 1466 | Freezebite DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1469" data-img="https://static.ffxiah.com/images/icon/1469.png" target="_blank" rel="noopener">Chunk Of Wootz Ore</a> | 1469 | Shockwave DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1517" data-img="https://www.bg-wiki.com/images/3/38/Giant_Frozen_Head_description.png" target="_blank" rel="noopener">Giant Frozen Head</a> | 1517 | Ground Strike DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1618" data-img="https://www.bg-wiki.com/images/9/94/Uragnite_Shell_description.png" target="_blank" rel="noopener">Uragnite Shell</a> | 1618 | Sickle Moon DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1626" data-img="https://static.ffxiah.com/images/icon/1626.png" target="_blank" rel="noopener">Bottle Of Avatar Blood</a> | 1626 | Gale Axe DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1650" data-img="https://static.ffxiah.com/images/icon/1650.png" target="_blank" rel="noopener">Chunk Of Kopparnickel Ore</a> | 1650 | Spinning Axe DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1700" data-img="https://static.ffxiah.com/images/icon/1700.png" target="_blank" rel="noopener">Spool Of Bloodthread</a> | 1700 | Calamity DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1703" data-img="https://static.ffxiah.com/images/icon/1703.png" target="_blank" rel="noopener">Chunk Of Kunwu Ore</a> | 1703 | Decimation DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1704" data-img="https://static.ffxiah.com/images/icon/1704.png" target="_blank" rel="noopener">Chunk Of Kunwu Iron</a> | 1704 | Iron Tempest DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1719" data-img="https://www.bg-wiki.com/images/6/65/Harajnite_Shell_description.png" target="_blank" rel="noopener">Harajnite Shell</a> | 1719 | Sturmwind DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1852" data-img="https://www.bg-wiki.com/images/c/cb/H.Q._Phuabo_Org._description.png" target="_blank" rel="noopener">High-Quality Phuabo Organ</a> | 1852 | Keen Edge DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1855" data-img="https://www.bg-wiki.com/images/f/fe/H.Q._Xzomit_Organ_description.png" target="_blank" rel="noopener">High-Quality Xzomit Organ</a> | 1855 | Steel Cyclone DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1871" data-img="https://www.bg-wiki.com/images/0/09/H.Q._Hpemde_Org._description.png" target="_blank" rel="noopener">High-Quality Hpemde Organ</a> | 1871 | Nightmare Scythe DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1875" data-img="https://www.bg-wiki.com/images/2/2d/Anct._Beastcoin_description.png" target="_blank" rel="noopener">Ancient Beastcoin</a> | 1875 | Spinning Scythe DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1885" data-img="https://static.ffxiah.com/images/icon/1885.png" target="_blank" rel="noopener">Chunk Of Zincite</a> | 1885 | Vorpal Scythe DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1899" data-img="https://www.bg-wiki.com/images/f/fa/H.Q._Euvhi_Organ_description.png" target="_blank" rel="noopener">High-Quality Euvhi Organ</a> | 1899 | Spiral Hell DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/1900" data-img="https://www.bg-wiki.com/images/e/e5/H.Q._Aern_Organ_description.png" target="_blank" rel="noopener">High-Quality Aern Organ</a> | 1900 | Leg Sweep DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2175" data-img="https://static.ffxiah.com/images/icon/2175.png" target="_blank" rel="noopener">Chunk Of Flan Meat</a> | 2175 | Vorpal Thrust DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2488" data-img="https://static.ffxiah.com/images/icon/2488.png" target="_blank" rel="noopener">Piece Of Alexandrite</a> | 2488 | Skewer DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2849" data-img="https://www.bg-wiki.com/images/f/f7/Likho_Talon_description.png" target="_blank" rel="noopener">Likho Talon</a> | 2849 | Impulse Drive DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2851" data-img="https://www.bg-wiki.com/images/f/fa/Bukktooth_description.png" target="_blank" rel="noopener">Bukktooth</a> | 2851 | Blade To DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/2859" data-img="https://static.ffxiah.com/images/icon/2859.png" target="_blank" rel="noopener">Chunk Of Cobalt Ore</a> | 2859 | Blade Chi DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/3503" data-img="https://static.ffxiah.com/images/icon/3503.png" target="_blank" rel="noopener">Chunk Of Mulcibars Scoria</a> | 3503 | Blade Ten DMG | 9 | 18 | 27 | 36 | 45 | 40 | 80 | 120 | 160 | 200 | no cap |

### Progression (Exp / Cap)

| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|
| <a class="item-link" href="https://www.ffxiah.com/item/2523" data-img="https://www.bg-wiki.com/images/e/ec/Peiste_Skin_description.png" target="_blank" rel="noopener">Peiste Skin</a> | 2523 | Exp. Point +33% | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
| <a class="item-link" href="https://www.ffxiah.com/item/942" data-img="https://www.bg-wiki.com/images/9/90/Phil._Stone_description.png" target="_blank" rel="noopener">Philosophers Stone</a> | 942 | Cap. Point +33% | 1 | 2 | 3 | 4 | 5 | 32 | 64 | 96 | 128 | 160 | no cap |
<!-- DOCGEN:END id="augment-catalog" -->

## Notes

- Catalyst items are existing FFXI items (synth materials, mob drops, vouchers) selected from a non-consumable, non-equippable pool. Trading them at the Augment Moogle is a *new* use; their other functions in crafting and quests still work.
- Augments with `modId=0` in the SQL data (server no-ops) are filtered out — they wouldn't do anything anyway.
- Negative augments on stats that are "good when high" (e.g. `HP-33`) are filtered out. Useful negatives like `Enmity-1`, `Phys.dmg.taken -1%`, and `Spell interruption rate down 1%` are kept.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: c867d07fcce7 -->
_Last updated: 2026-06-18 20:56 UTC_
<!-- DOCGEN:END id="last-updated" -->
