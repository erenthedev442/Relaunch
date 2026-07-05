-----------------------------------
-- Shared private-dungeon runtime
-----------------------------------
local catalog      = require('modules/custom/lua/dungeon_catalog')
local augmentDrops = require('modules/custom/lua/augment_dungeon_drops')

local runtime = {}

local function forEachPlayer(instance, fn)
    for _, player in ipairs(instance:getChars()) do
        fn(player)
    end
end

local function leaveDungeon(player, message)
    player:setCharVar('DungeonActive', 0)
    player:setLocalVar('DungeonInstancePending', 0)
    if message then
        player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
    end

    player:setPos(
        catalog.exit.x,
        catalog.exit.y,
        catalog.exit.z,
        catalog.exit.rotation,
        catalog.exit.zoneId)
end

-- Closes the target's whole private dungeon when its live CInstance still
-- exists.  If only stale dungeon markers remain, recover just that player.
runtime.forceClose = function(player)
    local activeId = player:getCharVar('DungeonActive')
    local pendingId = player:getLocalVar('DungeonInstancePending')
    local instance = player:getInstance()
    local dungeon = catalog.getDungeonByInstanceId(activeId) or
        catalog.getDungeonByInstanceId(pendingId)

    if instance then
        local liveDungeon = catalog.getDungeonByInstanceId(instance:getID())
        if not liveDungeon then
            return false, 0, nil, 'The player is in a non-dungeon instance.'
        end

        local memberCount = #instance:getChars()
        instance:fail()
        return true, memberCount, liveDungeon, nil
    end

    if not dungeon then
        return false, 0, nil, 'The player has no active dungeon.'
    end

    leaveDungeon(player, '[Dungeon] A GM has force-closed your dungeon.')
    return true, 1, dungeon, nil
end

