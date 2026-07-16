local catalog = require('modules/custom/lua/welcome_moogle_catalog')

describe('Welcome Moogle starter catalog', function()
    local function allWares()
        local rows = {}
        for _, categoryName in ipairs(catalog.categoryOrder) do
            for _, subcategoryName in ipairs(catalog.subcategoryOrder[categoryName]) do
                for _, entry in ipairs(catalog.wares[categoryName][subcategoryName]) do
                    table.insert(rows, entry)
                end
            end
        end
        return rows
    end

    it('offers the complete fixed-price level-50 selection', function()
        local wares = allWares()
        assert(#wares == 76)

        local seen = {}
        for _, entry in ipairs(wares) do
            assert(not seen[entry.id], string.format('duplicate item %d', entry.id))
            assert(entry.price == 1000)
            assert(#entry.augments == 2)
            seen[entry.id] = true
        end
    end)

    it('uses only valid basic exdata values and no critical-hit augments', function()
        local forbidden =
        {
            [41] = true,  -- Critical hit rate
            [132] = true, -- Double Attack + critical hit rate
            [328] = true, -- Critical hit damage
            [335] = true, -- Magic critical hit damage
        }

        for _, entry in ipairs(allWares()) do
            for _, augment in ipairs(entry.augments) do
                assert(augment.value >= 0 and augment.value <= 31)
                assert(not forbidden[augment.id], string.format(
                    'forbidden critical augment %d on item %d', augment.id, entry.id))
            end
        end
    end)

    it('puts EXP plus fifteen on exactly two accessories', function()
        local expCount = 0
        for _, entry in ipairs(allWares()) do
            for _, augment in ipairs(entry.augments) do
                if augment.id == 72 then
                    assert(augment.value == 14)
                    expCount = expCount + 1
                end
            end
        end
        assert(expCount == 2)
    end)

    it('reserves exactly the three approved first-click gifts', function()
        assert(#catalog.starterGifts == 3)
        assert(catalog.starterGifts[1].id == 10293)
        assert(catalog.starterGifts[2].id == 11811)
        assert(catalog.starterGifts[3].id == 27556)
    end)
end)
