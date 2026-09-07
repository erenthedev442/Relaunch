-- Server-side lock for addon / !augment trades.
-- The Windower addon is a client file and can be edited; this module is the
-- authority. A trade is allowed only when the player is within NPC-trade
-- range of the live Arcane Augment AND has recently interacted with him
-- (onTrigger / onTrade already passed the engine's 6-yalm check).
--
-- insertDynamicEntity stores the script name as DE_Augment_Moogle. Looking
-- up "Augment_Moogle" never finds him (and the zone name-cache can also
-- freeze an empty miss). Resolve by entity ID, then DE_ name, then sanctum
-- coordinates.

local KEY = 'modules/custom/lua/augment_trade_guard'
local M   = package.loaded[KEY]
if type(M) ~= 'table' then
    M = {}
end

M.NPC_ID    = tonumber(M.NPC_ID) or 16959491 -- live Abdhaljs dynamic NPC
M.NPC_NAME  = 'DE_Augment_Moogle'
M.ZONE_ID   = 44
M.POS       = { x = 571.6949, y = -0.5056, z = 544.0399 }
M.RANGE     = 6
M.ARM_SECS  = 180
M.ARM_VAR   = 'Augment_TradeArm'

function M.setNpcId(id)
    id = tonumber(id)
    if id and id > 0 then
        M.NPC_ID = id
    end
end

local function findNpc(player)
    local id = tonumber(M.NPC_ID) or 0
    if id > 0 then
        local byId = GetEntityByID(id, nil, true)
        if byId then
            return byId
        end
    end

    local zone = player and player.getZone and player:getZone()
    if not zone then
        return nil
    end

    local ok, list = pcall(function()
        return zone:queryEntitiesByName(M.NPC_NAME)
    end)
    if ok and type(list) == 'table' and list[1] then
        return list[1]
    end

    return nil
end

function M.near(player)
    local npc = findNpc(player)
    if npc then
        return player:checkDistance(npc) <= M.RANGE
    end

    if player:getZoneID() == M.ZONE_ID then
        local pos = M.POS
        return player:checkDistance(pos.x, pos.y, pos.z) <= M.RANGE
    end

    return false
end

function M.arm(player)
    player:setCharVar(M.ARM_VAR, os.time() + M.ARM_SECS)
end

function M.armed(player)
    return (player:getCharVar(M.ARM_VAR) or 0) >= os.time()
end

function M.allow(player)
    return M.near(player) and M.armed(player)
end

function M.denyReason(player)
    if not M.near(player) then
        return 'You must be within 6 yalms of the Arcane Augment.'
    end
    if not M.armed(player) then
        return 'Talk to the Arcane Augment first, then Trade while standing next to him.'
    end
    return nil
end

return M
