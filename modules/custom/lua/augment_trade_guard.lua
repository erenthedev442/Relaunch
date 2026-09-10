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

-- Inventory slot 0 is gil. Bag slots are 1-80.
local INV_SLOT_MIN = 1
local INV_SLOT_MAX = 80

function M.parseGearToken(token)
    token = tostring(token or '')
    local id, slot = token:match('^(%d+)@(%d+)$')
    if id then
        return tonumber(id), tonumber(slot)
    end
    id = tonumber(token)
    if id and id > 0 then
        return id, nil
    end
    return nil, nil
end

-- If parts[2] is slot:N, consume it and return N.
function M.takeSlotArg(parts)
    if type(parts) ~= 'table' or not parts[2] then
        return nil
    end
    local n = tostring(parts[2]):match('^[Ss]lot:(%d+)$')
    if not n then
        return nil
    end
    table.remove(parts, 2)
    return tonumber(n)
end

function M.heldBusyReason(item)
    if not item then
        return 'That piece is gone.'
    end
    if item.getReservedValue and item:getReservedValue() > 0 then
        return 'That piece is busy. Try again in a moment.'
    end
    if not item.state then
        return nil
    end
    local st = item:state()
    if st == xi.itemState.EQUIPPED then
        return 'Unequip that piece first.'
    end
    if st == xi.itemState.BAZAAR then
        return 'Take that piece out of your bazaar first.'
    end
    if st == xi.itemState.IN_TRANSACTION then
        return 'That piece is busy. Try again in a moment.'
    end
    if st ~= xi.itemState.FREE then
        return 'That piece is not free to augment.'
    end
    return nil
end

function M.findFreeInvItem(player, itemId)
    itemId = tonumber(itemId)
    if not player or not itemId or itemId <= 0 then
        return nil
    end
    local copies = player:findItems(itemId, 0)
    if type(copies) ~= 'table' then
        return nil
    end
    for _, item in ipairs(copies) do
        if not M.heldBusyReason(item) then
            return item
        end
    end
    return nil
end

-- Resolve a specific inventory copy. Slot is required when the player
-- has more than one free copy of the same item ID (two Chirich Rings,
-- etc). Equipped / bazaar / reserved pieces are never chosen -- that
-- used to delete the worn copy and addItem a third one.
function M.resolveHeldGear(player, gearId, bagSlot)
    gearId = tonumber(gearId)
    bagSlot = tonumber(bagSlot)
    if not player or not gearId or gearId <= 0 then
        return nil, 'Invalid gear item ID.'
    end

    if bagSlot then
        if bagSlot < INV_SLOT_MIN or bagSlot > INV_SLOT_MAX then
            return nil, 'Invalid inventory slot.'
        end
        local item = player:getStorageItem(0, bagSlot, 255)
        if not item or item:getID() ~= gearId then
            return nil, 'That inventory slot does not hold that gear piece.'
        end
        local busy = M.heldBusyReason(item)
        if busy then
            return nil, busy
        end
        return item, nil
    end

    local copies = player:findItems(gearId, 0)
    if type(copies) ~= 'table' or #copies == 0 then
        return nil, 'You do not have that gear piece in your inventory.'
    end

    local free = {}
    for _, item in ipairs(copies) do
        if not M.heldBusyReason(item) then
            free[#free + 1] = item
        end
    end
    if #free == 1 then
        return free[1], nil
    end
    if #free == 0 then
        return nil, M.heldBusyReason(copies[1]) or 'Unequip that piece first.'
    end
    return nil, 'You have more than one of that item. Select a specific copy in Augment Trade.'
end

return M
