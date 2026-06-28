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
    wave1Mobs = { 17989633, 17989634, 17989635, 17989636 }, -- Yagudo Squadron
    statues   = { 17989637, 17989638 },
    midBoss   = 17989639,                                   -- Evincing Idol
    wave2Mobs = { 17989640, 17989641, 17989642, 17989643 }, -- Yagudo Regiment
    megaBoss  = 17989644,                                   -- Fii Pexu the Eternal
    disjoined = 17989645,                                   -- Disjoined Tarutaru (wave 3)
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
