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

    -- ===== Reward currency (accelerating curve + milestones) =====
    -- Rebirth Points granted per rebirth (this system's OWN currency, CharVar
    -- Rebirth_RP_<job>). Spent at the Rebirth NPC on the boost categories.
    -- Later rebirths pay more to compensate for the escalating EXP penalty.
    --
    -- Formula: floor(rpMin + rpScale * (count^rpPower - 1)) + milestone bonus
    --   rpMin   = RP at R1 (curve always starts here)
    --   rpPower = exponent > 1 accelerates; = 1 is linear; < 1 is diminishing
    -- Approx values: R1=10, R5=19, R10=34, R15=59, R20=73, R30=114
    -- Milestones (R10, R20, R30, ...): add rpMilestoneBonus on top of the curve.
    rpMin            = 10,   -- RP at first rebirth
    rpScale          = 1.3,  -- acceleration coefficient
    rpPower          = 1.3,  -- curve exponent (>1 = accelerating)
    rpMilestoneEvery = 10,   -- milestone bonus every N rebirths
    rpMilestoneBonus = 30,   -- extra RP at each milestone (R10: 64, R20: 103, R30: 144)

    -- ===== Rebirth EXP penalty (MULTIPLICATIVE -- a true % cut, augment-proof) =====
    -- Applied by the ENGINE (charutils.cpp AddExpBonus) AFTER all additive EXP_BONUS
    -- (gear augments, food, RoV, Dedication), via the per-main-job [RebirthExpCut]
    -- charVar that JobRebirth.lua sets. So NO amount of +EXP augments can cancel it --
    -- the stated % is always taken off the top.
    --
    -- Accelerating curve (mirrors the RP award curve):
    --   cut(N) = min(floor(expPenaltyMin + expPenaltyScale*(N^rpPower - 1)) + milestone, expPenaltyHardCap)
    -- rpPower and rpMilestoneEvery are SHARED with the RP curve -- both accelerate in
    -- lock-step, so tuning the curve shape keeps penalty and reward correlated.
    -- Milestone extra fires at the same rebirths as the RP bonus (R10, R20, R30, ...).
    --   R1=-4%, R5=-11%, R10=-32% (milestone), R20=-64% (milestone), R30+→-90% (cap)
    -- The engine floors EXP at 5% of base, so a job can never be truly soft-locked.
    expPenaltyMin            =  4,   -- penalty % at R1 (curve always starts here)
    expPenaltyScale          =  1.1, -- acceleration coefficient (mirrors rpScale shape)
    expPenaltyMilestoneExtra =  8,   -- extra penalty % at each milestone (same trigger as RP bonus)
    expPenaltyHardCap        = 90,   -- absolute ceiling

    -- Hard cap on rebirths per job. nil = uncapped.
    maxRebirths = nil,
}
