-----------------------------------
-- func: optout
-- desc: Opts the player OUT of leaderboards and Discord tracking.
--       Sets Leaderboard_OptOut CharVar to 1. The Discord bot and any
--       leaderboard query will exclude this player entirely.
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
