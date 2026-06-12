-----------------------------------
-- func: optin
-- desc: Opts the player INTO leaderboards and Discord tracking.
--       This is the default state for new characters.
--
-- Usage: !optin
-- See also: !optout
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setCharVar('Leaderboard_OptOut', 0)
    player:printToPlayer(
        '[Leaderboard] You are now OPTED IN. Your progress will appear on '
        .. 'leaderboards and Discord announcements.  Use !optout to reverse this.',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
