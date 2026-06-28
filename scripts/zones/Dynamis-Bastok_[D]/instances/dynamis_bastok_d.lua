-----------------------------------
-- Dynamis - Bastok [D]  --  Dynamis-Divergence instance (relaunch)
-- Instance 29500, zone 295. Delegates to the shared engine. Unlocks HANDS.
-----------------------------------
require("scripts/globals/dynamis_divergence")
-----------------------------------
local instanceObject = {}

local CONFIG =
{
    entrySlot = 'hands',
    exitZone  = xi.zone.BASTOK_MINES,
    entryPos  = { 116.482, 0.994, -72.121, 128 },
    exitPos   = { 112.000, 0.994, -72.000, 127 },
    wave1Mobs = { 17985537, 17985538, 17985539, 17985540 }, -- Quadav Squadron
    statues   = { 17985541, 17985542 },
    midBoss   = 17985543,                                   -- Mu'Sha Effigy
    wave2Mobs = { 17985544, 17985545, 17985546, 17985547 }, -- Quadav Regiment
    megaBoss  = 17985548,                                   -- Ka'Rho Fearsinger
    disjoined = 17985549,                                   -- Disjoined Galka (wave 3)
}

instanceObject.registryRequirements = function(player) return true end
instanceObject.entryRequirements    = function(player) return true end
instanceObject.onInstanceCreated         = function(instance) xi.divergence.onInstanceCreated(instance, CONFIG) end
instanceObject.onInstanceCreatedCallback = function(player, instance) if instance then xi.divergence.placePlayer(player, instance, CONFIG) end end
instanceObject.afterInstanceRegister     = function(player)
    xi.divergence.startCountdown(player)
    player:printToPlayer('[Divergence] Bastok [D] -- clear the waves, fell Ka\'Rho Fearsinger, then the Disjoined Galka!', xi.msg.channel.SYSTEM_3)
end
instanceObject.onInstanceTimeUpdate = function(instance, elapsed) xi.divergence.onInstanceTimeUpdate(instance, elapsed, CONFIG) end
instanceObject.onInstanceComplete   = function(instance) xi.divergence.onInstanceComplete(instance, CONFIG) end
instanceObject.onInstanceFailure    = function(instance) xi.divergence.onInstanceFailure(instance, CONFIG) end
instanceObject.onEventUpdate = function(player, csid, option, npc) end
instanceObject.onEventFinish = function(player, csid, option, npc) end

return instanceObject
