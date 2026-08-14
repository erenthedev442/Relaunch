-----------------------------------
-- func: apex
-- desc: Apex Trials helper -- check your record / Paragon Points or bail out
--       of a climb. New climbs begin through the Apex Arbiter NPC.
--
-- Usage:
--   !apex          -- show your Apex record + unspent Paragon Points
--   !apex abort           -- end your own climb
--   !apex status [player] -- self status; support GMs may inspect another player
--   !apex cleanup         -- support GM: remove orphaned Apex bosses from the arena
--
-- The engine + tunables live in modules/custom/lua/ApexTrials.lua /
-- apex_catalog.lua; this file is just the chat front-end.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

local SYS = xi.msg.channel.SYSTEM_3

local function printStatus(viewer, target, inRun)
    local record = target:getCharVar('Apex_HighestTier') or 0
    local pp     = target:getCharVar('Paragon_Points') or 0
    viewer:printToPlayer(string.format(
        '[Apex] %s: Record Tier %d. Unspent Paragon Points: %d. %s',
        target:getName(), record, pp,
        inRun and '(climbing now)' or ('Next push: Tier ' .. (record + 1))), SYS)
end

commandObj.onTrigger = function(player, sub, targetName)
    sub = (sub or ''):lower()

    local sessions = xi._apex_sessions or {}
    local inRun    = sessions[player:getName()] ~= nil

    if sub == 'abort' then
        local target = player
        if targetName then
            if player:getGMLevel() < 5 then
                player:printToPlayer('[Apex] Use !gmcontent reset apex <player> <reason>.', SYS)
                return
            end

            target = GetPlayerByName(targetName)
            if not target then
                player:printToPlayer('[Apex] Player not found: ' .. targetName, SYS)
                return
            end
        end

        if sessions[target:getName()] and xi._apex_endRun then
            xi._apex_endRun(target, 'abort')
            if target ~= player then
                player:printToPlayer('[Apex] Aborted climb for ' .. target:getName() .. '.', SYS)
            end
        else
            player:printToPlayer('[Apex] ' .. target:getName() .. ' is not in a climb.', SYS)
        end
        return
    end

    if sub == 'status' then
        local target = player
        if targetName then
            if player:getGMLevel() < 1 then
                player:printToPlayer('[Apex] Support GM permission required to inspect another player.', SYS)
                return
            end

            target = GetPlayerByName(targetName)
            if not target then
                player:printToPlayer('[Apex] Player not found: ' .. targetName, SYS)
                return
            end
        end

        printStatus(player, target, sessions[target:getName()] ~= nil)
        return
    end

    if sub == 'enter' then
        player:printToPlayer('[Apex] Begin climbs through the Apex Arbiter NPC in Purgonorgo Isle.', SYS)
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
    printStatus(player, player, inRun)
    player:printToPlayer('[Apex] Talk to the Apex Arbiter in Purgonorgo Isle to begin a climb.', SYS)
end

return commandObj
