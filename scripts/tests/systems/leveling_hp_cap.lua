local levelingHpCap = require('modules/custom/lua/leveling_hp_cap')

describe('Legendary leveling HP cap', function()
    local function makeTarget(maxHp, isMob, currentHp)
        return
        {
            isMob = function()
                return isMob ~= false
            end,
            getMaxHP = function()
                return maxHp
            end,
            getHP = function()
                return currentHp or maxHp
            end,
        }
    end

    it('clamps sub-99 hits to one third of mob max HP', function()
        local target = makeTarget(10000)
        assert(levelingHpCap.apply(50, target, 9000) == 3333)
        assert(levelingHpCap.apply(98, target, 3333) == 3333)
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

    it('finishes a sliver leftover instead of leaving the bar at 1%', function()
        -- 3 * floor(10000/3) = 9999, so a third hit would have left 1 HP.
        assert(levelingHpCap.apply(50, makeTarget(10000, true, 3334), 9000) == 3334)
        assert(levelingHpCap.apply(50, makeTarget(10000, true, 5), 3333) == 3333)
        assert(levelingHpCap.apply(50, makeTarget(10000, true, 5000), 9000) == 3333)
    end)
end)
