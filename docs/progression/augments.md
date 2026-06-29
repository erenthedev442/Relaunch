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

The table below lists **which catalyst maps to which augment**, organized by tier (T0–T4). Higher tiers drop from tougher monsters and open up as you progress. The **Cap** column shows the hard in-game ceiling where one exists — see [how scaling works](#how-augment-power-scales) above.

<!-- DOCGEN:BEGIN id="augment-catalog" -->
_299 catalyst items across 5 tiers. Each drops (~50%) from a specific monster; trade it to the **Augment Moogle in Leafallia** (`!leaf`) to apply the augment. Cost is **10,000 gil flat per trade** plus the catalyst itself. The **Cap** column is the hard engine ceiling for that stat where one exists (e.g. Haste caps at 25%, damage-taken floors at -50%), or **no cap** for additive stats._

### T0 — Free (Day 1)

No progression gate — available from the first day on any character. These are **job-specific or class-specific** utilities that only meaningfully help a single playstyle: ability delays, pet-ability extensions, proc-chance passives most jobs ignore. Catalysts drop from low-level overworld mobs.

| Augment | Catalyst | Item ID | Cap | Affinity Category |
|---|---|---:|:--:|---|
| Reverse Flourish | <a class="item-link" href="https://www.ffxiah.com/item/1591" data-img="https://www.bg-wiki.com/images/c/c9/H.Q._Coeurl_Hide_description.png" target="_blank" rel="noopener">High-Quality Coeurl Hide</a> | 1591 | no cap | Attack |
| Zanshin | <a class="item-link" href="https://www.ffxiah.com/item/926" data-img="https://www.bg-wiki.com/images/0/0a/Lizard_Tail_description.png" target="_blank" rel="noopener">Lizard Tail</a> | 926 | no cap | DEX |
| Daken | <a class="item-link" href="https://www.ffxiah.com/item/947" data-img="https://static.ffxiah.com/images/icon/947.png" target="_blank" rel="noopener">Jar Of Firesand</a> | 947 | no cap | DEX |
| Rapid Shot | <a class="item-link" href="https://www.ffxiah.com/item/1619" data-img="https://www.bg-wiki.com/images/8/8b/Hippogryph_Fthr._description.png" target="_blank" rel="noopener">Hippogryph Feather</a> | 1619 | no cap | Accuracy |
| Barrage | <a class="item-link" href="https://www.ffxiah.com/item/1199" data-img="https://www.bg-wiki.com/images/f/f2/Northern_Fur_description.png" target="_blank" rel="noopener">Northern Fur</a> | 1199 | no cap | Accuracy |
| Recycle | <a class="item-link" href="https://www.ffxiah.com/item/834" data-img="https://static.ffxiah.com/images/icon/834.png" target="_blank" rel="noopener">Ball Of Saruta Cotton</a> | 834 | no cap | AGI |
| Slow | <a class="item-link" href="https://www.ffxiah.com/item/821" data-img="https://static.ffxiah.com/images/icon/821.png" target="_blank" rel="noopener">Spool Of Rainbow Thread</a> | 821 | +25% | Haste |
| Resist Slow | <a class="item-link" href="https://www.ffxiah.com/item/828" data-img="https://static.ffxiah.com/images/icon/828.png" target="_blank" rel="noopener">Square Of Velvet Cloth</a> | 828 | no cap | Haste |
| Blood Pact ability delay | <a class="item-link" href="https://www.ffxiah.com/item/876" data-img="https://www.bg-wiki.com/images/7/73/Manta_Skin_description.png" target="_blank" rel="noopener">Manta Skin</a> | 876 | no cap | Ability delays |
| Call Beast ability delay | <a class="item-link" href="https://www.ffxiah.com/item/912" data-img="https://www.bg-wiki.com/images/9/9d/Beehive_Chip_description.png" target="_blank" rel="noopener">Beehive Chip</a> | 912 | no cap | Ability delays |
| Quick Draw ability delay | <a class="item-link" href="https://www.ffxiah.com/item/1623" data-img="https://www.bg-wiki.com/images/3/3d/Eft_Skin_description.png" target="_blank" rel="noopener">Eft Skin</a> | 1623 | no cap | Ability delays |
| Phantom Roll ability delay | <a class="item-link" href="https://www.ffxiah.com/item/832" data-img="https://static.ffxiah.com/images/icon/832.png" target="_blank" rel="noopener">Clump Of Sheep Wool</a> | 832 | no cap | Ability delays |
| Elemental Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/849" data-img="https://www.bg-wiki.com/images/1/17/Undead_Skin_description.png" target="_blank" rel="noopener">Undead Skin</a> | 849 | no cap | Elemental / Enfeebling / Enhancing magic recast delays |
| Enfeebling Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/859" data-img="https://www.bg-wiki.com/images/8/80/Ram_Skin_description.png" target="_blank" rel="noopener">Ram Skin</a> | 859 | no cap | Elemental / Enfeebling / Enhancing magic recast delays |
| Enhancing Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/868" data-img="https://static.ffxiah.com/images/icon/868.png" target="_blank" rel="noopener">Handful Of Pugil Scales</a> | 868 | no cap | Elemental / Enfeebling / Enhancing magic recast delays |
| Fire Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2506" data-img="https://www.bg-wiki.com/images/1/1a/Ladybug_Wing_description.png" target="_blank" rel="noopener">Ladybug Wing</a> | 2506 | no cap | Element affinity + magic accuracy |
| Ice Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2509" data-img="https://www.bg-wiki.com/images/3/3a/Slug_Eye_description.png" target="_blank" rel="noopener">Slug Eye</a> | 2509 | no cap | Element affinity + magic accuracy |
| Wind Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2522" data-img="https://www.bg-wiki.com/images/0/08/Gnat_Wing_description.png" target="_blank" rel="noopener">Gnat Wing</a> | 2522 | no cap | Element affinity + magic accuracy |
| Earth Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2749" data-img="https://www.bg-wiki.com/images/f/f0/Gargouille_Eye_description.png" target="_blank" rel="noopener">Gargouille Eye</a> | 2749 | no cap | Element affinity + magic accuracy |
| Lightning Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2890" data-img="https://www.bg-wiki.com/images/3/30/Clionid_Wing_description.png" target="_blank" rel="noopener">Clionid Wing</a> | 2890 | no cap | Element affinity + magic accuracy |
| Water Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/2938" data-img="https://www.bg-wiki.com/images/f/ff/Bakka%27s_Wing_description.png" target="_blank" rel="noopener">Bakkas Wing</a> | 2938 | no cap | Element affinity + magic accuracy |
| Light Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/3502" data-img="https://static.ffxiah.com/images/icon/3502.png" target="_blank" rel="noopener">Vial Of Umbral Marrow</a> | 3502 | no cap | Element affinity + magic accuracy |
| Dark Affinity Magic Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/3930" data-img="https://www.bg-wiki.com/images/6/67/Twitherym_Wing_description.png" target="_blank" rel="noopener">Twitherym Wing</a> | 3930 | no cap | Element affinity + magic accuracy |
| Fire Affinity Magic Accuracy Recast time | <a class="item-link" href="https://www.ffxiah.com/item/3941" data-img="https://www.bg-wiki.com/images/f/f7/Chapuli_Wing_description.png" target="_blank" rel="noopener">Chapuli Wing</a> | 3941 | no cap | Element affinity + magic accuracy |
| Waltz potency | <a class="item-link" href="https://www.ffxiah.com/item/1741" data-img="https://www.bg-wiki.com/images/5/5c/H.Q._Eft_Skin_description.png" target="_blank" rel="noopener">High-Quality Eft Skin</a> | 1741 | no cap | Healing |
| Waltz ability delay | <a class="item-link" href="https://www.ffxiah.com/item/801" data-img="https://www.bg-wiki.com/images/7/7a/Chrysoberyl_description.png" target="_blank" rel="noopener">Chrysoberyl</a> | 801 | no cap | Healing |
| Waltz TP cost | <a class="item-link" href="https://www.ffxiah.com/item/836" data-img="https://static.ffxiah.com/images/icon/836.png" target="_blank" rel="noopener">Square Of Damascene Cloth</a> | 836 | no cap | Healing |
| Healing Magic Recast Delay | <a class="item-link" href="https://www.ffxiah.com/item/838" data-img="https://www.bg-wiki.com/images/b/bd/Spider_Web_description.png" target="_blank" rel="noopener">Spider Web</a> | 838 | no cap | Healing |
| Charm | <a class="item-link" href="https://www.ffxiah.com/item/902" data-img="https://www.bg-wiki.com/images/1/19/Demon_Horn_description.png" target="_blank" rel="noopener">Demon Horn</a> | 902 | no cap | CHR |
| Resist Charm | <a class="item-link" href="https://www.ffxiah.com/item/2372" data-img="https://www.bg-wiki.com/images/6/65/Khimaira_Mane_description.png" target="_blank" rel="noopener">Khimaira Mane</a> | 2372 | no cap | CHR |
| All songs | <a class="item-link" href="https://www.ffxiah.com/item/1291" data-img="https://www.bg-wiki.com/images/9/96/Golden_Hktk._Eye_description.png" target="_blank" rel="noopener">Golden Hakutaku Eye</a> | 1291 | no cap | CHR |
| Song recast delay | <a class="item-link" href="https://www.ffxiah.com/item/817" data-img="https://static.ffxiah.com/images/icon/817.png" target="_blank" rel="noopener">Spool Of Grass Thread</a> | 817 | no cap | CHR |
| Song spellcasting time | <a class="item-link" href="https://www.ffxiah.com/item/2827" data-img="https://static.ffxiah.com/images/icon/2827.png" target="_blank" rel="noopener">Spool Of Rugged Gold Thread</a> | 2827 | no cap | CHR |
| Gilfinder | <a class="item-link" href="https://www.ffxiah.com/item/1858" data-img="https://www.bg-wiki.com/images/b/b7/Moblumin_Ingot_description.png" target="_blank" rel="noopener">Moblumin Ingot</a> | 1858 | no cap | CHR |
| Enmity | <a class="item-link" href="https://www.ffxiah.com/item/787" data-img="https://www.bg-wiki.com/images/6/6e/Diamond_description.png" target="_blank" rel="noopener">Diamond</a> | 787 | no cap | Enmity |
| Enmity | <a class="item-link" href="https://www.ffxiah.com/item/901" data-img="https://www.bg-wiki.com/images/f/fb/Venomous_Claw_description.png" target="_blank" rel="noopener">Venomous Claw</a> | 901 | no cap | Enmity |
| Pet TP Bonus | <a class="item-link" href="https://www.ffxiah.com/item/856" data-img="https://www.bg-wiki.com/images/d/d0/Rabbit_Hide_description.png" target="_blank" rel="noopener">Rabbit Hide</a> | 856 | no cap | Pet stats pulled from old cat 1 |
| Sic and Ready ability delay | <a class="item-link" href="https://www.ffxiah.com/item/810" data-img="https://www.bg-wiki.com/images/a/ad/Fluorite_description.png" target="_blank" rel="noopener">Fluorite</a> | 810 | no cap | Pet stats pulled from old cat 4 |
| Pet Enmity | <a class="item-link" href="https://www.ffxiah.com/item/1408" data-img="https://static.ffxiah.com/images/icon/1408.png" target="_blank" rel="noopener">Bottle Of Illuminink</a> | 1408 | no cap | Pet stats pulled from old cat 7 |
| Pet Enmity | <a class="item-link" href="https://www.ffxiah.com/item/1453" data-img="https://www.bg-wiki.com/images/c/c6/M._Silverpiece_description.png" target="_blank" rel="noopener">Montiont Silverpiece</a> | 1453 | no cap | Pet stats pulled from old cat 7 |
| Blood Boon | <a class="item-link" href="https://www.ffxiah.com/item/852" data-img="https://www.bg-wiki.com/images/8/88/Lizard_Skin_description.png" target="_blank" rel="noopener">Lizard Skin</a> | 852 | no cap | Core pet utilities (old cat 10) |
| Avatar perpetuation cost | <a class="item-link" href="https://www.ffxiah.com/item/1156" data-img="https://www.bg-wiki.com/images/f/fb/Crawler_Calculus_description.png" target="_blank" rel="noopener">Crawler Calculus</a> | 1156 | no cap | Core pet utilities (old cat 10) |
| Elemental Siphon | <a class="item-link" href="https://www.ffxiah.com/item/1272" data-img="https://www.bg-wiki.com/images/e/e7/Arioch_Fang_description.png" target="_blank" rel="noopener">Arioch Fang</a> | 1272 | no cap | Core pet utilities (old cat 10) |
| Fire Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1268" data-img="https://www.bg-wiki.com/images/b/ba/Doll_Gizmo_description.png" target="_blank" rel="noopener">Doll Gizmo</a> | 1268 | no cap | Avatar element affinities (old cat 11) |
| Ice Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1270" data-img="https://www.bg-wiki.com/images/5/51/Arachne_Web_description.png" target="_blank" rel="noopener">Arachne Web</a> | 1270 | no cap | Avatar element affinities (old cat 11) |
| Wind Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1295" data-img="https://www.bg-wiki.com/images/3/36/Twincoon_description.png" target="_blank" rel="noopener">Twincoon</a> | 1295 | no cap | Avatar element affinities (old cat 11) |
| Earth Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1311" data-img="https://static.ffxiah.com/images/icon/1311.png" target="_blank" rel="noopener">Piece Of Oxblood</a> | 1311 | no cap | Avatar element affinities (old cat 11) |
| Water Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1313" data-img="https://static.ffxiah.com/images/icon/1313.png" target="_blank" rel="noopener">Lock Of Sirens Hair</a> | 1313 | no cap | Avatar element affinities (old cat 11) |
| Light Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1414" data-img="https://static.ffxiah.com/images/icon/1414.png" target="_blank" rel="noopener">Piece Of Wisteria Lumber</a> | 1414 | no cap | Avatar element affinities (old cat 11) |
| Dark Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1443" data-img="https://static.ffxiah.com/images/icon/1443.png" target="_blank" rel="noopener">Pinch Of Dried Mugwort</a> | 1443 | no cap | Avatar element affinities (old cat 11) |
| Thunder Affinity Avatar perp. cost | <a class="item-link" href="https://www.ffxiah.com/item/1830" data-img="https://static.ffxiah.com/images/icon/1830.png" target="_blank" rel="noopener">Sack Of Lugworm Sand</a> | 1830 | no cap | Avatar element affinities (old cat 11) |
| Thunder Affinity | <a class="item-link" href="https://www.ffxiah.com/item/2173" data-img="https://www.bg-wiki.com/images/2/24/Wam._Cocoon_description.png" target="_blank" rel="noopener">Wamoura Cocoon</a> | 2173 | no cap | Avatar element affinities (old cat 11) |
| Beast Affinity | <a class="item-link" href="https://www.ffxiah.com/item/2518" data-img="https://static.ffxiah.com/images/icon/2518.png" target="_blank" rel="noopener">Smilodon Hide</a> | 2518 | no cap | Beast affinity |
| Fire resist | <a class="item-link" href="https://www.ffxiah.com/item/837" data-img="https://static.ffxiah.com/images/icon/837.png" target="_blank" rel="noopener">Spool Of Malboro Fiber</a> | 837 | no cap | Ele Resist |
| Ice resist | <a class="item-link" href="https://www.ffxiah.com/item/918" data-img="https://static.ffxiah.com/images/icon/918.png" target="_blank" rel="noopener">Sprig Of Mistletoe</a> | 918 | no cap | Ele Resist |
| Wind resist | <a class="item-link" href="https://www.ffxiah.com/item/928" data-img="https://static.ffxiah.com/images/icon/928.png" target="_blank" rel="noopener">Pinch Of Bomb Ash</a> | 928 | no cap | Ele Resist |
| Earth resist | <a class="item-link" href="https://www.ffxiah.com/item/937" data-img="https://static.ffxiah.com/images/icon/937.png" target="_blank" rel="noopener">Block Of Animal Glue</a> | 937 | no cap | Ele Resist |
| Lightning resist | <a class="item-link" href="https://www.ffxiah.com/item/938" data-img="https://static.ffxiah.com/images/icon/938.png" target="_blank" rel="noopener">Sprig Of Papaka Grass</a> | 938 | no cap | Ele Resist |
| Water resist | <a class="item-link" href="https://www.ffxiah.com/item/943" data-img="https://static.ffxiah.com/images/icon/943.png" target="_blank" rel="noopener">Pinch Of Poison Dust</a> | 943 | no cap | Ele Resist |
| Light resist | <a class="item-link" href="https://www.ffxiah.com/item/948" data-img="https://www.bg-wiki.com/images/5/5f/Carnation_description.png" target="_blank" rel="noopener">Carnation</a> | 948 | no cap | Ele Resist |
| Dark resist | <a class="item-link" href="https://www.ffxiah.com/item/952" data-img="https://static.ffxiah.com/images/icon/952.png" target="_blank" rel="noopener">Bag Of Poison Flour</a> | 952 | no cap | Ele Resist |
| Fire,Wind,Lightning,Light resists | <a class="item-link" href="https://www.ffxiah.com/item/955" data-img="https://www.bg-wiki.com/images/6/62/Golem_Shard_description.png" target="_blank" rel="noopener">Golem Shard</a> | 955 | no cap | Ele Resist |
| Ice,Earth,Water,Dark resists | <a class="item-link" href="https://www.ffxiah.com/item/959" data-img="https://www.bg-wiki.com/images/f/f6/Dahlia_description.png" target="_blank" rel="noopener">Dahlia</a> | 959 | no cap | Ele Resist |
| All elemental resists | <a class="item-link" href="https://www.ffxiah.com/item/1132" data-img="https://static.ffxiah.com/images/icon/1132.png" target="_blank" rel="noopener">Square Of Raxa</a> | 1132 | no cap | Ele Resist |
| All elemental resists | <a class="item-link" href="https://www.ffxiah.com/item/1158" data-img="https://www.bg-wiki.com/images/8/8a/Wandering_Bulb_description.png" target="_blank" rel="noopener">Wandering Bulb</a> | 1158 | no cap | Ele Resist |
| Fire Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1165" data-img="https://www.bg-wiki.com/images/1/16/Doll_Shard_description.png" target="_blank" rel="noopener">Doll Shard</a> | 1165 | no cap | Element affinities (passive elemental identity, not resists) |
| Ice Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1186" data-img="https://www.bg-wiki.com/images/7/70/Bomb_Queen_Core_description.png" target="_blank" rel="noopener">Bomb Queen Core</a> | 1186 | no cap | Element affinities (passive elemental identity, not resists) |
| Wind Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1187" data-img="https://static.ffxiah.com/images/icon/1187.png" target="_blank" rel="noopener">Pinch Of Bomb Queen Ash</a> | 1187 | no cap | Element affinities (passive elemental identity, not resists) |
| Earth Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1200" data-img="https://static.ffxiah.com/images/icon/1200.png" target="_blank" rel="noopener">Piece Of Eastern Pottery</a> | 1200 | no cap | Element affinities (passive elemental identity, not resists) |
| Lightning Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1201" data-img="https://www.bg-wiki.com/images/f/f2/Southern_Mummy_description.png" target="_blank" rel="noopener">Southern Mummy</a> | 1201 | no cap | Element affinities (passive elemental identity, not resists) |
| Water Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1236" data-img="https://static.ffxiah.com/images/icon/1236.png" target="_blank" rel="noopener">Bag Of Cactus Stems</a> | 1236 | no cap | Element affinities (passive elemental identity, not resists) |
| Light Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1237" data-img="https://static.ffxiah.com/images/icon/1237.png" target="_blank" rel="noopener">Bag Of Tree Cuttings</a> | 1237 | no cap | Element affinities (passive elemental identity, not resists) |
| Dark Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1263" data-img="https://www.bg-wiki.com/images/d/d3/Leshonki_Bulb_description.png" target="_blank" rel="noopener">Leshonki Bulb</a> | 1263 | no cap | Element affinities (passive elemental identity, not resists) |
| Ice Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1449" data-img="https://www.bg-wiki.com/images/1/19/T._Whiteshell_description.png" target="_blank" rel="noopener">Tukuku Whiteshell</a> | 1449 | no cap | Element affinities (passive elemental identity, not resists) |
| Wind Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1450" data-img="https://www.bg-wiki.com/images/1/1c/L._Jadeshell_description.png" target="_blank" rel="noopener">Lungo-Nango Jadeshell</a> | 1450 | no cap | Element affinities (passive elemental identity, not resists) |
| Earth Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1464" data-img="https://www.bg-wiki.com/images/6/6f/Lancewood_Log_description.png" target="_blank" rel="noopener">Lancewood Log</a> | 1464 | no cap | Element affinities (passive elemental identity, not resists) |
| Lightning Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1465" data-img="https://static.ffxiah.com/images/icon/1465.png" target="_blank" rel="noopener">Slab Of Granite</a> | 1465 | no cap | Element affinities (passive elemental identity, not resists) |
| Water Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1474" data-img="https://www.bg-wiki.com/images/1/11/Infinity_Core_description.png" target="_blank" rel="noopener">Infinity Core</a> | 1474 | no cap | Element affinities (passive elemental identity, not resists) |
| Light Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1520" data-img="https://static.ffxiah.com/images/icon/1520.png" target="_blank" rel="noopener">Jar Of Goblin Grease</a> | 1520 | no cap | Element affinities (passive elemental identity, not resists) |
| Dark Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1614" data-img="https://www.bg-wiki.com/images/3/36/Corse_Bracelet_description.png" target="_blank" rel="noopener">Corse Bracelet</a> | 1614 | no cap | Element affinities (passive elemental identity, not resists) |
| Ice Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1624" data-img="https://www.bg-wiki.com/images/0/08/Bugbear_Mask_description.png" target="_blank" rel="noopener">Bugbear Mask</a> | 1624 | no cap | Element affinities (passive elemental identity, not resists) |
| Wind Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1625" data-img="https://www.bg-wiki.com/images/f/f3/Moblin_Helm_description.png" target="_blank" rel="noopener">Moblin Helm</a> | 1625 | no cap | Element affinities (passive elemental identity, not resists) |
| Earth Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1631" data-img="https://www.bg-wiki.com/images/e/e0/Moblin_Armor_description.png" target="_blank" rel="noopener">Moblin Armor</a> | 1631 | no cap | Element affinities (passive elemental identity, not resists) |
| Lightning Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1632" data-img="https://www.bg-wiki.com/images/6/67/Moblin_Mail_description.png" target="_blank" rel="noopener">Moblin Mail</a> | 1632 | no cap | Element affinities (passive elemental identity, not resists) |
| Water Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1639" data-img="https://www.bg-wiki.com/images/3/30/Corse_Robe_description.png" target="_blank" rel="noopener">Corse Robe</a> | 1639 | no cap | Element affinities (passive elemental identity, not resists) |
| Light Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1651" data-img="https://static.ffxiah.com/images/icon/1651.png" target="_blank" rel="noopener">Spool Of Moblin Thread</a> | 1651 | no cap | Element affinities (passive elemental identity, not resists) |
| Dark Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1664" data-img="https://www.bg-wiki.com/images/d/df/Eastern_Gem_description.png" target="_blank" rel="noopener">Eastern Gem</a> | 1664 | no cap | Element affinities (passive elemental identity, not resists) |
| Ice Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1669" data-img="https://static.ffxiah.com/images/icon/1669.png" target="_blank" rel="noopener">Pinch Of Hoary Bomb Ash</a> | 1669 | no cap | Element affinities (passive elemental identity, not resists) |
| Wind Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1687" data-img="https://static.ffxiah.com/images/icon/1687.png" target="_blank" rel="noopener">Recollection Of Fear</a> | 1687 | no cap | Element affinities (passive elemental identity, not resists) |
| Earth Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1688" data-img="https://static.ffxiah.com/images/icon/1688.png" target="_blank" rel="noopener">Recollection Of Pain</a> | 1688 | no cap | Element affinities (passive elemental identity, not resists) |
| Lightning Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1689" data-img="https://static.ffxiah.com/images/icon/1689.png" target="_blank" rel="noopener">Recollection Of Guilt</a> | 1689 | no cap | Element affinities (passive elemental identity, not resists) |
| Water Affintiy | <a class="item-link" href="https://www.ffxiah.com/item/1712" data-img="https://static.ffxiah.com/images/icon/1712.png" target="_blank" rel="noopener">Clump Of Cashmere Wool</a> | 1712 | no cap | Element affinities (passive elemental identity, not resists) |
| Light Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1714" data-img="https://static.ffxiah.com/images/icon/1714.png" target="_blank" rel="noopener">Square Of Cashmere Cloth</a> | 1714 | no cap | Element affinities (passive elemental identity, not resists) |
| Dark Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1724" data-img="https://www.bg-wiki.com/images/d/d8/Soulflayer_Robe_description.png" target="_blank" rel="noopener">Soulflayer Robe</a> | 1724 | no cap | Element affinities (passive elemental identity, not resists) |
| Ice Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1738" data-img="https://www.bg-wiki.com/images/1/1b/Shakudo_Ingot_description.png" target="_blank" rel="noopener">Shakudo Ingot</a> | 1738 | no cap | Element affinities (passive elemental identity, not resists) |
| Wind Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1739" data-img="https://static.ffxiah.com/images/icon/1739.png" target="_blank" rel="noopener">Square Of Balloon Cloth</a> | 1739 | no cap | Element affinities (passive elemental identity, not resists) |
| Earth Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1831" data-img="https://static.ffxiah.com/images/icon/1831.png" target="_blank" rel="noopener">Sack Of Little Worm Mulch</a> | 1831 | no cap | Element affinities (passive elemental identity, not resists) |
| Lightning Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1836" data-img="https://www.bg-wiki.com/images/6/69/Marble_description.png" target="_blank" rel="noopener">Marble Slab</a> | 1836 | no cap | Element affinities (passive elemental identity, not resists) |
| Water Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1843" data-img="https://static.ffxiah.com/images/icon/1843.png" target="_blank" rel="noopener">Square Of Spectral Crimson</a> | 1843 | no cap | Element affinities (passive elemental identity, not resists) |
| Light Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1847" data-img="https://www.bg-wiki.com/images/1/12/Fifth_Virtue_description.png" target="_blank" rel="noopener">Fifth Virtue</a> | 1847 | no cap | Element affinities (passive elemental identity, not resists) |
| Dark Affinity | <a class="item-link" href="https://www.ffxiah.com/item/1848" data-img="https://www.bg-wiki.com/images/e/e4/Fourth_Virtue_description.png" target="_blank" rel="noopener">Fourth Virtue</a> | 1848 | no cap | Element affinities (passive elemental identity, not resists) |
| Enhances | <a class="item-link" href="https://www.ffxiah.com/item/1850" data-img="https://www.bg-wiki.com/images/1/1b/First_Virtue_description.png" target="_blank" rel="noopener">First Virtue</a> | 1850 | no cap | Element affinities (passive elemental identity, not resists) |
| Occ. inc. resist to stat ailments | <a class="item-link" href="https://www.ffxiah.com/item/2831" data-img="https://www.bg-wiki.com/images/b/b1/Yel._Brass_Chain_description.png" target="_blank" rel="noopener">Yellow Brass Chain</a> | 2831 | no cap | Status |
| Occ. Resistance to Status Ailments | <a class="item-link" href="https://www.ffxiah.com/item/1849" data-img="https://www.bg-wiki.com/images/2/27/Sixth_Virtue_description.png" target="_blank" rel="noopener">Sixth Virtue</a> | 1849 | no cap | Status |
| Resist Sleep | <a class="item-link" href="https://www.ffxiah.com/item/1163" data-img="https://static.ffxiah.com/images/icon/1163.png" target="_blank" rel="noopener">Lock Of Manticore Hair</a> | 1163 | no cap | Status |
| Resist Poison | <a class="item-link" href="https://www.ffxiah.com/item/1452" data-img="https://www.bg-wiki.com/images/4/48/O._Bronzepiece_description.png" target="_blank" rel="noopener">Ordelle Bronzepiece</a> | 1452 | no cap | Status |
| Resist Paralyze | <a class="item-link" href="https://www.ffxiah.com/item/1630" data-img="https://static.ffxiah.com/images/icon/1630.png" target="_blank" rel="noopener">Pinch Of Cluster Ash</a> | 1630 | no cap | Status |
| Resist Blind | <a class="item-link" href="https://www.ffxiah.com/item/1638" data-img="https://www.bg-wiki.com/images/7/73/Moblin_Mask_description.png" target="_blank" rel="noopener">Moblin Mask</a> | 1638 | no cap | Status |
| Resist Silence | <a class="item-link" href="https://www.ffxiah.com/item/1667" data-img="https://www.bg-wiki.com/images/a/af/Cluster_Core_description.png" target="_blank" rel="noopener">Cluster Core</a> | 1667 | no cap | Status |
| Resist Virus | <a class="item-link" href="https://www.ffxiah.com/item/2337" data-img="https://static.ffxiah.com/images/icon/2337.png" target="_blank" rel="noopener">Clump Of Wamoura Hair</a> | 2337 | no cap | Status |
| Resist Petrify | <a class="item-link" href="https://www.ffxiah.com/item/2549" data-img="https://static.ffxiah.com/images/icon/2549.png" target="_blank" rel="noopener">Pinch Of Djinn Ash</a> | 2549 | no cap | Status |
| Resist Bind | <a class="item-link" href="https://www.ffxiah.com/item/2860" data-img="https://static.ffxiah.com/images/icon/2860.png" target="_blank" rel="noopener">Slab Of Plumbago</a> | 2860 | no cap | Status |
| Resist Curse | <a class="item-link" href="https://www.ffxiah.com/item/784" data-img="https://www.bg-wiki.com/images/e/eb/Jadeite_description.png" target="_blank" rel="noopener">Jadeite</a> | 784 | no cap | Status |
| Resist Gravity | <a class="item-link" href="https://www.ffxiah.com/item/797" data-img="https://www.bg-wiki.com/images/f/f9/Painite_description.png" target="_blank" rel="noopener">Painite</a> | 797 | no cap | Status |
| Resist Stun | <a class="item-link" href="https://www.ffxiah.com/item/805" data-img="https://www.bg-wiki.com/images/0/0b/Zircon_description.png" target="_blank" rel="noopener">Zircon</a> | 805 | no cap | Status |
| Exp. Point +33% | <a class="item-link" href="https://www.ffxiah.com/item/2523" data-img="https://www.bg-wiki.com/images/e/ec/Peiste_Skin_description.png" target="_blank" rel="noopener">Peiste Skin</a> | 2523 | no cap | Exp/Cap points |
| Ninja tool expertise | <a class="item-link" href="https://www.ffxiah.com/item/1269" data-img="https://www.bg-wiki.com/images/6/67/Mana_Barrel_description.png" target="_blank" rel="noopener">Mana Barrel</a> | 1269 | no cap | Job-specific niche utilities |
| Repair potency | <a class="item-link" href="https://www.ffxiah.com/item/2729" data-img="https://www.bg-wiki.com/images/b/b9/Hydrangea_description.png" target="_blank" rel="noopener">Hydrangea</a> | 2729 | no cap | Job-specific niche utilities |
| Indi Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2641" data-img="https://www.bg-wiki.com/images/4/4e/Amb._Pseudopod_description.png" target="_blank" rel="noopener">Amoeban Pseudopod</a> | 2641 | no cap | Job-specific niche utilities |

### T1 — Initiate (Hunting League Rank 3)

Opens at **Hunting League Rank 3**. Practical job abilities and defensive options useful to a wider range of jobs — counter/parry/evasion, spell interruption, elemental affinities, shield tech. Catalysts drop from mid-level mobs.

| Augment | Catalyst | Item ID | Cap | Affinity Category |
|---|---|---:|:--:|---|
| Counter | <a class="item-link" href="https://www.ffxiah.com/item/895" data-img="https://www.bg-wiki.com/images/b/bb/Ram_Horn_description.png" target="_blank" rel="noopener">Ram Horn</a> | 895 | no cap | STR |
| Martial Arts | <a class="item-link" href="https://www.ffxiah.com/item/897" data-img="https://www.bg-wiki.com/images/9/92/Scorpion_Claw_description.png" target="_blank" rel="noopener">Scorpion Claw</a> | 897 | no cap | STR |
| Kick Attacks Rate or Damage | <a class="item-link" href="https://www.ffxiah.com/item/903" data-img="https://www.bg-wiki.com/images/3/30/Dragon_Talon_description.png" target="_blank" rel="noopener">Dragon Talon</a> | 903 | no cap | STR |
| Meditate Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2711" data-img="https://www.bg-wiki.com/images/b/b7/Khroma_Nugget_description.png" target="_blank" rel="noopener">Khroma Nugget</a> | 2711 | no cap | Attack |
| Breath dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/1193" data-img="https://www.bg-wiki.com/images/2/29/H.Q._Crab_Shell_description.png" target="_blank" rel="noopener">High-Quality Crab Shell</a> | 1193 | -50% | Defense |
| Shield Mastery | <a class="item-link" href="https://www.ffxiah.com/item/770" data-img="https://www.bg-wiki.com/images/e/e5/Blue_Rock_description.png" target="_blank" rel="noopener">Blue Rock</a> | 770 | no cap | Defense |
| Chance of successful block | <a class="item-link" href="https://www.ffxiah.com/item/771" data-img="https://www.bg-wiki.com/images/b/b1/Yellow_Rock_description.png" target="_blank" rel="noopener">Yellow Rock</a> | 771 | no cap | Defense |
| Parrying rate | <a class="item-link" href="https://www.ffxiah.com/item/776" data-img="https://www.bg-wiki.com/images/e/e9/White_Rock_description.png" target="_blank" rel="noopener">White Rock</a> | 776 | no cap | Defense |
| Evasion | <a class="item-link" href="https://www.ffxiah.com/item/1617" data-img="https://www.bg-wiki.com/images/b/bd/Flytrap_Leaf_description.png" target="_blank" rel="noopener">Flytrap Leaf</a> | 1617 | no cap | Evasion |
| Mag. Evasion | <a class="item-link" href="https://www.ffxiah.com/item/1713" data-img="https://static.ffxiah.com/images/icon/1713.png" target="_blank" rel="noopener">Spool Of Cashmere Thread</a> | 1713 | no cap | Evasion |
| Enhancing Magic Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2510" data-img="https://www.bg-wiki.com/images/0/04/Orc_Helmet_description.png" target="_blank" rel="noopener">Orc Helmet</a> | 2510 | no cap | INT |
| Helix Effect Duration | <a class="item-link" href="https://www.ffxiah.com/item/2640" data-img="https://www.bg-wiki.com/images/0/01/Murex_Spicule_description.png" target="_blank" rel="noopener">Murex Spicule</a> | 2640 | no cap | INT |
| Drain/Aspir Potency | <a class="item-link" href="https://www.ffxiah.com/item/2943" data-img="https://www.bg-wiki.com/images/5/57/Balaur_Skull_description.png" target="_blank" rel="noopener">Balaur Skull</a> | 2943 | no cap | Magic ATK |
| Spell interruption rate down 1% | <a class="item-link" href="https://www.ffxiah.com/item/854" data-img="https://www.bg-wiki.com/images/6/6d/Cockatrice_Skin_description.png" target="_blank" rel="noopener">Cockatrice Skin</a> | 854 | no cap | Magic ATK |
| Spell Interruption Rate Down 2% | <a class="item-link" href="https://www.ffxiah.com/item/2834" data-img="https://www.bg-wiki.com/images/0/08/Immortal_Molt_description.png" target="_blank" rel="noopener">Immortal Molt</a> | 2834 | no cap | Magic ATK |
| Occ. quickens spellcasting | <a class="item-link" href="https://www.ffxiah.com/item/2507" data-img="https://www.bg-wiki.com/images/6/67/Lycopodium_Flower_description.png" target="_blank" rel="noopener">Lycopodium Flower</a> | 2507 | no cap | Magic ATK |
| Healing magic skill | <a class="item-link" href="https://www.ffxiah.com/item/792" data-img="https://www.bg-wiki.com/images/9/9d/Pearl_description.png" target="_blank" rel="noopener">Pearl</a> | 792 | no cap | Healing |
| Cure spellcasting time | <a class="item-link" href="https://www.ffxiah.com/item/793" data-img="https://www.bg-wiki.com/images/e/e7/Black_Pearl_description.png" target="_blank" rel="noopener">Black Pearl</a> | 793 | no cap | Healing |
| HP recovered while healing | <a class="item-link" href="https://www.ffxiah.com/item/1122" data-img="https://www.bg-wiki.com/images/e/e5/Wyvern_Skin_description.png" target="_blank" rel="noopener">Wyvern Skin</a> | 1122 | no cap | Regen |
| MP recovered while healing | <a class="item-link" href="https://www.ffxiah.com/item/791" data-img="https://www.bg-wiki.com/images/7/77/Aquamarine_description.png" target="_blank" rel="noopener">Aquamarine</a> | 791 | no cap | MP |
| Pet Attack Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/1615" data-img="https://www.bg-wiki.com/images/f/f1/Buffalo_Horn_description.png" target="_blank" rel="noopener">Buffalo Horn</a> | 1615 | no cap | Pet stats pulled from old cat 1 |
| Pet Attack Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/1622" data-img="https://www.bg-wiki.com/images/4/48/Bugard_Tusk_description.png" target="_blank" rel="noopener">Bugard Tusk</a> | 1622 | no cap | Pet stats pulled from old cat 1 |
| Pet Dbl.Atk. Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/1718" data-img="https://www.bg-wiki.com/images/6/64/M-bugard_Tusk_description.png" target="_blank" rel="noopener">Megalobugard Tusk</a> | 1718 | no cap | Pet stats pulled from old cat 1 |
| Pet Damage taken | <a class="item-link" href="https://www.ffxiah.com/item/786" data-img="https://www.bg-wiki.com/images/8/88/Ruby_description.png" target="_blank" rel="noopener">Ruby</a> | 786 | no cap | Pet stats pulled from old cat 1 |
| Pet Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/853" data-img="https://www.bg-wiki.com/images/4/40/Raptor_Skin_description.png" target="_blank" rel="noopener">Raptor Skin</a> | 853 | no cap | Pet stats pulled from old cat 1 |
| Pet Phys. dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/855" data-img="https://static.ffxiah.com/images/icon/855.png" target="_blank" rel="noopener">Square Of Black Tiger Leather</a> | 855 | no cap | Pet stats pulled from old cat 1 |
| Pet Dbl.Att | <a class="item-link" href="https://www.ffxiah.com/item/857" data-img="https://www.bg-wiki.com/images/c/c4/Dhalmel_Hide_description.png" target="_blank" rel="noopener">Dhalmel Hide</a> | 857 | no cap | Pet stats pulled from old cat 1 |
| Pet Magic Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/863" data-img="https://www.bg-wiki.com/images/8/8a/Coeurl_Hide_description.png" target="_blank" rel="noopener">Coeurl Hide</a> | 863 | no cap | Pet stats pulled from old cat 1 |
| Pet STR | <a class="item-link" href="https://www.ffxiah.com/item/2168" data-img="https://www.bg-wiki.com/images/9/9f/Cerberus_Claw_description.png" target="_blank" rel="noopener">Cerberus Claw</a> | 2168 | no cap | Pet stats pulled from old cat 1 |
| Pet STR DEX VIT | <a class="item-link" href="https://www.ffxiah.com/item/2169" data-img="https://www.bg-wiki.com/images/0/05/Cerberus_Hide_description.png" target="_blank" rel="noopener">Cerberus Hide</a> | 2169 | no cap | Pet stats pulled from old cat 1 |
| Pet Accuracy Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/922" data-img="https://www.bg-wiki.com/images/0/0c/Bat_Wing_description.png" target="_blank" rel="noopener">Bat Wing</a> | 922 | no cap | Pet stats pulled from old cat 2 |
| Pet Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/935" data-img="https://www.bg-wiki.com/images/6/6a/Ahriman_Wing_description.png" target="_blank" rel="noopener">Ahriman Wing</a> | 935 | no cap | Pet stats pulled from old cat 2 |
| Pet Enemy crit. hit rate | <a class="item-link" href="https://www.ffxiah.com/item/939" data-img="https://www.bg-wiki.com/images/3/33/Hecteyes_Eye_description.png" target="_blank" rel="noopener">Hecteyes Eye</a> | 939 | no cap | Pet stats pulled from old cat 2 |
| Pet Accuracy Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/1124" data-img="https://www.bg-wiki.com/images/7/75/Wyvern_Wing_description.png" target="_blank" rel="noopener">Wyvern Wing</a> | 1124 | no cap | Pet stats pulled from old cat 2 |
| Pet Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/1288" data-img="https://www.bg-wiki.com/images/0/0e/Wooden_Hktk._Eye_description.png" target="_blank" rel="noopener">Wooden Hakutaku Eye</a> | 1288 | no cap | Pet stats pulled from old cat 2 |
| Pet Store TP | <a class="item-link" href="https://www.ffxiah.com/item/1289" data-img="https://www.bg-wiki.com/images/2/2d/Burning_Hktk._Eye_description.png" target="_blank" rel="noopener">Burning Hakutaku Eye</a> | 1289 | no cap | Pet stats pulled from old cat 2 |
| Pet Subtle Blow | <a class="item-link" href="https://www.ffxiah.com/item/1290" data-img="https://www.bg-wiki.com/images/9/93/Earthen_Hktk._Eye_description.png" target="_blank" rel="noopener">Earthen Hakutaku Eye</a> | 1290 | no cap | Pet stats pulled from old cat 2 |
| Pet DEX | <a class="item-link" href="https://www.ffxiah.com/item/2842" data-img="https://www.bg-wiki.com/images/6/69/Flawed_Garnet_description.png" target="_blank" rel="noopener">Flawed Garnet</a> | 2842 | no cap | Pet stats pulled from old cat 2 |
| Pet DEF | <a class="item-link" href="https://www.ffxiah.com/item/2854" data-img="https://www.bg-wiki.com/images/c/c8/Stately_Crab_Sh._description.png" target="_blank" rel="noopener">Stately Crab Shell</a> | 2854 | no cap | Pet stats pulled from old cat 3 |
| Pet Mag.Def.Bns | <a class="item-link" href="https://www.ffxiah.com/item/768" data-img="https://www.bg-wiki.com/images/3/37/Flint_Stone_description.png" target="_blank" rel="noopener">Flint Stone</a> | 768 | no cap | Pet stats pulled from old cat 3 |
| Pet Magic Dmg. Taken | <a class="item-link" href="https://www.ffxiah.com/item/775" data-img="https://www.bg-wiki.com/images/2/21/Black_Rock_description.png" target="_blank" rel="noopener">Black Rock</a> | 775 | no cap | Pet stats pulled from old cat 3 |
| Pet VIT | <a class="item-link" href="https://www.ffxiah.com/item/803" data-img="https://www.bg-wiki.com/images/f/f7/Sunstone_description.png" target="_blank" rel="noopener">Sunstone</a> | 803 | no cap | Pet stats pulled from old cat 3 |
| Pet Evasion | <a class="item-link" href="https://www.ffxiah.com/item/825" data-img="https://static.ffxiah.com/images/icon/825.png" target="_blank" rel="noopener">Square Of Cotton Cloth</a> | 825 | no cap | Pet stats pulled from old cat 4 |
| Pet Mag. Evasion | <a class="item-link" href="https://www.ffxiah.com/item/827" data-img="https://static.ffxiah.com/images/icon/827.png" target="_blank" rel="noopener">Square Of Wool Cloth</a> | 827 | no cap | Pet stats pulled from old cat 4 |
| Pet AGI | <a class="item-link" href="https://www.ffxiah.com/item/1861" data-img="https://www.bg-wiki.com/images/c/cc/Moblin_Sheepskin_description.png" target="_blank" rel="noopener">Moblin Sheepskin</a> | 1861 | no cap | Pet stats pulled from old cat 4 |
| Pet Mag.Acc | <a class="item-link" href="https://www.ffxiah.com/item/914" data-img="https://static.ffxiah.com/images/icon/914.png" target="_blank" rel="noopener">Vial Of Mercury</a> | 914 | no cap | Pet stats pulled from old cat 5 |
| Pet Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/954" data-img="https://www.bg-wiki.com/images/c/c6/Magic_Pot_Shard_description.png" target="_blank" rel="noopener">Magic Pot Shard</a> | 954 | no cap | Pet stats pulled from old cat 5 |
| Pet Mag.Acc. Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/1518" data-img="https://www.bg-wiki.com/images/b/b3/Colossal_Skull_description.png" target="_blank" rel="noopener">Colossal Skull</a> | 1518 | no cap | Pet stats pulled from old cat 5 |
| Avatar Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/1521" data-img="https://static.ffxiah.com/images/icon/1521.png" target="_blank" rel="noopener">Vial Of Slime Juice</a> | 1521 | no cap | Pet stats pulled from old cat 5 |
| Pet Mag.Acc. Mag.Dmg | <a class="item-link" href="https://www.ffxiah.com/item/2157" data-img="https://www.bg-wiki.com/images/d/d4/Imp_Horn_description.png" target="_blank" rel="noopener">Imp Horn</a> | 2157 | no cap | Pet stats pulled from old cat 5 |
| Pet Magic Damage | <a class="item-link" href="https://www.ffxiah.com/item/2163" data-img="https://www.bg-wiki.com/images/c/cb/Imp_Wing_description.png" target="_blank" rel="noopener">Imp Wing</a> | 2163 | no cap | Pet stats pulled from old cat 5 |
| Pet INT | <a class="item-link" href="https://www.ffxiah.com/item/2847" data-img="https://www.bg-wiki.com/images/0/07/Blue_Jasper_description.png" target="_blank" rel="noopener">Blue Jasper</a> | 2847 | no cap | Pet stats pulled from old cat 5 |
| Pet MND | <a class="item-link" href="https://www.ffxiah.com/item/2198" data-img="https://www.bg-wiki.com/images/0/04/W._Spider%27s_Web_description.png" target="_blank" rel="noopener">Water Spiders Web</a> | 2198 | no cap | Pet stats pulled from old cat 6 |
| Pet CHR | <a class="item-link" href="https://www.ffxiah.com/item/2850" data-img="https://static.ffxiah.com/images/icon/2850.png" target="_blank" rel="noopener">Ingot Of Sahagin Gold</a> | 2850 | no cap | Pet stats pulled from old cat 7 |
| Pet Regen | <a class="item-link" href="https://www.ffxiah.com/item/1133" data-img="https://static.ffxiah.com/images/icon/1133.png" target="_blank" rel="noopener">Vial Of Dragon Blood</a> | 1133 | no cap | Pet stats pulled from old cat 8 |
| Pet Acc R.Acc Atk. R.Atk | <a class="item-link" href="https://www.ffxiah.com/item/839" data-img="https://static.ffxiah.com/images/icon/839.png" target="_blank" rel="noopener">Piece Of Crawler Cocoon</a> | 839 | no cap | Core pet utilities (old cat 10) |
| Summoning magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1015" data-img="https://www.bg-wiki.com/images/1/1b/Sand_Bat_Fang_description.png" target="_blank" rel="noopener">Sand Bat Fang</a> | 1015 | no cap | Core pet utilities (old cat 10) |
| Avatar Blood Pact Dmg | <a class="item-link" href="https://www.ffxiah.com/item/1445" data-img="https://www.bg-wiki.com/images/9/9f/Freya%27s_Tear_description.png" target="_blank" rel="noopener">Freyas Tear</a> | 1445 | no cap | Core pet utilities (old cat 10) |
| Pet Phy. Dmg. Taken | <a class="item-link" href="https://www.ffxiah.com/item/1979" data-img="https://static.ffxiah.com/images/icon/1979.png" target="_blank" rel="noopener">Cup Of Leech Saliva</a> | 1979 | no cap | Core pet utilities (old cat 10) |
| Hand-to-Hand skill | <a class="item-link" href="https://www.ffxiah.com/item/923" data-img="https://www.bg-wiki.com/images/7/7a/Dryad_Root_description.png" target="_blank" rel="noopener">Dryad Root</a> | 923 | no cap | Weapon skills |
| Dagger skill | <a class="item-link" href="https://www.ffxiah.com/item/864" data-img="https://static.ffxiah.com/images/icon/864.png" target="_blank" rel="noopener">Handful Of Fish Scales</a> | 864 | no cap | Weapon skills |
| Sword skill | <a class="item-link" href="https://www.ffxiah.com/item/894" data-img="https://www.bg-wiki.com/images/1/18/Beetle_Jaw_description.png" target="_blank" rel="noopener">Beetle Jaw</a> | 894 | no cap | Weapon skills |
| Great Sword skill | <a class="item-link" href="https://www.ffxiah.com/item/916" data-img="https://www.bg-wiki.com/images/e/ee/Cactuar_Needle_description.png" target="_blank" rel="noopener">Cactuar Needle</a> | 916 | no cap | Weapon skills |
| Axe skill | <a class="item-link" href="https://www.ffxiah.com/item/920" data-img="https://www.bg-wiki.com/images/f/f4/Malboro_Vine_description.png" target="_blank" rel="noopener">Malboro Vine</a> | 920 | no cap | Weapon skills |
| Great Axe skill | <a class="item-link" href="https://www.ffxiah.com/item/925" data-img="https://www.bg-wiki.com/images/f/f8/Giant_Stinger_description.png" target="_blank" rel="noopener">Giant Stinger</a> | 925 | no cap | Weapon skills |
| Scythe skill | <a class="item-link" href="https://www.ffxiah.com/item/940" data-img="https://www.bg-wiki.com/images/9/96/Revival_Root_description.png" target="_blank" rel="noopener">Revival Tree Root</a> | 940 | no cap | Weapon skills |
| Polearm skill | <a class="item-link" href="https://www.ffxiah.com/item/944" data-img="https://static.ffxiah.com/images/icon/944.png" target="_blank" rel="noopener">Pinch Of Venom Dust</a> | 944 | no cap | Weapon skills |
| Katana skill | <a class="item-link" href="https://www.ffxiah.com/item/953" data-img="https://www.bg-wiki.com/images/0/06/Treant_Bulb_description.png" target="_blank" rel="noopener">Treant Bulb</a> | 953 | no cap | Weapon skills |
| Great Katana skill | <a class="item-link" href="https://www.ffxiah.com/item/1264" data-img="https://static.ffxiah.com/images/icon/1264.png" target="_blank" rel="noopener">Clump Of Great Boyahda Moss</a> | 1264 | no cap | Weapon skills |
| Club skill | <a class="item-link" href="https://www.ffxiah.com/item/1446" data-img="https://www.bg-wiki.com/images/d/d7/Lacquer_Tree_Log_description.png" target="_blank" rel="noopener">Lacquer Tree Log</a> | 1446 | no cap | Weapon skills |
| Staff skill | <a class="item-link" href="https://www.ffxiah.com/item/1592" data-img="https://www.bg-wiki.com/images/4/4a/Cactuar_Root_description.png" target="_blank" rel="noopener">Cactuar Root</a> | 1592 | no cap | Weapon skills |
| Melee skill | <a class="item-link" href="https://www.ffxiah.com/item/1616" data-img="https://www.bg-wiki.com/images/9/9e/Antlion_Jaw_description.png" target="_blank" rel="noopener">Antlion Jaw</a> | 1616 | no cap | Weapon skills |
| Ranged skill | <a class="item-link" href="https://www.ffxiah.com/item/1663" data-img="https://www.bg-wiki.com/images/0/08/Arnica_Root_description.png" target="_blank" rel="noopener">Arnica Root</a> | 1663 | no cap | Weapon skills |
| Magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1864" data-img="https://www.bg-wiki.com/images/b/ba/H.Q._Antlion_Jaw_description.png" target="_blank" rel="noopener">High-Quality Antlion Jaw</a> | 1864 | no cap | Weapon skills |
| Archery skill | <a class="item-link" href="https://www.ffxiah.com/item/2361" data-img="https://www.bg-wiki.com/images/c/cd/Ameretat_Vine_description.png" target="_blank" rel="noopener">Ameretat Vine</a> | 2361 | no cap | Weapon skills |
| Marksmanship skill | <a class="item-link" href="https://www.ffxiah.com/item/2513" data-img="https://www.bg-wiki.com/images/2/2f/Rafflesia_Vine_description.png" target="_blank" rel="noopener">Rafflesia Vine</a> | 2513 | no cap | Weapon skills |
| Throwing skill | <a class="item-link" href="https://www.ffxiah.com/item/2524" data-img="https://www.bg-wiki.com/images/e/e4/Peiste_Stinger_description.png" target="_blank" rel="noopener">Peiste Stinger</a> | 2524 | no cap | Weapon skills |
| Shield skill | <a class="item-link" href="https://www.ffxiah.com/item/2936" data-img="https://www.bg-wiki.com/images/8/87/Chasmic_Stinger_description.png" target="_blank" rel="noopener">Chasmic Stinger</a> | 2936 | no cap | Weapon skills |
| Parrying Skill | <a class="item-link" href="https://www.ffxiah.com/item/2937" data-img="https://www.bg-wiki.com/images/d/d3/Raskovnik_Vine_description.png" target="_blank" rel="noopener">Raskovnik Vine</a> | 2937 | no cap | Weapon skills |
| Divine magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1725" data-img="https://www.bg-wiki.com/images/4/4a/Snow_Lily_description.png" target="_blank" rel="noopener">Snow Lily</a> | 1725 | no cap | Magic skills |
| Dark magic skill | <a class="item-link" href="https://www.ffxiah.com/item/824" data-img="https://static.ffxiah.com/images/icon/824.png" target="_blank" rel="noopener">Square Of Grass Cloth</a> | 824 | no cap | Magic skills |
| Enha.mag. skill | <a class="item-link" href="https://www.ffxiah.com/item/1740" data-img="https://www.bg-wiki.com/images/1/1f/Iolite_description.png" target="_blank" rel="noopener">Iolite</a> | 1740 | no cap | Magic skills |
| Enfb.mag. skill | <a class="item-link" href="https://www.ffxiah.com/item/1817" data-img="https://www.bg-wiki.com/images/f/f4/Cactus_Arm_description.png" target="_blank" rel="noopener">Cactus Arm</a> | 1817 | no cap | Magic skills |
| Elem. magic skill | <a class="item-link" href="https://www.ffxiah.com/item/1854" data-img="https://static.ffxiah.com/images/icon/1854.png" target="_blank" rel="noopener">Deed Of Moderation</a> | 1854 | no cap | Magic skills |
| Ninjutsu skill | <a class="item-link" href="https://www.ffxiah.com/item/2154" data-img="https://www.bg-wiki.com/images/1/17/Orobon_Lure_description.png" target="_blank" rel="noopener">Orobon Lure</a> | 2154 | no cap | Magic skills |
| Singing skill | <a class="item-link" href="https://www.ffxiah.com/item/2155" data-img="https://www.bg-wiki.com/images/d/d4/Lesser_Chigoe_description.png" target="_blank" rel="noopener">Lesser Chigoe</a> | 2155 | no cap | Magic skills |
| String instrument skill | <a class="item-link" href="https://www.ffxiah.com/item/2161" data-img="https://www.bg-wiki.com/images/2/24/Troll_Vambrace_description.png" target="_blank" rel="noopener">Troll Vambrace</a> | 2161 | no cap | Magic skills |
| Wind instrument skill | <a class="item-link" href="https://www.ffxiah.com/item/831" data-img="https://static.ffxiah.com/images/icon/831.png" target="_blank" rel="noopener">Square Of Shining Cloth</a> | 831 | no cap | Magic skills |
| Blue Magic skill | <a class="item-link" href="https://www.ffxiah.com/item/2171" data-img="https://www.bg-wiki.com/images/5/5f/Colibri_Beak_description.png" target="_blank" rel="noopener">Colibri Beak</a> | 2171 | no cap | Magic skills |
| Geomancy Skill | <a class="item-link" href="https://www.ffxiah.com/item/2212" data-img="https://www.bg-wiki.com/images/0/0b/Gpwdr._Swathe_description.png" target="_blank" rel="noopener">Gunpowder Swathe</a> | 2212 | no cap | Magic skills |
| Handbell Skill | <a class="item-link" href="https://www.ffxiah.com/item/2334" data-img="https://www.bg-wiki.com/images/2/2e/Poroggo_Hat_description.png" target="_blank" rel="noopener">Poroggo Hat</a> | 2334 | no cap | Magic skills |
| Cap. Point +33% | <a class="item-link" href="https://www.ffxiah.com/item/942" data-img="https://www.bg-wiki.com/images/9/90/Phil._Stone_description.png" target="_blank" rel="noopener">Philosophers Stone</a> | 942 | no cap | Exp/Cap points |
| Phantom Roll effect | <a class="item-link" href="https://www.ffxiah.com/item/1875" data-img="https://www.bg-wiki.com/images/2/2d/Anct._Beastcoin_description.png" target="_blank" rel="noopener">Ancient Beastcoin</a> | 1875 | no cap | Job-specific niche utilities |

### T2 — Adept (Hunting League Rank 5)

Opens at **Hunting League Rank 5**. Core combat stats that nearly every job cares about — base attributes (STR/DEX/VIT/AGI/INT), Accuracy, DEF, Store TP, Fast Cast, Mag.Acc., Snapshot. Catalysts drop from high-level mobs.

| Augment | Catalyst | Item ID | Cap | Affinity Category |
|---|---|---:|:--:|---|
| STR | <a class="item-link" href="https://www.ffxiah.com/item/1620" data-img="https://www.bg-wiki.com/images/7/7f/Taurus_Horn_description.png" target="_blank" rel="noopener">Taurus Horn</a> | 1620 | no cap | STR |
| Conserve TP | <a class="item-link" href="https://www.ffxiah.com/item/1108" data-img="https://static.ffxiah.com/images/icon/1108.png" target="_blank" rel="noopener">Pinch Of Sulfur</a> | 1108 | no cap | Attack |
| Save TP | <a class="item-link" href="https://www.ffxiah.com/item/1516" data-img="https://www.bg-wiki.com/images/4/49/Griffon_Hide_description.png" target="_blank" rel="noopener">Griffon Hide</a> | 1516 | no cap | Attack |
| DEX | <a class="item-link" href="https://www.ffxiah.com/item/2150" data-img="https://www.bg-wiki.com/images/e/e1/Colibri_Feather_description.png" target="_blank" rel="noopener">Colibri Feather</a> | 2150 | no cap | DEX |
| Store TP Subtle Blow | <a class="item-link" href="https://www.ffxiah.com/item/840" data-img="https://www.bg-wiki.com/images/4/4c/Chocobo_Fthr._description.png" target="_blank" rel="noopener">Chocobo Feather</a> | 840 | no cap | DEX |
| Store TP | <a class="item-link" href="https://www.ffxiah.com/item/1621" data-img="https://www.bg-wiki.com/images/5/53/Taurus_Wing_description.png" target="_blank" rel="noopener">Taurus Wing</a> | 1621 | no cap | DEX |
| Subtle Blow | <a class="item-link" href="https://www.ffxiah.com/item/1690" data-img="https://www.bg-wiki.com/images/5/59/Hippogryph_Tf._description.png" target="_blank" rel="noopener">Hippogryph Tailfeather</a> | 1690 | no cap | DEX |
| Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/846" data-img="https://www.bg-wiki.com/images/9/92/Insect_Wing_description.png" target="_blank" rel="noopener">Insect Wing</a> | 846 | no cap | Accuracy |
| Rng.Accuracy | <a class="item-link" href="https://www.ffxiah.com/item/847" data-img="https://www.bg-wiki.com/images/8/8c/Bird_Feather_description.png" target="_blank" rel="noopener">Bird Feather</a> | 847 | no cap | Accuracy |
| Accuracy Rng.Acc | <a class="item-link" href="https://www.ffxiah.com/item/1292" data-img="https://www.bg-wiki.com/images/b/bc/Damp_Hktk._Eye_description.png" target="_blank" rel="noopener">Damp Hakutaku Eye</a> | 1292 | no cap | Accuracy |
| Accuracy Attack | <a class="item-link" href="https://www.ffxiah.com/item/884" data-img="https://www.bg-wiki.com/images/3/30/Blk._Tiger_Fang_description.png" target="_blank" rel="noopener">Black Tiger Fang</a> | 884 | no cap | Accuracy |
| Rng.Acc. Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/1116" data-img="https://www.bg-wiki.com/images/9/97/Manticore_Hide_description.png" target="_blank" rel="noopener">Manticore Hide</a> | 1116 | no cap | Accuracy |
| VIT | <a class="item-link" href="https://www.ffxiah.com/item/773" data-img="https://www.bg-wiki.com/images/6/61/Translucent_Rock_description.png" target="_blank" rel="noopener">Translucent Rock</a> | 773 | no cap | VIT |
| DEF | <a class="item-link" href="https://www.ffxiah.com/item/881" data-img="https://www.bg-wiki.com/images/5/57/Crab_Shell_description.png" target="_blank" rel="noopener">Crab Shell</a> | 881 | no cap | Defense |
| DEF | <a class="item-link" href="https://www.ffxiah.com/item/774" data-img="https://www.bg-wiki.com/images/2/23/Purple_Rock_description.png" target="_blank" rel="noopener">Purple Rock</a> | 774 | no cap | Defense |
| Mag.Def.Bns | <a class="item-link" href="https://www.ffxiah.com/item/769" data-img="https://www.bg-wiki.com/images/0/01/Red_Rock_description.png" target="_blank" rel="noopener">Red Rock</a> | 769 | no cap | Defense |
| Phalanx Received | <a class="item-link" href="https://www.ffxiah.com/item/772" data-img="https://www.bg-wiki.com/images/1/17/Green_Rock_description.png" target="_blank" rel="noopener">Green Rock</a> | 772 | no cap | Defense |
| Enemy crit. hit rate | <a class="item-link" href="https://www.ffxiah.com/item/3504" data-img="https://www.bg-wiki.com/images/b/bb/Peapuk_Wing_description.png" target="_blank" rel="noopener">Peapuk Wing</a> | 3504 | no cap | Defense |
| AGI | <a class="item-link" href="https://www.ffxiah.com/item/878" data-img="https://www.bg-wiki.com/images/4/49/Karakul_Skin_description.png" target="_blank" rel="noopener">Karakul Skin</a> | 878 | no cap | AGI |
| Snapshot | <a class="item-link" href="https://www.ffxiah.com/item/829" data-img="https://static.ffxiah.com/images/icon/829.png" target="_blank" rel="noopener">Square Of Silk Cloth</a> | 829 | no cap | Evasion |
| INT | <a class="item-link" href="https://www.ffxiah.com/item/921" data-img="https://static.ffxiah.com/images/icon/921.png" target="_blank" rel="noopener">Bottle Of Ahriman Tears</a> | 921 | no cap | INT |
| Mag. Acc | <a class="item-link" href="https://www.ffxiah.com/item/886" data-img="https://www.bg-wiki.com/images/2/26/Demon_Skull_description.png" target="_blank" rel="noopener">Demon Skull</a> | 886 | no cap | Magic ATK |
| Mag. Acc. Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/905" data-img="https://www.bg-wiki.com/images/5/5e/Wyvern_Skull_description.png" target="_blank" rel="noopener">Wyvern Skull</a> | 905 | no cap | Magic ATK |
| Mag. Acc./Mag. Dmg | <a class="item-link" href="https://www.ffxiah.com/item/909" data-img="https://www.bg-wiki.com/images/7/73/Guivre%27s_Skull_description.png" target="_blank" rel="noopener">Guivres Skull</a> | 909 | no cap | Magic ATK |
| Mag.Atk.Bns | <a class="item-link" href="https://www.ffxiah.com/item/2426" data-img="https://www.bg-wiki.com/images/7/76/Wivre_Horn_description.png" target="_blank" rel="noopener">Wivre Horn</a> | 2426 | no cap | Magic ATK |
| Magic Damage | <a class="item-link" href="https://www.ffxiah.com/item/2498" data-img="https://www.bg-wiki.com/images/5/5e/Briareus%27s_Sash_description.png" target="_blank" rel="noopener">Briareuss Sash</a> | 2498 | no cap | Magic ATK |
| Fast Cast | <a class="item-link" href="https://www.ffxiah.com/item/2427" data-img="https://www.bg-wiki.com/images/2/25/Wivre_Maul_description.png" target="_blank" rel="noopener">Wivre Maul</a> | 2427 | no cap | Magic ATK |
| Occult Acumen | <a class="item-link" href="https://www.ffxiah.com/item/2428" data-img="https://www.bg-wiki.com/images/d/d2/Wivre_Hide_description.png" target="_blank" rel="noopener">Wivre Hide</a> | 2428 | no cap | Magic ATK |
| Enspell Dmg | <a class="item-link" href="https://www.ffxiah.com/item/2338" data-img="https://www.bg-wiki.com/images/0/0d/Wamoura_Scale_description.png" target="_blank" rel="noopener">Wamoura Scale</a> | 2338 | no cap | Magic ATK |
| MND | <a class="item-link" href="https://www.ffxiah.com/item/888" data-img="https://www.bg-wiki.com/images/b/b4/Seashell_description.png" target="_blank" rel="noopener">Seashell</a> | 888 | no cap | MND |
| Cure potency | <a class="item-link" href="https://www.ffxiah.com/item/833" data-img="https://static.ffxiah.com/images/icon/833.png" target="_blank" rel="noopener">Clump Of Moko Grass</a> | 833 | no cap | Healing |
| Potency of Cure received | <a class="item-link" href="https://www.ffxiah.com/item/887" data-img="https://www.bg-wiki.com/images/9/9a/Coral_Fragment_description.png" target="_blank" rel="noopener">Coral Fragment</a> | 887 | no cap | Healing |
| CHR | <a class="item-link" href="https://www.ffxiah.com/item/2841" data-img="https://static.ffxiah.com/images/icon/2841.png" target="_blank" rel="noopener">Ingot Of Quadav Silver</a> | 2841 | no cap | CHR |
| Regen Potency | <a class="item-link" href="https://www.ffxiah.com/item/850" data-img="https://static.ffxiah.com/images/icon/850.png" target="_blank" rel="noopener">Square Of Sheep Leather</a> | 850 | no cap | Regen |
| Conserve MP | <a class="item-link" href="https://www.ffxiah.com/item/1119" data-img="https://www.bg-wiki.com/images/5/5d/Tonberry_Coat_description.png" target="_blank" rel="noopener">Tonberry Coat</a> | 1119 | no cap | Refresh |
| Pet Haste | <a class="item-link" href="https://www.ffxiah.com/item/826" data-img="https://static.ffxiah.com/images/icon/826.png" target="_blank" rel="noopener">Square Of Linen Cloth</a> | 826 | no cap | Pet stats pulled from old cat 4 |
| Weapon Skill Acc | <a class="item-link" href="https://www.ffxiah.com/item/1110" data-img="https://static.ffxiah.com/images/icon/1110.png" target="_blank" rel="noopener">Vial Of Black Beetle Blood</a> | 1110 | no cap | WSD+ |

### T3 — Magus (Prestige)

Opens via **Prestige** progression. Damage multipliers and sustain — Double Attack, Crit rate, Magic burst damage, Mag.crit hit damage, weapon delay reductions, HP/MP pool expansions, Regen, Refresh. Catalysts drop from Prestige-tier (Nightmare Court) bosses.

| Augment | Catalyst | Item ID | Cap | Affinity Category |
|---|---|---:|:--:|---|
| Counter | <a class="item-link" href="https://www.ffxiah.com/item/2147" data-img="https://www.bg-wiki.com/images/4/4b/Marid_Tusk_description.png" target="_blank" rel="noopener">Marid Tusk</a> | 2147 | no cap | STR |
| Attack | <a class="item-link" href="https://www.ffxiah.com/item/861" data-img="https://www.bg-wiki.com/images/f/f8/Tiger_Hide_description.png" target="_blank" rel="noopener">Black Tiger Hide</a> | 861 | no cap | Attack |
| Rng.Attack | <a class="item-link" href="https://www.ffxiah.com/item/883" data-img="https://www.bg-wiki.com/images/d/d3/Behemoth_Horn_description.png" target="_blank" rel="noopener">Behemoth Horn</a> | 883 | no cap | Attack |
| Attack Rng.Atk | <a class="item-link" href="https://www.ffxiah.com/item/874" data-img="https://www.bg-wiki.com/images/4/4c/Amaltheia_Hide_description.png" target="_blank" rel="noopener">Amaltheia Hide</a> | 874 | no cap | Attack |
| Dbl.Atk. Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/880" data-img="https://www.bg-wiki.com/images/d/de/Bone_Chip_description.png" target="_blank" rel="noopener">Bone Chip</a> | 880 | 100%/swing | Attack |
| Dbl.Atk | <a class="item-link" href="https://www.ffxiah.com/item/882" data-img="https://www.bg-wiki.com/images/5/56/Sheep_Tooth_description.png" target="_blank" rel="noopener">Sheep Tooth</a> | 882 | 100%/swing | Attack |
| Crit.hit rate | <a class="item-link" href="https://www.ffxiah.com/item/2148" data-img="https://www.bg-wiki.com/images/2/2b/Puk_Wing_description.png" target="_blank" rel="noopener">Puk Wing</a> | 2148 | 100%/swing | DEX |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/816" data-img="https://static.ffxiah.com/images/icon/816.png" target="_blank" rel="noopener">Spool Of Silk Thread</a> | 816 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/818" data-img="https://static.ffxiah.com/images/icon/818.png" target="_blank" rel="noopener">Spool Of Cotton Thread</a> | 818 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/927" data-img="https://www.bg-wiki.com/images/3/34/Coeurl_Whisker_description.png" target="_blank" rel="noopener">Coeurl Whisker</a> | 927 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/1118" data-img="https://www.bg-wiki.com/images/5/5c/Antican_Pauldron_description.png" target="_blank" rel="noopener">Antican Pauldron</a> | 1118 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/1121" data-img="https://www.bg-wiki.com/images/6/65/Antican_Robe_description.png" target="_blank" rel="noopener">Antican Robe</a> | 1121 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/1196" data-img="https://www.bg-wiki.com/images/1/11/Qiqirn_Cape_description.png" target="_blank" rel="noopener">Qiqirn Cape</a> | 1196 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/1265" data-img="https://www.bg-wiki.com/images/2/2c/4Lf._Korrin_Bud_description.png" target="_blank" rel="noopener">Four-Leaf Korrigan Bud</a> | 1265 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/1275" data-img="https://www.bg-wiki.com/images/a/a1/Amemet_Skin_description.png" target="_blank" rel="noopener">Amemet Skin</a> | 1275 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/1276" data-img="https://www.bg-wiki.com/images/9/92/Tarasque_Skin_description.png" target="_blank" rel="noopener">Tarasque Skin</a> | 1276 | no cap | Weapon delay (melee) |
| Delay (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/1277" data-img="https://www.bg-wiki.com/images/9/97/Lindwurm_Skin_description.png" target="_blank" rel="noopener">Lindwurm Skin</a> | 1277 | no cap | Weapon delay (melee) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1279" data-img="https://static.ffxiah.com/images/icon/1279.png" target="_blank" rel="noopener">Square Of Taffeta Cloth</a> | 1279 | no cap | Weapon delay (ranged) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1280" data-img="https://static.ffxiah.com/images/icon/1280.png" target="_blank" rel="noopener">Square Of Sarcenet Cloth</a> | 1280 | no cap | Weapon delay (ranged) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1281" data-img="https://static.ffxiah.com/images/icon/1281.png" target="_blank" rel="noopener">Square Of Cheviot Cloth</a> | 1281 | no cap | Weapon delay (ranged) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1282" data-img="https://www.bg-wiki.com/images/5/5e/Flauros_Whisker_description.png" target="_blank" rel="noopener">Flauros Whisker</a> | 1282 | no cap | Weapon delay (ranged) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1283" data-img="https://www.bg-wiki.com/images/8/8f/Ose_Whisker_description.png" target="_blank" rel="noopener">Ose Whisker</a> | 1283 | no cap | Weapon delay (ranged) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1296" data-img="https://www.bg-wiki.com/images/d/d8/Yowie_Skin_description.png" target="_blank" rel="noopener">Yowie Skin</a> | 1296 | no cap | Weapon delay (ranged) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1312" data-img="https://static.ffxiah.com/images/icon/1312.png" target="_blank" rel="noopener">Piece Of Angel Skin</a> | 1312 | no cap | Weapon delay (ranged) |
| Delay (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/1470" data-img="https://www.bg-wiki.com/images/3/3f/Sparkling_Stone_description.png" target="_blank" rel="noopener">Sparkling Stone</a> | 1470 | no cap | Weapon delay (ranged) |
| Magic burst dmg | <a class="item-link" href="https://www.ffxiah.com/item/2776" data-img="https://www.bg-wiki.com/images/5/5d/Pumice_Stone_description.png" target="_blank" rel="noopener">Pumice Stone</a> | 2776 | +40% | Magic ATK |
| Mag. crit. hit dmg | <a class="item-link" href="https://www.ffxiah.com/item/2777" data-img="https://static.ffxiah.com/images/icon/2777.png" target="_blank" rel="noopener">Vial Of Magicked Blood</a> | 2777 | no cap | Magic ATK |
| Magic crit. hit rate | <a class="item-link" href="https://www.ffxiah.com/item/842" data-img="https://www.bg-wiki.com/images/8/80/Giant_Bird_Fthr._description.png" target="_blank" rel="noopener">Giant Bird Feather</a> | 842 | no cap | Magic ATK |
| Helix Damage | <a class="item-link" href="https://www.ffxiah.com/item/2335" data-img="https://static.ffxiah.com/images/icon/2335.png" target="_blank" rel="noopener">Soulflayer Tentacle</a> | 2335 | no cap | Custom magic augments |
| Spikes Dmg | <a class="item-link" href="https://www.ffxiah.com/item/2531" data-img="https://static.ffxiah.com/images/icon/2531.png" target="_blank" rel="noopener">Shard Of Obsidian</a> | 2531 | no cap | Custom magic augments |
| Immunobreak Chance+ | <a class="item-link" href="https://www.ffxiah.com/item/2875" data-img="https://www.bg-wiki.com/images/4/46/Ethereal_Squama_description.png" target="_blank" rel="noopener">Ethereal Squama</a> | 2875 | no cap | Custom magic augments |
| HP | <a class="item-link" href="https://www.ffxiah.com/item/860" data-img="https://www.bg-wiki.com/images/a/ad/Behemoth_Hide_description.png" target="_blank" rel="noopener">Behemoth Hide</a> | 860 | no cap | HP |
| HP MP | <a class="item-link" href="https://www.ffxiah.com/item/867" data-img="https://static.ffxiah.com/images/icon/867.png" target="_blank" rel="noopener">Handful Of Dragon Scales</a> | 867 | no cap | HP |
| Regen | <a class="item-link" href="https://www.ffxiah.com/item/848" data-img="https://static.ffxiah.com/images/icon/848.png" target="_blank" rel="noopener">Square Of Dhalmel Leather</a> | 848 | no cap | Regen |
| MP | <a class="item-link" href="https://www.ffxiah.com/item/841" data-img="https://www.bg-wiki.com/images/9/98/Yagudo_Feather_description.png" target="_blank" rel="noopener">Yagudo Feather</a> | 841 | no cap | MP |
| Refresh | <a class="item-link" href="https://www.ffxiah.com/item/919" data-img="https://static.ffxiah.com/images/icon/919.png" target="_blank" rel="noopener">Clump Of Boyahda Moss</a> | 919 | no cap | Refresh |
| Weapon skill damage | <a class="item-link" href="https://www.ffxiah.com/item/1473" data-img="https://www.bg-wiki.com/images/5/5d/H.Q._Scp._Shell_description.png" target="_blank" rel="noopener">High-Quality Scorpion Shell</a> | 1473 | no cap | WSD+ |
| Sklchn.dmg | <a class="item-link" href="https://www.ffxiah.com/item/865" data-img="https://static.ffxiah.com/images/icon/865.png" target="_blank" rel="noopener">Handful Of Nidhoggs Scales</a> | 865 | no cap | WSD+ |

### T4 — Sage (Endgame)

**Endgame only.** Top-tier universals that benefit every job without exception: Haste, Triple Attack, Quadruple Attack, TP Bonus, critical hit damage, physical/magic/all damage-taken percentage reductions. Catalysts drop from Shinryu- and Abyssea-tier NMs.

| Augment | Catalyst | Item ID | Cap | Affinity Category |
|---|---|---:|:--:|---|
| Triple Atk | <a class="item-link" href="https://www.ffxiah.com/item/891" data-img="https://www.bg-wiki.com/images/f/fe/Bat_Fang_description.png" target="_blank" rel="noopener">Bat Fang</a> | 891 | 100%/swing | Attack |
| TP Bonus | <a class="item-link" href="https://www.ffxiah.com/item/1271" data-img="https://www.bg-wiki.com/images/8/8a/Pigeon%27s_Blood_description.png" target="_blank" rel="noopener">Pigeons Blood Ruby</a> | 1271 | no cap | Attack |
| Quadruple Attack | <a class="item-link" href="https://www.ffxiah.com/item/1293" data-img="https://www.bg-wiki.com/images/1/1f/Narasimha_Hide_description.png" target="_blank" rel="noopener">Narasimha Hide</a> | 1293 | 100%/swing | Attack |
| Crit. hit damage | <a class="item-link" href="https://www.ffxiah.com/item/2149" data-img="https://www.bg-wiki.com/images/4/4e/Apkallu_Feather_description.png" target="_blank" rel="noopener">Apkallu Feather</a> | 2149 | +100% | DEX |
| Magic dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/936" data-img="https://static.ffxiah.com/images/icon/936.png" target="_blank" rel="noopener">Chunk Of Rock Salt</a> | 936 | -50% | Defense |
| Phys. dmg. taken | <a class="item-link" href="https://www.ffxiah.com/item/858" data-img="https://www.bg-wiki.com/images/e/e8/Wolf_Hide_description.png" target="_blank" rel="noopener">Wolf Hide</a> | 858 | -50% | Defense |
| Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/1123" data-img="https://www.bg-wiki.com/images/e/ec/Manticore_Fang_description.png" target="_blank" rel="noopener">Manticore Fang</a> | 1123 | -50% | Defense |
| Physical Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/2151" data-img="https://www.bg-wiki.com/images/d/d3/Marid_Hide_description.png" target="_blank" rel="noopener">Marid Hide</a> | 2151 | -50% | Defense |
| Magic Damage Taken | <a class="item-link" href="https://www.ffxiah.com/item/2158" data-img="https://www.bg-wiki.com/images/0/0e/Hydra_Fang_description.png" target="_blank" rel="noopener">Hydra Fang</a> | 2158 | -50% | Defense |
| Haste | <a class="item-link" href="https://www.ffxiah.com/item/820" data-img="https://static.ffxiah.com/images/icon/820.png" target="_blank" rel="noopener">Spool Of Wool Thread</a> | 820 | +25% | Haste |
| Dmg (melee,not ranged) | <a class="item-link" href="https://www.ffxiah.com/item/889" data-img="https://www.bg-wiki.com/images/a/ab/Beetle_Shell_description.png" target="_blank" rel="noopener">Beetle Shell</a> | 889 | no cap | WSD+ |
| Dmg (ranged,not melee) | <a class="item-link" href="https://www.ffxiah.com/item/908" data-img="https://www.bg-wiki.com/images/2/26/Adamantoise_Shell_description.png" target="_blank" rel="noopener">Adamantoise Shell</a> | 908 | no cap | WSD+ |
<!-- DOCGEN:END id="augment-catalog" -->

## Notes

- Catalyst items are existing FFXI items (synth materials, mob drops, vouchers) selected from a non-consumable, non-equippable pool. Trading them at the Augment Moogle is a *new* use; their other functions in crafting and quests still work.
- Augments with `modId=0` in the SQL data (server no-ops) are filtered out — they wouldn't do anything anyway.
- Negative augments on stats that are "good when high" (e.g. `HP-33`) are filtered out. Useful negatives like `Enmity-1`, `Phys.dmg.taken -1%`, and `Spell interruption rate down 1%` are kept.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 2770c2cb5aa0 -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
