-- ============================================================================
-- Intense VD Ambuscade cosmetic rewards.
--
-- These are existing retail item IDs. Restrictions therefore apply to every
-- copy/source of each listed item:
--   CAN_SEND_ACCT (16) -- delivery to characters on the same account remains OK
--   NO_AUCTION    (64)
--   NO_SALE       (4096)
--   NO_DELIVERY   (8192) -- blocks normal delivery; CAN_SEND_ACCT is the override
--   EXCLUSIVE     (16384)
--   RARE          (32768)
--
-- Idempotent. Item data is cached; restart xi_map after applying.
-- ============================================================================

UPDATE `item_basic`
SET
    `flags`    = `flags` | 61520,
    `aH`       = 0,
    `BaseSell` = 0
WHERE
    `itemId` BETWEEN 10256 AND 10271 OR
    `itemId` BETWEEN 10330 AND 10345 OR
    `itemId` IN
    (
        10250, 10251, 10252, 10253, 10254, 10293,
        10382, 10383, 10384, 10385,
        10429, 10430, 10431, 10432, 10433,
        10593, 10594, 10595, 10596,
        10796, 10809,
        11316, 11317, 11318, 11319, 11355,
        11490, 11491, 11500, 11861, 11862,
        13819, 13820, 13821, 13822, 13916, 13933,
        14126, 14251, 14386,
        14532, 14533, 14534, 14535,
        15176, 15178, 16075, 16118, 16378,
        23731, 23790, 23791,
        25585, 25639, 25711, 25715, 25722, 25726, 25756, 25758,
        26517, 26546, 26703, 26719, 26954,
        27854, 27866, 27911
    );
