local C = require('modules/custom/lua/thief_mug_catalog')

describe('main THF Mug drain', function()
    it('uses 90s on main THF and 5:00 on /THF', function()
        assert(C.recastFor(true) == 90)
        assert(C.recastFor(false) == 300)
    end)

    it('keeps DEX+AGI inside the band they earned', function()
        assert(C.bandFor(false, false) == 'fresh')
        assert(C.bandFor(false, true) == 'master')
        assert(C.bandFor(true, false) == 'rema')
        assert(C.bandFor(true, true) == 'rema')

        -- DEX+AGI 160 / 210 / 260 / 297 / 335 against each band.
        local function split(total)
            return math.floor(total / 2), math.ceil(total / 2)
        end

        local function at(total, band)
            local dex, agi = split(total)
            return C.healAmount(dex, agi, band)
        end

        assert(at(160, 'fresh') == 500 and at(160, 'master') == 900 and at(160, 'rema') == 1600)
        assert(at(210, 'fresh') == 900 and at(210, 'master') == 1300 and at(210, 'rema') == 2000)
        assert(at(260, 'fresh') == 900 and at(260, 'master') == 1700 and at(260, 'rema') == 2400)
        assert(at(297, 'fresh') == 900 and at(297, 'master') == 1996 and at(297, 'rema') == 2696)
        assert(at(335, 'fresh') == 900 and at(335, 'master') == 2000 and at(335, 'rema') == 3000)
    end)

    it('reads a finished REMA and ignores a path stage', function()
        assert(C.isRemaItem(20583)) -- Mandau 119 III
        assert(C.isRemaItem(20587)) -- Twashtar 119 III
        assert(C.isRemaItem(20594)) -- Aeneas
        assert(not C.isRemaItem(19747)) -- Mandau 99
        assert(not C.isRemaItem(0))
    end)

    it('heals from the equipped REMA band', function()
        local player =
        {
            getStat = function(_, mod)
                if mod == xi.mod.DEX then
                    return 80
                end
                if mod == xi.mod.AGI then
                    return 80
                end
                return 0
            end,
            getSpentJobPoints = function()
                return 0
            end,
            getEquipID = function(_, slot)
                if slot == xi.slot.MAIN then
                    return 20583
                end
                return 0
            end,
        }

        assert(C.equippedRema(player))
        assert(C.playerHeal(player) == 1600)
    end)
end)
