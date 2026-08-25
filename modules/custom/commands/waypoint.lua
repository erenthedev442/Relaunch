-----------------------------------
-- func: waypoint
-- desc: Personal, per-character warp points. Each player can save up to 10
--       positions (slots 1-10) wherever they stand and warp back later. Slots
--       are overwritable -- saving over a slot just replaces it.
--
-- Usage:
--   !waypoint save <1-10>    -- save your current position to a slot (alias: set)
--   !waypoint <1-10>         -- warp to a saved slot
--   !waypoint list           -- list your saved waypoints (alias: l)
--   !waypoint clear <1-10>   -- delete a slot (alias: del)
--   !waypoint                -- show this help + your list
--
-- Storage: per-character CharVars -- WP<n>_zone/_x/_y/_z/_rot. CharVars are
-- integers, so positions are stored x1000 (3-decimal precision, plenty for a
-- warp) and the zone is stored +1 so an unset slot reads back as 0 = empty.
--
-- Pure Lua, no new tables. Lives in modules/custom/commands/ (merge-safe,
-- auto-loaded via the custom/commands/ folder entry). Player command (perm 0).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

local MAX_SLOTS = 10
local CHANNEL   = xi.msg.channel.SYSTEM_3

-- zoneId -> enum name, built once for the list display (guarded in case the
-- zone enum isn't ready when this file loads -- falls back to "zone <id>").
local zoneNameById = {}
for name, id in pairs(xi.zone or {}) do
    if type(id) == 'number' then
        zoneNameById[id] = name
    end
end

local function say(player, text)
    player:printToPlayer(text, CHANNEL)
end

-- CharVar key builders for a slot.
local function kZone(n) return string.format('WP%d_zone', n) end
local function kX(n)    return string.format('WP%d_x', n) end
local function kY(n)    return string.format('WP%d_y', n) end
local function kZ(n)    return string.format('WP%d_z', n) end
local function kRot(n)  return string.format('WP%d_rot', n) end

local function validSlot(n)
    return n ~= nil and n == math.floor(n) and n >= 1 and n <= MAX_SLOTS
end

-- nil if the slot is empty, else the stored waypoint.
local function readWaypoint(player, n)
    local zoneEnc = player:getCharVar(kZone(n))
    if zoneEnc == 0 then
        return nil
    end
    return {
        zone = zoneEnc - 1,
        x    = player:getCharVar(kX(n)) / 1000,
        y    = player:getCharVar(kY(n)) / 1000,
        z    = player:getCharVar(kZ(n)) / 1000,
        rot  = player:getCharVar(kRot(n)),
    }
end

local function saveWaypoint(player, n)
    player:setCharVar(kZone(n), player:getZoneID() + 1)  -- +1 so 0 means "empty"
    player:setCharVar(kX(n),   math.floor(player:getXPos() * 1000 + 0.5))
    player:setCharVar(kY(n),   math.floor(player:getYPos() * 1000 + 0.5))
    player:setCharVar(kZ(n),   math.floor(player:getZPos() * 1000 + 0.5))
    player:setCharVar(kRot(n), player:getRotPos())
end

local function clearWaypoint(player, n)
    player:setCharVar(kZone(n), 0)  -- setting a CharVar to 0 removes its row
    player:setCharVar(kX(n), 0)
    player:setCharVar(kY(n), 0)
    player:setCharVar(kZ(n), 0)
    player:setCharVar(kRot(n), 0)
end

local function zoneLabel(zoneId)
    local name = zoneNameById[zoneId]
    if name then
        return (name:gsub('_', ' '))
    end
    return string.format('zone %d', zoneId)
end

local function showList(player)
    say(player, '[Waypoint] Your saved waypoints:')
    local any = false
    for n = 1, MAX_SLOTS do
        local wp = readWaypoint(player, n)
        if wp then
            any = true
            say(player, string.format('  %d: %s  (%.1f, %.1f, %.1f)',
                n, zoneLabel(wp.zone), wp.x, wp.y, wp.z))
        end
    end
    if not any then
        say(player, '  (none yet -- save one with: !waypoint save 1)')
    end
end

local function showHelp(player)
    say(player, string.format('[Waypoint] Personal warp points (up to %d):', MAX_SLOTS))
    say(player, string.format('  !waypoint save <1-%d>   - save your current spot', MAX_SLOTS))
    say(player, string.format('  !waypoint <1-%d>        - warp to a saved spot', MAX_SLOTS))
    say(player, '  !waypoint list          - show your waypoints')
    say(player, string.format('  !waypoint clear <1-%d>  - delete a spot', MAX_SLOTS))
    showList(player)
end

local function warpTo(player, n)
    local wp = readWaypoint(player, n)
    if not wp then
        say(player, string.format('[Waypoint] Slot %d is empty. Save it first: !waypoint save %d', n, n))
        return
    end
    if player:isEngaged() then
        say(player, '[Waypoint] You cannot warp while engaged in battle.')
        return
    end

    if player:getZoneID() == wp.zone then
        player:setPos(wp.x, wp.y, wp.z, wp.rot)             -- same zone: instant reposition
    else
        player:setPos(wp.x, wp.y, wp.z, wp.rot, wp.zone)    -- different zone: zone transfer
    end
    say(player, string.format('[Waypoint] Warping to waypoint %d (%s).', n, zoneLabel(wp.zone)))
end

commandObj.onTrigger = function(player, arg1, arg2)
    if arg1 == nil then
        showHelp(player)
        return
    end

    local cmd = string.lower(arg1)

    if cmd == 'help' then
        showHelp(player)
        return
    elseif cmd == 'list' or cmd == 'l' then
        showList(player)
        return
    elseif cmd == 'save' or cmd == 'set' or cmd == 's' then
        local n = tonumber(arg2)
        if not validSlot(n) then
            say(player, string.format('[Waypoint] Pick a slot 1-%d, e.g. !waypoint save 1', MAX_SLOTS))
            return
        end
        saveWaypoint(player, n)
        say(player, string.format('[Waypoint] Saved your position to waypoint %d.', n))
        return
    elseif cmd == 'clear' or cmd == 'del' or cmd == 'delete' or cmd == 'remove' then
        local n = tonumber(arg2)
        if not validSlot(n) then
            say(player, string.format('[Waypoint] Pick a slot 1-%d, e.g. !waypoint clear 1', MAX_SLOTS))
            return
        end
        clearWaypoint(player, n)
        say(player, string.format('[Waypoint] Cleared waypoint %d.', n))
        return
    end

    -- Otherwise, treat arg1 as a slot number -> warp.
    local n = tonumber(arg1)
    if validSlot(n) then
        warpTo(player, n)
        return
    end

    say(player, string.format('[Waypoint] Unknown option "%s".', arg1))
    showHelp(player)
end

return commandObj
