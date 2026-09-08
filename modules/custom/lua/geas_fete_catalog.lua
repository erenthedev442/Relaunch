-----------------------------------
-- geas_fete_catalog.lua
--
-- Geas Fete currency drop numbers. FileWatcher-safe (mutate package.loaded).
-- Geas_Fete.lua is restart-gated; this table is read at award time.
--
-- Beitetsu only. Riftborn Boulders are an Abyssea drop so Geas cannot
-- farm Mythic and Empyrean from the same kill.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/geas_fete_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.BEITETSU          = 4060
C.DROPS_BOULDERS    = false

-- Guaranteed + independent bonus rolls. Treasure Hunter may raise bonus rolls.
-- Mythic I->II is 300 Beitetsu, II->III is 10,000 (10,300 total).
-- T1 stays a trickle; T4 is the farm.
C.BEITETSU_BY_TIER =
{
    -- 3-4, avg 3.5   (~2,940 T1 kills for 10.3k)
    [1] = { guaranteed = 3,  chances = { 50 } },
    -- 10-12, avg 11.3 (~910 T2 kills)
    [2] = { guaranteed = 10, chances = { 80, 50 } },
    -- 25-28, avg 26.7 (~385 T3 kills)
    [3] = { guaranteed = 25, chances = { 80, 70, 50 } },
    -- 55-59, avg 57.7 (~180 T4 kills)
    [4] = { guaranteed = 55, chances = { 90, 80, 60, 40 } },
}

function C.beitetsuExpected(tier)
    local spec = C.BEITETSU_BY_TIER[tier]
    if not spec then
        return 0
    end

    local n = spec.guaranteed
    for _, chance in ipairs(spec.chances) do
        n = n + chance / 100
    end

    return n
end

function C.rollBeitetsu(tier, passFn)
    local spec = C.BEITETSU_BY_TIER[tier] or C.BEITETSU_BY_TIER[1]
    local quantity = spec.guaranteed
    for _, chance in ipairs(spec.chances) do
        if passFn(chance) then
            quantity = quantity + 1
        end
    end

    return quantity
end

return C
