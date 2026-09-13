-- ============================================================================
-- bst_beast_affinity_augment.sql
-- Adds Beast Affinity (augmentId 2100) to the augments table.
--
-- Effect: grants PET_BEAST_AFF (mod 1200) to the BST wearing the gear.
--   BstJugPetOverhaul.lua reads PET_BEAST_AFF from the master and applies it
--   as a % multiplier to all flat pet-stat bonuses at spawn.
--   100 points = +100% to all CONFIG.flat* values (×2.0 total).
--
-- Per augment slot (value=5, multiplier treated as ×1 by engine when <2):
--   - Floor (no achievements): (5 + 0) × 1 =  5 Beast Affinity points (+5%)
--   - Cap  (max achievements): (5 + 31) × 1 = 36 Beast Affinity points (+36%)
-- 4-slot piece: 20..144 points → +20%..+144% to all pet flat stats.
--
-- To make gear obtainable, add augmentId 2100 to augment_catalog.lua for
-- the relevant BST gear items. Map restart required (augments load at boot).
-- ============================================================================

INSERT IGNORE INTO `augments` (`augmentId`, `multiplier`, `modId`, `value`, `isPet`, `petType`)
VALUES (2100, 0, 1200, 5, 0, 0); -- Beast Affinity +5 per slot (legacy; 11-bit wrap)

-- Retail 1378 is the client string "Enhances Beast Affinity". The custom
-- id 2100 wrapped to 52 ("MP recovered while healing") in the 11-bit
-- packet field. Point 1378 at PET_BEAST_AFF so new rolls display correctly.
-- 2100 stays mapped so already-applied pieces still function.
UPDATE `augments`
SET `multiplier` = 0, `modId` = 1200, `value` = 5, `isPet` = 0, `petType` = 0
WHERE `augmentId` = 1378;
