require('modules/custom/lua/Character_Upgrader')

local travelGuard = require('modules/custom/lua/travel_guard')
local setupCmd    = require('modules/custom/commands/setup')
local unlockCmd   = require('modules/custom/commands/unlockfix')

describe('First-login character upgrade', function()
    local HOMEPOINT = xi.teleport.type.HOMEPOINT

    local function stampLateHomepoint(player)
        player.teleports[HOMEPOINT] = player.teleports[HOMEPOINT] or {}
        player.teleports[HOMEPOINT][3] = player.teleports[HOMEPOINT][3] or {}
        player.teleports[HOMEPOINT][3][25] = true
    end

    local function giveSentinelKeyItems(player)
        for _, kiId in ipairs(xi.characterUpgrade.SENTINEL_KIS) do
            player.kis[kiId] = true
        end
    end

    local function makePlayer(opts)
        opts = opts or {}
        local vars      = opts.vars or {}
        local localVars = opts.localVars or {}
        local kis       = opts.kis or {}
        local player    =
        {
            vars      = vars,
            localVars = localVars,
            kis       = kis,
            teleports = opts.teleports or {},
            messages  = {},
            timers    = 0,
        }

        player.isPC = function()
            return true
        end

        player.getCharVar = function(_, key)
            return vars[key] or 0
        end

        player.setCharVar = function(_, key, value)
            vars[key] = value
        end

        player.getLocalVar = function(_, key)
            return localVars[key] or 0
        end

        player.setLocalVar = function(_, key, value)
            localVars[key] = value
        end

        player.hasKeyItem = function(_, kiId)
            return kis[kiId] == true
        end

        player.hasTeleport = function(_, teleportType, bit, set)
            local byType = player.teleports[teleportType]
            return byType ~= nil and byType[set] ~= nil and byType[set][bit] == true
        end

        player.printToPlayer = function(_, message)
            player.messages[#player.messages + 1] = message
        end

        player.timer = function()
            player.timers = player.timers + 1
        end

        player.hasStatusEffect = function(_, effect)
            return player.lockEffect == effect
        end

        player.addStatusEffect = function(_, effect)
            player.lockEffect = effect
            return true
        end

        player.delStatusEffectSilent = function(_, effect)
            if player.lockEffect == effect then
                player.lockEffect = nil
            end
            return true
        end

        return player
    end

    it('treats AutoUnlock_Complete as finished', function()
        local player = makePlayer({ vars = { AutoUnlock_Complete = 1 } })
        assert(xi.characterUpgrade.isComplete(player) == true)
    end)

    it('backfills complete from sentinel mounts plus the last homepoint', function()
        local player = makePlayer()
        giveSentinelKeyItems(player)
        stampLateHomepoint(player)

        assert(xi.characterUpgrade.isComplete(player) == true)
        assert(player.vars.AutoUnlock_Complete == 1)
    end)

    it('stays incomplete when a late mount KI is missing', function()
        local player = makePlayer()
        giveSentinelKeyItems(player)
        player.kis[xi.ki.CRAKLAW_COMPANION] = nil
        stampLateHomepoint(player)

        assert(xi.characterUpgrade.isComplete(player) == false)
        assert((player.vars.AutoUnlock_Complete or 0) == 0)
    end)

    it('stays incomplete when the last homepoint is missing', function()
        local player = makePlayer()
        giveSentinelKeyItems(player)

        assert(xi.characterUpgrade.isComplete(player) == false)
    end)

    it('does not resume an already-complete character unless forced', function()
        local player = makePlayer({ vars = { AutoUnlock_Complete = 1 } })
        assert(xi.characterUpgrade.resume(player) == false)
        assert(player.timers == 0)
        assert(xi.characterUpgrade.resume(player, { force = true, delayMs = 10 }) == true)
        assert(player.vars.AutoUnlock_Complete == 0)
        assert(player.localVars.AutoUnlock_Running == 1)
        assert(player.timers == 1)
        assert(player.lockEffect == xi.effect.BIND)
    end)

    it('binds an incomplete character and clears the lock when asked', function()
        local player = makePlayer()
        assert(xi.characterUpgrade.resume(player, { delayMs = 10 }) == true)
        assert(player.lockEffect == xi.effect.BIND)

        xi.characterUpgrade.clearMovementLock(player)
        assert(player.lockEffect == nil)
    end)

    it('resumes an interrupted grant and refuses travel', function()
        local player = makePlayer({ vars = { AutoUnlock_Done = 1 } })
        assert(xi.characterUpgrade.refuseTravel(player) == true)
        assert(player.localVars.AutoUnlock_Running == 1)
        assert(player.timers == 1)
        assert(xi.characterUpgrade.refuseTravel(player) == true)
        assert(player.timers == 1)
    end)

    it('allows travel after setup is complete', function()
        local player = makePlayer({ vars = { AutoUnlock_Complete = 1, AutoUnlock_Done = 1 } })
        assert(xi.characterUpgrade.refuseTravel(player) == false)
        assert(travelGuard.refuseTravel(player) == false)
    end)

    it('lets !setup restart an incomplete grant and no-ops when complete', function()
        local incomplete = makePlayer()
        setupCmd.onTrigger(incomplete)
        assert(incomplete.localVars.AutoUnlock_Running == 1)
        assert(incomplete.timers == 1)

        setupCmd.onTrigger(incomplete)
        assert(incomplete.timers == 1)
        assert(incomplete.messages[#incomplete.messages] ==
            'Setup is still running -- you cannot move until Setup Complete, kupo!')

        local complete = makePlayer({ vars = { AutoUnlock_Complete = 1 } })
        setupCmd.onTrigger(complete)
        assert(complete.timers == 0)
        assert(complete.messages[1] == 'Your character setup is already complete.')
    end)

    it('blocks !hub during an interrupted grant', function()
        local hub = require('modules/custom/commands/hub')
        local player = makePlayer({ vars = { AutoUnlock_Done = 1 } })
        player.setPos = function()
            player.moved = true
        end

        hub.onTrigger(player)
        assert(player.moved ~= true)
        assert(player.localVars.AutoUnlock_Running == 1)
    end)

    it('skips mid-setup party members on !warpty', function()
        local warpty = require('scripts/commands/warpty')
        local member = makePlayer({ vars = { AutoUnlock_Done = 1 } })
        member.getID = function()
            return 2
        end
        member.getZoneID = function()
            return 230
        end
        member.setPos = function()
            member.moved = true
        end
        member.setInstance = function()
        end

        local leader = makePlayer({ vars = { AutoUnlock_Complete = 1 } })
        leader.getPartySize = function()
            return 2
        end
        leader.getPartyLeader = function()
            return leader
        end
        leader.getID = function()
            return 1
        end
        leader.getXPos = function()
            return 0
        end
        leader.getYPos = function()
            return 0
        end
        leader.getZPos = function()
            return 0
        end
        leader.getRotPos = function()
            return 0
        end
        leader.getZoneID = function()
            return 230
        end
        leader.getInstance = function()
            return nil
        end
        leader.getParty = function()
            return { leader, member }
        end
        leader.getName = function()
            return 'Leader'
        end
        leader.getZoneName = function()
            return 'Southern San dOria'
        end

        warpty.onTrigger(leader)
        assert(member.moved ~= true)
        assert(member.localVars.AutoUnlock_Running == 1)
    end)

    it('lets !unstick run during setup', function()
        local unstick = require('scripts/commands/unstick')
        local player = makePlayer({ vars = { AutoUnlock_Done = 1 } })
        player.released = false
        player.release = function()
            player.released = true
        end
        player.getMoghouseFlag = function()
            return 0
        end
        player.setMoghouseFlag = function()
        end

        unstick.onTrigger(player)
        assert(player.released == true)
        assert(player.localVars.AutoUnlock_Running ~= 1)
    end)

    it('keeps !setup as a player command and !unlockfix as GM1', function()
        assert(setupCmd.cmdprops.permission == 0)
        assert(unlockCmd.cmdprops.permission == 1)
    end)

    it('refuses travel for a jailed player even when setup is complete', function()
        local player = makePlayer({ vars = { AutoUnlock_Complete = 1, inJail = 2 } })
        assert(travelGuard.refuseTravel(player) == true)
        assert(xi.characterUpgrade.refuseTravel(player) == false)
    end)
end)
