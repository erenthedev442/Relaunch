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
--       Data source: enumerates the live player list of every zone via
--       GetZone(id):getPlayers(). This is the in-world ground truth -- unlike the
--       !who online-tracker, it does NOT reset on a map restart and does NOT miss
--       players who reconnected as a zone-in after a crash (the tracker only
--       records non-zoning logins, so it reads empty for ~hours after each crash).
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

local S          = xi.msg.channel.SYSTEM_3
local MAX_ZONEID = 300   -- src/map/zone.h ZONEID::MAX_ZONEID; valid ids 0..299

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
    local seen = {}
    for zid = 0, MAX_ZONEID - 1 do
        local z = GetZone(zid)
        if z then
            local players = z:getPlayers()
            if players and #players > 0 then
                local zoneName = ((z:getName() or '?'):gsub('_', ' '))
                for _, p in ipairs(players) do
                    local name = p:getName()
                    if name and not seen[name] then
                        seen[name] = true
                        local mj     = jobAbbr(p:getMainJob())
                        local sj     = p:getSubJob() or 0
                        local jobStr = (sj > 0)
                            and string.format('%s%d/%s%d', mj, p:getMainLvl(), jobAbbr(sj), p:getSubLvl())
                            or  string.format('%s%d', mj, p:getMainLvl())

                        local include = true
                        if filter then
                            include = name:lower():find(filter, 1, true) ~= nil
                                   or jobStr:lower():find(filter, 1, true) ~= nil
                        end
                        if include then
                            rows[#rows + 1] = { name = name, jobStr = jobStr, zone = zoneName }
                        end
                    end
                end
            end
        end
    end

    -- Group by zone, then alphabetical -- easiest for a GM to scan / !goto.
    table.sort(rows, function(a, b)
        if a.zone ~= b.zone then return a.zone < b.zone end
        return a.name < b.name
    end)

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
