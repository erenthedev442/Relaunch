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
    -- Fresh mobid range (17982300+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17982300, 17982301, 17982302, 17982303, 17982304, 17982305,
        17982306, 17982307, 17982308, 17982309, 17982310, 17982311,
        17982312, 17982313, 17982314, 17982315, 17982316, 17982317,
        17982318, 17982319, 17982320, 17982321, 17982322, 17982323,
        17982324, 17982325, 17982326, 17982327, 17982328, 17982329,
        17982330, 17982331, 17982332, 17982333, 17982334, 17982335,
        17982336, 17982337, 17982338, 17982339, 17982340, 17982341,
        17982342, 17982343, 17982344, 17982345, 17982346, 17982347,
    },
    statues   = {
        17982348, 17982349, 17982350, 17982351, 17982352,
        17982353, 17982354, 17982355, 17982356, 17982357,
    },
    midBoss   = 17981770,                                   -- Overseer's Tombstone (relocated: corridor midpoint)
    wave2Mobs = {
        17982358, 17982359, 17982360, 17982361, 17982362, 17982363,
        17982364, 17982365, 17982366, 17982367, 17982368, 17982369,
        17982370, 17982371, 17982372, 17982373, 17982374, 17982375,
        17982376, 17982377, 17982378, 17982379, 17982380, 17982381,
        17982382, 17982383, 17982384, 17982385, 17982386, 17982387,
        17982388, 17982389, 17982390, 17982391, 17982392, 17982393,
        17982394, 17982395, 17982396, 17982397, 17982398, 17982399,
        17982400, 17982401, 17982402, 17982403, 17982404, 17982405,
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
