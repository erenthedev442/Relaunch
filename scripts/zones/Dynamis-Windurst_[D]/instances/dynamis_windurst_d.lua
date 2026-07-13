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
    -- Corridor population pass (owner 2026-07-12): 48 W1 trash + 10 statues +
    -- 48 W2 trash + 3 bosses spread entry -> far corner. Every coord in the
    -- backing SQL comes from a validated retail Dynamis-Windurst stock spawn point.
    -- Fresh mobid range (17990500+) so the old 12+12 roster drops out cleanly.
    wave1Mobs = {
        17990500, 17990501, 17990502, 17990503, 17990504, 17990505,
        17990506, 17990507, 17990508, 17990509, 17990510, 17990511,
        17990512, 17990513, 17990514, 17990515, 17990516, 17990517,
        17990518, 17990519, 17990520, 17990521, 17990522, 17990523,
        17990524, 17990525, 17990526, 17990527, 17990528, 17990529,
        17990530, 17990531, 17990532, 17990533, 17990534, 17990535,
        17990536, 17990537, 17990538, 17990539, 17990540, 17990541,
        17990542, 17990543, 17990544, 17990545, 17990546, 17990547,
    },
    statues   = {
        17990548, 17990549, 17990550, 17990551, 17990552,
        17990553, 17990554, 17990555, 17990556, 17990557,
    },
    midBoss   = 17989634,                                   -- Evincing Idol (relocated: corridor midpoint)
    wave2Mobs = {
        17990558, 17990559, 17990560, 17990561, 17990562, 17990563,
        17990564, 17990565, 17990566, 17990567, 17990568, 17990569,
        17990570, 17990571, 17990572, 17990573, 17990574, 17990575,
        17990576, 17990577, 17990578, 17990579, 17990580, 17990581,
        17990582, 17990583, 17990584, 17990585, 17990586, 17990587,
        17990588, 17990589, 17990590, 17990591, 17990592, 17990593,
        17990594, 17990595, 17990596, 17990597, 17990598, 17990599,
        17990600, 17990601, 17990602, 17990603, 17990604, 17990605,
    },
    megaBoss  = 17989981,                                   -- Fii Pexu the Eternal (relocated: far corner)
    disjoined = 17990425,                                   -- Disjoined Tarutaru (wave 3, at far corner)
}

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
