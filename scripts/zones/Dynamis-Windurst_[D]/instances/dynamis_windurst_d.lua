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
    -- Mobids sit on the stock indexes whose client-DAT names match each role
    -- (fixed mobs display DAT names by index; server-side names never show).
    wave1Mobs = { 17989636, 17989645, 17989640, 17989665,   -- Squadron Hoplite / 's Wyvern / Magian
                  17989671, 17989668, 17989661, 17989692,
                  17989680, 17989673, 17989695, 17989689 },
    statues   = { 17989635, 17989641, 17989646, 17989651 }, -- Incarnation Icon
    midBoss   = 17989634,                                   -- Evincing Idol
    wave2Mobs = { 17989983, 17989994, 17989988, 17990001,   -- Regiment Hoplite / 's Wyvern / Magian
                  17990010, 17990015, 17990007, 17990021,
                  17990033, 17990017, 17990037, 17990057 },
    megaBoss  = 17989981,                                   -- Fii Pexu the Eternal
    disjoined = 17990425,                                   -- Disjoined Tarutaru (wave 3)
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
