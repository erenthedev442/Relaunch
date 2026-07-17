# Systems Map

Every system on the Relaunch server feeds into something else. This page maps the full picture — what exists, what it produces, and how the pieces connect. Everything below the line is regenerated from the live server catalogs on every site publish.

---

<!-- DOCGEN:BEGIN id="systems-map" -->
## The big picture

```
New character → Level 99 → Hunting League (Rank I–Rank V) → Endgame
```

**Hunt Marks** are the primary currency for the entire game. You earn them by killing Hunting League NMs, spend them to unlock the next rank and buy Seals, and Seals buy gear. Everything branches off that spine.

| Phase | Gate | Core loop | Main output |
| --- | --- | --- | --- |
| **Foundation** | None | Level to 99, first hunts | 25 starter marks, daily +50 |
| **Core Loop** | Rank gates: 150 → 650 → 1,500 → 3,000 lifetime marks | Pop NMs → Hunt Marks → Seals → Gear | Gear tiers, rank progress |
| **Content Unlocks** | Augment tier keys (see below) | Boss content → Reforge marks, affinities | Reforge armor, better augment rolls |
| **Deep Endgame** | Party content | HTBF, Dynamis, Voidwatch, Nyzul, Gauntlet | Top-tier gear, Infamy, Paragon Pts |
| **Vertical** | Always on | Prestige, Rebirth, Prime, Apex | Permanent stat bonuses |

---

## Phase 1 — Foundation

!!! note ""
    **Gate:** None. Available from the moment you create a character.

Every new character starts with **25 Hunt Marks**. Your first login each UTC day pays **+50 marks**, and login streaks add milestones: 7d **+75** · 14d **+200** · 21d **+400** · 30d **+750**.

| System | What it does |
| --- | --- |
| `!buff` | Grants Refresh / Regen / Regain + the current zone's regional buff — the buff also hands you that zone's Mastery Sigil. |
| Newcomer linkshell | Fresh characters are handed a pearl for the server linkshell automatically. |
| Adventuring Fellow | Your persistent companion — levels from your kills from day one. `!fellow` |
| Cross-Job Ability Trainer | Trainer at `!hub`. Pay a flat gil per ability (one-time, per character) to add a chosen job ability off-job. |
| Cross-Job Trait Trainer | Trainer at `!hub`. Pay a flat gil per trait (one-time, per character) to add a chosen job trait off-job. |
| Character Upgrader | One-shot first-login top-up — full wardrobes, wallet, and starter kit. Re-affirms whatever the char is missing. |

Once you hit 99, type **`!hunt`** to warp to Escha - Zi'Tah. The Hunt: Seals and Hunt: Spawner NPCs are side by side where you land.

---

## Phase 2 — Core Hunt Loop (Rank I–Rank III)

!!! tip ""
    **Gate:** None. This is the game's primary content engine from your first kill forward.

### The loop

1. Talk to **Hunt: Spawner** → pick an NM at your rank → it appears in front of you
2. Kill it → earn **Hunt Marks** (5 / 12 / 22 / 38 / 65 per kill at Rank I / Rank II / Rank III / Rank IV / Rank V)
3. Spend marks on **Seals** at the Seals Vendor
4. Spend Seals at the **Armor / Weapons / Accessories Vendors** in Escha - Zi'Tah
5. Accumulate lifetime marks to unlock the next rank (150 → 650 → 1,500 → 3,000 total)

Payout multipliers: your first-ever kill of each NM pays **double**; the weekly **Featured Hunt** pays 2× base (stacks with first-kill); kill streaks within 5 minutes add **+10% at 3, +20% at 5, +50% at 10**.

### Systems active in Phase 2

| System | What it produces |
| --- | --- |
| Hunting League Rank I–Rank V | Hunt Marks — 5 / 12 / 22 / 38 / 65 per kill by rank (Shinryu **110**) |
| Weekly Hunt Board (`!lib`) | Bonus marks — sweep all objectives for a **+5,000 mark** meta-bonus |
| Daily Board (`!lib`) | Hunt Marks + Gil on daily objectives |
| Game Master / Wave Mode (`!wavemaster`) | Hunt Marks per difficulty cleared |
| Seals Vendor | Bronze / Silver / Gold Seals |
| Armor Vendor | Tiered armor, gated by seal type |
| Weapons Vendor | Tiered weapons, gated by seal type |
| Accessories Vendor | Accessories + Sortie job earrings |

