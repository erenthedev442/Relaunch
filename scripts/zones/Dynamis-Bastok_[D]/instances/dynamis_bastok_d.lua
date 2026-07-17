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
    -- T3 solo/trust pacing pass: 20 W1 trash + 6 statues + 20 W2 trash +
    -- 3 bosses spread entry -> far corner. Every coord in the
    -- backing SQL comes from a validated retail Dynamis-Bastok stock spawn point.
    -- Fresh mobid range (17986400+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17986400, 17986402, 17986405, 17986407, 17986410,
        17986412, 17986415, 17986417, 17986420, 17986422,
        17986425, 17986427, 17986430, 17986432, 17986435,
        17986437, 17986440, 17986442, 17986445, 17986447,
    },
    statues   = {
        17986448, 17986450, 17986452, 17986453, 17986455, 17986457,
    },
    midBoss   = 17985538,                                   -- Mu'Sha Effigy (relocated: corridor midpoint)
    wave2Mobs = {
        17986458, 17986460, 17986463, 17986465, 17986468,
        17986470, 17986473, 17986475, 17986478, 17986480,
        17986483, 17986485, 17986488, 17986490, 17986493,
        17986495, 17986498, 17986500, 17986503, 17986505,
    },
    megaBoss  = 17985895,                                   -- Ka'Rho Fearsinger (relocated: far corner)
    disjoined = 17986326,                                   -- Disjoined Galka (wave 3, at far corner)
}
instanceObject.config = CONFIG

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
