# Progression

![Hunt beast crest](../assets/emblems/hunting-league.svg){ .lgnd-emblem }

Forget what you know about retail progression on the Relaunch server. Story missions still exist, but the real path through the game runs through the **Hunting League** — a custom rank-based NM hunting system that drives both gear acquisition and endgame challenge.

!!! tip "Summary"
    Level to 99 (a couple of hours with <!--setting:map.EXP_RATE-->3<!--/setting-->× mob EXP / <!--setting:main.EXP_RATE-->10<!--/setting-->× scripted), type **`!hunt`** to warp to **Escha ZiTah**, find the **Hunt Seals** and **Spawner** NPCs, pop NMs, earn **Hunt Marks**, unlock the next rank, buy endgame gear. Repeat through 5 ranks until you take down Shinryu at the top.

## Currencies at a glance

the Relaunch server layers a handful of custom currencies on top of gil. Here's what each one is, how you earn it, and where it's spent:

| Currency | How you earn it | Where you spend it |
|---|---|---|
| **Hunt Marks** | Killing Hunting League NMs (5–65 per kill by rank), Weekly Hunts, and the Wave Master | Hunt Hub reward shop — rank unlocks, seals, and Sortie job earrings |
| **Seals** (Bronze / Silver / Gold) | Bought with Hunt Marks at the Seals NPC | [Armor & Weapons vendors](gear-vendors.md) at Escha ZiTah |
| **AF / Relic / Empy Marks** | Killing Sky God / Unity / Abyssea NMs | [Reforge system](reforge.md) — upgrade AF/Relic/Empy armor from base to +3 |
| **Infamy** | Endgame content — Abyssea NM hunts, Invasions, and the weekly Raid | [Infamy Vendor](gear-vendors.md#infamy-vendor) — relic weapons, instruments & best-in-slot gear; also unlocks the Augment Sage |
| **Gil** | Quests (100× rate), crafting, and drops | Auction House, NPC vendors, consumables |

## The Hunting League at a glance

The system has **two NPCs side-by-side** in Escha ZiTah:

| NPC | Purpose |
|---|---|
| **Hunt: Seals** | Shows your rank and Hunt Marks. Unlock the next rank. Visit the reward shop. |
| **Hunt: Spawner** | Spawns the current rank's NMs on demand. No mob_spawn_points needed — they appear in front of you. |

**Currency:** Hunt Marks (carried as a character variable, not an inventory item).

**Cooldown:** None — you can spawn the next NM as soon as the previous one is dead.

**Anti-stack:** If an NM of the same type is already alive, the Spawner won't let you pop another.

**Tier gating:** Kill credit only counts if your rank is at or above the mob's tier — no skipping ahead.

## How it works in 6 steps

1. Type **`!hunt`** in chat. You'll warp directly to Escha ZiTah and land next to the Hunt Seals — no map navigation required.
2. Talk to **Hunt: Spawner** (right next to the Seals).
3. Pick an NM from your current rank's list.
4. The NM appears at the spawn point. Engage and kill it (you must land the killing blow, or be the player credited as `killer`).
5. Hunt Marks land in your character variable instantly. You'll see a system message.
6. Back to **Hunt: Seals** to unlock the next rank or spend marks at the reward shop.

## The Ranks

Each rank has 3 NMs to hunt. You can repeatedly kill the same NM to farm marks. Higher ranks have tougher targets but pay more per kill.

<!-- DOCGEN:BEGIN id="hunting-league-tiers" -->
### Rank I - Initiate

**Unlock cost:** 0 Hunt Marks  ·  **Hunt Marks per kill:** 5

| NM | Points |
|---|---:|
| Leaping Lizzy | 5 |
| Valkurm Emperor | 5 |
| Tom Tit Tat | 5 |

### Rank II - Hunter

**Unlock cost:** 50 Hunt Marks  ·  **Hunt Marks per kill:** 12

| NM | Points |
|---|---:|
| Roc | 12 |
| Bomb Queen | 12 |
| Aquarius | 12 |

### Rank III - Elite

**Unlock cost:** 150 Hunt Marks  ·  **Hunt Marks per kill:** 22

| NM | Points |
|---|---:|
| Serket | 22 |
| Vrtra | 22 |
| Simurgh | 22 |

### Rank IV - Champion

**Unlock cost:** 350 Hunt Marks  ·  **Hunt Marks per kill:** 38

| NM | Points |
|---|---:|
| Nidhogg | 38 |
| King Behemoth | 38 |
| Kirin | 38 |

### Rank V - Legend

**Unlock cost:** 700 Hunt Marks

| NM | Points |
|---|---:|
| Absolute Virtue | 65 |
| Pandemonium Warden | 65 |
| Shinryu | 110 |
<!-- DOCGEN:END id="hunting-league-tiers" -->

!!! tip "Rank V notes"
    **Shinryu** at Rank V is the explicit gear-check — level 225–250 with 40× HP, 8000 DEF, 15000 ATT. Bring a party.
    **Leaping Lizzy** at Rank I is also buffed beyond its retail stats (+1500 ATT, +350 DEF). Don't underestimate the "starter."

## The Reward Shop

Spend Hunt Marks at the Seals NPC. The shop is paginated (3 items per page). Inventory must have a free slot or the purchase fails.

<!-- DOCGEN:BEGIN id="hunting-league-rewards" -->
The reward shop is organized into 4 categories — 50 purchasable entries in all, every price in Hunt Marks. The **Seals** category converts marks into the Bronze/Silver/Gold seals you spend at the Armor and Weapons vendors, while the **Sortie** categories sell job earrings. The full per-item earring list lives on the [Gear Vendors](gear-vendors.md) page.

| Category | Items | Cost each (Hunt Marks) |
|---|---:|---:|
| Seals | 3 | 5–40 |
| Sortie: NQ | 22 | 100 |
| Sortie: +1 | 22 | 200 |
| Spells | 3 | 200–400 |
<!-- DOCGEN:END id="hunting-league-rewards" -->

**Approximate full clear:** 1,250 marks for rank unlocks + ~5,500+ marks for every shop item.

## Recommended progression order

<!-- DOCGEN:BEGIN id="progression-order" -->
1. **Visit GM Home first.** Type `!gmhome` to warp there instantly. Collect your starter gear from the Armor and Accessories NPCs, pick up key items and any open missions, and configure your character. Nearly every system — Weekly Hunts, the Game Master, the Infamy Vendor, the Augment Sage — is accessible from GM Home.
2. **Hit level 99.** Use FoV books, ROE, trust grinding, or EXP rings. With <!--setting:map.EXP_RATE-->3<!--/setting-->× mob EXP and <!--setting:main.EXP_RATE-->10<!--/setting-->× scripted EXP, expect an afternoon.
3. **Warp to Reisenjima Henge** with `!hunt`. The command drops you right at the Seals and Spawner NPCs. _(Without `!hunt` the zone is gated behind mid-Seekers progression — use the command.)_
4. **Start Rank I - Initiate.** Pop any of the three NMs from the Spawner: Leaping Lizzy, Valkurm Emperor, Tom Tit Tat. Each kill pays **5 Hunt Marks**. Grind until you have **50 Hunt Marks** to unlock Rank II — talk to the Seals NPC to advance.
5. **Pick up Weekly Hunt objectives.** Visit the Weekly Hunt Board at GM Home (`!gmhome`) or type `!weekly` for a status check. Five random objectives roll fresh each Monday. Sweeping all 5 objectives in a single week pays a **5,000 Hunt Marks** meta-bonus on top of the per-objective rewards. Completing these adds a big mark income boost alongside your regular NM grind.
6. **Push through Rank II - Hunter and Rank III - Elite.** Rank II unlocks at **50 Hunt Marks** spent; each kill pays **12 Hunt Marks** (Roc, Bomb Queen, Aquarius). Rank III unlocks at **150 Hunt Marks** — kills pay **22 Hunt Marks** (Serket, Vrtra, Simurgh). Use accumulated marks to buy core BiS accessories: Brutal Earring, Epona’s Ring, Rajas Ring, Suppanomimi, etc.
7. **Try Game Master wave challenges at GM Home.** Talk to the Game Master NPC (`!gmhome`). Start with **Easy** difficulty: 3 waves, 1 mob per wave, manageable for a geared solo player. Full clear pays **50 Hunt Marks**. Harder difficulties (Normal / Hard / Insane) pay progressively more marks and unlock tougher wave pools.
8. **Unlock Rank IV - Champion and Rank V - Legend.** Rank IV costs **350 Hunt Marks** total spent; kills pay **38 Hunt Marks** (Nidhogg, King Behemoth, Kirin). Rank V costs **700 Hunt Marks** total spent — endgame kills pay **65 Hunt Marks** (Absolute Virtue, Pandemonium Warden, Shinryu). Rank V is the gear-check wall. Bring a party.
9. **Start the Reforge track.** Farm Sky Gods, Unity NMs, and Abyssea NMs for AF Marks, Relic Marks, and Empy Marks. These currencies feed the Reforge system to upgrade your AF/Relic/Empy armor to +1 / +2 / +3 tiers. Type `!huntrank` to check your current Hunting League rank and overall progress.
10. **Augment your gear.** Visit the Augment Moogle at GM Home (`!gmhome`) to add random stats to equipment. For passive endgame bonuses, earn enough Infamy to unlock the **Augment Sage** — Infamy comes from apex Reisenjima NMs, Scheduled Invasions, and the weekly Raid. The Sage applies permanent stat bonuses outside the normal augment RNG.
<!-- DOCGEN:END id="progression-order" -->

## Where retail content still matters

The Hunting League is the main game now, but retail content still has a role:

| Content | Why it's still worth doing |
|---|---|
| **Crafting** | <!--setting:SKILLUP_CHANCE_MULTIPLIER-->10<!--/setting-->× skill-up and <!--setting:CRAFT_HQ_CHANCE_MULTIPLIER-->10<!--/setting-->× HQ multipliers make it lucrative. Sell to fund consumables. |
| **ROE** | <!--setting:ROE_EXP_RATE-->10<!--/setting-->× ROE EXP, no weekly sparks cap. Quick way to add to your Hunt Marks income. |

## What's NOT here

- **Retail Hunt Registry** (the LSB NPC version in cities) is also in the world but isn't the primary system. It uses a different currency (scylds, capped at 1000) and pays out evoliths in retail — on this server it's secondary.
- **Limit Break / subjob / advanced job quests** — not needed, all unlocked at creation.
- **Fishing** — disabled server-wide.

## Tips

- **Bring a party for Rank IV–V.** Tier 4 NMs (Kirin, King Behemoth, Nidhogg) are doable solo with strong gear. Tier 5 — especially Shinryu — is a real raid boss.
- **Save marks.** Don't blow your first 150 on a Fotia Gorget if you haven't unlocked Rank III yet. Get the rank unlocks first; the gear stays available.
- **Tier-gating cuts both ways.** If you stand around in Escha ZiTah while someone else pops a higher-tier NM, you won't get credit unless you've unlocked that rank.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: b1445768da98 -->
_Last updated: 2026-06-20 21:09 UTC_
<!-- DOCGEN:END id="last-updated" -->
