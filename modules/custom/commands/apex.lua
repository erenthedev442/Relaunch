-----------------------------------
-- func: apex
-- desc: Apex Trials helper -- check your record / Paragon Points, start a
--       climb, or bail out of one.
--
-- Usage:
--   !apex          -- show your Apex record + unspent Paragon Points
--   !apex enter    -- begin a climb (same as the Apex Arbiter NPC)
--   !apex abort    -- end your current climb (banked points are kept)
--   !apex cleanup  -- GM: remove orphaned Apex bosses from the arena
--
-- The engine + tunables live in modules/custom/lua/ApexTrials.lua /
-- apex_catalog.lua; this file is just the chat front-end.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local SYS = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, sub)
    sub = (sub or ''):lower()

    local sessions = xi._apex_sessions or {}
    local inRun    = sessions[player:getName()] ~= nil

    if sub == 'abort' then
        if inRun and xi._apex_endRun then
            xi._apex_endRun(player, 'abort')
        else
            player:printToPlayer('[Apex] You are not in a climb.', SYS)
        end
        return
    end

    if sub == 'enter' then
        if xi._apex_enter then
            xi._apex_enter(player)
        else
            player:printToPlayer('[Apex] Apex Trials are not loaded.', SYS)
        end
        return
    end

    if sub == 'cleanup' then
        if player:getGMLevel() < 1 then
            player:printToPlayer('[Apex] GM permission required.', SYS)
            return
        end

        if xi._apex_cleanupOrphans then
            local killed = xi._apex_cleanupOrphans()
            player:printToPlayer(string.format('[Apex] Cleanup complete. Removed %d orphaned Apex mob(s).', killed), SYS)
        else
            player:printToPlayer('[Apex] Apex cleanup is not loaded.', SYS)
        end
        return
    end

    -- Default: status.
    local record = player:getCharVar('Apex_HighestTier') or 0
    local pp     = player:getCharVar('Paragon_Points') or 0
    player:printToPlayer(string.format(
        '[Apex] Record: Tier %d.  Unspent Paragon Points: %d.  %s',
        record, pp, inRun and '(climbing now -- !apex abort to stop)' or ('Next push: Tier ' .. (record + 1))), SYS)
    player:printToPlayer('[Apex] !apex enter to climb, or talk to the Apex Arbiter in GM Home.', SYS)
end

return commandObj
