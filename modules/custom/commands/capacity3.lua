-----------------------------------
-- func: capacity3
-- desc: Warp to the East Ronfaure [S] Capacity Point farm.
--       Landing spot MUST stay in sync with warpPos in
--       ronfaure_s_farm_catalog.lua.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if player:getMainLvl() < 99 then
        player:printToPlayer(
            'Capacity Point farms require a level 99 main job.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    player:setPos(510.8990, -59.5513, 471.9462, 92, xi.zone.EAST_RONFAURE_S)
    player:printToPlayer(
        'Warped to the Capacity farm in East Ronfaure [S]. Grind well, kupo!',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
