local plus4 = require('modules/custom/lua/dynamis_plus4')
local plus4map = require('modules/custom/lua/reforge_plus4_map')

local function fakeTrade(qtys)
    local slots = {}
    for itemId, qty in pairs(qtys) do
        if qty > 0 then
            slots[#slots + 1] = { id = itemId, qty = qty }
        end
    end

    local trade = {}
    function trade:getSlotCount()
        return #slots
    end
    function trade:getItemId(slot)
        local row = slots[slot + 1]
        return row and row.id or 0
    end
    function trade:getItemQty(itemId)
        return qtys[itemId] or 0
    end
    return trade
end

describe('Dynamis +4 forge trade matching', function()
    local warHead = plus4map[23375]
    local rusted = plus4.RUSTED_ID
    local black = plus4.BLACK_ID

    it('maps AF +3 Pummelers Mask to +4', function()
        assert(warHead ~= nil)
        assert(warHead.result == 23895)
        assert(warHead.slot == 'head')
        assert(warHead.pcard == 9281)
    end)

    it('accepts leftover rusted cards instead of an exact 60-stack', function()
        local trade = fakeTrade({
            [23375] = 1,
            [warHead.pcard] = 3,
            [rusted] = 99,
            [black] = 6,
        })
        local kind, pieceId, entry = plus4.classify(trade, plus4map, {})
        assert(kind == 'recipe')
        assert(pieceId == 23375)
        assert(entry.result == 23895)
    end)

    it('accepts a lone +3 so materials can come from inventory', function()
        local trade = fakeTrade({ [23375] = 1 })
        local kind = plus4.classify(trade, plus4map, {})
        assert(kind == 'piece_only')
    end)

    it('does not treat a short rusted stack as a complete recipe', function()
        local trade = fakeTrade({
            [23375] = 1,
            [warHead.pcard] = 3,
            [rusted] = 10,
            [black] = 6,
        })
        local kind = plus4.classify(trade, plus4map, {})
        assert(kind == 'short')
    end)

    it('body pieces ask for the taxed card counts', function()
        local body = plus4map[23442]
        assert(body.slot == 'body')
        local mats = plus4.materialsFor(body)
        assert(mats[1].qty == plus4.PCARD_QTY_BODY)
        assert(mats[2].qty == plus4.RUSTED_QTY_BODY)
        assert(mats[3].qty == plus4.BLACK_QTY_BODY)
    end)
end)
