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
    -- Fresh mobid range (17994700+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17994700, 17994701, 17994702, 17994703, 17994704, 17994705,
        17994706, 17994707, 17994708, 17994709, 17994710, 17994711,
        17994712, 17994713, 17994714, 17994715, 17994716, 17994717,
        17994718, 17994719, 17994720, 17994721, 17994722, 17994723,
        17994724, 17994725, 17994726, 17994727, 17994728, 17994729,
        17994730, 17994731, 17994732, 17994733, 17994734, 17994735,
        17994736, 17994737, 17994738, 17994739, 17994740, 17994741,
        17994742, 17994743, 17994744, 17994745, 17994746, 17994747,
    },
    statues   = {
        17994748, 17994749, 17994750, 17994751, 17994752,
        17994753, 17994754, 17994755, 17994756, 17994757,
    },
    midBoss   = 17993730,                                   -- Impish Golem (relocated: corridor midpoint)
    wave2Mobs = {
        17994758, 17994759, 17994760, 17994761, 17994762, 17994763,
        17994764, 17994765, 17994766, 17994767, 17994768, 17994769,
        17994770, 17994771, 17994772, 17994773, 17994774, 17994775,
        17994776, 17994777, 17994778, 17994779, 17994780, 17994781,
        17994782, 17994783, 17994784, 17994785, 17994786, 17994787,
        17994788, 17994789, 17994790, 17994791, 17994792, 17994793,
        17994794, 17994795, 17994796, 17994797, 17994798, 17994799,
        17994800, 17994801, 17994802, 17994803, 17994804, 17994805,
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