---

## Phase 3 — Content Unlocks

!!! abstract ""
    **Gate:** the Augment Moogle's content tiers. Tier 1 opens after: *reach level 99 on any job*.

### Boss content → Reforge marks

Killing these NMs earns **AF / Relic / Empy Marks** — the currency for the Reforge System, which upgrades AF, Relic, and Empy armor to +1 / +2 / +3.

| System | Currency produced | Spent on |
| --- | --- | --- |
| Abyssea NMs | AF / Relic / Empy Marks | Reforge Vendor (+1 / +2 / +3 armor) |
| Unity Concord | Accolades | Unity shop (gear, reward items) |
| HNM Kings / Sky Gods | AF / Relic / Empy Marks | Reforge Vendor |
| **[Hunter's Guild](../progression/hunters-guild.md)** | Reputation ranks (multiple guilds) | Passive: each rank amplifies that guild's mark payout — up to +% per guild at Grandmaster; **Trinity Hunter** / **Apex Hunter** capstones stack on top |

### Affinity NMs → Augment Sage

The **Affinity NM** system bridges boss content and augmenting:

1. Kill one of the **11 always-up Affinity NMs** (classic HNMs, back up 30 seconds after each kill)
2. The NM drops its unique **trophy**
3. Take the trophy to the **Augment Sage** at `!hub` and register the affinity (requires Hunting League Rank 3, costs 1,000 Hunt Marks)
4. Every augment roll in that stat category now **rolls twice and keeps the better result**

Full roster: [Affinity NMs](../endgame/affinity-nms.md)

### The Augment ladder

| Tier | Unlocked by |
| --- | --- |
| Augment Tier 1 | reach level 99 on any job |
| Augment Tier 2 | reach Hunting League Rank 5 |
| Augment Tier 3 | clear Voidspire floor 10 + every Game Master wave difficulty |
| Augment Tier 4 | clear a Dynamis - Divergence city |
| Augment Tier 5 | defeat Maat's Echo (Ru'Lude Gardens, !maat) |

Your Sage Mastery rank lifts the roll floor inside the unlocked band — see [Augments](../progression/augments.md).

### Other content in this phase

- **Dungeons** — custom instanced zones with curated loot and boss encounters
- **Nyzul Isle** — enter via the **Sorrowful Sage** NPC at Mhaura. No Assault rank needed. See [Nyzul Isle](../endgame/nyzul-isle.md).

---

## Phase 4 — Deep Endgame

!!! warning ""
    Most of this content expects endgame gear; several fights want a party.

