local hold = require('modules/custom/lua/hades_hold_currency')

local LOW  = 1456 -- 100 Byne Bill
local HIGH = 1457 -- 10,000 Byne Bill

local function mockPlayer(holdLow, holdHigh)
    local vars = {}
    vars[hold.cv(LOW)]  = holdLow or 0
    vars[hold.cv(HIGH)] = holdHigh or 0
    return {
        getCharVar = function(_, key) return vars[key] or 0 end,
        setCharVar = function(_, key, value) vars[key] = value end,
        getItemCount = function() return 0 end,
        vars = vars,
    }
end

describe('Dynamis currency mix', function()
    it('values high-tier at the box exchange rate', function()
        assert(hold.exchangeRate() == 10)
        local player = mockPlayer(20, 3)
        local value, low, high, rate = hold.countMixed(player, LOW, HIGH)
        assert(rate == 10)
        assert(low == 20)
        assert(high == 3)
        assert(value == 50)
    end)

    it('pays a 750 repeat with only 100-piece currency', function()
        local player = mockPlayer(800, 0)
        local ok, takenLow, takenHigh = hold.takeMixed(player, LOW, HIGH, 750)
        assert(ok)
        assert(takenLow == 750)
        assert(takenHigh == 0)
        assert(hold.count(player, LOW) == 50)
        assert(hold.count(player, HIGH) == 0)
    end)

    it('pays a 750 repeat with only 10k-piece currency', function()
        local player = mockPlayer(0, 80)
        local ok, takenLow, takenHigh = hold.takeMixed(player, LOW, HIGH, 750)
        assert(ok)
        assert(takenLow == 0)
        assert(takenHigh == 75)
        assert(hold.count(player, HIGH) == 5)
    end)

    it('mixes 10k-piece first then fills with 100-piece', function()
        local player = mockPlayer(50, 70)
        local ok, takenLow, takenHigh = hold.takeMixed(player, LOW, HIGH, 750)
        assert(ok)
        assert(takenHigh == 70)
        assert(takenLow == 50)
        assert(hold.count(player, LOW) == 0)
        assert(hold.count(player, HIGH) == 0)
    end)

    it('covers every Weapon Forge relic step amount', function()
        for _, need in ipairs({ 50, 100, 500, 750 }) do
            local lowOnly = mockPlayer(need, 0)
            assert(hold.takeMixed(lowOnly, LOW, HIGH, need), string.format('low-only failed for %d', need))
            assert(hold.count(lowOnly, LOW) == 0)

            local highOnly = mockPlayer(0, need / 10)
            assert(hold.takeMixed(highOnly, LOW, HIGH, need), string.format('high-only failed for %d', need))
            assert(hold.count(highOnly, HIGH) == 0)
        end

        local mixed = mockPlayer(20, 3) -- 20 + 30 = 50
        local ok, takenLow, takenHigh = hold.takeMixed(mixed, LOW, HIGH, 50)
        assert(ok)
        assert(takenHigh == 3)
        assert(takenLow == 20)
    end)

    it('refuses when combined value is short', function()
        local player = mockPlayer(40, 70) -- 40 + 700 = 740
        local ok, takenLow, takenHigh = hold.takeMixed(player, LOW, HIGH, 750)
        assert(not ok)
        assert(takenLow == 0)
        assert(takenHigh == 0)
        assert(hold.count(player, LOW) == 40)
        assert(hold.count(player, HIGH) == 70)
    end)

    it('restores a mixed payment on refund', function()
        local player = mockPlayer(50, 70)
        local ok, takenLow, takenHigh = hold.takeMixed(player, LOW, HIGH, 750)
        assert(ok)
        hold.refundMixed(player, LOW, HIGH, takenLow, takenHigh)
        assert(hold.count(player, LOW) == 50)
        assert(hold.count(player, HIGH) == 70)
    end)
end)
