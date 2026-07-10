# Voidwatch

Tears in the void have opened across Vana'diel. The **Voidwatch** system sends you into the field to find them — examine a **Planar Rift** in any of 30 overworld zones, and a tier-scaled Voidwalker NM tears through. Each rift you survive raises your abyssite rank, scaling every fight harder and paying more.

!!! tip "Summary"
    Find a Planar Rift in the overworld, spend a Voidstone to open a rift, fight a Voidwalker NM, and probe its hidden weaknesses with magic, weaponskills, and ranged attacks to shape your reward. Use `!voidwatch` to check status or buy Voidstones.

## Getting started

The **Officer** NPC on **Purgonorgo Isle** sells Voidstones and runs the **Atmacite Refiner** where you spend atmacite shards on permanent perks. You start with a stock of Voidstones the first time you engage the system.

<!-- DOCGEN:BEGIN id="voidwatch-economy" -->
| Voidstones | Detail |
|---|---|
| Carry cap | 10 Voidstones |
| Regen | 1 Voidstone every 1 hour, real time |
| Starting stock | 5 Voidstones, granted your first time |
| Rift cost | 1 Voidstone per opening |
| Buy price | 400 cruor each |
| Battle timer | 30 minutes before the NM voids out |
| Pyxis claim window | 3 minutes to open the chest |
<!-- DOCGEN:END id="voidwatch-economy" -->

Use `!voidwatch` at any time to check your Voidstones, cruor balance, and current tier.

## Planar Rifts

Planar Rifts are clickable objects scattered across **30 overworld zones** — original Vana'diel areas from West Ronfaure to Sauromugue Champaign and beyond. Examine one, confirm you want to spend a Voidstone, and the NM tears through right where you stand.

The rift battle runs for up to **30 minutes**. If the NM survives, it voids out.

### Rift locations

