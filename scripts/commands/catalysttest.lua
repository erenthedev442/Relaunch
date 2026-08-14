-----------------------------------
-- !catalysttest [itemId]
--
-- DIAGNOSTIC (2026-07-07): fire the EXACT augment-catalyst award + drop message
-- on yourself, bypassing the mob-death hook and the 50% roll. This proves the
-- award/message code path works in isolation, so we can tell "the message code
-- is broken" apart from "the mob-death hook / gating isn't reaching it".
--
--   !catalysttest         -> awards the first item in the live catalyst mob map
--   !catalysttest 5498    -> awards that specific catalyst item id
--
-- The real drop path (augment_catalyst_drops.lua) also logs a [CatalystDBG] line
-- per player kill; grep map-server.log for 'CatalystDBG' after killing mobs.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = 's',
}

local CHANNEL = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, arg)
    local acd = xi.augmentCatalystDrops
    if not acd or not acd.give then
        player:printToPlayer('[catalysttest] augment_catalyst_drops is not loaded '
            .. '(needs a map restart after the module change).', CHANNEL)
        return
    end

    local id = tonumber(arg)
    if not id then
        -- no id given: grab any real mapped catalyst so the command works bare
        for _, v in pairs(acd.map or {}) do id = v; break end
    end
    if not id then
        player:printToPlayer('[catalysttest] no itemId given and the catalyst map is empty.', CHANNEL)
        return
    end

    local ok = acd.give(player, id)
    player:printToPlayer(string.format(
        '[catalysttest] fired the award path for itemId=%d (awarded=%s). '
        .. 'If you saw the "[Augments] Catalyst dropped" line above, the message path works.',
        id, tostring(ok)), CHANNEL)
end

return commandObj
