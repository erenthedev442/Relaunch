-----------------------------------
-- Zone: Ordelles Caves (193)
-----------------------------------
---@type TZone
local zoneObject = {}
local dungeonZone = require('modules/custom/lua/dungeon_zone')

zoneObject.onInitialize = function(zone)
    xi.treasure.initZone(zone)
end

zoneObject.onZoneIn = function(player, prevZone)
    local cs = -1

    if
        player:getXPos() == 0 and
        player:getYPos() == 0 and
        player:getZPos() == 0
    then
        player:setPos(-76.839, -1.696, 659.969, 122)
    end

    dungeonZone.recoverOrphan(player)
    return cs
end

zoneObject.onInstanceZoneIn = dungeonZone.onInstanceZoneIn
zoneObject.onInstanceLoadFailed = dungeonZone.onInstanceLoadFailed

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
