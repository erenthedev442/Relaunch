-----------------------------------
-- func: profile
-- desc: Displays a competitive stat summary for a player.  With no
--       argument shows your own stats; with a name shows that player's
--       (they must be online - offline players can't be queried via Lua).
--
-- Usage:
--   !profile          - your own stats
--   !profile Jbae     - Jbae's stats (must be online)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local TIER_NAMES = { 'Initiate', 'Bronze', 'Silver', 'Gold', 'Legend' }
local ACH_IDS    = { 'FIRST_HUNT','TENTH_HUNT','CENTURY','THOUSAND',
                      'TIER2_FIRST','TIER3_FIRST','TIER4_FIRST','APEX_HUNTER',
                      'MARKS_1K','MARKS_10K','MARKS_100K' }

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, targetName)
    local targ

    if targetName and targetName ~= '' then
        targ = GetPlayerByName(targetName)
        if not targ then
            player:printToPlayer(
                string.format('[Profile] Player "%s" not found or not online.', targetName), H)
            return
        end
    else
        targ = player
    end

    local name     = targ:getName()
    local hlTier   = targ:getCharVar('HL_Tier')            or 0
    local hlLife   = targ:getCharVar('HL_Points_Lifetime') or 0
    local nmKills  = targ:getCharVar('Custom_NM_Kills')    or 0
    local dungeons = targ:getCharVar('Dungeon_Clears_Total')   or 0
    local sweeps   = targ:getCharVar('WH_AllCleared_Lifetime') or 0
    local infamy   = targ:getCharVar('Infamy_Lifetime')        or 0

    -- Count earned achievements.
    local achCount = 0
    for _, id in ipairs(ACH_IDS) do
        if (targ:getCharVar('ACH_' .. id) or 0) ~= 0 then
            achCount = achCount + 1
        end
    end

    local tierName = TIER_NAMES[math.max(1, math.min(hlTier, 5))] or 'Initiate'
    if hlTier == 0 then tierName = 'Initiate' end

    player:printToPlayer(string.format('[Profile] == %s ==========================', name), H)
    player:printToPlayer(string.format('  HL Rank: %-8s  NM Kills: %-6d  Lifetime Marks: %d',
        tierName, nmKills, hlLife), B)
    player:printToPlayer(string.format('  Dungeons: %d clears  |  Infamy: %d  |  Weekly Sweeps: %d',
        dungeons, infamy, sweeps), B)
    player:printToPlayer(string.format('  Achievements: %d / %d', achCount, #ACH_IDS), B)

    if targ ~= player then
        player:printToPlayer(
            '  (Full leaderboards at fjb-relaunch.pages.dev/community/leaderboards/)', B)
    end
end

return commandObj
