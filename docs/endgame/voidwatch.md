# Voidwatch

Tears in the void have opened across Vana'diel. The **Voidwatch** system sends you into the field to find them — examine a **Planar Rift** in any of 30 overworld zones, and a tier-scaled Voidwalker NM tears through. Each rift you survive raises your abyssite rank, scaling every fight harder and paying more.

!!! tip "Summary"
    Find a Planar Rift in the overworld, spend a Voidstone to open a rift, fight a Voidwalker NM, and probe its hidden weaknesses with magic, weaponskills, and ranged attacks to shape your reward. Use `!voidwatch` to check status or buy Voidstones.

## Getting started

The **Officer** NPC in **Leafallia** sells Voidstones and runs the **Atmacite Refiner** where you spend atmacite shards on permanent perks. You start with a stock of Voidstones the first time you engage the system.

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
| **Krabkatoa** | Acubens Helm, Karka Ring | Krabkatoa Shell, Igneous Barnacle, Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Raker Bee** | Philosophers Stone | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Yacumama** | Backlash Torque | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Farruca Fly** | Alert Ring | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Gorehound** | Philosophers Stone | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Skuld** | Veela Cape | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Blobdingnag** | Blobnag Ring, Beguiling Collar | Muculent Ingot, Baby Blobdingnag, Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Capricornus** | Fierce Belt | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Shoggoth** | Jinx Ampulla | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Dawon** | Succor Ring, Leonine Mask | Pelt of Dawon, Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Jyeshtha** | Fatality Belt | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Lamprey Lord** | Hirudinea Earring | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Feuerunke** | Pagondas Earring | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Gjenganger** | Philosophers Stone | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Tammuz** | Repelling Collar | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Aglaophotis** | Sattva Ring | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Erebus** | Nyx Gorget | Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Lord Ruthven** | Strigoi Ring, Marching Belt | Ruthvens Nail, Ingot of Befouled Silver, Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |
| **Yilbegan** | Zilant Ring, Galdr Ring, Agronas Leggings, Lucky Coin | Square of Scarlet Kadife, Reraiser, Vile Elixir, Hi-reraiser, Vile Elixir +1 |

**Shared common tier** (quality 0–59 — every Voidwalker also rolls these standard crafting materials): Chunk of Dark Ore, Chunk of Darksteel Ore, Chunk of Earth Ore, Chunk of Fire Ore, Chunk of Gold Ore, Chunk of Ice Ore, Chunk of Light Ore, Chunk of Lightning Ore, Chunk of Mythril Ore, Chunk of Platinum Ore, Chunk of Water Ore, Chunk of Wind Ore, Coral Fragment, Darksteel Ingot, Demon Horn, Ebony Log, Gold Ingot, Handful of Wyvern Scales, Mahogany Log, Manticore Hide, Mythril Ingot, Petrified Log, Philosophers Stone, Phoenix Feather, Platinum Ingot, Ram Horn, Ram Skin, Slab of Granite, Spool of Gold Thread, Square of Rainbow Cloth, Square of Raxa, Wyvern Skin
<!-- DOCGEN:END id="voidwatch-loot" -->

## Atmacite Refiner

The **Officer** NPC in Leafallia runs the **Atmacite Refiner** — spend the atmacite shards you bank from Pearl lights on six perks that empower your Voidwatch runs. Each perk levels up; the cost climbs with every level.

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
<!-- content-hash: da5195b29ca9 -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
