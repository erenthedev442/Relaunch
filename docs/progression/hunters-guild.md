# Hunter's Guild

The Hunter's Guild is a passive reputation system layered on top of every NM-killing track on the Relaunch server. Killing NMs earns reputation in the matching guild; rep-rank-ups boost the marks you earn from that same guild for the rest of your character's life.

!!! tip "Summary"
    Kill NMs → earn rep in the matching guild → rep ranks up → earned marks get amplified more at each rank (see the ladder below). Hit Grandmaster across multiple guilds for the **Trinity Hunter** or **Apex Hunter** capstone stacked on top. Use `!huntrank` to see your status anywhere.

## The four guilds

Each guild parallels one NM-kill source on the server. Reputation in guild X amplifies marks earned in guild X's currency only.

| Guild | NM source | Currency it amplifies |
|---|---|---|
| **AF Hunters' Guild** | Reforge **AF** (Sky Gods) NMs | AF Marks |
| **Relic Hunters' Guild** | Reforge **Relic** (Unity) NMs | Relic Marks |
| **Empyrean Hunters' Guild** | Reforge **Empy** (Abyssea) NMs | Empyrean Marks |
| **League Hunters' Guild** | [Hunting League](index.md) NMs | Hunt Marks |

Reputation **is** the kill's base mark value — i.e. the marks you'd earn *before* the amplifier. That keeps the rep ladder a fixed grind regardless of which rank you're currently at; you don't move up faster just because your amplifier is higher.

## Rank ladder

The same six ranks apply to all four guilds. Thresholds and amplifier values:

<!-- DOCGEN:BEGIN id="hunters-guild-ranks" -->
| Rank | Rep needed | Amplifier |
|---|---:|---:|
| Apprentice | 0 | +0% |
| Journeyman | 500 | +10% |
| Veteran | 5,000 | +25% |
| Master | 25,000 | +50% |
| Champion | 55,000 | +75% |
| Grandmaster | 100,000 | +100% |
<!-- DOCGEN:END id="hunters-guild-ranks" -->

Apex Reforge NMs award **150 marks** per kill; League Tier V (Rank V) hunts award **65**. Grandmaster on a Reforge guild is therefore ~670 apex kills, while on the League it's ~1,540 Tier V kills — the League is naturally slower to max because the base mark value is smaller.

## Capstones

Reaching Grandmaster on multiple guilds **at the same time** unlocks a permanent meta-bonus that stacks on top of each individual guild's +100%.

<!-- DOCGEN:BEGIN id="hunters-guild-capstones" -->
| Capstone | Requires | Bonus | Applies to |
|---|---|---:|---|
| **Trinity Hunter** | Grandmaster in af + relic + empy | **+25%** | All Reforge marks (AF/Relic/Empy) |
| **Apex Hunter** | Grandmaster in **all four** guilds | **+50%** | All marks, supersedes Trinity |
<!-- DOCGEN:END id="hunters-guild-capstones" -->

Apex supersedes Trinity at the math level — once you flip the Apex flag, the system stops applying Trinity's +25% on Reforge marks (no double-dipping). The multiplier is **additive**: `multiplier = 1.0 + rankAmp + capstone`. For an Apex Hunter at Grandmaster that's `1.0 + 1.00 + 0.50 = 2.5×` base marks on every kill.

Capstone roll calls live on the [Leaderboards page](../community/leaderboards.md) — Trinity and Apex Hunters get their own sections.

## Hunt Targets

Reputation in each guild comes **exclusively** from killing the following Vana'diel NMs. Rep is shared with the **whole party/alliance** — every member present when the NM dies earns rep, regardless of who landed the killing blow.

All 20 hunt targets respawn on a flat **30-minute timer**, and each NM awards rep to a given player at most **once per 30 minutes** — a camper killing every respawn always earns rep, but re-killing the same NM sooner (see below) yields the kill and drops with no extra rep. Two targets — **King Vinegarroon** and **Fafnir** — also have fast-repop [Affinity NM](../endgame/affinity-nms.md) copies in the same zone; those copies count as the same NM for rep, so they can't out-earn the normal camp rate.

<!-- DOCGEN:BEGIN id="hunters-guild-hunt-targets" -->
<div class="milestone-grid" markdown="1">

#### af

| Tier | NM | Zone | Rep reward |
|---|---|---|---:|
| ★ | Tarasque | Ifrits Cauldron | 500 |
| ★★ | Capricornus | Jugner Forest | 750 |
| ★★★ | Charybdis | Sea Serpent Grotto | 1,000 |
| ★★★★ | Tiamat | Attohwa Chasm | 1,500 |
| ★★★★★ | Fafnir | Dragons Aery | 2,500 |

#### relic

| Tier | NM | Zone | Rep reward |
|---|---|---|---:|
| ★ | Cactrot Rapido | Eastern Altepa Desert | 500 |
| ★★ | Lord of Onzozo | Labyrinth of Onzozo | 750 |
| ★★★ | King Vinegarroon | Western Altepa Desert | 1,000 |
| ★★★★ | Khimaira | Caedarva Mire | 1,500 |
| ★★★★★ | Cerberus | Mount Zhayolm | 2,500 |

#### empy

| Tier | NM | Zone | Rep reward |
|---|---|---|---:|
| ★ | Faust | The Shrine of RuAvitau | 500 |
| ★★ | Despot | RuAun Gardens | 750 |
| ★★★ | Steam Cleaner | VeLugannon Palace | 1,000 |
| ★★★★ | Brigandish Blade | VeLugannon Palace | 1,500 |
| ★★★★★ | Bahamut | Riverne-Site B01 | 2,500 |

#### hl

| Tier | NM | Zone | Rep reward |
|---|---|---|---:|
| ★ | Bune | Gustav Tunnel | 500 |
| ★★ | Carmine Dobsonfly | Riverne-Site A01 | 750 |
| ★★★ | Aspidochelone | Valley of Sorrows | 1,000 |
| ★★★★ | Behemoth | Behemoths Dominion | 1,500 |
| ★★★★★ | Jormungand | Uleguerand Range | 2,500 |

</div>
<!-- DOCGEN:END id="hunters-guild-hunt-targets" -->

## Where to check your rank

In-game: `!huntrank` shows your current rank, rep, amplifier, and progress to the next rank for all four guilds — plus your Trinity / Apex flags.

## Backfill for existing players

Retroactive backfill is **off by default** on the Relaunch server. Under the current Vana'diel-hunt model, rep comes **only** from killing the listed open-world NMs — so everyone starts the guild ladder from zero and climbs it by hunting, even long-time players. Lifetime mark totals are *not* converted into starting rep.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: e74840b4a08c -->
_Last updated: 2026-07-12 08:02 PDT_
<!-- DOCGEN:END id="last-updated" -->
