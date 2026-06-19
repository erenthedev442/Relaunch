-----------------------------------
-- func: tournament
-- desc: Legendary Tournament — last-person-standing PvE wave event.
--
-- Usage:
--   !tournament                  show current status
--   !tournament join             register during sign-up phase
--   !tournament leave            withdraw during sign-up phase
--   !tournament open   (GM)      open sign-ups
--   !tournament start  (GM)      warp all entrants in, begin wave 1
--   !tournament cancel (GM)      abort and warp survivors home
--   !tournament kick <name> (GM) remove a player
--   !tournament add  <name> (GM) force-add a player to sign-ups
--
-- All logic lives in modules/custom/lua/Tournament.lua.
-- This file is a thin command shim.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'sss',
}

commandObj.onTrigger = function(player, sub, a2, a3)
    local tm = xi._tournament
    if not tm then
        player:printToPlayer('[Tournament] Tournament module not loaded.')
        return
    end
    tm.handleCmd(player, sub, a2, a3)
end

return commandObj
