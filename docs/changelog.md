# Server Changelog

Recent updates to Legendary, newest first — generated from our live deploy history.

---

!!! note "Week of June 15–21, 2026"
    **Thursday, June 18**

    - **PUP** — Automaton survives master death (retail behavior)
    - **Augments** — Apply the 5th augment slot on inventory load
    - **Items** — Grant Geomancy/Handbell skill on all-magic-skills gear
    - **Augments** — Reduce individual WS DMG+ cap 800%→200%
    - **Augments** — Cap Gilfinder augment at +4/slot (20 total max)
    - **Combat** — Uncap skillchain damage for PC attackers
    - **Trusts** — Replace Hunter's Prelude with double madrigal on Gemma
    - **Trusts** — Replace Gemma's Sentinel's Scherzo with Hunter's Prelude
    - **Combat** — Exclude the 8 Abyssea marks-pop zones from level correction
    - **Ascension** — Despawn trial NM on player KO
    - **Items** — Add missing mods for Spaekonas Gloves +4 (23988)
    - **Combat** — Use MESSAGE_SYSTEM_1 for over-cap damage notification
    - **SMN** — Boost avatar BP damage and fix gear-swap stat refresh
    - **Casino** — Close 30ms double-bet exploit at Lady Luck
    - **Commands** — Show pet level + stats for all 4 pet jobs (was PUP-only)
    - **Shop** — Add Eminent Sachet (21383) to !shop ammo

    **Wednesday, June 17**

    - **World NMs** — Drop Escha Ru'Aun from the auto-pop list (Reisenjima only)
    - **Abyssea** — Make ??? marks-pop + kill-reward clobber-proof (hook pattern)
    - **Blue Magic** — Disable Mortal Ray (spell 686) - cannot be cast
    - **Subjobs** — Level-0 sub jobs permanently stuck (EXP_TO_NEXT[0] was nil)
    - **Augments** — Refund staked items when the player cancels the augment menu
    - **Skillchain** — Record SC damage as int32 (int16 capped hits at 32,767)
    - **Sparks Exchange** — Shorten Eminence Broker main title (128-byte click cap)
    - **Abyssea** — Add Cruor reward on marks-popped NM kill
    - **Corsair** — Double-up always showed 0 because corsairActiveRoll was clobbered
    - **Commands** — Add !delnegdmg - purge items whose applied DMG augment netted negative
    - **Magic** — Uncap PC magic damage (remove base + MAB/MDB ratio ceilings)
    - **Infamy** — Add Daurdabla (string relic) to Infamy Vendor at 800 Inf
    - **Automerits** — Skip job-specific, Others, and Weaponskill merits
    - **Vendors** — Add BRD instruments to hunting league + infamy gear vendors
    - **Infamy Vendor** — Ryunohige -> i119 III final form (21858)
    - **Augments** — Force re-apply of EXP-bonus augment fix (augId 73 -> mod 382)
    - **Crash** — Comprehensive IsEntityAlive guard pass on CLuaBaseEntity
    - **Crash** — Extend IsEntityAlive guard to setHP (boss-command UAF)

    **Tuesday, June 16**

    - **Augments** — Remove 6 Dmg (melee/ranged) augments from pool
    - **Infamy** — Restore Infamy Vendor as standalone module
    - **Augments** — Add Thunder Affinity augment (augId 2040)
    - **Abyssea** — Grant permanent visitant on onZoneIn so !abyssea warps work
    - **Magic** — Uncap magic damage for PC casters (mirrors WS uncap)
    - **Abyssea** — !visitant no longer ejects the player from Abyssea
    - **Abyssea** — Add !visitant command to grant permanent visitant status
    - **Crash** — Extend IsEntityAlive guard to setLocalVar/getLocalVar(s)
    - **Hunting League** — Make full Augment Sage rank chain obtainable in Escha
    - **Crash** — Alive-entity registry + trust null-spell guard
    - **Abyssea** — Wire ??? markers to AbysseaMarks gil/infamy pop menu
    - **Vendors** — Consolidate Accessory NPC to Escha-ZiTah gear row
    - **Crash** — Gate treasure re-show on trading player still in zone
    - **Crash** — Guard invalid spell IDs in CastMagic packet + drop dungeon recap
    - **Marks** — Add Infamy balance to !marks output
    - **Gemma** — Increase MACC 600→6000 to land enfeebles on Abyssea NMs
    - **Abyssea** — Correct onGameIn override path in AbysseaKICleanup
    - **Abyssea** — Reduce NM atkDef/accEva by 1/3 across all tiers
    - **Abyssea** — Suppress trade-to-pop ??? interaction silently
    - **Dungeons** — Remove custom dungeon system entirely
    - **Abyssea** — Reward all party members on marks-pop NM kill
    - **Abyssea** — One-shot cleanup of retail pop key items
    - **Abyssea** — Raise infamy rewards to match vendor costs
    - **Abyssea** — Remove Empyreal Paradox from marks-pop system
    - **Abyssea** — Reduce marks-pop NM HP by 1/3
    - **Abyssea** — Raise Visions base infamy to 2 so multipliers show
    - **Abyssea** — Increase marks-pop NM gil reward 5x
    - **Abyssea** — Release player from ??? lock before customMenu
    - **Subjobs** — Restore true 50%-of-main sub leveling (curve was 2-4x too steep)
    - **Abyssea** — Boost marks-pop NM difficulty x30
    - **Abyssea** — Zone-tiered difficulty — full-party NM stats
    - **Abyssea** — Remove Abyssea from always_popped_nms
    - **Abyssea** — Guard nil getCharVar + pcall-protect marks pop path
    - **CMD** — Split !abyssea into two-tier menu (client 8-option cap)
    - **CMD** — Add !abyssea warp command for all 10 Abyssea zones
    - **Abyssea** — Add Gil reward + party/trust multipliers to marks pop
    - **Abyssea** — Add Hunt Marks pop system + Infamy kill reward
    - Dungeon double-warp fix, Outer Bastion WP fix, Sortie rings, item fixes
    - **Capacity Farm** — Refresh campZone from deadMob to survive FileWatcher reloads
    - **Shop** — Add Angon and Throwing Tomahawk to !shop ammo
    - *…and 61 more changes this update*

    **Monday, June 15**

    - **Dungeons** — Dismiss trusts before zone warp to prevent heap crash
    - **Bullet Pouches** — Make the 4 Bullet Pouches equippable WAIST pieces
    - **RNG** — Register Hover Shot ability (abilityId 971)
    - **SCH** — Helix Detonation — all nuke tiers eligible, tiered flat bonus
    - **SCH** — Helix Detonation combo — same-element Tier V/VI nuke within 10s
    - **Difficulty** — Hunting League NMs +50% (everything, DEF gentler)
    - **Hunting League** — Migrate from Reisenjima Henge to Escha Zi'Tah
    - **Dungeons** — Defer boss spawn until all trash/NMs are cleared
    - **Difficulty** — Dungeon mobs +50% to all combat stats (not just HP)
    - **Ascension** — Bake +50% into stat blocks, revert tier mult (it broadcast Empowered)
    - **Weaponskills** — Land true (over-cap) WS damage on mob HP, clamp only the packet
    - **Difficulty** — +50% Ascension trials and dungeon mobs
    - **Capacity Farm** — Respawn phantoms synchronously + cap-safe density
    - **APEX** — 30s respawn for all apex mobs server-wide
    - **Ascension** — Disable the Ascension companion system (no more lynx familiars)
    - **Trustattack** — Engage the trusts directly, not just the master
    - **Endgame** — Prime Armory wired to all 4 trials (remove voucher system)
    - **Endgame** — Job Mastery Challenges — 12 Weapon Guardians (Prime Weapon Trial 4)
    - **Trustattack** — Auto-engage the caller on their cursor target
    - **Trustattack** — Trusts fight the target without the master engaging
    - **Augments** — Remove the High-Quality Scorpion Shell catalyst + its WSD augment
    - **Endgame** — Endless Tower — 50-floor solo gauntlet (Prime Weapon Trial 2)
    - **Endgame** — Nightmare tier for all 8 dungeons (Prime Weapon Trial 1)
    - **Invasion** — Halve Al Zahbi rewards again (~12.5% of launch)
    - **Invasion** — Cut Al Zahbi invasion rewards 75%
    - **Endgame** — Weekly World Boss system (Hall of the Gods, 8-boss rotation)
    - **Gear** — PET scoring role so SMN pet gear isn't mis-scored as a nuker, + SMN sachets
    - **Dungeons** — Per-dungeon re-entry cooldown (anti-farm + anti-spam)
    - **Capacity Points** — Schedule phantom respawn on the killer, not the dying mob
    - **Prestige** — Repool Provenance tiers 1-4 to FRESH avatar models
    - **Dungeons** — Compress infamy rewards for long-term endgame grind
    - **Prestige** — Repool tiers 1-4 to Provenance-safe models (were invisible)
    - **Dungeons** — Cut infamy rewards by 2/3 across all 8 dungeons
    - **Dungeons** — Defer mob despawn on zone-exit abort to avoid destructor crash
    - **Dungeons** — Cap mob engine level at 255 (uint8 overflow = insta-clear exploit)
    - **Capacity Points** — Max density 357 phantoms + 2s respawn timer
    - **Capacity Points** — Wipe Bibiki Bay native pop, keep 6 scripted NMs
    - **Expcamp** — Extend the GM Home EXP-camp Moogle through Lv99
    - **Capacity Farm** — Populate the whole Bibiki Bay zone with CP mobs
    - **Warpman** — Add Bibiki Bay (Capacity Farm) to the gil-warp NPC
    - *…and 3 more changes this update*

