-- ============================================================================
-- zz_catalyst_droplist_rate.sql
--
-- Flat 10% base rate for every live augment-catalyst association in the RETAIL
-- droplists.
--
-- Retail data can represent materials as independent drops (dropType 0),
-- grouped drops (dropType 1), or only as Steal/Despoil rows (dropType 2/4).
-- Treat every existing association for a live catalyst as an intended source,
-- canonicalize its kill drop to one independent 10% row, and preserve the
-- original Steal/Despoil behavior.
--
-- 2026-07-11 owner rule: every catalyst source pays a flat 10%:
--   * retail droplists      -> this file (itemRate 100 = 10%)
--   * assigned 1:1 mobs     -> DROP_RATE     = 10 (augment_catalyst_drops.lua)
--   * any-mob fallback      -> FALLBACK_RATE = 10 (augment_catalyst_drops.lua)
--   * dungeon trash         -> TRASH_RATE    = 10 (augment_dungeon_drops.lua)
-- DROP_RATE_MULTIPLIER is 1.0 in settings/map.lua on the box (verified
-- 2026-07-11), so the effective retail rate is exactly 10% (Treasure Hunter
-- still adds on top -- engine behaviour).
-- 2026-08-29: that 10% is per in-range alliance member, not one shared roll.
-- Engine also floors catalog-catalyst droplist rolls at 10% per player so a
-- Rare 5% row (Manticore Fang) still pays 10% each.
--
-- The item-id list mirrors augment_catalog.lua (143 catalysts). Regenerate the
-- list after catalog changes: the ids below are every key with an augId field.
--
-- Droplists are cached at map boot -> takes effect on the next MAP RESTART.
-- Idempotent config override: source pairs are captured before kill rows are
-- rebuilt, so re-running produces the same one-row-per-source result.
-- ============================================================================
DROP TEMPORARY TABLE IF EXISTS `_live_augment_catalysts`;
CREATE TEMPORARY TABLE `_live_augment_catalysts`
(
    `itemId` SMALLINT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `_live_augment_catalysts` (`itemId`) VALUES
    (768), (770), (816), (817), (818), (820), (821), (825), (827), (828), (829), (832),
    (834), (836), (838), (839), (841), (842), (846), (847), (848), (849), (850), (852),
    (853), (855), (856), (857), (858), (859), (861), (863), (868), (876), (878), (880),
    (881), (882), (884), (886), (887), (888), (889), (891), (895), (897), (902), (909),
    (912), (914), (918), (919), (921), (922), (926), (927), (928), (935), (936), (937),
    (938), (939), (942), (943), (947), (952), (954), (955), (959), (1116), (1119), (1122),
    (1123), (1133), (1156), (1163), (1193), (1196), (1199), (1269), (1449), (1452), (1470), (1473),
    (1474), (1516), (1518), (1521), (1591), (1606), (1607), (1608), (1609), (1615), (1617),
    (1619), (1620), (1621), (1622), (1623), (1630), (1638), (1667), (1690), (1875), (1888),
    (2148), (2149), (2150), (2151), (2153), (2157), (2163), (2166), (2198), (2235), (2335),
    (2338), (2426), (2427), (2428), (2504), (2505), (2507), (2510), (2514), (2518), (2520), (2521),
    (2523), (2531), (2543), (2549), (2640), (2641), (2711), (2747), (2748), (2823), (2888), (2889),
    (3504), (3543);

DROP TEMPORARY TABLE IF EXISTS `_intended_catalyst_drops`;
CREATE TEMPORARY TABLE `_intended_catalyst_drops`
(
    `dropId` SMALLINT UNSIGNED NOT NULL,
    `itemId` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`dropId`, `itemId`)
);

-- Any existing droplist association is evidence that the mob is an intended
-- source. Capture it before rebuilding kill drops.
INSERT IGNORE INTO `_intended_catalyst_drops` (`dropId`, `itemId`)
SELECT DISTINCT
    source.`dropId`, source.`itemId`
FROM `mob_droplist` AS source
INNER JOIN `_live_augment_catalysts` AS catalyst
    ON catalyst.`itemId` = source.`itemId`;

-- Replace independent/grouped kill entries with exactly one independent 10%
-- entry per intended source. Steal (2) and Despoil (4) rows remain untouched.
DELETE drops
FROM `mob_droplist` AS drops
INNER JOIN `_intended_catalyst_drops` AS intended
    ON intended.`dropId` = drops.`dropId`
   AND intended.`itemId` = drops.`itemId`
WHERE drops.`dropType` IN (0, 1);

INSERT INTO `mob_droplist`
    (`dropId`, `dropType`, `groupId`, `groupRate`, `itemId`, `itemRate`)
SELECT
    intended.`dropId`, 0, 0, 1000, intended.`itemId`, 100
FROM `_intended_catalyst_drops` AS intended;

DROP TEMPORARY TABLE `_intended_catalyst_drops`;
DROP TEMPORARY TABLE `_live_augment_catalysts`;
