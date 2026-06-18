# Server Changelog

Recent changes to Legendary. Updated automatically from our development history.

---

!!! note "Wednesday · June 17, 2026"
    - feat(docgen): recover the docs toolchain into the main tree (from fjb/main)
    - feat(shop): add Eminent Sachet (21383) to !shop ammo
    - fix(deploy): repair the SITE_BAT re-score step after the worktree was deleted
    - feat(deploy): add deploy-rebuild.bat â€” ship + rebuild + SQL + restart
    - Deploy Everything Wed 06/17/2026 17:38:36.90
    - feat(always-popped-nms): drop Escha Ru'Aun from the auto-pop list (Reisenjima only)
    - fix(deploy): fix broken SITE_BAT path (worktree busy-johnson deleted)
    - fix(deploy): exclude scripts/specs from live sync tarballs
    - fix(game-master): guard onMobDeath against non-PC killers, add per-diff stagger
    - fix(abyssea): make ??? marks-pop + kill-reward clobber-proof (hook pattern)
    - feat(blue-magic): disable Mortal Ray (spell 686) - cannot be cast
    - fix(subjob): level-0 sub jobs permanently stuck (EXP_TO_NEXT[0] was nil)
    - feat(deploy): list changed files in the Deploy Everything auto-commit body
    - chore(augment): remove 6 negative-DMG augment entries (743-745 melee, 749-751 ranged)
    - fix(augment): refund staked items when the player cancels the augment menu
    - fix(skillchain): record SC damage as int32 (int16 capped hits at 32,767)
    - fix(sparks-exchange): shorten Eminence Broker main title (128-byte click cap)
    - feat(abyssea): add Cruor reward on marks-popped NM kill
    - feat(tools): negative-DMG augment DB scan + strip
    - fix(corsair): double-up always showed 0 because corsairActiveRoll was clobbered
    - feat(commands): add !delnegdmg - purge items whose applied DMG augment netted negative
    - feat(magic): uncap PC magic damage (remove base + MAB/MDB ratio ceilings)
    - feat(infamy): add Daurdabla (string relic) to Infamy Vendor at 800 Inf
    - fix(automerits): skip job-specific, Others, and Weaponskill merits
    - feat(vendors): add BRD instruments to hunting league + infamy gear vendors
    - fix(infamy-vendor): Ryunohige -> i119 III final form (21858)
    - Deploy Everything Wed 06/17/2026 10:57:15.56
    - fix(augment): force re-apply of EXP-bonus augment fix (augId 73 -> mod 382)
    - fix(crash): comprehensive IsEntityAlive guard pass on CLuaBaseEntity
    - fix(crash): extend IsEntityAlive guard to setHP (boss-command UAF)

??? note "Tuesday · June 16, 2026"
    - fix(deploy): SQL upload past xi:xi perms + live C++ build-progress window
    - Deploy Everything Tue 06/16/2026 23:03:02.01
    - feat(deploy): azure-rebuild.bat now applies changed SQL before restart
    - feat(deploy): add azure-rebuild.bat - box-only recompile, no laptop files
    - feat(deploy): verify core LSB patches survived before every rebuild/ship
    - feat(augments): remove 6 Dmg (melee/ranged) augments from pool
    - feat(infamy): restore Infamy Vendor as standalone module
    - feat(augments): add Thunder Affinity augment (augId 2040)
    - fix(abyssea): grant permanent visitant on onZoneIn so !abyssea warps work
    - feat(magic): uncap magic damage for PC casters (mirrors WS uncap)
    - fix(abyssea): !visitant no longer ejects the player from Abyssea
    - feat(abyssea): add !visitant command to grant permanent visitant status
    - chore(deploy): retire legacy deploy-to-azure (SQL-only) to _legacy/
    - fix(crash): extend IsEntityAlive guard to setLocalVar/getLocalVar(s)
    - feat(hunting-league): make full Augment Sage rank chain obtainable in Escha
    - fix(crash): alive-entity registry + trust null-spell guard
    - feat(abyssea): wire ??? markers to AbysseaMarks gil/infamy pop menu
    - feat(vendors): consolidate Accessory NPC to Escha-ZiTah gear row
    - fix(crash): gate treasure re-show on trading player still in zone
    - fix(crash): guard invalid spell IDs in CastMagic packet + drop dungeon recap
    - fix(deploy): remove intermediate map restart in step 3
    - fix(deploy): non-git fallback in _apply_changed_sql.sh + restore zz_*.sql SCP
    - Deploy Everything Tue 06/16/2026 15:54:16.59
    - fix(docs): box cron now regenerates augment catalog before publishing
    - feat(deploy): git-diff-based SQL apply covers all layers
    - feat(marks): add Infamy balance to !marks output
    - balance(gemma): increase MACC 600â†’6000 to land enfeebles on Abyssea NMs
    - fix(abyssea): correct onGameIn override path in AbysseaKICleanup
    - balance(abyssea): reduce NM atkDef/accEva by 1/3 across all tiers
    - chore: delete temporary gmboot.lua bootstrap command
    - fix(abyssea): suppress trade-to-pop ??? interaction silently
    - feat(dungeon): remove custom dungeon system entirely
    - feat(abyssea): reward all party members on marks-pop NM kill
    - feat(abyssea): one-shot cleanup of retail pop key items
    - balance(abyssea): raise infamy rewards to match vendor costs
    - feat(abyssea): remove Empyreal Paradox from marks-pop system
    - balance(abyssea): reduce marks-pop NM HP by 1/3
    - fix(abyssea): raise Visions base infamy to 2 so multipliers show
    - feat(abyssea): increase marks-pop NM gil reward 5x
    - fix(abyssea): release player from ??? lock before customMenu
    - fix(subjob): restore true 50%-of-main sub leveling (curve was 2-4x too steep)
    - feat(abyssea): boost marks-pop NM difficulty x30
    - feat(abyssea): zone-tiered difficulty â€” full-party NM stats
    - feat(abyssea): remove Abyssea from always_popped_nms
    - fix(abyssea): guard nil getCharVar + pcall-protect marks pop path
    - fix(cmd): split !abyssea into two-tier menu (client 8-option cap)
    - feat(cmd): add !abyssea warp command for all 10 Abyssea zones
    - feat(abyssea): add Gil reward + party/trust multipliers to marks pop
    - feat(abyssea): add Hunt Marks pop system + Infamy kill reward
    - feat: dungeon double-warp fix, Outer Bastion WP fix, Sortie rings, item fixes
    - fix(capacity_farm): refresh campZone from deadMob to survive FileWatcher reloads
    - feat(shop): add Angon and Throwing Tomahawk to !shop ammo
    - fix(dungeon): fix !dungeon abort reaching live session table
    - feat(cmd): add !dungeon abort command
    - fix(dungeon): clamp mob scatter positions to navmesh
    - feat(cmd): add !henge warp command to Reisenjima Henge
    - feat(deploy): add sync-lua-to-azure.bat for no-restart content push
    - fix(dungeon): guard getZone() nil deref in mob-count PAI loop
    - fix(prestige): guard idle-watcher against freed mob entity after zone exit
    - fix(brd): add missing scroll script for Aria of Passion
    - fix(ranger): replace broken hover_shot JA with !hovershot command
    - feat(prestige): idle-despawn trial boss after 20s of no damage
    - feat(world-boss): move spawn zone from Hall of the Gods to West Ronfaure
    - revert(endless-tower): disallow Trusts in Walk of Echoes (zone 182)
    - fix(job-mastery): use owner-verified Mastery warp coords (-519,36,236)
    - fix(job-mastery): correct Weapon Mastery warp-in (was off-map)
    - fix(leaderboard): record pre-cap WS damage for peak hit tracker
    - feat(endless-tower): hard-cap trusts at 1 (was honor-system)
    - fix(endless-tower): allow trusts in Walk of Echoes (zone 182)
    - fix(hunting-league): idempotent mob_groups in escha migration (zone 288)

