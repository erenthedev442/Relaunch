-- ============================================================================
-- bouncer_abilities.sql   (Phase 3 of the custom "Bouncer" tank job, DB half)
--
-- Re-stats the repurposed GEO (job 21) ability ROWS into the Bouncer's tank
-- kit.  The behaviour (what each ability DOES) is rewritten in the Lua half:
-- modules/custom/lua/bouncer_abilities.lua.  This file only adjusts the data
-- columns the C++ ability pipeline reads directly (targeting, recast, range,
-- enmity, learn level, message).  See documentation/custom_tank_job_design.md.
--
-- "Same socket, new content": we keep the original GEO abilityIds (the client
-- already knows their JA menu slots) and only change what they do + how they
-- target.  Phase 6 (DAT pack) relabels the names/icons cosmetically.
--
-- DONOR GEO row -> BOUNCER ability (full kit; recastIds are all distinct):
--   343 bolster            -> Last Call      (NO row change -- pure Lua)
--   345 full_circle        -> Step Outside   (single-target taunt)
--   347 ecliptic_attrition -> Sucker Punch   (single-target Stun + claim)
--   348 collimated_fervor  -> Bodyguard      (grant an ally a brief invuln)
--   349 life_cycle         -> Retaliate      (self reflect/leech stance)
--   350 blaze_of_glory     -> Brace          (self damage-taken reduction)
--   351 dematerialize      -> Hold the Line  (self brief full invuln)
--   352 theurgic_focus     -> Bloodbind      (self heal)
--   377 widened_compass    -> Crowd Control  (AoE threat reinforce)
--
-- Enmity is engine-driven from CE/VE (ability_state.cpp::ApplyEnmity):
--   * enemy target (validTarget=4) => single-target UpdateEnmity + ClaimMob
--     (this is how Step Outside taunts and Sucker Punch claims the mob).
--   * self/ally target            => GenerateInRangeEnmity(CE,VE), reinforcing
--     threat on every mob already engaged with the Bouncer (Crowd Control).
--   CE=0/VE=0 on the self buffs (Brace/Hold the Line/Bloodbind) and on Bodyguard
--   means they generate no enmity.
--
-- message1 is set to 0 on every repurposed row so the client shows the plain
-- "uses <ability>" line (the GEO flavour messages would mis-describe the new
-- behaviour); the status effects supply their own gain messages.  message2 is
-- engine-unused.
--
-- This is data-only: no recompile.  A map-server restart reloads the changes.
--
-- Apply once against the live database:
--   "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/bouncer_abilities.sql
--
-- Idempotent: every statement SETs explicit absolute values keyed by abilityId,
-- so re-applying is a deterministic no-op.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. full_circle (345) -> "Step Outside" : single-target taunt.
--    Provoke-grade: enemy target, range 16, CE=1/VE=1800.
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `validTarget` = 4,
        `recastTime`  = 30,
        `range`       = 16.0,
        `CE`          = 1,
        `VE`          = 1800,
        `message1`    = 0,
        `message2`    = 0
    WHERE `abilityId` = 345;   -- full_circle -> Step Outside (taunt)


-- ----------------------------------------------------------------------------
-- 2. ecliptic_attrition (347) -> "Sucker Punch" : single-target Stun + claim.
--    Enemy target (validTarget 1 -> 4), range 0 -> 16, recast 300 -> 60.
--    CE=1/VE=400 so the punch also claims/holds the struck mob; the Lua handler
--    adds the Stun.  (Shares no recast timer with any other Bouncer ability.)
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `validTarget` = 4,
        `recastTime`  = 60,
        `range`       = 16.0,
        `CE`          = 1,
        `VE`          = 400,
        `message1`    = 0,
        `message2`    = 0
    WHERE `abilityId` = 347;   -- ecliptic_attrition -> Sucker Punch (Stun)


-- ----------------------------------------------------------------------------
-- 3. collimated_fervor (348) -> "Bodyguard" : grant an ally a brief invuln.
--    Party target (validTarget 1 -> 2), range 0 -> 16, recast 300 -> 180.
--    CE=0/VE=0 (no enmity -- it just wards the ally).  Needs the additive action
--    file scripts/actions/abilities/collimated_fervor.lua (stock ships none).
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `validTarget` = 2,
        `recastTime`  = 180,
        `range`       = 16.0,
        `CE`          = 0,
        `VE`          = 0,
        `message1`    = 0,
        `message2`    = 0
    WHERE `abilityId` = 348;   -- collimated_fervor -> Bodyguard (ally invuln)


-- ----------------------------------------------------------------------------
-- 4. life_cycle (349) -> "Retaliate" : self reflect/leech stance.
--    Stays self-target; recast 600 -> 30 so the 180s Lua stance is ~permanent.
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `recastTime` = 30,
        `message1`   = 0,
        `message2`   = 0
    WHERE `abilityId` = 349;   -- life_cycle -> Retaliate (reflect/leech stance)


