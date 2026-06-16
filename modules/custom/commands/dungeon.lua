-----------------------------------
-- !dungeon [abort]
-- Player command to manage an active dungeon run.
--
-- Usage:
--   !dungeon abort   -- cancel the current run (no reward, cooldown applies)
-----------------------------------
local DungeonSystem = require('modules/custom/lua/DungeonSystem')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

commandObj.onTrigger = function(player, sub)
    local CH = xi.msg.channel.SYSTEM_3
    sub = (sub or ''):lower()

    if sub == 'abort' then
        DungeonSystem.endDungeon(player, 'manual')
        player:printToPlayer('[Dungeon] Run aborted. No reward applied.', CH)
    else
        player:printToPlayer('Usage: !dungeon abort', CH)
    end
end

return commandObj
