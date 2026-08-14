-----------------------------------
-- !prov2
-- GM warp to Ascension Altar II (secondary) in Provenance (zone 222).
-- Sibling commands: !prov1 (Altar I), !prov3 (Altar III).
-- Coords mirror the Altar II anchor in Prestige_System.lua -- keep in sync.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(-161.7446, -0.0117, -685.5436, 88, 222) -- 222 = Provenance
    player:printToPlayer('Warped to Ascension Altar II (Provenance).', xi.msg.channel.SYSTEM_3)
end

return commandObj
