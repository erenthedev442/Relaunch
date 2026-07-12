-----------------------------------
-- Dynamis - San d'Oria [D]  --  Dynamis-Divergence instance (relaunch)
-- Instance 29400, zone 294. Delegates every callback to the shared engine
-- (scripts/globals/dynamis_divergence.lua). Clearing it unlocks the FEET reforge slot.
-----------------------------------
require("scripts/globals/dynamis_divergence")
-----------------------------------
local instanceObject = {}

local CONFIG =
{
    entrySlot = 'feet',
    exitZone  = xi.zone.SOUTHERN_SAN_DORIA,
    entryPos  = { 161.838, -2.000, 161.673, 93 },
    exitPos   = { 161.000, -2.000, 161.000, 94 },
    -- Mobids sit on the stock indexes whose client-DAT names match each role
    -- (fixed mobs display DAT names by index; server-side names never show).
    wave1Mobs = { 17981448, 17981449, 17981451, 17981470,   -- Squadron Knight / 's Wyvern / Evoker
                  17981473, 17981471, 17981472, 17981480,
                  17981474, 17981475, 17981490, 17981481 },
    statues   = { 17981442, 17981447, 17981452, 17981457 }, -- Corporal Tombstone
    midBoss   = 17981770,                                   -- Overseer's Tombstone
    wave2Mobs = { 17981800, 17981801, 17981793, 17981807,   -- Regiment Knight / 's Wyvern / Evoker
                  17981856, 17981808, 17981794, 17981872,
                  17981857, 17981854, 17981897, 17981873 },
    megaBoss  = 17982112,                                   -- Halphas
    disjoined = 17982238,                                   -- Disjoined Elvaan (wave 3)
}

instanceObject.registryRequirements = function(player) return true end
instanceObject.entryRequirements    = function(player) return true end
instanceObject.onInstanceCreated         = function(instance) xi.divergence.onInstanceCreated(instance, CONFIG) end
instanceObject.onInstanceCreatedCallback = function(player, instance) if instance then xi.divergence.placePlayer(player, instance, CONFIG) end end
instanceObject.afterInstanceRegister     = function(player)
    xi.divergence.startCountdown(player)
    player:printToPlayer('[Divergence] San d\'Oria [D] -- clear the waves, fell Halphas, then the Disjoined Elvaan!', xi.msg.channel.SYSTEM_3)
end
instanceObject.onInstanceTimeUpdate = function(instance, elapsed) xi.divergence.onInstanceTimeUpdate(instance, elapsed, CONFIG) end
instanceObject.onInstanceComplete   = function(instance) xi.divergence.onInstanceComplete(instance, CONFIG) end
instanceObject.onInstanceFailure    = function(instance) xi.divergence.onInstanceFailure(instance, CONFIG) end
instanceObject.onEventUpdate = function(player, csid, option, npc) end
instanceObject.onEventFinish = function(player, csid, option, npc) end

return instanceObject
