-- ============================================================
-- boom_job_spells.sql
--
-- Custom job "Boom" (relaunch) repurposes the Summoner slot (job 15). Give that
-- slot cast access to its spell kit by setting the SMN learn-level byte (byte 15
-- of the spell_list.jobs binary(22) blob). BoomJob.lua additionally addSpell()s
-- these on login so the player KNOWS them; this UPDATE lets the job CAST them.
--
-- Byte-15-only edit (other jobs' bytes survive) -- same pattern as
-- restore_geo_retail.sql (byte 21 for GEO). Idempotent.
--
-- The kit (all cast normally -- detonation/Ignite is handled by BoomJob's
-- MAGIC_USE listener; no commands):
--   * Tier-III nukes (small boom):   146 Stone, 151 Water, 156 Aero,
--                                    161 Fire, 166 Blizzard, 171 Thunder  @ Lv20
--   * Ancient Magic (BIG boom):      204 Flare, 206 Freeze, 208 Tornado,
--                                    210 Quake, 212 Burst, 214 Flood       @ Lv50
--   * Enspells ("Ignite" trigger):   100 Enfire .. 105 Enwater             @ Lv30
-- ============================================================

-- Tier-III nukes @ Lv20 (0x14)
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x14) WHERE `spellid` IN (146, 151, 156, 161, 166, 171);

-- Ancient Magic @ Lv50 (0x32)
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x32) WHERE `spellid` IN (204, 206, 208, 210, 212, 214);

-- Enspells @ Lv30 (0x1E)
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x1E) WHERE `spellid` IN (100, 101, 102, 103, 104, 105);
