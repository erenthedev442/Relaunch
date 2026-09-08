local hundred = require('modules/custom/lua/dynamis_hundred_piece')

describe('Dynamis hundred-piece', function()
    it('pays the zone 100-piece in the three cities', function()
        assert(hundred.hundredItem(xi.zone.DYNAMIS_SAN_DORIA, xi.item.ORDELLE_BRONZEPIECE)
            == xi.item.RANPERRE_GOLDPIECE)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_BASTOK, xi.item.ONE_BYNE_BILL)
            == xi.item.ONE_HUNDRED_BYNE_BILL)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_WINDURST, xi.item.TUKUKU_WHITESHELL)
            == xi.item.LUNGO_NANGO_JADESHELL)
    end)

    it('uses one shared Jeuno pool instead of three separate rolls', function()
        local seen = {}
        for i = 1, 3 do
            local itemId = hundred.hundredItem(xi.zone.DYNAMIS_JEUNO, xi.item.TUKUKU_WHITESHELL, function()
                return i
            end)
            seen[itemId] = true
        end

        assert(seen[xi.item.RANPERRE_GOLDPIECE])
        assert(seen[xi.item.ONE_HUNDRED_BYNE_BILL])
        assert(seen[xi.item.LUNGO_NANGO_JADESHELL])
    end)

    it('maps Beauc / Xarc singles to the matching 100-piece', function()
        assert(hundred.hundredItem(xi.zone.DYNAMIS_BEAUCEDINE, xi.item.TUKUKU_WHITESHELL)
            == xi.item.LUNGO_NANGO_JADESHELL)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_XARCABARD, xi.item.ORDELLE_BRONZEPIECE)
            == xi.item.RANPERRE_GOLDPIECE)
    end)

    it('rotates Dreamland nightmare currency with the Vana 8-hour windows', function()
        assert(hundred.dreamlandSingle(0) == xi.item.TUKUKU_WHITESHELL)
        assert(hundred.dreamlandSingle(7) == xi.item.TUKUKU_WHITESHELL)
        assert(hundred.dreamlandSingle(8) == xi.item.ONE_BYNE_BILL)
        assert(hundred.dreamlandSingle(15) == xi.item.ONE_BYNE_BILL)
        assert(hundred.dreamlandSingle(16) == xi.item.ORDELLE_BRONZEPIECE)
        assert(hundred.dreamlandSingle(23) == xi.item.ORDELLE_BRONZEPIECE)

        assert(hundred.hundredItem(xi.zone.DYNAMIS_VALKURM, hundred.dreamlandSingle(0))
            == xi.item.LUNGO_NANGO_JADESHELL)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_BUBURIMU, hundred.dreamlandSingle(8))
            == xi.item.ONE_HUNDRED_BYNE_BILL)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_QUFIM, hundred.dreamlandSingle(16))
            == xi.item.RANPERRE_GOLDPIECE)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_TAVNAZIA, hundred.dreamlandSingle(20))
            == xi.item.RANPERRE_GOLDPIECE)
    end)

    it('is a flat 1 percent roll', function()
        assert(hundred.CHANCE_PERCENT == 1)
    end)
end)
