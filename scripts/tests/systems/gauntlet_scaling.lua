local catalog = require('modules/custom/lua/gauntlet_catalog')

describe('Gauntlet damage-ceiling rebalance', function()
    it('uses the reduced ten-level HP curve', function()
        local expected =
        {
            5000000,
            5830000,
            6797779,
            7926211,
            9241962,
            10776128,
            12564965,
            14650749,
            17082774,
            19918515,
        }

        for level, hp in ipairs(expected) do
            assert(catalog.nmHp(level) == hp)
            if level > 1 then
                assert(catalog.nmHp(level) > catalog.nmHp(level - 1))
            end
        end
    end)

    it('scales self-healing with the reduced HP curve', function()
        for level = 1, 10 do
            local drain = catalog.mechCfg(level).drain
            assert(drain.periodSec == 15)
            assert(drain.heal == level * 1000)
        end
    end)
end)
