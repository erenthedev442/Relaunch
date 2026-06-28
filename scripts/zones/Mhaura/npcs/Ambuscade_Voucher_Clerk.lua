-----------------------------------
-- Ambuscade Voucher Clerk (Mhaura)
-- NPC: npcid 17797276  !pos -26.600 -15.990 52.565 249
-- DB:  ambuscade_adds.sql (cloned look from Gorpa-Masorpa)
--
-- Accepts Ambuscade Vouchers (item IDs 9235-9244) and exchanges them for
-- job-specific Ambuscade armor.  Fill in GEAR_BY_JOB with the item IDs that
-- exist on this server (query: SELECT itemid,name FROM item_equipment WHERE
-- name LIKE '%Ambuscade%' ORDER BY itemid;).
--
-- Voucher IDs:
--   Head 9235 / Body 9236 / Hands 9237 / Legs 9238 / Feet 9239
--   Head+1 9240 / Body+1 9241 / Hands+1 9242 / Legs+1 9243 / Feet+1 9244
-----------------------------------
local SYS = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Gear catalog: { [jobId] = { head, body, hands, legs, feet, head+1, body+1, hands+1, legs+1, feet+1 } }
-- Fill in item IDs from your DB.  0 = slot not available for this job.
-- Example stub: all zeros until populated.
-- Run:  SELECT itemid, name FROM item_equipment WHERE name LIKE '%mbuscade%';
-----------------------------------
local GEAR_BY_JOB =
{
    -- [xi.job.WAR] = { 0,0,0,0,0, 0,0,0,0,0 },
    -- [xi.job.MNK] = { 0,0,0,0,0, 0,0,0,0,0 },
    -- ... fill in per job when item IDs are known ...
}

-- Slot index mapping inside GEAR_BY_JOB row.
local SLOT_BASE   = { 1, 2, 3, 4, 5 }   -- base head/body/hands/legs/feet
local SLOT_PLUS1  = { 6, 7, 8, 9, 10 }  -- +1 variants
local SLOT_NAME   = { 'Head', 'Body', 'Hands', 'Legs', 'Feet' }

-- Voucher IDs indexed the same way as SLOT_NAME.
local VOUCHER_BASE  = { 9235, 9236, 9237, 9238, 9239 }
local VOUCHER_PLUS1 = { 9240, 9241, 9242, 9243, 9244 }

local function hasVoucher(player, voucherId)
    return player:hasItem(voucherId, xi.inv.INVENTORY)
end

local function doRedeem(player, slotIdx, isPlus1)
    local jobId   = player:getMainJob()
    local catalog = GEAR_BY_JOB[jobId]
    if not catalog then
        player:printToPlayer('[Ambuscade] No gear available for your current job.', SYS)
        return false
    end

    local itemId  = isPlus1 and catalog[SLOT_PLUS1[slotIdx]] or catalog[SLOT_BASE[slotIdx]]
    if not itemId or itemId == 0 then
        player:printToPlayer('[Ambuscade] That gear slot is not available for your job.', SYS)
        return false
    end

    local voucherId = isPlus1 and VOUCHER_PLUS1[slotIdx] or VOUCHER_BASE[slotIdx]
    if not hasVoucher(player, voucherId) then
        player:printToPlayer('[Ambuscade] You do not have the required voucher.', SYS)
        return false
    end

    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer('[Ambuscade] Inventory is full.', SYS)
        return false
    end

    player:delItem(voucherId, 1)
    player:addItem(itemId, 1)
    player:printToPlayer(string.format('[Ambuscade] Exchanged voucher for %s piece (%s).',
        SLOT_NAME[slotIdx], isPlus1 and '+1' or 'base'), SYS)
    return true
end

local function showSlotMenu(player, isPlus1, backFn)
    local jobId   = player:getMainJob()
    local catalog = GEAR_BY_JOB[jobId]
    local options = {}
    local vlist   = isPlus1 and VOUCHER_PLUS1 or VOUCHER_BASE
    local slist   = isPlus1 and SLOT_PLUS1    or SLOT_BASE

    for i, slotName in ipairs(SLOT_NAME) do
        local idx     = i
        local hasVch  = hasVoucher(player, vlist[i])
        local hasGear = catalog and catalog[slist[i]] and catalog[slist[i]] ~= 0
        local tag     = (not hasVch and ' (no vou)') or (not hasGear and ' (N/A)') or ''
        options[#options + 1] =
        {
            slotName .. tag,
            function(pp) doRedeem(pp, idx, isPlus1); showSlotMenu(pp, isPlus1, backFn) end,
        }
    end
    options[#options + 1] = { 'Back', backFn }

    local title = isPlus1 and 'Redeem +1' or 'Redeem Base'
    local snapshot = { title = title, options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

local function showMainMenu(player)
    local options =
    {
        {
            'Redeem Base Gear',
            function(pp) showSlotMenu(pp, false, function(p) showMainMenu(p) end) end,
        },
        {
            'Redeem +1 Gear',
            function(pp) showSlotMenu(pp, true, function(p) showMainMenu(p) end) end,
        },
        { 'Leave', function(pp) end },
    }
    local snapshot = { title = 'Voucher Clerk', options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

-----------------------------------
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    local hasAnyVoucher = false
    for _, vid in ipairs(VOUCHER_BASE) do
        if hasVoucher(player, vid) then hasAnyVoucher = true; break end
    end
    for _, vid in ipairs(VOUCHER_PLUS1) do
        if hasVoucher(player, vid) then hasAnyVoucher = true; break end
    end
    if not hasAnyVoucher then
        player:printToPlayer('[Ambuscade] You have no vouchers.  Earn them by clearing Ambuscade!', SYS)
        return
    end
    showMainMenu(player)
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
