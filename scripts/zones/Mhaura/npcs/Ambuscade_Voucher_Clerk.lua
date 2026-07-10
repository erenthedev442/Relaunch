-----------------------------------
-- Ambuscade Voucher Clerk (Mhaura)
-- NPC: npcid 17797276  !pos -26.600 -15.990 52.565 249
-- DB:  ambuscade_adds.sql (cloned look from Gorpa-Masorpa)
--
-- Accepts Ambuscade Vouchers (item IDs 9235-9244) and exchanges them for
-- job-specific Ambuscade armor. Gear data lives in scripts/globals/
-- ambuscade.lua (xi.ambuscade.armorSets / xi.ambuscade.jobSets) so the
-- clerk and Gorpa-Masorpa's upgrade trades share one catalog.
--
-- Both retail armor lines are offered from the SAME vouchers (this server
-- has no second voucher currency): e.g. a DNC/THF head voucher can become
-- either a Meghanada Visor (line 1) or a Mummu Bonnet (line 2). +1
-- vouchers redeem the +1 piece directly; +2 comes from trading the piece
-- + Abdhaljs Metal/Fiber to Gorpa-Masorpa.
--
-- Voucher IDs:
--   Head 9235 / Body 9236 / Hands 9237 / Legs 9238 / Feet 9239
--   Head+1 9240 / Body+1 9241 / Hands+1 9242 / Legs+1 9243 / Feet+1 9244
-----------------------------------
local SYS = xi.msg.channel.SYSTEM_3

local SLOT_NAME     = { 'Head', 'Body', 'Hands', 'Legs', 'Feet' }
local VOUCHER_BASE  = { 9235, 9236, 9237, 9238, 9239 }
local VOUCHER_PLUS1 = { 9240, 9241, 9242, 9243, 9244 }

local function hasVoucher(player, voucherId)
    return player:hasItem(voucherId, xi.inv.INVENTORY)
end

-- Resolve the player's set for a line ('line1' or 'line2').
-- Returns the set table (with .label/.nq/.p1) or nil.
local function setForJob(player, lineKey)
    local jobSets = xi.ambuscade.jobSets[player:getMainJob()]
    local setKey  = jobSets and jobSets[lineKey]
    return setKey and xi.ambuscade.armorSets[setKey] or nil
end

local function doRedeem(player, slotIdx, isPlus1, lineKey)
    local set = setForJob(player, lineKey)
    if not set then
        player:printToPlayer('[Ambuscade] No gear available for your current job.', SYS)
        return false
    end

    local itemId = isPlus1 and set.p1[slotIdx] or set.nq[slotIdx]
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
    player:printToPlayer(string.format('[Ambuscade] Exchanged voucher for %s %s piece (%s).',
        set.label, SLOT_NAME[slotIdx], isPlus1 and '+1' or 'base'), SYS)
    return true
end

local function showSlotMenu(player, isPlus1, lineKey, backFn)
    local set     = setForJob(player, lineKey)
    local options = {}
    local vlist   = isPlus1 and VOUCHER_PLUS1 or VOUCHER_BASE

    for i, slotName in ipairs(SLOT_NAME) do
        local idx    = i
        local hasVch = hasVoucher(player, vlist[i])
        local tag    = (not set and ' (N/A)') or (not hasVch and ' (no vou)') or ''
        options[#options + 1] =
        {
            slotName .. tag,
            function(pp) doRedeem(pp, idx, isPlus1, lineKey); showSlotMenu(pp, isPlus1, lineKey, backFn) end,
        }
    end
    options[#options + 1] = { 'Back', backFn }

    local title = string.format('%s %s', set and set.label or 'Redeem', isPlus1 and '+1' or 'Base')
    local snapshot = { title = title, options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

local function showMainMenu(player)
    local set1 = setForJob(player, 'line1')
    local set2 = setForJob(player, 'line2')
    local l1   = set1 and set1.label or 'Set 1'
    local l2   = set2 and set2.label or 'Set 2'
    local back = function(p) showMainMenu(p) end

    local options =
    {
        { string.format('Base: %s', l1), function(pp) showSlotMenu(pp, false, 'line1', back) end },
        { string.format('+1:   %s', l1), function(pp) showSlotMenu(pp, true,  'line1', back) end },
        { string.format('Base: %s', l2), function(pp) showSlotMenu(pp, false, 'line2', back) end },
        { string.format('+1:   %s', l2), function(pp) showSlotMenu(pp, true,  'line2', back) end },
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
        if hasVoucher(player, vid) then hasAnyVoucher = true break end
    end
    if not hasAnyVoucher then
        for _, vid in ipairs(VOUCHER_PLUS1) do
            if hasVoucher(player, vid) then hasAnyVoucher = true break end
        end
    end
    if not hasAnyVoucher then
        player:printToPlayer('[Ambuscade] You have no vouchers. Gorpa-Masorpa sells them for Hallmarks -- earn those by clearing Ambuscade!', SYS)
        return
    end
    showMainMenu(player)
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
