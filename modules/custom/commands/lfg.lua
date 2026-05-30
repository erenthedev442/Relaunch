-----------------------------------
-- func: lfg
-- desc: Broadcasts a Looking-For-Group announcement server-wide so
--       other players know you're looking for someone to play with.
--
-- Usage:   !lfg <activity>
-- Example: !lfg dungeons
--          !lfg hunting league tier 3
--          !lfg any
--
-- Uses xi.msg.area.SYSTEM broadcast (same ZMQ path as login
-- announcements) so every online player sees it in yellow system chat
-- regardless of which zone they are in.
--
-- There is no cooldown enforced here, but the message includes the
-- player's name and current zone so receivers can context-switch.
-- Add a charvar cooldown (pattern in gainexp.lua) if abuse becomes
-- an issue.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

commandObj.onTrigger = function(player, activity)
    local name = player:getName()

    if not activity or activity == '' then
        player:printToPlayer('[LFG] Usage: !lfg <activity>  e.g.  !lfg dungeons', xi.msg.channel.SYSTEM_3)
        player:printToPlayer('[LFG] Broadcasts your request to all online players.', xi.msg.channel.SYSTEM_3)
        return
    end

    local msg = string.format('[LFG] %s is looking for group: %s  (use /tell %s to respond)', name, activity, name)
    player:printToArea(msg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
end

return commandObj
