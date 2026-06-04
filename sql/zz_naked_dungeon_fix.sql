-- ---------------------------------------------------------------------------
-- zz_naked_dungeon_fix.sql
--
-- Static item_mods for 8 obtainable iLvl119 items that equipped with ZERO
-- stat bonus in the live DB. They were missed by BOTH existing fixers:
--   * gen_naked_item_stats.py only scans 4 catalogs; these are sold via
--     dungeon_catalog.lua, so they were never in its naked list.
--   * fix_missing_gear_mods.sql derives +4 from the _+3 tier by name; the
--     5 +4 pieces below have NO _+3 counterpart, so derivation skipped them.
--
-- Values parsed from tools/bgwiki_stats_cache.json with the same parser as
-- gen_naked_item_stats.py (parse_stats), so conventions match the other
-- zz_ files (e.g. Haste% stored x100: mod 384 = 700 -> 7%).
--
-- INSERT IGNORE + zz_ prefix: loads AFTER sql/item_mods.sql (which DROPs the
-- table) and never overwrites a pre-existing (itemId, modId) row.
--
-- NOTE: onion_sword_iii (21602) was intentionally OMITTED — the whole Onion
-- Sword line is naked by design (cf. sql/zz_rollback_fabricated_mods.sql);
-- its value is DMG/Delay/skill in item_weapon, not a stat block.
-- ---------------------------------------------------------------------------

LOCK TABLES `item_mods` WRITE;

-- 23911: laksamana_tricorne_+4 -- Reforge +4 (no _+3 parent → derivation skipped it)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Laksamana_Tricorne_%2B4
-- Raw: DEF:125 HP+74 STR+33 DEX+39 VIT+27 AGI+44 INT+30 MND+33 CHR+31 Ranged Accuracy+66 Magic Accuracy+66 Evasion+104 Magic Evasion+98 "Magic Def. Bonus"+4 Haste+8% ”Quick Draw"+20 Set: Accuracy+ Ranged Acc
-- Unparsed (WS/JA/set bonuses — not stored as mods): ”Quick Draw Set Accuracy Ranged Accuracy Magic Accuracy
INSERT IGNORE INTO `item_mods` VALUES (23911,384,800);    -- HASTE_GEAR: 8
INSERT IGNORE INTO `item_mods` VALUES (23911,29,4);    -- MDEF: 4
INSERT IGNORE INTO `item_mods` VALUES (23911,30,66);    -- MACC: 66
INSERT IGNORE INTO `item_mods` VALUES (23911,31,98);    -- MEVA: 98
INSERT IGNORE INTO `item_mods` VALUES (23911,26,66);    -- RACC: 66
INSERT IGNORE INTO `item_mods` VALUES (23911,68,104);    -- EVA: 104
INSERT IGNORE INTO `item_mods` VALUES (23911,1,125);    -- DEF: 125
INSERT IGNORE INTO `item_mods` VALUES (23911,2,74);    -- HP: 74
INSERT IGNORE INTO `item_mods` VALUES (23911,8,33);    -- STR: 33
INSERT IGNORE INTO `item_mods` VALUES (23911,9,39);    -- DEX: 39
INSERT IGNORE INTO `item_mods` VALUES (23911,10,27);    -- VIT: 27
INSERT IGNORE INTO `item_mods` VALUES (23911,11,44);    -- AGI: 44
INSERT IGNORE INTO `item_mods` VALUES (23911,12,30);    -- INT: 30
INSERT IGNORE INTO `item_mods` VALUES (23911,13,33);    -- MND: 33
INSERT IGNORE INTO `item_mods` VALUES (23911,14,31);    -- CHR: 31

