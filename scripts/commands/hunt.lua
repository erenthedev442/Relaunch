-----------------------------------
-- func: hunt
-- desc: Warps you to the Hunting League Seals NPC in Reisenjima Henge —
--       the leftmost of the vendor row. Walk right to reach Spawner /
--       Gear Progression / Armor / Accessories / Accessory / Chronicler.
--       Landing spot MUST stay in sync with sealsPos in hunting_league_catalog.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, 
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(-11.0000, 5.5090, -12.1827, 230, xi.zone.REISENJIMA_HENGE)
    player:printToPlayer('Warped to the Hunting League hub. Hunt well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
