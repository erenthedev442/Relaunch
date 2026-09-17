local drops   = require('modules/custom/lua/dynamis_currency_drops')
local hundred = require('modules/custom/lua/dynamis_hundred_piece')

describe('Dynamis currency drops', function()
    it('uses a TH-agnostic 100/50/20/5 single curve', function()
        assert(drops.SINGLE_RATES[1] == 100)
        assert(drops.SINGLE_RATES[2] == 50)
        assert(drops.SINGLE_RATES[3] == 20)
        assert(drops.SINGLE_RATES[4] == 5)
        assert(drops.expectedSingles() == 1.75)
    end)

    it('uses the pack tag instead of the Vana hour', function()
        local mob =
        {
            getLocalVar = function(_, key)
                if key == 'dynamis_currency' then
                    return xi.item.ONE_BYNE_BILL
                end

                return 0
            end,
        }

        assert(drops.packSingle(mob) == xi.item.ONE_BYNE_BILL)
        assert(drops.mobSingle(mob) == xi.item.ONE_BYNE_BILL)
        assert(drops.isCurrencyMob(mob))
    end)

    it('rolls those singles then the matching 100-piece', function()
        local treasures    = {}
        local hundredRolls = 0
        local origDrop     = hundred.tryDrop
        local origRandom   = math.random
        hundred.tryDrop = function(_, _, currency)
            hundredRolls = hundredRolls + 1
            assert(currency == xi.item.ORDELLE_BRONZEPIECE)
            return true
        end
        math.random = function()
            return 1
        end

        local mob =
        {
            getTHlevel = function()
                return 14
            end,
            getLocalVar = function(_, key)
                if key == 'dynamis_currency' then
                    return xi.item.ORDELLE_BRONZEPIECE
                end

                return 0
            end,
            getZoneID = function()
                return xi.zone.DYNAMIS_VALKURM
            end,
        }
        local killer =
        {
            addTreasure = function(_, itemId)
                treasures[#treasures + 1] = itemId
            end,
        }

        local ok, err = pcall(function()
            drops.onDeath(mob, killer)
            assert(#treasures == 4)
            for _, itemId in ipairs(treasures) do
                assert(itemId == xi.item.ORDELLE_BRONZEPIECE)
            end
            assert(hundredRolls == 1)
        end)
        hundred.tryDrop = origDrop
        math.random = origRandom
        assert(ok, err)
    end)

    it('guarantees an extra 100-piece on white proc', function()
        local treasures = {}
        local origDrop  = hundred.tryDrop
        hundred.tryDrop = function()
            return false
        end

        local mob =
        {
            getLocalVar = function(_, key)
                if key == 'dynamis_proc' then
                    return 4
                end
                if key == 'dynamis_currency' then
                    return xi.item.ONE_BYNE_BILL
                end

                return 0
            end,
            getZoneID = function()
                return xi.zone.DYNAMIS_VALKURM
            end,
        }
        local killer =
        {
            addTreasure = function(_, itemId)
                treasures[#treasures + 1] = itemId
            end,
        }

        local origRandom = math.random
        math.random = function()
            return 100
        end

        local ok, err = pcall(function()
            drops.onDeath(mob, killer)
            local sawHundred = false
            for _, itemId in ipairs(treasures) do
                if itemId == xi.item.ONE_HUNDRED_BYNE_BILL then
                    sawHundred = true
                end
            end
            assert(sawHundred)
        end)
        hundred.tryDrop = origDrop
        math.random = origRandom
        assert(ok, err)
    end)
end)
