require('scripts/globals/dynamis')
require('scripts/globals/dynamis_divergence')
require('scripts/zones/Dynamis-San_dOria/IDs')
require('scripts/zones/Dynamis-Bastok/IDs')
require('scripts/zones/Dynamis-Windurst/IDs')
require('scripts/zones/Dynamis-Jeuno/IDs')

describe('Dynamis time extensions', function()
    it('keeps a granule + minutes + mob id on every city TE row', function()
        local cityZones =
        {
            xi.zone.DYNAMIS_SAN_DORIA,
            xi.zone.DYNAMIS_BASTOK,
            xi.zone.DYNAMIS_WINDURST,
            xi.zone.DYNAMIS_JEUNO,
        }

        for _, zoneId in ipairs(cityZones) do
            local tes = zones[zoneId].mob.TIME_EXTENSION
            assert(tes ~= nil)
            assert(#tes == 5)
            for _, te in ipairs(tes) do
                assert(te.minutes >= 10)
                assert(te.ki >= xi.ki.CRIMSON_GRANULES_OF_TIME)
                assert(te.ki <= xi.ki.OBSIDIAN_GRANULES_OF_TIME)
                assert(type(te.mob) == 'number' or type(te.mob) == 'table')
            end
        end
    end)

    local function makeEffect(remainingMs)
        local duration = remainingMs
        return
        {
            getTimeRemaining = function()
                return duration
            end,
            setDuration = function(_, value)
                duration = value
            end,
            resetStartTime = function()
            end,
            getDuration = function()
                return duration
            end,
        }
    end

    local function makePlayer(opts)
        opts = opts or {}
        local kis       = opts.kis or {}
        local localVars = {}
        local effect    = opts.effect
        local granted   = {}
        local messages  = {}

        return
        {
            kis      = kis,
            granted  = granted,
            messages = messages,
            getStatusEffect = function(_, effectId)
                if effectId == xi.effect.DYNAMIS then
                    return effect
                end

                return nil
            end,
            hasKeyItem = function(_, ki)
                return kis[ki] == true
            end,
            delKeyItem = function(_, ki)
                kis[ki] = nil
            end,
            addKeyItem = function(_, ki)
                kis[ki] = true
                granted[#granted + 1] = ki
            end,
            getZoneID = function()
                return opts.zoneId or xi.zone.DYNAMIS_SAN_DORIA
            end,
            setLocalVar = function(_, key, value)
                localVars[key] = value
            end,
            getLocalVar = function(_, key)
                return localVars[key] or 0
            end,
            messageSpecial = function(_, ...)
                messages[#messages + 1] = { ... }
            end,
        }
    end

    it('wipes leftover granules so a later run can award TEs again', function()
        local player = makePlayer({
            kis = {
                [xi.ki.CRIMSON_GRANULES_OF_TIME] = true,
                [xi.ki.OBSIDIAN_GRANULES_OF_TIME] = true,
            },
        })

        xi.dynamis.clearTimeGranules(player)
        assert(player.kis[xi.ki.CRIMSON_GRANULES_OF_TIME] == nil)
        assert(player.kis[xi.ki.OBSIDIAN_GRANULES_OF_TIME] == nil)
    end)

    it('extends remaining Dynamis time and refuses a duplicate granule', function()
        local effect = makeEffect(30 * 60 * 1000)
        local player = makePlayer({ effect = effect })
        local ki     = xi.ki.CRIMSON_GRANULES_OF_TIME

        assert(xi.dynamis.applyTimeExtension(player, 10, ki) == true)
        assert(effect:getTimeRemaining() == 40 * 60 * 1000)
        assert(player.kis[ki] == true)
        assert(#player.messages >= 1)

        assert(xi.dynamis.applyTimeExtension(player, 10, ki) == false)
        assert(effect:getTimeRemaining() == 40 * 60 * 1000)
    end)

    it('credits the zone when a TE dies with no PC killer', function()
        local originalGetMobByID = GetMobByID
        local effect = makeEffect(20 * 60 * 1000)
        local player = makePlayer({ effect = effect })
        local te     = zones[xi.zone.DYNAMIS_SAN_DORIA].mob.TIME_EXTENSION[1]
        local mob    =
        {
            getID = function()
                return te.mob
            end,
            getZoneID = function()
                return xi.zone.DYNAMIS_SAN_DORIA
            end,
            getName = function()
                return 'Warchief_Tombstone'
            end,
            getZone = function()
                return
                {
                    getPlayers = function()
                        return { player }
                    end,
                }
            end,
        }

        local ok, err = xpcall(function()
            GetMobByID = function()
                return { setRespawnTime = function() end }
            end

            xi.dynamis.timeExtensionOnDeath(mob, nil, { noKiller = true })
            assert(player.kis[te.ki] == true)
            assert(effect:getTimeRemaining() == 30 * 60 * 1000)
        end, debug.traceback)

        GetMobByID = originalGetMobByID
        assert(ok, err)
    end)

    it('does not treat a preloaded Divergence statue as a time extension', function()
        local originalGetMobByID = GetMobByID
        local vars = {}
        local instance =
        {
            getLocalVar = function(_, key)
                return vars[key] or 0
            end,
            setLocalVar = function(_, key, value)
                vars[key] = value
            end,
        }
        local mob =
        {
            isAlive = function()
                return false
            end,
        }

        local ok, err = xpcall(function()
            GetMobByID = function()
                return mob
            end

            assert(xi.divergence.isStatueDefeated(instance, 17982348) == false)
            assert((vars['stSeen17982348'] or 0) == 0)
        end, debug.traceback)

        GetMobByID = originalGetMobByID
        assert(ok, err)
    end)

    it('credits a Divergence statue only after it has been seen alive', function()
        local originalGetMobByID = GetMobByID
        local vars = {}
        local alive = true
        local instance =
        {
            getLocalVar = function(_, key)
                return vars[key] or 0
            end,
            setLocalVar = function(_, key, value)
                vars[key] = value
            end,
            getTimeLimit = function()
                return 90
            end,
            setTimeLimit = function(_, seconds)
                vars.timeLimitSec = seconds
            end,
            getChars = function()
                return {}
            end,
        }
        local mob =
        {
            isAlive = function()
                return alive
            end,
        }

        local ok, err = xpcall(function()
            GetMobByID = function()
                return mob
            end

            assert(xi.divergence.isStatueDefeated(instance, 42) == false)
            assert(vars['stSeen42'] == 1)

            alive = false
            assert(xi.divergence.isStatueDefeated(instance, 42) == true)
            assert(xi.divergence.creditStatue(instance, 42) == true)
            assert(vars['st42'] == 1)
            assert(vars.timeLimitSec == 91 * 60)
            assert(xi.divergence.creditStatue(instance, 42) == false)
        end, debug.traceback)

        GetMobByID = originalGetMobByID
        assert(ok, err)
    end)

    it('still credits a Divergence statue if GetMobByID misses after death', function()
        local originalGetMobByID = GetMobByID
        local vars = { stSeen99 = 1 }
        local instance =
        {
            getLocalVar = function(_, key)
                return vars[key] or 0
            end,
            setLocalVar = function(_, key, value)
                vars[key] = value
            end,
        }

        local ok, err = xpcall(function()
            GetMobByID = function()
                return nil
            end

            assert(xi.divergence.isStatueDefeated(instance, 99) == true)
        end, debug.traceback)

        GetMobByID = originalGetMobByID
        assert(ok, err)
    end)
end)
