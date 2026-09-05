-- Server-side lock for addon / !augment trades.
-- The Windower addon is a client file and can be edited; this module is the
-- authority. A trade is allowed only when the player is within NPC-trade
-- range of the live Arcane Augmenter AND has recently interacted with him
-- (onTrigger / onTrade already passed the engine's 6-yalm check).

local NPC_NAME = 'Augment_Moogle'
local RANGE    = 6
local ARM_SECS = 180
local ARM_VAR  = 'Augment_TradeArm'

local M = {}

local function findNpc(player)
    local zone = player:getZone()
    if not zone then
        return nil
    end

    local ok, list = pcall(function()
        return zone:queryEntitiesByName(NPC_NAME)
    end)
    if not ok or type(list) ~= 'table' or not list[1] then
        return nil
    end

    return list[1]
end

function M.near(player)
    local npc = findNpc(player)
    if not npc then
        return false
    end

    return player:checkDistance(npc) <= RANGE
end

function M.arm(player)
    player:setCharVar(ARM_VAR, os.time() + ARM_SECS)
end

function M.armed(player)
    return (player:getCharVar(ARM_VAR) or 0) >= os.time()
end

function M.allow(player)
    return M.near(player) and M.armed(player)
end

function M.denyReason(player)
    if not M.near(player) then
        return 'You must be within 6 yalms of the Arcane Augmenter.'
    end
    if not M.armed(player) then
        return 'Talk to the Arcane Augmenter first, then Trade while standing next to him.'
    end
    return nil
end

return M
