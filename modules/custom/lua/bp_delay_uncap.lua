-----------------------------------
-- bp_delay_uncap.lua
--
-- Makes Summoner "Blood Pact Ability Delay" gear + augments actually scale.
--
-- THE PROBLEM: a Blood Pact's base recast is 60s. The engine
-- (src/map/entities/charentity.cpp:1834) HARD-CAPS the BP_DELAY (mod 357)
-- reduction at 15s and the I+II total at 30s, so a SMN stacking AF/+2 gear AND
-- the "Blood Pact ability delay" augment -- which are ALL mod 357 -- pours
-- everything into one 15s bucket and freezes at 60 - 15 = 45s. Past the first 15
-- points the augment and the AF gear do nothing ("45s regardless of what you do").
--
-- THE FIX: the C++ snapshots the (capped) reduced recast into the "bpRecastTime"
-- localvar at ability-use time; the Lua handler xi.job_utils.summoner.onUseBloodPact
-- re-reads that localvar (summoner.lua:211) when the pact goes off and applies it
-- as the recast. We override that handler, recompute bpRecastTime with the per-mod
-- cap effectively removed (so every point of BP-delay gear/augment counts), clamp
-- to a FLOOR so BPs can't become instant, then delegate to the original via super().
-- Avatar's Favor stays capped at 10 (retail).
--
-- Pure Lua override module -> needs ONE map restart to load (no C++ rebuild). Every
-- BP script calls xi.job_utils.summoner.onUseBloodPact by full path at runtime
-- (scripts/actions/abilities/pets/*.lua), so the override is guaranteed to intercept.
--
-- TUNING: lower CONFIG.floor for faster BP spam; raise it to keep BPs rarer.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/job_utils/summoner')

local m = Module:new('bp_delay_uncap')

local CONFIG =
{
    perModCap = 60, -- per-mod reduction cap (engine stock = 15). 60 = effectively uncapped vs a 60s base.
    floor     = 15, -- a Blood Pact can never recast faster than this many seconds.
    favorCap  = 10, -- Avatar's Favor reduction cap (retail).
}

m:addOverride('xi.job_utils.summoner.onUseBloodPact', function(target, petskill, summoner, action)
    -- Recompute only on the primary target (the original consumes recast there too)
    -- and only when the ability's base recast resolves. Setting bpRecastTime BEFORE
    -- super() means the original reads OUR uncapped value.
    if target:getID() == action:getPrimaryTargetID() then
        local ability = GetAbility(petskill:getID())
        if ability then
            local base  = ability:getRecastTime()

            local favor = 0
            local fav   = summoner:getStatusEffect(xi.effect.AVATARS_FAVOR)
            if fav then
                favor = math.min(fav:getPower(), CONFIG.favorCap)
            end

            local reduction =
                  math.min(summoner:getMod(xi.mod.BP_DELAY),    CONFIG.perModCap)
                + math.min(summoner:getMod(xi.mod.BP_DELAY_II), CONFIG.perModCap)
                + favor

            summoner:setLocalVar('bpRecastTime', math.max(CONFIG.floor, base - reduction))
        end
    end

    super(target, petskill, summoner, action)
end)

return m