| System | What you get |
| --- | --- |
| **[High-Tier Battlefields](../endgame/high-tier-battlefields.md)** | Retail HTBF fights via phantom gem entry, tiered difficulty. Access gate: **master the entering job (2,100 JP)** + **register all 11 NM affinities** at the Augment Sage. |
| **[Ambuscade](../endgame/ambuscade.md)** | On-demand instanced boss fights in Mhaura (3 modes × 5 difficulties). Gate: **1 HNM King kill + 1 HTBF clear at each of T1/T2/T3**. Clears pay **Hallmarks** (200k monthly cap) + **Gallantry** for the 5-stage weapon upgrade chain (Tokko → Ajja → Eletta → Kaja → Final: Naegling, Karambit, Nandaka, Tauret, …). |
| **[Dynamis – Divergence](../endgame/dynamis-divergence.md)** | 4 cities × wave battles. **Entry toll: 250 Reforge Marks (AF / Relic / Empyrean)**. The **+3 → +4 Forge**: farm Rusted/Black ID Cards + a Mega-Boss Paragon Card, trade a reforged +3 AF/Relic piece → **+4** (AF & Relic only; Empy caps at +3). |
| **[Voidwatch](../endgame/voidwatch.md)** | Planar Rifts → Voidwalker NM → collect lights → Pyxis loot chest |
| **[Domain Invasion](../endgame/domain-invasion.md)** | Server-wide co-op event across the two Escha zones (8×/day). Two waves + a named boss; pays **Escha Silt**, **Escha Beads**, and **Domain Points**. `!diwarp` |
| **[Nyzul Isle](../endgame/nyzul-isle.md)** | Floor-climb dungeon runs with Nyzul armor rewards |
| **[The Gauntlet](../endgame/the-gauntlet.md)** | Solo NM climb. Full clear: **5,000,000 Gil + 500 Paragon Pts + 500 Infamy**. |
| **[Endless Tower](../endgame/endless-tower.md)** | Infinite escalating floors. How high you climb is the score. |
| **[Colosseum](../endgame/colosseum.md)** | Ladder arena at `!hub` — 10 Hunt Marks per win |
| **[Maat's Challenge](../endgame/maats-challenge.md)** | `!maat` — the solo super-fight; first kill is an Augment Tier key |
| **[Geas Fete](../endgame/geas-fete.md)** | ??? pop-a-NM across Escha - Zi'Tah, Escha - Ru'Aun, and Reisenjima. Pays **Escha Beads** (shared currency) and drops the Aeonic weapon crafting materials (Attestations + Riftborn Boulders). |
| **[Voidspire](../endgame/voidspire.md)** | Endless escalating wave-gauntlet at the Warden in Escha - Ru'Aun. Trusts enabled; a wipe ends the run and records your deepest floor on the leaderboard. |
| **[Omen](../endgame/omen.md)** | Reisenjima Henge gauntlet: five gates of trials, three Glassy sentinels, and the **Caturae** (Kin, Gin, Fu, Kyou, Kei) with the hidden Prime **Ou** beyond them. |
| **REMA / Prime WS Enhancement** | Upgrade weapon-skill damage and mods on Relic / Empyrean / Mythic / Aeonic / Prime weapons — the WS tuning layer sitting on top of the endgame weapon ladder. |
| **[Open World Mob Scaling](../progression/server-features.md#open-world-mob-scaling)** | Always-on stat floors for ordinary mobs (level 91+) across the open-world progression zones — under-tuned field mobs are raised to the relaunch curve the moment they spawn. |
| **Commemoration Moogle** | One-time reward the first time a character reaches level 99: pick a bundle of free augment catalysts to kick-start [augmenting](../progression/augmenting-guide.md). |

---

## Always Active — Vertical Progression

!!! success ""
    **Gate:** None — these run in parallel with everything else and never stop paying out.

### Infamy track

Infamy accumulates from the sources below and is spent at the **Infamy Vendor** (`!hub`) for best-in-slot gear.

| Source | Notes |
| --- | --- |
| Scheduled Invasions | Wave events — server-wide announcement on start |
| Star-Devourer Raid | Weekly server-wide raid boss. Party recommended. |
| Apex Trials | `!apex` — post-cap NMs. Infamy + Paragon Points per kill. See [Apex & Paragon](../endgame/apex-paragon.md). |
| The Gauntlet | 500 Infamy per full clear |

### Paragon board

**Apex Trials** produce **Paragon Points**. Spend them on the **Paragon Board** for permanent account-wide stat bonuses that never reset.

### Prestige and Rebirth

| System | How it works |
| --- | --- |
| **[Prestige](../progression/prestige.md)** | Reach Hunting League Rank 5 → the Ascension Altar opens. Nightmare Court kills pay Ascension AP for permanent per-job bonuses. |
| **[Job Rebirth](../progression/job-rebirth.md)** | Any job with **2,100 spent Job Points** can rebirth — permanent stacking category boosts. |

### Capacity farm

Job Points fuel Rebirth, and the **[Capacity farm](../progression/capacity-farm.md)** is how you bank them: instant-respawn phantom camps at Bibiki Bay (`!capacity`) and King Ranperre's Tomb (`!ranperre`) pay bonus Capacity Points per kill so your capacity chain never goes cold.

### Prime Weapons

The **Prime Armory** at `!hub` forges a Prime Weapon after **5 trials** — 16 named forms, 750,000,000 gil per forge. See [Prime Armory](../progression/prime-armory.md).

### Mastery systems

| System | What it does |
| --- | --- |
| **[Spell & Skill Mastery](../progression/spell-mastery.md)** | Mastery Sage at `!hub`. Spend Mastery Sigils to empower weapon skills and spells beyond their normal caps. |
| **[Job Mastery](../endgame/job-mastery.md)** | Earn Mastery Points by killing specific mob types. Permanent per-job-class bonuses. |

### Side Activities & Events

| System | What it does |
| --- | --- |
| **[Chocobo Derby](../endgame/chocobo-derby.md)** | Bet gil on chocobo races at the Race Caller in Purgonorgo Isle; raise a strong chocobo and enter it as a runner for a bigger payout. |
| **[Casino — Lady Luck](../endgame/casino.md)** | Four-game gil-sink casino (slots, high-low, roulette, dice) run by Lady Luck at `!leaf`. Biggest wins shout server-wide. |
| **[Tournament](../endgame/tournament.md)** | `!tournament join` during sign-ups. Warp in, fight 8 waves, last team standing takes the crown (Hunt Marks + Infamy for surviving members). |
| **[Treasure Hunts](../endgame/treasure-hunts.md)** | Hunting League kills can drop treasure maps. Take one to its overworld zone and dig; hot/cold feedback guides you to a strongbox of marks, gil, and augment catalysts. |
| **[Provisioners' League](../endgame/provisioners-league.md)** | Fish and turn in HQ crafts at the League Steward in **Escha - Zi'Tah** to earn League Points. Five ranks; each rank stacks a permanent mark bonus. |
| **[Live Events](../endgame/live-events.md)** | Three standing bonuses on fixed clocks: daily **Happy Hour** EXP/CP boost, **Divergence City of the Day** (bonus medals on clear), **Unity weekly featured NM** (double accolades). Live-events board on the Player Portal counts each one down. |
| **Sparks Exchange** | Trade retail Sparks-of-Eminence for Hunt Marks + seals + augment catalysts at the exchange NPC. |
| **Cosmetic Boutique** | Gil-only cosmetic outlet — dyes, glamours, model swaps. Pure vanity, no stats. |

### Achievements

**Achievements** are personal milestones that award bonus Hunt Marks and occasionally an in-game title on first completion. Every eligible player can earn each achievement — not server-first exclusives.

---

## Currencies at a Glance

| Currency | Earn from | Spend on |
| --- | --- | --- |
| **Hunt Marks** | Kill HL NMs (5–110/kill); daily login (+50); Weekly & Daily Boards; Wave Master | Seals, rank unlocks (150 → 650 → 1,500 → 3,000 lifetime), reward shop; Affinity registration (1,000 each) |
| **Seals** (Bronze / Silver / Gold) | Trade Hunt Marks at the Seals Vendor | Armor, Weapons, and Accessories Vendors — seal tier gates the gear tier |
| **AF / Relic / Empy Marks** | Abyssea NMs, Unity Concord, HNM Kings | Reforge Vendor — upgrade armor to +1 / +2 / +3 |
| **Infamy** | Invasions, Apex Trials, The Gauntlet | Infamy Vendor (BiS gear) |
| **Paragon Points** | Apex Trials, The Gauntlet (500/clear) | Paragon Board — permanent account-wide stat bonuses |
| **Affinity Trophies** | Kill one of the 11 Affinity NMs | Augment Sage registration — better rolls in that stat category |
| **Mastery Sigils** | Regional buff via `!buff` grants the current zone's Sigil | Prime Armory trials, Spell & Skill Mastery empowers |
| **Hallmarks / Gallantry** | Clear Ambuscade fights (Mhaura) | Gorpa-Masorpa — armor vouchers, weapon skins, Abdhaljs upgrade mats |
| **Escha Silt / Beads / Domain Points** | Domain Invasion (Escha zones, 8×/day) | Escha vendors and Domain Point rewards |
| **Capacity Points** | Capacity farm — Bibiki Bay (`!capacity`), King Ranperre's Tomb (`!ranperre`) | Convert to Job Points → Job Rebirth |
| **Gil** | Quests, crafting, drops, The Gauntlet (5,000,000 on full clear) | AH, consumables, crafting materials, NPC vendors |

*Every number on this page is regenerated from the live server catalogs on each site publish — if it disagrees with the game, the next hourly publish reconciles it.*
<!-- DOCGEN:END id="systems-map" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: fbfd1cd013c7 -->
_Last updated: 2026-07-17 04:15 PDT_
<!-- DOCGEN:END id="last-updated" -->