??? note "Monday · June 15, 2026"
    - Deploy (No Rebuild) Mon 06/15/2026 23:59:36.23
    - fix(deploy): remove parens from log header in deploy-no-rebuild.bat
    - fix(deploy): convert bat files from LF to CRLF (Windows CMD requires CRLF)
    - fix(capacity_farm): use DE_ prefix in queryEntitiesByName so mobs respawn
    - docs(core): mark the sub-job gear-equip patch in EquipArmor
    - feat(vendor): add Gold-tier axes to Hunting League gear vendor
    - feat(dungeon): scaled gil reward on clear (1M easiest -> 10M hardest)
    - feat(dungeon): theme all 8 dungeons to distinct mob families
    - fix(trust): Meat now forces mob target-switch on every hate-pin tick
    - fix(crash): guard treasure.lua timers against freed NPC entity
    - fix(dungeon): paginate the Dungeon Master menu (8 dungeons overflowed)
    - feat(cmd): show (X,Y,Z) world coords in !mobs listing
    - chore(cmd): open !mobs to permission 0 (all players)
    - feat(npc): add Unity Accolades exchange to Eminence Broker
    - feat(hl): increase affinity trophy drop quantity from 1 to 5
    - feat(hl): Nidhogg also drops Fafnir's Scale (Augment Sage rank 4 trophy)
    - feat(shop): split augments ws into ws/ws2 to stay under client 80-item cap
    - fix(shop): sort !shop augments by sortname to match client display
    - feat(shop): sort !shop augments by actual item name from item_basic
    - fix(augment): rename HQ Scorpion Shell label to sort first in !shop augments ws
    - feat(shop): make !shop augments live-reload via module command override
    - fix(dungeon): switch Maxixi +4 drops to first (Hume F/Taru F) race variant
    - feat(shop): sort augment catalysts alphabetically by label
    - fix(shop): force-reload augment_catalog on shop hot-reload
    - feat(reallevel): auto-populate the leaderboard via a login hook
    - feat(augment): add 10 missing magic/instrument skill catalysts
    - feat(ws): boost Asuran Fists fTP to 1.5/1.75/2.0 per hit
    - feat(ws): add per-hit crit chance to Asuran Fists
    - feat(reallevel): store Real Level in a CharVar for the website leaderboard
    - feat(hl): add Augment Sage affinity trophy drops to all 13 HL NMs
    - feat(hl): guaranteed Khimaira Horn drop from Pandemonium Warden
    - feat(tracker): WSMaxDmg charVar - record peak weapon skill damage per player
    - feat(augment): full weapon skill coverage in augment catalog
    - feat(cmd): GM Ascension Trial tools - spawntrialboss / killtrial / cleartrial
    - feat(prime): enable Great Sword (Fimbulvetr) + Axe (Blitz) Prime WS + aftermath
    - feat(cmd): !fixboss - GM teleport any mob to player position
    - feat(prime): wire Prime aftermath onto the Prime Dagger too
    - feat(prime): implement faithful Prime Weapon Aftermath
    - feat(cmd): !spawntrialboss - GM force-spawn Ascension Trial boss in Provenance
    - feat(brd): add Aria of Passion + Honor March songs
    - fix(dungeon): self-heal boss spawn when zone is genuinely clear
    - feat(cmd): !mobs - list live mobs in your zone (GM debug)
    - revert(augment): restore HQ Scorpion Shell -> Weapon skill damage catalyst
    - tune(ah): raise universal buyback cap 200 -> 1000 per pass
    - feat(tools): AH bot status + transaction-history check
    - fix(dungeon): correct voidwalker_arena bossPos Y from 7.263 to 12.000
    - feat(brd): implement Honor March (spell 417) as tier-3 BRD march
    - fix(hunting-league): scope Escha migration mob_spawn_points delete by zone
    - fix(rng): correct hover_shot to retail abilityId 289, recastId 55
    - chore(hunt): temporarily restrict !hunt to GM (permission 0 -> 1)
    - Deploy Everything Mon 06/15/2026 13:00:01.89
    - fix(dungeon): dismiss trusts before zone warp to prevent heap crash
    - fix(bullet-pouches): make the 4 Bullet Pouches equippable WAIST pieces
    - feat(rng): register Hover Shot ability (abilityId 971)
    - balance(SCH): Helix Detonation â€” all nuke tiers eligible, tiered flat bonus
    - feat(SCH): Helix Detonation combo â€” same-element Tier V/VI nuke within 10s
    - feat(gm): !grantpearls command + offline SQL
    - balance(difficulty): Hunting League NMs +50% (everything, DEF gentler)
    - feat(hunting-league): migrate from Reisenjima Henge to Escha Zi'Tah
    - feat(dungeon): defer boss spawn until all trash/NMs are cleared
    - balance(difficulty): dungeon mobs +50% to all combat stats (not just HP)
    - fix(ascension): bake +50% into stat blocks, revert tier mult (it broadcast Empowered)
    - feat(weaponskills): land true (over-cap) WS damage on mob HP, clamp only the packet
    - balance(difficulty): +50% Ascension trials and dungeon mobs
    - style(gm_home): uniform NPC grid (centered rows, even spacing)
    - fix(capacity-farm): respawn phantoms synchronously + cap-safe density
    - feat(apex): 30s respawn for all apex mobs server-wide
    - feat(ascension): disable the Ascension companion system (no more lynx familiars)