Every Planar Rift by zone, with its exact map coordinates and the Voidwalker NMs that can emerge there (one is drawn from the zone's stratum roster each time). Coordinates are the in-game `X, Y, Z` — head to the spot and examine the rift.

<!-- DOCGEN:BEGIN id="voidwatch-rifts" -->
| Stratum | Zone | Rift coordinates (X, Y, Z) | Voidwalker NMs (one emerges) |
|---|---|---|---|
| Crimson Stratum | **East Ronfaure** | 183, -20, -315 | Krabkatoa · Yacumama · Raker Bee |
| Crimson Stratum | **East Sarutabaruta** | -120, -4.879, -415 | Krabkatoa · Yacumama · Raker Bee |
| Crimson Stratum | **North Gustaberg** | -322, 40, -42 | Krabkatoa · Yacumama · Raker Bee |
| Crimson Stratum | **South Gustaberg** | 250, -0.018, -640 | Krabkatoa · Yacumama · Raker Bee |
| Crimson Stratum | **West Ronfaure** | -320, -10, -360 | Krabkatoa · Yacumama · Raker Bee |
| Crimson Stratum | **West Sarutabaruta** | -441, 4, -357 | Krabkatoa · Yacumama · Raker Bee |
| Indigo Stratum | **Buburimu Peninsula** | -360, -8, -200 | Farruca Fly · Skuld · Gorehound |
| Indigo Stratum | **Konschtat Highlands** | -125, 72.046, 720 | Farruca Fly · Skuld · Gorehound |
| Indigo Stratum | **La Theine Plateau** | -440, -8, 440 | Farruca Fly · Skuld · Gorehound |
| Indigo Stratum | **Tahrongi Canyon** | 200, -24, -160 | Farruca Fly · Skuld · Gorehound |
| Indigo Stratum | **Valkurm Dunes** | -75, -0.312, -45 | Farruca Fly · Skuld · Gorehound |
| Jade Stratum | **Bibiki Bay** | -120, 0.3, -629 | Blobdingnag · Shoggoth · Capricornus |
| Jade Stratum | **Jugner Forest** | -325, 0, -124 | Blobdingnag · Shoggoth · Capricornus |
| Jade Stratum | **Meriphataud Mountains** | -282, 16, 602 | Blobdingnag · Shoggoth · Capricornus |
| Jade Stratum | **Pashhow Marshlands** | -420, 24.14, -230 | Blobdingnag · Shoggoth · Capricornus |
| White Stratum | **Batallia Downs** | -320, -16, -42 | Lamprey Lord · Jyeshtha · Dawon |
| White Stratum | **Rolanberry Fields** | -360, 8, 279 | Lamprey Lord · Jyeshtha · Dawon |
| White Stratum | **Sauromugue Champaign** | -245, 7.75, 245 | Lamprey Lord · Jyeshtha · Dawon |
| Ashen Stratum | **Qufim Island** | -120, -19.304, 375 | Gjenganger · Feuerunke · Tammuz |
| Ashen Stratum | **Western Altepa Desert** | -170, 0.001, 327 | Gjenganger · Feuerunke · Tammuz |
| Ashen Stratum | **Yuhtunga Jungle** | -242, 0.55, 405 | Gjenganger · Feuerunke · Tammuz |
| Hyacinth Stratum | **Attohwa Chasm** | 361, 21, 222 | Aglaophotis · Erebus · Gorehound |
| Hyacinth Stratum | **Beaucedine Glacier** | -135, -60.5, -200 | Aglaophotis · Erebus · Gorehound |
| Hyacinth Stratum | **Lufaise Meadows** | -234, -15, 125 | Aglaophotis · Erebus · Gorehound |
| Hyacinth Stratum | **Misareaux Coast** | 267, -15, 222 | Aglaophotis · Erebus · Gorehound |
| Hyacinth Stratum | **Ro'Maeve** | -114, -8, 44 | Aglaophotis · Erebus · Gorehound |
| Hyacinth Stratum | **The Sanctuary of Zi'Tah** | -275, 0.2, 46 | Aglaophotis · Erebus · Gorehound |
| Amber Stratum | **Behemoth's Dominion** | -210, -20.375, 70 | Yilbegan · Lord Ruthven · Erebus |
| Amber Stratum | **Ru'Aun Gardens** | -117, -40, 436 | Yilbegan · Lord Ruthven · Erebus |
| Amber Stratum | **Uleguerand Range** | -141, -19, -325 | Yilbegan · Lord Ruthven · Erebus |
<!-- DOCGEN:END id="voidwatch-rifts" -->

## Abyssite strata

The 30 rift zones are grouped into **seven abyssite strata**, each with its own starting tier and its own roster of Voidwalker NMs. Higher strata begin harder — your clears within a stratum push its tier up from there.

<!-- DOCGEN:BEGIN id="voidwatch-strata" -->
| Stratum | Starting tier | Zones | Voidwalker NMs |
|---|---|---|---|
| **Crimson Stratum** | 1 | 6 | Krabkatoa, Yacumama, Raker Bee |
| **Indigo Stratum** | 4 | 5 | Farruca Fly, Skuld, Gorehound |
| **Jade Stratum** | 7 | 4 | Blobdingnag, Shoggoth, Capricornus |
| **White Stratum** | 10 | 3 | Lamprey Lord, Jyeshtha, Dawon |
| **Ashen Stratum** | 13 | 3 | Gjenganger, Feuerunke, Tammuz |
| **Hyacinth Stratum** | 16 | 6 | Aglaophotis, Erebus, Gorehound |
| **Amber Stratum** | 19 | 3 | Yilbegan, Lord Ruthven, Erebus |
<!-- DOCGEN:END id="voidwatch-strata" -->

## Tier scaling

Your **abyssite rank** determines the strength of the next rift. Clearing a tier increments it — every rift is tougher than your last. The scaling is continuous with no cap: level, HP, stats, and mechanics all climb together.

<!-- DOCGEN:BEGIN id="voidwatch-scaling" -->
| What scales | Formula |
|---|---|
| NM level | 78 + tier × 4 |
| NM HP | 180,000 + tier × 110,000 |
| Attack | 700 + tier × 200 |
| Accuracy | 550 + tier × 110 |
| Cruor reward | 800 + tier × 350 |
| EXP reward | 1,500 + tier × 600 |
<!-- DOCGEN:END id="voidwatch-scaling" -->

At higher tiers the NM gains additional mechanics (see below).

## Hidden weaknesses and Lights

Every NM has **5–9 hidden weaknesses** from the weakness pool (elements, weaponskills, ranged attacks). Probe the NM during the fight by using magic elements, weaponskills, or ranged attacks — when you hit a weakness, a **Light** activates and is announced in chat. Stack up to 5 of each colour (up to 8 with Atmacite Insight); more Lights = better reward from the Riftworn Pyxis.

Each NM's weaknesses are **fixed and learnable** — the same NM always has the same triggers, so skilled players can enter knowing exactly which elements and weapon skills to use.

<!-- DOCGEN:BEGIN id="voidwatch-lights" -->
| Light | Colour | Reward boon | Per-light weight |
|---|---|---|---|
| **Vermillion** | Red | reward quality | +8 to the quality roll per light |
| **Cerulean** | Blue | reward quantity | +1 loot roll per 2 lights |
| **Verdant** | Green | cruor | +25% cruor per light |
| **Amber** | Yellow | EXP | +25% EXP per light |
| **Pearl** | White | atmacite | 1 atmacite shard per light |
<!-- DOCGEN:END id="voidwatch-lights" -->

The weakness pool covers fire/ice/wind/earth/lightning/water/light/dark magic elements, weaponskills, and ranged attacks — every job can contribute Lights.

## NM mechanics by tier

Higher tiers layer in additional combat mechanics from the `mob_mechanics_library`:

| Unlocks at tier | Mechanic |
|---|---|
| **2** | Stance dance — alternates physical immunity / magic immunity windows |
| **3** | AoE void shockwave every ~14 seconds |
| **4** | Terror CC every ~28 seconds |
| **5** | Enrage at 5 minutes (massive attack/haste boost) |
| **6** | Doom at 12% HP |
| **7** | Phase transitions at 50% and 20% HP |

!!! note
    Stance dance does **not** block Lights — weakness listeners fire on use, not on damage, so you can keep probing through an immunity window.

## Rewards — Riftworn Pyxis

Killing the NM opens a **Riftworn Pyxis** whose contents are shaped by your Light tally:

- **Cruor** — base scales with tier; boosted by Verdant lights
- **EXP** — base scales with tier; boosted by Amber lights
- **Loot rolls** — extra rolls from Cerulean lights
- **Quality** — a d100 roll boosted by Vermillion lights determines common / uncommon / rare:
    - **92+** (+ Vermillion bias) → rare (gear + valuable items)
    - **60–91** → uncommon (valuable mats + consumables)
    - **0–59** → common (crafting materials)
- **Atmacite shards** — 1 per Pearl light, spend at the Atmacite Refiner for permanent perks
- **3+ Pearl lights** → a guaranteed bonus rare roll

### Drops by NM

Each Voidwalker has its **own** drop table (retail-sourced from the fork's droplists). The quality tier your Lights roll decides which of its tables the Pyxis opens — **rare** holds that NM's signature gear and chase items, **uncommon** its signature material plus consumables, and every NM shares the standard **common** crafting pool. Vermillion lights bias toward rare; Cerulean lights add extra rolls.

<!-- DOCGEN:BEGIN id="voidwatch-loot" -->
| Voidwalker NM | Rare — gear & chase (quality 92+) | Uncommon — materials & consumables (60–91) |
|---|---|---|
| **Krabkatoa** | <a class="item-link" href="https://www.ffxiah.com/item/11502" data-img="https://www.bg-wiki.com/images/f/f1/Acubens_Helm_description.png" target="_blank" rel="noopener">Acubens Helm</a>, <a class="item-link" href="https://www.ffxiah.com/item/11632" data-img="https://www.bg-wiki.com/images/9/9a/Karka_Ring_description.png" target="_blank" rel="noopener">Karka Ring</a> | <a class="item-link" href="https://www.ffxiah.com/item/2884" data-img="https://www.bg-wiki.com/images/e/ed/Krabkatoa_Shell_description.png" target="_blank" rel="noopener">Krabkatoa Shell</a>, <a class="item-link" href="https://www.ffxiah.com/item/2879" data-img="https://www.bg-wiki.com/images/d/dc/Igneous_Barnacle_description.png" target="_blank" rel="noopener">Igneous Barnacle</a>, <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Raker Bee** | <a class="item-link" href="https://www.ffxiah.com/item/942" data-img="https://www.bg-wiki.com/images/9/90/Phil._Stone_description.png" target="_blank" rel="noopener">Philosophers Stone</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Yacumama** | <a class="item-link" href="https://www.ffxiah.com/item/11586" data-img="https://www.bg-wiki.com/images/0/05/Backlash_Torque_description.png" target="_blank" rel="noopener">Backlash Torque</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Farruca Fly** | <a class="item-link" href="https://www.ffxiah.com/item/11635" data-img="https://www.bg-wiki.com/images/8/80/Alert_Ring_description.png" target="_blank" rel="noopener">Alert Ring</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Gorehound** | <a class="item-link" href="https://www.ffxiah.com/item/942" data-img="https://www.bg-wiki.com/images/9/90/Phil._Stone_description.png" target="_blank" rel="noopener">Philosophers Stone</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Skuld** | <a class="item-link" href="https://www.ffxiah.com/item/11544" data-img="https://www.bg-wiki.com/images/7/76/Veela_Cape_description.png" target="_blank" rel="noopener">Veela Cape</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Blobdingnag** | <a class="item-link" href="https://www.ffxiah.com/item/11631" data-img="https://www.bg-wiki.com/images/1/14/Blobnag_Ring_description.png" target="_blank" rel="noopener">Blobnag Ring</a>, <a class="item-link" href="https://www.ffxiah.com/item/11585" data-img="https://www.bg-wiki.com/images/e/ea/Beguiling_Collar_description.png" target="_blank" rel="noopener">Beguiling Collar</a> | <a class="item-link" href="https://www.ffxiah.com/item/2876" data-img="https://static.ffxiah.com/images/icon/2876.png" target="_blank" rel="noopener">Muculent Ingot</a>, <a class="item-link" href="https://www.ffxiah.com/item/2882" data-img="https://static.ffxiah.com/images/icon/2882.png" target="_blank" rel="noopener">Baby Blobdingnag</a>, <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Capricornus** | <a class="item-link" href="https://www.ffxiah.com/item/15954" data-img="https://www.bg-wiki.com/images/b/b7/Fierce_Belt_description.png" target="_blank" rel="noopener">Fierce Belt</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Shoggoth** | <a class="item-link" href="https://www.ffxiah.com/item/19245" data-img="https://www.bg-wiki.com/images/e/ea/Jinx_Ampulla_description.png" target="_blank" rel="noopener">Jinx Ampulla</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Dawon** | <a class="item-link" href="https://www.ffxiah.com/item/15859" data-img="https://www.bg-wiki.com/images/9/92/Succor_Ring_description.png" target="_blank" rel="noopener">Succor Ring</a>, <a class="item-link" href="https://www.ffxiah.com/item/16151" data-img="https://www.bg-wiki.com/images/a/a3/Leonine_Mask_description.png" target="_blank" rel="noopener">Leonine Mask</a> | <a class="item-link" href="https://www.ffxiah.com/item/2570" data-img="https://static.ffxiah.com/images/icon/2570.png" target="_blank" rel="noopener">Pelt of Dawon</a>, <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Jyeshtha** | <a class="item-link" href="https://www.ffxiah.com/item/15955" data-img="https://www.bg-wiki.com/images/2/25/Fatality_Belt_description.png" target="_blank" rel="noopener">Fatality Belt</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Lamprey Lord** | <a class="item-link" href="https://www.ffxiah.com/item/16054" data-img="https://www.bg-wiki.com/images/4/4a/Hirudinea_Earring_description.png" target="_blank" rel="noopener">Hirudinea Earring</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Feuerunke** | <a class="item-link" href="https://www.ffxiah.com/item/16056" data-img="https://www.bg-wiki.com/images/1/1a/Pagondas_Earring_description.png" target="_blank" rel="noopener">Pagondas Earring</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Gjenganger** | <a class="item-link" href="https://www.ffxiah.com/item/942" data-img="https://www.bg-wiki.com/images/9/90/Phil._Stone_description.png" target="_blank" rel="noopener">Philosophers Stone</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Tammuz** | <a class="item-link" href="https://www.ffxiah.com/item/16307" data-img="https://www.bg-wiki.com/images/a/a9/Repelling_Collar_description.png" target="_blank" rel="noopener">Repelling Collar</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Aglaophotis** | <a class="item-link" href="https://www.ffxiah.com/item/15544" data-img="https://www.bg-wiki.com/images/2/2f/Sattva_Ring_description.png" target="_blank" rel="noopener">Sattva Ring</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Erebus** | <a class="item-link" href="https://www.ffxiah.com/item/11587" data-img="https://www.bg-wiki.com/images/7/78/Nyx_Gorget_description.png" target="_blank" rel="noopener">Nyx Gorget</a> | <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Lord Ruthven** | <a class="item-link" href="https://www.ffxiah.com/item/11628" data-img="https://www.bg-wiki.com/images/3/32/Strigoi_Ring_description.png" target="_blank" rel="noopener">Strigoi Ring</a>, <a class="item-link" href="https://www.ffxiah.com/item/15953" data-img="https://www.bg-wiki.com/images/5/52/Marching_Belt_description.png" target="_blank" rel="noopener">Marching Belt</a> | <a class="item-link" href="https://www.ffxiah.com/item/2883" data-img="https://static.ffxiah.com/images/icon/2883.png" target="_blank" rel="noopener">Ruthvens Nail</a>, <a class="item-link" href="https://www.ffxiah.com/item/2877" data-img="https://static.ffxiah.com/images/icon/2877.png" target="_blank" rel="noopener">Ingot of Befouled Silver</a>, <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |
| **Yilbegan** | <a class="item-link" href="https://www.ffxiah.com/item/11629" data-img="https://www.bg-wiki.com/images/4/49/Zilant_Ring_description.png" target="_blank" rel="noopener">Zilant Ring</a>, <a class="item-link" href="https://www.ffxiah.com/item/11633" data-img="https://www.bg-wiki.com/images/0/04/Galdr_Ring_description.png" target="_blank" rel="noopener">Galdr Ring</a>, <a class="item-link" href="https://www.ffxiah.com/item/14162" data-img="https://www.bg-wiki.com/images/4/4f/Agrona%27s_Leggings_description.png" target="_blank" rel="noopener">Agronas Leggings</a>, <a class="item-link" href="https://www.ffxiah.com/item/19248" data-img="https://www.bg-wiki.com/images/8/85/Lucky_Coin_description.png" target="_blank" rel="noopener">Lucky Coin</a> | <a class="item-link" href="https://www.ffxiah.com/item/2878" data-img="https://static.ffxiah.com/images/icon/2878.png" target="_blank" rel="noopener">Square of Scarlet Kadife</a>, <a class="item-link" href="https://www.ffxiah.com/item/4172" data-img="https://static.ffxiah.com/images/icon/4172.png" target="_blank" rel="noopener">Reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4174" data-img="https://static.ffxiah.com/images/icon/4174.png" target="_blank" rel="noopener">Vile Elixir</a>, <a class="item-link" href="https://www.ffxiah.com/item/4173" data-img="https://static.ffxiah.com/images/icon/4173.png" target="_blank" rel="noopener">Hi-reraiser</a>, <a class="item-link" href="https://www.ffxiah.com/item/4175" data-img="https://static.ffxiah.com/images/icon/4175.png" target="_blank" rel="noopener">Vile Elixir +1</a> |

**Shared common tier** (quality 0–59 — every Voidwalker also rolls these standard crafting materials): <a class="item-link" href="https://www.ffxiah.com/item/1262" data-img="https://static.ffxiah.com/images/icon/1262.png" target="_blank" rel="noopener">Chunk of Dark Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/645" data-img="https://static.ffxiah.com/images/icon/645.png" target="_blank" rel="noopener">Chunk of Darksteel Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/1258" data-img="https://static.ffxiah.com/images/icon/1258.png" target="_blank" rel="noopener">Chunk of Earth Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/1255" data-img="https://static.ffxiah.com/images/icon/1255.png" target="_blank" rel="noopener">Chunk of Fire Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/737" data-img="https://static.ffxiah.com/images/icon/737.png" target="_blank" rel="noopener">Chunk of Gold Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/1256" data-img="https://static.ffxiah.com/images/icon/1256.png" target="_blank" rel="noopener">Chunk of Ice Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/1261" data-img="https://static.ffxiah.com/images/icon/1261.png" target="_blank" rel="noopener">Chunk of Light Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/1259" data-img="https://static.ffxiah.com/images/icon/1259.png" target="_blank" rel="noopener">Chunk of Lightning Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/644" data-img="https://static.ffxiah.com/images/icon/644.png" target="_blank" rel="noopener">Chunk of Mythril Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/738" data-img="https://static.ffxiah.com/images/icon/738.png" target="_blank" rel="noopener">Chunk of Platinum Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/1260" data-img="https://static.ffxiah.com/images/icon/1260.png" target="_blank" rel="noopener">Chunk of Water Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/1257" data-img="https://static.ffxiah.com/images/icon/1257.png" target="_blank" rel="noopener">Chunk of Wind Ore</a>, <a class="item-link" href="https://www.ffxiah.com/item/887" data-img="https://www.bg-wiki.com/images/9/9a/Coral_Fragment_description.png" target="_blank" rel="noopener">Coral Fragment</a>, <a class="item-link" href="https://www.ffxiah.com/item/654" data-img="https://static.ffxiah.com/images/icon/654.png" target="_blank" rel="noopener">Darksteel Ingot</a>, <a class="item-link" href="https://www.ffxiah.com/item/902" data-img="https://www.bg-wiki.com/images/1/19/Demon_Horn_description.png" target="_blank" rel="noopener">Demon Horn</a>, <a class="item-link" href="https://www.ffxiah.com/item/702" data-img="https://static.ffxiah.com/images/icon/702.png" target="_blank" rel="noopener">Ebony Log</a>, <a class="item-link" href="https://www.ffxiah.com/item/745" data-img="https://static.ffxiah.com/images/icon/745.png" target="_blank" rel="noopener">Gold Ingot</a>, <a class="item-link" href="https://www.ffxiah.com/item/866" data-img="https://static.ffxiah.com/images/icon/866.png" target="_blank" rel="noopener">Handful of Wyvern Scales</a>, <a class="item-link" href="https://www.ffxiah.com/item/700" data-img="https://static.ffxiah.com/images/icon/700.png" target="_blank" rel="noopener">Mahogany Log</a>, <a class="item-link" href="https://www.ffxiah.com/item/1116" data-img="https://www.bg-wiki.com/images/9/97/Manticore_Hide_description.png" target="_blank" rel="noopener">Manticore Hide</a>, <a class="item-link" href="https://www.ffxiah.com/item/653" data-img="https://static.ffxiah.com/images/icon/653.png" target="_blank" rel="noopener">Mythril Ingot</a>, <a class="item-link" href="https://www.ffxiah.com/item/703" data-img="https://static.ffxiah.com/images/icon/703.png" target="_blank" rel="noopener">Petrified Log</a>, <a class="item-link" href="https://www.ffxiah.com/item/942" data-img="https://www.bg-wiki.com/images/9/90/Phil._Stone_description.png" target="_blank" rel="noopener">Philosophers Stone</a>, <a class="item-link" href="https://www.ffxiah.com/item/844" data-img="https://static.ffxiah.com/images/icon/844.png" target="_blank" rel="noopener">Phoenix Feather</a>, <a class="item-link" href="https://www.ffxiah.com/item/746" data-img="https://static.ffxiah.com/images/icon/746.png" target="_blank" rel="noopener">Platinum Ingot</a>, <a class="item-link" href="https://www.ffxiah.com/item/895" data-img="https://www.bg-wiki.com/images/b/bb/Ram_Horn_description.png" target="_blank" rel="noopener">Ram Horn</a>, <a class="item-link" href="https://www.ffxiah.com/item/859" data-img="https://www.bg-wiki.com/images/8/80/Ram_Skin_description.png" target="_blank" rel="noopener">Ram Skin</a>, <a class="item-link" href="https://www.ffxiah.com/item/1465" data-img="https://static.ffxiah.com/images/icon/1465.png" target="_blank" rel="noopener">Slab of Granite</a>, <a class="item-link" href="https://www.ffxiah.com/item/823" data-img="https://static.ffxiah.com/images/icon/823.png" target="_blank" rel="noopener">Spool of Gold Thread</a>, <a class="item-link" href="https://www.ffxiah.com/item/830" data-img="https://static.ffxiah.com/images/icon/830.png" target="_blank" rel="noopener">Square of Rainbow Cloth</a>, <a class="item-link" href="https://www.ffxiah.com/item/1132" data-img="https://static.ffxiah.com/images/icon/1132.png" target="_blank" rel="noopener">Square of Raxa</a>, <a class="item-link" href="https://www.ffxiah.com/item/1122" data-img="https://www.bg-wiki.com/images/e/e5/Wyvern_Skin_description.png" target="_blank" rel="noopener">Wyvern Skin</a>
<!-- DOCGEN:END id="voidwatch-loot" -->

## Atmacite Refiner

The **Officer** NPC on Purgonorgo Isle runs the **Atmacite Refiner** — spend the atmacite shards you bank from Pearl lights on six perks that empower your Voidwatch runs. Each perk levels up; the cost climbs with every level.

<!-- DOCGEN:BEGIN id="voidwatch-atmacite" -->
| Perk | Effect | Max level | Cost (shards) |
|---|---|---|---|
| **Fortune** | +8% cruor per level | 5 | 3 × next level (to 45 at max) |
| **Fervor** | +8% EXP per level | 5 | 3 × next level (to 45 at max) |
| **Greed** | +1 loot roll per level | 4 | 3 × next level (to 30 at max) |
| **Insight** | +1 max Light per colour per level | 3 | 3 × next level (to 18 at max) |
| **Attunement** | -0.5s weakness cooldown per level | 4 | 3 × next level (to 30 at max) |
| **Flow** | +12% Voidstone regen speed per level | 5 | 3 × next level (to 45 at max) |
<!-- DOCGEN:END id="voidwatch-atmacite" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: fdaef0f04e95 -->
_Last updated: 2026-07-10 16:53 PDT_
<!-- DOCGEN:END id="last-updated" -->
