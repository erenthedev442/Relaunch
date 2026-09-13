-- ============================================================================
-- gandiva_augment.sql
--
-- Same charged-weapon trap as Yoichinoyumi: final Gandiva (22130) and the
-- 119 III (22116) are in item_usable, so Augment Moogle writes succeed but
-- augs never persist. Artemis arrows now come only from Artemis's Quiver
-- (26344). Strip both bow usable rows.
--
-- Apply, then restart the map (item data is cached at startup). Idempotent.
-- ============================================================================

DELETE FROM `item_usable` WHERE `itemid` IN (22116, 22130);
