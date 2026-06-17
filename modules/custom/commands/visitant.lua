-----------------------------------
-- !visitant
-- Grants the calling player PERMANENT Abyssea Visitant status -- the same
-- no-duration effect retail hands visible GMs (xi.abyssea.onZoneIn, the
-- getVisibleGMLevel >= 3 branch). With no `duration` the engine never starts
-- the countdown, so the player is never ejected for running out of time.
--
-- Must be used INSIDE an Abyssea zone: the VISITANT effect's onEffectTick
-- (scripts/effects/visitant.lua) deletes itself on the next tick anywhere
-- that isn't an Abyssea zone, so granting it elsewhere is a no-op.
--
-- NOTE: this server already auto-grants permanent visitant to every player
-- on Abyssea zone-in (modules/custom/lua/unlimited_visitant.lua /
-- AbysseaPermanentVisitant.lua). This command is a manual re-assert -- useful
-- if a timed 304s visitant ever overwrote the permanent one, or to restore it
-- on demand without re-zoning.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,   -- all players (matches the auto-grant everyone already gets)
    parameters = '',
}

commandObj.onTrigger = function(player)
    if not xi.abyssea.isInAbysseaZone(player) then
        player:printToPlayer('You must be inside an Abyssea zone to gain Visitant status.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Drop any existing (possibly timed) visitant first so the permanent,
    -- no-duration effect replaces it instead of inheriting its expiring timer.
    if player:hasStatusEffect(xi.effect.VISITANT) then
        player:delStatusEffect(xi.effect.VISITANT)
    end

    -- No `duration` field -> permanent. Mirrors the visible-GM grant in
    -- xi.abyssea.onZoneIn; the countdown never runs, so no eject to Searing Ward.
    player:addStatusEffect(xi.effect.VISITANT, { origin = player })

    player:printToPlayer('Permanent Visitant status granted -- your Abyssea time will never expire.', xi.msg.channel.SYSTEM_3)
end

return commandObj
