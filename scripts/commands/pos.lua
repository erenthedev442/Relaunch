-- func: pos
-- desc: Prints the caller's current position. Player movement is intentionally
--       unavailable through this command.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local terrainNames =
{
    [xi.terrain.OBJECT]        = 'Object',
    [xi.terrain.PATH]          = 'Path',
    [xi.terrain.GRASS]         = 'Grass',
    [xi.terrain.SAND]          = 'Sand',
    [xi.terrain.SNOW]          = 'Snow',
    [xi.terrain.STONE]         = 'Stone',
    [xi.terrain.METAL]         = 'Metal',
    [xi.terrain.WOOD]          = 'Wood',
    [xi.terrain.SHALLOW_WATER] = 'Shallow Water',
    [xi.terrain.DEEP_WATER]    = 'Deep Water',
    [xi.terrain.UNKNOWN]       = 'Unknown',
    [xi.terrain.NONE]          = 'None',
}

local function printPosition(player)
    local zone        = player:getZone()
    local pos         = player:getPos()
    local terrainType = zone:getTerrainType(pos)
    local terrainName = terrainNames[terrainType] or string.format('Unknown (%d)', terrainType)

    player:printToPlayer(string.format('%s: X %.4f  Y %.4f  Z %.4f  Rot %i  Zone %i  Floor %i  Terrain: %s',
        player:getName(),
        player:getXPos(),
        player:getYPos(),
        player:getZPos(),
        player:getRotPos(),
        player:getZoneID(),
        zone:getFloorId(pos),
        terrainName
    ), xi.msg.channel.SYSTEM_3)
end

commandObj.onTrigger = function(player)
    printPosition(player)
end

return commandObj