-- 23956: laksamana_frac_+4 -- Reforge +4 (no _+3 parent → derivation skipped it)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Laksamana_Frac_%2B4
-- Raw: DEF:155 HP+108 MP+64 STR+39 DEX+44 VIT+31 AGI+50 INT+33 MND+36 CHR+33 Ranged Accuracy+67 Ranged Attack+40 Magic Accuracy+67 Evasion+109 Magic Evasion+109 "Magic Def. Bonus"+8 Haste+4% "Rapid Shot"+20 
-- Unparsed (WS/JA/set bonuses — not stored as mods): Recycle Set Accuracy Ranged Accuracy Magic Accuracy
INSERT IGNORE INTO `item_mods` VALUES (23956,384,400);    -- HASTE_GEAR: 4
INSERT IGNORE INTO `item_mods` VALUES (23956,359,20);    -- RAPID_SHOT: 20
INSERT IGNORE INTO `item_mods` VALUES (23956,29,8);    -- MDEF: 8
INSERT IGNORE INTO `item_mods` VALUES (23956,30,67);    -- MACC: 67
INSERT IGNORE INTO `item_mods` VALUES (23956,31,109);    -- MEVA: 109
INSERT IGNORE INTO `item_mods` VALUES (23956,26,67);    -- RACC: 67
INSERT IGNORE INTO `item_mods` VALUES (23956,24,40);    -- RATT: 40
INSERT IGNORE INTO `item_mods` VALUES (23956,68,109);    -- EVA: 109
INSERT IGNORE INTO `item_mods` VALUES (23956,1,155);    -- DEF: 155
INSERT IGNORE INTO `item_mods` VALUES (23956,2,108);    -- HP: 108
INSERT IGNORE INTO `item_mods` VALUES (23956,5,64);    -- MP: 64
INSERT IGNORE INTO `item_mods` VALUES (23956,8,39);    -- STR: 39
INSERT IGNORE INTO `item_mods` VALUES (23956,9,44);    -- DEX: 44
INSERT IGNORE INTO `item_mods` VALUES (23956,10,31);    -- VIT: 31
INSERT IGNORE INTO `item_mods` VALUES (23956,11,50);    -- AGI: 50
INSERT IGNORE INTO `item_mods` VALUES (23956,12,33);    -- INT: 33
INSERT IGNORE INTO `item_mods` VALUES (23956,13,36);    -- MND: 36
INSERT IGNORE INTO `item_mods` VALUES (23956,14,33);    -- CHR: 33
INSERT IGNORE INTO `item_mods` VALUES (23956,840,12);    -- ALL_WSDMG_ALL_HITS: 12

-- 24091: laksamana_bottes_+4 -- Reforge +4 (no _+3 parent → derivation skipped it)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Laksamana_Bottes_%2B4
-- Raw: DEF:95 HP+84 STR+22 DEX+39 VIT+20 AGI+54 MND+25 CHR+40 Ranged Accuracy+62 Magic Accuracy+62 Evasion+132 Magic Evasion+114 "Magic Def. Bonus"+7 Haste+4% ”Quick Draw"+20 Set: Accuracy+ Ranged Accuracy+ 
-- Unparsed (WS/JA/set bonuses — not stored as mods): ”Quick Draw Set Accuracy Ranged Accuracy Magic Accuracy
INSERT IGNORE INTO `item_mods` VALUES (24091,384,400);    -- HASTE_GEAR: 4
INSERT IGNORE INTO `item_mods` VALUES (24091,29,7);    -- MDEF: 7
INSERT IGNORE INTO `item_mods` VALUES (24091,30,62);    -- MACC: 62
INSERT IGNORE INTO `item_mods` VALUES (24091,31,114);    -- MEVA: 114
INSERT IGNORE INTO `item_mods` VALUES (24091,26,62);    -- RACC: 62
INSERT IGNORE INTO `item_mods` VALUES (24091,68,132);    -- EVA: 132
INSERT IGNORE INTO `item_mods` VALUES (24091,1,95);    -- DEF: 95
INSERT IGNORE INTO `item_mods` VALUES (24091,2,84);    -- HP: 84
INSERT IGNORE INTO `item_mods` VALUES (24091,8,22);    -- STR: 22
INSERT IGNORE INTO `item_mods` VALUES (24091,9,39);    -- DEX: 39
INSERT IGNORE INTO `item_mods` VALUES (24091,10,20);    -- VIT: 20
INSERT IGNORE INTO `item_mods` VALUES (24091,11,54);    -- AGI: 54
INSERT IGNORE INTO `item_mods` VALUES (24091,13,25);    -- MND: 25
INSERT IGNORE INTO `item_mods` VALUES (24091,14,40);    -- CHR: 40

