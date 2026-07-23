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

    local function wareById(itemId)
        for _, entry in ipairs(allWares()) do
            if entry.id == itemId then
                return entry
            end
        end

        return nil
    end

    it('offers the complete fixed-price level-50 selection', function()
        local wares = allWares()
        assert(#wares == 83)

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

    it('encodes advertised flat bonuses from their plus-one augment tiers', function()
        local expected =
        {
            ['HP +20']       = { id = 1,  value = 19 },
            ['MP +20']       = { id = 9,  value = 19 },
            ['Attack +6']    = { id = 25, value = 5 },
            ['Rng. Atk. +6'] = { id = 29, value = 5 },
            ['Accuracy +6']  = { id = 23, value = 5 },
            ['Rng. Acc. +6'] = { id = 27, value = 5 },
            ['Mag. Acc. +6'] = { id = 35, value = 5 },
        }

        local checked = {}
        for _, entry in ipairs(allWares()) do
            for _, augment in ipairs(entry.augments) do
                local encoding = expected[augment.label]
                if encoding then
                    assert(augment.id == encoding.id)
                    assert(augment.value == encoding.value)
                    checked[augment.label] = true
                end
            end
        end

        for label in pairs(expected) do
            assert(checked[label], string.format('catalog no longer exercises %s', label))
        end
    end)

    it('puts EXP plus fifteen on exactly two accessories', function()
        local expCount = 0
        for _, entry in ipairs(allWares()) do
            for _, augment in ipairs(entry.augments) do
                if augment.id == 72 then
                    assert(augment.value == 14)
                    assert(entry.jobs == 'All Jobs')
                    expCount = expCount + 1
                end
            end
        end
        assert(expCount == 2)
        assert(wareById(11531))
        assert(not wareById(13692))
    end)

    it('labels every job body for clear filtered menus', function()
        for _, entry in ipairs(catalog.wares.Armor['Job Bodies']) do
            assert(entry.jobs and entry.jobs ~= '')
        end
    end)

    it('adds universal catch-up gear and a level-50 corsair gun', function()
        for _, itemId in ipairs({ 14936, 14937, 15691, 15692, 15773, 15777 }) do
            local entry = wareById(itemId)
            assert(entry)
            assert(entry.jobs == 'All Jobs')
        end

        assert(wareById(18711).jobs == 'THF/RNG/NIN/COR')
    end)

    it('offers WHM a melee-focused level-50 club', function()
        local found = false
        for _, entry in ipairs(catalog.wares.Weapons.Melee) do
            if entry.id == 17082 then
                assert(entry.jobs == 'WHM')
                assert(entry.augments[1].label == 'Accuracy +6')
                assert(entry.augments[2].label == 'Attack +6')
                found = true
            end
        end

        assert(found)
    end)

    it('reserves exactly the three approved first-click gifts', function()
        assert(#catalog.starterGifts == 3)
        assert(catalog.starterGifts[1].id == 10293)
        assert(catalog.starterGifts[2].id == 11811)
        assert(catalog.starterGifts[3].id == 27556)
    end)
end)
