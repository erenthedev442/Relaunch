-- ============================================================================
-- gastraphetes_augment.sql
--
-- Same charged-weapon trap as Yoichinoyumi / Gandiva: final Gastraphetes
-- (22139) and the 119 III (21266) are in item_usable, so Augment Moogle
-- writes succeed but augs never persist. Quelling Bolts now come only from
-- Quelling Bolt Quiver (26346). Strip both crossbow usable rows.
--
-- Apply, then restart the map (item data is cached at startup). Idempotent.
-- ============================================================================

DELETE FROM `item_usable` WHERE `itemid` IN (21266, 22139);
