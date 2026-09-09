-- !scour <gear_item_id> [confirm]
-- Strip ALL augments, including crystalized lines. Same 25,000 gil cost
-- as trading the piece to the Arcane Augmenter. Server-enforced: must be
-- within 6 yalms and have talked to / traded him in the last 3 minutes.
-- The addon UI is not trusted.

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local AUGMENT_NPC_ID = 16959491
local AUGMENT_ZONE   = 44
local AUGMENT_RANGE  = 6
local AUGMENT_POS    = { x = 571.6949, y = -0.5056, z = 544.0399 }

local SCOUR_GIL_COST = 25000
local LOCK_MASK_BYTE = 13
local SIG_HEAD_BYTE  = 12

local function nearAugment(player)
    local npc = GetEntityByID(AUGMENT_NPC_ID, nil, true)
    if npc and player:checkDistance(npc) <= AUGMENT_RANGE then
        return true
    end
    if player:getZoneID() == AUGMENT_ZONE then
        return player:checkDistance(AUGMENT_POS.x, AUGMENT_POS.y, AUGMENT_POS.z) <= AUGMENT_RANGE
    end
    return false
end

local function denyAugment(player)
    if not nearAugment(player) then
        return 'You must be within 6 yalms of the Arcane Augment.'
    end
    local ok, tradeGuard = pcall(require, 'modules/custom/lua/augment_trade_guard')
    if ok and tradeGuard and tradeGuard.armed then
        if not tradeGuard.armed(player) then
            return 'Talk to the Arcane Augment first, then Scour while standing next to him.'
        end
        return nil
    end
    return nil
end

local function readSignature(item)
    if not item or not item.getSignature then
        return ''
    end
    local ok, sig = pcall(function()
        return item:getSignature()
    end)
    if ok and type(sig) == 'string' then
        return sig
    end
    return ''
end

-- Rebuild held gear without dropping inscriptions. A blank Kraken Club
-- addItem stamps a new LEG serial and announces it as a fresh drop.
local function addHeldGear(player, itemId, signature, extra)
    local payload = { id = itemId, quantity = 1 }
    if extra then
        for key, value in pairs(extra) do
            payload[key] = value
        end
    end
    if signature and signature ~= '' then
        payload.signature = signature
    end
    return player:addItem(payload)
end

commandObj.onTrigger = function(player, args)
    if not args or args:match('^%s*$') then
        player:printToPlayer(
            'Usage: !scour <gear_item_id> confirm   (25,000 gil, strips crystalized too)',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local parts = {}
    for p in args:gmatch('%S+') do
        table.insert(parts, p)
    end
    local confirmed = false
    while #parts > 0 do
        local last = parts[#parts]:lower()
        if last == 'confirm' then
            confirmed = true
            table.remove(parts)
        else
            break
        end
    end

    if #parts ~= 1 then
        player:printToPlayer(
            'Usage: !scour <gear_item_id> confirm   (25,000 gil, strips crystalized too)',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local deny = denyAugment(player)
    if deny then
        player:printToPlayer(deny, xi.msg.channel.SYSTEM_3)
        return
    end

    local gearId = tonumber(parts[1])
    if not gearId or gearId <= 0 then
        player:printToPlayer('Invalid gear item ID: ' .. tostring(parts[1]), xi.msg.channel.SYSTEM_3)
        return
    end

    local gear = player:findItem(gearId, 0)
    if not gear then
        player:printToPlayer('You do not have that gear piece in your inventory.', xi.msg.channel.SYSTEM_3)
        return
    end
    if not (gear:isType(xi.itemType.WEAPON) or gear:isType(xi.itemType.ARMOR)) then
        player:printToPlayer('Only weapons and armor can be scoured.', xi.msg.channel.SYSTEM_3)
        return
    end

    local lockMask = 0
    if gear.getExDataRaw then
        local okRaw, raw = pcall(function()
            return gear:getExDataRaw()
        end)
        if okRaw and raw then
            lockMask = bit.band(raw[LOCK_MASK_BYTE] or 0, 0x1F)
        end
    end

    local existingCount = 0
    for slot = 0, 4 do
        local existing = gear:getAugment(slot)
        local augId = existing and existing[1] or 0
        if augId ~= 0 then
            existingCount = existingCount + 1
        end
    end

    if existingCount == 0 and lockMask == 0 then
        player:printToPlayer('That piece has no augments to scour.', xi.msg.channel.SYSTEM_3)
        return
    end

    if not confirmed then
        player:printToPlayer(
            'This will STRIP every augment, including crystalized. Add confirm to continue (25,000 gil).',
            xi.msg.channel.SYSTEM_3)
        return
    end

    if player:getGil() < SCOUR_GIL_COST then
        player:printToPlayer(
            string.format('Need %d gil to scour (you have %d).', SCOUR_GIL_COST, player:getGil()),
            xi.msg.channel.SYSTEM_3)
        return
    end

    local signature = readSignature(gear)
    local slotId = gear:getSlotID()

    if not player:delGil(SCOUR_GIL_COST) then
        player:printToPlayer(
            string.format('Need %d gil to scour (you have %d).', SCOUR_GIL_COST, player:getGil()),
            xi.msg.channel.SYSTEM_3)
        return
    end

    if not player:delItemAt(gearId, 1, 0, slotId) then
        player:addGil(SCOUR_GIL_COST)
        player:printToPlayer('The selected gear moved; scour cancelled.', xi.msg.channel.SYSTEM_3)
        return
    end

    local stripped = addHeldGear(player, gearId, signature)
    if not stripped then
        addHeldGear(player, gearId, signature)
        player:addGil(SCOUR_GIL_COST)
        player:printToPlayer('Scour failed - gear returned, no gil charged.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Zero the lock mask only. Do not touch signature bytes on inscribed
    -- gear -- that would blank LEG#### and the next addItem would mint a
    -- new Kraken serial.
    if signature == '' then
        pcall(function()
            stripped:setExDataRaw({ [SIG_HEAD_BYTE] = 0, [LOCK_MASK_BYTE] = 0 })
        end)
    end

    player:printToPlayer(
        string.format('[AUGDONE]Scoured: all augments including crystalized are gone (-%d gil).', SCOUR_GIL_COST),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
