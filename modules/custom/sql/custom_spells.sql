-- ============================================================================
-- custom_spells.sql
--
-- Adds two custom spells to the xi database:
--
--   ID 1020 — Divine Aegis  (PLD lv50, Enhancing/Divine)
--   ID 1021 — Convergence   (RDM lv50, Enfeebling)
--
-- Also adds their matching scroll items (29697, 29698) so players can
-- obtain them via the Hunting League shop.
--
-- The spell behaviour lives in:
--   scripts/actions/spells/white/divine_aegis.lua
--   scripts/actions/spells/white/convergence.lua
--
-- Apply once against the xi database:
--   mysql -u root -p xi < modules/custom/sql/custom_spells.sql
--
-- Safe to re-apply (INSERT IGNORE is idempotent).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Jobs bitmask layout (BINARY 22 — one byte per job, value = minimum level):
--   byte0=WAR  byte1=MNK  byte2=WHM  byte3=BLM  byte4=RDM  byte5=THF
--   byte6=PLD  byte7=DRK  byte8=BST  byte9=BRD  byte10=RNG byte11=SAM
--   byte12=NIN byte13=DRG byte14=SMN byte15=BLU  byte16=COR byte17=PUP
--   byte18=DNC byte19=SCH byte20=GEO byte21=RUN
--
-- Divine Aegis: PLD (byte6) = 0x32 = 50
--   0x00000000000032000000000000000000000000000000
-- Convergence:  RDM (byte4) = 0x32 = 50
--   0x00000000320000000000000000000000000000000000
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 1.  spell_list entries
-- ============================================================================

-- Columns:
--   spellid, name, jobs, group, family, element, zonemisc,
--   validTargets, skill, mpCost, castTime, recastTime,
--   message, magicBurstMessage,
--   animation, animationTime,
--   AOE, base, multiplier, CE, VE, requirements,
--   spell_range, radius, content_tag

-- Divine Aegis — self-target PLD protection + detonation
INSERT IGNORE INTO `spell_list`
    (`spellid`, `name`, `jobs`,
     `group`, `family`, `element`, `zonemisc`,
     `validTargets`, `skill`,
     `mpCost`, `castTime`, `recastTime`,
     `message`, `magicBurstMessage`,
     `animation`, `animationTime`,
     `AOE`, `base`, `multiplier`,
     `CE`, `VE`, `requirements`,
     `spell_range`, `radius`, `content_tag`)
VALUES
    (1020, 'divine_aegis', 0x00000000000032000000000000000000000000000000,
     6, 5, 7, 0,
     1, 32,
     80, 4000, 120000,
     230, 0,
     21, 2000,
     0, 0, 1.00,
     0, 0, 0,
     0, 0, NULL);

-- Convergence — enemy-target RDM random enfeeble+damage
INSERT IGNORE INTO `spell_list`
    (`spellid`, `name`, `jobs`,
     `group`, `family`, `element`, `zonemisc`,
     `validTargets`, `skill`,
     `mpCost`, `castTime`, `recastTime`,
     `message`, `magicBurstMessage`,
     `animation`, `animationTime`,
     `AOE`, `base`, `multiplier`,
     `CE`, `VE`, `requirements`,
     `spell_range`, `radius`, `content_tag`)
VALUES
    (1021, 'convergence', 0x00000000320000000000000000000000000000000000,
     6, 0, 0, 0,
     4, 35,
     60, 2500, 45000,
     2, 0,
     216, 2000,
     0, 0, 1.00,
     8, 16, 0,
     18, 0, NULL);

-- ============================================================================
-- 2.  Scroll items — item_basic
-- ============================================================================

-- Flag breakdown (same as Scroll of Silencega):
--   FLAG_MYSTERY_BOX =   4
--   FLAG_MOG_GARDEN  =   8
--   FLAG_SCROLL      = 128
--   FLAG_CANUSE      = 512
--   FLAG_CANTRADENPC =1024
--   combined         =1676
--   USABLE_TYPE      =   5
--   WHITE_MAGIC (aH) =  28

INSERT IGNORE INTO `item_basic`
    (`itemid`, `subid`, `name`, `sortname`, `name_jp`,
     `type`, `stackSize`, `flags`, `aH`, `BaseSell`)
VALUES
    (29697, 1020, 'scroll_of_divine_aegis',  'divine_aegis',  'ディバインイージス', 5, 1, 1676, 28, 5000),
    (29698, 1021, 'scroll_of_convergence',   'convergence',   'コンバージェンス',   5, 1, 1676, 28, 4000);

-- ============================================================================
-- 3.  Scroll items — item_usable
-- ============================================================================

-- animation=11: standard white-magic scroll use animation

INSERT IGNORE INTO `item_usable`
    (`itemid`, `name`, `validTargets`, `activation`, `animation`,
     `animationTime`, `maxCharges`, `useDelay`, `reuseDelay`, `aoe`)
VALUES
    (29697, 'scroll_of_divine_aegis', 1, 1, 11, 5, 0, 0, 0, 0),
    (29698, 'scroll_of_convergence',  1, 1, 11, 5, 0, 0, 0, 0);
