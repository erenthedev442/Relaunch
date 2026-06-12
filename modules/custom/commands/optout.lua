-----------------------------------
-- func: optout
-- desc: Opts the player OUT of leaderboards and Discord tracking.
--       This character is excluded from every leaderboard entirely.
--
-- Usage: !optout
-- See also: !optin
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setCharVar('Leaderboard_OptOut', 1)
    player:printToPlayer(
        '[Leaderboard] You are now OPTED OUT. Your progress is hidden from '
        .. 'leaderboards and Discord.  Use !optin to reverse this.',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
