# What's Custom

**Server name:** FJB Relaunch
**Tagline:** _Extreme QoL & Fast Progression_

This is a heavily-customized FFXI server. Beyond the settings tweaks (rates, caps, durations), it adds custom NPCs, hunt systems, gear pipelines, and background overrides that don't exist on retail. This page is the index — every custom system is listed here. Detail pages link out for the big content.

## Rates at a glance

<!-- DOCGEN:BEGIN id="rates-at-a-glance" -->
| | Multiplier | Notes |
|---|---:|---|
| **EXP** (scripted, FoV/GoV, ROE) | **10×** | All script-based EXP sources |
| **EXP** (mob kills) | **3×** | Base mob EXP |
| **Capacity Points** (scripted) | **10×** | Records of Eminence, etc. |
| **Capacity Points** (mob kills) | **3×** |  |
| **Sparks** | **10×** |  |
| **TABs** (FoV) | **10×** |  |
| **Mob drop rate** | **3×** |  |
| **Gil from mobs** | **10×** | Plus the **+N gil/mob level** bonus shown below |
| **Gil bonus per mob level** | **+1,000** | Flat bonus added to every mob kill |
| **Gil from quests** | **100×** |  |
| **Bayld from quests** | **2×** |  |
| **Fame gain** | **10×** |  |
| **Skill-up rate** | **10×** | All combat & magic skills |
| **Craft skill-up rate** | **10×** |  |
| **Craft HQ chance** | **10×** |  |
| **Player / Pet / Trust / Fellow TP gain** | **3×** |  |
| **NPC shop prices** | **2×** | Things cost more at vendors |
| **EXP loss on death** | **3×** | Death is costly — be careful |
<!-- DOCGEN:END id="rates-at-a-glance" -->

_If a stat maps to more than one underlying setting and they differ, both values are shown (e.g. `10× / 3×`)._

## New character bonuses

You start with way more than retail:

