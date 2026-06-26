-- ============================================================
-- boom_job_spells.sql
--
-- Custom job "Boom" (relaunch) repurposes the Summoner slot (job 15). Give that
-- slot cast access to its handful of detonating elemental nukes by setting the
-- SMN learn-level byte (byte 15 of the spell_list.jobs binary(22) blob).
--
-- 0x14 = level 20. BoomJob.lua additionally addSpell()s these on login so the
-- player KNOWS them; this UPDATE is what lets the job CAST them.
--
-- Byte-15-only edit (other jobs' bytes survive) -- same pattern as
-- restore_geo_retail.sql (which edits byte 21 for GEO). Idempotent.
--
-- Spell ids: 146 Stone III, 151 Water III, 156 Aero III, 161 Fire III,
--            166 Blizzard III, 171 Thunder III.
-- ============================================================

UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x14) WHERE `spellid` = 146;  -- Stone III
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x14) WHERE `spellid` = 151;  -- Water III
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x14) WHERE `spellid` = 156;  -- Aero III
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x14) WHERE `spellid` = 161;  -- Fire III
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x14) WHERE `spellid` = 166;  -- Blizzard III
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x14) WHERE `spellid` = 171;  -- Thunder III
