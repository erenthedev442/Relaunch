local catalog = require('modules/custom/lua/expcamp_kamihr_catalog')

describe('Kamihr !expcamp Ashen Tiger clones', function()
    it('keeps 12 retail slots and clones 40 more for 52 total', function()
        assert(#catalog.retailIds == 12)
        assert(#catalog.northSouthPoints == 20)
        assert(#catalog.westPoints == 20)
        assert(catalog.dynamicCount == 40)
        assert(catalog.totalCount == 52)
        assert(catalog.linkRadius == 10)
        assert(catalog.retailIdSet[17871008])
        assert(catalog.respawnSeconds == 60)
        assert(catalog.maxHP == 30000)
        assert(catalog.groupId == 13)
        assert(catalog.groupZoneId == 267)
    end)

    it('lines the clones between the two player pins on each path', function()
        local ns = catalog.northSouthPoints
        local west = catalog.westPoints

        assert(math.abs(ns[1].x - 162.8919) < 0.01)
        assert(math.abs(ns[1].z - 316.8826) < 0.01)
        assert(math.abs(ns[#ns].x - 155.6881) < 0.01)
        assert(math.abs(ns[#ns].z - 239.8582) < 0.01)

        assert(math.abs(west[1].x - 155.6881) > 1)
        assert(math.abs(west[#west].x - 74.8336) < 0.01)
        assert(math.abs(west[#west].z - 235.8724) < 0.01)
    end)
end)
