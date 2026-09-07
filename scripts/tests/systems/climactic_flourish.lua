local function readFile(path)
    local file = assert(io.open(path, 'r'))
    local text = file:read('*a')
    file:close()
    return text
end

describe('Climactic Flourish', function()
    it('consumes every finishing move and stores that many crit charges', function()
        local dancer = readFile('scripts/globals/job_utils/dancer.lua')
        local ability = dancer:match('useClimacticFlourishAbility = function.-return xi.effect.CLIMACTIC_FLOURISH')
        assert(ability ~= nil)
        assert(ability:find('power = numMoves', 1, true))
        assert(ability:find('setFinishingMoves(player, 0)', 1, true))
        assert(not ability:find('numMoves - 1', 1, true))
        assert(not ability:find('power = 3', 1, true))
    end)

    it('spends one charge per weaponskill hit instead of wiping on WEAPONSKILL_USE', function()
        local ws = readFile('scripts/globals/weaponskills.lua')
        assert(ws:find('consumeClimacticCharge', 1, true))
        assert(ws:find('CLIMACTIC_FLOURISH', 1, true))

        local consumer = readFile('modules/custom/lua/climactic_flourish_consumer.lua')
        assert(consumer:find('MELEE_SWING_HIT', 1, true))
        assert(not consumer:find('WEAPONSKILL_USE', 1, true))
    end)

    it('gives DNC empyrean tiaras +1 max finishing moves', function()
        local sql = readFile('modules/custom/sql/dnc_empy_finishing_moves.sql')
        for _, itemId in ipairs({ 12026, 11182, 11082, 26776, 26777, 23103, 23438 }) do
            assert(sql:find(tostring(itemId) .. ', 988, 1', 1, true), 'missing MAX_FINISHING_MOVE_BONUS on ' .. itemId)
        end
    end)
end)
