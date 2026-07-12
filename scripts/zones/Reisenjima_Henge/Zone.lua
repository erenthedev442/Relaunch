-----------------------------------
-- Zone: Reisenjima_Henge (292)
--
-- The public copy hosts hub NPCs; private instance copies host Omen
-- (modules/custom/lua/omen_instance.lua, loaded via instances/omen.lua).
-----------------------------------
local omenCatalog = require('modules/custom/lua/omen_catalog')

---@type TZone
local zoneObject = {}

zoneObject.onInitialize = function(zone)
end

zoneObject.onInstanceZoneIn = function(player, instance)
    player:setPos(
        omenCatalog.arena.entryPos.x,
        omenCatalog.arena.entryPos.y,
        omenCatalog.arena.entryPos.z,
        omenCatalog.arena.entryPos.rotation)
end

zoneObject.onInstanceLoadFailed = function()
    -- Send strays back to Reisenjima beside the Omen ingress.
    return omenCatalog.entry.zoneId
end

zoneObject.onZoneIn = function(player, prevZone)
    local cs = -1
    --[[
    if
        player:getXPos() == 0 and
        player:getYPos() == 0 and
        player:getZPos() == 0
    then
        player:setPos(?, ?, ?, ?)
    end
    ]]
    return cs
end

zoneObject.onConquestUpdate = function(zone, updatetype, influence, owner, ranking, isConquestAlliance)
end

zoneObject.onTriggerAreaEnter = function(player, triggerArea)
end

zoneObject.onEventUpdate = function(player, csid, option, npc)
end

zoneObject.onEventFinish = function(player, csid, option, npc)
end

return zoneObject
