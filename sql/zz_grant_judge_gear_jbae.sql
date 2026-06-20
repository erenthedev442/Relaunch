-- =============================================================================
-- zz_grant_judge_gear_jbae.sql
-- Grant the full Judge gear set to player Jbae, each piece fully augmented
-- with Exp. Point +33% in all 5 slots (augId 73, max boost 31 = 64%/slot).
--
-- Full set total: 13 pieces × 5 slots × 64% = 3,120% EXP bonus potential
-- (actual bonus is summed across all equipped pieces by the engine).
--
-- Extra blob (24 bytes) layout (AugmentStandard, packed):
--   Byte 0:     AugmentKindFlags    = 0x02 (HasAugments)
--   Byte 1:     AugmentSubKindFlags = 0x03 (Standard)
--   Bytes 2-11: 5 × Augment{Id:11, Value:5} little-endian uint16
--               augId 73, boost 31 → (31<<11)|73 = 0xF849 → LE: 0x49 0xF8
--   Bytes 12-23: Signature (12 × 0x00, unsigned)
--
-- Safe to run while Jbae is offline; or online with a relog to see the items.
-- =============================================================================

BEGIN;

SET @charid    = (SELECT charid FROM chars WHERE charname = 'Jbae' LIMIT 1);
-- 5 slots all maxed (augId 73 = Exp. Point +33%, boost 31 → 64% per slot):
SET @extra     = UNHEX('020349F849F849F849F849F8000000000000000000000000');
SET @base_slot = (SELECT COALESCE(MAX(slot), -1) + 1
                  FROM char_inventory
                  WHERE charid = @charid AND location = 0);

INSERT INTO char_inventory (charid, location, slot, itemId, quantity, extra) VALUES
    (@charid, 0, @base_slot +  0, 12523, 1, @extra),  -- judges_helm
    (@charid, 0, @base_slot +  1, 12551, 1, @extra),  -- judges_cuirass
    (@charid, 0, @base_slot +  2, 12679, 1, @extra),  -- judges_gauntlets
    (@charid, 0, @base_slot +  3, 12807, 1, @extra),  -- judges_cuisses
    (@charid, 0, @base_slot +  4, 12935, 1, @extra),  -- judges_greaves
    (@charid, 0, @base_slot +  5, 13074, 1, @extra),  -- judges_gorget
    (@charid, 0, @base_slot +  6, 13215, 1, @extra),  -- judges_belt
    (@charid, 0, @base_slot +  7, 13358, 1, @extra),  -- judges_earring (ear 1)
    (@charid, 0, @base_slot +  8, 13358, 1, @extra),  -- judges_earring (ear 2)
    (@charid, 0, @base_slot +  9, 13505, 1, @extra),  -- judges_ring (ring 1)
    (@charid, 0, @base_slot + 10, 13505, 1, @extra),  -- judges_ring (ring 2)
    (@charid, 0, @base_slot + 11, 13606, 1, @extra),  -- judges_cape
    (@charid, 0, @base_slot + 12, 12332, 1, @extra);  -- judges_shield

COMMIT;
