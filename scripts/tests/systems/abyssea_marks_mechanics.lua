local runtime = require('modules/custom/lua/abyssea_marks_mechanics')

describe('Abyssea marks encounter lifecycle', function()
    it('attaches cleanly, ignores Trust hold-fire damage, and deduplicates procs', function()
        local originalGetPlayerByID = GetPlayerByID
        local listeners = {}
        local charVars = {}
        local healed = 0
        local timers = {}

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
        function mob:timer(_, callback)
            timers[#timers + 1] = callback
        end
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
            local trustDeferred = table.remove(timers, 1)
            trustDeferred(mob)
            assert(healed == 0)

            listeners.ABY_MARKS_DAMAGE(mob, 400, player, xi.attackType.PHYSICAL)
            assert(state.challenge.ownerDamage == 400)
            assert(healed == 0)
            local ownerDeferred = table.remove(timers, 1)
            ownerDeferred(mob)
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

    it('anchors positional tells and restores existing movement state', function()
        local originalGetPlayerByID = GetPlayerByID
        local listeners = {}
        local noMove = 7
        local behavior = xi.behavior.NO_ASSIST
        local stagger
        local weaknessTriggers = 0

        local player = {}
        function player:getID() return 1002 end
        function player:getHP() return 1000 end
        function player:getMaxHP() return 1000 end
        function player:getHPP() return 100 end
        function player:getParty() return { self } end
        function player:getZoneID() return 15 end
        function player:isPC() return true end
        function player:isBehind() return true end
        function player:printToPlayer() end
        function player:setCharVar() end
        function player:getXPos() return 0 end
        function player:getZPos() return 0 end

        local mob = {}
        function mob:getID() return 3002 end
        function mob:getName() return 'Positional_Test_Mob' end
        function mob:getZoneID() return 15 end
        function mob:getHPP() return 100 end
        function mob:getHP() return 10000 end
        function mob:getMaxHP() return 10000 end
        function mob:getMobMod(mobMod)
            return mobMod == xi.mobMod.NO_MOVE and noMove or 0
        end
        function mob:setMobMod(mobMod, value)
            if mobMod == xi.mobMod.NO_MOVE then noMove = value end
        end
        function mob:getBehavior() return behavior end
        function mob:setBehavior(value) behavior = value end
        function mob:setHP() end
        function mob:addMod() end
        function mob:weaknessTrigger()
            weaknessTriggers = weaknessTriggers + 1
        end
        function mob:addStatusEffect(effect, params)
            stagger = { effect = effect, params = params }
        end
        function mob:addListener(_, id, callback) listeners[id] = callback end
        function mob:removeListener(id) listeners[id] = nil end

        local ok, err = xpcall(function()
            GetPlayerByID = function(id)
                return id == player:getID() and player or nil
            end

            local rear =
            {
                kind = 'rear', tell = 'Rear', success = 'Good', fail = 'Bad',
                delaySec = 0, failure = {}, reward = {},
            }
            runtime.attach(mob,
                {
                    tier = 3, label = 'Test', signature = rear,
                    phases =
                    {
                        {
                            hp = 100, kind = 'highhp', tell = 'Phase',
                            success = 'Good', fail = 'Bad', delaySec = 10,
                            failure = {}, reward = {},
                        },
                    },
                    firstSignatureSec = 0, repeatSec = 999, pressureSec = 720,
                },
                player)

            listeners.ABY_MARKS_COMBAT(mob)
            assert(noMove == 1)
            assert(bit.band(behavior, xi.behavior.NO_TURN) ~= 0)
            assert(bit.band(behavior, xi.behavior.NO_ASSIST) ~= 0)

            listeners.ABY_MARKS_COMBAT(mob)
            assert(runtime.getState(mob).challenge == nil)
            assert(noMove == 7)
            assert(behavior == xi.behavior.NO_ASSIST)
            assert(stagger.effect == xi.effect.TERROR)
            assert(stagger.params.duration == 15)
            assert(stagger.params.origin == player)
            assert(weaknessTriggers == 2)
            assert(runtime.getState(mob).vulnerability)
            assert(runtime.getState(mob).nextPhase == 1)

            rear.delaySec = 5
            runtime.attach(mob,
                {
                    tier = 3, label = 'Test', signature = rear, phases = {},
                    firstSignatureSec = 0, repeatSec = 999, pressureSec = 720,
                },
                player)
            listeners.ABY_MARKS_COMBAT(mob)
            assert(noMove == 1)
            listeners.ABY_MARKS_DESPAWN(mob)
            assert(runtime.getState(mob) == nil)
            assert(noMove == 7)
            assert(behavior == xi.behavior.NO_ASSIST)
        end, debug.traceback)

        GetPlayerByID = originalGetPlayerByID
        assert(ok, err)
    end)

    it('punishes failure only with a visible status and native TP move', function()
        local originalGetPlayerByID = GetPlayerByID
        local listeners = {}
        local status
        local damageCalls = 0
        local forcedTp
        local usedSkill

        local player = {}
        function player:getID() return 1003 end
        function player:getHP() return 1000 end
        function player:getMaxHP() return 1000 end
        function player:getHPP() return 10 end
        function player:getParty() return { self } end
        function player:getZoneID() return 15 end
        function player:isPC() return true end
        function player:printToPlayer() end
        function player:getCharVar() return 0 end
        function player:setCharVar() end
        function player:getXPos() return 0 end
        function player:getZPos() return 0 end
        function player:takeDamage()
            damageCalls = damageCalls + 1
        end
        function player:addStatusEffect(effect, params)
            status = { effect = effect, params = params }
        end

        local mob = {}
        function mob:getID() return 3003 end
        function mob:getName() return 'Failure_Test_Mob' end
        function mob:getZoneID() return 15 end
        function mob:getHPP() return 100 end
        function mob:getHP() return 10000 end
        function mob:getMaxHP() return 10000 end
        function mob:setHP() end
        function mob:weaknessTrigger() end
        function mob:setTP(value) forcedTp = value end
        function mob:useMobAbility(...)
            usedSkill = { ... }
        end
        function mob:addListener(_, id, callback) listeners[id] = callback end
        function mob:removeListener(id) listeners[id] = nil end

        local ok, err = xpcall(function()
            GetPlayerByID = function(id)
                return id == player:getID() and player or nil
            end

            local highhp =
            {
                kind = 'highhp', tell = 'Recover', success = 'Good', fail = 'Bad',
                delaySec = 0,
                failure =
                {
                    skill = 353, effect = xi.effect.POISON,
                    power = 9, duration = 12,
                },
                reward = {},
            }
            runtime.attach(mob,
                {
                    tier = 3, label = 'Test', signature = highhp,
                    phases =
                    {
                        {
                            hp = 100, kind = 'highhp', tell = 'Phase',
                            success = 'Good', fail = 'Bad', delaySec = 10,
                            failure = { skill = 353 }, reward = {},
                        },
                    },
                    firstSignatureSec = 0, repeatSec = 999, pressureSec = 720,
                },
                player)

            listeners.ABY_MARKS_COMBAT(mob)
            assert(runtime.getState(mob).challenge)
            listeners.ABY_MARKS_COMBAT(mob)

            assert(runtime.getState(mob).challenge == nil)
            assert(runtime.getState(mob).nextPhase == 1)
            assert(runtime.getState(mob).punishmentUntil)
            assert(damageCalls == 0)
            assert(status.effect == xi.effect.POISON)
            assert(status.params.power == 9)
            assert(status.params.duration == 12)
            assert(status.params.tick == 3)
            assert(status.params.origin == mob)
            assert(forcedTp == 3000)
            assert(usedSkill[1] == 353)
            assert(usedSkill[2] == player)
            assert(usedSkill[4] == true)

            runtime.cleanup(mob)
        end, debug.traceback)

        GetPlayerByID = originalGetPlayerByID
        assert(ok, err)
    end)
end)
