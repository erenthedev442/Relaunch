-----------------------------------
-- func: wavemaster
-- desc: Warps you to Hall of the Gods where the Wave Master NPC is located.
--       The Wave Master runs themed enemy wave fights (Easy → Nightmare)
--       that reward Hunt Marks on full clear.
--
-- Usage: !wavemaster
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    -- Hall of the Gods (zone 251). NPC is at z=-169, a few units ahead
    -- of the default zone spawn. Player lands at the zone's standard
    -- entry point facing into the chamber.
    player:setPos(-0.011, -1.848, -176.133, 192, 251)
    player:printToPlayer('[Wave Master] Warping to the Hall of the Gods — the arena awaits!', xi.msg.channel.SYSTEM_3)
end

return commandObj
