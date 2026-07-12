-----------------------------------
-- !checkascend
-- Shows the player's Ascension (Provenance Altar) AP spend for their
-- current main job: prestige level, unspent AP, and every boost category
-- with purchased levels vs cap. Extracted from !mystats to reduce clutter
-- (ported from Legendary 2026-07-12, player request: Lant).
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
    if not prestigeOk or not prestige or not prestige.categories then
        player:printToPlayer('Ascension data unavailable.', S)
        return
    end

    local mJob = player:getMainJob()
    player:printToPlayer('>>> ASCENSION (PROVENANCE) <<<', S)
    line(player, 'Prestige Lv %d   AP unspent %d   (current main job)',
        player:getCharVar(string.format('Prestige_Level_%d', mJob)) or 0,
        player:getCharVar(string.format('Prestige_AP_%d', mJob)) or 0)

    local buf = {}
    for _, cat in ipairs(prestige.categories) do
        local lv = player:getCharVar(string.format('Prestige_Cat_%d_%s', mJob, cat.id)) or 0
        table.insert(buf, string.format('%s %d/%d', cat.label, lv, cat.cap))
        if #buf == 3 then
            line(player, '%s', table.concat(buf, '   '))
            buf = {}
        end
    end
    if #buf > 0 then
        line(player, '%s', table.concat(buf, '   '))
    end

    player:printToPlayer(' ', S)
    player:printToPlayer('Use !checkrebirth for Rebirth stats. Boosts are already included in !mystats totals.', S)
end

return commandObj
