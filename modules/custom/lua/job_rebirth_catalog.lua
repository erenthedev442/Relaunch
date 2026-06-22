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

    -- ===== Rebirth EXP penalty (MULTIPLICATIVE -- a true % cut, augment-proof) =====
    -- Applied by the ENGINE (charutils.cpp AddExpBonus) AFTER all additive EXP_BONUS
    -- (gear augments, food, RoV, Dedication), via the per-main-job [RebirthExpCut]
    -- charVar that JobRebirth.lua sets. So NO amount of +EXP augments can cancel it --
    -- the stated % is always taken off the top. (Switched from an additive EXP_BONUS
    -- ramp on 2026-06-22: a maxed 16-piece augment set is ~+5,000% EXP_BONUS, which an
    -- additive penalty couldn't touch; a multiplicative one always takes its share.)
    -- Linear ramp: caps at expPenaltyMaxCut% reduction at rebirth expPenaltyMaxRebirth,
    -- scaling straight down to rebirth 1.
    --   cut(N) = min(round(N / expPenaltyMaxRebirth * expPenaltyMaxCut), expPenaltyMaxCut)
    --   R1 -4%, R5 -20%, R10 -40%, R15 -60%, R20 -80% (cap), R20+ -80%.
    -- The engine still floors EXP at 5% of base, so a job can never be soft-locked.
    expPenaltyMaxCut     = 80,   -- max EXP reduction % (a true multiplicative cut)
    expPenaltyMaxRebirth = 20,   -- rebirth count at which the cut reaches the cap

    -- Hard cap on rebirths per job. nil = uncapped.
    maxRebirths = nil,
}
