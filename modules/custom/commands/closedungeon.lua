-----------------------------------
-- func: closedungeon (player)
-- desc: Force-closes a player's private dungeon and returns its party to GM Home.
--
-- Usage:
--   !closedungeon CharacterName
--   !closedungeon                 -- cursor-targeted player, otherwise yourself
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = 's',
}

local runtime = require('modules/custom/lua/dungeon_instance')
local systemMessage = xi.msg.channel.SYSTEM_3

local function getTarget(player, targetName)
    if targetName and targetName ~= '' then
        return GetPlayerByName(targetName)
    end

    local cursorTarget = player:getCursorTarget()
    if cursorTarget and cursorTarget:isPC() then
        return cursorTarget
    end

    return player
end

commandObj.onTrigger = function(player, targetName)
    local target = getTarget(player, targetName)
    if not target then
        player:printToPlayer(
            string.format('[Dungeon Close] Player "%s" is not online.', targetName),
            systemMessage)
        return
    end

    local closed, memberCount, dungeon, errorMessage = runtime.forceClose(target)
    if not closed then
        player:printToPlayer(
            string.format('[Dungeon Close] %s: %s', target:getName(), errorMessage),
            systemMessage)
        return
    end

    player:printToPlayer(
        string.format('[Dungeon Close] Closed %s for %s; %d player(s) sent to GM Home.',
            dungeon.label, target:getName(), memberCount),
        systemMessage)
end

return commandObj
