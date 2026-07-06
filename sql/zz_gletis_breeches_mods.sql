-- Gleti's Breeches (23777) — implement retail stats (upstream TODO).
-- Re-runs every deploy (zz_ convention).

-- Fix item_equipment: set MId to 465 (Gleti set visual model).
REPLACE INTO `item_equipment` VALUES (23777,'gletis_breeches',99,119,303392,465,0,0,128,0,0,0);

-- Item mods (retail values).
REPLACE INTO `item_mods` VALUES (23777, 1, 165);     -- DEF
REPLACE INTO `item_mods` VALUES (23777, 2, 79);      -- HP
REPLACE INTO `item_mods` VALUES (23777, 8, 49);      -- STR
REPLACE INTO `item_mods` VALUES (23777, 10, 37);     -- VIT
REPLACE INTO `item_mods` VALUES (23777, 11, 23);     -- AGI
REPLACE INTO `item_mods` VALUES (23777, 12, 30);     -- INT
REPLACE INTO `item_mods` VALUES (23777, 13, 20);     -- MND
REPLACE INTO `item_mods` VALUES (23777, 14, 17);     -- CHR
REPLACE INTO `item_mods` VALUES (23777, 23, 40);     -- ATT
REPLACE INTO `item_mods` VALUES (23777, 25, 40);     -- ACC
REPLACE INTO `item_mods` VALUES (23777, 29, 14);     -- MDEF
REPLACE INTO `item_mods` VALUES (23777, 30, 40);     -- MACC
REPLACE INTO `item_mods` VALUES (23777, 31, 112);    -- MEVA
REPLACE INTO `item_mods` VALUES (23777, 68, 77);     -- EVA
REPLACE INTO `item_mods` VALUES (23777, 161, -800);  -- DMGPHYS: -8%
REPLACE INTO `item_mods` VALUES (23777, 165, 7);     -- CRITHITRATE
REPLACE INTO `item_mods` VALUES (23777, 368, 3);     -- REGAIN
REPLACE INTO `item_mods` VALUES (23777, 384, 500);   -- HASTE_GEAR: 5%
REPLACE INTO `item_mods` VALUES (23777, 1052, 5);    -- SIC_READY_RECAST: -5s
REPLACE INTO `item_mods` VALUES (23777, 1081, 8);    -- DAMAGE_LIMITP: 8%
