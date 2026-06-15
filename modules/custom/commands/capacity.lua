-----------------------------------
-- func: capacity
-- desc: Warps you to the Capacity Point farm camp in Bibiki Bay.
--       Kill the always-up Lv150-160 mobs for Capacity/Job Points.
--       Landing spot MUST stay in sync with warpPos in
--       modules/custom/lua/capacity_farm_catalog.lua.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    -- Bibiki Bay (zone 4); coord matches capacity_farm_catalog.warpPos.
    player:setPos(93.0, -45.5, 928.0, 128, xi.zone.BIBIKI_BAY)
    player:printToPlayer('Warped to the Capacity farm in Bibiki Bay. Grind well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
