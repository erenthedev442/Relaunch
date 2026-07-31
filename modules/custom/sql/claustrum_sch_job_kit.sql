-- Claustrum 119 III (22060): MAINJOB=SCH customization kit.
-- Latent 62 = MAINJOB; param 20 = SCH.
DELETE FROM `item_latents`
WHERE `itemId` = 22060
  AND `latentId` = 62
  AND `latentParam` = 20;

INSERT INTO `item_latents` VALUES (22060,  28, 30, 62, 20);  -- MATT +30
INSERT INTO `item_latents` VALUES (22060,  30, 25, 62, 20);  -- MACC +25
INSERT INTO `item_latents` VALUES (22060, 478, 10, 62, 20);  -- HELIX_EFFECT +10
