-- ---------------------------------------------------------------------------
-- zz_infamy_extra_mods.sql
--
-- Passive item_mods for endgame gear added to the Infamy Vendor that equipped
-- naked / under-statted. Parsed from tools/bgwiki_stats_cache.json with
-- parse_stats() AFTER trimming conditional/JA/pet/set/latent tails.
--
-- Hjarrandi Helm 25592 + Breastplate 25766 are the REAL pieces (the
-- 'Hjarrandi Tank' set previously pointed at 27637=evalach / 27718=worm_masque).
-- Brigantia's Mantle 26259 gets its DRG effects as real engine mods:
-- JUMP_DOUBLE_ATTACK (888) and WYVERN_BREATH (402). Vim Torque +1's Regain is
-- a weapon-drawn LATENT -> sql/zz_infamy_extra_latents.sql (only DEF here).
-- Sroda Earring 26118 audit fix: add its missing Double Attack+7%.
--
-- ON DUPLICATE KEY UPDATE: also repairs items that had a stray single mod
-- (Pteroslaver/Flamma from a broken +N derivation). zz_ prefix loads after
-- sql/item_mods.sql's DROP TABLE.
-- ---------------------------------------------------------------------------

LOCK TABLES `item_mods` WRITE;

-- 25592: Hjarrandi Helm (head)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Hjarrandi_Helm
-- Passive: DEF:125 HP+114 STR+32 DEX+21 VIT+44 AGI+16 INT+26 MND+29 CHR+38 Accuracy+41 Attack+45 Magic Accuracy+43 Evasion+38 Magic Evasion+53 "Magic Def. Bonus"+8 "Double Attack"+6% "Store TP"+7 Damage taken -1
INSERT INTO `item_mods` VALUES (25592,160,-1000) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DMG: -10
INSERT INTO `item_mods` VALUES (25592,288,6) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DOUBLE_ATTACK: 6
INSERT INTO `item_mods` VALUES (25592,73,7) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STORETP: 7
INSERT INTO `item_mods` VALUES (25592,29,8) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MDEF: 8
INSERT INTO `item_mods` VALUES (25592,30,43) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MACC: 43
INSERT INTO `item_mods` VALUES (25592,31,53) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MEVA: 53
INSERT INTO `item_mods` VALUES (25592,25,41) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- ACC: 41
INSERT INTO `item_mods` VALUES (25592,23,45) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- ATT: 45
INSERT INTO `item_mods` VALUES (25592,68,38) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- EVA: 38
INSERT INTO `item_mods` VALUES (25592,1,125) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEF: 125
INSERT INTO `item_mods` VALUES (25592,2,114) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- HP: 114
INSERT INTO `item_mods` VALUES (25592,8,32) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STR: 32
INSERT INTO `item_mods` VALUES (25592,9,21) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEX: 21
INSERT INTO `item_mods` VALUES (25592,10,44) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- VIT: 44
INSERT INTO `item_mods` VALUES (25592,11,16) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- AGI: 16
INSERT INTO `item_mods` VALUES (25592,12,26) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- INT: 26
INSERT INTO `item_mods` VALUES (25592,13,29) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MND: 29
INSERT INTO `item_mods` VALUES (25592,14,38) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- CHR: 38

-- 25766: Hjarrandi Breastplate (body)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Hjarrandi_Breastplate
-- Passive: DEF:155 HP+228 STR+38 DEX+24 VIT+51 AGI+19 INT+24 MND+29 CHR+35 Accuracy+47 Attack+53 Magic Accuracy+29 Evasion+47 Magic Evasion+69 Magic Def. Bonus+10 Store TP+10 Critical hit rate+13% Damage taken-1
INSERT INTO `item_mods` VALUES (25766,160,-1200) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DMG: -12
INSERT INTO `item_mods` VALUES (25766,73,10) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STORETP: 10
INSERT INTO `item_mods` VALUES (25766,165,13) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- CRITHITRATE: 13
INSERT INTO `item_mods` VALUES (25766,29,10) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MDEF: 10
INSERT INTO `item_mods` VALUES (25766,30,29) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MACC: 29
INSERT INTO `item_mods` VALUES (25766,31,69) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MEVA: 69
INSERT INTO `item_mods` VALUES (25766,25,47) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- ACC: 47
INSERT INTO `item_mods` VALUES (25766,23,53) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- ATT: 53
INSERT INTO `item_mods` VALUES (25766,68,47) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- EVA: 47
INSERT INTO `item_mods` VALUES (25766,1,155) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEF: 155
INSERT INTO `item_mods` VALUES (25766,2,228) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- HP: 228
INSERT INTO `item_mods` VALUES (25766,8,38) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STR: 38
INSERT INTO `item_mods` VALUES (25766,9,24) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEX: 24
INSERT INTO `item_mods` VALUES (25766,10,51) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- VIT: 51
INSERT INTO `item_mods` VALUES (25766,11,19) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- AGI: 19
INSERT INTO `item_mods` VALUES (25766,12,24) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- INT: 24
INSERT INTO `item_mods` VALUES (25766,13,29) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MND: 29
INSERT INTO `item_mods` VALUES (25766,14,35) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- CHR: 35

