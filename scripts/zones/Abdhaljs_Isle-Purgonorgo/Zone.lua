-----------------------------------
-- Zone: Abdhaljs_Isle-Purgonorgo
-----------------------------------
---@type TZone
local zoneObject = {}

zoneObject.onInitialize = function(zone)
      -- Invisible wall blocking the tunnel mouth near H-8.
    zone:registerCuboidTriggerArea(1, 499.0, -5.0, 462.0, 512.0, 2.0, 471.0) -- back right of !hub
        -- Invisible wall blocking the tunnel mouth near H-8.
    zone:registerCuboidTriggerArea(2, 609.38, -3.0, 617.94, 461.65, 2.0, 469.12) -- back left of hub
end

zoneObject.onZoneIn = function(player, prevZone)
    local cs = -1
    player:addKeyItem(xi.ki.MAP_OF_ABDH_ISLE_PURGONORGO)

    if
        player:getXPos() == 0 and
        player:getYPos() == 0 and
        player:getZPos() == 0
    then
        player:setPos(521.600, -3.000, 563.000, 64)
    end

    return cs
end

zoneObject.onTriggerAreaEnter = function(player, triggerArea)
	if triggerArea:getTriggerAreaID() == 1 then
        player:setPos(514.0, -2.5, 459.0, 221)
        player:printToPlayer('This area is off limits.')
	elseif triggerArea:getTriggerAreaID() == 2 then
        player:setPos(608.07, -2.74, 470.0, 156)
        player:printToPlayer('This area is off limits.')
    end
end

zoneObject.onEventUpdate = function(player, csid, option, npc)
end

zoneObject.onEventFinish = function(player, csid, option, npc)
end

return zoneObject
