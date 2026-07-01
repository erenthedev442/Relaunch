-- ============================================================
-- remove_boom_spells.sql
--
-- Reverts boom_job_spells.sql. The custom "Boom" job (relaunch) is REMOVED
-- (2026-06-30) so job 15 is plain Summoner again. Boom had set the byte-15
-- (SMN slot) learn-level in spell_list.jobs so the slot could CAST its kit;
-- this restores byte 15 to 0x00 (stock "cannot learn" -- verified: Firaga III
-- 176 byte15=0) for all 18 Boom spells. Idempotent; other jobs' bytes untouched.
-- ============================================================
UPDATE `spell_list` SET `jobs` = INSERT(`jobs`, 15, 1, 0x00)
WHERE `spellid` IN (146, 151, 156, 161, 166, 171,   -- Tier-III nukes (Boom)
                    204, 206, 208, 210, 212, 214,   -- Ancient Magic (Boom)
                    100, 101, 102, 103, 104, 105);  -- Enspells (Boom)
