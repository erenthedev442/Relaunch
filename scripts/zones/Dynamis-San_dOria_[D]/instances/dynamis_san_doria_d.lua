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
    -- Corridor population pass (owner 2026-07-12): 48 W1 trash + 10 statues +
    -- 48 W2 trash + 3 bosses spread entry -> far corner. Every coord in the
    -- backing SQL comes from a validated retail Dynamis-SdO stock spawn point.
    -- Fresh mobid range (17982500+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17982500, 17982501, 17982502, 17982503, 17982504, 17982505,
        17982506, 17982507, 17982508, 17982509, 17982510, 17982511,
        17982512, 17982513, 17982514, 17982515, 17982516, 17982517,
        17982518, 17982519, 17982520, 17982521, 17982522, 17982523,
        17982524, 17982525, 17982526, 17982527, 17982528, 17982529,
        17982530, 17982531, 17982532, 17982533, 17982534, 17982535,
        17982536, 17982537, 17982538, 17982539, 17982540, 17982541,
        17982542, 17982543, 17982544, 17982545, 17982546, 17982547,
    },
    statues   = {
        17982548, 17982549, 17982550, 17982551, 17982552,
        17982553, 17982554, 17982555, 17982556, 17982557,
    },
    midBoss   = 17981770,                                   -- Overseer's Tombstone (relocated: corridor midpoint)
    wave2Mobs = {
        17982558, 17982559, 17982560, 17982561, 17982562, 17982563,
        17982564, 17982565, 17982566, 17982567, 17982568, 17982569,
        17982570, 17982571, 17982572, 17982573, 17982574, 17982575,
        17982576, 17982577, 17982578, 17982579, 17982580, 17982581,
        17982582, 17982583, 17982584, 17982585, 17982586, 17982587,
        17982588, 17982589, 17982590, 17982591, 17982592, 17982593,
        17982594, 17982595, 17982596, 17982597, 17982598, 17982599,
        17982600, 17982601, 17982602, 17982603, 17982604, 17982605,
    },
    megaBoss  = 17982112,                                   -- Halphas (relocated: far corner)
    disjoined = 17982238,                                   -- Disjoined Elvaan (wave 3, at far corner)
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
