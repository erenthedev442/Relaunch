# Systems Map

Every system on the Relaunch server feeds into something else. This page maps the full picture — what exists, what it produces, and roughly when each piece opens up.

---

## The big picture

```
New character → Level 99 → Hunting League (Ranks I–V) → Endgame
```

**Hunt Marks** are the primary currency for the entire game. You earn them by killing Hunting League NMs, spend them to unlock the next rank and buy Seals, and Seals buy gear. Everything branches off that spine.

| Phase | Gate | Core loop | Main output |
|---|---|---|---|
| **Foundation** | None | Level to 99, grab starter gear | Ready to hunt |
| **Core Loop** | Rank I–III | Pop NMs → Hunt Marks → Seals → Gear | Tier 1–3 gear, rank progress |
| **Content Unlocks** | Rank III | Abyssea, Affinity NMs, Unity, Dungeons | Reforge marks, affinity bonuses |
| **Deep Endgame** | Rank IV–V | HTBF, Dynamis, Voidwatch, Nyzul, Gauntlet | Top-tier gear, Infamy, Paragon Pts |
| **Vertical** | Always | Invasions, Apex, Prestige, Rebirth, Prime | Permanent stat bonuses |

---

## Phase 1 — Foundation

!!! note ""
    **Gate:** None. Available from the moment you create a character.

Every new character is **fully provisioned at creation** — every spell, all skills capped, complete trust roster, all key items, missions completed, and a starter gear kit. You also start with **+100 Hunt Marks** in the bank.

| System | What it does |
|---|---|
| Auto-setup | Spells, skills, trusts, key items, missions, maps, warps, starter gear — all done automatically |
| `!expcamp` | Warps to 20 level-banded camps. 3× mob EXP + 10× scripted EXP. Expect a few hours to 99. |
| `!buff` | Grants Refresh / Regen / Regain + the current zone's regional buff. Free, always available. |

Once you hit 99, type **`!hunt`** to warp to Escha Zi'Tah. The Hunt: Seals and Hunt: Spawner NPCs are side by side where you land.

---

## Phase 2 — Core Hunt Loop (Ranks I–III)

!!! tip ""
    **Gate:** None. This is the game's primary content engine from your first kill forward.

### The loop

1. Talk to **Hunt: Spawner** → pick a Rank I–III NM → it appears in front of you
2. Kill it → earn **Hunt Marks** (5 / 12 / 22 per kill at Ranks I / II / III)
3. Spend marks on **Seals** at the Seals Vendor
4. Spend Seals at the **Armor / Weapons / Accessories Vendors** in Escha Zi'Tah
5. Accumulate enough marks to unlock the next rank (150 → 650 → 1,500 → 3,000 total)

### Systems active in Phase 2

| System | What it produces |
|---|---|
| Hunting League Ranks I–III | Hunt Marks — 5 / 12 / 22 per kill by rank |
| Weekly Hunt Board (`!lib`) | Bonus marks — sweep all 5 objectives for a **+5,000 mark** meta-bonus |
| Daily Board (`!lib`) | Hunt Marks + Gil on daily objectives |
| Game Master / Wave Mode (`!wavemaster`) | Hunt Marks per difficulty cleared (Easy → Insane) |
| Seals Vendor | Bronze / Silver / Gold Seals |
| Armor Vendor | Tiered armor, gated by seal type |
| Weapons Vendor | Tiered weapons, gated by seal type |
| Accessories Vendor | Accessories + Sortie job earrings |

---

## Phase 3 — Content Unlocks (Rank III)

!!! abstract ""
    **Gate:** Hunting League **Rank III** (Elite). Unlock cost: 650 Hunt Marks total spent.

### Boss content → Reforge marks

Killing these NMs earns you **AF / Relic / Empy Marks** — the currency for the Reforge System, which upgrades AF, Relic, and Empy armor from base to +1, +2, and +3.

| System | Currency produced | Spent on |
|---|---|---|
| Abyssea NMs | AF / Relic / Empy Marks | Reforge Vendor (+1 / +2 / +3 armor) |
| Unity Concord | Accolades | Unity shop (gear, reward items) |
| HNM Kings / Sky Gods | AF / Relic / Empy Marks | Reforge Vendor |

### Affinity NMs → Augment Sage

The **Affinity NM** system bridges boss content and augmenting:

1. Kill one of the **24 always-up Affinity NMs** (classic HNMs, 15-min respawn)
2. The trophy drops **100% guaranteed** to the killing blow player
3. Take it to the **Augment Sage** at `!leaf` — register for **Rank III + 1,000 Hunt Marks**
4. Every augment roll in that stat category now gets a **1.5× value multiplier**

Full roster: [Affinity NMs](../endgame/affinity-nms.md)

### Augment systems

| System | What it does |
|---|---|
| Augment Moogle (`!leaf`) | Random stat augments on any gear piece. No gate — works from day 1. |
| Augment Sage (`!leaf`) | Permanent 1.5× affinity bonus per registered stat category. Gates: Rank III + Infamy threshold + 1,000 marks/affinity. |

### Other content opening around Rank III

- **Dungeons** — custom instanced zones with curated loot and boss encounters
- **Nyzul Isle** — 100-floor dungeon. Enter via the **Sorrowful Sage** NPC at Mhaura. No Assault rank needed. See [Nyzul Isle](../endgame/nyzul-isle.md).

