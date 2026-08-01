-- ============================================================================
-- player_castable_spells.sql
--
-- Opens player casting for custom-intended -ga / Meteor II spells whose base
-- spell_list rows are mob-only (all-zero jobs). Also adds the Silencega scroll.
--
-- Apply once against the xi database (map server restart required afterward):
--   mysql -u root -p xi < modules/custom/sql/player_castable_spells.sql
--
-- Safe to re-apply (UPDATE + INSERT IGNORE are idempotent).
-- ============================================================================

-- Job bytes (0-indexed): 2=WHM 3=BLM 4=RDM 19=SCH. Value = min level; 0 = no access.

-- Silencega (359): WHM 40, RDM 50, SCH 50
UPDATE `spell_list`
    SET `jobs` = 0x00002800320000000000000000000000000000320000
    WHERE `spellid` = 359;

-- Hastega (358): WHM 40, RDM 50, SCH 50
UPDATE `spell_list`
    SET `jobs` = 0x00002800320000000000000000000000000000320000
    WHERE `spellid` = 358;

-- Meteor II (244): BLM 99, RDM 99, SCH 99
UPDATE `spell_list`
    SET `jobs` = 0x00000063630000000000000000000000000000630000
    WHERE `spellid` = 244;

-- Scroll of Silencega (item 29696) — same as silencega_scroll.sql
INSERT IGNORE INTO `item_basic`
    (`itemid`, `subid`, `name`, `sortname`, `name_jp`,
     `type`, `stackSize`, `flags`, `aH`, `BaseSell`)
VALUES
    (29696, 359, 'scroll_of_silencega', 'silencega', 'サイレスガ',
     5, 1, 1676, 28, 3000);

INSERT IGNORE INTO `item_usable`
    (`itemid`, `name`, `validTargets`, `activation`, `animation`,
     `animationTime`, `maxCharges`, `useDelay`, `reuseDelay`, `aoe`)
VALUES
    (29696, 'scroll_of_silencega', 1, 1, 11, 5, 0, 0, 0, 0);
