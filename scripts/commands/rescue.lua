-----------------------------------
-- !rescue <charname>
-- desc: GM command -- unsticks a player, whether online or offline.
--
--       ONLINE  (same map cluster): warps to Lower Jeuno and forceLogout
--                                   so they can log back in fresh.
--       ONLINE  (different cluster): the GM must switch clusters to reach the
--                                    entity object; message tells them so.
--       OFFLINE (any state):        engine resetPlayer path -- deletes any
--                                   stale accounts_sessions row and warps them
--                                   to the same Lower Jeuno spot.
--
--       Gentler alternatives that don't force a relog:
--         !gmrelease <name> <reason>  (GM1 event-state clear + resync)
--         Ask the player to use !unstick for self-service recovery.
--       Use !rescue when those aren't enough (e.g. char logged out below
--       geometry, Y-coord in the void, can't log back in without crashing).
--
-- permission 1 = GM1 support, online or offline
-----------------------------------
-- (xi.zone is a global from scripts/enum/zone.lua -- no require needed.)

---@type TCommand
local commandObj = {}

commandObj.cmdprops = { permission = 1, parameters = 's' }

-- Same landing as CLuaBaseEntity::resetPlayer / Discord !rescue.
local RESCUE_ZONE = xi.zone.LOWER_JEUNO -- 245
local RESCUE_X, RESCUE_Y, RESCUE_Z, RESCUE_ROT = 33.464, -5.000, 69.162, 86

commandObj.onTrigger = function(gm, charname)
    if not charname or charname == '' then
        gm:printToPlayer('Usage: !rescue <charname>', xi.msg.channel.SYSTEM_3)
        gm:printToPlayer('Unsticks a player, online or offline.', xi.msg.channel.SYSTEM_3)
        gm:printToPlayer('  online  -> Lower Jeuno + forceLogout', xi.msg.channel.SYSTEM_3)
        gm:printToPlayer('  offline -> Lower Jeuno (engine resetPlayer)', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Try to grab the entity object first (only exists if online in this cluster).
    local target = GetPlayerByName(charname)
    if target then
        if gm:getGMLevel() < 5 and (target:getGMLevel() or 0) > 0 then
            gm:printToPlayer('[Rescue] GM1 cannot rescue another staff character.', xi.msg.channel.SYSTEM_3)
            return
        end
        local fromZone = target:getZoneName() or '?'
        target:setPos(RESCUE_X, RESCUE_Y, RESCUE_Z, RESCUE_ROT, RESCUE_ZONE)
        target:forceLogout()
        gm:printToPlayer(string.format('[Rescue] %s warped from %s -> Lower Jeuno and session cleared. They can now log back in.', charname, fromZone), xi.msg.channel.SYSTEM_3)
        target:printToPlayer(string.format('[Rescue] A GM has moved you to Lower Jeuno from %s. Please log back in.', fromZone), xi.msg.channel.SYSTEM_3)
        return
    end

    -- Not in this cluster -- resolve char id from the DB to distinguish
    -- "offline" from "online elsewhere" from "no such character".
    local targetID = GetPlayerIDByName(charname)
    if not targetID or targetID <= 0 or targetID >= 0xFFFFFFFF then
        gm:printToPlayer(string.format('[Rescue] No character named %s exists.', charname), xi.msg.channel.SYSTEM_3)
        return
    end

    if PlayerHasValidSession(targetID) then
        -- Online, but on a different map process. resetPlayer would race the
        -- live session; bounce back to the GM.
        gm:printToPlayer(string.format('[Rescue] %s is online in a different cluster. Switch to that map process and re-run !rescue.', charname), xi.msg.channel.SYSTEM_3)
        return
    end

    -- Truly offline -- engine handles the DB update.
    gm:resetPlayer(charname)
    gm:printToPlayer(string.format('[Rescue] %s was offline. Session cleared and warped to Lower Jeuno via engine reset. They can now log back in.', charname), xi.msg.channel.SYSTEM_3)
end

return commandObj
