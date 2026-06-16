-----------------------------------
-- !dungeon [abort]
-- Player command to manage an active dungeon run.
--
-- Usage:
--   !dungeon abort   -- cancel the current run (no reward, cooldown applies)
-----------------------------------
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
        local ds = xi._dungeonSystem
        if not ds then
            player:printToPlayer('[Dungeon] Dungeon system not loaded.', CH)
            return
        end
        ds.endDungeon(player, 'manual')
        player:printToPlayer('[Dungeon] Run aborted. No reward applied.', CH)
    else
        player:printToPlayer('Usage: !dungeon abort', CH)
    end
end

return commandObj
