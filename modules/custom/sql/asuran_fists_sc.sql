-- ============================================================================
-- asuran_fists_sc.sql
--
-- Give Asuran Fists (weaponskillid 9) the SAME skillchain properties as Chant
-- du Cygne (weaponskillid 225) -- Light + Distortion -- so it self-skillchains
-- to Light, exactly like Chant du Cygne does.
--
-- The three *_sc columns are SKILLCHAIN_ELEMENT ids (src/map/utils/battleutils.cpp):
--   13 = Light, 10 = Distortion, 0 = none.
-- When you use the same WS twice, the engine resonates the opener's properties
-- against the closer's. With {Light, Distortion} on both, the {Light, Light}
-- pair matches first in skillchain_map -> SC_LIGHT_II, which the client shows as
-- a Light skillchain (the strongest tier) -- the same result Chant du Cygne gets.
--
-- This REPLACES Asuran Fists' stock properties (was 9/3 = Gravitation /
-- Liquefaction), so it now chains like Chant du Cygne for all purposes.
--
-- weapon_skills is loaded into the WS cache at map boot, so this needs a MAP
-- RESTART to take effect (not a Lua hot-reload). Idempotent UPDATE; kept as a
-- custom override (not an edit to sql/weapon_skills.sql) so it survives upstream
-- merges and re-applies via the custom-SQL ledger.
-- ============================================================================

UPDATE `weapon_skills`
SET `primary_sc`   = 13,  -- Light      (was 9 = Gravitation)
    `secondary_sc` = 10,  -- Distortion (was 3 = Liquefaction)
    `tertiary_sc`  = 0
WHERE `weaponskillid` = 9; -- Asuran Fists
