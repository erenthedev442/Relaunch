-- ============================================================================
-- zz_aeonic_aftermath.sql  --  Wire AFTERMATH (mod 256) onto the Aeonic weapons
-- ----------------------------------------------------------------------------
-- Implements retail-style Aeonic Aftermath ("Occasionally deals double/triple
-- damage"). The AFTERMATH mod (256) value is the aftermath ID defined in
-- scripts/globals/aftermath.lua (xi.aftermath.effects):
--   49 = Aeonic MELEE  -> REM_OCC_DO_DOUBLE_DMG / REM_OCC_DO_TRIPLE_DMG
--   50 = Aeonic RANGED -> REM_OCC_DO_DOUBLE_DMG_RANGED / _TRIPLE_DMG_RANGED
--
-- Aeonic AM is NOT tied to a signature WS: it is applied by ANY weapon skill,
-- hooked centrally in weaponskills.lua (do*Weaponskill -> addStatusEffect(...,
-- AEONIC)). That is why the merit-WS Aeonics (Fomalhaut -> Last Stand, etc.)
-- work without an ADDS_WEAPONSKILL entry.
--
-- This whole Aeonic path (aftermath.lua type/effects 49-50 + the 3 weaponskills
-- hooks) was ported from Legendary, where it was missing entirely on relaunch
-- (aftermath.lua carried a `-- TODO: Add Aeonic`). Placed in sql/ (NOT
-- modules/custom/sql/) so it re-runs UNCONDITIONALLY every deploy and sorts
-- AFTER item_mods.sql -- desync-proof against a base item_mods re-import.
--
-- mod 256 = MOD_AFTERMATH. item_mods load at map boot -> needs an xi_map RESTART
-- to take effect. NOT a one-time migration.
-- ============================================================================

DELETE FROM `item_mods`
WHERE `modId` = 256
AND `itemId` IN
(
    20515, 20594, 20695, 21694, 21753, 20843, 20890, 20935, 20977, 21025,
    21082, 21147, 22117, 21485
);

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- ----- melee Aeonics (aftermath 49) -----------------------------------
    (20515, 256, 49),  -- Godhands            / H2H         (MNK/PUP)
    (20594, 256, 49),  -- Aeneas              / Dagger      (THF/BRD/DNC)
    (20695, 256, 49),  -- Sequence            / Sword       (RDM/PLD/BLU)
    (21694, 256, 49),  -- Lionheart           / Great Sword (RUN)
    (21753, 256, 49),  -- Tri-edge            / Axe         (BST)
    (20843, 256, 49),  -- Chango              / Great Axe   (WAR)
    (20890, 256, 49),  -- Anguta              / Scythe      (DRK)
    (20935, 256, 49),  -- Trishula            / Polearm     (DRG)
    (20977, 256, 49),  -- Heishi Shorinken    / Katana      (NIN)
    (21025, 256, 49),  -- Dojikiri Yasutsuna  / Great Katana(SAM)
    (21082, 256, 49),  -- Tishtrya            / Club        (WHM/GEO)
    (21147, 256, 49),  -- Khatvanga           / Staff       (BLM/SMN/SCH)
    -- ----- ranged Aeonics (aftermath 50) ----------------------------------
    (22117, 256, 50),  -- Fail-Not            / Bow         (RNG)
    (21485, 256, 50)   -- Fomalhaut           / Gun         (RNG/COR)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