-- 23992: ignominy_finger_gauntlets_+4 -- Reforge +4 (no _+3 parent → derivation skipped it)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Ignominy_Finger_Gauntlets_%2B4
-- Raw: DEF:129 HP+86 MP+42 STR+25 DEX+49 VIT+43 INT+18 MND+38 CHR+29 Accuracy+64 Attack+38 Magic Accuracy+64 Evasion+82 Magic Evasion+71 "Magic Def. Bonus"+3 Haste+4% "Skillchain Bonus" +10 "Weapon Bash"+16 
-- Unparsed (WS/JA/set bonuses — not stored as mods): Weapon Bash Weapon Bash Chain Bind Set Accuracy Ranged Accuracy Magic Accuracy
INSERT IGNORE INTO `item_mods` VALUES (23992,384,400);    -- HASTE_GEAR: 4
INSERT IGNORE INTO `item_mods` VALUES (23992,29,3);    -- MDEF: 3
INSERT IGNORE INTO `item_mods` VALUES (23992,30,64);    -- MACC: 64
INSERT IGNORE INTO `item_mods` VALUES (23992,31,71);    -- MEVA: 71
INSERT IGNORE INTO `item_mods` VALUES (23992,25,64);    -- ACC: 64
INSERT IGNORE INTO `item_mods` VALUES (23992,23,38);    -- ATT: 38
INSERT IGNORE INTO `item_mods` VALUES (23992,68,82);    -- EVA: 82
INSERT IGNORE INTO `item_mods` VALUES (23992,1,129);    -- DEF: 129
INSERT IGNORE INTO `item_mods` VALUES (23992,2,86);    -- HP: 86
INSERT IGNORE INTO `item_mods` VALUES (23992,5,42);    -- MP: 42
INSERT IGNORE INTO `item_mods` VALUES (23992,8,25);    -- STR: 25
INSERT IGNORE INTO `item_mods` VALUES (23992,9,49);    -- DEX: 49
INSERT IGNORE INTO `item_mods` VALUES (23992,10,43);    -- VIT: 43
INSERT IGNORE INTO `item_mods` VALUES (23992,12,18);    -- INT: 18
INSERT IGNORE INTO `item_mods` VALUES (23992,13,38);    -- MND: 38
INSERT IGNORE INTO `item_mods` VALUES (23992,14,29);    -- CHR: 29
INSERT IGNORE INTO `item_mods` VALUES (23992,174,10);    -- SKILLCHAINBONUS: 10

-- 24097: runeist_boots_+4 -- Reforge +4 (no _+3 parent → derivation skipped it)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Runeist_Boots_%2B4
-- Raw: DEF:100 HP+84 STR+22 DEX+37 VIT+22 AGI+52 MND+27 CHR+40 Accuracy+56 Magic Accuracy+56 Evasion+152 Magic Evasion+124 "Magic Def. Bonus"+7 Haste+4% "Pflug"+4 Set: Accuracy+ Ranged Accuracy+ Magic Accura
-- Unparsed (WS/JA/set bonuses — not stored as mods): Pflug Set Accuracy Ranged Accuracy Magic Accuracy
INSERT IGNORE INTO `item_mods` VALUES (24097,384,400);    -- HASTE_GEAR: 4
INSERT IGNORE INTO `item_mods` VALUES (24097,29,7);    -- MDEF: 7
INSERT IGNORE INTO `item_mods` VALUES (24097,30,56);    -- MACC: 56
INSERT IGNORE INTO `item_mods` VALUES (24097,31,124);    -- MEVA: 124
INSERT IGNORE INTO `item_mods` VALUES (24097,25,56);    -- ACC: 56
INSERT IGNORE INTO `item_mods` VALUES (24097,68,152);    -- EVA: 152
INSERT IGNORE INTO `item_mods` VALUES (24097,1,100);    -- DEF: 100
INSERT IGNORE INTO `item_mods` VALUES (24097,2,84);    -- HP: 84
INSERT IGNORE INTO `item_mods` VALUES (24097,8,22);    -- STR: 22
INSERT IGNORE INTO `item_mods` VALUES (24097,9,37);    -- DEX: 37
INSERT IGNORE INTO `item_mods` VALUES (24097,10,22);    -- VIT: 22
INSERT IGNORE INTO `item_mods` VALUES (24097,11,52);    -- AGI: 52
INSERT IGNORE INTO `item_mods` VALUES (24097,13,27);    -- MND: 27
INSERT IGNORE INTO `item_mods` VALUES (24097,14,40);    -- CHR: 40

