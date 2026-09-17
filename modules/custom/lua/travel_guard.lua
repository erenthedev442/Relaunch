-----------------------------------
-- Shared travel refusal for player warp commands.
-- Jail stays a separate check so !unstick can recover a jailed character
-- without also inheriting the first-login stay-put lock.
-----------------------------------
local jail = require('modules/custom/lua/mordion_jail')

local guard = {}

-- Paid / private instance zones. GetZone type-mask is the live check; this
-- table is the test fallback and a belt for the four Dynamis [D] rifts plus
-- Ambuscade that were leaking empty copies via !waypoint.
local INSTANCED_ZONE_FALLBACK =
{
    [xi.zone.DYNAMIS_SAN_DORIA_D]          = true,
    [xi.zone.DYNAMIS_BASTOK_D]             = true,
    [xi.zone.DYNAMIS_WINDURST_D]           = true,
    [xi.zone.DYNAMIS_JEUNO_D]              = true,
    [xi.zone.MAQUETTE_ABDHALJS_LEGION_B]   = true,
    [xi.zone.NYZUL_ISLE]                   = true,
    [xi.zone.REISENJIMA_HENGE]             = true,
}

function guard.isInstancedZoneId(zoneId)
    if not zoneId then
        return false
    end
    local ok, zone = pcall(function()
        return GetZone(zoneId)
    end)
    if ok and zone and zone.getTypeMask then
        return bit.band(zone:getTypeMask(), xi.zoneType.INSTANCED) ~= 0
    end
    return INSTANCED_ZONE_FALLBACK[zoneId] == true
end

-- Block saving a waypoint while standing in an instance. Same-zone
-- reposition while already inside a live copy is still allowed on warp.
-- GMs keep access for debugging.
function guard.refuseInstanceSave(player)
    local zoneId = player.getZoneID and player:getZoneID()
    if not guard.isInstancedZoneId(zoneId) then
        return false
    end
    if player.getGMLevel and player:getGMLevel() > 0 then
        return false
    end

    player:printToPlayer(
        '[Waypoint] Instance zones cannot be saved or warped into. Use the entry NPC.',
        xi.msg.channel.SYSTEM_3)
    return true
end

function guard.refuseInstanceTravel(player, destZoneId)
    destZoneId = destZoneId or (player.getZoneID and player:getZoneID())
    if not guard.isInstancedZoneId(destZoneId) then
        return false
    end
    if player.getGMLevel and player:getGMLevel() > 0 then
        return false
    end

    local currentZone = player.getZoneID and player:getZoneID()
    local inst        = player.getInstance and player:getInstance() or nil
    if inst and currentZone == destZoneId then
        return false
    end

    player:printToPlayer(
        '[Waypoint] Instance zones cannot be saved or warped into. Use the entry NPC.',
        xi.msg.channel.SYSTEM_3)
    return true
end

function guard.refuseTravel(player)
    if jail.refuseTravel(player) then
        return true
    end

    local upgrade = xi.characterUpgrade
    if upgrade and upgrade.refuseTravel and upgrade.refuseTravel(player) then
        return true
    end

    return false
end

return guard
