-- ============================================================================
-- zz_epeo_idris_ladder.sql
--
-- Real 99 / 119 I IDs for Epeolatry and Idris (empty retail hole 19968-19971).
-- Client DATs clone looks from 20753 / 21070. Server jobs match the forge:
-- Epeo WAR/DRK, Idris GEO.
--
-- Ladder:
--   Epeolatry  19968 (99) -> 19969 (119 I) -> 20753 (119) -> 21685 (119 III)
--   Idris      19970 (99) -> 19971 (119 I) -> 21070 (119) -> 21080 (119 III)
--
-- Native WS is on every stage so pilgrimage chapters work while equipped,
-- same as Conqueror / Yagrush. GEO+10 stays on Idris 119 III only.
-- Idempotent. Restart xi_map after apply (item tables are cached at boot).
-- ============================================================================

-- Rare/Ex equippable weapon:
-- NOAUCTION|CANEQUIP|NOSALE|NODELIVERY|EX|RARE = 64+2048+4096+8192+16384+32768 = 63552
-- type 7 = weapon

DELETE FROM `item_basic` WHERE `itemid` IN (19968, 19969, 19970, 19971);
INSERT INTO `item_basic`
    (`itemid`, `subid`, `name`, `sortname`, `name_jp`, `type`, `stackSize`, `flags`, `aH`, `BaseSell`)
VALUES
    (19968, 0, 'epeolatry', 'epeolatry', 'エピオラトリー', 7, 1, 63552, 0, 0),
    (19969, 0, 'epeolatry', 'epeolatry', 'エピオラトリー', 7, 1, 63552, 0, 0),
    (19970, 0, 'idris',     'idris',     'イドリス',       7, 1, 63552, 0, 0),
    (19971, 0, 'idris',     'idris',     'イドリス',       7, 1, 63552, 0, 0);

DELETE FROM `item_weapon` WHERE `itemId` IN (19968, 19969, 19970, 19971);
INSERT INTO `item_weapon`
    (`itemId`, `name`, `skill`, `subskill`, `ilvl_skill`, `ilvl_parry`, `ilvl_macc`, `dmgType`, `hit`, `delay`, `dmg`, `unlock_points`)
VALUES
    (19968, 'epeolatry', 4,  0,   0,   0,   0, 2, 1, 489, 154, 0),
    (19969, 'epeolatry', 4,  0, 242, 242, 215, 2, 1, 489, 243, 0),
    (19970, 'idris',    11,  0,   0,   0,   0, 3, 1, 280,  80, 0),
    (19971, 'idris',    11,  0, 242, 242, 228, 3, 1, 280, 139, 0);

-- jobs: WAR+DRK = 33, GEO = 1048576
-- MId 706 / 707 match the 119 donors so the DAT-cloned looks resolve
DELETE FROM `item_equipment` WHERE `itemId` IN (19968, 19969, 19970, 19971);
INSERT INTO `item_equipment`
    (`itemId`, `name`, `level`, `ilevel`, `jobs`, `MId`, `shieldSize`, `scriptType`, `slot`, `rslot`, `rslotlook`, `su_level`)
VALUES
    (19968, 'epeolatry', 99,   0,      33, 706, 0, 0, 1, 0, 0, 0),
    (19969, 'epeolatry', 99, 119,      33, 706, 0, 0, 1, 0, 0, 0),
    (19970, 'idris',     99,   0, 1048576, 707, 0, 0, 3, 0, 0, 0),
    (19971, 'idris',     99, 119, 1048576, 707, 0, 0, 3, 0, 0, 0);

-- Existing 119 / 119 III were RUN-only (2097152). Forge path is WAR/DRK.
UPDATE `item_equipment` SET `jobs` = 33 WHERE `itemId` IN (20753, 21685);

DELETE FROM `item_mods` WHERE `itemId` IN (19968, 19969, 19970, 19971, 20753, 21070);
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- Epeolatry 99
    (19968,  27,  18),   -- ENMITY
    (19968, 256,  39),   -- AFTERMATH (mythic)
    (19968, 355,  61),   -- ADDS_WEAPONSKILL Dimidiation
    -- Epeolatry 119 I
    (19969,  27,  18),
    (19969, 256,  39),
    (19969, 355,  61),
    -- Epeolatry 119 (was unmodded; grant WS so Chapter III can be worn)
    (20753,  27,  18),
    (20753, 256,  39),
    (20753, 355,  61),
    -- Idris 99
    (19970,   5,  50),   -- MP
    (19970, 256,  31),   -- AFTERMATH (mage mythic)
    (19970, 355, 175),   -- ADDS_WEAPONSKILL Exudation
    -- Idris 119 I
    (19971,   5, 100),
    (19971,  28,  25),   -- MATT
    (19971,  30,  25),   -- MACC
    (19971, 256,  31),
    (19971, 311, 155),   -- MAGIC_DAMAGE
    (19971, 355, 175),
    -- Idris 119: keep MP, add WS, drop GEO+10 (that stays on 21080)
    (21070,   5, 100),
    (21070, 256,  31),
    (21070, 355, 175);
