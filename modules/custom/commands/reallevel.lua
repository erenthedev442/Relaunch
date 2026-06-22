-----------------------------------
-- func: reallevel
-- desc: Computes a player's "real level" -- a single fun number that
--       reflects how far PAST the level-99 cap a character has actually
--       progressed, by folding in every endgame power axis FFXI offers:
--       gear (item level), Ascension (Prestige), Job Points, and merits.
--
--       The cap is 99, but two identical lvl-99 characters can be worlds
--       apart. This command turns "all the stuff above 99" into one
--       headline number, with a transparent breakdown of where every
--       bonus level came from.
--
-- Usage:
--   !reallevel          -- your own real level
--   !reallevel Jbae     -- Jbae's real level (must be online)
--
-- The actual formula + tunables live in the shared lib
-- modules/custom/lua/real_level.lua, so this command and the login-time
-- leaderboard updater (RealLevel_Tracker.lua) can never drift apart. This
-- file is just the chat-display + an on-demand CharVar refresh.
--
-- Lives in modules/custom/commands/ so it survives upstream LSB merges
-- (scripts/commands/ is upstream-tracked; this folder is ours).
-----------------------------------
local realLib = require('modules/custom/lua/real_level')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

-- == Output channels (match profile.lua: yellow header, default body) ===
local H = xi.msg.channel.SYSTEM_3    -- header line
local B = xi.msg.channel.SYSTEM_3   -- body lines

-- Invert xi.job (key->id) once so we can show "WAR" instead of a raw id.
local function jobName(jobId)
    for k, v in pairs(xi.job) do
        if v == jobId then return k end
    end
    return '???'
end

commandObj.onTrigger = function(player, targetName)
    -- Resolve who we're reporting on. Optional name targets an ONLINE
    -- player (offline characters can't be queried through Lua).
    local targ = player
    if targetName and targetName ~= '' then
        targ = GetPlayerByName(targetName)
        if not targ then
            player:printToPlayer(
                string.format('[Real Level] Player "%s" not found or not online.', targetName), H)
            return
        end
    end

    -- Shared computation (single source -- see real_level.lua).
    local realLevel, bd = realLib.compute(targ)
    if realLevel == nil then
        player:printToPlayer('[Real Level] Target is not a player character.', H)
        return
    end

    -- Persist for the website leaderboard (docs/community/leaderboards.md ranks
    -- the RealLevel CharVar). Running !reallevel registers / refreshes the board
    -- on demand; the login hook (RealLevel_Tracker) keeps everyone else fresh.
    targ:setCharVar('RealLevel', realLevel)

    -- == Render ==
    player:printToPlayer(string.format(
        '[Real Level] -- %s the %s%d -----------------------',
        targ:getName(), jobName(bd.job), bd.base), H)
    player:printToPlayer(string.format('  >>> REAL LEVEL: %d <<<', realLevel), B)
    player:printToPlayer(string.format('  Base lvl %d  +  %d from your investment:', bd.base, bd.bonus), B)
    player:printToPlayer(string.format('    Gear ......... +%-4d (avg iLvl %d)',   bd.gear, bd.ilvl), B)
    player:printToPlayer(string.format('    Ascension .... +%-4d (Prestige rank %d)', bd.asc, bd.asc), B)
    player:printToPlayer(string.format('    Job Points ... +%-4d (%d JP spent)',   bd.jp, bd.jpSpent), B)
    player:printToPlayer(string.format('    Merits ....... +%-4d (attribute merits +%d)', bd.merit, bd.meritSum), B)
    player:printToPlayer(string.format('    Rebirth ...... +%-4d (%d rebirths)', bd.rebirth, bd.rebirthCount), B)

    -- Account-wide flex tail: total ascensions across every job.
    local lifeAsc = targ:getCharVar('Prestige_Ascensions_Total') or 0
    if lifeAsc > 0 then
        player:printToPlayer(string.format(
            '  Lifetime ascensions (all jobs): %d', lifeAsc), B)
    end
    player:printToPlayer('  (Full stat sheet: !mystats)', B)
end

return commandObj
