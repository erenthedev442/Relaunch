describe('Kraken Club acquisition', function()
    local content = require('scripts/battlefields/Waughroon_Shrine/up_in_arms')
    local invasionLoot = require('modules/custom/lua/invasion_loot_pool')

    it('keeps Up in Arms retail entry and level restrictions', function()
        assert(content.zoneId == xi.zone.WAUGHROON_SHRINE)
        assert(content.battlefieldId == xi.battlefield.id.UP_IN_ARMS)
        assert(content.maxPlayers == 3)
        assert(content.levelCap == 60)
        assert(content.timeLimit == utils.minutes(15))
        assert(content.requiredItems[1] == xi.item.MOON_ORB)
        assert(content.groups[1].mobs[1] == 'Fee')
        assert(content.groups[1].allDeath ~= nil)
        assert(#content.armouryCrates == 3)
        assert(content.armouryCrates[1] == zones[xi.zone.WAUGHROON_SHRINE].mob.FEE + 1)
    end)

    it('sets the Up in Arms Kraken Club roll to exactly two percent', function()
        local group = content.loot[#content.loot]
        local total = 0
        local clubWeight = 0

        for _, entry in ipairs(group) do
            total = total + entry.weight
            if entry.itemId == xi.item.KRAKEN_CLUB then
                clubWeight = entry.weight
            end
        end

        assert(total == 10000)
        assert(clubWeight == 200)
    end)

    it('does not allow Invasion to create another Kraken Club source', function()
        for _, itemId in ipairs(invasionLoot) do
            assert(itemId ~= xi.item.KRAKEN_CLUB)
        end
    end)

    it('rebuilds inscribed gear through addHeldGear so augmenting cannot mint a new serial', function()
        local file = assert(io.open('modules/custom/lua/Augment_Moogle.lua', 'r'))
        local text = file:read('*a')
        file:close()

        assert(text:find('local function addHeldGear', 1, true))
        assert(text:find('payload.signature', 1, true))
        assert(not text:find('addItem({ id = st.itemId', 1, true))
        assert(not text:find('addItem({ id = st2.itemId', 1, true))
        assert(not text:find('id     = deliveredId', 1, true))
    end)
end)