---

## Phase 4 — Deep Endgame (Rank IV–V)

!!! warning ""
    **Gate:** Hunting League **Rank IV** (Champion) and above. Most of this content requires a party.

| System | What you get |
|---|---|
| **[High-Tier Battlefields](../endgame/high-tier-battlefields.md)** | 3 tiers via phantom gem entry. Best non-Infamy loot. Party required at T2+. |
| **[Dynamis – Divergence](../endgame/dynamis-divergence.md)** | 4 cities × 3 waves. Medal drops → Divergence armor → Reforge to +3. |
| **[Voidwatch](../endgame/voidwatch.md)** | Planar Rifts → Voidwalker NM → collect 5 LIGHTS → Pyxis loot chest. |
| **[Nyzul Isle](../endgame/nyzul-isle.md)** | 100 floors, 30-min timer, save-your-floor progression. Nyzul armor sets as rewards. |
| **[The Gauntlet](../endgame/the-gauntlet.md)** | 10-level solo NM climb. HP doubles each level. Clear all 10: **5M Gil + 500 Paragon Pts + 500 Infamy**. |
| **[Endless Tower](../endgame/endless-tower.md)** | Infinite escalating floors. How high you climb is the score. |
| **[Colosseum](../endgame/colosseum.md)** | Wave-based arena at `!leaf`. 10 Hunt Marks on clear. |
| **[Maat's Challenge](../endgame/maats-challenge.md)** | Battle Maat for rewards. |

---

## Always Active — Vertical Progression

!!! success ""
    **Gate:** None — these run in parallel with everything else and never stop paying out.

### Infamy track

Infamy accumulates from four sources and is spent at the **Infamy Vendor** (`!leaf`) for best-in-slot gear, relic weapons, and instruments. A minimum Infamy total also unlocks **Augment Sage** registration.

| Source | Notes |
|---|---|
| Scheduled Invasions | Wave events — server-wide announcement on start. Watch for the alert. |
| Star-Devourer Raid | Weekly server-wide raid boss. Party recommended. |
| Apex Trials | `!apex` — post-cap NMs at the Apex arena. Infamy + Paragon Points per kill. See [Apex & Paragon](../endgame/apex-paragon.md). |
| The Gauntlet | 500 Infamy per floor-10 clear. |

### Paragon board

**Apex Trials** and **The Gauntlet** produce **Paragon Points**. Spend them on the **Paragon Board** for permanent account-wide stat bonuses that never reset.

### Prestige and Rebirth

| System | How it works |
|---|---|
| **[Prestige](../progression/prestige.md)** | Max your HL rank on a job → reset it for a permanent per-job bonus. Stackable across all 22 jobs. |
| **[Job Rebirth](../progression/job-rebirth.md)** | After Prestige: re-grind RP (kills) for larger permanent stat bonuses. |

### Prime Weapons

The **Prime Armory** at `!leaf` lets you forge a Prime Weapon through 5 trials using Sigils + Hunt Marks. Sixteen named Prime Weapon III forms available. See [Prime Armory](../progression/prime-armory.md).

### Mastery systems

| System | What it does |
|---|---|
| **[Spell & Skill Mastery](../progression/spell-mastery.md)** | Mastery Sage at `!leaf`. Spend Sigils to empower weapon skills and spells beyond their normal caps. |
| **[Job Mastery](../endgame/job-mastery.md)** | Earn Mastery Points by killing specific mob types. Permanent per-job-class bonuses. |

---

## Currencies at a Glance

| Currency | Earn from | Spend on |
|---|---|---|
| **Hunt Marks** | Kill HL NMs (5–110/kill); Weekly & Daily Boards; Colosseum; Wave Master | Seals, rank unlocks (150/650/1500/3000 marks total), reward shop, Affinity registration (1,000 each) |
| **Seals** (Bronze / Silver / Gold) | Trade Hunt Marks at the Seals Vendor | Armor, Weapons, and Accessories Vendors — seal tier gates the gear tier |
| **AF / Relic / Empy Marks** | Abyssea NMs, Unity Concord NMs, HNM Kings (Sky Gods) | Reforge Vendor — upgrade armor from base to +1 / +2 / +3 |
| **Infamy** | Invasions, Apex Trials, Star-Devourer Raid, The Gauntlet | Infamy Vendor (BiS gear + relic weapons); also unlocks Augment Sage |
| **Paragon Points** | Apex Trials (per kill), The Gauntlet (floor-10 clear) | Paragon Board — permanent account-wide stat bonuses |
| **Affinity Trophies** | Kill one of 24 Affinity NMs — 100% drop to the killing blow player | Augment Sage registration (Rank III + 1,000 Hunt Marks per affinity) |
| **Sigils** | Regional buff via `!buff` grants the current zone's Sigil | Prime Armory trials, Spell & Skill Mastery empowers |
| **Gil** | Quests (100× rate), crafting, drops, The Gauntlet (5M on floor-10 clear) | AH, consumables, crafting materials, NPC vendors |

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: placeholder -->
_Last updated: 2026-07-02 00:00 UTC_
<!-- DOCGEN:END id="last-updated" -->