-- ----------------------------------------------------------------------------
-- 5. blaze_of_glory (350) -> "Brace" : self damage-taken reduction.
--    Stays self-target; recast 600 -> 120 (60s Lua duration => 50% uptime).
--    CE=0/VE=0 (no enmity).
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `validTarget` = 1,
        `recastTime`  = 120,
        `CE`          = 0,
        `VE`          = 0,
        `message1`    = 0,
        `message2`    = 0
    WHERE `abilityId` = 350;   -- blaze_of_glory -> Brace (damage-taken down)


-- ----------------------------------------------------------------------------
-- 6. dematerialize (351) -> "Hold the Line" : self brief full invuln.
--    Stays self-target; recast 600 -> 180.  CE=0/VE=0 (no enmity).
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `validTarget` = 1,
        `recastTime`  = 180,
        `CE`          = 0,
        `VE`          = 0,
        `message1`    = 0,
        `message2`    = 0
    WHERE `abilityId` = 351;   -- dematerialize -> Hold the Line (self invuln)


-- ----------------------------------------------------------------------------
-- 7. theurgic_focus (352) -> "Bloodbind" : self heal.
--    Stays self-target; recast 300 -> 90.  CE=0/VE=0 (no enmity).
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `validTarget` = 1,
        `recastTime`  = 90,
        `CE`          = 0,
        `VE`          = 0,
        `message1`    = 0,
        `message2`    = 0
    WHERE `abilityId` = 352;   -- theurgic_focus -> Bloodbind (self heal)


-- ----------------------------------------------------------------------------
-- 8. widened_compass (377) -> "Crowd Control" : AoE threat reinforce.
--    Self target (validTarget=1) so ApplyEnmity calls GenerateInRangeEnmity,
--    reinforcing threat (CE=1/VE=1800, Provoke-grade) on every mob already
--    engaged with the Bouncer.  recast 3600 -> 60.  level 96 -> 30 so it
--    unlocks at a sensible tank level (the abilities list is loaded ORDER BY
--    level, so re-stating the level re-gates learning correctly).
-- ----------------------------------------------------------------------------
UPDATE `abilities`
    SET `validTarget` = 1,
        `level`       = 30,
        `recastTime`  = 60,
        `CE`          = 1,
        `VE`          = 1800,
        `message1`    = 0,
        `message2`    = 0
    WHERE `abilityId` = 377;   -- widened_compass -> Crowd Control (AoE threat)


-- NOTE: 343 bolster -> "Last Call" intentionally has NO row change here.
-- It is already validTarget=1 (self), 3600s recast, open check; its new
-- behaviour (setUnkillable + max Dread Spikes) is implemented entirely in
-- modules/custom/lua/bouncer_abilities.lua.


-- ============================================================================
-- REVERSE (manual rollback -- restores the original GEO ability rows):
--
--   UPDATE `abilities` SET `validTarget`=1, `recastTime`=10, `range`=0.0,
--          `CE`=1, `VE`=300, `message1`=0,   `message2`=0   WHERE `abilityId`=345;
--   UPDATE `abilities` SET `validTarget`=1, `recastTime`=300,`range`=0.0,
--          `CE`=1, `VE`=300, `message1`=664, `message2`=0   WHERE `abilityId`=347;
--   UPDATE `abilities` SET `validTarget`=1, `recastTime`=300,`range`=0.0,
--          `CE`=1, `VE`=300, `message1`=100, `message2`=0   WHERE `abilityId`=348;
--   UPDATE `abilities` SET `recastTime`=600,`message1`=306, `message2`=309
--          WHERE `abilityId`=349;
--   UPDATE `abilities` SET `validTarget`=1, `recastTime`=600,
--          `CE`=1, `VE`=300, `message1`=100, `message2`=0   WHERE `abilityId`=350;
--   UPDATE `abilities` SET `validTarget`=1, `recastTime`=600,
--          `CE`=1, `VE`=300, `message1`=319, `message2`=0   WHERE `abilityId`=351;
--   UPDATE `abilities` SET `validTarget`=1, `recastTime`=300,
--          `CE`=1, `VE`=300, `message1`=100, `message2`=0   WHERE `abilityId`=352;
--   UPDATE `abilities` SET `validTarget`=1, `level`=96, `recastTime`=3600,
--          `CE`=1, `VE`=300, `message1`=100, `message2`=0   WHERE `abilityId`=377;
--
-- (343 bolster was never changed here, so nothing to revert for Last Call.)
-- Then remove modules/custom/lua/bouncer_abilities.lua, the additive action file
-- scripts/actions/abilities/collimated_fervor.lua, and the additive effect file
-- scripts/effects/blaze_of_glory.lua to restore stock GEO Lua.
-- ============================================================================
