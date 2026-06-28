-----------------------------------
-- Ambuscade instance handler
-- Instance ID : 30000   (!instance 30000)
-- Zone        : 287 (Maquette_Abdhaljs-Legion_B)
-- Entry pos   : (137, 12.5, -137, rot 32)
-- Exit zone   : 249 (Mhaura)
--
-- Difficulty is stored in the player's Ambuscade_Difficulty charVar before
-- createInstance fires, then written to instance:setProgress() in the
-- callback so it survives for the lifetime of the instance.
-- Mob HP is scaled in onInstanceProgressUpdate (fires immediately after setProgress).
-----------------------------------
local ID = zones[xi.zone.MAQUETTE_ABDHALJS_LEGION_B]
-----------------------------------
local instanceObject = {}

-- Matches the HP_SCALE table in scripts/globals/ambuscade.lua.
-- Applied as a multiplier to the mob's base HP from the DB.
local HP_SCALE =
{
    [1]  = 5.0,  [2]  = 3.5,  [3]  = 2.5,  [4]  = 1.8,  [5]  = 1.0,  -- Intense VD→VE
    [6]  = 4.0,  [7]  = 2.8,  [8]  = 2.0,  [9]  = 1.5,  [10] = 1.0,  -- Regular VD→VE
}

-- Spawn all mobs defined for this zone's Ambuscade instance.
instanceObject.onInstanceCreated = function(instance)
    for _, mobId in pairs(ID.mob) do
        SpawnMob(mobId, instance)
    end
end

-- Transfer the chosen difficulty from the player's charVar to the instance,
-- then place the player inside.  setProgress triggers onInstanceProgressUpdate,
-- which scales mob HP before the player can engage.
instanceObject.onInstanceCreatedCallback = function(player, instance)
    if not instance then return end
    local diff = player:getCharVar('Ambuscade_Difficulty')
    if diff < 1 or diff > 10 then diff = 10 end  -- fallback: Regular VE (minimum rewards)
    instance:setProgress(diff)
    player:setInstance(instance)
    player:setPos(137, 12.5, -137, 32, instance:getZone():getID())
end

instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()
    if instance then
        player:countdown(instance:getTimeLimit() * 60)
    end
end

-- Scale mob HP to match the selected difficulty.
-- Fires right after onInstanceCreatedCallback calls instance:setProgress().
-- All mobs are already spawned (from onInstanceCreated) so getMobs() works here.
instanceObject.onInstanceProgressUpdate = function(instance, progress)
    local mult = HP_SCALE[progress] or 1.0
    if mult == 1.0 then return end  -- no scaling needed for VE difficulties
    for _, mob in pairs(instance:getMobs()) do
        if mob:isAlive() then
            local newHP = math.max(1, math.floor(mob:getMaxHP() * mult))
            mob:setMaxHP(newHP)
            mob:setHP(newHP)
        end
    end
end

-- Polling fallback: detect when all mobs are dead and complete the instance.
-- The mob script's onMobDeath is the preferred trigger, but this catches any
-- edge cases where that callback doesn't fire (e.g., mob despawn vs. kill).
instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
    local mobs   = instance:getMobs()
    local anyMob = false
    for _, mob in pairs(mobs) do
        anyMob = true
        if mob:isAlive() then return end  -- still fighting
    end
    if anyMob then
        instance:complete()
    end
end

instanceObject.onInstanceFailure = function(instance)
    xi.ambuscade.onInstanceFailure(instance)
end

instanceObject.onInstanceComplete = function(instance)
    xi.ambuscade.onInstanceComplete(instance)
end

instanceObject.onEventUpdate = function(player, csid, option, npc)
end

-- csid 10001 is the generic instance-exit event; warp the player back to Mhaura.
instanceObject.onEventFinish = function(player, csid, option, npc)
    if csid == 10001 then
        player:setPos(-34.2, -16, 58, 32, 249)
    end
end

return instanceObject
