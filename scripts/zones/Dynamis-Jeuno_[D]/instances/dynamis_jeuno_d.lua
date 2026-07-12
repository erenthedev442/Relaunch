-----------------------------------
-- Dynamis - Jeuno [D]  --  Dynamis-Divergence instance (relaunch)
-- Instance 29700, zone 297. Delegates to the shared engine. Unlocks LEGS.
-----------------------------------
require("scripts/globals/dynamis_divergence")
-----------------------------------
local instanceObject = {}

local CONFIG =
{
    entrySlot = 'legs',
    exitZone  = xi.zone.RULUDE_GARDENS,
    entryPos  = { 48.930, 10.002, -71.032, 195 },
    exitPos   = { 48.930, 10.002, -71.032, 195 },
    wave1Mobs = { 17993729, 17993730, 17993731, 17993732,   -- Goblin Squadron
                  17993742, 17993743, 17993744, 17993745,
                  17993746, 17993747, 17993748, 17993749 },
    statues   = { 17993733, 17993734, 17993750, 17993751 },
    midBoss   = 17993735,                                   -- Impish Golem
    wave2Mobs = { 17993736, 17993737, 17993738, 17993739,   -- Goblin Regiment
                  17993752, 17993753, 17993754, 17993755,
                  17993756, 17993757, 17993758, 17993759 },
    megaBoss  = 17993740,                                   -- Obstatrix
    disjoined = 17993741,                                   -- Disjoined Mithra (wave 3)
}

instanceObject.registryRequirements = function(player) return true end
instanceObject.entryRequirements    = function(player) return true end
instanceObject.onInstanceCreated         = function(instance) xi.divergence.onInstanceCreated(instance, CONFIG) end
instanceObject.onInstanceCreatedCallback = function(player, instance) if instance then xi.divergence.placePlayer(player, instance, CONFIG) end end
instanceObject.afterInstanceRegister     = function(player)
    xi.divergence.startCountdown(player)
    player:printToPlayer('[Divergence] Jeuno [D] -- clear the waves, fell Obstatrix, then the Disjoined Mithra!', xi.msg.channel.SYSTEM_3)
end
instanceObject.onInstanceTimeUpdate = function(instance, elapsed) xi.divergence.onInstanceTimeUpdate(instance, elapsed, CONFIG) end
instanceObject.onInstanceComplete   = function(instance) xi.divergence.onInstanceComplete(instance, CONFIG) end
instanceObject.onInstanceFailure    = function(instance) xi.divergence.onInstanceFailure(instance, CONFIG) end
instanceObject.onEventUpdate = function(player, csid, option, npc) end
instanceObject.onEventFinish = function(player, csid, option, npc) end

return instanceObject
