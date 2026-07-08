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
    -- Drop the player at the hub entrance -- the live-verified station-1 spot
    -- (!pos 2026-07-07), with the Reforge Vendor + Mark Exchange a few units
    -- north at the origin cluster and the NM Spawner stations spread out from
    -- here (see reforge_catalog.stations).
    player:setPos(-0.66, 0.0, -3.10, 143, xi.zone.DIORAMA_ABDHALJS_GHELSBA)
    player:printToPlayer('Warped to the Reforge hub. Reforge well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
