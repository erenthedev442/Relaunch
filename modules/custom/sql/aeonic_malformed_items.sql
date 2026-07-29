-- One-time migration: 14 Malformed weapons for the Aeonic forge path.
-- These are non-equippable exchange items bought from Temprix in Reisenjima.
-- Apply once on box: mysql xidb < sql/aeonic_malformed_items.sql
--
-- IDs 29701-29714 are confirmed free (highest retail item is 29695).
--
-- NOTE: item_basic has no nolog/nodrop/noauction/nodelivery columns -- those
-- live in the `flags` bitfield (see src/map/enums/item_flag.h). The original
-- intent (noauction) is flags = 0x40 = 64 (NoAuction).

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

-- Repair rows created by earlier versions of this migration. INSERT IGNORE does
-- not update an existing row, so explicitly correct the cached item class.
UPDATE item_basic
SET type = 1
WHERE itemid BETWEEN 29701 AND 29714;
