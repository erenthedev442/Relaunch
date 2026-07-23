-----------------------------------
-- Dynamis - Windurst [D]  --  Dynamis-Divergence instance (relaunch)
-- Instance 29600, zone 296. Delegates to the shared engine. Unlocks HEAD.
-----------------------------------
require("scripts/globals/dynamis_divergence")
-----------------------------------
local instanceObject = {}

local CONFIG =
{
    entrySlot = 'head',
    exitZone  = xi.zone.WINDURST_WALLS,
    entryPos  = { -221.988, 1.000, -120.184, 0 },
    exitPos   = { -217.000, 1.000, -119.000, 94 },
    -- T3 solo/trust pacing pass: 20 W1 trash + 6 statues + 20 W2 trash +
    -- 3 bosses spread entry -> far corner. Every coord in the
    -- backing SQL comes from a validated retail Dynamis-Windurst stock spawn point.
    -- Fresh mobid range (17990500+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17990500, 17990502, 17990505, 17990507, 17990510,
        17990512, 17990515, 17990517, 17990520, 17990522,
        17990525, 17990527, 17990530, 17990532, 17990535,
        17990537, 17990540, 17990542, 17990545, 17990547,
    },
    statues   = {
        17990548, 17990550, 17990552, 17990553, 17990555, 17990557,
    },
    midBoss   = 17989634,                                   -- Evincing Idol (relocated: corridor midpoint)
    wave2Mobs = {
        17990558, 17990560, 17990563, 17990565, 17990568,
        17990570, 17990573, 17990575, 17990578, 17990580,
        17990583, 17990585, 17990588, 17990590, 17990593,
        17990595, 17990598, 17990600, 17990603, 17990605,
    },
    megaBoss  = 17990606,                                   -- Fii Pexu the Eternal (fresh registered slot, far corner)
    disjoined = 17990425,                                   -- Disjoined Tarutaru (wave 3, at far corner)
}
instanceObject.config = CONFIG

instanceObject.registryRequirements = function(player) return true end
instanceObject.entryRequirements    = function(player) return true end
instanceObject.onInstanceCreated         = function(instance) xi.divergence.onInstanceCreated(instance, CONFIG) end
instanceObject.onInstanceCreatedCallback = function(player, instance) if instance then xi.divergence.placePlayer(player, instance, CONFIG) end end
instanceObject.afterInstanceRegister     = function(player)
    xi.divergence.startCountdown(player)
    player:printToPlayer('[Divergence] Windurst [D] -- clear the waves, fell Fii Pexu the Eternal, then the Disjoined Tarutaru!', xi.msg.channel.SYSTEM_3)
end
instanceObject.onInstanceTimeUpdate = function(instance, elapsed) xi.divergence.onInstanceTimeUpdate(instance, elapsed, CONFIG) end
instanceObject.onInstanceComplete   = function(instance) xi.divergence.onInstanceComplete(instance, CONFIG) end
instanceObject.onInstanceFailure    = function(instance) xi.divergence.onInstanceFailure(instance, CONFIG) end
instanceObject.onEventUpdate = function(player, csid, option, npc) end
instanceObject.onEventFinish = function(player, csid, option, npc) end

return instanceObject
