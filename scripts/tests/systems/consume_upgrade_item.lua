local consume = require('modules/custom/lua/consume_upgrade_item')
local bags = require('modules/custom/lua/hl_seal_currency')

describe('Upgrade consume helper', function()
    it('exposes a one-copy consume used by reforge and REMA forges', function()
        assert.is_function(consume.one)
        assert.is_function(bags.take)
    end)
end)
