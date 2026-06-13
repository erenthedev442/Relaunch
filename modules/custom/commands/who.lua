-----------------------------------
-- func: who
-- desc: Lists players who have logged in during this server session,
--       sorted by Hunting League tier (highest first), with their tier
--       name shown.  Stale entries (crashed clients) are pruned lazily
--       via GetPlayerByName at query time.
--
-- Usage: !who
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local tracker = require('modules/custom/lua/online_tracker')

local HL_TIER_NAMES = { 'Initiate', 'Bronze', 'Silver', 'Gold', 'Legend' }

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_1

commandObj.onTrigger = function(player)
    local online = tracker.getOnline()

    player:printToPlayer(string.format('[Who] %d player(s) online this session:', #online), H)

    if #online == 0 then
        player:printToPlayer('  No players tracked yet - list updates as players log in.', B)
    else
        for _, info in ipairs(online) do
            local tier     = info.tier or 0
            local tierName = HL_TIER_NAMES[math.max(1, math.min(tier, 5))] or 'Initiate'
            if tier == 0 then tierName = 'Initiate' end
            player:printToPlayer(string.format('  %-16s [%s]', info.name, tierName), B)
        end
    end
end

return commandObj
