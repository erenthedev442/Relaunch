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
    -- Corridor population pass (owner 2026-07-12): 48 W1 trash + 10 statues +
    -- 48 W2 trash + 3 bosses spread entry -> far corner. Every coord in the
    -- backing SQL comes from a validated retail Dynamis-Bastok stock spawn point.
    -- Fresh mobid range (17986500+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17986500, 17986501, 17986502, 17986503, 17986504, 17986505,
        17986506, 17986507, 17986508, 17986509, 17986510, 17986511,
        17986512, 17986513, 17986514, 17986515, 17986516, 17986517,
        17986518, 17986519, 17986520, 17986521, 17986522, 17986523,
        17986524, 17986525, 17986526, 17986527, 17986528, 17986529,
        17986530, 17986531, 17986532, 17986533, 17986534, 17986535,
        17986536, 17986537, 17986538, 17986539, 17986540, 17986541,
        17986542, 17986543, 17986544, 17986545, 17986546, 17986547,
    },
    statues   = {
        17986548, 17986549, 17986550, 17986551, 17986552,
        17986553, 17986554, 17986555, 17986556, 17986557,
    },
    midBoss   = 17985538,                                   -- Mu'Sha Effigy (relocated: corridor midpoint)
    wave2Mobs = {
        17986558, 17986559, 17986560, 17986561, 17986562, 17986563,
        17986564, 17986565, 17986566, 17986567, 17986568, 17986569,
        17986570, 17986571, 17986572, 17986573, 17986574, 17986575,
        17986576, 17986577, 17986578, 17986579, 17986580, 17986581,
        17986582, 17986583, 17986584, 17986585, 17986586, 17986587,
        17986588, 17986589, 17986590, 17986591, 17986592, 17986593,
        17986594, 17986595, 17986596, 17986597, 17986598, 17986599,
        17986600, 17986601, 17986602, 17986603, 17986604, 17986605,
    },
    megaBoss  = 17985895,                                   -- Ka'Rho Fearsinger (relocated: far corner)
    disjoined = 17986326,                                   -- Disjoined Galka (wave 3, at far corner)
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
