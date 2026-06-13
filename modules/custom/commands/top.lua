-----------------------------------
-- func: top
-- desc: Shows the top 5 currently online players ranked by a stat.
--       Opted-out players are excluded.  For full server-wide rankings
--       see the website at legendary-ffxi.pages.dev
--
-- Usage:
--   !top           - default: top by lifetime Hunt Marks
--   !top kills     - top by NM kill count
--   !top marks     - top by lifetime Hunt Marks earned
--   !top infamy    - top by lifetime Infamy earned
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local ot = require('modules/custom/lua/online_tracker')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_1

-- Stat definitions: label shown to player + CharVar to read.
local STATS = {
    kills  = { label = 'NM Kills',              cv = 'Custom_NM_Kills'      },
    marks  = { label = 'Lifetime Hunt Marks',   cv = 'HL_Points_Lifetime'   },
    infamy = { label = 'Lifetime Infamy',       cv = 'Infamy_Lifetime'      },
}

local DEFAULT_STAT = 'marks'

commandObj.onTrigger = function(player, arg)
    -- Normalise argument: trim whitespace, lowercase.
    local key = (arg or ''):match('^%s*(.-)%s*$'):lower()
    if key == '' then key = DEFAULT_STAT end

    local statDef = STATS[key]
    if not statDef then
        player:printToPlayer(
            '[top] Unknown stat.  Use: !top kills | !top marks | !top infamy',
            xi.msg.channel.SYSTEM_3)
        return
    end

    -- Collect online players who have not opted out.
    local online = ot.getOnline()
    local rows   = {}
    for _, name in ipairs(online) do
        local p = GetPlayerByName(name)
        if p and (p:getCharVar('Leaderboard_OptOut') or 0) == 0 then
            local val = p:getCharVar(statDef.cv) or 0
            table.insert(rows, { name = name, val = val })
        end
    end

    -- Sort descending by stat value.
    table.sort(rows, function(a, b) return a.val > b.val end)

    player:printToPlayer(
        string.format('[Top 5 Online] == %s ==========================', statDef.label), H)

    if #rows == 0 then
        player:printToPlayer('  No eligible players online.', B)
    else
        local limit = math.min(5, #rows)
        for rank = 1, limit do
            local r = rows[rank]
            player:printToPlayer(
                string.format('  %d. %-20s  %d', rank, r.name, r.val), B)
        end
    end

    player:printToPlayer(
        '  Full server rankings: legendary-ffxi.pages.dev', B)
end

return commandObj
