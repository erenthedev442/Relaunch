-- ============================================================================
-- zz_catalyst_droplist_rate.sql
--
-- Flat 10% base rate for every augment-catalyst item in the RETAIL droplists
-- (normal kill drops only -- dropType 0; Steal/Despoil rows untouched).
--
-- 2026-07-11 owner rule: every catalyst source pays a flat 10%:
--   * retail droplists      -> this file (itemRate 100 = 10%)
--   * assigned 1:1 mobs     -> DROP_RATE     = 10 (augment_catalyst_drops.lua)
--   * any-mob fallback      -> FALLBACK_RATE = 10 (augment_catalyst_drops.lua)
--   * dungeon trash         -> TRASH_RATE    = 10 (augment_dungeon_drops.lua)
-- DROP_RATE_MULTIPLIER is 1.0 in settings/map.lua on the box (verified
-- 2026-07-11), so the effective retail rate is exactly 10% (Treasure Hunter
-- still adds on top -- engine behaviour).
--
-- The item-id list mirrors augment_catalog.lua (146 catalysts). Regenerate the
-- list after catalog changes: the ids below are every key with an augId field.
--
-- Droplists are cached at map boot -> takes effect on the next MAP RESTART.
-- Idempotent config override (a fixed SET, not a one-time migration), safe to
-- live in zz_*.sql, which re-applies on every deploy.
-- ============================================================================
UPDATE `mob_droplist` SET `itemRate` = 100
WHERE `dropType` = 0 AND `itemId` IN (
    768, 770, 816, 817, 818, 820, 821, 825, 827, 828, 829, 832,
    834, 836, 838, 839, 841, 842, 846, 847, 848, 849, 850, 852,
    853, 855, 856, 857, 858, 859, 861, 863, 868, 876, 878, 880,
    881, 882, 884, 886, 887, 888, 889, 891, 895, 897, 902, 909,
    912, 914, 918, 919, 921, 922, 926, 927, 928, 935, 936, 937,
    938, 939, 942, 943, 947, 952, 954, 955, 959, 1116, 1119, 1122,
    1123, 1133, 1156, 1163, 1193, 1196, 1199, 1269, 1449, 1452, 1470, 1473,
    1474, 1516, 1518, 1521, 1591, 1606, 1607, 1608, 1609, 1615, 1617,
    1619, 1620, 1621, 1622, 1623, 1630, 1638, 1663, 1667, 1690, 1875, 1888,
    1889, 2148, 2149, 2150, 2151, 2153, 2157, 2163, 2166, 2198, 2235, 2335,
    2338, 2426, 2427, 2428, 2504, 2505, 2507, 2510, 2514, 2518, 2520, 2521,
    2523, 2531, 2543, 2549, 2640, 2641, 2711, 2747, 2748, 2823, 2888, 2889,
    3504, 3543
);