??? note "Sunday · June 14, 2026"
    - fix(trustattack): engage the trusts directly, not just the master
    - feat(endgame): Prime Armory wired to all 4 trials (remove voucher system)
    - feat(endgame): Job Mastery Challenges â€” 12 Weapon Guardians (Prime Weapon Trial 4)
    - feat(trustattack): auto-engage the caller on their cursor target
    - fix(trustattack): trusts fight the target without the master engaging
    - fix(augment): remove the High-Quality Scorpion Shell catalyst + its WSD augment
    - feat(endgame): Endless Tower â€” 50-floor solo gauntlet (Prime Weapon Trial 2)
    - feat(endgame): Nightmare tier for all 8 dungeons (Prime Weapon Trial 1)
    - balance(invasion): halve Al Zahbi rewards again (~12.5% of launch)
    - balance(invasion): cut Al Zahbi invasion rewards 75%
    - feat(endgame): Weekly World Boss system (Hall of the Gods, 8-boss rotation)
    - feat(gear): PET scoring role so SMN pet gear isn't mis-scored as a nuker, + SMN sachets
    - feat(dungeon): per-dungeon re-entry cooldown (anti-farm + anti-spam)
    - fix(capacity): schedule phantom respawn on the killer, not the dying mob
    - fix(prestige): repool Provenance tiers 1-4 to FRESH avatar models
    - balance(dungeon): compress infamy rewards for long-term endgame grind
    - fix(prestige): repool tiers 1-4 to Provenance-safe models (were invisible)
    - balance(dungeon): cut infamy rewards by 2/3 across all 8 dungeons
    - fix(dungeon): defer mob despawn on zone-exit abort to avoid destructor crash
    - fix(dungeon): cap mob engine level at 255 (uint8 overflow = insta-clear exploit)
    - feat(capacity): max density 357 phantoms + 2s respawn timer
    - feat(capacity): wipe Bibiki Bay native pop, keep 6 scripted NMs
    - feat(expcamp): extend the GM Home EXP-camp Moogle through Lv99
    - feat(capacity-farm): populate the whole Bibiki Bay zone with CP mobs
    - feat(warpman): add Bibiki Bay (Capacity Farm) to the gil-warp NPC
    - feat(capacity-farm): +2000 bonus CP per kill at the Bibiki Bay JP camp
    - balance(capacity-farm): 3x mobs, -25% HP in the Bibiki Bay JP camp
    - feat(hl-vendor): add one-handed katanas (NIN) to the gear progression vendor
    - Deploy Everything Sun 06/14/2026 19:32:12.67
    - chore(trust): commit pending Skoll tweak for backup (NOT deployed)
    - chore(wip): commit pending working-tree fixes for backup (NOT deployed)
    - balance(pup): bump automaton damage multiplier 12x -> 20x
    - feat(shop): real infinite-ammo bullet pouches in !shop ammo
    - feat(pup): ~12x automaton outgoing physical-damage multiplier vs custom NMs
    - feat(shop): add endgame arrows + Devastating Bullet to !shop ammo
    - feat(capacity): shared CP farm camp in Bibiki Bay (!capacity)
    - feat(shop): add Chrono/Living/Eradicating Bullets to !shop ammo
    - balance(hunt+reforge): silent +20% on all Hunting League & Reforge NMs
    - feat(augment): wire up Fafnir's Scale + Kirin's Mane trophy drops
    - feat(augment): King Arthro drops its affinity trophy (Emperor Arthro's Shell)
    - balance(ascension): bake the +20% into boss stat blocks (silent)
    - fix(deploy): Deploy Everything reports Server: BUILD FAILED on a failed C++ rebuild
    - balance(ascension): +20% difficulty on all Ascension trial NMs
    - feat(infamy): Infamy Vendor uses the native shop window (icons + stat tooltips)
    - feat(shop): let the native shop charge a CharVar currency (setShopCurrencyVar)
    - fix(dungeon): defer abort teardown out of onZoneIn (re-entrant setPos crash)
    - feat(invasion): !iwarp drops players on the spawn plaza (synced to catalog)
    - feat(invasion): point players to !iwarp in the warning + start broadcasts
    - fix(invasion): announcements said GM Home, battleground is Al Zahbi
    - feat(jobpoints): enable Capacity Points on single-target NMs (Reforge/HL/Prestige)
    - tune(ah): raise buyback cap 50->200, run cron every 2h
    - feat(progression): auto-grant LIMIT_BREAKER + JOB_BREAKER so merit/JP menus aren't greyed
    - feat(infamy): finish Aeonic Anguta weapon + add to Infamy Vendor
    - feat(ascension): opt Jbae out of the shadow-companion familiar
    - feat(infamy): finish Aeonic Trishula weapon + add to Infamy Vendor
    - fix(reforge): keep !reforged spawn menu under 150-byte wire cap (Hadhayosh unspawnable)
    - feat(dev): add local test server workflow
    - feat(gm): add !giveinfamy command to grant Infamy to a player
    - feat(alzahbi): loot fountain - every kill drops a random DB item
    - Deploy Everything Sun 06/14/2026 13:54:01.03
    - feat(invasion): enable trusts + mounts in Al Zahbi (zone misc 5784->7838)
    - fix(zone_entities): clear entity enmity before freeing in releaseIdOnDisappear path
    - feat(reforge): move Reforge Exchange NPC from !hunt to !reforged
    - fix(crash): guard cure-enmity against dangling notoriety pointers (SIGQUIT)
    - feat(hunt-vendor): re-add Malignance Boots to Gold feet (pin in scorer)
    - revert(shop): remove the Gobbie Dial Keys !shop that shadowed the main shop
    - Revert "feat(augments): restore 37 dropped augments (magic/skill/utility) via FORCED_CATALYST"
    - fix(iwarp): move warp point 70y north of spawn anchor (Gajaad coords)
    - fix(invasion): set warp + spawn anchor to confirmed coords (42.4,0,46.4)
    - fix(invasion): use real Al Zahbi ground coords (-35,-1,-31)
    - fix(iwarp): use setPos instead of teleport for cross-zone warp
    - Deploy Everything Sun 06/14/2026 12:40:56.08
    - fix(invasion): update error message from 'GM Home' to 'Al Zahbi (zone 48)'
    - feat(invasion): expand to 5 waves, add all unused mob groups
    - feat(invasion): fixed spawn anchor at Al Zahbi center (0, 0, 36)
    - feat(invasion): add !iwarp command - warps player to Al Zahbi invasion zone
    - feat(invasion): move battleground from GM Home to Al Zahbi (zone 48)
    - feat(invasion): full-DB item drops per kill + auto-reraise at full HP
    - feat(trustattack): make it a toggle that auto-attacks your target until turned off
    - feat(ah-bot): universal buy-back (all AH items, 200%-NPC floor) + move to box cron
    - fix(invasion): move !invasion to modules/custom/commands/ (hot-reload path)
    - feat(invasion): add !invasion GM command (start/end/status)
    - feat(gear-vendor): add Malignance Boots to Gold feet (completes the set)
    - fix(invasion): NonExclusive claim so the whole raid can fight every invader
    - feat(rng): implement Hover Shot (RNG L95 JA, stacking RACC+RATT)
    - balance(trusts): Meat 50M->25M, Corvus 15M->75M (Gemma stays 50M default)
    - feat(shop): add Trizek Ring (27557) to general shop at 100k gil
    - feat(server): hide the disabled RoE/Sparks NPCs in the 3 capitals (DISAPPEAR)
    - feat(server): disable RoE + Sparks NPCs in the 3 starting capitals
    - feat(dungeons): add 4 parallel-track dungeons (D5-D8) to double concurrent capacity
    - feat(pup): automaton survivability buff (HP/DEF/regen) for lv150 NMs
    - feat(ascension): swap companion to LynxFamiliar (small non-avatar jug pet)
    - fix(deploy): stop xi_map around tarball extract to prevent FileWatcher storm
    - feat(ascension): swap shadow companion to Carbuncle (small pet); clear opt-out
    - feat(ascension): per-char opt-out for the shadow companion (Jbae off by request)
    - Deploy Everything Sun 06/14/2026  8:18:46.77
    - fix(aep): resolve duplicate CLuaBaseEntity::hasTrait blocking the C++ build
    - fix(lua): guard GetSystemTime() nil returns in setLocalVar calls
    - Deploy Everything Sun 06/14/2026  7:24:23.00
    - fix(prime-armory): reduce PAGE_SIZE 7->4 to fix pagination
    - fix(trust): guard nil return from getPartyLastMemberJoinedTime
    - Deploy Everything Sun 06/14/2026  6:34:35.96
    - Deploy Everything Sun 06/14/2026  6:28:34.40
    - fix(trust): guard nil skill/target in Valaineral WEAPONSKILL_USE listener (crash 2026-06-14)
    - Deploy Everything Sun 06/14/2026  6:17:20.71
    - feat(shop): add Antacid to consumables; ship PUP Animators + free reforge-set claim
    - balance(voidspire): bump depth-milestone bonus marks (200/500/1500/3000/6000 -> 2500/10000/25000/40000/70000)
    - feat(ascension): shadow companion for ascended; revert rejected stars+title
    - feat(aep): Alter Ego Points system (March 2026 retail)
    - fix(pup): boost automaton weapon damage and ACC/ATT vs custom high-level NMs
    - fix(pup): keep loadout menu under the ~8-option cap
    - feat(pup): add 'Unlock all attachments' to !pup menu + !pup attachments (runs addallattachments)
    - feat(prime): open !primevoucher to all players (permission 0)

??? note "Saturday · June 13, 2026"
    - chore(ops): untrack navmeshes phantom gitlink
    - Deploy Everything Sat 06/13/2026 23:55:14.03
    - deploy(retire-laptop-publish): deploy-everything now publishes the site FROM THE BOX
    - Deploy Everything Sat 06/13/2026 23:48:12.54
    - Deploy Everything Sat 06/13/2026 23:36:54.68
    - fix(docs-deploy): add git pull to Azure cron so docs auto-update
    - feat(login-streak): boost milestone bonuses 30x
    - feat(docs-deploy): venv + token-file + cron-safe PATH in refresh_site_azure
    - fix(wavemaster): award completionBonus to all party members
    - feat(branding): replace repo logo with the Legendary dragon emblem
    - fix(trust): repair Void Keeper menu (quote-in-label) + add !givetrust
    - feat(prime): 1% Prime Voucher drop from any Hunting League NM
    - feat(ws): enable the other 5 Prime weapon types (GA/Scythe/Polearm/Bow/Gun)
    - feat(trust): give Corvus a hard hitter -- Apex Arrow at 1000 TP
    - fix(gmhome): paginate Cross-Job Ability Trainer menu (un-hide Ninja + How-it-works)
    - feat(prime): reusable Prime Voucher reward helper (source-agnostic)
    - feat(ascension): show master stars + menacing title for ascended players
    - feat(trust): make Corvus actually hit hard (give his empty bow real DMG)
    - docs(gmhome): Trait Trainer survives job change (verified, no hook needed)
    - feat(prime): add !primevoucher GM command to grant the bound voucher
    - feat(ws): enable 6 more Prime weapon skills + voucher-gated Prime Armory
    - feat(trust): Corvus look -> Elvaan Male ranger (LotR elf) with a longbow
    - feat(gmhome): add Cross-Job Trait Trainer (6 borrowed job traits)
    - feat(trust): add Corvus, a ranged-DPS custom trust on the Curilla (902) slot
    - feat(onboarding): linkpearl ask in login Quick Tips bar
    - feat(aura): add !aura sweep <mode> <start> <end> to audition effect ranges
    - tune(gmhome): Sparks Exchange rate 50->10 gil/spark
    - feat(ws): implement Maru Kala (231) as a player weapon skill
    - feat(gmhome): add Sparks Exchange (sparks->gil) + fix Casino position collision
    - Deploy Everything Sat 06/13/2026 18:45:17.77
    - feat(qol): !trustattack -- send your trusts at your target before you engage
    - feat(shop): add Chocobo Shirt + Destrier Beret to !shop armor
    - feat(gmhome): add the Lady Luck casino (slots, high-low, roulette, dice)
    - fix(seal-drops): cumulative quantity roll (X% = drop N-or-more)
    - balance(seal-drops): guaranteed escalating quantity per mob
    - fix(launch): RaidBoss + Reforge NPC + Impetus bugs; add mob seal drops
    - balance(invasion): increase + enrich GM Home defense rewards
    - feat(gmhome): Unlocker NPC can unlock all automaton parts (PUP)
    - docs(commands): add docgen func/desc headers to the spell commands
    - feat(spells): expose custom spells as !aegis/!convergence/!silencega
    - fix(hunting-league): price the Armor NPC [TEST] preview shop at 100M gil (was ~12)
    - balance(prestige): make Raja (Voidfang) silenceable
    - balance(hunting-league): bump Simurgh difficulty a notch (T3)
    - tune(weapons-vendor): cap Prime/Su5/Ambuscade ranged, spread across tiers, drop ammo
    - feat(weapons-vendor): add capped ranged weapons (archery + marksmanship)
    - fix(trusts): block the retail San d'Oria Excenmille NPC from granting Meat (899)
    - fix(trusts): exclude Meat (899) from the grant-all NPC + !addalltrusts
    - feat(augments): restore 37 dropped augments (magic/skill/utility) via FORCED_CATALYST
    - fix(commands): drop the per-line "SystemMessage" banner across all custom commands
    - feat(pup): !pup unlock -- grant all automaton frames & heads instantly
    - fix(mystats): drop the per-line "SystemMessage" banner spam
    - fix(hunting-league): spread the Reisenjima Henge vendor NPCs (fix label overlap)
    - tune(hunting-league): un-engaged NM despawn 180s -> 30s
    - Deploy Everything Sat 06/13/2026 12:12:19.58
    - fix(geo): allow GEO luopan (Geo- spells) across all Reisenjima zones
    - feat(reforge): idle-despawn un-engaged NMs after a few minutes
    - feat(gear-vendor): complete the Taliah +2 set in the Armor NPC (silver)
    - feat(pup): !pup automaton quick-loadout manager (save/swap frames + attachments)
    - feat(crossjob): add Tier 1+2 abilities to the Cross-Job Trainer (39 -> 63)
    - feat(hunting-league): idle-despawn un-engaged NMs after a few minutes
    - feat(shop): add subjob ninja tools to !shop ninja (1 gil)
    - feat(shop): add !shop ninja -- universal ninja tools at 1 gil
    - feat(qol): make Auction House usable in every zone (!ah anywhere)
    - feat(augments): remove Physical Damage Limit augment (redundant after cap raise)
    - balance(trusts): Meat + Gemma 500M -> 50M gil (Void Keeper)
    - feat(shop): add Matre bell to !shop weapons
    - fix(links): correct Discord invite across docs, server message, announcer
    - feat(mysterymog): add Pupil set pieces to the gil-gamble prize pool
    - data(gear-mods): refresh item-mods pipeline output
    - feat(qol): open !release to all players (permission 1 -> 0)
    - fix(raid): re-enable Star-Devourer stances (correct nil xi.mod names)
    - fix(shop): custom-currency shops deduct across all stacks/containers (no more free buys)
    - fix(hunting-league): let pet jobs call pets in Reisenjima Henge
    - fix(hunting-league): consume seals across all stacks/containers, not just the first inventory stack
    - feat(shop): add !shop ammo - leveling ladder of arrows/bolts/bullets/shuriken
    - ops(docs): Azure-side site refresh script (live leaderboards + player pages)
    - feat(shop): add !shop pets -- curated BST jug pets + pet food
    - fix(custom-chat): move custom command/login output off linkshell channels
    - balance(gear-vendor): add Ryuo Domaru (bronze) + Agony Jerkin +1 (gold) bodies
    - balance(gear-vendor): fill body-slot coverage gaps (lean set)
    - fix(warp): use verified in-game !pos for Ra'Kaznar Inner Court warp
    - feat(warp): add Ra'Kaznar Inner Court to the Warpman (Endgame tier)
    - balance(gear-vendor): pull Argosy Hauberk base from silver + add gap-report tool
    - feat(gear-vendor): add 5 melee/tank body pieces to bronze tier
    - feat(shop): optional custom-currency shops (charge an item instead of gil)
    - fix(sparkshop): never leave the event menu hanging (Rolandienne lock-up)
    - feat(qol): personal per-character waypoints (!waypoint)
    - fix(crash): null-guard CLuaBaseEntity::getZoneID() (Abyssea casket crash)
    - feat(shop): add Mumeito to !shop weapons (15k gil)
    - feat(shop): add !shop dice - all 31 Corsair roll dice at 1 gil
    - balance(gm-home): buff GM-Home Serket HP to match the Hunt League fix
    - balance(hunting-league): buff Serket HP (Rank III was too soft)
    - balance(shop): augment catalysts 1,000,000 -> 100,000 gil
    - feat(shop): surface EXP/Capacity augments as their own !shop group

??? note "Friday · June 12, 2026"
    - fix(linkshell)!: remove global LS auto-grant entirely (was crash-looping server)
    - fix(linkshell)!: stop auto-equipping global LS - it crash-loops the server
    - Deploy Everything Fri 06/12/2026 23:16:26.25
    - Deploy Everything Fri 06/12/2026 23:01:55.47
    - feat(ops): NPC declutter -- safety-filtered set + deliberate one-shot apply
    - feat(prestige): cosmetic Ascension aura for ascended players
    - fix(augments): restore Exp./Cap. Point catalysts durably via generator
    - feat(jobs): auto-unlock RUN + GEO for all players in the Mog House menu
    - ï»¿feat(ops): NPC declutter -- status-0 filter + both-bucket SQL
    - feat(gm-home): cluster the 3 teleport NPCs on the east side
    - Deploy Everything Fri 06/12/2026 21:35:26.34
    - feat(linkshell): global Legendary server linkshell for all players
    - feat(ops): searchable HTML view for the NPC disable audit
    - ï»¿feat(ops): NPC disable audit -- per-zone "extra NPC" review list
    - fix(modules): gate login hooks on gameLogin, not 'not zoning'
    - fix(missions): skip the SoA/RoV mission tails too
    - perf(npc): set customMenu send delay to 30ms (was 50, briefly 15)
    - perf(npc): lower customMenu send delay 50ms -> 15ms (all NPCs)
    - fix(missions): actually skip CoP in the Mission Moogle
    - ï»¿feat(augments): wire up an Enspell Damage catalyst (Wamoura Scale)
    - ï»¿feat(ops): achievements feed for the Discord watcher (second webhook)
    - ï»¿feat(ops): Discord join watcher for the public launch
    - Deploy Everything Fri 06/12/2026 16:34:39.27
    - feat(jobs)!: retire the Bouncer, restore retail Geomancer on slot 21
    - fix(commands): remove dev notes from player command !help text
    - ï»¿fix(world): stop the ZMQ router busy-spin pinning a core at 100%
    - ï»¿fix(mounts): honor MOUNT_SPEED above 255 and clamp the mount branch
    - ï»¿feat(mystats): Ascension section -- every Provenance AP category
    - fix(concurrency): public-launch hardening - menu race + dungeon occupancy
    - Deploy Everything Fri 06/12/2026 14:54:44.95
    - fix(league): Reisenjima_Henge zoneId is 292, not 291
    - feat(derby): Chocobo Derby - simulated racing with betting + raised birds
    - feat(treasure): treasure maps, overworld digs, buried strongboxes
    - feat(league): Provisioners' League - the non-combat fishing/crafting league
    - fix(prestige): spawn Trial bosses on a ring at the summoner, on the floor
    - feat(raid): The Star-Devourer - weekly multi-phase raid boss
    - feat(invasion): scheduled Voidsent assaults on GM Home
    - feat(colosseum): async ranked PvP vs AI replicas of real champions
    - fix(prestige): spawn Trial bosses at the summoner, not a fixed off-map point
    - feat(dungeon): Mythic+ keystones - endless key levels above Mythic
    - ï»¿Retire the new-player linkshell; dedupe the Dungeon Veteran title
    - ï»¿docs-in-code: catch comments up to the 5-catalyst reality

??? note "Wednesday · June 10, 2026"
    - Deploy Everything Wed 06/10/2026 20:57:21.64
    - feat(augment): allow up to 5 catalysts/trade (the engine's 5 augment slots)
    - Deploy Everything Wed 06/10/2026 20:33:09.33
    - revert(augment): back to one augment line per catalyst (4-line stacking)
    - balance(augment): split value budget rank 0-24 / stack 0-7 (owner choice)

??? note "Tuesday · June 9, 2026"
    - Deploy Everything Tue 06/09/2026 19:19:28.42
    - fix(augment): confirm menu fits stacked trades + proper N-times scaling
    - Deploy Everything Tue 06/09/2026 18:57:54.58
    - fix(dangruf-wadi): nil-guard weather handler to stop intermittent startup crash
    - fix(augment): stop catalyst stacking from eating gear; amplify via value field
    - Re-tune haste augments to a sane ~1%->25% curve + normalize their display
    - Deploy Everything Tue 06/09/2026 17:41:12.31

??? note "Monday · June 8, 2026"
    - Normalize stored-xN augment mods in the displays (disp divisor)
    - Deploy Everything Mon 06/08/2026 22:59:55.47
    - fix(escha): remove Warder of Temperance spawn from the GM-wave area
    - feat(items): make all edible foods stack to 99 (Magma Steak etc. shipped at stackSize 1)
    - feat(shop): add top attack foods to !shop food (Magma/Behemoth/Charred Salisbury Steak)
    - Deploy Everything Mon 06/08/2026 22:05:45.66
    - feat(combat): exempt Provenance from level correction (hosts lv150 Prestige bosses)
    - Permanently exclude the 19 Judge items from all three gear scorers
    - feat(gear): WS Set Builder fixes â€” grips, Fotia, WSD rings, Knobkierrie; remove Judge's
    - Deploy Everything Mon 06/08/2026 19:03:31.04

??? note "Sunday · June 7, 2026"
    - Reforge tier carry-forward + all-source mod reads + ascension perks
    - feat(gear): commit reforge tier stat/model fills + audit tooling
    - feat(combat): raise magic/spell damage cap 99,999 -> 131,071
    - feat(combat): raise damage cap 99,999 -> 131,071 (FFXIAH client packet max)
    - fix(infamy): remove phantom 'Knobkierrie' vendor entry (id 26072 doesn't exist)
    - Deploy Everything Sun 06/07/2026 14:33:55.23

??? note "Saturday · June 6, 2026"
    - Deploy Everything Sat 06/06/2026 11:40:31.11
    - feat(deploy): score-once-deploy-both so server and website never drift
    - deploy: sync server catalogs to published website + harden deploy button
    - fix(voidspire): correct invalid mod names so the catalog loads on live
    - Deploy Everything Sat 06/06/2026  4:00:10.71
    - Live update 2026-06-06_03:16
    - Live update 2026-06-06_02:08
    - fix(dungeons): remove all movement boundaries (gates + OOB warp)
    - feat(deploy): make Full Update (Live) a true one-click
    - feat(crossjob): auto-create char_cross_job_abilities via zz_ reload
    - chore(infamy): auto-splice itemTypeMap into catalog; refresh expanded map
    - feat(crossjob): Cross-Job Ability Trainer at GM Home
    - feat(gmhome): Home Point crystal warps to any homepoint, free
    - feat(infamy): grouped vendor browser + relic/endgame listings
    - feat(infamy): generator for the vendor item type-map (grouped browser)

??? note "Friday · June 5, 2026"
    - chore(docgen): commit BG-Wiki stats cache for reproducibility
    - feat(infamy): stat blocks for relic 119 III + endgame gear

??? note "Thursday · June 4, 2026"
    - fix: stat naked dungeon-shop gear + make DB-only tier mods rebuild-safe

??? note "Saturday · May 30, 2026"
    - feat: add !reallevel command (effective level past 99)
    - feat: raise BRD max songs and COR max phantom rolls to 6
    - feat: help/marks/streak/tier/week/events/top/announce/setbonus/reforge commands, death penalty, weekly recap, Infamy milestones, tier promotion broadcast
    - feat: party bonus, kill streak, who/profile/nms/time/shutdown commands, login bonuses, auto-buff, achievement titles, leaderboard NPC, weekly dungeon bonus
    - [dungeon] Add weekly bonus dungeon system (2x Infamy on clear)
    - feat: featured/achievements/optin/optout commands, seasonal events, progress drill-down, Discord achievements
    - feat: enable HNM Kings system + add lower-tier HNMs
    - feat: new player experience, first-kill bonuses, weekly events, achievements
    - refactor(augments): remove weaker duplicate augment catalysts, keep strongest only
    - feat: move Wave Master NPC from GM_Home to Balga's Dais (zone 146)
    - feat: Daily Board, 4th dungeon, !lfg, !progress, !gainexp cooldown

??? note "Friday · May 29, 2026"
    - feat: add Curated Sets vendor category to Infamy Vendor
    - fix: Infamy Vendor menus exceed 150-byte customMenu cap, silently dropping Buy

??? note "Saturday · May 16, 2026"
    - Khimaira Audit
    - [lua] [sql] Mammet Bugfixes
    - [trust, sql, lua, core] Trust Tank audit and cleanup (#10002)

??? note "Friday · May 15, 2026"
    - [lua] Fixes nil errors in Disaster Idol spell choose
    - Fix hit distortion wrap on overkills
    - [core] Use slot to determine delay for TP return
    - [cpp, lua, sql] Renames family to species
    - [core] Don't clobber look string data on entities with no size data
    - Send item unlock packet on craft material saved
    - Carry ItemUse transaction on PChar for dtor order
    - Add missing steal to Antican Praetor and Legatus
    - Fix Rice balls latent values on gear
    - Allow ammo to be consumed while equipped

??? note "Thursday · May 14, 2026"
    - Fix Automaton Skill Lookup
    - [lua] Truth Lies Hid quest
    - [lua] [sql] Implement Dainslaif's add effect
    - Mocking Colibri base dmg adjustment
    - Convert Bugfix

??? note "Wednesday · May 13, 2026"
    - [lua][module] BST Era Bug Fix
    - [lua] AA MR Pet Fix

??? note "Tuesday · May 12, 2026"
    - [lua] Superlinking
    - Watch Wamoura adjustment
    - Crustacean Conundrum
    - [cpp] Fixes ordering of mods applied in bcnms
    - MMM Rune/Vouchers unlocks
    - Lua bindings to get/set MMM unlocks
    - Load and send MMM unlocks to player
    - Add MMM unlocks to char_unlocks table

??? note "Monday · May 11, 2026"
    - [sql] Add Elementals Ancient Magic
    - fix(dbtool): open modules/init.txt with utf-8 encoding
    - [lua] [sql] Dragon Poison Breath
    - [cpp] Fixes underflow in avatar perpetuation
    - [cpp, lua, sql] Implements new family system

??? note "Sunday · May 10, 2026"
    - [lua] Holy Cow
    - Behemoth NM Audits Resists Fix
    - Moment of Truth implementation
    - Add missing RACC for Demon Arrow
    - [lua] Bahamut TP Move Cleanup

??? note "Saturday · May 9, 2026"
    - /itemsearch support
    - Lua bindings for PC-to-PC trades tests
    - [sql] Fixes promy dem mob name
    - [lua] [sql] Up in Arms Improvements
    - Route synthesis through SynthTransaction
    - [trust, sql, lua, core] Valaineral gambits, mods, spells, gambit support (#9947)

??? note "Friday · May 8, 2026"
    - [sql] Movalpolis Goblin Skill List Audit
    - [lua] Pulling the Strings Improvements
    - Allow spells to set knockback and distortion in packets
    - [lua] [sql] Various BCNM Fixes
    - [cpp] Adds setting for era recast time
    - [lua] Royal Jelly Refactor
    - Fix 2 broken 'onTriggerAreaEnter' cases
    - [lua] Add level penalty to picklocking treasure chests / coffers
    - Core: Improve ximesh raycast around block.hasBarriers
    - Add support for drain-like AEs
    - [lua][sql] Rapid Raptors
    - [lua] Pulling the Strings Bugfixes
    - [cpp] Allows dualWield to be changed on the fly

??? note "Thursday · May 7, 2026"
    - [cpp] Combined trust and char ranged attack code to battle entity
    - Core: Add safety check to entity:canSee(...) binding
    - Give Peace a Chance Full inv event
    - Synthesis 'Dawn Mulsum' content_tag ABYSSEA
    - Remove mentions of losmeshes
    - Core: Clean up Vector3
    - Removed losmeshes submodule
    - Core: Use ximesh for raycasts, remove LOSmeshes
    - Ode to the Serpents follow up quest conditional fix
    - [lua] Fix physical mobskill missing enmity update
    - Set Purgonorgo 'Jagil' mob to non-agressive
    - [cmake] Update MariaDBCPP commit
    - Add missing status effects
    - Add missing HIDE_TIMER to effects
    - Add missing NO_CANCEL to effects
    - Fix cross-family mob linking in Einherjar

??? note "Wednesday · May 6, 2026"
    - Lazy load instances
    - [sql] Expansion Flock Bat SkillList Audit
    - Link rapidyaml; YAML parsing lib
    - Link earcut.hpp; polygon triangulation lib
    - [lua] [module] DEL duplicate module Lamia Fang Key timer
    - [lua] curio moogle 2025-26 Q1
    - Return to the Depths Fight
    - Stamp Scheduler on MapSession at creation
    - Cancel fishing on hostile action received
    - Streamline ATTACK/ON_ATTACK effects removal handling
    - Crit fail synthesis when taking damage
    - Core: Fix packBits heap-buffer-overflow.
    - [cpp, lua] Change delay to have the in-game input instead of milliseonds
    - [lua] [sql] Pulling the Strings

??? note "Tuesday · May 5, 2026"
    - ISNM 3k Happy Caster adjustment
    - [lua] [sql] Improve Hundredfaced Hapool Ja
    - [core][lua][sql] Movalpolis Patrols and Guards
    - [cpp] fixes ranged job abilities - Removes shadow bug for double and triple shot (+40% activation rate over what's shown on mod::double_shot_rate and mod::triple_shot_rate
    - [lua] What Price Loyalty quest
    - [lua] [sql] Implement Lamiabane

??? note "Monday · May 4, 2026"
    - [lua] Charmed Pet/MNK Mob TP Returns
    - synth HQ rate xi_test
    - [core] Simplify magic/ranged state hasMoved()
    - [lua] Fix Kumhau the Flashfrost Naakual cutscene exit position
    - [lua] Fix Water Way to Go trade item not consumed on completion
    - [core] Dual Wield Setup
    - [lua] [sql] Balmung AE Dispel
    - [core] Refactor getBarrageShotCount to allow trusts to use it
    - [lua] Add rank requirement to signet staves
    - [sql] Add BARRAGE_COUNT item mods where applicable
    - Core: Flatten CPetController::DoRoamTick logic, general tidy
    - [core] Adjust some logic for BST pets causing heap corruption
    - Fixes augment 1152 - DEF +10
    - [lua] Beneath the Mask quest
    - [sql] Toreadors Cape Crit Rate
    - [sql] Snakeeye / Snakeeye+1
    - [cpp] Adds missing ranged attack animations
    - style check for royal_savior.lua
    - gambits_container RANDOM TP amount trigger
    - rughadjeen and trion gambits and skills

??? note "Sunday · May 3, 2026"
    - Route item usage through transactions
    - [core] Use message to determine if spell had no effect
    - [lua] [module] Lamian Fang Key Conquest Timer
    - [core] add CLuaItemPuppet
    - [sql] Update pepperoni price
    - [lua] Chicken Knife
    - Fix Blu physical spell miss message
    - Mob 2hr TP Flag Fix
    - Bump ximeshes version
    - [core] Remove some NM only mods (no proof exists)
    - Engine: Add runtime navmesh generation
    - [lua] Convert COR AF3 to Interaction Framework
    - [lua] Honor Under Fire quest

??? note "Saturday · May 2, 2026"
    - [lua] [sql] Barrage support to ranged attacks
    - ISNM3k Compliments to the Chef adjustment
    - Core: Turn REPLACE INTO into upserts
    - Core: make chocoboRaisingInfo upserts
    - [sql] Fix Fluorescence target flag to self

??? note "Friday · May 1, 2026"
    - Adds getLocalVars table for LLS
    - Adds event 171 default action to qm_cancel_escort in Grand Palace
    - Adjust Foreseer's delay back to 240
    - Adjust Tyrannic Tunnok to a 7 hit
    - Conflict fix for automaton skills in mob_skill.lua
    - Mnejing, gambits, scripts, sql and mob_skill.lua additions
    - Add player and trial table check to magian onMobDeath function

??? note "Thursday · April 30, 2026"
    - [lua] Check if any NM in the PH list is spawned or going to spawn
    - [lua] Enable spawning of both Tom Tit Tat copies
    - [lua] Fixes 3 mobskills
    - [lua] [sql] Implement Hyakume
    - [SQL] Correct Four of Batons dropid
    - [core] equip sync: remove stale references from items being deleted
    - [core] Only queue equip update if item was equipped

??? note "Wednesday · April 29, 2026"
    - Raising: Add breeding.lua (not hooked up yet)
    - Encapsulate PC equipment and set ItemState
    - ItemState and badge-gated mark() role transitions

??? note "Tuesday · April 28, 2026"
    - Adjust several MNK NMs to observed delays
    - [lua] Chocobo riding game reward fix
    - Puppetmaster LB Fight
    - [core] Skip sub slot if main is h2h with /lockstyleset #
    - [lua] [sql] BCNM 50 Idol Thoughts
    - [lua] Give Peg Powler a PH, upgrade spawn rate
    - [sql] Enable some drop pools, disable drop pool for another
    - [core] print an error if a mob droplist is empty
    - [core] Adjust EXP Rate settings & mechanics
    - [lua] [sql] Staff Mobskills
    - [chore] Starts mob ecosystem cleanup
    - [lua] Ouryu Bugfix
    - Update Dialogue to reference correct brother in The Competition

??? note "Monday · April 27, 2026"
    - [lua] [sql] Archery Mobskills
    - [lua] Quelling the Storm quest
    - Items, containers tests
    - [lua] Convert COR AF2 to Interaction Framework
    - Raising: Map out ability learning flow

??? note "Sunday · April 26, 2026"
    - [lua] [sql] Club Mobskills
    - [lua][module] Adds blocks for certain door related KIs
    - Raising: Map out chocobo visible mood opcode
    - Raising: Map out the rest of xi.chocoboRaising.cutscenes
    - Route all item creation/lookups through xi::items
    - Limit HQ2 and HQ3 results depending on HQ tier
    - Great Katana Mobskills

??? note "Saturday · April 25, 2026"
    - [lua][sql] COP Bomb/Snoll Skill Lists + Audit
    - [sql] Fixes several droplist typos in mob groups
    - Implement katana mobskills
    - Implement polearm mobskills
    - [lua] Fafnir Audit
    - [lua] [sql] Scythe Mobskills
    - [lua] [sql] Axe Mobskills
    - [lua] [sql] Greataxe mobskills

??? note "Friday · April 24, 2026"
    - [Module][Quest] Home Point Era Menu
    - [core] Unify more Core/Lua TP Functions
    - [lua] Repeatable Quest Fixes

??? note "Thursday · April 23, 2026"
    - [lua] Add Choke Effect to Gale Axe
    - Fixes Bind allowed resist state value and duration calculation
    - [lua] [sql] H2H Mobskills
    - Fix impetus setMod() usage
    - [lua] [sql] Great Sword Mobskills

??? note "Wednesday · April 22, 2026"
    - [lua] [module] Implement old TP gain as module
    - Raising: Tidy walks
    - Raising: Fix forced retirement
    - Raising: General VM cleanup

??? note "Tuesday · April 21, 2026"
    - Prevent client lockup during Brygid The Stylist Returns
    - [lua, sql][module] Remove OOE HELM items
    - [lua] Bahamut BV2 Message
    - [lua] [sql] Dagger mobskills
    - [lua] Fire in the Hole quest
    - [lua] Evisceration bugfix
    - Raising: Confirm force-naming at ADULT_3
    - Raising: Even more White Handkerchief quest latching
    - Raising: Clean up White Handkerchief quest latching
    - Raising: Fix GM stat printing
    - Raising: Hide more information from PRESENT_CHOCOBO_APPEARANCE
    - Raising: Clean up stat packing and condition reporting
    - Raising: Don't leak appearance data before it's time
    - Raising: Clean up REGISTER_CHOCOBO_WHISTLE
    - Raising: Clean up INTRO_MENU_PT_3
    - Raising: First pass of Chocobo Whistle questing, registration, and usage
    - Raising: Handle White Handkerchief quest
    - Raising: Trying to correct care plan overrun
    - Raising: Map out care plan menu
    - Raising: Don't accumulate energy usage through full report
    - Raising: Handle initial care plan shifting and reporting
    - Raising: Remove synthetic events, general cleanup

??? note "Sunday · April 19, 2026"
    - [lua] Premium Mogti WS Message
    - [lua] [sql] Sword mobskills
    - Improve mobskill status effect handling and application
    - [lua] Have core use lua functions for fSTR
    - [trust, sql, lua, core] Gessho adjustments and Issekigan Job Point crash fix for trust (#9826)
    - Cap targetfinding vertical search to 8/8.5y
    - Chuchuroon patrol nodes

??? note "Saturday · April 18, 2026"
    - [lua][module] Set gravity to apply evasion penalty
    - [lua] [sql] Markmanship Mobskills
    - [lua] [sql] The Wyrmking Descends
    - [lua] Fix hybridDamage mobskill function
    - Riverne B NM Audits
    - Lower chance for Dynamis staggers if not main target
    - [core] Set EVA Rank fallback for jobs with no subjob.
    - [sql] Correct Ancient Bomb Levels
    - Raising: Split out logic into different files
    - Raising: Split out Event Condenser, fix condenser logic
    - Raising: Remove invalid LIMIT from setChocoboRaisingInfo query
    - Fire _TAKE listeners on all AoE targets
    - Mobskills only trigger resonance on main target
    - Uplift !additem to new exdata format

??? note "Friday · April 17, 2026"
    - Round packet size to nearest 4
    - [cpp] Fix NM hp in mob groups not working
    - [lua, sql] Rework ToAU 15 Black Coffin battlefield
    - [lua] utils.shadowAbsorb cleanup
    - [cpp] Changes crystal drop rate per party member and rates

??? note "Thursday · April 16, 2026"
    - [Module] Quest "Chocobo's Wounds" - Era-Wait-Time
    - [cpp, lua] Moves dynamis cpp function to lua
    - Fix mobskill spam: Angler Orobon, Tinnin
    - The Bonds of Fate (Qultada)
    - Fix Chocobo's Wounds

??? note "Wednesday · April 15, 2026"
    - Fold PacketGuard into the general C2S system
    - BLU LB Raubahn out of combat self buff adjustment
    - Remove Battlefield Scripted Roamflag
    - [cpp] Cleanup my old HP formula
    - Corrects Tantra Cyclas +1 functionality and cleanup Impetus
    - Change default spell list entry to a buff
    - [core] Adjust IEP code to /check IEP at 56 exactly
    - SMN AF2 Dryad roaming
    - [lua] Convert Better Part of Valor + Fires of Discontent  to IF
    - Riverne A NM Audits
    - Fix quest events, their priority and overall cleanup
    - [Quest] Chocobos Wounds Trade Function Correction
    - Return to the Depths implementation

??? note "Tuesday · April 14, 2026"
    - Skull of Sins Audit
    - [core][lua] Physical Mobskll Refactor
    - [lua] Fix ranged PDIF edgecase
    - [lua] [sql] Divine Might Tuning
    - [lua] Implement high/low pdif rolls for melee
    - [lua] Move melee spike ratio out to a function
    - Unbridled Passion bugfix
    - [core] Don't fire mobskill if mob has Hysteria status
    - Cleanup teleport NPC scripts

??? note "Monday · April 13, 2026"
    - Implement Promy Vahzl Apex Mobs
    - Implement Promy Mea Apex Mobs
    - /translate support, JP item names
    - Implement Promy Holla Apex Mobs

??? note "Sunday · April 12, 2026"
    - [lua, sql] Implement Promy Dem Apex Mobs
    - [lua] [sql] Storms of Fate & Bahamut Mobskills
    - [sql] Minuet / Titanis Earring Latents
    - Curilla gambits, skills and mods
    - Call onItemDrop when passing through the recycle bin
    - Validate furniture placement
    - [sql] Delete unused and duplicate mob family values
    - Fix Alsha immediately changing phase after last cure is casted

??? note "Saturday · April 11, 2026"
    - [lua][chore] ROE Objective enums
    - [Trust, core, sql, lua] August gambits and supporting gambit_container changes (#9718)
    - Knocking on Forbidden Doors fight mechanics and adjustments
    - Flag certain items to skip rare check and recycle bin
    - [lua] [sql] Ouryu Cometh

??? note "Friday · April 10, 2026"
    - [lua] Aydeewa Diremite Remove unused mixin
    - Audit weapon damage type
    - [core] Exclude mobs from Martial Arts calculations
    - [lua] Fixes curtana floating qm
    - Audit weapons skill, damage, delay
    - Audit equipment levels, jobs, slot, size
    - [core][lua] Correct base TP returns for mobs.
    - Audit usable items usage time and targets
    - [lua] [sql] KS99 Adjustments
    - Drop nodiscard flag from setters
    - [lua] WoTG Sword Module Bugfix
    - Audit furnishing storage, element
    - Audit items stack size
    - Audit item flags
    - Sort usable item entries

??? note "Thursday · April 9, 2026"
    - Add missing general items
    - Add missing equipment and weapon items
    - Add missing usable items
    - Add missing BCNM orbs and storage slips
    - Add missing furnishing items
    - Support floating activation time on usable items
    - Fix item names and sortnames to match retail data
    - Boat Audit Pt. 1 revisions
    - [login] Adjust char info management during the lifetime of data_session
    - Behind the Smile quest implementation
    - Convert item_basic flags to readable SQL variables
    - Move item flags to ItemFlag enum class
    - Missions: Add empty stubs for TVR mission line
    - Bump item flags from uint16 to uint32
    - Missions: Add empty stubs for remaining ASA missions
    - Missions: Format AMK missions a little
    - Missions: Add empty stubs for remaining ACP missions
    - Docs: Add advanced guidance for IF usage and event packets
    - Docs: Add information on capture formats
    - Docs: Add guidance for humans and AI agents

??? note "Wednesday · April 8, 2026"
    - BRD AF3 Bugfix
    - [login] Increment key after char deletion
    - Limit delivery box to 128 items in flight
    - [lua, sql] Fixes COP 7-1 full inventory message and NPC
    - [documentation] Moves all of the old limbus to documentation folder

??? note "Tuesday · April 7, 2026"
    - Exdata definitions
    - [lua] [sql] Moblin Fantocciniman + Marionette Dice

??? note "Monday · April 6, 2026"
    - Yeet unneeded THF AF1 stew code
    - TOAU Mission 5 Quest IF Adjustments
    - [lua] [sql] Marionette Dice Pt. 1
    - [c++] Fix Moghouse entry in WoTG + SoA
    - Fix message ID for Leviathan Slowga

??? note "Sunday · April 5, 2026"
    - Remove Silver beastcoin from THF quest quadavs
    - [lua] [sql] Moblin Emotes
    - Exdata definitions
    - [lua, sq;] ToAU 13 Lost Kingdom fight adjustments
    - Bug Fix Quest Rock Racketeer wrong Prog Value

??? note "Saturday · April 4, 2026"
    - Ancient Goobbue Audits
    - [lua] ENM Pulling the Strings framework
    - Exdata definitions
    - Replace Magic Numbers in Tavnazia, Nashmau, Shadowreign shops

??? note "Friday · April 3, 2026"
    - [lua] [lls] Adjust some LLS hinting for new LLS version
    - [lua] Add 'hitsLanded' = 1 to calcparams of magic ws (#9701)

??? note "Thursday · April 2, 2026"
    - [core] Always fetch subjob when saving char to db
    - Exdata definitions
    - [core] thunder element should look up thunder res rank
    - Quest Cleanup Promotion Superior Private
    - [core] Filter additional bad equip packets
    - Replace magic numbers in TOAU shops
    - [core] [lua] Actually enforce "must zone" and not just /logout

??? note "Wednesday · April 1, 2026"
    - Exdata definitions

??? note "Tuesday · March 31, 2026"
    - Enable ximesh files support
    - [lua] Fix edge cases that report incorrect misses for mob/weaponskill
    - Implemented burden of suspicion
    - Implemented Storm on the Horizon
    - Audit Uleguerand Range NMs
    - Fix stackoverflow from reentrant action queue
    - Revamp exdata handling

??? note "Monday · March 30, 2026"
    - [lua] Refactor PDIF clamping and simplify code
    - Implement Inner Horutoto Ruins spawn slots and phs
    - Implement West Sarutabaruta spawn slots and ph ids
    - Implement Ve'Lugannon Palace spawn slots
    - Implement King Ranperre's Tomb spawn slots & ph info
    - Implements yuhtunga jungle spawn slots
    - Implement cape Teriggan spawn slots
    - [lua] KS99 Horns of War

??? note "Sunday · March 29, 2026"
    - Implement Upper Delkfutt's Tower spawn slots and update NM PHs
    - Implement Sea Serpent Grotto spawn slots and NM phs
    - Implement Promy Dem spawn slots
    - Implement Kuftal Tunnel spawn lots and NM PHs
    - Implement PsoXja spawn slots and NM info

??? note "Saturday · March 28, 2026"
    - Allow mob entities to use job abilities
    - Implement Middle Delkfutts Tower spawn slots
    - Core: Streamline MapStatistics usage in MapNetworking
    - [lua] KS30 ODS Fix
    - Core: Use IPP as const&
    - Core: Refactor packet building in MapNetworking
    - Core: Move network cpp locals into class members
    - Core: Tidy up MapSocket

??? note "Friday · March 27, 2026"
    - Fix Ranged Weapon Rank
    - Core: Remove PacketMod system
    - Core: Move NetworkBuffer definition
    - Core: add operator== and hash to IPP
    - Add rewards to brigands chart
    - Mob fishable for brigands chart

??? note "Thursday · March 26, 2026"
    - [lua] Changed Valkurm Emperor to true lotto
    - [lua][module] ToAU mission era wait times

??? note "Tuesday · March 24, 2026"
    - [core] [lua] Load /check exp curve from lua
    - [tests] Adjust Sonic Boom Finish & mobs parrying/guarding tests
    - Brigand chart: Make chests fishable

??? note "Monday · March 23, 2026"
    - Spells cost,recast,levels audit
    - Update client spells and abilities after changing equip
    - [core] nullptr check for Rune Enhancement
    - Update synthesis skill up amount calculations

??? note "Sunday · March 22, 2026"
    - Yazquhl ws message placement fix
    - [lua] [sql] Follow the White Rabbit
    - Remove unused 'xi.ws' weaponskill alias
    - Enums for Mezzotinting exdata
    - 'WEAPONSKILL_USE' minor cleanup leftovers
    - Bundled augments enum and data
    - [trust] tuned AAEV/AAHM/Amchuchu and cleaned up scripts
    - Evolith data tables

??? note "Saturday · March 21, 2026"
    - Exdata enums for Evolith/Meeble
    - Core: Remove g_PTrigger legacy global
    - Core: Remove Scheduler::isTest helpers
    - Core: Add forced yields in ZoneServer cleanup steps
    - Core: Simplify ZMQ wrapper lifetimes
    - Modules: Fix issue with GM Horro
    - Enums and data for Pankration
    - Enums for Chocobo Racing/Raising, Mannequins
    - Add safety to spawn lists
    - Exdata supporting enums for Bonanza/Brenner/Escutcheons/Legion
    - [trust] AAHM: Added gambits/mods/tp usage

??? note "Friday · March 20, 2026"
    - Enum and data for Moblin Maze Mongers
