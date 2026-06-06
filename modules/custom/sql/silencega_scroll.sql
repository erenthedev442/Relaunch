-- ============================================================================
-- silencega_scroll.sql
--
-- Makes Silencega (spell ID 359) castable by players and adds the
-- Scroll of Silencega as an obtainable item (item ID 29696).
--
-- The spell itself is already fully wired up in the server:
--   scripts/actions/spells/white/silencega.lua       (behavior)
--   scripts/globals/spells/enfeebling_spell.lua       (pTable params)
--   sql/spell_list.sql id=359                         (AoE Wind, radius 160)
--
-- This file is the only DB change needed to unlock it for players.
--
-- Apply once against the xi database:
--   mysql -u root -p xi < modules/custom/sql/silencega_scroll.sql
--
-- Safe to re-apply (UPDATE + INSERT IGNORE are idempotent).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Grant WHM / RDM / SCH access to Silencega.
--
-- The `jobs` column in spell_list is BINARY(22): one byte per job
-- (WAR=byte0 ... RUN=byte21).  The value in each byte is the minimum
-- character level required for that job to cast the spell; 0 = no access.
--
-- Job layout (0-indexed byte → job abbreviation):
--   0=WAR  1=MNK  2=WHM  3=BLM  4=RDM  5=THF  6=PLD  7=DRK
--   8=BST  9=BRD 10=RNG 11=SAM 12=NIN 13=DRG 14=SMN 15=BLU
--  16=COR 17=PUP 18=DNC 19=SCH 20=GEO 21=RUN
--
-- Levels assigned:
--   WHM (byte  2) = 40  (0x28)   — primary silence user
--   RDM (byte  4) = 50  (0x32)   — enfeebling specialist
--   SCH (byte 19) = 50  (0x32)   — enfeebling magic focus
-- ----------------------------------------------------------------------------
UPDATE `spell_list`
    SET `jobs` = 0x00002800320000000000000000000000000000320000
    WHERE `spellid` = 359;

-- ----------------------------------------------------------------------------
-- 2. Add the Scroll of Silencega to item_basic.
--
-- Columns: itemid, subid, name, sortname, name_jp,
--          type, stackSize, flags, aH, BaseSell
--
-- Raw flag values (from item_basic.sql variable definitions):
--   FLAG_MYSTERY_BOX  =    4
--   FLAG_MOG_GARDEN   =    8
--   FLAG_SCROLL       =  128
--   FLAG_CANUSE       =  512
--   FLAG_CANTRADENPC  = 1024
--   combined          = 1676
--
--   USABLE_TYPE       =  5
--   WHITE_MAGIC (aH)  = 28
-- ----------------------------------------------------------------------------
INSERT IGNORE INTO `item_basic`
    (`itemid`, `subid`, `name`, `sortname`, `name_jp`,
     `type`, `stackSize`, `flags`, `aH`, `BaseSell`)
VALUES
    (29696, 359, 'scroll_of_silencega', 'silencega', 'サイレスガ',
     5, 1, 1676, 28, 3000);

-- ----------------------------------------------------------------------------
-- 3. Add the Scroll of Silencega to item_usable.
--
-- Columns: itemid, name, validTargets, activation, animation,
--          animationTime, maxCharges, useDelay, reuseDelay, aoe
--
-- animation=11 is the white-magic scroll use animation (same as
-- scroll_of_slow, scroll_of_silence, etc.).
-- ----------------------------------------------------------------------------
INSERT IGNORE INTO `item_usable`
    (`itemid`, `name`, `validTargets`, `activation`, `animation`,
     `animationTime`, `maxCharges`, `useDelay`, `reuseDelay`, `aoe`)
VALUES
    (29696, 'scroll_of_silencega', 1, 1, 11, 5, 0, 0, 0, 0);
