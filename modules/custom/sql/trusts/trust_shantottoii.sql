-- Custom: unlock T2–V for Shantotto II (retail is T1-only; keep this power path).
-- Base list 428 already has T1. REPLACE adds higher tiers on top.
-- NOTE: do not delete T1 rows; do not remove this file on combat audits.

REPLACE INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
('TRUST_Shantotto_II',428,145,38,255), -- fire_ii
('TRUST_Shantotto_II',428,146,62,255), -- fire_iii
('TRUST_Shantotto_II',428,147,73,255), -- fire_iv
('TRUST_Shantotto_II',428,148,86,255), -- fire_v
('TRUST_Shantotto_II',428,150,42,255), -- blizzard_ii
('TRUST_Shantotto_II',428,151,64,255), -- blizzard_iii
('TRUST_Shantotto_II',428,152,74,255), -- blizzard_iv
('TRUST_Shantotto_II',428,153,89,255), -- blizzard_v
('TRUST_Shantotto_II',428,155,34,255), -- aero_ii
('TRUST_Shantotto_II',428,156,59,255), -- aero_iii
('TRUST_Shantotto_II',428,157,72,255), -- aero_iv
('TRUST_Shantotto_II',428,158,83,255), -- aero_v
('TRUST_Shantotto_II',428,160,26,255), -- stone_ii
('TRUST_Shantotto_II',428,161,51,255), -- stone_iii
('TRUST_Shantotto_II',428,162,68,255), -- stone_iv
('TRUST_Shantotto_II',428,163,77,255), -- stone_v
('TRUST_Shantotto_II',428,165,46,255), -- thunder_ii
('TRUST_Shantotto_II',428,166,66,255), -- thunder_iii
('TRUST_Shantotto_II',428,167,75,255), -- thunder_iv
('TRUST_Shantotto_II',428,168,92,255), -- thunder_v
('TRUST_Shantotto_II',428,170,30,255), -- water_ii
('TRUST_Shantotto_II',428,171,55,255), -- water_iii
('TRUST_Shantotto_II',428,172,70,255), -- water_iv
('TRUST_Shantotto_II',428,173,80,255); -- water_v
