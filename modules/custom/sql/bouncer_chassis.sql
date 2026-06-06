-- ============================================================================
-- bouncer_chassis.sql   (Phase 1 of the custom "Bouncer" tank job)
--
-- Repurposes the GEO (Geomancer) job slot, job id 21, as a polearm-wielding
-- heavy-armor TANK called the "Bouncer".  See the full design in
--   documentation/custom_tank_job_design.md
--
-- This file is the DB half of Phase 1 ("the chassis").  The C++ half is two
-- direct core edits that must be COMPILED IN for this to take full effect:
--   1. src/map/grades.cpp   line ~60  GEO stat-grade row ->
--        { 1, 0, 4, 4, 1, 4, 6, 4, 4 }   (HP=A, MP=0/none, VIT=A, rest moderate)
--   2. src/map/job_points.cpp          JOB_GEO case neutralized (no spell grants)
-- Rebuild the map server (rebuild-server.bat) after applying this SQL.
--
-- Apply once against the live database (creds per settings/network.lua):
--   "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/bouncer_chassis.sql
--
-- Idempotent: re-applying is safe (UPDATEs are deterministic, the trait block
-- DELETEs-then-INSERTs its own job=21 rows, the equip OR is a no-op once set).
--
-- All numeric values here are STARTING values, to be tuned at the balance pass
-- (design doc Phase 7).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Combat skill ranks for the GEO/Bouncer slot.
--
-- skill_ranks: one row per skill (skillid PK), one column per job.  The `geo`
-- column is this job slot.  SCALE IS INVERTED: lower number = higher rank
-- (1 = ~A+, ~7 = ~C/D, ~11 = G, 0 = no access).
--
--   polearm  (skillid  8): 0 -> 1   A rank, matches DRG (the polearm job)
--   parrying (skillid 31): 10 -> 1   A rank, matches RUN (best parry)
--   evasion  (skillid 29): 9 -> 7   moderate, matches WAR/PLD/DRK
--
-- No shield skill (skillid 30 left at 0): the Bouncer is 2-handed (polearm),
-- so it cannot use a shield by design -- mitigation comes from HP/VIT/DEF and
-- damage reflection, not blocking.
--
-- The GEO magic skills (geomancy 44, handbell 45) are intentionally left for
-- Phase 2 ("strip GEO gameplay"), where the spell identity is removed wholesale.
-- ----------------------------------------------------------------------------
UPDATE `skill_ranks` SET `geo` = 1 WHERE `skillid` = 8;   -- polearm
UPDATE `skill_ranks` SET `geo` = 1 WHERE `skillid` = 31;  -- parrying
UPDATE `skill_ranks` SET `geo` = 7 WHERE `skillid` = 29;  -- evasion


-- ----------------------------------------------------------------------------
-- 2. "max hp boost" job trait so the Bouncer's HP exceeds MNK.
--
-- Both MNK and the Bouncer share grade-A base HP (grades.cpp).  To push the
-- Bouncer's total HP clearly ABOVE MNK, give it a stronger flat-HP trait.
--
--   traits schema: (traitid, name, job, level, rank, modifier, value, content_tag, meritid)
--   PK = (traitid, job, level, rank, modifier)
--   traitid 7  = "max hp boost"   modifier 1095 = dedicated flat Max-HP mod
--   value      = ABSOLUTE flat HP at that tier (the game grants the single
--                highest rank the character qualifies for; tiers do NOT stack)
--   content_tag NULL = no expansion gate, always active.
--
-- MNK (job 2) tops out at 280 flat HP (rank 6, level 65).  The Bouncer line
-- below peaks at 480 at level 90 -> ~+200 HP over MNK at cap, on top of equal
-- grade-A base.  This makes the Bouncer the single highest-HP job.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `traitid` = 7 AND `job` = 21;
INSERT INTO `traits`
    (`traitid`, `name`, `job`, `level`, `rank`, `modifier`, `value`, `content_tag`, `meritid`)
VALUES
    (7, 'max hp boost', 21, 10, 1, 1095,  30, NULL, 0),
    (7, 'max hp boost', 21, 20, 2, 1095,  60, NULL, 0),
    (7, 'max hp boost', 21, 30, 3, 1095, 120, NULL, 0),
    (7, 'max hp boost', 21, 40, 4, 1095, 180, NULL, 0),
    (7, 'max hp boost', 21, 50, 5, 1095, 240, NULL, 0),
    (7, 'max hp boost', 21, 60, 6, 1095, 300, NULL, 0),
    (7, 'max hp boost', 21, 70, 7, 1095, 360, NULL, 0),
    (7, 'max hp boost', 21, 80, 8, 1095, 420, NULL, 0),
    (7, 'max hp boost', 21, 90, 9, 1095, 480, NULL, 0);


-- ----------------------------------------------------------------------------
-- 3. Starter itemization: let the Bouncer equip polearms + heavy/basic armor.
--
-- item_equipment.jobs is an int bitmask; bit = 1 << (jobid - 1).
--   WAR = bit 0  = 1
--   DRG = bit 13 = 8192      (polearms + dragoon armor)
--   GEO = bit 20 = 1048576   <-- now means "the Bouncer can equip this"
--
-- OR the GEO bit onto everything currently equippable by DRG or WAR.  This
-- gives the Bouncer a full starter kit: polearms + heavy armor (DRG) and the
-- large pool of generic/heavy gear (WAR).  Bit-OR is idempotent.
--
-- Full AF/relic/empyrean itemization is Phase 5; this is just enough to make a
-- job-21 character playable and feel-testable.
-- ----------------------------------------------------------------------------
UPDATE `item_equipment`
    SET `jobs` = `jobs` | 1048576
    WHERE (`jobs` & 8192) <> 0      -- DRG-equippable
       OR (`jobs` & 1) <> 0;        -- WAR-equippable


-- ============================================================================
-- REVERSE (manual rollback, if ever needed):
--
--   -- skills (restore real-GEO values)
--   UPDATE `skill_ranks` SET `geo` = 0  WHERE `skillid` = 8;
--   UPDATE `skill_ranks` SET `geo` = 10 WHERE `skillid` = 31;
--   UPDATE `skill_ranks` SET `geo` = 9  WHERE `skillid` = 29;
--
--   -- trait
--   DELETE FROM `traits` WHERE `traitid` = 7 AND `job` = 21;
--
--   -- equip flag (strips the GEO bit globally; safe because the GEO job slot
--   -- is repurposed and no real GEO exists to need it)
--   UPDATE `item_equipment` SET `jobs` = `jobs` & ~1048576 WHERE (`jobs` & 1048576) <> 0;
--
-- ...and revert the two grades.cpp / job_points.cpp core edits, then rebuild.
-- ============================================================================
