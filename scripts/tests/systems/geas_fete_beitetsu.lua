local C = require('modules/custom/lua/geas_fete_catalog')

describe('Geas Fete Beitetsu', function()
    it('does not drop Riftborn Boulders', function()
        assert(C.DROPS_BOULDERS == false)
    end)

    it('pays more Beitetsu on higher tiers', function()
        assert(C.beitetsuExpected(1) < C.beitetsuExpected(2))
        assert(C.beitetsuExpected(2) < C.beitetsuExpected(3))
        assert(C.beitetsuExpected(3) < C.beitetsuExpected(4))
        assert(C.BEITETSU_BY_TIER[1].guaranteed == 3)
        assert(C.BEITETSU_BY_TIER[4].guaranteed == 42)
    end)

    it('does not sell Beitetsu, Plutons, or Riftborn Boulders for beads', function()
        local file = assert(io.open('modules/custom/lua/Geas_Fete.lua', 'r'))
        local text = file:read('*a')
        file:close()

        assert(not text:find("label='Beitetsu'", 1, true))
        assert(not text:find("label='Pluton'", 1, true))
        assert(not text:find("label='Riftborn", 1, true))
        assert(text:find("label='Riftcinder'", 1, true))
    end)

    it('always grants the tier floor when bonus rolls fail', function()
        local none = function() return false end
        assert(C.rollBeitetsu(1, none) == 3)
        assert(C.rollBeitetsu(2, none) == 10)
        assert(C.rollBeitetsu(3, none) == 25)
        assert(C.rollBeitetsu(4, none) == 42)
        local all = function() return true end
        assert(C.rollBeitetsu(4, all) == 52)
    end)
end)
