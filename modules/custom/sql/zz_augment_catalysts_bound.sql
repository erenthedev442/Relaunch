-- ============================================================================
-- Character-bind every catalyst accepted by the Arcane Augmenter.
--
-- Item flags are global per item ID, so this applies to Commemoration Moogle
-- rewards, farmed catalysts, and copies characters already own:
--   NOAUCTION  0x0040 -- cannot be listed on the Auction House
--   NODELIVERY 0x2000 -- cannot be sent through the Delivery Box
--   EXCLUSIVE  0x4000 -- cannot be traded/bazaar-sold to another character
--
-- CanSendAccount (0x0010) is cleared because it otherwise bypasses NoDelivery
-- for characters on the same account. AugSendable (0x0001) is also cleared.
-- CanTradeNPC (0x0400) is preserved, so catalysts still work when traded to
-- the Arcane Augmenter. RARE is deliberately not added: catalysts must stack
-- and the Commemoration Moogle allows up to three of a selected type.
--
-- Keep this list synchronized with modules/custom/lua/augment_catalog.lua.
-- Apply SQL, then restart xi_map (item definitions are cached at startup).
-- Idempotent.
-- ============================================================================

UPDATE `item_basic`
SET
    `flags` = (`flags` | 24640) & ~17,
    `aH`    = 0
WHERE `itemId` IN
(
    768, 770, 816, 817, 818, 820, 821, 825, 827, 828, 829, 832,
    834, 836, 838, 839, 841, 842, 846, 847, 848, 849, 850, 852,
    853, 855, 856, 857, 858, 859, 861, 863, 868, 876, 878, 880,
    881, 882, 884, 886, 887, 888, 889, 891, 895, 897, 902, 909,
    912, 914, 918, 919, 921, 922, 926, 927, 928, 935, 936, 937,
    938, 939, 942, 943, 947, 952, 954, 955, 959, 1116, 1119, 1122,
    1123, 1133, 1156, 1163, 1193, 1196, 1199, 1269, 1470, 1473,
    1474, 1516, 1518, 1521, 1591, 1606, 1607, 1608, 1609, 1615, 1617, 1619,
    1620, 1621, 1622, 1623, 1626, 1630, 1638, 1667, 1690, 1875, 1888, 2148, 2149,
    2150, 2151, 2153, 2157, 2163, 2166, 2198, 2235, 2335, 2338, 2426, 2427,
    2428, 2504, 2505, 2507, 2510, 2514, 2518, 2520, 2521, 2523, 2531, 2543,
    2549, 2640, 2641, 2711, 2747, 2748, 2823, 2888, 2889, 3504, 3543
);

-- 2026-09-03: 1452 is Dynamis Orc bronze (relic exchange), not a catalyst.
-- 1449 was a stale leftover Whiteshell in this list. Restore stock currency
-- flags so they are not EX / no-AH.
UPDATE `item_basic`
SET
    `flags` = 4100,
    `aH`    = 65
WHERE `itemId` IN (1449, 1452);
