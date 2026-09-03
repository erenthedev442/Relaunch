-- ============================================================================
-- yoichinoyumi_augment.sql
--
-- Final Yoichinoyumi (22129, yoichinoyumi_119_iii_aug) and the 119 III
-- intermediate (22115) were still in item_usable. That sets validTargets,
-- which marks the weapon ITEM_CHARGED. Charged equipment stores timer
-- exdata, so Augment Moogle / Sage re-adds succeed but the augs never stick.
--
-- Yoichi Arrows now come only from Yoichi's Quiver (26343), granted with
-- the final bow. Strip both bow usable rows so neither form is an
-- enchantment ammo source.
--
-- Apply, then restart the map (item data is cached at startup). Idempotent.
-- ============================================================================

DELETE FROM `item_usable` WHERE `itemid` IN (22115, 22129);
