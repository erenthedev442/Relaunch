-----------------------------------
-- func: provenance
-- desc: Sends you to zone 222 (PROVENANCE), home of the Ascension Altar.
--       Mirrors !gmhome (permission 0 = usable by everyone). The player
--       lands at (0,0,0); Provenance's onZoneIn repositions them to the
--       altar's doorstep at (-640, -20, -519.999) facing rot 192.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(0, 0, 0, 0, xi.zone.PROVENANCE)
end

return commandObj
