-----------------------------------
-- job_rebirth_catalog.lua
-- Configuration for the Job Rebirth system. Edit this file only --
-- JobRebirth.lua reads it automatically.
--
-- Job Rebirth is a STANDALONE prestige system. It is NOT tied to Ascension:
-- it has its own currency (Rebirth Points), its own per-job boost levels, its
-- own caps, its own apply, and its own NPC. The ONLY thing it borrows from
-- Ascension is the boost CATEGORY LIST (prestige_catalog.categories) -- the same
-- stats, so the two systems offer matching boosts -- but it stores, caps, and
-- applies them entirely on its own (a separate, stacking track).
--
-- Flow: max a job (lv99 + Job Points maxed) -> rebirth it (level -> 1, Job
-- Points fully wiped via player:resetJobPoints()) -> earn Rebirth Points ->
-- spend them at the Rebirth NPC on the boost categories. Each rebirth also
-- stamps an escalating PER-JOB exp penalty so every re-grind is harder.
-----------------------------------
return
{
    -- ===== NPC placement (RuLude Gardens, zone 243) =====
    npcZone = 243,
    npcPos  = { x = 0.2612, y = 0.0000, z = 30.0492, rot = 62 },

    -- ===== Eligibility =====
    -- A job is rebirth-eligible when its TOTAL job points spent (current main
    -- job) reaches this. Spending JP needs level 99, so this also implies max
    -- level. 2100 = the live MAX_JOB_POINTS ceiling.
    jpRequired = 2100,

    -- ===== Reward currency =====
    -- Rebirth Points granted per rebirth (this system's OWN currency, CharVar
    -- Rebirth_RP_<job>). Spent at the Rebirth NPC on the boost categories.
    -- Categories reuse Ascension's per-level cost (apCost) so relative prices
    -- stay sensible; tune these to set how many levels a rebirth buys.
    -- Formula: min(rpBase + (rebirthNumber - 1) * rpPerLevel, rpMax)
    --   Rebirth 1: 10, Rebirth 2: 12, Rebirth 3: 14, Rebirth 4: 16, Rebirth 5: 18, Rebirth 6+: 20
    rpBase     = 10,
    rpPerLevel =  2,
    rpMax      = 20,

    -- ===== Escalating exp penalty (the "harder each time" knob) =====
    -- Triangular scaling: rebirth N adds N*expPenaltyPerRebirth% more than the
    -- previous one, so the penalty accelerates and eventually overwhelms any EXP
    -- augment stack. No cap: the engine's own floor (~0 EXP/kill) is the ceiling.
    --   penalty(N) = N*(N+1)/2 * expPenaltyPerRebirth
    --   R1: 10%   R2: 30%   R3: 60%   R4: 100% (floor w/o augs)
    --   R5: 150%  R6: 210%  R7: 280%  R8: 360% ...
    -- A player stacking 6 EXP augment pieces (+198%) still hits the floor at R6.
    expPenaltyPerRebirth = 10,
    expPenaltyCap        = nil,

    -- Hard cap on rebirths per job. nil = uncapped.
    maxRebirths = nil,
}
