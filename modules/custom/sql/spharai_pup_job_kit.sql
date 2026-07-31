-- Spharai 119 III (20509): MAINJOB=PUP customization kit.
-- Latent 62 = MAINJOB; param 18 = PUP.
-- Idempotent: wipe prior kit rows for this item+latent, then re-insert.
DELETE FROM `item_latents`
WHERE `itemId` = 20509
  AND `latentId` = 62
  AND `latentParam` = 18;

INSERT INTO `item_latents` VALUES (20509, 990, 40, 62, 18);  -- PET_ATK_DEF +40
INSERT INTO `item_latents` VALUES (20509, 991, 40, 62, 18);  -- PET_ACC_EVA +40
INSERT INTO `item_latents` VALUES (20509, 504,  1, 62, 18);  -- MANEUVER_BONUS +1
INSERT INTO `item_latents` VALUES (20509, 505, 10, 62, 18);  -- OVERLOAD_THRESH +10
