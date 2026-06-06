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
-- HOW THE NUMBER IS BUILT
-- =======================
-- Real Level = base job level + the sum of four INDEPENDENT bonuses.
-- Each bonus is read from its OWN system so nothing is double-counted:
--
--   Gear ........ getAverageItemLevel() - 99
--                 The weighted item level the game shows on your stats
--                 screen (weapon-heavy). iLvl 119 in every slot = +20.
--                 Purely from equipped gear -- no merits/JP/ascension in it.
--
--   Ascension ... Prestige_Level_<job> CharVar
--                 Each completed ascension at the Altar = +1. This axis is
--                 UNCAPPED (the endless "Paragon" tail), so it's the big
--                 long-term flex. Per-CURRENT-job, matching how Prestige
--                 stat bonuses apply.
--
--   Job Points .. getSpentJobPoints() / JP_PER_LEVEL
--                 Total JP poured into the current job (0 below lvl 99).
--                 A fully job-pointed job (~2100 JP) ~= +21 at the default
--                 divisor of 100.
--
--   Merits ...... sum of the 7 base-attribute merits / MERIT_ATTR_PER_LEVEL
--                 STR DEX VIT AGI INT MND CHR meritted bonuses. This is the
--                 slice of merit investment we can measure exactly; broader
--                 merit/skill investment still shows up in your effective
--                 stats (see !mystats).
--
-- TUNING: the two divisors below are the only knobs. Lower divisor = each
--         point of JP / merit is worth more real levels. Gear and Ascension
--         are deliberately 1:1 (an item level / an ascension each = 1 level).
--
-- Lives in modules/custom/commands/ so it survives upstream LSB merges
-- (scripts/commands/ is upstream-tracked; this folder is ours).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

-- == Tunables ========================================================
-- JP spent per bonus real-level. 100 -> a maxed job (~2100 JP) is ~+21.
local JP_PER_LEVEL        = 100
-- Summed attribute-merit points per bonus real-level.
local MERIT_ATTR_PER_LEVEL = 5

-- == Output channels (match profile.lua: yellow header, green body) ===
local H = xi.msg.channel.SYSTEM_3    -- header line
local B = xi.msg.channel.LINKSHELL   -- body lines

-- The 7 base-attribute merits we can read exactly via getMerit(). HP/MP
-- merits are intentionally excluded -- their values are an order of
-- magnitude larger and would drown out the attribute signal.
local ATTR_MERITS = { 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR' }

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

    local job   = targ:getMainJob()
    local base  = targ:getMainLvl()

    -- == Gear: item levels above 99 (weapon-weighted, as shown in-game) ==
    local ilvl   = targ:getAverageItemLevel()
    local gearLv = math.max(0, ilvl - 99)

    -- == Ascension: completed ascensions for the CURRENT job ==
    local ascLv  = targ:getCharVar('Prestige_Level_' .. job) or 0

    -- == Job Points: total spent on the current job ==
    local jpSpent = targ:getSpentJobPoints() or 0
    local jpLv    = math.floor(jpSpent / JP_PER_LEVEL)

    -- == Merits: sum of the 7 base-attribute merit bonuses ==
    local meritSum = 0
    for _, m in ipairs(ATTR_MERITS) do
        meritSum = meritSum + (targ:getMerit(xi.merit[m]) or 0)
    end
    local meritLv = math.floor(meritSum / MERIT_ATTR_PER_LEVEL)

    local realLevel = base + gearLv + ascLv + jpLv + meritLv
    local bonus     = gearLv + ascLv + jpLv + meritLv

    -- == Render ==
    player:printToPlayer(string.format(
        '[Real Level] -- %s the %s%d -----------------------',
        targ:getName(), jobName(job), base), H)
    player:printToPlayer(string.format('  >>> REAL LEVEL: %d <<<', realLevel), B)
    player:printToPlayer(string.format('  Base lvl %d  +  %d from your investment:', base, bonus), B)
    player:printToPlayer(string.format('    Gear ......... +%-4d (avg iLvl %d)',   gearLv, ilvl), B)
    player:printToPlayer(string.format('    Ascension .... +%-4d (Prestige rank %d)', ascLv, ascLv), B)
    player:printToPlayer(string.format('    Job Points ... +%-4d (%d JP spent)',   jpLv, jpSpent), B)
    player:printToPlayer(string.format('    Merits ....... +%-4d (attribute merits +%d)', meritLv, meritSum), B)

    -- Account-wide flex tail: total ascensions across every job.
    local lifeAsc = targ:getCharVar('Prestige_Ascensions_Total') or 0
    if lifeAsc > 0 then
        player:printToPlayer(string.format(
            '  Lifetime ascensions (all jobs): %d', lifeAsc), B)
    end
    player:printToPlayer('  (Full stat sheet: !mystats)', B)
end

return commandObj
