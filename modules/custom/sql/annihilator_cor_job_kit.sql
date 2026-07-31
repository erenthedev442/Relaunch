-- Annihilator 119 III (22140): MAINJOB=COR customization kit.
-- Latent 62 = MAINJOB; param 17 = COR.
DELETE FROM `item_latents`
WHERE `itemId` = 22140
  AND `latentId` = 62
  AND `latentParam` = 17;

INSERT INTO `item_latents` VALUES (22140, 191, 30, 62, 17);  -- QUICK_DRAW_MACC +30
INSERT INTO `item_latents` VALUES (22140, 411, 30, 62, 17);  -- QUICK_DRAW_DMG +30
