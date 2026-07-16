local runtime = require('modules/custom/lua/abyssea_marks_mechanics')

describe('Abyssea marks encounter lifecycle', function()
    it('attaches cleanly, ignores Trust hold-fire damage, and deduplicates procs', function()
        local originalGetPlayerByID = GetPlayerByID
        local listeners = {}
        local charVars = {}
        local healed = 0

        local player = {}
        function player:getID() return 1001 end
        function player:getHP() return 1000 end
        function player:getMaxHP() return 1000 end
        function player:getHPP() return 100 end
        function player:getName() return 'Test Player' end
        function player:getParty() return { self } end
        function player:getZoneID() return 15 end
        function player:isPC() return true end
        function player:printToPlayer() end
        function player:getCharVar(name) return charVars[name] or 0 end
        function player:setCharVar(name, value) charVars[name] = value end
        function player:getXPos() return 0 end
        function player:getZPos() return 0 end

        local trust = {}
        function trust:isPC() return false end
        function trust:getID() return 2001 end

        local mob = {}
        function mob:getID() return 3001 end
        function mob:getName() return 'Test_Mob' end
        function mob:getZoneID() return 15 end
        function mob:getHPP() return 100 end
        function mob:getHP() return 10000 end
        function mob:getMaxHP() return 10000 end
        function mob:setHP() end
        function mob:addHP(value) healed = healed + value end
        function mob:addMod() end
        function mob:addStatusEffect() end
        function mob:weaknessTrigger() end
        function mob:addListener(_, id, callback) listeners[id] = callback end
        function mob:removeListener(id) listeners[id] = nil end

        local ok, err = xpcall(function()
            GetPlayerByID = function(id)
                return id == player:getID() and player or nil
            end

            local hold =
            {
                kind = 'hold', tell = 'Hold', success = 'Good', fail = 'Bad',
                delaySec = 5, failure = {}, reward = {},
            }
            runtime.attach(mob,
                {
                    tier = 1, label = 'Test', signature = hold, phases = {},
                    firstSignatureSec = 0, pressureSec = 720,
                },
                player)

            listeners.ABY_MARKS_COMBAT(mob)
            local state = runtime.getState(mob)
            assert(state and state.challenge)

            listeners.ABY_MARKS_DAMAGE(mob, 500, trust, xi.attackType.PHYSICAL)
            assert(state.challenge.ownerDamage == 0)
            assert(healed == 0)

            listeners.ABY_MARKS_DAMAGE(mob, 400, player, xi.attackType.PHYSICAL)
            assert(state.challenge.ownerDamage == 400)
            assert(healed == 400)

            runtime.onProc(mob, player, xi.abyssea.triggerType.RED)
            runtime.onProc(mob, player, xi.abyssea.triggerType.RED)
            assert(charVars.AbyProcRed == 1)

            runtime.cleanup(mob)
            assert(runtime.getState(mob) == nil)
            assert(listeners.ABY_MARKS_COMBAT == nil)
        end, debug.traceback)

        GetPlayerByID = originalGetPlayerByID
        assert(ok, err)
    end)
end)
