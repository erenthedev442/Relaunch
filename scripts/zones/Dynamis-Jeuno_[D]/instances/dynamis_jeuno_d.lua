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
    -- Mobids sit on the stock indexes whose client-DAT names match each role
    -- (fixed mobs display DAT names by index; server-side names never show).
    wave1Mobs = { 17993732, 17993741, 17993736, 17993748,   -- Squadron Berserker / 's Wyvern / Arcanomancer
                  17993778, 17993758, 17993753, 17993787,
                  17993783, 17993768, 17993806, 17993785 },
    statues   = { 17993731, 17993737, 17993744, 17993749 }, -- Impish Statue
    midBoss   = 17993730,                                   -- Impish Golem
    wave2Mobs = { 17994070, 17994079, 17994074, 17994083,   -- Regiment Berserker / 's Wyvern / Arcanomancer
                  17994091, 17994120, 17994087, 17994100,
                  17994127, 17994095, 17994108, 17994155 },
    megaBoss  = 17994068,                                   -- Obstatrix
    disjoined = 17994487,                                   -- Disjoined Mithra (wave 3)
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
