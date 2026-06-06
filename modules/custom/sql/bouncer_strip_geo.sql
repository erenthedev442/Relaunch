-- ============================================================================
-- bouncer_strip_geo.sql   (Phase 2 of the custom "Bouncer" tank job)
--
-- Strips the GEO (Geomancer) *magic* identity from the repurposed job slot,
-- job id 21, now the "Bouncer" tank.  See documentation/custom_tank_job_design.md.
--
-- Phase 1 (bouncer_chassis.sql) built the chassis (stats/skills/HP/equip).
-- This phase removes everything that made the slot a luopan caster:
--   * all spell access (Indi-/Geo-/Cure/etc.)
--   * the magic skills (Geomancy, Handbell)
--   * the GEO magic/MP job traits
--
-- NOTE ON SCOPE: this file does NOT touch the GEO *job abilities* (Bolster,
-- Full Circle, Life Cycle, Ecliptic Attrition, Dematerialize, ...).  Those
-- "ability sockets" are deliberately KEPT and rewritten into tank abilities in
-- Phase 3 (scripts/globals/job_utils/bouncer.lua + abilities.sql).  Likewise
-- scripts/globals/job_utils/geomancer.lua is intentionally left in place: once
-- spell access is revoked below, a job-21 character can never spawn a luopan,
-- so every luopan/spell code path in that file becomes unreachable for the
-- Bouncer.  Its ability functions are replaced wholesale in Phase 3.
--
-- This is data-only: no recompile.  A map-server restart reloads the changes.
--
-- Apply once against the live database:
--   "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/bouncer_strip_geo.sql
--
-- Idempotent: re-applying is safe (the spell UPDATE skips already-zeroed rows,
-- the skill UPDATEs are deterministic, the trait DELETE removes nothing new).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Revoke ALL spell access for the GEO/Bouncer slot.
--
-- spell_list.jobs is BINARY(22): one byte per job (0-indexed:
--   0=WAR 1=MNK 2=WHM 3=BLM 4=RDM 5=THF 6=PLD 7=DRK 8=BST 9=BRD 10=RNG
--   11=SAM 12=NIN 13=DRG 14=SMN 15=BLU 16=COR 17=PUP 18=DNC 19=SCH 20=GEO 21=RUN).
-- The byte value is the minimum level a job needs to cast; 0 = no access.
--
-- GEO is 0-indexed byte 20 = SQL position 21 (verified empirically against the
-- silencega row and live Indi-* spells).  INSERT(jobs,21,1,0x00) zeroes ONLY
-- that byte, length-preserving (stays 22 bytes) and leaving every other job's
-- access intact -- so spells GEO shared with WHM/BLM/etc. stay castable by them.
--
-- Touches the 221 spells GEO could cast.  WHERE clause makes it idempotent.
-- ----------------------------------------------------------------------------
UPDATE `spell_list`
    SET `jobs` = INSERT(`jobs`, 21, 1, 0x00)
    WHERE SUBSTRING(`jobs`, 21, 1) != 0x00;


-- ----------------------------------------------------------------------------
-- 2. Remove the GEO magic skills from the slot.
--
-- The Bouncer is a martial tank; its combat skills (polearm/parrying/evasion)
-- were set in Phase 1.  Zero the two magic skills so they no longer appear or
-- rank up.  (geomancy = skillid 44, handbell = skillid 45.)
-- ----------------------------------------------------------------------------
UPDATE `skill_ranks` SET `geo` = 0 WHERE `skillid` = 44;  -- geomancy
UPDATE `skill_ranks` SET `geo` = 0 WHERE `skillid` = 45;  -- handbell


-- ----------------------------------------------------------------------------
-- 3. Strip the GEO magic/MP job traits.
--
-- Current job=21 traits are all caster traits that make no sense on a no-MP
-- polearm tank:
--     8 max mp boost, 13 conserve mp, 24 clear mind, 112 elemental celerity,
--   116 cardinal chant, 119 curative recantation, 120 primeval zeal.
-- Delete every job=21 trait EXCEPT traitid 7 ("max hp boost"), which the
-- Bouncer chassis (Phase 1) added.  Phase 4 layers in the tank traits.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` <> 7;


-- ============================================================================
-- REVERSE (manual rollback, if ever needed):
--
--   -- spells: the original per-spell GEO levels cannot be reconstructed from
--   -- the zeroed data.  Restore the GEO byte by re-importing the canonical
--   -- column source (git-tracked, unchanged):
--   --     mysql ... xidb < sql/spell_list.sql        (full table reimport)
--   -- or restore spell_list from a DB backup taken before this migration.
--
--   -- skills (restore real-GEO magic skill ranks)
--   UPDATE `skill_ranks` SET `geo` = 7 WHERE `skillid` = 44;  -- geomancy
--   UPDATE `skill_ranks` SET `geo` = 7 WHERE `skillid` = 45;  -- handbell
--
--   -- traits: re-import the GEO trait rows from git-tracked sql/traits.sql
--   -- (job=21 traitids 8,13,24,112,116,119,120), or restore from backup.
-- ============================================================================
