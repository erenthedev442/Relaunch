-----------------------------------
-- func: reforged
-- desc: Warps you to the Reforge Armor system NPCs in Gwora-Corridor.
--       Position matches catalog.spawnerPos in
--       modules/custom/lua/reforge_catalog.lua — keep them in sync.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    -- Spawner is at (10, 0, 0); Vendor is at (15, 0, 0). Drop the player
    -- a couple of units in front of the Spawner so both NPCs are in view.
    player:setPos(8.0, 0.0, 0.0, 64, xi.zone.GWORA_CORRIDOR)
    player:printToPlayer('Warped to the Reforge area. Reforge well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
