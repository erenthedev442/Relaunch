local exchange = require('modules/custom/lua/dynamis_currency_exchange')

describe('Dynamis currency exchange', function()
    it('converts any stack at the live 10:1 rate and leaves a remainder', function()
        local taken, given = exchange.upgradeCounts(10, 10)
        assert(taken == 10 and given == 1)

        taken, given = exchange.upgradeCounts(90, 10)
        assert(taken == 90 and given == 9)

        taken, given = exchange.upgradeCounts(100, 10)
        assert(taken == 100 and given == 10)

        taken, given = exchange.upgradeCounts(99, 10)
        assert(taken == 90 and given == 9)

        taken, given = exchange.upgradeCounts(792, 10)
        assert(taken == 790 and given == 79)

        taken, given = exchange.upgradeCounts(9, 10)
        assert(taken == 0 and given == 0)
    end)

    it('does not treat goblin shop prices as a 100s-to-10k upgrade', function()
        local shop =
        {
            7,  1,
            8,  2,
            9,  3,
            12, 4,
            20, 5,
            25, 6,
            33, 7,
        }

        assert(exchange.isShopPrice(shop, 20))
        assert(exchange.isShopPrice(shop, 7))
        assert(not exchange.isShopPrice(shop, 10))
        assert(not exchange.isShopPrice(shop, 90))
        assert(not exchange.isShopPrice(shop, 100))
        assert(not exchange.isShopPrice(nil, 20))
    end)
end)
