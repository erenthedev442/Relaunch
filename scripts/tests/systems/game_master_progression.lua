local progress = require('modules/custom/lua/game_master_progress')
local catalog = require('modules/custom/lua/game_master_catalog')

local function makePlayer(value)
    local vars = { GM_Wave_Clears = value or 0 }
    return
    {
        getCharVar = function(_, name) return vars[name] or 0 end,
        setCharVar = function(_, name, newValue) vars[name] = newValue end,
    }, vars
end

describe('Wave Master progression', function()
    it('keeps the linear ladder paced and mechanically distinct', function()
        local linear = { 'Easy', 'Normal', 'Hard', 'Insane', 'Nightmare', 'Apocalypse', 'Oblivion', 'Ragnarok', 'Terror' }
        local expectedWaves = { 3, 5, 7, 8, 10, 12, 14, 16, 18 }
        local previousLevel, previousHp = 0, 0

        for index, name in ipairs(linear) do
            local difficulty = catalog.difficulties[name]
            assert(difficulty ~= nil)
            assert(difficulty.minLevel >= previousLevel)
            assert(difficulty.maxLevel <= 150)
            assert(difficulty.hpBoost > previousHp)
            assert(difficulty.wavesTotal == expectedWaves[index])
            assert(difficulty.mobsPerWave == 1)
            assert((difficulty.spawnStagger or 0) == 0)
            assert(difficulty.mechanics ~= nil)
            assert(#difficulty.mobs > 0)
            previousLevel = difficulty.minLevel
            previousHp = difficulty.hpBoost
        end

        local terror = catalog.difficulties.Terror
        local ragnarok = catalog.difficulties.Ragnarok
        assert(terror.hpBoost > ragnarok.hpBoost)
        assert(terror.mods[xi.mod.ATT] > ragnarok.mods[xi.mod.ATT])
        assert(terror.mods[xi.mod.ACC] > ragnarok.mods[xi.mod.ACC])
        assert(terror.completionBonus > ragnarok.completionBonus)
        assert(terror.markBonus > ragnarok.markBonus)
    end)

    it('keeps the append-only difficulty bits stable', function()
        assert(progress.bitFor('Easy') == 1)
        assert(progress.bitFor('Hard') == 4)
        assert(progress.bitFor('Nightmare') == 16)
        assert(progress.bitFor('Apocalypse') == 32)
        assert(progress.bitFor('Oblivion') == 64)
        assert(progress.bitFor('Ragnarok') == 128)
        assert(progress.bitFor('Terror') == 256)
    end)

    it('requires consecutive clears for progression masks', function()
        local player = makePlayer(7)
        assert(progress.hasThrough(player, 3))
        assert(not progress.hasThrough(player, 4))

        player = makePlayer(15)
        assert(progress.hasThrough(player, 4))
        assert(not progress.has(player, 'Nightmare'))
    end)

    it('records one difficulty without erasing prior clears', function()
        local player, vars = makePlayer(7)
        assert(progress.markClear(player, 'Insane'))
        assert(vars.GM_Wave_Clears == 15)
        assert(not progress.markClear(player, 'Insane'))
        assert(vars.GM_Wave_Clears == 15)
    end)
end)
