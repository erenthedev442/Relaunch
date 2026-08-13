-- Aeonic forge tokens: 14 Malformed bases plus unique Stage I / Stage II
-- intermediates. Unique intermediates prevent the Aeonic route from colliding
-- with the Prime route's Ajja/Kaja equipment.
-- Apply once on box: mysql xidb < sql/aeonic_malformed_items.sql
--
-- IDs 29701-29714 are confirmed free (highest retail item is 29695).
--
-- NOTE: item_basic has no nolog/nodrop/noauction/nodelivery columns -- those
-- live in the `flags` bitfield (see src/map/enums/item_flag.h). The original
-- All tokens are Rare/Exclusive, unsellable, undeliverable, and unauctionable
-- (0xF040 = 61504) so a forge stage cannot be duplicated or transferred.

SET @AEONIC_OLD_SQL_MODE = @@SQL_MODE;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

INSERT IGNORE INTO item_basic
    (itemid, name, type, stackSize, flags, aH)
VALUES
    (29701, 'Malformed Knuckles',   1, 1, 64, 0),  -- H2H (MNK/PUP)
    (29702, 'Malformed Knife',      1, 1, 64, 0),  -- Dagger (THF/BRD/DNC)
    (29703, 'Malformed Sword',      1, 1, 64, 0),  -- Sword (RDM/PLD/BLU/RUN)
    (29704, 'Malformed Claymore',   1, 1, 64, 0),  -- Great Sword (WAR/DRK)
    (29705, 'Malformed Axe',        1, 1, 64, 0),  -- Axe (WAR/BST)
    (29706, 'Malformed Greataxe',   1, 1, 64, 0),  -- Great Axe (WAR)
    (29707, 'Malformed Scythe',     1, 1, 64, 0),  -- Scythe (DRK)
    (29708, 'Malformed Lance',      1, 1, 64, 0),  -- Polearm (DRG)
    (29709, 'Malformed Katana',     1, 1, 64, 0),  -- Katana (NIN)
    (29710, 'Malformed Tachi',      1, 1, 64, 0),  -- Great Katana (SAM)
    (29711, 'Malformed Rod',        1, 1, 64, 0),  -- Club (WHM/GEO)
    (29712, 'Malformed Staff',      1, 1, 64, 0),  -- Staff (BLM/SMN/SCH)
    (29713, 'Malformed Bow',        1, 1, 64, 0),  -- Archery (RNG)
    (29714, 'Malformed Culverin',   1, 1, 64, 0);  -- Marksmanship (COR/RNG)

INSERT IGNORE INTO item_basic
    (itemid, name, type, stackSize, flags, aH)
VALUES
    (29715, 'Attuned Knuckles',   1, 1, 64, 0),
    (29716, 'Attuned Knife',      1, 1, 64, 0),
    (29717, 'Attuned Sword',      1, 1, 64, 0),
    (29718, 'Attuned Claymore',   1, 1, 64, 0),
    (29719, 'Attuned Axe',        1, 1, 64, 0),
    (29720, 'Attuned Greataxe',   1, 1, 64, 0),
    (29721, 'Attuned Scythe',     1, 1, 64, 0),
    (29722, 'Attuned Lance',      1, 1, 64, 0),
    (29723, 'Attuned Katana',     1, 1, 64, 0),
    (29724, 'Attuned Tachi',      1, 1, 64, 0),
    (29725, 'Attuned Rod',        1, 1, 64, 0),
    (29726, 'Attuned Staff',      1, 1, 64, 0),
    (29727, 'Attuned Bow',        1, 1, 64, 0),
    (29728, 'Attuned Culverin',   1, 1, 64, 0),
    (29729, 'Empowered Knuckles', 1, 1, 64, 0),
    (29730, 'Empowered Knife',    1, 1, 64, 0),
    (29731, 'Empowered Sword',    1, 1, 64, 0),
    (29732, 'Empowered Claymore', 1, 1, 64, 0),
    (29733, 'Empowered Axe',      1, 1, 64, 0),
    (29734, 'Empowered Greataxe', 1, 1, 64, 0),
    (29735, 'Empowered Scythe',   1, 1, 64, 0),
    (29736, 'Empowered Lance',    1, 1, 64, 0),
    (29737, 'Empowered Katana',   1, 1, 64, 0),
    (29738, 'Empowered Tachi',    1, 1, 64, 0),
    (29739, 'Empowered Rod',      1, 1, 64, 0),
    (29740, 'Empowered Staff',    1, 1, 64, 0),
    (29741, 'Empowered Bow',      1, 1, 64, 0),
    (29742, 'Empowered Culverin', 1, 1, 64, 0);

-- Repair rows created by earlier versions of this migration. INSERT IGNORE does
-- not update an existing row, so explicitly correct the cached item class.
UPDATE item_basic
SET type = 1, flags = 61504
WHERE itemid BETWEEN 29701 AND 29742;

SET SQL_MODE = @AEONIC_OLD_SQL_MODE;
