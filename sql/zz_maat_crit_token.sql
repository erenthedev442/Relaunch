-- zz_maat_crit_token.sql
-- Adds "Maat's Blessing" (id 29000), a rare consumable token.
-- Dropped at 25% from the custom level-250 Maat challenge in GM_Home.
-- When present in inventory, guarantees a critical augment at the Augment
-- Moogle (modules/custom/lua/Augment_Moogle.lua); consumed on success.
--
-- INSERT IGNORE: safe to re-apply (PRIMARY KEY on itemId prevents duplicate).
-- Flags: EX (16384) | RARE (32768) | NOAUCTION (64) | NOSALE (4096) | NODELIVERY (8192)
--   = 61440

-- Positional INSERT to match the working sql/item_basic.sql rows -- an explicit
-- column list naming `jname` failed with "Unknown column 'jname'" (that column
-- isn't in item_basic on this schema). Column order: itemId, subid, name,
-- sortname, <jp name>, type, stackSize, flags, ahcat, basesell.
INSERT IGNORE INTO `item_basic`
VALUES
    (29000, 0, 'maats_blessing', 'maats_blessing', 'マートの加護',
     1,   -- GENERAL_TYPE
     1,   -- stackSize (RARE prevents stacking anyway)
     61440, -- EX | RARE | NOAUCTION | NOSALE | NODELIVERY
     0,   -- ahcat = NONE
     0);  -- basesell (no NPC sale value)
