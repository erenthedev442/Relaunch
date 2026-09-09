-----------------------------------
-- abyssea_boulder_catalog.lua
--
-- Riftborn Boulder payouts for Abyssea marks NMs. FileWatcher-safe
-- (mutate package.loaded). AbysseaMarks.lua is restart-gated; this table
-- is read at award time.
--
-- Empyrean forge needs 300 (I->II) + 3000 (II->III) = 3300 for one 119 III.
-- Old 1-3 (avg 2.2 with a 2.5% Case) was ~1,480 kills. Heroes is the farm;
-- Visions stays a trickle.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/abyssea_boulder_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.RIFTBORN_BOULDER = 4061
C.BOULDER_CASE     = 6182
C.EMPY_BOULDERS    = 3300

-- Case item itself still opens to 3-15 (scripts/items/boulder_case.lua).
-- caseRate only changes how often the Case drops.
--
-- Expected raw + Case, and kills for one Empy (3300):
--   T1  4-6   avg  5.0 + 5% Case  ~5.5    (~605 kills)
--   T2  8-12  avg 10.0 + 8% Case  ~10.7   (~308 kills)
--   T3 20-30  avg 25.0 + 12% Case ~26.1   (~126 kills)
C.BY_TIER =
{
    [1] = { min =  4, max =  6, caseRate = 0.05 },
    [2] = { min =  8, max = 12, caseRate = 0.08 },
    [3] = { min = 20, max = 30, caseRate = 0.12 },
}

function C.spec(tier)
    return C.BY_TIER[tier] or C.BY_TIER[1]
end

function C.expectedRaw(tier)
    local spec = C.spec(tier)
    return (spec.min + spec.max) / 2
end

function C.expectedWithCase(tier)
    -- Boulder Case opens 3-15, average 9.
    return C.expectedRaw(tier) + C.spec(tier).caseRate * 9
end

function C.empyKills(tier)
    local expected = C.expectedWithCase(tier)
    if expected <= 0 then
        return 0
    end

    return C.EMPY_BOULDERS / expected
end

function C.rollBoulders(tier, randInt)
    local spec = C.spec(tier)
    local rng = randInt or math.random
    return rng(spec.min, spec.max)
end

function C.rollCase(tier, rand01)
    local spec = C.spec(tier)
    local rng = rand01 or math.random
    return rng() < spec.caseRate
end

return C
