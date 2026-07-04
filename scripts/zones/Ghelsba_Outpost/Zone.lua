-----------------------------------
-- Zone: Ghelsba_Outpost (140)
-----------------------------------
---@type TZone
local zoneObject = {}
local unityInstance = require('modules/custom/lua/unity_wanted_instance_runtime')

zoneObject.onInitialize = function(zone)
    xi.helm.initZone(zone, xi.helmType.LOGGING)
end

zoneObject.onZoneIn = function(player, prevZone)
    local cs = -1

    if
        player:getXPos() == 0 and
        player:getYPos() == 0 and
        player:getZPos() == 0
    then
        player:setPos(99, 0, -34, 191)
    end

    unityInstance.recoverOrphan(player)

    return cs
end

zoneObject.onInstanceZoneIn = unityInstance.onInstanceZoneIn
zoneObject.onInstanceLoadFailed = unityInstance.onInstanceLoadFailed

zoneObject.onConquestUpdate = function(zone, updatetype, influence, owner, ranking, isConquestAlliance)
    xi.conquest.onConquestUpdate(zone, updatetype, influence, owner, ranking, isConquestAlliance)
end

zoneObject.onTriggerAreaEnter = function(player, triggerArea)
end

zoneObject.onEventUpdate = function(player, csid, option, npc)
end

zoneObject.onEventFinish = function(player, csid, option, npc)
end

return zoneObject
