-- zz_aeonic_weapon_mods.sql
-- Missing mod entries for the 16 final-stage Aeonic weapons, sourced from BG Wiki.
-- INSERT IGNORE: safe to re-apply (PRIMARY KEY on itemId+modId prevents duplicates).
--
-- Magic Damage tiers (weapon type → value):
--   T1 +155 : H2H / Dagger / Axe / GAxe / Polearm / GKatana / Bow / Gun
--   T2 +186 : Sword / GS / Scythe / Katana / Club (RDM/PLD/BLU)
--   T3 +217 : Club for WHM/GEO (Tishtrya)
--   T4 +279 : Staff for BLM/SMN/SCH (Khatvanga)

-- ── Tishtrya (21082, WHM/GEO Club) ── no mods exist upstream
INSERT IGNORE INTO `item_mods` VALUES (21082, 73,  10);  -- Store TP+10
INSERT IGNORE INTO `item_mods` VALUES (21082, 311, 217); -- Magic Damage+217
INSERT IGNORE INTO `item_mods` VALUES (21082, 345, 500); -- TP Bonus+500

-- ── Missing MAGIC_DAMAGE (mod 311) on weapons that have other mods upstream ──

-- T1 (+155)
INSERT IGNORE INTO `item_mods` VALUES (20843, 311, 155); -- Chango            (WAR  Great Axe)
INSERT IGNORE INTO `item_mods` VALUES (20935, 311, 155); -- Trishula          (DRG  Polearm)
INSERT IGNORE INTO `item_mods` VALUES (21025, 311, 155); -- Dojikiri Yasutsuna (SAM  Great Katana)
INSERT IGNORE INTO `item_mods` VALUES (21485, 311, 155); -- Fomalhaut         (RNG/COR  Gun)
INSERT IGNORE INTO `item_mods` VALUES (21753, 311, 155); -- Tri-edge          (BST  Dagger)

-- T2 (+186)
INSERT IGNORE INTO `item_mods` VALUES (20890, 311, 186); -- Anguta            (DRK  Scythe)

-- T4 (+279)
INSERT IGNORE INTO `item_mods` VALUES (21147, 311, 279); -- Khatvanga         (BLM/SMN/SCH  Staff)

-- ── Marsyas (21398, BRD Wind Instrument) ── missing Store TP + TP Bonus
INSERT IGNORE INTO `item_mods` VALUES (21398, 73,  10);  -- Store TP+10
INSERT IGNORE INTO `item_mods` VALUES (21398, 345, 500); -- TP Bonus+500
