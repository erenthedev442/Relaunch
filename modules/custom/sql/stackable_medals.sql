-- ============================================================================
-- stackable_medals.sql
--
-- Make Demons Medal (item 9543) stack to 99 so it matches its two sibling
-- medals (Beastmens Medal 9539 / Kindreds Medal 9541) and is usable as a
-- Hunting League currency.
--
-- Upstream FFXI ships Demons Medal as stack=1, which makes it a poor
-- currency item (every unit takes an inventory slot). The other two medals
-- in the trio are already stack=99.
--
-- This override runs AFTER sql/item_basic.sql is imported by dbtool, so it
-- corrects the row in-place each time the DB is rebuilt. UPDATE is
-- idempotent — safe to re-apply.
-- ============================================================================

UPDATE `item_basic` SET `stackSize` = 99 WHERE `itemid` = 9543;
