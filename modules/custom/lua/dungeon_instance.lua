-----------------------------------
-- Shared private-dungeon runtime
-----------------------------------
local catalog      = require('modules/custom/lua/dungeon_catalog')
local augmentDrops = require('modules/custom/lua/augment_dungeon_drops')

-- Zoning leash (world units): a player more than this far from EVERY roster
-- anchor is heading for a wall / zone line -- crossing one drops them from the
-- private instance and ends the run -- so we pull them back first. Generous so
-- normal fighting near the route never trips it; tune down if players still slip
-- out, up if legitimate positions get yanked.
local DUNGEON_LEASH = 55

-- Hot-reloadable: reuse the cached table so a FileWatcher re-run updates
-- runtime.create in place -- NEW dungeon instances then use the updated spawn
-- logic without a map restart (same pattern as augment_dungeon_drops.lua).
local runtime = package.loaded['modules/custom/lua/dungeon_instance']
if type(runtime) ~= 'table' then runtime = {} end

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

    local bossIndex = #dungeon.mobs
    local bossDef   = dungeon.mobs[bossIndex]

    -- Forward declaration: onDungeonMobDeath summons the boss once the trash is
    -- cleared, and spawnDungeonMob needs onDungeonMobDeath for its onMobDeath.
    local spawnDungeonMob

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
            -- All TRASH is down: summon the boss NOW. It is withheld at spawn so
            -- players can never pull it first (the old bug: the boss sat in the
            -- roster and could be the first mob fought). A boss kill therefore
            -- always caps a genuine full clear.
            if instance:getLocalVar('DungeonBossSpawned') == 0 then
                instance:setLocalVar('DungeonBossSpawned', 1)

                if spawnDungeonMob(instance, bossIndex) then
                    instance:setLocalVar('DungeonMobsRemaining', 1)
                    forEachPlayer(instance, function(player)
                        player:printToPlayer(
                            string.format('[Dungeon] The lair is cleared -- %s emerges near X %.0f, Z %.0f! Slay it to finish the run.',
                                bossDef.name, bossDef.x, bossDef.z),
                            xi.msg.channel.SYSTEM_3)
                    end)
                    return
                end
                -- Boss failed to spawn (should not happen) -- fall through to
                -- completion rather than soft-locking the run.
            end

            local elapsedSeconds = math.floor(instance:getLocalVar('DungeonElapsedMs') / 1000)
            instance:setLocalVar('DungeonKickAt', elapsedSeconds + catalog.completionDelay)
            instance:setLocalVar('DungeonLastCountdown', catalog.completionDelay + 1)
            instance:complete()
        end
    end

    -- Spawns roster slot `index` into the instance; returns the mob (or nil).
    spawnDungeonMob = function(instance, index)
        local def = dungeon.mobs[index]
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
                -- Catalyst payouts (Augmentation Dungeons only; acts on the
                -- optParams.isKiller dispatch, no-op otherwise). Pass the roster
                -- index + boss flag straight from this closure -- the
                -- DungeonMobIndex localvar does NOT survive on these dynamic
                -- mobs (reads 0 at death), so relying on it dropped nothing.
                augmentDrops.onDungeonMobDeath(dungeonKey, instance, deadMob, player, optParams, index, index == bossIndex)
            end,
        })

        if not mob then
            return nil
        end

        mob:setLocalVar('DungeonMobIndex', index)
        if index == bossIndex then
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
        return mob
    end

    instanceObject.onInstanceCreated = function(instance)
        local spawned = 0

        -- Spawn TRASH ONLY (slots 1 .. bossIndex-1). The boss is withheld until
        -- every trash mob is dead (see onDungeonMobDeath) so it can never be the
        -- first thing pulled, and a boss kill always caps a full clear.
        for index = 1, bossIndex - 1 do
            if spawnDungeonMob(instance, index) then
                spawned = spawned + 1
            end
        end

        instance:setLocalVar('DungeonMobsRemaining', spawned)
        instance:setLocalVar('DungeonBossSpawned', 0)
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
            string.format('[Dungeon] Private %s opened. Clear all %d guardians within %d minutes -- the boss emerges once they fall.',
                dungeon.label, instance:getLocalVar('DungeonMobsRemaining'), catalog.runTimeMinutes),
            xi.msg.channel.SYSTEM_3)
        player:printToPlayer(
            '[Dungeon] Follow the marked route (the final three living targets are tracked). Stay on it -- straying toward a zone line pulls you back.',
            xi.msg.channel.SYSTEM_3)
    end

    instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
        instance:setLocalVar('DungeonElapsedMs', elapsed)

        -- Zoning leash: while the run is live, pull back anyone who has wandered
        -- more than DUNGEON_LEASH units from EVERY roster anchor (heading for a
        -- zone line). Crossing one would orphan them out of the instance and end
        -- the run, so we relocate them to the nearest anchor instead.
        if not instance:completed() and not instance:failed() then
            forEachPlayer(instance, function(player)
                local px, pz = player:getXPos(), player:getZPos()
                local bestSq, bestDef
                for _, def in ipairs(dungeon.mobs) do
                    local dx, dz = px - def.x, pz - def.z
                    local dsq    = dx * dx + dz * dz
                    if not bestSq or dsq < bestSq then
                        bestSq  = dsq
                        bestDef = def
                    end
                end
                if bestDef and bestSq > DUNGEON_LEASH * DUNGEON_LEASH then
                    player:setPos(bestDef.x, bestDef.y, bestDef.z, bestDef.r)
                    player:printToPlayer(
                        '[Dungeon] You strayed toward a zone line and were pulled back onto the route.',
                        xi.msg.channel.SYSTEM_3)
                end
            end)
        end

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
