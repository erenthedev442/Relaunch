-- ============================================================================
-- bouncer_itemization.sql   (Phase 5 of the custom "Bouncer" tank job)
--
-- Finalizes the Bouncer's (GEO slot, job 21) equip-access pool.  See the full
-- design in documentation/custom_tank_job_design.md.
--
-- THE BOUNCER'S GEAR IDENTITY (polearm heavy-armor enmity/reflect tank):
--   pool = DRG (polearms + heavy DD)        -- granted Phase 1 (bouncer_chassis)
--        + WAR (generic heavy / enmity)      -- granted Phase 1 (bouncer_chassis)
--        + PLD (enmity / phys-DT tank gear)  -- granted HERE  (section 2)
--        + RUN (magic-DT / magic-tank gear)  -- granted HERE  (section 2)
--        - ALL shields                       -- removed HERE  (section 1)
--
-- item_equipment.jobs is an int bitmask; a job's bit = 1 << (jobid - 1), where
-- jobid is the 1-indexed JOBTYPE (JOB_WAR=1 ... JOB_GEO=21, JOB_RUN=22):
--   WAR = job 1  -> bit 0  =       1
--   PLD = job 7  -> bit 6  =      64
--   DRG = job 14 -> bit 13 =    8192   (the polearm/heavy pool granted Phase 1)
--   GEO = job 21 -> bit 20 = 1048576   <-- now means "the Bouncer can equip this"
--   RUN = job 22 -> bit 21 = 2097152
-- Because job 21 is now exclusively the Bouncer (Phase 2 stripped every GEO
-- gameplay path), toggling bit 20 affects ONLY the Bouncer; every other job's
-- access is untouched.  shieldSize (>0 = a shield) is the precise shield marker,
-- independent of the slot bitmask, so we gate on it directly.
--
-- WHY SECTION 1 EXISTS (a Phase-1 correction):
--   The locked design rule is "2-handed polearm, NO shield" (the Bouncer has no
--   shield skill -- skillid 30 stayed 0).  But Phase 1 granted the Bouncer bit
--   to everything WAR-equippable, and WAR uses shields -- so 279 shields silently
--   became Bouncer-equippable.  Section 1 strips the Bouncer bit back off every
--   shield, restoring the no-shield identity.  (Other jobs keep their shields.)
--
-- This is data-only: no recompile.  A map-server restart reloads the changes.
-- It touches ONLY the item_equipment config table (equip-access masks) -- no
-- character, inventory, or auction data is read or written.
--
-- Apply once against the live database:
--   "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/bouncer_itemization.sql
--
-- Idempotent: section 1's strip skips already-cleared rows; section 2's bit-OR
-- is a no-op on rows that already carry the bit.  Sections operate on disjoint
-- row sets (shieldSize>0 vs shieldSize=0), so apply order does not matter.
--
-- NOTE ON SCOPE: this grants access to the EXISTING tank gear that fits the
-- Bouncer's role -- it does NOT create bespoke Bouncer AF/relic/empyrean items
-- (that needs new item ids, client DAT models, and drop sources -- a separate
-- content project, documented as a Phase-7+ follow-up).  All values remain
-- STARTING POINTS for the balance pass (design doc Phase 7); no live player has
-- a leveled Bouncer yet, so this grant carries zero progression risk.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Remove ALL shields from the Bouncer (honor the locked "no shield" rule;
--    corrects the Phase-1 WAR-OR side effect that granted 279 shields).
--    Clears ONLY the Bouncer bit (20); every other job's shield access stays.
-- ----------------------------------------------------------------------------
UPDATE `item_equipment`
    SET `jobs` = `jobs` & ~1048576
    WHERE `shieldSize` > 0
      AND (`jobs` & 1048576) <> 0;


-- ----------------------------------------------------------------------------
-- 2. Grant the Bouncer all NON-SHIELD gear that PLD or RUN can equip -- the
--    enmity / phys-DT (PLD) and magic-DT / magic-tank (RUN) pieces that define
--    a tank and that the DRG/WAR pool (Phase 1) does not already cover.
--    shieldSize = 0 keeps section 1's no-shield guarantee intact.
--    (Off-skill main weapons that come along -- swords, great swords -- are
--    self-limiting: the Bouncer has no skill in them; only polearm is on-grade.
--    2-handed polearm also can't equip a sub-slot grip, so granted grips are
--    inert.  This mirrors the harmless off-skill weapons Phase 1's WAR OR added.)
-- ----------------------------------------------------------------------------
UPDATE `item_equipment`
    SET `jobs` = `jobs` | 1048576
    WHERE `shieldSize` = 0
      AND ( (`jobs` & 64)      <> 0     -- PLD-equippable (bit 6)
         OR (`jobs` & 2097152) <> 0 );  -- RUN-equippable (bit 21)


-- ============================================================================
-- REVERSE (manual rollback -- restores the post-Phase-1 access state):
--
--   -- re-grant the shields Phase 1 had given (only those still WAR-equippable):
--   UPDATE `item_equipment` SET `jobs` = `jobs` | 1048576
--       WHERE `shieldSize` > 0 AND (`jobs` & 1) <> 0;
--
--   -- strip the PLD/RUN-only gear granted by section 2 (i.e. non-shield PLD/RUN
--   -- items that DRG/WAR do NOT also cover, so Phase-1 access is preserved):
--   UPDATE `item_equipment` SET `jobs` = `jobs` & ~1048576
--       WHERE `shieldSize` = 0
--         AND ( (`jobs` & 64) <> 0 OR (`jobs` & 2097152) <> 0 )
--         AND (`jobs` & 8192) = 0 AND (`jobs` & 1) = 0;   -- not DRG- or WAR-gear
--
-- To strip the Bouncer bit globally instead, see bouncer_chassis.sql's reverse.
-- ============================================================================
