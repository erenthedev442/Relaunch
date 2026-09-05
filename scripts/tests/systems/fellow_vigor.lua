-- Vigor is 2.5 REGEN per allocated point (250 at the 100 cap). The fellow
-- power curve is 0.005-0.10 for the first half of the build; floor(pts * 0.005)
-- was 0, which is why maxed Vigor showed no regen. Sustain mods apply at face value.

describe('Fellow Vigor regen allocation', function()
    local allocatedModAmount

    before_each(function()
        require('modules/custom/lua/fellow_companion')
        allocatedModAmount = xi.fellow.allocatedModAmount
    end)

    it('applies maxed Vigor at face value on the early power curve', function()
        assert(allocatedModAmount(xi.mod.REGEN, 2.5, 100, 0.005) == 250)
        assert(allocatedModAmount(xi.mod.REGEN, 2.5, 100, 0.10) == 250)
        assert(allocatedModAmount(xi.mod.REGEN, 2.5, 100, 1.0) == 250)
        assert(allocatedModAmount(xi.mod.REGEN, 2.5, 1, 0.005) == 2)
        assert(allocatedModAmount(xi.mod.REGEN, 2.5, 0, 1.0) == 0)
    end)

    it('still scales damage tracks through fellowPowerProgress', function()
        assert(allocatedModAmount(xi.mod.ATT, 3, 100, 0.005) == 1)
        assert(allocatedModAmount(xi.mod.ATT, 3, 100, 1.0) == 300)
    end)
end)
