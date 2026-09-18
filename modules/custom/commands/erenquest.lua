-----------------------------------
-- !erenquest [status|abort]
-- Tester-facing status and safe encounter-abort command.
-----------------------------------
local catalog = require('modules/custom/lua/eren_quest_catalog')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local SYS = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, action)
    action = type(action) == 'string' and action:lower() or 'status'
    if action == 'abort' then
        if not (xi.erenQuest and xi.erenQuest.abort and xi.erenQuest.abort(player)) then
            player:printToPlayer('[Eren Quest] You have no active encounter to abort.', SYS)
        end
        return
    end

    if not catalog.hasAccess(player) then
        player:printToPlayer('[Eren Quest] This unreleased quest is not available to your character.', SYS)
        return
    end

    if action == '' or action == 'status' then
        if xi.erenQuest and xi.erenQuest.status then
            xi.erenQuest.status(player)
        else
            for _, line in ipairs(catalog.statusLines(player)) do
                player:printToPlayer(line, SYS)
            end
        end
    else
        player:printToPlayer('Usage: !erenquest [status | abort]', SYS)
    end
end

return commandObj
