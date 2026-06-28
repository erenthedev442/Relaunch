# Voidwatch

Tears in the void have opened across Vana'diel. The **Voidwatch** system sends you into the field to find them — examine a **Planar Rift** in any of 30 overworld zones, and a tier-scaled Voidwalker NM tears through. Each rift you survive raises your abyssite rank, scaling every fight harder and paying more.

!!! tip "Summary"
    Find a Planar Rift in the overworld, spend a Voidstone to open a rift, fight a Voidwalker NM, and probe its hidden weaknesses with magic, weaponskills, and ranged attacks to shape your reward. Use `!voidwatch` to check status or buy Voidstones.

## Getting started

The **Officer** NPC in **Leafallia** sells Voidstones (400 Cruor each) and runs the **Atmacite Refiner** where you spend Voidwatch_Shards on permanent perks. You start with **5 Voidstones** the first time you engage the system.

- **Carry cap:** 10 Voidstones
- **Regen:** 1 Voidstone every hour, real time
- **Rift cost:** 1 Voidstone per opening

Use `!voidwatch` at any time to check your Voidstones, cruor balance, and current tier.

## Planar Rifts

Planar Rifts are clickable objects scattered across **30 overworld zones** — original Vana'diel areas from West Ronfaure to Sauromugue Champaign and beyond. Examine one, confirm you want to spend a Voidstone, and the NM tears through right where you stand.

The rift battle runs for up to **30 minutes**. If the NM survives, it voids out.

## Tier scaling

Your **abyssite rank** (your Voidwatch_Tier) determines the strength of the next rift. Clearing a tier increments it — every rift is tougher than your last. The scaling is continuous with no cap: level, HP, stats, and mechanics all climb together.

| What scales | Formula |
|---|---|
| NM level | 78 + tier × 4 |
| NM HP | ~180,000 + tier × 110,000 |
| Attack / accuracy | Base 700–550, +200–110 per tier |

At higher tiers the NM gains additional mechanics (see below).

## Hidden weaknesses and Lights

Every rift hides **5 weaknesses**, one per Light colour. Probe the NM during the fight by using magic elements, weaponskills, or ranged attacks — when you hit a weakness, a **Light** activates and is announced in chat. Stack up to 5 of each colour; more Lights = better reward from the Riftworn Pyxis.

| Light | Colour | Boosted by | Reward boon |
|---|---|---|---|
| **Vermillion** | Red | (random trigger) | +8 to quality roll per light |
| **Cerulean** | Blue | (random trigger) | +1 loot roll per 2 lights |
| **Verdant** | Green | (random trigger) | +25% cruor per light |
| **Amber** | Yellow | (random trigger) | +25% EXP per light |
| **Pearl** | White | (random trigger) | 1 atmacite shard per light |

The 5 weaknesses are rolled fresh each rift from a pool of fire/ice/wind/earth/lightning/water/light/dark magic elements, weaponskills, and ranged attacks — every job can draw Lights.

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

## Atmacite Refiner

The **Officer** NPC in Leafallia runs the **Atmacite Refiner** — spend **Voidwatch_Shards** (your accumulated Pearl-light atmacite) on six permanent perks that enhance your Voidwatch experience. Perks stack and persist across log-outs.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 000000000000 -->
_Last updated: 2026-06-27_
<!-- DOCGEN:END id="last-updated" -->
