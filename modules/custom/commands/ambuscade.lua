-----------------------------------
-- !ambuscade [stats]
-- Shows the player's Ambuscade currency and monthly cap status.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

commandObj.onTrigger = function(player, subcommand)
    if not xi.ambuscade then
        player:printToPlayer('[Ambuscade] Ambuscade system not loaded.', xi.msg.channel.SYSTEM_3)
        return
    end

    local sub = (subcommand or ''):lower()

    -- Default: show personal stats.
    xi.ambuscade.printStats(player)

    if sub == 'stats' then
        -- Already printed above; nothing extra needed.
        return
    end

    -- Brief reminder of how to enter / spend.
    player:printToPlayer('[Ambuscade] Enter via the Ambuscade Tome in Mhaura. Spend HM at Gorpa-Masorpa nearby.',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
