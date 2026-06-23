-----------------------------------
-- func: seek  (GM)
-- desc: GM-only player finder -- the /sea you wanted. Lists every online player
--       with their REAL main/sub job, level, and zone, IGNORING /anon.
--
--       /anon only hides job/level on the CLIENT (the /check and /sea displays);
--       it is NOT a server-side data restriction, so reading the entity directly
--       reveals everyone. (The real /sea can't be made GM-only: the xi_search
--       process is separate + stateless and never learns who is searching.)
--
-- Usage:
--   !seek            -- list every online player
--   !seek <filter>   -- only players whose JOB or NAME matches <filter>
--                       e.g. !seek war   !seek drb
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,   -- GM
    parameters = 's',
}

local S = xi.msg.channel.SYSTEM_3

-- Same in-memory online list that powers !who (pruned via GetPlayerByName).
local tracker = require('modules/custom/lua/online_tracker')

local JOB_ABBR =
{
    [0]  = '---',
    [1]  = 'WAR', [2]  = 'MNK', [3]  = 'WHM', [4]  = 'BLM', [5]  = 'RDM', [6]  = 'THF',
    [7]  = 'PLD', [8]  = 'DRK', [9]  = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
    [13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU', [17] = 'COR', [18] = 'PUP',
    [19] = 'DNC', [20] = 'SCH', [21] = 'GEO', [22] = 'RUN',
}
local function jobAbbr(id) return JOB_ABBR[id or 0] or ('J' .. tostring(id)) end

commandObj.onTrigger = function(player, filterArg)
    local filter = (filterArg and filterArg ~= '') and filterArg:lower() or nil

    local rows = {}
    for _, info in ipairs(tracker.getOnline()) do
        local p = GetPlayerByName(info.name)
        if p then
            local mj     = jobAbbr(p:getMainJob())
            local sj     = p:getSubJob() or 0
            local jobStr = (sj > 0)
                and string.format('%s%d/%s%d', mj, p:getMainLvl(), jobAbbr(sj), p:getSubLvl())
                or  string.format('%s%d', mj, p:getMainLvl())
            local zone   = ((p:getZoneName() or '?'):gsub('_', ' '))

            local include = true
            if filter then
                include = info.name:lower():find(filter, 1, true) ~= nil
                       or jobStr:lower():find(filter, 1, true) ~= nil
            end
            if include then
                rows[#rows + 1] = { name = info.name, jobStr = jobStr, zone = zone }
            end
        end
    end

    table.sort(rows, function(a, b) return a.name < b.name end)

    if #rows == 0 then
        player:printToPlayer(filter
            and string.format('[Seek] No online players match "%s".', filterArg)
            or  '[Seek] No players online.', S)
        return
    end

    player:printToPlayer(string.format('[Seek] %d online%s -- real job/zone, /anon ignored:',
        #rows, filter and (' matching "' .. filterArg .. '"') or ''), S)
    for _, r in ipairs(rows) do
        player:printToPlayer(string.format('  %-15s %-12s %s', r.name, r.jobStr, r.zone), S)
    end
end

return commandObj
