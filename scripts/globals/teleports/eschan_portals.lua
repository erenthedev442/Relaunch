-----------------------------------
-- Escha/Reisenjima Portals Global
-----------------------------------
require('scripts/globals/npc_util')
require('scripts/globals/teleports')
-----------------------------------
xi = xi or {}
xi.escha = xi.escha or {}
xi.escha.portals = xi.escha.portals or {}

local portalOffsets =
{
--  [ZoneId] = { First Portal, Last Portal },
    [xi.zone.ESCHA_ZITAH] = {  0,  7 },
    [xi.zone.ESCHA_RUAUN] = {  8, 22 },
    [xi.zone.REISENJIMA ] = { 23, 31 },
}

local portalData =
{
    [xi.zone.ESCHA_ZITAH] =
    {
        ['Eschan_Portal_#1'] = 0,
        ['Eschan_Portal_#2'] = 1,
        ['Eschan_Portal_#3'] = 2,
        ['Eschan_Portal_#4'] = 3,
        ['Eschan_Portal_#5'] = 4,
        ['Eschan_Portal_#6'] = 5,
        ['Eschan_Portal_#7'] = 6,
        ['Eschan_Portal_#8'] = 7,
    },
    [xi.zone.ESCHA_RUAUN] =
    {
        ['Eschan_Portal_#1' ] =  8,
        ['Eschan_Portal_#2' ] =  9,
        ['Eschan_Portal_#3' ] = 10,
        ['Eschan_Portal_#4' ] = 11,
        ['Eschan_Portal_#5' ] = 12,
        ['Eschan_Portal_#6' ] = 13,
        ['Eschan_Portal_#7' ] = 14,
        ['Eschan_Portal_#8' ] = 15,
        ['Eschan_Portal_#9' ] = 16,
        ['Eschan_Portal_#10'] = 17,
        ['Eschan_Portal_#11'] = 18,
        ['Eschan_Portal_#12'] = 19,
        ['Eschan_Portal_#13'] = 20,
        ['Eschan_Portal_#14'] = 21,
        ['Eschan_Portal_#15'] = 22,
    },
    [xi.zone.REISENJIMA] =
    {
        ['Ethereal_Ingress_#1' ] = 23,
        ['Ethereal_Ingress_#2' ] = 24,
        ['Ethereal_Ingress_#3' ] = 25,
        ['Ethereal_Ingress_#4' ] = 26,
        ['Ethereal_Ingress_#5' ] = 27,
        ['Ethereal_Ingress_#6' ] = 28,
        ['Ethereal_Ingress_#7' ] = 29,
        ['Ethereal_Ingress_#8' ] = 30,
        ['Ethereal_Ingress_#9' ] = 31,
        ['Ethereal_Ingress_#10'] = 32,
    },
}

-----------------------------------
-- Notes:
-- RELAUNCH grants every local destination on first use and charges no Silt.
-----------------------------------
local function getPortalCost(_player)
    return 0
end

xi.escha.portals.eschanPortalOnTrigger = function(player, npc)
    local portalBitMask       = player:getTeleport(xi.teleport.type.ESCHAN_PORTAL) -- Param 2.
    local zoneId              = player:getZoneID()                                 -- Param 3.
    local lockValue           = 0                                                  -- Param 5.
    local portalGlobalNumber  = portalData[zoneId][npc:getName()]                  -- Bit number used to track portals unlocked.
    local zonePortalsUnlocked = 0

    -- RELAUNCH: touching any Escha/Reisenjima portal permanently unlocks every
    -- destination represented in that zone's shared portal bitmask.
    if portalOffsets[zoneId] then
        for portalBit = portalOffsets[zoneId][1], portalOffsets[zoneId][2] do
            if not utils.mask.getBit(portalBitMask, portalBit) then
                player:addTeleport(xi.teleport.type.ESCHAN_PORTAL, portalBit)
            end
        end

        portalBitMask = player:getTeleport(xi.teleport.type.ESCHAN_PORTAL)
    end

    -- Get zone portals and count how many we have unlocked.
    for bit = portalOffsets[zoneId][1], portalOffsets[zoneId][2] do
        if utils.mask.getBit(portalBitMask, bit) then
            zonePortalsUnlocked = zonePortalsUnlocked + 1
        end
    end

    -- Portal #10 is global bit 32, beyond the uint32 unlock mask. The event's
    -- Rhapsody flag exposes it without requiring the key item.
    if zoneId == xi.zone.REISENJIMA then
        lockValue           = lockValue + 4
        zonePortalsUnlocked = zonePortalsUnlocked + 1
    end

    -- Player has not activated this Portal.
    if
        portalGlobalNumber ~= 32 and -- Reisenjima Portal #10 exception.
        not utils.mask.getBit(portalBitMask, portalGlobalNumber)
    then
        -- Unlock Portal.
        player:addTeleport(xi.teleport.type.ESCHAN_PORTAL, portalGlobalNumber)

        -- Update Variables.
        portalBitMask       = player:getTeleport(xi.teleport.type.ESCHAN_PORTAL)
        zonePortalsUnlocked = zonePortalsUnlocked + 1
        lockValue           = lockValue + 1 -- We set it to "Locked" even if we JUST unlocked it.
    end

    -- Check if we have other portals to warp to. Do not display menu if not.
    if zonePortalsUnlocked <= 1 then
        if zoneId == xi.zone.ESCHA_ZITAH then
            portalBitMask = bit.lshift(1, 0) -- Bit 0 (Base 0) true.
        elseif zoneId == xi.zone.ESCHA_RUAUN then
            portalBitMask = bit.lshift(1, 8) -- Bit 8 (base 0) true.
        else
            portalBitMask = bit.lshift(1, 16) -- Bit 16 (Base 0) true.
        end
    end

    player:startEvent(9100, 0, portalBitMask, zoneId, portalGlobalNumber, lockValue, player:getCurrency('escha_silt'), getPortalCost(player), 0)
end

xi.escha.portals.eschanPortalEventUpdate = function(player, csid, option, npc)
end

xi.escha.portals.eschanPortalEventFinish = function(player, csid, option, npc)
    -- RELAUNCH: all Escha/Reisenjima destinations are free. The client performs
    -- the event warp; no Silt, temporary item, or key item is consumed here.
end
