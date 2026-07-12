-----------------------------------
-- !checkrebirth
-- Shows the player's Job Rebirth stats for their current main job:
-- rebirth count, unspent Rebirth Points, EXP penalty, and every boost
-- category with purchased levels vs cap. Rebirth shares its category list
-- with Ascension (prestige_catalog.categories -- see JobRebirth.lua).
-- Ported from Legendary 2026-07-12 (player request: Lant).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local S = xi.msg.channel.SYSTEM_3
local prestigeOk, prestige = pcall(require, 'modules/custom/lua/prestige_catalog')

local function line(player, fmt, ...)
    player:printToPlayer('  ' .. string.format(fmt, ...), S)
end

commandObj.onTrigger = function(player)
    local mJob = player:getMainJob()

    local count  = player:getCharVar('Rebirth_Count_' .. mJob) or 0
    local rp     = player:getCharVar('Rebirth_RP_' .. mJob) or 0
    local expCut = player:getCharVar('[RebirthExpCut]') or 0

    player:printToPlayer('>>> JOB REBIRTH <<<', S)
    line(player, 'Rebirths: %d   RP unspent: %d   EXP penalty: -%d%%   (current main job)',
        count, rp, expCut)

    if not prestigeOk or not prestige or not prestige.categories then
        line(player, '(boost category data unavailable)')
        return
    end

    if count == 0 then
        line(player, '(no rebirths yet -- max job + JP, then visit the Rebirth NPC)')
    else
        local buf = {}
        for _, cat in ipairs(prestige.categories) do
            local lv = player:getCharVar(string.format('Rebirth_Cat_%d_%s', mJob, cat.id)) or 0
            table.insert(buf, string.format('%s %d/%d', cat.label, lv, cat.cap))
            if #buf == 3 then
                line(player, '%s', table.concat(buf, '   '))
                buf = {}
            end
        end
        if #buf > 0 then
            line(player, '%s', table.concat(buf, '   '))
        end
    end

    player:printToPlayer(' ', S)
    player:printToPlayer('Use !checkascend for Ascension stats. Boosts are already included in !mystats totals.', S)
end

return commandObj
