-- ============================================================================
-- Welcome Moogle level-50 wares.
--
-- These are retail item IDs, so these restrictions apply to every copy from
-- every source. The Welcome Moogle grants them with fixed starter augments.
--
-- Added flags:
--   NOAUCTION (64), NOSALE (4096), NODELIVERY (8192),
--   EXCLUSIVE (16384), RARE (32768)
-- Cleared flags:
--   AUG_SENDABLE (1), CAN_SEND_ACCT (16), CAN_TRADE_NPC (1024)
--
-- Result: Rare/Ex, no PC trade, AH, delivery, same-account send, bazaar/vendor
-- resale, or NPC trade. BaseSell is zero as a second resale safeguard.
-- Idempotent. Item data is cached, so restart xi_map after applying.
-- ============================================================================

UPDATE `item_basic`
SET
    `flags`    = (`flags` | 61504) & ~1041,
    `aH`       = 0,
    `NoSale`   = 1,
    `BaseSell` = 0
WHERE `itemId` IN
(
    -- Weapons: melee
    17472, -- Cross-Counters
    18752, -- Retaliators
    18020, -- Mercurial Kris
    18411, -- Buboso
    17813, -- Soboro Sukehiro
    16965, -- Koryukagemitsu
    16940, -- Gerwitz's Sword
    16571, -- Temple Knight Army Sword
    18219, -- Leucous Voulge +1
    16681, -- Gerwitz's Axe
    16851, -- Royal Knight Army Lance
    19150, -- Cobra Unit Claymore
    19277, -- Tsugumi

    -- Weapons: ranged and magic/support
    17173, -- War Bow +1
    17226, -- Arbalest +1
    17182, -- Kaman +1
    17253, -- Musketeer Gun
    16757, -- Corsair's Knife
    17072, -- Lilith's Rod
    17082, -- Tactician Magician's Wand
    16694, -- Tactician Magician's Hooks
    17851, -- Storm Fife
    16810, -- Tactician Magician's Espadon

    -- Armor: job bodies
    14412, -- Parade Cuirass
    14409, -- Gloom Breastplate
    14411, -- Aikido Gi
    14403, -- Rapparee Harness
    14405, -- Wyvern Mail
    14407, -- Cerise Doublet
    14410, -- Nimbus Doublet
    14408, -- Glamor Jupon
    14406, -- Shikaree Aketon
    14401, -- Duende Cotehardie
    14402, -- Nokizaru Gi
    14404, -- Shinimusha Hara-ate
    14413, -- Gaudy Harness

    -- Armor: other pieces
    12550, -- Iron Musketeer's Cuirass
    12686, -- Royal Knight's Mufflers
    12806, -- Iron Musketeer's Cuisses
    12942, -- Royal Knight's Sollerets
    13939, -- Austere Hat
    13940, -- Penance Hat
    14020, -- Enkelados's Bracelets
    12312, -- Royal Knight Army Shield
    12379, -- Holy Shield

    -- Accessories: rings
    13286, -- Soldier's Ring
    13287, -- Kampfer Ring
    13288, -- Medicine Ring
    13289, -- Sorcerer's Ring
    13290, -- Fencer's Ring
    13291, -- Rogue's Ring
    13292, -- Guardian's Ring
    13293, -- Slayer's Ring
    13294, -- Tamer's Ring
    13295, -- Minstrel's Ring
    13296, -- Tracker's Ring
    13297, -- Ronin Ring
    13298, -- Shinobi Ring
    13299, -- Drake Ring
    13300, -- Conjurer's Ring
    14649, -- Telluric Ring

    -- Accessories: earrings
    15974, -- Velocity Earring
    15970, -- Stoic Earring
    11042, -- Rebel Earring
    15969, -- Storm Earring
    14744, -- Undead Earring
    14745, -- Arcana Earring

    -- Accessories: neck, waist and back
    13107, -- Royal Knight Army Collar
    13105, -- Temple Knight Army Collar
    13167, -- Storm Gorget
    13168, -- Intellect Torque
    13220, -- Royal Knight's Belt
    13676, -- Heavy Mantle
    13678, -- Sniper's Mantle
    13677, -- Esoteric Mantle
    13692  -- Skulker's Cape
);
