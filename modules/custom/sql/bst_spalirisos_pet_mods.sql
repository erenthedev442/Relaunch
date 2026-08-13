-- =====================================================================
-- bst_spalirisos_pet_mods.sql
-- Spalirisos retail pet line: Pet Lv.+1/+2/+3 by stage; final stage also
-- grants Pet Acc/RAcc/MAcc +35.
-- Prime Aftermath (Incl. Pets) is handled in scripts/globals/aftermath.lua.
-- =====================================================================

DELETE FROM `item_mods`
WHERE `itemId` IN (21727, 21728, 21729, 21730) AND `modId` = 1201;
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
(21728, 1201, 1),
(21729, 1201, 2),
(21730, 1201, 3);

DELETE FROM `item_mods_pet` WHERE `itemId` = 21730;
INSERT INTO `item_mods_pet` (`itemId`, `modId`, `value`, `petType`) VALUES
(21730, 25, 35, 0),  -- ACC
(21730, 26, 35, 0),  -- RACC
(21730, 30, 35, 0);  -- MACC
