-----------------------------------
-- !maat
-- Warps the player to the custom "Maat's Echo" challenge NPC in Ru'Lude Gardens
-- (the level-250 Maat fight entry -- see modules/custom/lua/maat_infamy_fight.lua).
-- Available to all players (permission 0), like !henge / !capacity.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

commandObj.onTrigger = function(player)
    -- Maat's Echo NPC location (zone 243, RuLude Gardens). Mirrors NPC_X/Y/Z/ROT
    -- in maat_infamy_fight.lua -- keep in sync if that NPC is ever moved.
    player:setPos(12.0, 3.0, 118.0, 200, xi.zone.RULUDE_GARDENS)
end

return commandObj
