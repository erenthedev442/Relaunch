-- ============================================================================
-- zz_backfill_item_usable.sql
--
-- Silences the boot-time xi_map log spam:
--   [map][error] ResultSetWrapper::get: key maxCharges is null
--   [map][error] ResultSetWrapper::get: key useDelay is null
--   [map][error] ResultSetWrapper::get: key reuseDelay is null
--
-- WHY IT HAPPENS: itemutils.cpp LoadItemList() builds a CItemUsable for every
-- item_basic row typed Usable (type = 5) and then reads u.maxCharges / u.useDelay /
-- u.reuseDelay for it WITHOUT a null guard (unlike the validTargets check just
-- above). So any Usable item that has NO item_usable row makes the LEFT JOIN return
-- NULL for those columns and logs 3 errors per item. It is BENIGN -- get() logs the
-- null and returns 0, it does not throw (src/common/database.h:317-328) -- pure noise.
--
-- The repo SQL is clean (every base + custom Usable item has an item_usable row);
-- the offenders are stale/orphaned rows that live only in the deployed DB. This
-- set-based, idempotent backfill gives every such orphan a DEFAULT all-zero
-- item_usable row so the JOIN matches instead of returning NULL. It is functionally
-- a no-op -- those items already loaded as 0 -- it just stops the logging. It is
-- self-discovering (fixes current AND any future orphans) and safe to re-run every
-- deploy: once a row exists, INSERT IGNORE / the u.itemid IS NULL filter skip it.
--
-- The derived-table wrapper forces MariaDB/MySQL to materialise the missing set
-- first, sidestepping the "can't INSERT into a table you also SELECT from in the
-- same statement" restriction. All non-listed columns are NOT NULL DEFAULT 0.
-- ============================================================================

INSERT IGNORE INTO `item_usable` (`itemid`, `name`)
SELECT `itemid`, `name` FROM (
    SELECT b.`itemid` AS `itemid`, b.`name` AS `name`
    FROM `item_basic` AS b
    LEFT JOIN `item_usable` AS u ON u.`itemid` = b.`itemid`
    WHERE b.`type` = 5          -- ItemType::Usable (src/map/enums/item_types.h)
      AND u.`itemid` IS NULL
) AS missing;