| Setting | This server | Retail |
|---|---|---|
| **Starting gil** | <!--setting:START_GIL:comma-->5,000,000<!--/setting--> | 10 |
| **Starting inventory & satchel** | <!--setting:START_INVENTORY-->80<!--/setting--> (max) | 30 |
| **All 8 Mog Wardrobes** | <!--setting:START_INVENTORY-->80<!--/setting--> slots each, at creation | 0 (must be quested individually) |
| **Starting level cap** | 99 | 50 (Limit Break required) |
| **Subjob unlocked at** | level 0 (immediate) | level 18 quest |
| **Advanced jobs unlocked at** | level 0 (immediate) | level 30 quest |
| **All maps** | granted at creation | earn over time |
| **Outpost warps** | all unlocked (including Tu'Lia and Tavnazia) | earn over time |
| **Opening cutscene** | skipped | shown |

## Combat & magic buffs

Magic and weapon skills hit harder; defensive spells last longer:

| Effect | This server | Retail |
|---|---:|---:|
| Cure power | <!--setting:CURE_POWER-->2<!--/setting-->× | 1× |
| Elemental magic damage | <!--setting:ELEMENTAL_POWER-->2<!--/setting-->× | 1× |
| Divine magic damage | <!--setting:DIVINE_POWER-->2<!--/setting-->× | 1× |
| Ninjutsu damage | <!--setting:NINJUTSU_POWER-->2<!--/setting-->× | 1× |
| Blue magic damage | <!--setting:BLUE_POWER-->2<!--/setting-->× | 1× |
| Dark magic drain | <!--setting:DARK_POWER-->2<!--/setting-->× | 1× |
| Weapon skill damage | <!--setting:WEAPON_SKILL_POWER-->2<!--/setting-->× | 1× |
| Item potency (potions/ethers) | <!--setting:ITEM_POWER-->2<!--/setting-->× | 1× |
| **Stoneskin HP cap** | <!--setting:STONESKIN_CAP:comma-->1,000<!--/setting--> | 350 |
| **Blink shadows** | <!--setting:BLINK_SHADOWS-->6<!--/setting--> | 2 |
| **Spike effects last** | <!--setting:SPIKE_EFFECT_DURATION-->1800<!--/setting-->s | 180s |
| **Elemental debuffs last** | <!--setting:ELEMENTAL_DEBUFF_DURATION-->1200<!--/setting-->s | 120s |
| **Aquaveil hits absorbed** | <!--setting:AQUAVEIL_COUNTER-->5<!--/setting--> | 1 |

## Movement

You move *fast*:

| | This server | Retail |
|---|---:|---:|
| Base run speed | <!--setting:BASE_SPEED-->100<!--/setting--> | 50 |
| Speed cap (with gear) | <!--setting:SPEED_LIMIT-->500<!--/setting--> | 80 |
| Mount speed | <!--setting:MOUNT_SPEED-->510<!--/setting--> | 80 |

## Subjob

**Subjob is full level**, not half. If your main is 99, your sub is 99 too. (Retail: sub is half main, so 99/49.)

**Subjob also levels itself.** While you grind your main, your subjob banks one-quarter (25%) of the EXP and levels up in the background, capped at main's current level. See [Subjob EXP Share](../progression/subjob-exp.md) for the full mechanic.

## Merits & currencies

Higher caps and unlimited spending:

| | This server | Retail |
|---|---:|---:|
| Max merit points held | <!--setting:MAX_MERIT_POINTS:comma-->127<!--/setting--> | 30 |
| Sparks cap | <!--setting:CAP_CURRENCY_SPARKS:comma-->999,999<!--/setting--> | 99,999 |
| Accolades cap | <!--setting:CAP_CURRENCY_ACCOLADES:comma-->999,999<!--/setting--> | 99,999 |
| Valor cap | <!--setting:CAP_CURRENCY_VALOR:comma-->500,000<!--/setting--> | 50,000 |
| Ballista crystals cap | <!--setting:CAP_CURRENCY_BALLISTA:comma-->20,000<!--/setting--> | 2,000 |
| Weekly sparks/accolades spending cap | **disabled** | 100,000/week |

## Dynamis

Built for grinding:

- **Cooldown between Dynamis runs:** <!--setting:BETWEEN_2DYNA_WAIT_TIME-->0<!--/setting-->h (retail: 24h).
- **Level minimum:** <!--setting:DYNA_LEVEL_MIN-->1<!--/setting--> (retail: 65).
- **Prismatic Hourglass cost:** <!--setting:PRISMATIC_HOURGLASS_COST:comma-->1<!--/setting--> gil (retail: 50,000).
- **Currency exchange rate:** <!--setting:CURRENCY_EXCHANGE_RATE-->10<!--/setting-->:1 (retail: 100:1) — cheaper to upgrade ancient currency.
- **100s → 1s exchange enabled.**
- **COP Dynamis** has no Chains of Promathia mission prerequisite (FREE_COP_DYNAMIS = <!--setting:FREE_COP_DYNAMIS-->1<!--/setting-->).

## Trusts

- **Custom Engagement** enabled — trusts behave more flexibly.
- **Alter Ego Extravaganza** event running (summer/NY trust acquisition discounts).
- **Alter Ego Expo** running (HPP / MPP / Status Resistance bonus).

## Quality-of-life settings

- **`@unstuck` self-rescue command** enabled (24h cooldown).
- **Unlimited AH listings** (retail: 7).
- **Equip from Mog Satchel / Sack / Case** allowed (requires a client addon).
- **Explorer Moogle teleports** available from level <!--setting:EXPLORER_MOOGLE_LV-->1<!--/setting--> (retail: 10).
- **Records of Eminence timed records** active.
- **Synergy crafting** enabled.
- **Login Campaign** active — daily rewards for logging in.
- **Daily tally / Gobbie Mystery Box** — <!--setting:DAILY_TALLY_AMOUNT-->50<!--/setting--> points/day (retail: 10), eligible after <!--setting:GOBBIE_BOX_MIN_AGE-->1<!--/setting--> day (retail: 45).
- **ENM key-item cooldown** — <!--setting:ENM_COOLDOWN-->0<!--/setting-->h (retail: 120h).
- **No regime level penalty** — REGIME_REWARD_THRESHOLD = <!--setting:REGIME_REWARD_THRESHOLD-->150<!--/setting--> (retail: 15).
- **EXP rings** — multiple ownership allowed, no one-per-week limit, up to **<!--setting:NUMBER_OF_DM_EARRINGS-->10<!--/setting--> Divine Might earrings**.
- **Homepoint teleport system** enabled.

---

# Custom NPCs and content

Beyond the settings tweaks above, the Relaunch server adds a stack of custom NPCs and hunt systems. The big ones each have their own page; the rest are summarized inline.

## Escha ZiTah hub

Three custom NPCs stand side-by-side at **Escha ZiTah** — the endgame zone that anchors the bulk of the server's progression loop.

| NPC | Position | What it does |
|---|---|---|
| **Hunt: Hub** | _see [Hunting League](../progression/index.md)_ | Shows rank & marks, unlocks ranks, reward shop |
| **Hunt: Spawner** | _see [Hunting League](../progression/index.md)_ | Pops current-rank NMs on demand |
| **Armor Vendor** | next to the Hunting League NPCs | Endgame armor for seals — see [Gear Vendors](../progression/gear-vendors.md) |
| **Weapons Vendor** | next to the Hunting League NPCs | Endgame weapons for seals — see [Gear Vendors](../progression/gear-vendors.md) |

- **Hunting League** is the rank-based NM hunting system that drives all progression. Five ranks, ~3 NMs per rank, mark currency, reward shop. → [Full details](../progression/index.md)
- **Armor Vendor** and **Weapons Vendor** sell tiered gear (Bronze / Silver / Gold) for the three seal currencies. → [Full catalogs](../progression/gear-vendors.md)

## Reforge System (Gwora Corridor)

Two NPCs at **Gwora Corridor** drive a parallel NM-farm-to-armor pipeline focused on **AF / Relic / Empyrean** armor.

| NPC | Position | What it does |
|---|---|---|
| **Reforge Spawner** | `(10.0, 0.0, 0.0)` | Pops one of three NM pools (Sky Gods / Unity NMs / Abyssea NMs) |
| **Reforge Vendor** | `(15.0, 0.0, 0.0)` | Upgrades base → +1 → +2 → +3 for marks |

Three currencies (AF Marks, Relic Marks, Empyrean Marks) track separately. Every kill drops a base piece **and** marks for its track. All 22 jobs supported. → [Full details](../progression/reforge.md)

## Custom service NPCs

The server's custom service NPCs are split across two hubs — **Leafallia** (endgame progression) and the **Celennia Memorial Library** (beginner services). The summary below auto-updates from the live source.

<!-- DOCGEN:BEGIN id="gm-home-npcs" -->
_All NPCs are in **GM Home** (zone 210). Positions shown as (x, y, z)._

**Progression cluster** — gear upgrades and augments (z ≈ −7)

| NPC | Position | What it does |
|---|---|---|
| **Gear Moogle** | _unknown_ | One-time starter gear kit for new characters (once per character) |
| **Mog Moogle** | _unknown_ | Delivery Box access plus change to any of the 22 jobs on the spot |
| **Augment Moogle** | `(-20, 0, -45)` | Trade one equipment piece + 1–4 catalyst crystals for stacking augments |
| **Augment Sage** | `(-16, 0, 10)` | Augment affinity system — unlock passive stat bonuses by spending hunt marks |

**Utility cluster** — one-time character setup (z ≈ −14)

| NPC | Position | What it does |
|---|---|---|
| **Character Upgrader** | _unknown_ | Menu-driven: grants all weapon skills, spells, trusts, capped skills, outpost warps |
| **Key Item Moogle** | _unknown_ | Grants all ~4,000 key items in one transaction (single-use, once per character) |
| **Mission Moogle** | _unknown_ | Skip every story mission in one click (all nations + RoZ/CoP/ToAU/WotG/SoA/RoV); sets nation rank 10 |

**Activities cluster** — ongoing gameplay systems (z ≈ −21)

| NPC | Position | What it does |
|---|---|---|
| **EXP Camp Moogle** | _unknown_ | Free warp to one of 20 level-matched EXP camps (Lv 10–99) |
| **Hunt Board** | `(-102, -2.1, -94)` | Weekly hunt board — pick up and turn in weekly NM target bounties for marks |
| **Infamy Vendor** | `(0, 0, 10)` | Spend infamy currency earned from Abyssea NM hunts, Invasions, and the weekly Raid on gear and rewards |

**Admin cluster** — testing and meta systems (z ≈ −28)

| NPC | Position | What it does |
|---|---|---|
| **Game Master** | `(-289.5, -3.5, 387.5)` | Wave-based fight challenge (Easy → Insane); earn hunt marks on full clear |
| **Test Dummy** | `(0, 0, -40)` | Interactive combat dummy for testing DPS and skill rotations |

**Commerce row** — gil sinks and convenience services (z ≈ −35)

| NPC | Position | What it does |
|---|---|---|
| **Warpman** | `(-114, -2.1, -88)` | Paid warp service to city hubs (San d'Oria, Bastok, Windurst, Jeuno, and more) |
| **Mystery Mog** | `(-114, -2.1, -94)` | Gacha box — spend hunt marks for a random pull from the reward table |
| **Title Broker** | `(-98, -2.1, -100)` | Buy cosmetic titles for gil; cheap flavor titles to rare endgame trophies |
| **Gil Exchange** | `(-106, -2.1, -100)` | Trade hunt marks for gil in bulk |
<!-- DOCGEN:END id="gm-home-npcs" -->

## Custom HNM system

the Relaunch server runs a **hybrid HNM pop system** that blends era-style timed rotation with retail-style QM pops:

- **NQ kings** (Fafnir, Behemoth, Aspidochelone, etc.) rotate on a timed window, persisting across server restarts.
- **HQ kings** (Nidhogg, King Behemoth, etc.) drop via QM placeholders.
- Respawn timers persist across restarts — crashes don't reset the clock.
- Each king's respawn window is tuned individually (e.g. Fafnir's is 21–24h).

## World-first announcements

The server broadcasts to everyone online when a milestone is first achieved:

- **First player death** (server-wide bragging rights)
- **First level-up to each level per job** (e.g. "First WAR to hit 75")
- **First NM kills** for tracked HNMs
- Winners are recorded permanently, so the title stays attributed even after restarts.

---

# Background systems

System-level modules that change behavior server-wide without adding NPCs. You probably won't notice them directly — but you'll notice their absence on a vanilla server.

| Module | What it changes |
|---|---|
| **Always-Popped NMs** | Every NM in Abyssea (all 10 zones), Escha (Zi'Tah + Ru'Aun), Reisenjima, and Reisenjima Sanctorium auto-spawns at server start and respawns **30 seconds** after death. No trade pop, no key item, no atmacite, no cruor — just walk in and fight. HNMs and wave bosses included. Escha ZiTah is excluded so the Hunting League's on-demand spawner can keep working. |
| **Unlimited Visitant (Abyssea)** | Every player gets permanent Visitant status the moment they zone into any Abyssea area. No timer, no eject to Searing Ward, no pearl/atma farming just to stay alive. Same mechanism retail uses for GMs, applied to everyone. |
| **Homepoint Heal** | Every homepoint visit restores full HP & MP. No more relying on a healer at the crystal. |
| **Persistent NM Time of Death** | NM respawn timers survive crashes and restarts. Currently tracks Behemoth (21–24h window), with more NMs addable. |
| **Disable Zone-In Cutscenes** | Suppresses every auto-cutscene that fires when you zone into an area with a mission/quest stage that would normally trigger one. Side effects (position resets, charvar updates, key item grants) still happen — only the cutscene playback is skipped. Talk to the NPC manually if you want to see it. |
| **Auto Unstick** | Server-side watchdog that clears stuck event state from any character on zone-in. If your character is wedged in a "still in cutscene" state, just zone (or log out and back in) and the watchdog releases you. Also defuses the Mog House 2F unlock cutscene loop that traps some characters. |
| **Conquest Regional NPCs Always Up** | Bastok, Windurst, and San d'Oria regional NPCs stay visible regardless of which nation owns conquest. No "come back next week" walls. |
| **Mission Wardrobe Unlocks** | Hitting mission milestones unlocks Mog Wardrobe slots. Currently: Zilart completion → Mog Wardrobe 3 unlocked. |
| **Max-Size Mog Wardrobes at Creation** | All 8 Mog Wardrobes are pre-sized to maximum capacity on character creation. By default, wardrobes 1-8 start at 0 slots until manually expanded; this skips that and gives every new character full storage from minute one. |
| **New Player Linkshell** | New characters automatically receive a designated server linkshell at character creation. |
| **Login Announcements** | Broadcasts a server-wide message when a player logs in, so the community knows when familiar names are online. |
| **First-99 Timestamp Tracker** | The first time any of a character's jobs hits level 99, the timestamp is stamped permanently into a charvar. Powers the "Fastest 1 → 99" leaderboard on the [Community](../community/leaderboards.md) page. Lock-once — re-leveling another job to 99 doesn't overwrite the stamp. |
| **Chocobo Raising QoL** | Faster chocobo growth (2 days to chick stage), higher endgame stat caps (riding speed 120, endurance), tuned for active raising. |
| **Wish Upon a Star Workaround** | Patches the Bastok "Wish Upon a Star" weather-gate quest that's otherwise impossible without a specific weather event. |
| **SoA Imprimatur Gate Removed** | Seekers of Adoulin missions no longer require Imprimatur key items or fame. Talk to the NPC, get the mission. |
| **Garrison Placeholder Data** | Supplies temporary NPC appearance data (looks, weapons) for Garrison content so it runs even without captured units. Organized by level cap × nation. |

---

## What's NOT changed

For reference, these are at retail defaults on this server:

- Mob HP / accuracy / damage multipliers
- Mob movement speed
- Auction House fee structure
- Enmity cap (30,000)
- Sneak/Invis/Deodorize durations
- Old cure formula / old magic damage (both off — uses modern formulas)
- Fishing is **disabled** (server-wide)

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: c398df8aed12 -->
_Last updated: 2026-06-28 05:28 UTC_
<!-- DOCGEN:END id="last-updated" -->
