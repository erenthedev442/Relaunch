-----------------------------------
-- func: capacity4
-- desc: Warp to the second East Ronfaure [S] Capacity Point farm.
--       Landing spot MUST stay in sync with warpPos in
--       ronfaure_s_farm4_catalog.lua.
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

    player:setPos(577.1001, -51.1170, 149.4120, 116, xi.zone.EAST_RONFAURE_S)
    player:printToPlayer(
        'Warped to the south Capacity farm in East Ronfaure [S]. Grind well, kupo!',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
