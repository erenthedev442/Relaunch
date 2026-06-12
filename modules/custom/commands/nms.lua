-----------------------------------
-- func: nms
-- desc: Shows the player's NM Encyclopedia progress - which Hunting
--       League NMs they have killed at least once, and which ones
--       remain.  Lists up to 10 missing NMs to avoid flooding chat.
--
-- Usage: !nms
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local catalog = require('modules/custom/lua/hunting_league_catalog')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.LINKSHELL

commandObj.onTrigger = function(player)
    local killed  = 0
    local total   = 0
    local missing = {}

    for _, tierDef in ipairs(catalog.tiers) do
        for _, mob in ipairs(tierDef.mobs) do
            total = total + 1
            if (player:getCharVar('NMKilled_' .. mob.groupId) or 0) ~= 0 then
                killed = killed + 1
            else
                table.insert(missing, string.format('%s [T%d]', mob.label, tierDef.tier))
            end
        end
    end

    local pct = total > 0 and math.floor(killed / total * 100) or 0
    player:printToPlayer(
        string.format('[NM Encyclopedia] %d / %d NMs slain (%d%%)', killed, total, pct), H)

    if #missing == 0 then
        player:printToPlayer('  ALL NMs DEFEATED - you are a true completionist!', B)
    else
        local shown = math.min(#missing, 10)
        player:printToPlayer(string.format('  Still missing (%d):', #missing), B)
        for i = 1, shown do
            player:printToPlayer('  * ' .. missing[i], B)
        end
        if #missing > shown then
            player:printToPlayer(
                string.format('  ... and %d more.  Type !hunt to warp and keep hunting!', #missing - shown), B)
        end
    end
end

return commandObj