-- 24066: Pteroslaver Brais +4 (legs)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Pteroslaver_Brais_%2B4
-- Passive: DEF:145 HP+95 STR+48 DEX+22 VIT+46 AGI+25 INT+39 MND+26 CHR+22 Accuracy+44 Attack+74 Magic Accuracy+44 Evasion+67 Magic Evasion+135 "Magic Def. Bonus"+6 Haste+5% "Store TP"+10 "
INSERT INTO `item_mods` VALUES (24066,384,500) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (24066,73,10) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STORETP: 10
INSERT INTO `item_mods` VALUES (24066,29,6) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MDEF: 6
INSERT INTO `item_mods` VALUES (24066,30,44) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MACC: 44
INSERT INTO `item_mods` VALUES (24066,31,135) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MEVA: 135
INSERT INTO `item_mods` VALUES (24066,25,44) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- ACC: 44
INSERT INTO `item_mods` VALUES (24066,23,74) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- ATT: 74
INSERT INTO `item_mods` VALUES (24066,68,67) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- EVA: 67
INSERT INTO `item_mods` VALUES (24066,1,145) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEF: 145
INSERT INTO `item_mods` VALUES (24066,2,95) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- HP: 95
INSERT INTO `item_mods` VALUES (24066,8,48) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STR: 48
INSERT INTO `item_mods` VALUES (24066,9,22) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEX: 22
INSERT INTO `item_mods` VALUES (24066,10,46) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- VIT: 46
INSERT INTO `item_mods` VALUES (24066,11,25) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- AGI: 25
INSERT INTO `item_mods` VALUES (24066,12,39) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- INT: 39
INSERT INTO `item_mods` VALUES (24066,13,26) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MND: 26
INSERT INTO `item_mods` VALUES (24066,14,22) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- CHR: 22

-- 25953: Flamma Gambieras +2 (feet)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Flamma_Gambieras_%2B2
-- Passive: DEF:93 HP+40 MP+10 STR+31 DEX+34 VIT+20 AGI+26 MND+6 CHR+20 Accuracy+42 Magic Accuracy+42 Evasion+74 Magic Evasion+86 "Magic Def. Bonus"+5 Haste+2% "Double Attack"+6% "Store TP"+6
INSERT INTO `item_mods` VALUES (25953,384,200) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- HASTE_GEAR: 2
INSERT INTO `item_mods` VALUES (25953,288,6) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DOUBLE_ATTACK: 6
INSERT INTO `item_mods` VALUES (25953,73,6) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STORETP: 6
INSERT INTO `item_mods` VALUES (25953,29,5) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MDEF: 5
INSERT INTO `item_mods` VALUES (25953,30,42) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MACC: 42
INSERT INTO `item_mods` VALUES (25953,31,86) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MEVA: 86
INSERT INTO `item_mods` VALUES (25953,25,42) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- ACC: 42
INSERT INTO `item_mods` VALUES (25953,68,74) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- EVA: 74
INSERT INTO `item_mods` VALUES (25953,1,93) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEF: 93
INSERT INTO `item_mods` VALUES (25953,2,40) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- HP: 40
INSERT INTO `item_mods` VALUES (25953,5,10) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MP: 10
INSERT INTO `item_mods` VALUES (25953,8,31) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- STR: 31
INSERT INTO `item_mods` VALUES (25953,9,34) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEX: 34
INSERT INTO `item_mods` VALUES (25953,10,20) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- VIT: 20
INSERT INTO `item_mods` VALUES (25953,11,26) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- AGI: 26
INSERT INTO `item_mods` VALUES (25953,13,6) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- MND: 6
INSERT INTO `item_mods` VALUES (25953,14,20) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- CHR: 20

-- 26022: Vim Torque +1 (neck)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Vim_Torque_+1
-- Passive: DEF:15
INSERT INTO `item_mods` VALUES (26022,1,15) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEF: 15

-- 26259: Brigantia's Mantle (back)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Brigantia%27s_Mantle
-- Passive: DEF:18
INSERT INTO `item_mods` VALUES (26259,1,18) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DEF: 18
INSERT INTO `item_mods` VALUES (26259,888,20) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- JUMP_DOUBLE_ATTACK: 20 (All Jumps DA+20%)
INSERT INTO `item_mods` VALUES (26259,402,15) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- WYVERN_BREATH: 15

-- 26118: Sroda Earring -- AUDIT FIX: DB had only Evasion-10/Magic Eva-10
-- penalties and was MISSING the item's main stat. Adds Double Attack+7%.
INSERT INTO `item_mods` VALUES (26118,288,7) ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);    -- DOUBLE_ATTACK: 7

UNLOCK TABLES;
