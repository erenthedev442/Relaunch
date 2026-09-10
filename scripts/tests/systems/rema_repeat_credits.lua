local credits = require('modules/custom/lua/rema_repeat_credits')

local function makePlayer(vars)
    vars = vars or {}
    local player = {}
    function player:getCharVar(name)
        return vars[name] or 0
    end
    function player:setCharVar(name, value)
        vars[name] = value
    end
    return player, vars
end

describe('REMA repeat credits', function()
    it('treats an existing family final as one unused credit', function()
        local player = makePlayer({ WF_Relic_Final = 1 })
        assert(credits.available(player, 'relic') == 1)
        assert(credits.available(player, 'aeonic') == 0)
    end)

    it('spends the credit on one repeat and then closes the shop', function()
        local player, vars = makePlayer({ WF_Aeonic_Final = 1 })
        assert(credits.trySpend(player, 'aeonic'))
        assert(vars.WF_Aeonic_ProperCount == 1)
        assert(vars.WF_Aeonic_RepeatSpent == 1)
        assert(credits.available(player, 'aeonic') == 0)
        assert(not credits.trySpend(player, 'aeonic'))
    end)

    it('banks another credit when they finish a second proper weapon', function()
        local player, vars = makePlayer({ WF_Relic_Final = 1 })
        assert(credits.trySpend(player, 'relic'))
        assert(credits.available(player, 'relic') == 0)

        credits.noteProperCompletion(player, 'relic', 1)
        assert(vars.WF_Relic_ProperCount == 2)
        assert(credits.available(player, 'relic') == 1)
    end)

    it('counts the first proper finish as a single credit', function()
        local player, vars = makePlayer()
        credits.noteProperCompletion(player, 'mythic', 0)
        assert(vars.WF_Mythic_Final == 1)
        assert(vars.WF_Mythic_ProperCount == 1)
        assert(credits.available(player, 'mythic') == 1)
    end)

    it('keeps family shops independent', function()
        local player = makePlayer({
            WF_Relic_Final = 1,
            WF_Empyrean_Final = 1,
        })
        assert(credits.trySpend(player, 'relic'))
        assert(credits.available(player, 'relic') == 0)
        assert(credits.available(player, 'empyrean') == 1)
    end)
end)
