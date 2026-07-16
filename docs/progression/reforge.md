# Reforge System

![Forge hammer](../assets/emblems/reforge.svg){ .lgnd-emblem }

The Reforge System is a custom NM-hunting + armor-upgrade pipeline that takes you from base AF/Relic/Empyrean armor to +3 versions through three parallel tracks.

!!! tip "Summary"
    Warp to the Reforge hub with `!reforged` and talk to any **NM Spawner** station. Pop one of three NM pools. Each kill drops a random base armor piece from that pool's set plus marks for that set. Take base pieces to the **Reforge Vendor** at the hub entrance to upgrade base → +1 → +2 → +3 using the same marks.

!!! info "Want +4?"
    This system caps at **+3**. The **+4** tier for **AF and Relic** armor is a separate, endgame upgrade forged at the [Dynamis-Divergence Forge](../endgame/dynamis-divergence.md) — trade a reforged **+3** piece plus materials farmed in the [D] zones. (Empyrean has no +4.)

## How it works

Three parallel tracks. Each track ties one **NM pool**, one **currency**, and one **armor set** together:

| Track | NM pool | Currency | Armor set |
|---|---|---|---|
| **AF** | Sky Gods | AF Marks | Job's AF/Artifact armor |
| **Relic** | Unity NMs | Relic Marks | Job's Relic armor |
| **Empyrean** | Abyssea NMs | Empyrean Marks | Job's Empyrean armor |

Every NM kill awards:

1. **One base piece.** Each drop has a configurable chance of being for the killer's **main job** (currently **50%**); the remainder fall back to a random piece across all jobs. When you get a job-matched drop, your chat message includes `(main-job match!)`.
2. **Marks** for that track's currency.

The Reforge Vendor sells progressive upgrades: trade in a base piece + marks for +1, trade +1 + marks for +2, trade +2 + marks for +3.

All Reforge NMs are **level 99**. Their I–V power steps come from custom HP, stat, and mechanic profiles rather than level correction.

!!! tip "Roughly how many kills for a full +3 set?"
    With the 50% main-job bias and the current mark/cost values, expect **~50-80 NM kills** to complete a 5-piece +3 set on one specific job. Marks accumulate alongside drops, so the bottleneck is rolling the right slots — the bias makes each kill ~11× more likely to land on a piece you want.

## NPC locations

<!-- DOCGEN:BEGIN id="reforge-hub" -->
The Reforge hub lives in **Diorama Abdhaljs-Ghelsba** — warp straight there with `!reforged`. One shared **Reforge Vendor** and **Mark Exchange** sit at the hub entrance, with **3 independent NM Spawner stations** spread across the zone (each has its own single-occupancy guard, so multiple parties — even popping the same NM — farm side by side).

| Station | Position |
|---|---|
| **NM Spawner 1** | `(-0.66, 0.00, -3.10)` |
| **NM Spawner 2** | `(16.64, -0.54, 52.22)` |
| **NM Spawner 3** | `(-26.16, 0.28, 94.49)` |
<!-- DOCGEN:END id="reforge-hub" -->

## NM pools and rewards

<!-- DOCGEN:BEGIN id="reforge-sources" -->
### AF (Sky Gods)

**Currency:** AF Marks

| NM | Level / power step | Marks per kill |
|---|---:|---:|
| Genbu | Lv99 / I | 60 |
| Suzaku | Lv99 / II | 80 |
| Seiryu | Lv99 / III | 100 |
| Byakko | Lv99 / IV | 125 |
| Kirin | Lv99 / V | 150 |

### Relic (Unity NMs)

**Currency:** Relic Marks

| NM | Level / power step | Marks per kill |
|---|---:|---:|
| Bukhis | Lv99 / I | 60 |
| Khun | Lv99 / II | 80 |
| Padfoot | Lv99 / III | 100 |
| Glavoid | Lv99 / IV | 125 |
| Tinnin | Lv99 / V | 150 |

### Empyrean (Abyssea NMs)

**Currency:** Empy Marks

| NM | Level / power step | Marks per kill |
|---|---:|---:|
| Aello | Lv99 / I | 60 |
| Iratham | Lv99 / II | 80 |
| Briareus | Lv99 / III | 100 |
| Itzpapalotl | Lv99 / IV | 125 |
| Hadhayosh | Lv99 / V | 150 |
<!-- DOCGEN:END id="reforge-sources" -->

## Upgrade costs

<!-- DOCGEN:BEGIN id="reforge-costs" -->
| Set | base → +1 | +1 → +2 | +2 → +3 |
|---|---:|---:|---:|
| AF (Sky Gods) | 300 | 900 | 2000 |
| Relic (Unity NMs) | 300 | 900 | 2000 |
| Empyrean (Abyssea NMs) | 300 | 900 | 2000 |

_Costs are paid in that set's marks (e.g. AF upgrades cost AF Marks)._
<!-- DOCGEN:END id="reforge-costs" -->

## Per-job set names

The catalog covers every job. Each job has three named sets across the AF/Relic/Empyrean tracks:

<!-- DOCGEN:BEGIN id="reforge-job-sets" -->
| Job | AF | Relic | Empyrean |
|---|---|---|---|
| WAR | Pummeler's | Agoge | Boii |
| MNK | Anchorite's | Hesychast's | Bhikku |
| WHM | Theophany | Piety | Ebers |
| BLM | Spaekona's | Archmage's | Wicce |
| RDM | Atrophy | Vitiation | Lethargic |
| THF | Pillager's | Plunderer's | Skulker's |
| PLD | Reverence | Caballarius | Chevalier's |
| DRK | Ignominy | Fallen's | Heathen's |
| BST | Totemic | Ankusa | Nukumi |
| BRD | Brioso | Bihu | Fili |
| RNG | Orion | Arcadian | Amini |
| SAM | Wakido | Sakonji | Kasuga |
| NIN | Hachiya | Mochizuki | Hattori |
| DRG | Vishap | Pteroslaver | Peltast's |
| SMN | Convoker's | Glyphic | Beckoner's |
| BLU | Assimilator's | Luhlaza | Hashishin |
| COR | Laksamana's | Lanun | Chasseur's |
| PUP | Foire | Pitre | Karagoz |
| DNC | Maxixi | Horos | Maculele |
| SCH | Academic's | Pedagogy | Arbatel |
| GEO | Geomancy | Bagua | Azimuth |
| RUN | Runeist | Futhark | Erilaz |
<!-- DOCGEN:END id="reforge-job-sets" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 6864c7c7eb47 -->
_Last updated: 2026-07-11 21:16 PDT_
<!-- DOCGEN:END id="last-updated" -->
