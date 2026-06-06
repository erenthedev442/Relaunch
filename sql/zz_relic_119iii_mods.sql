-- ---------------------------------------------------------------------------
-- zz_relic_119iii_mods.sql
--
-- Passive stat blocks for Stage-5 (Level 119 III) Relic final-forms sold by
-- the Infamy Vendor (dungeon_catalog.lua). These equipped NAKED in the live
-- DB (no item_mods); base DMG/Delay already live in item_weapon.
--
-- Values parsed from tools/bgwiki_stats_cache.json with parse_stats() (same
-- parser as gen_naked_item_stats.py), AFTER trimming each string at the first
-- Pet/Wyvern/Avatar/Scavenge/Aftermath marker so only the PASSIVE block is
-- read (else the parser grabs pet/aftermath numbers, e.g. a Ranged Accuracy
-- from Spalirisos's pet line onto an axe). Great-weapon skills are remapped
-- to GSWORD/GAXE/GKATANA (the shared parser matches the non-"Great" rule
-- first -- a known quirk worked around here, not in the live cache).
--
-- NOT represented (by design): relic Aftermath (scripted), "Physical damage
-- limit+", "Magic Accuracy skill+", Duban's status-ailment-res + Magic-dmg-
-- taken-II. Loughnashade's "All songs +4" -> ALL_SONGS_EFFECT (mod 452);
-- its item_equipment row is also ilvl 0 (see dungeon_catalog note).
--
-- Already implemented elsewhere, intentionally NOT here:
--   Varga Purnikawa (21535) & Mpu Gandring (21590) -> sql/item_mods.sql
--   Caliburnus (21646)                             -> sql/zz_naked_dungeon_fix.sql
--
-- INSERT IGNORE + zz_ prefix: loads AFTER sql/item_mods.sql's DROP TABLE and
-- never overwrites a pre-existing (itemId, modId) row.
-- ---------------------------------------------------------------------------

LOCK TABLES `item_mods` WRITE;

-- 21653: Helheim (Great Sword) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Helheim_(Level_119_II)
-- Passive: DMG:318 Delay:431 STR+30 VIT+30 Accuracy+30 Magic Accuracy+30 Great Sword skill +269 Parrying skill +269 Magic Accuracy skill +269 "Store TP"+7 Fimbulvetr
INSERT IGNORE INTO `item_mods` VALUES (21653,73,7);    -- STORETP: 7
INSERT IGNORE INTO `item_mods` VALUES (21653,30,30);    -- MACC: 30
INSERT IGNORE INTO `item_mods` VALUES (21653,25,30);    -- ACC: 30
INSERT IGNORE INTO `item_mods` VALUES (21653,83,269);    -- GSWORD: 269
INSERT IGNORE INTO `item_mods` VALUES (21653,110,269);    -- PARRY: 269
INSERT IGNORE INTO `item_mods` VALUES (21653,8,30);    -- STR: 30
INSERT IGNORE INTO `item_mods` VALUES (21653,10,30);    -- VIT: 30

-- 21730: Spalirisos (Axe) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Spalirisos_(Level_119_III)
-- Passive: DMG:218 Delay:280 STR+35 DEX+35 CHR+35 Accuracy+35 Magic Accuracy+35 Axe skill +277 Parrying skill +277 Magic Accuracy skill +277 Critical hit rate +15%
INSERT IGNORE INTO `item_mods` VALUES (21730,165,15);    -- CRITHITRATE: 15
INSERT IGNORE INTO `item_mods` VALUES (21730,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21730,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21730,84,277);    -- AXE: 277
INSERT IGNORE INTO `item_mods` VALUES (21730,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (21730,8,35);    -- STR: 35
INSERT IGNORE INTO `item_mods` VALUES (21730,9,35);    -- DEX: 35
INSERT IGNORE INTO `item_mods` VALUES (21730,14,35);    -- CHR: 35

-- 21785: Laphria (Great Axe) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Laphria_(Level_119_III)
-- Passive: DMG:380 Delay:488 STR+35 VIT+35 Accuracy+35 Magic Accuracy+35 Great Axe skill +277 Parrying skill +277 Magic Accuracy skill +277 "Double Attack"+10% Disaster
INSERT IGNORE INTO `item_mods` VALUES (21785,288,10);    -- DOUBLE_ATTACK: 10
INSERT IGNORE INTO `item_mods` VALUES (21785,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21785,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21785,85,277);    -- GAXE: 277
INSERT IGNORE INTO `item_mods` VALUES (21785,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (21785,8,35);    -- STR: 35
INSERT IGNORE INTO `item_mods` VALUES (21785,10,35);    -- VIT: 35

-- 21837: Foenaria (Scythe) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Foenaria_(Level_119_III)
-- Passive: DMG:400 Delay:513 STR+35 INT+35 Accuracy+35 Magic Accuracy+35 Scythe skill +277 Parrying skill +277 Magic Accuracy skill +277 "Triple Attack"+6% Origin
INSERT IGNORE INTO `item_mods` VALUES (21837,302,6);    -- TRIPLE_ATTACK: 6
INSERT IGNORE INTO `item_mods` VALUES (21837,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21837,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21837,86,277);    -- SCYTHE: 277
INSERT IGNORE INTO `item_mods` VALUES (21837,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (21837,8,35);    -- STR: 35
INSERT IGNORE INTO `item_mods` VALUES (21837,12,35);    -- INT: 35

-- 21891: Gae Buide (Polearm) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Gae_Buide_(Level_119_III)
-- Passive: DMG:383 Delay:492 STR+35 VIT+35 Accuracy+35 Magic Accuracy+35 Polearm skill +277 Parrying skill +277 Magic Accuracy skill +277 "Double Attack"+10%
INSERT IGNORE INTO `item_mods` VALUES (21891,288,10);    -- DOUBLE_ATTACK: 10
INSERT IGNORE INTO `item_mods` VALUES (21891,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21891,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21891,87,277);    -- POLEARM: 277
INSERT IGNORE INTO `item_mods` VALUES (21891,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (21891,8,35);    -- STR: 35
INSERT IGNORE INTO `item_mods` VALUES (21891,10,35);    -- VIT: 35

-- 21932: Dokoku (Katana) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Dokoku_(Level_119_III)
-- Passive: DMG:163 Delay:210 DEX+35 AGI+35 Accuracy+35 Magic Accuracy+35 Magic Damage+263 Katana skill +277 Parrying skill +277 Magic Accuracy skill +277 "Store TP"+10 Zesho Meppo
INSERT IGNORE INTO `item_mods` VALUES (21932,73,10);    -- STORETP: 10
INSERT IGNORE INTO `item_mods` VALUES (21932,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21932,311,263);    -- MAGIC_DAMAGE: 263
INSERT IGNORE INTO `item_mods` VALUES (21932,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21932,88,277);    -- KATANA: 277
INSERT IGNORE INTO `item_mods` VALUES (21932,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (21932,9,35);    -- DEX: 35
INSERT IGNORE INTO `item_mods` VALUES (21932,11,35);    -- AGI: 35

-- 21986: Kusanagi (Great Katana) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Kusanagi_(Level_119_III)
-- Passive: DMG:340 Delay:437 STR+35 DEX+35 Accuracy+35 Magic Accuracy+35 Great Katana skill +277 Parrying skill +277 Magic Accuracy skill +277 "Double Attack"+10%
INSERT IGNORE INTO `item_mods` VALUES (21986,288,10);    -- DOUBLE_ATTACK: 10
INSERT IGNORE INTO `item_mods` VALUES (21986,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21986,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (21986,89,277);    -- GKATANA: 277
INSERT IGNORE INTO `item_mods` VALUES (21986,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (21986,8,35);    -- STR: 35
INSERT IGNORE INTO `item_mods` VALUES (21986,9,35);    -- DEX: 35

-- 22002: Lorg Mor (Club) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Lorg_Mor_(Level_119_II)
-- Passive: DMG:227 Delay:308 STR+30 MND+30 Accuracy+30 Magic Accuracy+30 "Magic Atk. Bonus"+50 Magic Damage+248 Club skill +269 Parrying skill +269 Magic Accuracy skill +269 "Regen"+6 Damage taken -7% Dagda
INSERT IGNORE INTO `item_mods` VALUES (22002,160,-700);    -- DMG: -7
INSERT IGNORE INTO `item_mods` VALUES (22002,28,50);    -- MATT: 50
INSERT IGNORE INTO `item_mods` VALUES (22002,30,30);    -- MACC: 30
INSERT IGNORE INTO `item_mods` VALUES (22002,311,248);    -- MAGIC_DAMAGE: 248
INSERT IGNORE INTO `item_mods` VALUES (22002,25,30);    -- ACC: 30
INSERT IGNORE INTO `item_mods` VALUES (22002,90,269);    -- CLUB: 269
INSERT IGNORE INTO `item_mods` VALUES (22002,110,269);    -- PARRY: 269
INSERT IGNORE INTO `item_mods` VALUES (22002,8,30);    -- STR: 30
INSERT IGNORE INTO `item_mods` VALUES (22002,13,30);    -- MND: 30
INSERT IGNORE INTO `item_mods` VALUES (22002,370,6);    -- REGEN: 6

-- 22106: Opashoro (Staff) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Opashoro_(Level_119_III)
-- Passive: DMG:304 Delay:390 INT+35 MND+35 Accuracy+35 Magic Accuracy+35 "Magic Atk. Bonus"+80 Magic Damage+325 Staff skill +277 Parrying skill +277 Magic Accuracy skill +277
INSERT IGNORE INTO `item_mods` VALUES (22106,28,80);    -- MATT: 80
INSERT IGNORE INTO `item_mods` VALUES (22106,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (22106,311,325);    -- MAGIC_DAMAGE: 325
INSERT IGNORE INTO `item_mods` VALUES (22106,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (22106,91,277);    -- STAFF: 277
INSERT IGNORE INTO `item_mods` VALUES (22106,110,277);    -- PARRY: 277
INSERT IGNORE INTO `item_mods` VALUES (22106,12,35);    -- INT: 35
INSERT IGNORE INTO `item_mods` VALUES (22106,13,35);    -- MND: 35

-- 22163: Pinaka (Archery) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Pinaka_(Level_119_III)
-- Passive: DMG:324 Delay:524 STR+35 AGI+35 Accuracy+35 Magic Accuracy+35 Archery skill +277 "Store TP"+10
INSERT IGNORE INTO `item_mods` VALUES (22163,73,10);    -- STORETP: 10
INSERT IGNORE INTO `item_mods` VALUES (22163,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (22163,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (22163,104,277);    -- ARCHERY: 277
INSERT IGNORE INTO `item_mods` VALUES (22163,8,35);    -- STR: 35
INSERT IGNORE INTO `item_mods` VALUES (22163,11,35);    -- AGI: 35

-- 22164: Earp (Marksmanship) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Earp_(Level_119_III)
-- Passive: DMG:162 Delay:582 DEX+35 AGI+35 Accuracy+35 Magic Accuracy+35 Marksmanship skill +277 Critical hit rate +15%
INSERT IGNORE INTO `item_mods` VALUES (22164,165,15);    -- CRITHITRATE: 15
INSERT IGNORE INTO `item_mods` VALUES (22164,30,35);    -- MACC: 35
INSERT IGNORE INTO `item_mods` VALUES (22164,25,35);    -- ACC: 35
INSERT IGNORE INTO `item_mods` VALUES (22164,105,277);    -- MARKSMAN: 277
INSERT IGNORE INTO `item_mods` VALUES (22164,9,35);    -- DEX: 35
INSERT IGNORE INTO `item_mods` VALUES (22164,11,35);    -- AGI: 35

-- 26495: Duban (Shield) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Duban_(Level_119_II)
-- Passive: DEF:150 VIT+30 MND+30 Evasion+30 Magic Evasion+30 Shield skill +129 All status ailment resistance +15 Magic damage taken II -20%
INSERT IGNORE INTO `item_mods` VALUES (26495,31,30);    -- MEVA: 30
INSERT IGNORE INTO `item_mods` VALUES (26495,68,30);    -- EVA: 30
INSERT IGNORE INTO `item_mods` VALUES (26495,109,129);    -- SHIELD: 129
INSERT IGNORE INTO `item_mods` VALUES (26495,1,150);    -- DEF: 150
INSERT IGNORE INTO `item_mods` VALUES (26495,10,30);    -- VIT: 30
INSERT IGNORE INTO `item_mods` VALUES (26495,13,30);    -- MND: 30

-- 22307: Loughnashade (Horn) -- Relic 119 III passive block (Aftermath = scripted, omitted)
-- BG-Wiki: https://www.bg-wiki.com/ffxi/Loughnashade_(Level_119_III)
-- Passive: DMG:0 Delay:0 CHR+20 All songs +4 Aria of Passion
INSERT IGNORE INTO `item_mods` VALUES (22307,14,20);    -- CHR: 20
INSERT IGNORE INTO `item_mods` VALUES (22307,452,4);    -- ALL_SONGS_EFFECT: 4

UNLOCK TABLES;