-- 21646: caliburnus -- Dungeon shop Aeonic sword (out of BG-Wiki generator catalog scope)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Caliburnus_(Level_119_III)
-- Raw: DMG:181 Delay:233 DEX+35 MND+35 Accuracy+35 Attack+70 Magic Accuracy+35 Magic Damage+263 Sword skill +277 Parrying skill +277 Magic Accuracy skill +277 "Refresh"+4 Damage taken -10% Imperator Aftermat
-- Unparsed (WS/JA/set bonuses — not stored as mods): DMG Delay Magic Accuracy skill Imperator Aftermath Physical damage limit
INSERT IGNORE INTO `item_mods` VALUES (21646,160,-1000);    -- DMG: -10
INSERT IGNORE INTO `item_mods` VALUES (21646,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21646,311,263);    -- MAGIC_DAMAGE: 263
INSERT IGNORE INTO `item_mods` VALUES (21646,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21646,23,70);    -- ATT: 70
INSERT IGNORE INTO `item_mods` VALUES (21646,82,277);    -- SWORD: 277
INSERT IGNORE INTO `item_mods` VALUES (21646,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (21646,9,35);    -- DEX: 35
INSERT IGNORE INTO `item_mods` VALUES (21646,13,35);    -- MND: 35
INSERT IGNORE INTO `item_mods` VALUES (21646,369,4);    -- REFRESH: 4

-- 25603: jumalik_helm -- Dungeon shop hybrid helm (out of generator catalog scope)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Jumalik_Helm
-- Raw: DEF:120 HP+45 MP+29 STR+21 DEX+15 VIT+38 AGI+15 INT+8 MND+8 CHR+8 Magic Accuracy+20 Magic Damage+20 Evasion+30 Magic Evasion+53 "Magic Atk. Bonus"+20 "Magic Def. Bonus"+2 Divine magic skill +20 Physic
INSERT IGNORE INTO `item_mods` VALUES (25603,161,-500);    -- DMGPHYS: -5
INSERT IGNORE INTO `item_mods` VALUES (25603,384,700);    -- HASTE_GEAR: 7
INSERT IGNORE INTO `item_mods` VALUES (25603,29,2);    -- MDEF: 2
INSERT IGNORE INTO `item_mods` VALUES (25603,28,20);    -- MATT: 20
INSERT IGNORE INTO `item_mods` VALUES (25603,30,20);    -- MACC: 20
INSERT IGNORE INTO `item_mods` VALUES (25603,31,53);    -- MEVA: 53
INSERT IGNORE INTO `item_mods` VALUES (25603,311,20);    -- MAGIC_DAMAGE: 20
INSERT IGNORE INTO `item_mods` VALUES (25603,68,30);    -- EVA: 30
INSERT IGNORE INTO `item_mods` VALUES (25603,111,20);    -- DIVINE: 20
INSERT IGNORE INTO `item_mods` VALUES (25603,1,120);    -- DEF: 120
INSERT IGNORE INTO `item_mods` VALUES (25603,2,45);    -- HP: 45
INSERT IGNORE INTO `item_mods` VALUES (25603,5,29);    -- MP: 29
INSERT IGNORE INTO `item_mods` VALUES (25603,8,21);    -- STR: 21
INSERT IGNORE INTO `item_mods` VALUES (25603,9,15);    -- DEX: 15
INSERT IGNORE INTO `item_mods` VALUES (25603,10,38);    -- VIT: 38
INSERT IGNORE INTO `item_mods` VALUES (25603,11,15);    -- AGI: 15
INSERT IGNORE INTO `item_mods` VALUES (25603,12,8);    -- INT: 8
INSERT IGNORE INTO `item_mods` VALUES (25603,13,8);    -- MND: 8
INSERT IGNORE INTO `item_mods` VALUES (25603,14,8);    -- CHR: 8

-- 27637: evalach_+1 -- Dungeon shop PLD shield (out of generator catalog scope)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Evalach_%2B1
-- Raw: DEF:102 HP+22 MP+29 Attack+11 "Magic Atk. Bonus"+11 Shield skill +107 Enmity+6 Damage taken -4% Unity Ranking: MP+10~50
-- Unparsed (WS/JA/set bonuses — not stored as mods): Unity Ranking ~50
INSERT IGNORE INTO `item_mods` VALUES (27637,160,-400);    -- DMG: -4
INSERT IGNORE INTO `item_mods` VALUES (27637,28,11);    -- MATT: 11
INSERT IGNORE INTO `item_mods` VALUES (27637,23,11);    -- ATT: 11
INSERT IGNORE INTO `item_mods` VALUES (27637,27,6);    -- ENMITY: 6
INSERT IGNORE INTO `item_mods` VALUES (27637,109,107);    -- SHIELD: 107
INSERT IGNORE INTO `item_mods` VALUES (27637,1,102);    -- DEF: 102
INSERT IGNORE INTO `item_mods` VALUES (27637,2,22);    -- HP: 22
INSERT IGNORE INTO `item_mods` VALUES (27637,5,29);    -- MP: 29

UNLOCK TABLES;
