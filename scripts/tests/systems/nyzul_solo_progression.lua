require('scripts/globals/nyzul')

describe('Nyzul solo progression', function()
    it('uses five scavenger lamps with a two-minute, one-minute-penalty cycle', function()
        assert(xi.nyzul.lampsObjective.SCAVENGER == 4)
        assert(xi.nyzul.scavengerLampCount == 5)
        assert(xi.nyzul.scavengerLampTimeMs == 120000)
        assert(xi.nyzul.scavengerLampPenaltyMin == 1)

        local instance =
        {
            getStage = function() return xi.nyzul.objective.ACTIVATE_ALL_LAMPS end,
        }
        assert(xi.nyzul.getObjectiveText(instance):find('5 runic lamps', 1, true) ~= nil)
        assert(xi.nyzul.getObjectiveText(instance):find('2 minutes', 1, true) ~= nil)
    end)

    it('awards floor-100 Mythic credit only to the Runic Disc holder', function()
        local originalGetPlayerByID = GetPlayerByID
        local holderVars =
        {
            NyzulFloorProgress = 95,
        }
        local helperVars = {}
        local instance
        local holder =
        {
            getInstance = function() return instance end,
            hasKeyItem = function(_, keyItem)
                return keyItem == xi.ki.RUNIC_DISC or keyItem == xi.ki.RUNIC_KEY
            end,
            getCharVar = function(_, name) return holderVars[name] or 0 end,
            setCharVar = function(_, name, value) holderVars[name] = value end,
        }

        instance =
        {
            getLocalVar = function(_, name)
                local vars =
                {
                    Nyzul_Current_Floor = 100,
                    Nyzul_Isle_StartingFloor = 96,
                    diskHolder = 123,
                }
                return vars[name] or 0
            end,
        }

        local mob =
        {
            getInstance = function() return instance end,
        }

        local ok, err = xpcall(function()
            GetPlayerByID = function(id)
                assert(id == 123)
                return holder
            end

            xi.nyzul.handleRunicKey(mob)

            assert(holderVars.NyzulFloorProgress == 100)
            assert(holderVars.Nyzul_F100_Cleared == 1)
            assert(helperVars.Nyzul_F100_Cleared == nil)
        end, debug.traceback)

        GetPlayerByID = originalGetPlayerByID
        assert(ok, err)
    end)
end)
