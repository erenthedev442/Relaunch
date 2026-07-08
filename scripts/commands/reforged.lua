-----------------------------------
-- func: reforged
-- desc: Warps you to the Reforge Armor hub in Diorama Abdhaljs-Ghelsba (zone 43).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    -- Drop the player at the hub centre, on the Reforge Vendor (0, 0, 0), with
    -- the ring of NM Spawner stations around them (see reforge_catalog.stations).
    -- NOTE: these coords track catalog.vendorPos -- finalise both together in the
    -- live !pos pass for zone 43 (blank diorama, no repo coordinate data).
    player:setPos(0.0, 0.0, 0.0, 128, xi.zone.DIORAMA_ABDHALJS_GHELSBA)
    player:printToPlayer('Warped to the Reforge hub. Reforge well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
