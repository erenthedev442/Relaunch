local announce = require('modules/custom/lua/rema_finish_announce')

describe('REMA 119 III finish announcements', function()
    it('labels Relic Empyrean Mythic Aeonic and Prime', function()
        assert(announce.familyLabel('relic') == 'Relic')
        assert(announce.familyLabel('EMPYREAN') == 'Empyrean')
        assert(announce.familyLabel('mythic') == 'Mythic')
        assert(announce.familyLabel('aeonic') == 'Aeonic')
        assert(announce.familyLabel('prime') == 'Prime')
        assert(announce.familyLabel('unknown') == 'REMA')
    end)

    it('names the player, family, and 119 III weapon', function()
        local msg = announce.message('Valtor', 'relic', 'Amanomurakumo')
        assert(msg:find('Valtor', 1, true))
        assert(msg:find('Relic', 1, true))
        assert(msg:find('Amanomurakumo', 1, true))
        assert(msg:find('119 III', 1, true))
    end)

    it('broadcasts through printToArea and skips empty names', function()
        local seen = {}
        local player =
        {
            getName = function() return 'Zahabi' end,
            printToArea = function(_, message)
                seen.message = message
            end,
        }

        assert(announce.broadcast(player, 'empyrean', 'Twashtar'))
        assert(seen.message:find('Zahabi', 1, true))
        assert(seen.message:find('Empyrean', 1, true))
        assert(seen.message:find('Twashtar', 1, true))

        assert(not announce.broadcast(player, 'relic', ''))
        assert(not announce.broadcast({ getName = function() return '' end }, 'relic', 'Mandau'))
    end)
end)
