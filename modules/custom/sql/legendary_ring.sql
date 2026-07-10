-- ============================================================================
-- legendary_ring.sql   (RELAUNCH -- lives in modules/custom/sql/)
--
-- The "Legendary Ring" -- the one FUNCTIONAL Legacy migration reward. Every
-- other Legacy reward is strictly cosmetic; the rule was intentionally relaxed
-- for THIS single heirloom as recognition for time invested on Legendary:
--
--     Legendary Ring   [Ring] All Races   (Rare/Ex)
--       Capacity Points Boost +50%
--       Experience Points Boost +50%
--       Auto Reraise Effect
--       Lv.1 All Jobs
--
-- All four effects are stock, engine-honored EQUIPMENT mods -- no C++, no Lua
-- for the item itself:
--   EXP_BONUS       382  = 50   -> charutils.cpp AddExpBonus() (additive +% EXP)
--   CAPACITY_BONUS  915  = 50   -> charutils.cpp capacity gain (+% capacity/JP)
--   RERAISE_I       456  = 1    -> charentity.cpp auto-reraise-on-death from gear
--
-- CLIENT DISPLAY: this repurposes retail item 26169 (reraise_ring), which was
-- chosen because it is (a) already Lv.1 / all-jobs / ring-slot / Rare-Ex, and
-- (b) NOT present in any Relaunch droplist, vendor, or quest, so nothing else is
-- clobbered. The client only has DAT text for real item ids, so a custom name
-- REQUIRES reusing a retail id + a client DAT override (XIPivot). See
-- "Custom DATs/Relaunch Custom DATs" for the id->"Legendary Ring" text override.
-- Without the DAT pack the ring still works; the client just shows the retail
-- "Reraise Ring" name (a sensible fallback).
--
-- GRANTED BY: modules/custom/lua/legacy_ring_grant.lua on login, to any char
-- whose charVar Legacy_Ring_Grant == 1 (set when the player claims this reward
-- on the portal). Nothing here distributes the item.
--
-- Apply, then RESTART the map -- item_basic / item_equipment / item_mods are all
-- cached at boot. Idempotent (UPDATE + DELETE/INSERT).
-- ============================================================================

-- ----- server-side name (GM commands / logging); display name is DAT-driven --
UPDATE `item_basic`
   SET `name` = 'legendary_ring', `sortname` = 'legendary_ring'
 WHERE `itemid` = 26169;

-- ----- equip rule: Lv.1, all jobs (4194303), ring slot (24576) ---------------
UPDATE `item_equipment`
   SET `name` = 'legendary_ring', `level` = 1, `ilvl` = 0, `jobs` = 4194303, `slot` = 24576
 WHERE `itemId` = 26169;

-- ----- stat package -----------------------------------------------------------
DELETE FROM `item_mods` WHERE `itemId` = 26169;

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (26169, 382, 50),   -- EXP_BONUS        +50%
    (26169, 915, 50),   -- CAPACITY_BONUS   +50%
    (26169, 456,  1);   -- RERAISE_I        Auto Reraise (tier I) from gear
