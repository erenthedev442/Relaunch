# Module ownership manifest

!!! note "Auto-generated — do not edit by hand"
    Regenerate with `python tools/module_audit.py`. Static scan of the
    auto-loaded `modules/custom/lua` tree. Implements the collision checks
    from the 2026-07-04 source/module audit.

## Hard problems

None. No duplicate entity names per zone and no un-allow-listed `xi.* = function` replacements.

## Override-target census (multiple writers)

Deep chains are not inherently bugs — most are legitimate `super()` chains — but every target with >1 writer is listed so overlap is visible.

| Target | Writers | Files |
|---|---:|---|
| `xi.player.onGameIn` | 28 | `AbysseaKICleanup.lua`, `announce_player_login.lua`, `Ascension_Companion.lua`, `blu_spell_progression.lua`, `Character_Upgrader.lua`, `combat_records.lua`, `CrossJob_TraitTrainer.lua`, `daily_login_bonus.lua`, `DualWieldPersist.lua`, `fellow_companion.lua`, `JobRebirth.lua`, `login_streak.lua`, `master_star_color.lua`, `new_player_starter.lua`, `online_tracker.lua`, `open_mog_containers.lua`, `Paragon.lua`, `Prestige_System.lua`, `RealLevel_Tracker.lua`, `RngOverhaul.lua`, `SpellSkillMastery.lua`, `subjob_exp_share.lua`, `trust_auto_attack_rearm.lua`, `unlock_adoulin_jobs.lua`, `unlock_progression_keyitems.lua`, `Voidwatch.lua`, `weekly_recap.lua`, `WSTracker.lua` |
| `xi.zones.Leafallia.Zone.onInitialize` | 16 | `ApexTrials.lua`, `Augment_Moogle.lua`, `CrossJob_Trainer.lua`, `CrossJob_TraitTrainer.lua`, `endless_tower.lua`, `HTBF_Vendor.lua`, `InfamyVendor.lua`, `job_mastery.lua`, `Paragon.lua`, `PrimeArmory_NPC.lua`, `Relic_Forge.lua`, `SpellSkillMastery.lua`, `TheGauntlet.lua`, `trust_skoll.lua`, `Voidwatch.lua`, `WeaponForge_NPC.lua` |
| `xi.player.onPlayerDeath` | 13 | `ApexTrials.lua`, `Colosseum.lua`, `death_penalty.lua`, `endless_tower.lua`, `GameMaster.lua`, `invasion_reraise.lua`, `job_mastery.lua`, `TheGauntlet.lua`, `Tournament.lua`, `Voidspire.lua`, `Voidwatch.lua`, `weekly_hunts.lua`, `world_first_announcements.lua` |
| `xi.zones.Celennia_Memorial_Library.Zone.onInitialize` | 11 | `Casino.lua`, `Cosmetic_Shop.lua`, `gil_exchange_npc.lua`, `gil_mystery_box.lua`, `gil_race_changer.lua`, `gil_title_vendor.lua`, `gil_warp_npc.lua`, `gm_home_homepoint.lua`, `SparksExchange.lua`, `unity_wanted.lua`, `UnityWantedInstances.lua` |
| `xi.mob.onMobDeathEx` | 8 | `abyssea_su5_drops.lua`, `allied_notes_drop.lua`, `alzahbi_loot.lua`, `augment_catalyst_drops.lua`, `fellow_companion.lua`, `mob_seal_drops.lua`, `SpellSkillMastery.lua`, `world_first_announcements.lua` |
| `xi.pet.spawnPet` | 4 | `BstJugPetOverhaul.lua`, `combat_records.lua`, `smn_avatar_boost.lua`, `WSTracker.lua` |
| `xi.player.charCreate` | 3 | `new_char_starter_marks.lua`, `new_char_wardrobe_sizes.lua`, `new_player_linkshell.lua` |
| `xi.player.onPlayerLevelUp` | 3 | `blu_spell_progression.lua`, `level_99_tracker.lua`, `world_first_announcements.lua` |
| `xi.trust.canCast` | 3 | `TheGauntlet.lua`, `Tournament.lua`, `trust_progression_cap.lua` |
| `xi.gear_sets.checkForGearSet` | 2 | `JobRebirth.lua`, `Prestige_System.lua` |
| `xi.server.onServerStart` | 2 | `chocobo_raising_qol.lua`, `quest_workarounds.lua` |
| `xi.zones.Escha_ZiTah.Zone.onInitialize` | 2 | `Geas_Fete.lua`, `leaderboard_npc.lua` |
| `xi.zones.Escha_ZiTah.Zone.onZoneIn` | 2 | `auto_buff_henge.lua`, `unity_wanted.lua` |
| `xi.zones.RuLude_Gardens.Zone.onInitialize` | 2 | `JobRebirth.lua`, `maat_infamy_fight.lua` |
| `xi.zones.Walk_of_Echoes.Zone.onZoneIn` | 2 | `endless_tower.lua`, `job_mastery.lua` |

