-----------------------------------
-- !visitant
-- Gives the caller effectively-permanent Abyssea Visitant status so the
-- countdown never ejects them. Usable by all players, inside Abyssea only.
--
-- WHY WE NEVER delStatusEffect(VISITANT):
--   Losing the VISITANT effect while standing in Abyssea mid-session fires
--   its onEffectLose handler (scripts/effects/visitant.lua), which runs
--   startEvent(2180) -- the "your visitant status expired" EJECT cutscene.
--   So removing-then-re-adding (the old version of this command) kicked the
--   player out instead of helping. We instead:
--     * have a visitant already -> extend it IN PLACE (setDuration +
--       resetStartTime), exactly like !addabytime. No removal -> no eject.
--     * have none             -> add the permanent (no-duration) effect, the
--       one retail hands visible GMs in xi.abyssea.onZoneIn.
--
--   NOTE: we set a huge finite duration rather than 0. Setting 0 on an
--   already-running timed effect makes reportTimeRemaining() see the time
--   cross its warning thresholds (300s..1s) and run the countdown -> eject.
--   A 14-day duration just trips the "time went UP, reset" branch and stays
--   silent; the passive zone-in grant re-ups true-permanent anyway.
--
-- Must be used INSIDE an Abyssea zone -- the effect self-removes on tick
-- anywhere else (visitant.lua onEffectTick).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,   -- all players
    parameters = '',
}

-- 14 days in ms. Well under int32 max, far longer than any Abyssea session,
-- so the visitant countdown never reaches its warning window.
local PERMA_MS = 1209600000

commandObj.onTrigger = function(player)
    if not xi.abyssea.isInAbysseaZone(player) then
        player:printToPlayer('You must be inside an Abyssea zone to gain Visitant status.', xi.msg.channel.SYSTEM_3)
        return
    end

    local effect = player:getStatusEffect(xi.effect.VISITANT)
    if effect then
        -- Extend in place -- DO NOT remove it (removal triggers the eject).
        -- Same safe path !addabytime uses.
        effect:setDuration(PERMA_MS)
        effect:resetStartTime()
        effect:setIcon(xi.effect.VISITANT)
    else
        -- No visitant present: grant the permanent (no-duration) effect.
        player:addStatusEffect(xi.effect.VISITANT, { origin = player })
    end

    player:printToPlayer('Permanent Visitant status set -- your Abyssea time will not expire.', xi.msg.channel.SYSTEM_3)
end

return commandObj
