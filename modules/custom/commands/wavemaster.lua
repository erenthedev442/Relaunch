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
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    -- Escha - Ru'Aun (zone 289), the open entry plaza. Player lands at the
    -- documented zone-in point; the Wave Master NPC sits a few units to the
    -- side. Far more room than the old Hall of the Gods, so waves spawn in the
    -- open. (Adjust with !pos in-game if you want a different open spot.)
    player:setPos(-0.371, -34.277, -466.98, 187, 289)
    player:printToPlayer('[Wave Master] Warping to Escha - Ru\'Aun - the arena awaits!', xi.msg.channel.SYSTEM_3)
end

return commandObj
