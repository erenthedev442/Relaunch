-- ============================================================================
-- legendary_ring.sql   (RELAUNCH -- lives in modules/custom/sql/)
--
-- The "Legendary Ring" -- the one FUNCTIONAL Legacy migration reward, buffed
-- into a flagship heirloom for Legendary 1.0 migrants (owner, 2026-07-12).
--
--     Legendary Ring   [Ring] All Races   (Rare/Ex)   -- item 26169
--       Experience Points Boost  +300%
--       Capacity Points Boost    +300%
--       Auto-Reraise (tier III)  -- highest a gear item can grant
--       Movement Speed           +25%  (engine hard cap; highest-piece-only)
--       Experience Retained on death  100%  -- you never lose EXP on death
--       No Weakness after Reraise      -- engine guard (charentity.cpp)
--       USE: toggles Vanish (Sneak+Invisible) <-> Transform (costume)
--       Permanent "legendary" aura -- a pure-visual glow (AFTERGLOW) while worn
--
-- The five stat lines are stock engine-honored EQUIPMENT mods (pure data):
--   EXP_BONUS             382 = 300  -> charutils.cpp AddExpBonus (additive +% EXP)
--   CAPACITY_BONUS        915 = 300  -> charutils.cpp capacity gain (+% capacity/JP)
--     NOTE: EXP_BONUS is ADDITIVE with all other +EXP sources (augments, food,
--     Dedication, RoV) and is then reduced MULTIPLICATIVELY by any Job Rebirth /
--     Prestige EXP cut -- so the effective EXP multiplier is rarely a clean 4x.
--     CAPACITY_BONUS multiplies cleanly (no rebirth/prestige cut) -> ~4x CP.
--   RERAISE_III           458 = 1    -> charentity.cpp auto-reraise-on-death (tier III)
--   MOVE_SPEED_GEAR_BONUS  76 = 25   -> battleentity.cpp gear move speed (clamped +25%)
--   EXPERIENCE_RETAINED   914 = 100  -> charentity.cpp death: retain 100% of EXP
-- The Vanish/Transform toggle + aura live in scripts/items/legendary_ring.lua;
-- the aura is re-applied on every zone-in by modules/custom/lua/
-- legendary_ring_aura.lua (status effects drop on zone). "No Weakness after
-- Reraise" is a guard in src/map/entities/charentity.cpp.
--
-- CLIENT DISPLAY: repurposes retail item 26169 (reraise_ring) -- already Lv.1,
-- all-jobs, ring-slot, Rare/Ex, USABLE (item_usable enchantment). The custom
-- "Legendary Ring" name needs the client DAT override (see
-- "Custom DATs/Relaunch Custom DATs"); without it the client shows the retail
-- "Reraise Ring" name (a sensible fallback).
--
-- NOT LOOT: never grant this from mobs, NMs, shops, or Gobbie Mystery Box.
-- GRANTED BY: modules/custom/lua/legacy_ring_grant.lua and
-- modules/custom/lua/new_char_starter_marks.lua only.
--
-- Apply, then RESTART the map -- item_basic / item_equipment / item_mods /
-- item_usable are cached at boot. The charentity.cpp guard needs a REBUILD.
-- Idempotent (UPDATE + DELETE/INSERT).
-- ============================================================================

-- ----- server-side name (GM commands / logging); display name is DAT-driven --
-- flags & ~4 drops FLAG_MYSTERY_BOX so SelectDailyItem / Gobbie Box cannot roll it.
UPDATE `item_basic`
   SET `name` = 'legendary_ring', `sortname` = 'legendary_ring',
       `flags` = `flags` & ~4
 WHERE `itemid` = 26169;

-- Belt-and-suspenders: strip any leftover corpse / shop rows if a live DB
-- still has them from an older import.
DELETE FROM `mob_droplist` WHERE `itemId` = 26169;

-- ----- equip rule: Lv.1, all jobs (4194303), ring slot (24576) ---------------
UPDATE `item_equipment`
   SET `name` = 'legendary_ring', `level` = 1, `ilevel` = 0, `jobs` = 4194303, `slot` = 24576
 WHERE `itemId` = 26169;

-- ----- make the enchantment a quick, reusable toggle (retail Reraise Ring is a
--       30s cast / 20h recharge; we want a fast on-demand Vanish/Transform) -----
UPDATE `item_usable`
   SET `useDelay` = 3, `reuseDelay` = 10, `maxCharges` = 1, `validTargets` = 1
 WHERE `itemId` = 26169;

-- ----- stat package -----------------------------------------------------------
DELETE FROM `item_mods` WHERE `itemId` = 26169;

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (26169, 382, 300),   -- EXP_BONUS             +300%
    (26169, 915, 300),   -- CAPACITY_BONUS        +300%
    (26169, 458,   1),   -- RERAISE_III           Auto-Reraise tier III (max gear tier)
    (26169,  76,  25),   -- MOVE_SPEED_GEAR_BONUS  +25% (engine cap)
    (26169, 914, 100);   -- EXPERIENCE_RETAINED    100% -> no EXP loss on death
