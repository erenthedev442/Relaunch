-----------------------------------
-- Private Unity Wanted runtime
--
-- This is deliberately separate from unity_wanted.lua.  The original board
-- continues to use Escha - Zi'Tah and UW_NM; this test path uses a private
-- Ghelsba Outpost instance and UWI_* state.
-----------------------------------
local catalog = require('modules/custom/lua/unity_wanted_catalog')

local runtime = {}

runtime.config =
{
    instanceId = 14000,
    zoneId     = xi.zone.GHELSBA_OUTPOST,
    entranceId = xi.zone.CELENNIA_MEMORIAL_LIBRARY,
    timeLimitMinutes = 15,
    completionDelay  = 10,
    emptyCloseDelay  = 30,

    boardPos = { x = -106.0, y = -2.15, z = -106.0, rot = 190 },
    exitPos  = { x = -102.0, y = -2.15, z = -106.0, rot = 190 },

    -- Save the Children hut arena.
    mobPos = { x = -188.703, y = -10.048, z = 45.326, rot = 112 },
}

runtime.vars =
{
    nm      = 'UWI_NM',
    paid    = 'UWI_Paid',
    active  = 'UWI_Active',
    pending = 'UWI_Pending',
}

local nmById = {}
for _, nm in ipairs(catalog.nms) do
    nmById[nm.id] = nm
end

local function weeklyFeaturedId()
    return (math.floor(os.time() / 604800) % #catalog.nms) + 1
end

local function forEachPlayer(instance, fn)
    for _, player in ipairs(instance:getChars()) do
        if player:getObjType() == xi.objType.PC then
            fn(player)
        end
    end
end

local function clearState(player)
    player:setCharVar(runtime.vars.nm, 0)
    player:setCharVar(runtime.vars.paid, 0)
    player:setCharVar(runtime.vars.active, 0)
    player:setLocalVar(runtime.vars.pending, 0)
end

local function returnToBoard(player, message)
    clearState(player)
    if message then
        player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
    end

    local pos = runtime.config.exitPos
    player:setPos(pos.x, pos.y, pos.z, pos.rot, runtime.config.entranceId)
end

runtime.getNm = function(nmId)
    return nmById[nmId]
end

runtime.weeklyFeaturedId = weeklyFeaturedId

runtime.hasState = function(player)
    return
        player:getCharVar(runtime.vars.nm) ~= 0 or
        player:getCharVar(runtime.vars.paid) ~= 0 or
        player:getCharVar(runtime.vars.active) ~= 0 or
        player:getLocalVar(runtime.vars.pending) ~= 0
end

runtime.clearState = clearState

runtime.refundPlayer = function(player, message)
    local paid = player:getCharVar(runtime.vars.paid)
    clearState(player)

    if paid > 0 then
        player:addCurrency('unity_accolades', paid)
    end

    if message then
        player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
    end

    return paid
end

runtime.recoverAtBoard = function(player)
    if not player:getInstance() and runtime.hasState(player) then
        local wasActive = player:getCharVar(runtime.vars.active) ~= 0
        local paid = 0
        if wasActive then
            clearState(player)
        else
            paid = runtime.refundPlayer(player)
        end

        if paid > 0 then
            player:printToPlayer(
                string.format('[Unity Instance] Recovered a stale trial and refunded %d accolades.', paid),
                xi.msg.channel.SYSTEM_3)
        elseif wasActive then
            player:printToPlayer(
                '[Unity Instance] Cleared an abandoned trial. Entry costs are not refunded after zoning in.',
                xi.msg.channel.SYSTEM_3)
        end
    end
end

runtime.recoverOrphan = function(player)
    if not runtime.hasState(player) or player:getInstance() then
        return
    end

    player:timer(1500, function(p)
        if runtime.hasState(p) and not p:getInstance() then
            local wasActive = p:getCharVar(runtime.vars.active) ~= 0
            local paid = 0
            if wasActive then
                clearState(p)
            else
                paid = runtime.refundPlayer(p)
            end

            local suffix = paid > 0 and string.format(' %d accolades were refunded.', paid) or ''
            returnToBoard(p, '[Unity Instance] Your private trial no longer exists.' .. suffix)
        end
    end)
end

local function awardPlayer(player, nm)
    if
        player:getCharVar(runtime.vars.active) ~= runtime.config.instanceId or
        player:getCharVar(runtime.vars.nm) ~= nm.id
    then
        return
    end

    -- Clear paid/active state before granting anything so repeated core death
    -- dispatches cannot pay this character twice.
    clearState(player)

    local reward = catalog.rewards[nm.tier]
    if nm.id == weeklyFeaturedId() then
        reward = reward * 2
        player:printToPlayer(
            string.format('[Unity Instance] Weekly bonus! %s yields double accolades!', nm.label),
            xi.msg.channel.SYSTEM_3)
    end

    player:addCurrency('unity_accolades', reward)
    player:setCharVar('Unity_Accolades_Lifetime',
        (player:getCharVar('Unity_Accolades_Lifetime') or 0) + reward)

    local conqFlag = 'UW_Conq_' .. nm.id
    if (player:getCharVar(conqFlag) or 0) == 0 then
        player:setCharVar(conqFlag, 1)
        player:setCharVar('Unity_NMs_Conquered',
            (player:getCharVar('Unity_NMs_Conquered') or 0) + 1)
    end

    player:printToPlayer(
        string.format('[Unity Instance] %s defeated! +%d accolades (total: %d)',
            nm.label, reward, player:getCurrency('unity_accolades')),
        xi.msg.channel.SYSTEM_3)
end

local instanceObject = {}

instanceObject.onInstanceCreatedCallback = function(player, instance)
    if not instance then
        for _, member in ipairs(player:getParty()) do
            if member:getObjType() == xi.objType.PC then
                runtime.refundPlayer(member,
                    '[Unity Instance] The private trial failed to open; your accolades were refunded.')
            end
        end

        return
    end

    local nmId = player:getCharVar(runtime.vars.nm)
    local nm = nmById[nmId]
    if not nm then
        instance:setLocalVar('UWI_RefundOnFail', 1)
        instance:fail()
        return
    end

    instance:setLocalVar('UWI_NM', nmId)

    local registered = 0
    for _, member in ipairs(player:getParty()) do
        if
            member:getObjType() == xi.objType.PC and
            member:getZoneID() == runtime.config.entranceId and
            member:getLocalVar(runtime.vars.pending) == runtime.config.instanceId and
            member:getCharVar(runtime.vars.nm) == nmId
        then
            member:setInstance(instance)
            member:setCharVar(runtime.vars.active, runtime.config.instanceId)
            member:setLocalVar(runtime.vars.pending, 0)
            registered = registered + 1
        end
    end

    if registered == 0 then
        instance:setLocalVar('UWI_RefundOnFail', 1)
        instance:fail()
        return
    end

    for _, member in ipairs(player:getParty()) do
        if member:getInstance() == instance then
            member:setPos(0, 0, 0, 0, runtime.config.zoneId)
        end
    end
end

instanceObject.onInstanceCreated = function(instance)
    local nm = nmById[instance:getLocalVar('UWI_NM')]
    if not nm then
        instance:setLocalVar('UWI_RefundOnFail', 1)
        instance:fail()
        return
    end

    local pos = runtime.config.mobPos
    local mob = instance:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = nm.groupId,
        groupZoneId          = catalog.huntZoneId,
        name                 = nm.name,
        x                    = pos.x,
        y                    = pos.y,
        z                    = pos.z,
        rotation             = pos.rot,
        minLevel             = nm.minLv,
        maxLevel             = nm.maxLv,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob)
            if deadMob:getLocalVar('UWI_DeathHandled') ~= 0 then
                return
            end

            deadMob:setLocalVar('UWI_DeathHandled', 1)
            forEachPlayer(instance, function(player)
                awardPlayer(player, nm)
            end)

            local elapsed = instance:getLocalVar('UWI_ElapsedMs')
            instance:setLocalVar('UWI_KickAtMs', elapsed + runtime.config.completionDelay * 1000)
            instance:complete()
        end,
    })

    if not mob then
        instance:setLocalVar('UWI_RefundOnFail', 1)
        instance:fail()
        return
    end

    mob:setSpawn(pos.x, pos.y, pos.z, pos.rot)
    mob:spawn()
    mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