??? note "Week of June 8–14, 2026"
    **Sunday, June 14**

    - **PUP** — Bump automaton damage multiplier 12x -> 20x
    - **Shop** — Real infinite-ammo bullet pouches in !shop ammo
    - **PUP** — ~12x automaton outgoing physical-damage multiplier vs custom NMs
    - **Shop** — Add endgame arrows + Devastating Bullet to !shop ammo
    - **Capacity Points** — Shared CP farm camp in Bibiki Bay (!capacity)
    - **Shop** — Add Chrono/Living/Eradicating Bullets to !shop ammo
    - **Hunt+Reforge** — Silent +20% on all Hunting League & Reforge NMs
    - **Augments** — Wire up Fafnir's Scale + Kirin's Mane trophy drops
    - **Augments** — King Arthro drops its affinity trophy (Emperor Arthro's Shell)
    - **Ascension** — Bake the +20% into boss stat blocks (silent)
    - **Ascension** — +20% difficulty on all Ascension trial NMs
    - **Infamy** — Infamy Vendor uses the native shop window (icons + stat tooltips)
    - **Shop** — Let the native shop charge a CharVar currency (setShopCurrencyVar)
    - **Dungeons** — Defer abort teardown out of onZoneIn (re-entrant setPos crash)
    - **Invasion** — !iwarp drops players on the spawn plaza (synced to catalog)
    - **Invasion** — Point players to !iwarp in the warning + start broadcasts
    - **Invasion** — Announcements said GM Home, battleground is Al Zahbi
    - **Jobpoints** — Enable Capacity Points on single-target NMs (Reforge/HL/Prestige)
    - **AH** — Raise buyback cap 50->200, run cron every 2h
    - **Progression** — Auto-grant LIMIT_BREAKER + JOB_BREAKER so merit/JP menus aren't greyed
    - **Infamy** — Finish Aeonic Anguta weapon + add to Infamy Vendor
    - **Ascension** — Opt Jbae out of the shadow-companion familiar
    - **Infamy** — Finish Aeonic Trishula weapon + add to Infamy Vendor
    - **Reforge** — Keep !reforged spawn menu under 150-byte wire cap (Hadhayosh unspawnable)
    - **DEV** — Add local test server workflow
    - **Alzahbi** — Loot fountain - every kill drops a random DB item
    - **Invasion** — Enable trusts + mounts in Al Zahbi (zone misc 5784->7838)
    - **Zone Entities** — Clear entity enmity before freeing in releaseIdOnDisappear path
    - **Reforge** — Move Reforge Exchange NPC from !hunt to !reforged
    - **Crash** — Guard cure-enmity against dangling notoriety pointers (SIGQUIT)
    - **Hunt Vendor** — Re-add Malignance Boots to Gold feet (pin in scorer)
    - **Shop** — Remove the Gobbie Dial Keys !shop that shadowed the main shop
    - **Iwarp** — Move warp point 70y north of spawn anchor (Gajaad coords)
    - **Invasion** — Set warp + spawn anchor to confirmed coords (42.4,0,46.4)
    - **Invasion** — Use real Al Zahbi ground coords (-35,-1,-31)
    - **Iwarp** — Use setPos instead of teleport for cross-zone warp
    - **Invasion** — Update error message from 'GM Home' to 'Al Zahbi (zone 48)'
    - **Invasion** — Expand to 5 waves, add all unused mob groups
    - **Invasion** — Fixed spawn anchor at Al Zahbi center (0, 0, 36)
    - **Invasion** — Add !iwarp command - warps player to Al Zahbi invasion zone
    - *…and 31 more changes this update*

    **Saturday, June 13**

    - **Retire Laptop Publish** — Deploy-everything now publishes the site FROM THE BOX
    - **Docs Deploy** — Add git pull to Azure cron so docs auto-update
    - **Login Streak** — Boost milestone bonuses 30x
    - **Docs Deploy** — Venv + token-file + cron-safe PATH in refresh_site_azure
    - **Wavemaster** — Award completionBonus to all party members
    - **Branding** — Replace repo logo with the Legendary dragon emblem
    - **Trusts** — Repair Void Keeper menu (quote-in-label) + add !givetrust
    - **Prime Weapons** — 1% Prime Voucher drop from any Hunting League NM
    - **Weapon Skills** — Enable the other 5 Prime weapon types (GA/Scythe/Polearm/Bow/Gun)
    - **Trusts** — Give Corvus a hard hitter -- Apex Arrow at 1000 TP
    - **Gmhome** — Paginate Cross-Job Ability Trainer menu (un-hide Ninja + How-it-works)
    - **Prime Weapons** — Reusable Prime Voucher reward helper (source-agnostic)
    - **Ascension** — Show master stars + menacing title for ascended players
    - **Trusts** — Make Corvus actually hit hard (give his empty bow real DMG)
    - **Prime Weapons** — Add !primevoucher GM command to grant the bound voucher
    - **Weapon Skills** — Enable 6 more Prime weapon skills + voucher-gated Prime Armory
    - **Trusts** — Corvus look -> Elvaan Male ranger (LotR elf) with a longbow
    - **Gmhome** — Add Cross-Job Trait Trainer (6 borrowed job traits)
    - **Trusts** — Add Corvus, a ranged-DPS custom trust on the Curilla (902) slot
    - **Onboarding** — Linkpearl ask in login Quick Tips bar
    - **AURA** — Add !aura sweep <mode> <start> <end> to audition effect ranges
    - **Gmhome** — Sparks Exchange rate 50->10 gil/spark
    - **Weapon Skills** — Implement Maru Kala (231) as a player weapon skill
    - **Gmhome** — Add Sparks Exchange (sparks->gil) + fix Casino position collision
    - **QOL** — !trustattack -- send your trusts at your target before you engage
    - **Shop** — Add Chocobo Shirt + Destrier Beret to !shop armor
    - **Gmhome** — Add the Lady Luck casino (slots, high-low, roulette, dice)
    - **Seal Drops** — Cumulative quantity roll (X% = drop N-or-more)
    - **Seal Drops** — Guaranteed escalating quantity per mob
    - **Launch** — RaidBoss + Reforge NPC + Impetus bugs; add mob seal drops
    - **Invasion** — Increase + enrich GM Home defense rewards
    - **Gmhome** — Unlocker NPC can unlock all automaton parts (PUP)
    - **Magic** — Expose custom spells as !aegis/!convergence/!silencega
    - **Hunting League** — Price the Armor NPC [TEST] preview shop at 100M gil (was ~12)
    - **Prestige** — Make Raja (Voidfang) silenceable
    - **Hunting League** — Bump Simurgh difficulty a notch (T3)
    - **Weapons Vendor** — Cap Prime/Su5/Ambuscade ranged, spread across tiers, drop ammo
    - **Weapons Vendor** — Add capped ranged weapons (archery + marksmanship)
    - **Trusts** — Block the retail San d'Oria Excenmille NPC from granting Meat (899)
    - **Trusts** — Exclude Meat (899) from the grant-all NPC + !addalltrusts
    - *…and 47 more changes this update*

    **Friday, June 12**

    - **OPS** — NPC declutter -- safety-filtered set + deliberate one-shot apply
    - **Prestige** — Cosmetic Ascension aura for ascended players
    - **Augments** — Restore Exp./Cap. Point catalysts durably via generator
    - **JOBS** — Auto-unlock RUN + GEO for all players in the Mog House menu
    - ﻿feat(ops): NPC declutter -- status-0 filter + both-bucket SQL
    - **Gm Home** — Cluster the 3 teleport NPCs on the east side
    - **Linkshell** — Global Legendary server linkshell for all players
    - **OPS** — Searchable HTML view for the NPC disable audit
    - ﻿feat(ops): NPC disable audit -- per-zone "extra NPC" review list
    - **Modules** — Gate login hooks on gameLogin, not `not zoning`
    - **Missions** — Skip the SoA/RoV mission tails too
    - **NPC** — Set customMenu send delay to 30ms (was 50, briefly 15)
    - **NPC** — Lower customMenu send delay 50ms -> 15ms (all NPCs)
    - **Missions** — Actually skip CoP in the Mission Moogle
    - ﻿feat(augments): wire up an Enspell Damage catalyst (Wamoura Scale)
    - ﻿feat(ops): achievements feed for the Discord watcher (second webhook)
    - ﻿feat(ops): Discord join watcher for the public launch
    - Feat(jobs)!: retire the Bouncer, restore retail Geomancer on slot 21
    - **Commands** — Remove dev notes from player command !help text
    - ﻿fix(world): stop the ZMQ router busy-spin pinning a core at 100%
    - ﻿fix(mounts): honor MOUNT_SPEED above 255 and clamp the mount branch
    - ﻿feat(mystats): Ascension section -- every Provenance AP category
    - **Concurrency** — Public-launch hardening - menu race + dungeon occupancy
    - **League** — Reisenjima_Henge zoneId is 292, not 291
    - **Derby** — Chocobo Derby - simulated racing with betting + raised birds
    - **Treasure** — Treasure maps, overworld digs, buried strongboxes
    - **League** — Provisioners' League - the non-combat fishing/crafting league
    - **Prestige** — Spawn Trial bosses on a ring at the summoner, on the floor
    - **RAID** — The Star-Devourer - weekly multi-phase raid boss
    - **Invasion** — Scheduled Voidsent assaults on GM Home
    - **Colosseum** — Async ranked PvP vs AI replicas of real champions
    - **Prestige** — Spawn Trial bosses at the summoner, not a fixed off-map point
    - **Dungeons** — Mythic+ keystones - endless key levels above Mythic
    - ﻿Retire the new-player linkshell; dedupe the Dungeon Veteran title
    - ﻿docs-in-code: catch comments up to the 5-catalyst reality

    **Wednesday, June 10**

    - **Augments** — Allow up to 5 catalysts/trade (the engine's 5 augment slots)
    - **Augments** — Back to one augment line per catalyst (4-line stacking)
    - **Augments** — Split value budget rank 0-24 / stack 0-7 (owner choice)

    **Tuesday, June 9**

    - **Augments** — Confirm menu fits stacked trades + proper N-times scaling
    - **Dangruf Wadi** — Nil-guard weather handler to stop intermittent startup crash
    - **Augments** — Stop catalyst stacking from eating gear; amplify via value field
    - Re-tune haste augments to a sane ~1%->25% curve + normalize their display
    - Normalize stored-xN augment mods in the displays (disp divisor)

    **Monday, June 8**

    - **Escha** — Remove Warder of Temperance spawn from the GM-wave area
    - **Items** — Make all edible foods stack to 99 (Magma Steak etc. shipped at stackSize 1)
    - **Shop** — Add top attack foods to !shop food (Magma/Behemoth/Charred Salisbury Steak)
    - **Combat** — Exempt Provenance from level correction (hosts lv150 Prestige bosses)
    - Permanently exclude the 19 Judge items from all three gear scorers
    - **Gear** — WS Set Builder fixes — grips, Fotia, WSD rings, Knobkierrie; remove Judge's
    - Reforge tier carry-forward + all-source mod reads + ascension perks
    - **Gear** — Commit reforge tier stat/model fills + audit tooling
    - **Combat** — Raise magic/spell damage cap 99,999 -> 131,071
    - **Combat** — Raise damage cap 99,999 -> 131,071 (FFXIAH client packet max)
    - **Infamy** — Remove phantom 'Knobkierrie' vendor entry (id 26072 doesn't exist)

??? note "Week of June 1–7, 2026"
    **Saturday, June 6**

    - Sync server catalogs to published website + harden deploy button
    - **Voidspire** — Correct invalid mod names so the catalog loads on live
    - **Dungeons** — Remove all movement boundaries (gates + OOB warp)
    - **Crossjob** — Auto-create char_cross_job_abilities via zz_ reload
    - **Crossjob** — Cross-Job Ability Trainer at GM Home
    - **Gmhome** — Home Point crystal warps to any homepoint, free
    - **Infamy** — Grouped vendor browser + relic/endgame listings
    - **Infamy** — Generator for the vendor item type-map (grouped browser)
    - **Infamy** — Stat blocks for relic 119 III + endgame gear
    - Stat naked dungeon-shop gear + make DB-only tier mods rebuild-safe
    - Add !reallevel command (effective level past 99)
    - Raise BRD max songs and COR max phantom rolls to 6
    - Help/marks/streak/tier/week/events/top/announce/setbonus/reforge commands, death penalty, weekly recap, Infamy milestones, tier promotion broadcast
    - Party bonus, kill streak, who/profile/nms/time/shutdown commands, login bonuses, auto-buff, achievement titles, leaderboard NPC, weekly dungeon bonus
    - [dungeon] Add weekly bonus dungeon system (2x Infamy on clear)
    - Featured/achievements/optin/optout commands, seasonal events, progress drill-down, Discord achievements
    - Enable HNM Kings system + add lower-tier HNMs
    - New player experience, first-kill bonuses, weekly events, achievements
    - Move Wave Master NPC from GM_Home to Balga's Dais (zone 146)
    - Daily Board, 4th dungeon, !lfg, !progress, !gainexp cooldown
    - Add Curated Sets vendor category to Infamy Vendor
    - Infamy Vendor menus exceed 150-byte customMenu cap, silently dropping Buy

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 73f753321468 -->
_Last updated: 2026-06-19 16:09 UTC_
<!-- DOCGEN:END id="last-updated" -->
