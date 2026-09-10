local hundred = require('modules/custom/lua/dynamis_hundred_piece')

describe('Dynamis hundred-piece', function()
    it('pays the zone 100-piece in the three cities', function()
        assert(hundred.hundredItem(xi.zone.DYNAMIS_SAN_DORIA, xi.item.ORDELLE_BRONZEPIECE)
            == xi.item.MONTIONT_SILVERPIECE)
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

        assert(seen[xi.item.MONTIONT_SILVERPIECE])
        assert(seen[xi.item.ONE_HUNDRED_BYNE_BILL])
        assert(seen[xi.item.LUNGO_NANGO_JADESHELL])
    end)

    it('maps Beauc / Xarc singles to the matching 100-piece', function()
        assert(hundred.hundredItem(xi.zone.DYNAMIS_BEAUCEDINE, xi.item.TUKUKU_WHITESHELL)
            == xi.item.LUNGO_NANGO_JADESHELL)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_XARCABARD, xi.item.ORDELLE_BRONZEPIECE)
            == xi.item.MONTIONT_SILVERPIECE)
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
            == xi.item.MONTIONT_SILVERPIECE)
        assert(hundred.hundredItem(xi.zone.DYNAMIS_TAVNAZIA, hundred.dreamlandSingle(20))
            == xi.item.MONTIONT_SILVERPIECE)
    end)

    it('is a flat 1 percent roll', function()
        assert(hundred.CHANCE_PERCENT == 1)
    end)

    it('never pays a 10,000-piece', function()
        local forbidden =
        {
            [xi.item.RANPERRE_GOLDPIECE] = true,
            [xi.item.TEN_THOUSAND_BYNE_BILL] = true,
            [xi.item.RIMILALA_STRIPESHELL] = true,
        }

        local singles =
        {
            xi.item.ORDELLE_BRONZEPIECE,
            xi.item.ONE_BYNE_BILL,
            xi.item.TUKUKU_WHITESHELL,
        }

        local zones =
        {
            xi.zone.DYNAMIS_SAN_DORIA,
            xi.zone.DYNAMIS_BASTOK,
            xi.zone.DYNAMIS_WINDURST,
            xi.zone.DYNAMIS_JEUNO,
            xi.zone.DYNAMIS_BEAUCEDINE,
            xi.zone.DYNAMIS_XARCABARD,
            xi.zone.DYNAMIS_VALKURM,
            xi.zone.DYNAMIS_BUBURIMU,
            xi.zone.DYNAMIS_QUFIM,
            xi.zone.DYNAMIS_TAVNAZIA,
        }

        for _, zoneId in ipairs(zones) do
            for _, single in ipairs(singles) do
                for pick = 1, 3 do
                    local itemId = hundred.hundredItem(zoneId, single, function()
                        return pick
                    end)
                    assert(not forbidden[itemId], string.format('zone %s single %s paid 10k %s', zoneId, single, tostring(itemId)))
                end
            end
        end
    end)
end)
