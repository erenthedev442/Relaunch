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
    -- Corridor population pass (owner 2026-07-12): 48 W1 trash + 10 statues +
    -- 48 W2 trash + 3 bosses spread entry -> far corner. Every coord in the
    -- backing SQL comes from a validated retail Dynamis-Jeuno stock spawn point.
    -- Fresh mobid range (17994600+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17994600, 17994601, 17994602, 17994603, 17994604, 17994605,
        17994606, 17994607, 17994608, 17994609, 17994610, 17994611,
        17994612, 17994613, 17994614, 17994615, 17994616, 17994617,
        17994618, 17994619, 17994620, 17994621, 17994622, 17994623,
        17994624, 17994625, 17994626, 17994627, 17994628, 17994629,
        17994630, 17994631, 17994632, 17994633, 17994634, 17994635,
        17994636, 17994637, 17994638, 17994639, 17994640, 17994641,
        17994642, 17994643, 17994644, 17994645, 17994646, 17994647,
    },
    statues   = {
        17994648, 17994649, 17994650, 17994651, 17994652,
        17994653, 17994654, 17994655, 17994656, 17994657,
    },
    midBoss   = 17993730,                                   -- Impish Golem (relocated: corridor midpoint)
    wave2Mobs = {
        17994658, 17994659, 17994660, 17994661, 17994662, 17994663,
        17994664, 17994665, 17994666, 17994667, 17994668, 17994669,
        17994670, 17994671, 17994672, 17994673, 17994674, 17994675,
        17994676, 17994677, 17994678, 17994679, 17994680, 17994681,
        17994682, 17994683, 17994684, 17994685, 17994686, 17994687,
        17994688, 17994689, 17994690, 17994691, 17994692, 17994693,
        17994694, 17994695, 17994696, 17994697, 17994698, 17994699,
        17994700, 17994701, 17994702, 17994703, 17994704, 17994705,
    },
    megaBoss  = 17994068,                                   -- Obstatrix (relocated: far corner)
    disjoined = 17994487,                                   -- Disjoined Mithra (wave 3, at far corner)
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
