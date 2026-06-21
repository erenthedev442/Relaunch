-----------------------------------
-- !prov3
-- GM warp to Ascension Altar III (tertiary) in Provenance (zone 222).
-- Sibling commands: !prov1 (Altar I), !prov2 (Altar II).
-- Coords mirror the Altar III anchor in Prestige_System.lua -- keep in sync.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1, -- GM only; set to 0 to let players use it
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(-279.2352, 0.2092, -790.8884, 223, 222) -- 222 = Provenance
    player:printToPlayer('Warped to Ascension Altar III (Provenance).', xi.msg.channel.SYSTEM_3)
end

return commandObj
