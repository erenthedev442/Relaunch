-----------------------------------
-- !prov1
-- GM warp to Ascension Altar I (the PRIMARY altar) in Provenance (zone 222).
-- Sibling commands: !prov2 (Altar II), !prov3 (Altar III).
-- Coords mirror prestige_catalog.lua altarPos -- update both if the altar moves.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1, -- GM only; set to 0 to let players use it
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(-636.000, -20.000, -519.999, 128, 222) -- 222 = Provenance
    player:printToPlayer('Warped to Ascension Altar I (Provenance).', xi.msg.channel.SYSTEM_3)
end

return commandObj
