-----------------------------------
-- func: bonus_dungeon
-- desc: Shows which dungeon is this week's Weekly Bonus Dungeon.
--       The bonus dungeon awards 2x Infamy on the first clear of the
--       week. The featured dungeon rotates deterministically each ISO
--       week using the same formula as the Hunting League's weekly
--       featured hunt:
--         weekIdx = math.floor(os.time() / 604800)
--         featIdx = (weekIdx % #enabled) + 1
--       so this command always agrees with what the server rewards.
--
-- Usage: !bonus_dungeon
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local catalog = require('modules/custom/lua/dungeon_catalog')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_1

commandObj.onTrigger = function(player)
    -- Build the enabled dungeon list (same as DungeonSystem.lua's getWeeklyBonusDungeon).
    local enabled = {}
    for _, d in ipairs(catalog.dungeons or {}) do
        if not d._disabled then
            table.insert(enabled, d)
        end
    end

    if #enabled == 0 then
        player:printToPlayer('[Bonus Dungeon] No dungeons are currently available.', H)
        return
    end

    local weekIdx  = math.floor(os.time() / 604800)
    local featIdx  = (weekIdx % #enabled) + 1
    local dungeon  = enabled[featIdx]

    -- Check if the player has already earned the bonus this week.
    local earnedCv = string.format('DB_Bonus_%d_%s', weekIdx, dungeon.id)
    local earned   = (player:getCharVar(earnedCv) or 0) == 1
    local status   = earned and 'earned' or '2x Infamy on clear!'

    player:printToPlayer('[Bonus Dungeon] \xe2\x94\x80\xe2\x94\x80 This Week\'s Featured Dungeon \xe2\x94\x80\xe2\x94\x80', H)
    player:printToPlayer(
        string.format('  %s  [%s]', dungeon.label, status), B)
end

return commandObj
