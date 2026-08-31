local levelingHpCap = require('modules/custom/lua/leveling_hp_cap')

describe('Legendary leveling HP cap', function()
    local function makeTarget(maxHp, isMob)
        return
        {
            isMob = function()
                return isMob ~= false
            end,
            getMaxHP = function()
                return maxHp
            end,
        }
    end

    it('clamps sub-99 hits to 33% of mob max HP', function()
        local target = makeTarget(10000)
        assert(levelingHpCap.apply(50, target, 9000) == 3300)
        assert(levelingHpCap.apply(98, target, 3300) == 3300)
        assert(levelingHpCap.apply(1, target, 100) == 100)
    end)

    it('does not clamp at level 99+', function()
        local target = makeTarget(10000)
        assert(levelingHpCap.apply(99, target, 9000) == 9000)
        assert(levelingHpCap.apply(119, target, 9000) == 9000)
    end)

    it('leaves non-mobs, heals, and empty targets alone', function()
        assert(levelingHpCap.apply(50, makeTarget(10000, false), 9000) == 9000)
        assert(levelingHpCap.apply(50, makeTarget(10000), -500) == -500)
        assert(levelingHpCap.apply(50, makeTarget(10000), 0) == 0)
        assert(levelingHpCap.apply(50, nil, 9000) == 9000)
    end)
end)
