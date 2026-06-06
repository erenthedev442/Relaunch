-----------------------------------
-- bouncer_abilities.lua   (Phase 3 of the custom "Bouncer" tank job, Lua half)
--
-- Rewrites the repurposed GEO (job 21) ability BEHAVIOURS into the Bouncer's
-- tank kit, WITHOUT editing any upstream-tracked file.  It overrides the
-- relevant xi.job_utils.geomancer.* functions in place via the module-override
-- framework (modules/module_utils.lua), so it survives LSB merges and needs no
-- recompile -- only a map-server restart.  See the DB half in
-- modules/custom/sql/bouncer_abilities.sql and the full design in
-- documentation/custom_tank_job_design.md.
--
-- "Same socket, new content": each Bouncer ability reuses an existing GEO
-- abilityId (the client already knows job 21's JA menu slots) and only changes
-- what it does + how it targets.  The donor GEO ability NAME still shows in the
-- client until the Phase-6 DAT pack relabels it -- cosmetic only.
--
-- DONOR -> BOUNCER ABILITY MAP (recastIds are all distinct => no shared timers):
--   343 bolster           -> Last Call      (2hr: can't-die + max reflect/leech)
--   345 full_circle       -> Step Outside   (single-target taunt)
--   347 ecliptic_attrition-> Sucker Punch   (single-target Stun + claim)
--   348 collimated_fervor -> Bodyguard      (grant an ally a brief invuln)
--   349 life_cycle        -> Retaliate      (self reflect/leech stance)
--   350 blaze_of_glory    -> Brace          (self damage-taken reduction)
--   351 dematerialize     -> Hold the Line  (self brief full invuln)
--   352 theurgic_focus    -> Bloodbind      (self heal, % of max HP)
--   377 widened_compass   -> Crowd Control  (AoE threat reinforce; engine enmity)
--
-- WHY THESE DONORS: every one is a NORMAL (non-pet) ability whose action file
-- delegates to an overridable xi.job_utils.geomancer.* function, and each has a
-- distinct recastId.  The luopan/pet abilities (353-355) are deliberately NOT
-- used -- a pet ability used by the (pet-less) Bouncer never reaches its Lua
-- handler or the engine enmity step (charentity.cpp::OnAbility takes the pet
-- branch and finds no pet), so it would be inert.
--
-- REFLECT/LEECH MECHANISM (Last Call / Retaliate, v1, rebuild-free):
--   Reuses the Dread Spikes status effect (xi.effect.DREAD_SPIKES).  Its C++
--   handler reflects the full post-mitigation damage taken back at the attacker
--   AND heals the defender by that amount until the effect's subPower "drain
--   budget" is exhausted.  So the v1 tuning levers are DURATION and BUDGET.
--
-- TUNING: the locals below are the only knobs.
-----------------------------------
require('modules/module_utils')

local m = Module:new('bouncer_abilities')

-- ---- Tuning knobs (starting values; balance pass = design doc Phase 7) ------
local RETALIATE_DURATION   = 180    -- seconds of reflect/leech uptime per cast
local RETALIATE_DRAIN_MULT = 3      -- Retaliate drain budget = maxHP * this
local LAST_CALL_DURATION   = 30     -- seconds of can't-die + full reflect/leech
local SUBPOWER_CAP         = 65000  -- hard ceiling: subPower is stored as uint16

local SUCKER_PUNCH_STUN      = 5    -- seconds of Stun on the struck enemy
local BODYGUARD_DURATION     = 5    -- seconds of full invuln granted to an ally
local BRACE_DURATION         = 60   -- seconds of damage-taken reduction
local BRACE_DMG_REDUCTION    = 2500 -- DMG mod magnitude (10000 = 100%) => -25% DT
local HOLD_THE_LINE_DURATION = 6    -- seconds of self full invuln
local BLOODBIND_HEAL_PCT     = 25   -- self-heal as a percentage of max HP

-- ---- Constants --------------------------------------------------------------
-- Repurposed GEO abilityIds whose action files route their CHECK through the
-- shared generic geoOnAbilityCheck.  Allow ONLY these for the (luopan-less)
-- Bouncer; every other ability that still funnels through that check defers to
-- the original (=> returns "requires luopan", staying correctly un-castable).
local GENERIC_CHECK_ALLOW =
{
    [345] = true,   -- full_circle   -> Step Outside  (taunt)
    [351] = true,   -- dematerialize -> Hold the Line (self invuln)
}

-- (Re)apply the Dread Spikes reflect+leech stance to a battle entity.
-- drainBudget = total incoming damage the stance may reflect/leech before it
-- drops; clamped to the uint16 subPower ceiling.
local function applyDreadStance(entity, duration, drainBudget)
    local budget = math.min(math.floor(drainBudget), SUBPOWER_CAP)

    -- Clean refresh: clear any prior stance so the new budget/duration take.
    entity:delStatusEffect(xi.effect.DREAD_SPIKES)
    entity:addStatusEffect(xi.effect.DREAD_SPIKES, {
        power    = 1,         -- unused for Dread (reflect = full damage taken)
        duration = duration,
        origin   = entity,
        subPower = budget,    -- drain budget read by HandleSpikesDamage
        tier     = 1,
    })
end

-----------------------------------
-- Ability CHECK overrides (remove the luopan gate)
-----------------------------------

-- Shared generic GEO check.  Allow the repurposed abilities in the allow-set;
-- for everything else that still funnels through here, defer to the original.
m:addOverride('xi.job_utils.geomancer.geoOnAbilityCheck',
    function(player, target, ability)
        if GENERIC_CHECK_ALLOW[ability:getID()] then
            return 0, 0
        end

        return super(player, target, ability)
    end)

-- life_cycle (349 -> Retaliate) is the sole caller of this check, so a blanket
-- allow is safe.
m:addOverride('xi.job_utils.geomancer.geoOnLifeCycleAbilityCheck',
    function(player, target, ability)
        return 0, 0
    end)

-- ecliptic_attrition (347 -> Sucker Punch) is the sole caller of this check
-- (verified: only ecliptic_attrition.lua references it), so a blanket allow is
-- safe -- it drops the luopan gate the Bouncer can never satisfy.
m:addOverride('xi.job_utils.geomancer.geoOnEclipticAttritionCheck',
    function(player, target, ability)
        return 0, 0
    end)

-- NOTE: 350 Brace (blaze_of_glory) and 377 Crowd Control (widened_compass)
-- already have OPEN checks (return 0,0) in their stock action files, and 352
-- Bloodbind (theurgic_focus) routes through geoOnTheurgicFocusCheck, which only
-- blocks if THEURGIC_FOCUS is already active (the Bouncer never applies it) --
-- so none of those three need a check override.

-----------------------------------
-- Ability USE overrides (tank behaviours)
-----------------------------------

-- 343 bolster -> "Last Call" (2hr): brief can't-die window with maximum
-- reflect + full leech.  setUnkillable floors HP at 1 on lethal damage
-- (battleentity.cpp::addHP); a queued timer restores killability after the
-- window.  The huge (capped) drain budget means Dread Spikes never runs dry
-- during the window => effectively 100% reflect/leech for its duration.
m:addOverride('xi.job_utils.geomancer.bolster',
    function(player, target, ability)
        player:setUnkillable(true)
        player:timer(LAST_CALL_DURATION * 1000, function(self)
            self:setUnkillable(false)
        end)

        applyDreadStance(player, LAST_CALL_DURATION, SUBPOWER_CAP)

        return xi.effect.DREAD_SPIKES
    end)

-- 345 full_circle -> "Step Outside" (single-target taunt).  Intentionally
-- blank: enmity is applied by the engine from the ability's CE/VE columns when
-- it lands on the enemy target (validTarget=4), exactly like Provoke's empty
-- handler.  Nothing to do in Lua.
m:addOverride('xi.job_utils.geomancer.fullCircle',
    function(player, target, ability)
        -- Taunt enmity is data-driven (abilities.sql CE/VE). No-op by design.
    end)

-- 347 ecliptic_attrition -> "Sucker Punch" (single-target Stun).  Lands on an
-- enemy (validTarget=4); briefly stuns it.  The threat (it also claims the mob)
-- comes from the engine reading this ability's CE/VE -- this handler only adds
-- the Stun.  Mirrors PLD Shield Bash (paladin.lua) which stuns the same way.
m:addOverride('xi.job_utils.geomancer.eclipticAttrition',
    function(player, target, ability, action)
        if target then
            target:addStatusEffect(xi.effect.STUN, { power = 1, duration = SUCKER_PUNCH_STUN, origin = player })
        end
    end)

-- 348 collimated_fervor -> "Bodyguard" (grant an ally a brief full invuln).
-- Reuses the DEMATERIALIZE effect (full phys/magic/breath immunity) on the
-- targeted party member.  Falls back to self if somehow target-less.
m:addOverride('xi.job_utils.geomancer.collimatedFervor',
    function(player, target, ability)
        local ward = target or player
        ward:addStatusEffect(xi.effect.DEMATERIALIZE, { power = 1, duration = BODYGUARD_DURATION, origin = player })

        return xi.effect.DEMATERIALIZE
    end)

-- 350 blaze_of_glory -> "Brace" (self damage-taken reduction).  Applies the
-- BLAZE_OF_GLORY effect with power = BRACE_DMG_REDUCTION; the Bouncer effect
-- script (scripts/effects/blaze_of_glory.lua) turns that into DMG -power.
m:addOverride('xi.job_utils.geomancer.blazeOfGlory',
    function(player, target, ability)
        player:addStatusEffect(xi.effect.BLAZE_OF_GLORY, { power = BRACE_DMG_REDUCTION, duration = BRACE_DURATION, origin = player })

        return xi.effect.BLAZE_OF_GLORY
    end)

-- 349 life_cycle -> "Retaliate" (self reflect/leech stance).  Replaces the GEO
-- "transfer 25% HP to the luopan" entirely.  Drain budget scales with the
-- tank's (large) max HP so the stance holds through sustained punishment.
m:addOverride('xi.job_utils.geomancer.lifeCycle',
    function(player, target, ability, action)
        applyDreadStance(player, RETALIATE_DURATION, player:getMaxHP() * RETALIATE_DRAIN_MULT)

        return xi.effect.DREAD_SPIKES
    end)

-- 351 dematerialize -> "Hold the Line" (self brief full invuln).  Reuses the
-- DEMATERIALIZE effect (full phys/magic/breath immunity) on the Bouncer.
m:addOverride('xi.job_utils.geomancer.dematerialize',
    function(player, target, ability, action)
        player:addStatusEffect(xi.effect.DEMATERIALIZE, { power = 1, duration = HOLD_THE_LINE_DURATION, origin = player })

        return xi.effect.DEMATERIALIZE
    end)

-- 352 theurgic_focus -> "Bloodbind" (self heal).  Heals a percentage of max HP.
-- NOTE: theurgic_focus.lua calls this as (player, ability, action) -- no target
-- arg -- which is fine for a self-cast; the override signature matches that.
m:addOverride('xi.job_utils.geomancer.theurgicFocus',
    function(player, ability, action)
        player:addHP(math.floor(player:getMaxHP() * BLOODBIND_HEAL_PCT / 100))

        return 0
    end)

-- 377 widened_compass -> "Crowd Control" (AoE threat reinforce).  Intentionally
-- blank: with validTarget=1 (self) the engine's ApplyEnmity calls
-- GenerateInRangeEnmity(CE,VE), reinforcing threat on every mob already engaged
-- with the Bouncer (a Warcry-style AoE enmity boost).  Nothing to do in Lua.
m:addOverride('xi.job_utils.geomancer.widenedCompass',
    function(player, target, ability)
        -- AoE enmity is data-driven (abilities.sql CE/VE). No-op by design.
    end)

return m
