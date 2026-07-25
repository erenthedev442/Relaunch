-----------------------------------
-- !geaski <1|2|3|4|urn|cellar|nef>
--
-- Buys a Geas Fete pop trigger remotely with Escha Beads.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

commandObj.onTrigger = function(player, requestedTier)
    local S = xi.msg.channel.SYSTEM_3
    if not xi.geasFete or not xi.geasFete.buyTrigger then
        player:printToPlayer('[Geas Fete] The trigger service is unavailable.', S)
        return
    end

    xi.geasFete.buyTrigger(player, requestedTier)
end

return commandObj