end

instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()
    local nm = instance and nmById[instance:getLocalVar('UWI_NM')]
    if nm then
        player:printToPlayer(
            string.format('[Unity Instance] Private trial: %s. Defeat it within %d minutes.',
                nm.label, runtime.config.timeLimitMinutes),
            xi.msg.channel.SYSTEM_3)
        player:printToPlayer(
            '[Unity Instance] Trusts may be summoned again after entering.',
            xi.msg.channel.SYSTEM_3)
    end
end

instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
    instance:setLocalVar('UWI_ElapsedMs', elapsed)

    if instance:completed() then
        if elapsed >= instance:getLocalVar('UWI_KickAtMs') then
            forEachPlayer(instance, function(player)
                returnToBoard(player, '[Unity Instance] Trial complete. Returning to the Concord.')
            end)
        end

        return
    end

    if elapsed >= instance:getTimeLimit() * 60 * 1000 then
        instance:fail()
        return
    end

    local playerCount = #instance:getChars()
    if playerCount == 0 then
        local emptySince = instance:getLocalVar('UWI_EmptySinceMs')
        if emptySince == 0 then
            instance:setLocalVar('UWI_EmptySinceMs', elapsed)
        elseif elapsed - emptySince >= runtime.config.emptyCloseDelay * 1000 then
            instance:fail()
        end
    else
        instance:setLocalVar('UWI_EmptySinceMs', 0)
    end
end

instanceObject.onInstanceComplete = function(instance)
    forEachPlayer(instance, function(player)
        player:printToPlayer(
            string.format('[Unity Instance] Victory! Returning in %d seconds.', runtime.config.completionDelay),
            xi.msg.channel.SYSTEM_3)
    end)
end

instanceObject.onInstanceFailure = function(instance)
    local refund = instance:getLocalVar('UWI_RefundOnFail') ~= 0
    forEachPlayer(instance, function(player)
        if refund then
            runtime.refundPlayer(player,
                '[Unity Instance] The trial could not spawn; your accolades were refunded.')
        end

        returnToBoard(player, refund and nil or '[Unity Instance] The private trial has closed.')
    end)
end

runtime.instanceObject = instanceObject

runtime.onInstanceZoneIn = function(player, instance)
    local entry = instance:getEntryPos()
    player:setPos(entry.x, entry.y, entry.z, entry.rot)
end

runtime.onInstanceLoadFailed = function()
    return runtime.config.entranceId
end

return runtime
