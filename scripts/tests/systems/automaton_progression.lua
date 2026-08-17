require('scripts/globals/automatonweaponskills')
local progression = require('modules/custom/lua/standard_ws_tuning_catalog')

describe('Automaton companion progression', function()
    local function makeMaster(mainItemId, spentJobPoints)
        return
        {
            isPC = function()
                return true
            end,
            getEquipID = function()
                return mainItemId
            end,
            getMainLvl = function()
                return 99
            end,
            getMainJob = function()
                return xi.job.PUP
            end,
            getSpentJobPoints = function()
                return spentJobPoints
            end,
        }
    end

    local target =
    {
        getMainLvl = function()
            return 150
        end,
    }

    local function makeAutomaton(master)
        local localVars = {}

        return
        {
            getMaster = function()
                return master
            end,
            setLocalVar = function(_, name, value)
                localVars[name] = value
            end,
            getLocalVar = function(_, name)
                return localVars[name] or 0
            end,
        }
    end

    it('applies shared companion progression without a universal automaton multiplier', function()
        local automaton = makeAutomaton(makeMaster(1, 0))

        assert(xi.autows.applyAutomatonProgression(automaton, target, 1000) == 7000)
        assert(xi.autows.applyAutomatonProgression(automaton, target, 100000) == 79999)
    end)

    it('uses the master weapon tier for the cap', function()
        local automaton = makeAutomaton(makeMaster(20511, 2100)) -- Kenkonken

        assert(xi.autows.applyAutomatonProgression(automaton, target, 100000) == 999999)
        local primeAutomaton = makeAutomaton(makeMaster(21535, 2100)) -- Varga Purnikawa
        assert(xi.autows.applyAutomatonProgression(primeAutomaton, target, 100000) == 1499999)
        assert(primeAutomaton:getLocalVar('CompanionDamageCap') == 1499999)
        assert(progression.getPetDamageCap(makeMaster(21535, 2100)) == 1499999)
        assert(progression.getPetDamageCap(makeMaster(22106, 2100)) == 79999) -- SMN's Opashoro
    end)
end)
