-- ============================================================================
-- Rare/Ex budget accessories sold through `!shop armor <page>`.
--
-- These are the original retail item IDs so their client names, icons and
-- equipment data remain unchanged. The restrictions therefore apply to every
-- copy and every source of each item, including copies players already own.
--
-- Flags added:
--   NOAUCTION  (64)    -- cannot be listed on the Auction House
--   NODELIVERY (8192)  -- cannot be sent through delivery
--   EXCLUSIVE  (16384) -- cannot be traded to another player; displays Ex
--   RARE       (32768) -- one copy per character; displays Rare
--
-- NOSALE (4096) is explicitly cleared so any standard NPC vendor can buy the
-- item for BaseSell = 5,000 gil. Apply SQL, then restart xi_map (items cache at
-- process startup). Idempotent.
-- ============================================================================

UPDATE `item_basic`
SET
    `flags`    = (`flags` | 57408) & ~4096,
    `aH`       = 0,
    `NoSale`   = 0,
    `BaseSell` = 5000
WHERE `itemId` IN
(
    -- Rings
    27564, -- Ifrit Ring
    27566, -- Leviathan Ring
    27568, -- Ramuh Ring
    27570, -- Titan Ring
    27572, -- Garuda Ring
    27574, -- Shiva Ring
    27576, -- Carbuncle Ring
    27578, -- Fenrir Ring
    26179, -- Varar Ring

    -- Pearls
    11014, -- Flame Pearl
    11015, -- Snow Pearl
    11016, -- Breeze Pearl
    11017, -- Soil Pearl
    11018, -- Thunder Pearl
    11019, -- Aqua Pearl
    11020, -- Light Pearl
    11021, -- Darkness Pearl

    -- Back, waist and neck
    10964, -- Eloquence Cape
    10966, -- Aisance Mantle
    10968, -- Vigilance Mantle
    10831, -- Paewr Belt
    10832, -- Carrier's Sash
    10836, -- Phos Belt
    10817, -- Moepapa Stone
    10839, -- Othila Sash
    10397, -- Ishtar's Collar
    10939, -- Dualism Collar
    10941, -- Tjukurrpa Medal
    10942, -- Aife's Medal
    10943, -- Moepapa Medal
    10945, -- Waylayer's Scarf

    -- Ammo and grips
    19779, -- Potestas Bomblet
    19777, -- Ombre Tathlum
    19773, -- Hagneia Stone
    19771, -- Strobilus
    19767, -- Oneiros Pebble
    18818, -- Dilettante's Grip
    18816, -- Wizzan Grip
    18825  -- Shamatha Grip
);
