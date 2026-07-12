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
    -- Mobids sit on the stock indexes whose client-DAT names match each role
    -- (fixed mobs display DAT names by index; server-side names never show).
    wave1Mobs = { 17985540, 17985543, 17985546, 17985557,   -- Squadron Weaponmaster / 's Avatar / Magician
                  17985583, 17985564, 17985561, 17985611,
                  17985574, 17985586, 17985620, 17985596 },
    statues   = { 17985539, 17985544, 17985548, 17985554 }, -- Lithicthrower Image
    midBoss   = 17985538,                                   -- Mu'Sha Effigy
    wave2Mobs = { 17985897, 17985900, 17985902, 17985916,   -- Regiment Weaponmaster / 's Avatar / Magician
                  17985926, 17985928, 17985922, 17985933,
                  17985949, 17985944, 17985938, 17985971 },
    megaBoss  = 17985895,                                   -- Ka'Rho Fearsinger
    disjoined = 17986326,                                   -- Disjoined Galka (wave 3)
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
