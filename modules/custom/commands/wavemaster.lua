-----------------------------------
-- func: wavemaster
-- desc: Warps you to Balga's Dais where the Wave Master NPC is located.
--       The Wave Master runs themed enemy wave fights (Easy → Insane)
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
    -- Balga's Dais (zone 146). NPC stands at z=383 just north of the
    -- player spawn point (317.842, -126.158, 380.143), so players
    -- appear facing the NPC immediately on arrival.
    player:setPos(317.842, -126.158, 380.143, 127, 146)
    player:printToPlayer('[Wave Master] Warping to Balga\'s Dais — the arena awaits!', xi.msg.channel.SYSTEM_3)
end

return commandObj
