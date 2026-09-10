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
            assert(itemId ~= xi.item.KRAKEN_CLUB_P1)
        end
    end)

    it('defines Kraken Club +1 as a 119 all-jobs 8-hit offhand', function()
        assert(xi.item.KRAKEN_CLUB_P1 == 19972)

        local sql = assert(io.open('modules/custom/sql/zz_kraken_club_plus_one.sql', 'r'))
        local text = sql:read('*a')
        sql:close()

        assert(text:find("%(19972, 'kraken_club_%+1', 11, 0, 269, 269, 228, 3, 8, 264, 16, 0%)"))
        assert(text:find("%(19972, 'kraken_club_%+1', 99, 119, 4194303, 110,"))
        assert(text:find('%(19972,  25, 25%)'))
        assert(text:find('%(19972,  73,  4%)'))
        assert(text:find('%(19972, 289,  5%)'))
        assert(not text:find('INSERT INTO `mob_droplist`', 1, true))
    end)

    it('stamps LEG serials on both Kraken Club ids', function()
        local header = assert(io.open('modules/custom/cpp/kraken_club.h', 'r'))
        local text = header:read('*a')
        header:close()

        assert(text:find('PlusOneItemId = 19972', 1, true))
        assert(text:find('isKrakenClub', 1, true))
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
