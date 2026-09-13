-- ============================================================================
-- acuity_belt_stats.sql
--
-- Unity Acuity Belt (28429) / +1 (28430) were DEF/MP/INT only. Retail also
-- has MND, Magic Accuracy, Magic Atk. Bonus, and Fast Cast.
-- Unity Ranking INT latent in unity_ranking_latents.sql stays as the extra.
-- Idempotent.
-- ============================================================================

DELETE FROM `item_mods` WHERE `itemId` = 28429 AND `modId` IN (13, 28, 30, 170);
INSERT INTO `item_mods` VALUES (28429, 13, 5);   -- MND: 5
INSERT INTO `item_mods` VALUES (28429, 28, 5);   -- MATT: 5
INSERT INTO `item_mods` VALUES (28429, 30, 5);   -- MACC: 5
INSERT INTO `item_mods` VALUES (28429, 170, 4);  -- FASTCAST: 4%

DELETE FROM `item_mods` WHERE `itemId` = 28430 AND `modId` IN (13, 28, 30, 170);
INSERT INTO `item_mods` VALUES (28430, 13, 6);   -- MND: 6
INSERT INTO `item_mods` VALUES (28430, 28, 6);   -- MATT: 6
INSERT INTO `item_mods` VALUES (28430, 30, 6);   -- MACC: 6
INSERT INTO `item_mods` VALUES (28430, 170, 5);  -- FASTCAST: 5%
