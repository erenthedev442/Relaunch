-----------------------------------
-- func: wavemaster
-- desc: Warps you to Escha - Ru'Aun where the Wave Master NPC is located.
--       The Wave Master runs themed enemy wave fights (Easy -> Nightmare)
--       that reward Hunt Marks on full clear.
--
-- Usage: !wavemaster
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

commandObj.onTrigger = function(player)
    -- Escha - Ru'Aun (zone 289). The Game Masters were spread across the zone
    -- 2026-07-09 (see game_master_catalog.lua npcPositions), so this convenience
    -- warp now lands at the FIRST spot (npcPositions[1]); walk to any of the four
    -- to run its waves. (Adjust with !pos in-game if you want a different spot.)
    player:setPos(258.6571, -70.0200, 509.2923, 149, 289)
    player:printToPlayer('[Wave Master] Warping to Escha - Ru\'Aun - the arena awaits!', xi.msg.channel.SYSTEM_3)
end

return commandObj
