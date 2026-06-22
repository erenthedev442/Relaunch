-- Fix Sancus Sachet and Sancus Sachet +1 (ids 21394 / 21395).
-- Both items shipped with only BP_DELAY (357) in item_mods; all other stats
-- were missing so the item showed no meaningful buffs in game.
--
-- Correct mods per wiki / retail data:
--   "Blood Pact" recast time II  -> BP_DELAY_II (541), not BP_DELAY (357)
--   Avatar: Lv. +20              -> AVATAR_LVL_BONUS (1040) = 20
--   "Blood Pact" damage          -> BP_DAMAGE (126)
--   Accuracy                     -> ACC  (25)
--   Ranged Accuracy              -> RACC (26)
--   Magic Accuracy               -> MACC (30)
--
-- Fix existing wrong mod type (357 -> 541) on both versions.
UPDATE `item_mods` SET `modId` = 541 WHERE `itemId` IN (21394, 21395) AND `modId` = 357;

-- Sancus Sachet +1 (21395) -- full stat line
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (21395, 126, 15),  -- "Blood Pact" damage +15
    (21395,  25, 20),  -- Accuracy +20
    (21395,  26, 20),  -- Ranged Accuracy +20
    (21395,  30, 20),  -- Magic Accuracy +20
    (21395, 1040, 20)  -- Avatar: Lv. +20 (-> lv.119)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

-- Sancus Sachet base (21394) -- scaled down
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (21394, 126, 12),  -- "Blood Pact" damage +12
    (21394,  25, 15),  -- Accuracy +15
    (21394,  26, 15),  -- Ranged Accuracy +15
    (21394,  30, 15),  -- Magic Accuracy +15
    (21394, 1040, 20)  -- Avatar: Lv. +20 (-> lv.119; same iLvl)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
