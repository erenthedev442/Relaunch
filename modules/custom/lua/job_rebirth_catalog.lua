-----------------------------------
-- job_rebirth_catalog.lua
-- Configuration for the Job Rebirth system. Edit this file only --
-- JobRebirth.lua reads it automatically.
--
-- Job Rebirth sits ON TOP of a fully-developed job. Once a job is at level 99
-- with its Job Points maxed, the player may REBIRTH it: the job's level resets
-- to 1 and its Job Points are fully WIPED (a real wipe via the C++
-- player:resetJobPoints() binding -- categories, gifts, capacity, DB). In return
-- the rebirth grants Ascension Points into that job's Ascension pool, spent at
-- the Ascension Altar on the SAME categories Ascension uses (prestige_catalog).
--
-- Each rebirth also stamps a PER-JOB EXP PENALTY that makes the next re-grind
-- harder: a stacking negative EXP_BONUS applied only while that job is active.
-- So the 2nd rebirth's climb to 99 is slower than the 1st, the 3rd slower
-- still, plateauing at expPenaltyCap.
-----------------------------------
return
{
    -- ===== NPC placement (GM Home, zone 210) =====
    -- Near the Cross-Job Trainer row (which sits at x=4.5). Adjust if it clips
    -- or faces wrong (rot is 0-255).
    npcPos = { x = 3.000, y = 0.000, z = -7.000, rot = 128 },

    -- ===== Eligibility =====
    -- A job is "maxed" (rebirth-eligible) when its TOTAL job points spent for
    -- the current main job reaches this. Spending JP requires level 99, so this
    -- also implies max level. 2100 = the live MAX_JOB_POINTS ceiling.
    jpRequired = 2100,

    -- ===== Reward =====
    -- Ascension Points granted per rebirth, banked into the job's Ascension
    -- pool (CharVar Prestige_AP_<job>) and spent at the Ascension Altar on the
    -- shared category tree (prestige_catalog.categories).
    apPerRebirth = 10,

    -- ===== Escalating exp penalty (the "harder each time" knob) =====
    -- Per-job: each rebirth adds this many % to the exp penalty (applied as a
    -- negative EXP_BONUS mod while that job is active). Capped so leveling is
    -- always possible.
    --   penalty(rebirths) = min(rebirths * expPenaltyPerRebirth, expPenaltyCap)
    -- e.g. 15/cap 90 -> R1 -15%, R2 -30%, ... R6 -90% (then plateau; always >=10% exp).
    expPenaltyPerRebirth = 15,
    expPenaltyCap        = 90,

    -- Hard cap on rebirths per job. nil = uncapped.
    maxRebirths = nil,
}
