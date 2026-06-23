-----------------------------------
-- !aoews <wsname>
-- desc: Permanently binds a weapon skill as your AoE WS.
--       Requires the AoE unlock from the Rupture Sage (GM Home).
--       Cannot be changed after setting.
--
-- Examples:
--   !aoews Resolution
--   !aoews Rudras Storm
--   !aoews Chant du Cygne
-----------------------------------
require('scripts/enum/weaponskill')

local cmdObj = {}

cmdObj.cmdprops = { permission = 0, parameters = 's' }

cmdObj.onTrigger = function(player, arg)
    local SYS = xi.msg.channel.SYSTEM_3

    if not arg or arg == '' then
        player:printToPlayer('[AoE WS] Usage: !aoews <wsname>  e.g. !aoews Resolution', SYS)
        player:printToPlayer('[AoE WS] Use the WS name as-is (spaces OK). Apostrophes are stripped.', SYS)
        return
    end

    if (player:getCharVar('AoEWSPct') or 0) < 50 then
        player:printToPlayer('[AoE WS] You must unlock AoE WS from the Rupture Sage in GM Home first.', SYS)
        return
    end

    if (player:getCharVar('AoEWSID') or 0) ~= 0 then
        player:printToPlayer(string.format('[AoE WS] Already set to WS#%d — cannot be changed.', player:getCharVar('AoEWSID')), SYS)
        return
    end

    -- Normalize: "Rudra's Storm" -> "RUDRAS_STORM", "Chant du Cygne" -> "CHANT_DU_CYGNE"
    local key = arg:upper():gsub("'", ''):gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    local wsID = xi.weaponskill[key]

    if not wsID then
        player:printToPlayer(string.format("[AoE WS] Unknown WS '%s' (looked up as '%s').", arg, key), SYS)
        player:printToPlayer('[AoE WS] Match the name to the xi.weaponskill enum (e.g. RESOLUTION, RUDRAS_STORM).', SYS)
        return
    end

    player:setCharVar('AoEWSID', wsID)
    player:printToPlayer(string.format("[AoE WS] Permanently bound to '%s' (ID %d) at %d%% splash.", arg, wsID, player:getCharVar('AoEWSPct')), SYS)
    player:printToPlayer('[AoE WS] Takes effect immediately — use your WS to see splash damage.', SYS)
end

return cmdObj
