local gendered = require('modules/custom/lua/gendered_armor')
local plus4map = require('modules/custom/lua/reforge_plus4_map')
local catalog  = require('modules/custom/lua/reforge_catalog')

local function fakePlayer(gender, items)
    items = items or {}
    return
    {
        getGender = function() return gender end,
        hasItem = function(_, itemId) return items[itemId] == true end,
    }
end

describe('Gendered Maxixi armor', function()
    it('hands males the male Maxixi id and females the female id', function()
        local male = fakePlayer(1)
        local female = fakePlayer(0)

        assert(gendered.resolve(male, 27826) == 27825)
        assert(gendered.resolve(female, 27825) == 27826)
        assert(gendered.resolve(male, 26660) == 26660)   -- Horos, unisex
        assert(gendered.resolve(female, 26934) == 26934) -- Maculele, unisex
    end)

    it('treats either gender as owning the upgrade ingredient', function()
        local female = fakePlayer(0, { [27826] = true })
        assert(gendered.has(female, 27825))
        assert(gendered.ownedId(female, 27825) == 27826)
        assert(gendered.ownedId(fakePlayer(1), 27825) == nil)
    end)

    it('keeps every Maxixi reforge tier paired through +4', function()
        for _, slot in pairs(catalog.pieces[xi.job.DNC].af) do
            for _, itemId in ipairs(slot) do
                local rec = gendered.pair(itemId)
                assert(rec ~= nil, string.format('Maxixi %d has no gender pair', itemId))
                assert(rec.female == rec.male + 1)
            end
        end

        assert(plus4map[23393] ~= nil, 'male Maxixi Tiara +3 must plus4')
        assert(plus4map[23394] ~= nil, 'female Maxixi Tiara +3 must plus4')
        assert(plus4map[23393].result == 23913)
        assert(plus4map[23394].result == 23914)
        assert(gendered.resolve(fakePlayer(0), plus4map[23393].result) == 23914)
    end)
end)
