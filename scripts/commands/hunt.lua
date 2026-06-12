-----------------------------------
-- func: hunt
-- desc: Warps you to the Hunting League Seals NPC in Reisenjima Henge —
--       the leftmost of the five NPCs in that row. Sidestep right to reach
--       Spawner / Weapons / Armor / Accessories.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, 
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(-6.5139, 5.5090, -12.1827, 230, xi.zone.REISENJIMA_HENGE)
    player:printToPlayer('Warped to the Hunting League hub. Hunt well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
