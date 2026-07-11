-----------------------------------
-- !rescue <charname>
-- desc: GM command -- teleports an online stuck player to GM Home (zone 210)
--       and clears their session so they can log back in fresh.
--       Works only for ONLINE characters (GetPlayerByName returns nil offline).
--       For offline chars that cannot log in, fix their position directly in
--       the DB (chars.pos_zone) instead.
--
--       Gentler alternatives that don't force a relog: !releaseme <name>
--       (event-state clear + resync) and !releaseme <name> force (homepoint
--       warp). Use !rescue when those aren't enough.
--
-- permission 1 = GM-only
-----------------------------------
-- (xi.zone is a global from scripts/enum/zone.lua -- no require needed.)

---@type TCommand
local commandObj = {}

commandObj.cmdprops = { permission = 1, parameters = 's' }

local RESCUE_ZONE = xi.zone.GM_HOME  -- 210
local RESCUE_X, RESCUE_Y, RESCUE_Z, RESCUE_ROT = 0, 0, 0, 0

commandObj.onTrigger = function(gm, charname)
    if not charname or charname == '' then
        gm:printToPlayer('Usage: !rescue <charname>', xi.msg.channel.SYSTEM_3)
        gm:printToPlayer('Teleports an online stuck player to GM Home and clears their session.', xi.msg.channel.SYSTEM_3)
        gm:printToPlayer('For offline chars that cannot log in, fix chars.pos_zone in the DB.', xi.msg.channel.SYSTEM_3)
        return
    end

    local target = GetPlayerByName(charname)
    if not target then
        gm:printToPlayer(string.format('[Rescue] %s is not online.', charname), xi.msg.channel.SYSTEM_3)
        gm:printToPlayer('[Rescue] For players who cannot log in at all, fix chars.pos_zone in the DB.', xi.msg.channel.SYSTEM_3)
        return
    end

    local fromZone = target:getZoneName() or '?'
    target:setPos(RESCUE_X, RESCUE_Y, RESCUE_Z, RESCUE_ROT, RESCUE_ZONE)
    target:forceLogout()
    gm:printToPlayer(string.format('[Rescue] %s warped from %s -> GM Home and session cleared. They can now log back in.', charname, fromZone), xi.msg.channel.SYSTEM_3)
    target:printToPlayer(string.format('[Rescue] A GM has moved you to GM Home from %s. Please log back in.', fromZone), xi.msg.channel.SYSTEM_3)
end

return commandObj
