-- ============================================================================
-- spaekona_coat_elem_to_mp.sql
-- ----------------------------------------------------------------------------
-- Spaekona's Coat N/+1/+2/+3/+4 all say "Converts 2% of elemental magic
-- damage dealt to MP" but shipped with no item_mod, so the line was flavor
-- text only. ELEM_DMG_TO_MP (1202) is a presence flag; damage_spell.lua
-- refunds 25% of MP spent on the elemental cast (once per cast).
-- Idempotent. item_mods are loaded at map boot; re-equip or zone after restart.
-- ============================================================================

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (27810, 1202, 2),  -- Spaekona's Coat
    (27831, 1202, 2),  -- Spaekona's Coat +1
    (23110, 1202, 2),  -- Spaekona's Coat +2
    (23445, 1202, 2),  -- Spaekona's Coat +3
    (23943, 1202, 2)   -- Spaekona's Coat +4
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