## Direct `xi.*` function assignments

`self` = the file declares this namespace (definition, fine). `allow` = explicitly allow-listed replacement. **patch** = assigns into a namespace it doesn't own (review).

| Target | File | Kind |
|---|---|:--:|
| `xi.abyssea.marksPopHook` | `modules/custom/lua/AbysseaMarks.lua`:178 | allow |
| `xi.combat.ranged.accuracyDistancePenalty` | `modules/custom/lua/ranged_no_distance_penalty.lua`:7 | allow |
| `xi.combat.ranged.attackDistancePenalty` | `modules/custom/lua/ranged_no_distance_penalty.lua`:6 | allow |
| `xi.fellow.addXp` | `modules/custom/lua/fellow_companion.lua`:885 | self |
| `xi.fellow.debug` | `modules/custom/lua/fellow_companion.lua`:891 | self |
| `xi.fellow.dismiss` | `modules/custom/lua/fellow_companion.lua`:883 | self |
| `xi.fellow.grantPoints` | `modules/custom/lua/fellow_companion.lua`:886 | self |
| `xi.fellow.openMenu` | `modules/custom/lua/fellow_companion.lua`:881 | self |
| `xi.fellow.status` | `modules/custom/lua/fellow_companion.lua`:884 | self |
| `xi.fellow.summon` | `modules/custom/lua/fellow_companion.lua`:882 | self |
| `xi.mob.marksRewardHook` | `modules/custom/lua/AbysseaMarks.lua`:228 | allow |
| `xi.spellSkillMastery.balance` | `modules/custom/lua/SpellSkillMastery.lua`:57 | self |
| `xi.spellSkillMastery.grant` | `modules/custom/lua/SpellSkillMastery.lua`:56 | self |
| `xi.spellSkillMastery.report` | `modules/custom/lua/SpellSkillMastery.lua`:387 | self |
| `xi.unity.onTrigger` | `modules/custom/lua/unity_wanted.lua`:395 | self |
| `xi.voidwatch.grantCruor` | `modules/custom/lua/Voidwatch.lua`:637 | self |
| `xi.voidwatch.grantShards` | `modules/custom/lua/Voidwatch.lua`:638 | self |
| `xi.voidwatch.menu` | `modules/custom/lua/Voidwatch.lua`:632 | self |
| `xi.voidwatch.open` | `modules/custom/lua/Voidwatch.lua`:633 | self |
| `xi.voidwatch.refiner` | `modules/custom/lua/Voidwatch.lua`:636 | self |
| `xi.voidwatch.reveal` | `modules/custom/lua/Voidwatch.lua`:635 | self |
| `xi.voidwatch.status` | `modules/custom/lua/Voidwatch.lua`:634 | self |

## Per-file ownership