runtime.create = function(dungeonKey)
    local dungeon = catalog.dungeons[dungeonKey]
    assert(dungeon, string.format('Unknown dungeon catalogue key: %s', dungeonKey))

    local instanceObject = {}

    local function onDungeonMobDeath(instance, deadMob)
        if instance:completed() or instance:failed() then
            return
        end

        -- Core dispatches onMobDeath once per nearby alliance member.  The
        -- marker belongs to this runtime mob, so each private instance and mob
        -- decrements its own objective exactly once.
        if deadMob:getLocalVar('DungeonDeathCounted') ~= 0 then
            return
        end

        deadMob:setLocalVar('DungeonDeathCounted', 1)

        local remaining = instance:getLocalVar('DungeonMobsRemaining')
        if remaining == 0 then
            return
        end

        remaining = remaining - 1
        instance:setLocalVar('DungeonMobsRemaining', remaining)

        forEachPlayer(instance, function(player)
            player:printToPlayer(
                string.format('[Dungeon] %s defeated. %d monster(s) remain.', deadMob:getPacketName(), remaining),
                xi.msg.channel.SYSTEM_3)
        end)

        if remaining > 0 and remaining <= 3 then
            for _, target in ipairs(instance:getMobs()) do
                if target:getHP() > 0 then
                    forEachPlayer(instance, function(player)
                        player:printToPlayer(
                            string.format('[Dungeon Tracker] %s is near X %.0f, Z %.0f.',
                                target:getPacketName(), target:getXPos(), target:getZPos()),
                            xi.msg.channel.SYSTEM_3)
                    end)
                end
            end
        end

        if remaining == 0 then
            local elapsedSeconds = math.floor(instance:getLocalVar('DungeonElapsedMs') / 1000)
            instance:setLocalVar('DungeonKickAt', elapsedSeconds + catalog.completionDelay)
            instance:setLocalVar('DungeonLastCountdown', catalog.completionDelay + 1)
            instance:complete()
        end
    end

    instanceObject.onInstanceCreated = function(instance)
        local spawned = 0

        for index, def in ipairs(dungeon.mobs) do
            local mob = instance:insertDynamicEntity({
                objtype              = xi.objType.MOB,
                groupId              = def.groupId,
                groupZoneId          = dungeon.zoneId,
                name                 = def.name,
                x                    = def.x,
                y                    = def.y,
                z                    = def.z,
                rotation             = def.r,
                minLevel             = dungeon.level,
                maxLevel             = dungeon.level,
                detection            = xi.detects.SIGHT_AND_HEARING,
                isAggroable          = true,
                releaseIdOnDisappear = true,

                onMobDeath = function(deadMob, player, optParams)
                    onDungeonMobDeath(instance, deadMob)
                    -- Catalyst payouts (Augmentation Dungeons only; acts on
                    -- the optParams.isKiller dispatch, no-op otherwise).
                    augmentDrops.onDungeonMobDeath(dungeonKey, instance, deadMob, player, optParams)
                end,
            })

            if mob then
                mob:setLocalVar('DungeonMobIndex', index)
                if index == #dungeon.mobs then
                    mob:setLocalVar('DungeonBossMob', 1)
                end
                mob:setSpawn(def.x, def.y, def.z, def.r)
                mob:spawn()
                mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
                if dungeon.noDrops ~= false then
                    mob:setMobMod(xi.mobMod.NO_DROPS, 1)
                end

                local scaledHP = math.floor(mob:getMaxHP() * (def.hpScale or dungeon.hpScale))
                mob:setMaxHP(scaledHP)
                mob:setHP(scaledHP)
                spawned = spawned + 1
            end
        end

        instance:setLocalVar('DungeonMobsRemaining', spawned)
        if spawned == 0 then
            instance:fail()
        end
    end

    instanceObject.onInstanceCreatedCallback = function(player, instance)
        if not instance then
            player:setLocalVar('DungeonInstancePending', 0)
            return
        end

        -- Only the requesting party is attached to this newly-created runtime
        -- copy.  Another party using the same database template receives a
        -- different CInstance and independent mobs/local variables.
        local registered = 0
        for _, member in ipairs(player:getParty()) do
            if
                member:getObjType() == xi.objType.PC and
                member:getZoneID() == catalog.npc.zoneId and
                member:getLocalVar('DungeonInstancePending') == dungeon.instanceId
            then
                member:setInstance(instance)
                member:setCharVar('DungeonActive', dungeon.instanceId)
                member:setLocalVar('DungeonInstancePending', 0)
                registered = registered + 1
            end
        end

        if registered == 0 then
            instance:fail()
            return
        end

        for _, member in ipairs(player:getParty()) do
            if member:getInstance() == instance then
                member:setPos(0, 0, 0, 0, dungeon.zoneId)
            end
        end
    end

    instanceObject.afterInstanceRegister = function(player)
        local instance = player:getInstance()
        if not instance then
            return
        end

        player:printToPlayer(
            string.format('[Dungeon] Private %s opened. Defeat all %d monsters within %d minutes.',
                dungeon.label, instance:getLocalVar('DungeonMobsRemaining'), catalog.runTimeMinutes),
            xi.msg.channel.SYSTEM_3)
        player:printToPlayer(
            '[Dungeon] Follow the marked route; the final three living targets will be tracked.',
            xi.msg.channel.SYSTEM_3)
    end

    instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
        instance:setLocalVar('DungeonElapsedMs', elapsed)

        if instance:completed() then
            local remaining = instance:getLocalVar('DungeonKickAt') - math.floor(elapsed / 1000)
            if remaining <= 0 then
                forEachPlayer(instance, function(player)
                    leaveDungeon(player, '[Dungeon] The cleared dungeon has closed.')
                end)
                return
            end

            local announce = remaining == 20 or remaining == 10 or remaining <= 5
            if announce and instance:getLocalVar('DungeonLastCountdown') ~= remaining then
                instance:setLocalVar('DungeonLastCountdown', remaining)
                forEachPlayer(instance, function(player)
                    player:printToPlayer(
                        string.format('[Dungeon] Clear complete! Exiting in %d second(s).', remaining),
                        xi.msg.channel.SYSTEM_3)
                end)
            end

            return
        end

        if elapsed >= instance:getTimeLimit() * 60 * 1000 then
            instance:fail()
            return
        end

        local emptySince = instance:getWipeTime()
        if emptySince ~= 0 and elapsed - emptySince >= catalog.emptyCloseDelay * 1000 then
            instance:fail()
        end
    end

    instanceObject.onInstanceFailure = function(instance)
        forEachPlayer(instance, function(player)
            leaveDungeon(player, '[Dungeon] The dungeon has closed without a clear.')
        end)
    end

    instanceObject.onInstanceComplete = function(instance)
        forEachPlayer(instance, function(player)
            player:printToPlayer(
                string.format('[Dungeon] Every monster is down! This instance closes in %d seconds.',
                    catalog.completionDelay),
                xi.msg.channel.SYSTEM_3)
        end)
    end

    return instanceObject
end

return runtime
