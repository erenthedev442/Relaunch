-- =====================================================================
-- bst_spalirisos_pet_mods.sql
-- Spalirisos (21730) retail pet line: Pet Acc/RAcc/MAcc +35.
-- Pet Level +3 needs a C++ jug level-bonus mod (not wired yet).
-- Prime Aftermath (Incl. Pets) is handled in scripts/globals/aftermath.lua.
-- =====================================================================

DELETE FROM `item_mods_pet` WHERE `itemId` = 21730;
INSERT INTO `item_mods_pet` (`itemId`, `modId`, `value`, `petType`) VALUES
(21730, 25, 35, 0),  -- ACC
(21730, 26, 35, 0),  -- RACC
(21730, 30, 35, 0);  -- MACC
