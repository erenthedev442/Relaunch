-----------------------------------
-- bp_delay_uncap.lua
--
-- Makes Summoner "Blood Pact Ability Delay" gear + augments actually scale.
--
-- THE PROBLEM: a Blood Pact's engine recast is 60s. The C++ snapshot
-- (src/map/entities/charentity.cpp:1834) HARD-CAPS the BP_DELAY (mod 357)
-- reduction at 15s and the I+II total at 30s, so a SMN stacking AF/+2 gear AND
-- the "Blood Pact ability delay" augment -- which are ALL mod 357 -- pours
-- everything into one 15s bucket and freezes at 60 - 15 = 45s. Past the first 15
-- points the augment and the AF gear do nothing ("45s regardless of what you do").
--
-- THE FIX: the C++ snapshots the (capped) reduced recast into the "bpRecastTime"
-- localvar at ability-use time; the Lua handler xi.job_utils.summoner.onUseBloodPact
-- re-reads that localvar (summoner.lua:211) when the pact goes off and applies it
-- as the recast. We override that handler, recompute bpRecastTime with Relaunch's
-- 20s native base, raised per-mod cap, and 6s floor, then delegate via super().
-- Avatar's Favor stays capped at 10 (retail). Astral Conduit bypasses the floor.
--
-- Pure Lua override module -> needs ONE map restart to load (no C++ rebuild). Every
-- BP script calls xi.job_utils.summoner.onUseBloodPact by full path at runtime
-- (scripts/actions/abilities/pets/*.lua), so the override is guaranteed to intercept.
--
-- TUNING: 20 seconds is the uninvested Relaunch recast. Gear, augments and
-- Avatar's Favor then reduce toward a 6-second floor. Astral Conduit still
-- bypasses that floor so the job ability remains a true burst window.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/job_utils/summoner')

local m = Module:new('bp_delay_uncap')

local CONFIG =
{
    base      = 20, -- Relaunch native Rage/Ward recast before delay gear.
    perModCap = 24, -- was 60; engine stock is 15. Gear/augments still count past 15.
    floor     = 6,  -- maximum normal frequency: one Rage and one Ward per 6s each.
    favorCap  = 10, -- Avatar's Favor reduction cap (retail). Unchanged.
}

xi.job_utils.summoner.getRelaunchBloodPactRecast = function(summoner)
    if summoner:hasStatusEffect(xi.effect.ASTRAL_CONDUIT) then
        return 0
    end

    local favor = 0
    local fav   = summoner:getStatusEffect(xi.effect.AVATARS_FAVOR)
    if fav then
        favor = math.min(math.max(fav:getPower(), 0), CONFIG.favorCap)
    end

    local delayI  = math.min(math.max(summoner:getMod(xi.mod.BP_DELAY), 0), CONFIG.perModCap)
    local delayII = math.min(math.max(summoner:getMod(xi.mod.BP_DELAY_II), 0), CONFIG.perModCap)

    return math.max(CONFIG.floor, CONFIG.base - delayI - delayII - favor)
end

m:addOverride('xi.job_utils.summoner.onUseBloodPact', function(target, petskill, summoner, action)
    -- Recompute only on the primary target (the original consumes recast there too)
    -- and only when the ability's base recast resolves. Setting bpRecastTime BEFORE
    -- super() means the original reads OUR uncapped value.
    -- Recompute the BP recast with Relaunch's raised per-mod cap.
    -- WRAPPED IN pcall so a binding hiccup can NEVER abort super() again. THE BUG:
    -- the old `ability:getRecastTime()` binding does not exist -> it threw HERE,
    -- BEFORE super(), so the original onUseBloodPact never ran and EVERY Blood Pact
    -- did 0 damage (all avatars, not just Siren). super() must always fire.
    pcall(function()
        if target:getID() == action:getPrimaryTargetID() then
            summoner:setLocalVar(
                'bpRecastTime',
                xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner))
        end
    end)

    super(target, petskill, summoner, action)
end)

return m
