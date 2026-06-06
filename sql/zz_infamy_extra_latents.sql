-- ---------------------------------------------------------------------------
-- zz_infamy_extra_latents.sql
--
-- Conditional (latent) effects for Infamy-Vendor gear whose value isn't a
-- flat stat. Format: (itemID, modId, modValue, latentId, latentParam).
--   latentId 10 = WEAPON_DRAWN (scripts/enum/latent.lua), modId 370 = REGAIN.
--
-- INSERT IGNORE + zz_ prefix: loads after sql/item_latents.sql (which DROPs
-- the table on import) and never clobbers an existing latent row.
--
-- Vim Torque +1 (26022): base item is DEF+15 (sql/zz_infamy_extra_mods.sql);
-- its signature is "Regain+20 while weapon drawn". (The Refresh+1~3 is a Unity
-- ranking augment, not a base latent, so it is intentionally not added.)
-- ---------------------------------------------------------------------------

LOCK TABLES `item_latents` WRITE;

INSERT IGNORE INTO `item_latents` VALUES (26022,370,20,10,0);    -- Vim Torque +1: "Regain"+20 while weapon drawn

UNLOCK TABLES;