| File | Override targets | Entity names (zone:name) | CharVars |
|---|---:|---|---|
| `AbysseaKICleanup.lua` | 1 | — | — |
| `Accessory_NPC.lua` | 0 | `?:Accessory_NPC` | — |
| `ApexTrials.lua` | 3 | `Leafallia:Apex_Arbiter` | — |
| `Armor_NPC.lua` | 0 | `?:Armor_NPC` | — |
| `Ascension_Companion.lua` | 1 | — | — |
| `Augment_Moogle.lua` | 1 | `Leafallia:Augment_Moogle` | — |
| `Augment_Sage.lua` | 0 | `?:Augment_Sage` | — |
| `BstJugPetOverhaul.lua` | 1 | — | — |
| `Casino.lua` | 1 | `Celennia_Memorial_Library:Casino_LadyLuck` | — |
| `Character_Upgrader.lua` | 2 | — | — |
| `ChocoboDerby.lua` | 0 | `?:Race_Caller` | — |
| `Colosseum.lua` | 1 | `?:Arena_Herald` | — |
| `Cosmetic_Shop.lua` | 1 | `Celennia_Memorial_Library:Cosmetic_Boutique` | — |
| `CrossJob_Trainer.lua` | 1 | `Leafallia:CrossJob_Trainer` | — |
| `CrossJob_TraitTrainer.lua` | 2 | `Leafallia:CrossJob_TraitTrainer` | — |
| `Divergence_Reforger.lua` | 1 | `Southern_San_dOria:Divergence_Smith` | — |
| `DualWieldPersist.lua` | 1 | — | — |
| `DungeonInstances.lua` | 0 | `?:Dungeon_Guide` | — |
| `Dynamis_Divergence.lua` | 0 | `?:Divergence_Portal` | — |
| `GameMaster.lua` | 1 | `?:Game_Master` | — |
| `GearProgression_NPC.lua` | 0 | `?:Weapons_NPC` | — |
| `Geas_Fete.lua` | 2 | — | — |
| `HTBF_Vendor.lua` | 1 | `Leafallia:HTBF_Gem_Vendor` | — |
| `HuntingLeague.lua` | 0 | `?:HuntingLeague_ZoneGuide`, `?:HuntingLeague_Seals`, `?:HuntingLeague_Accessories` | — |
| `InfamyVendor.lua` | 1 | `Leafallia:Infamy_Vendor` | — |
| `JobRebirth.lua` | 3 | `RuLude_Gardens:JobRebirth_Altar` | — |
| `Paragon.lua` | 2 | `Leafallia:Paragon_Sage` | — |
| `Prestige_System.lua` | 2 | `?:Ascension_Altar`, `?:Ascension_Altar_2`, `?:Ascension_Altar_3` | — |
| `PrimeArmory_NPC.lua` | 1 | `Leafallia:Prime_Armory` | — |
| `ProvisionersLeague.lua` | 0 | `?:League_Steward` | — |
| `RaidBoss.lua` | 0 | `?:Voidgate_Sentinel` | — |
| `RealLevel_Tracker.lua` | 1 | — | — |
| `Reforge_System.lua` | 0 | `?:Reforge_Spawner`, `?:Reforge_Vendor` | — |
| `Relic_Forge.lua` | 1 | `Leafallia:Relic_Forge` | — |
| `RngOverhaul.lua` | 1 | — | — |
| `SparksExchange.lua` | 1 | `Celennia_Memorial_Library:Sparks_Exchange` | — |
| `SpellSkillMastery.lua` | 3 | `Leafallia:Spell_Mastery_Sage` | — |
| `Temprix_NPC.lua` | 1 | `Reisenjima:Temprix` | — |
| `TestDummy.lua` | 0 | `?:Test_Dummy` | — |
| `TheGauntlet.lua` | 25 | `Leafallia:Gauntlet_Keeper` | — |
| `Tournament.lua` | 3 | — | — |
| `UnityWantedInstances.lua` | 1 | `Celennia_Memorial_Library:Unity_Instance_Board` | — |
| `Voidspire.lua` | 1 | `?:Voidspire_Warden` | — |
| `Voidwatch.lua` | 4 | `?:Riftworn_Pyxis`, `Leafallia:Voidwatch_Officer`, `Leafallia:Planar_Rift` | — |
| `WSTracker.lua` | 2 | — | — |
| `WeaponForge_NPC.lua` | 1 | `Leafallia:Weapon_Forger` | — |
| `abyssea_su5_drops.lua` | 1 | — | — |
| `allied_notes_drop.lua` | 1 | — | — |
| `alzahbi_loot.lua` | 1 | — | — |
| `announce_player_login.lua` | 1 | — | — |
| `augment_affinity_grants.lua` | 19 | — | — |
| `augment_catalyst_drops.lua` | 1 | — | — |
| `auto_buff_henge.lua` | 1 | — | — |
| `barrage_tuning.lua` | 1 | — | — |
| `block_curilla_retail_grant.lua` | 1 | — | — |
| `block_meat_retail_grant.lua` | 1 | — | — |
| `block_nanaa_retail_grant.lua` | 1 | — | — |
| `blu_spell_progression.lua` | 2 | — | — |
| `bp_delay_uncap.lua` | 1 | — | — |
| `bst_delay_uncap.lua` | 1 | — | — |
| `chocobo_raising_qol.lua` | 1 | — | — |
| `combat_records.lua` | 2 | — | — |
| `conquest_regional_npcs_always_up.lua` | 1 | — | — |
| `custom_HNM_system.lua` | 19 | — | — |
| `daily_board.lua` | 0 | `?:Daily_Board` | `Done`, `ObjIdx` |
| `daily_login_bonus.lua` | 1 | — | — |
| `death_penalty.lua` | 1 | — | — |
| `disable_zonein_cutscenes.lua` | 1 | — | — |
| `endless_tower.lua` | 3 | `Leafallia:Tower_Arbiter` | — |
| `enhancing_magic_double_duration.lua` | 1 | — | — |
| `fellow_companion.lua` | 2 | — | — |
| `garrison_placeholder_data.lua` | 1 | — | — |
| `gil_exchange_npc.lua` | 1 | `Celennia_Memorial_Library:Gil_Exchange` | — |
| `gil_mystery_box.lua` | 1 | `Celennia_Memorial_Library:Mystery_Mog` | — |
| `gil_race_changer.lua` | 1 | `Celennia_Memorial_Library:Race_Changer` | — |
| `gil_title_vendor.lua` | 1 | `Celennia_Memorial_Library:Title_Broker` | — |
| `gil_warp_npc.lua` | 1 | — | — |
| `gm_home_homepoint.lua` | 1 | `Celennia_Memorial_Library:Home_Point` | — |
| `homepoint_heal.lua` | 1 | — | — |
| `invasion_reraise.lua` | 1 | — | — |
| `job_mastery.lua` | 3 | `Leafallia:Weapon_Mastery_Sage` | — |
| `leaderboard_npc.lua` | 1 | `Escha_ZiTah:The Chronicler` | — |
| `level_99_tracker.lua` | 1 | — | — |
| `login_streak.lua` | 1 | — | — |
| `maat_infamy_fight.lua` | 2 | `?:Maat`, `RuLude_Gardens:Maat_Echo` | — |
| `master_star_color.lua` | 1 | — | — |
| `mob_mechanics_library.lua` | 0 | `?:Boss Name` | — |
| `mob_seal_drops.lua` | 1 | — | — |
| `moghouse_exit_reconcile.lua` | 1 | — | — |
| `new_char_starter_marks.lua` | 2 | — | — |
| `new_char_wardrobe_sizes.lua` | 1 | — | — |
| `new_player_linkshell.lua` | 1 | — | — |
| `new_player_starter.lua` | 1 | — | — |
| `online_tracker.lua` | 1 | — | — |
| `open_mog_containers.lua` | 1 | — | — |
| `quest_workarounds.lua` | 1 | — | — |
| `smn_avatar_boost.lua` | 1 | — | — |
| `smn_avatar_equalize.lua` | 3 | — | — |
| `soa_remove_imprimatur_gate.lua` | 1 | — | — |
| `subjob_exp_share.lua` | 1 | — | — |
| `trust_auto_attack_rearm.lua` | 1 | — | — |
| `trust_progression_cap.lua` | 1 | — | — |
| `trust_skoll.lua` | 3 | — | — |
| `unity_trust_fix.lua` | 1 | — | — |
| `unity_wanted.lua` | 2 | `Celennia_Memorial_Library:Unity_Wanted_Board` | — |
| `unity_wanted_catalog.lua` | 0 | `?:Display Name` | — |
| `unlimited_visitant.lua` | 2 | — | — |
| `unlock_adoulin_jobs.lua` | 1 | — | — |
| `unlock_progression_keyitems.lua` | 1 | — | — |
| `weekly_hunts.lua` | 1 | `?:Hunt_Board` | `AltProg`, `Done`, `Idx`, `Prog` |
| `weekly_recap.lua` | 1 | — | — |
| `world_boss.lua` | 2 | — | — |
| `world_first_announcements.lua` | 5 | — | — |

