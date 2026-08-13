-- !augment <gear_item_id> <catalyst_id>[:<qty>] ...
-- Bypass the Augment Moogle — apply augments to a gear piece in inventory.
-- Replicates the Moogle's content-tier bands, mastery floor, affinity,
-- critical roll, crystalize chance, 10k gil cost, and completion hooks.
--
-- Used by the AugmentTrade Windower addon (tools/windower/augment_trade/).
-- The addon sends: !augment <gear_id> <cat_id>:<qty> [<cat_id>:<qty> ...]

local cmdprops = {
    permission = 0,
    parameters = 'true',
    help       = '!augment <gear_item_id> <catalyst_id>[:<qty>] ...',
}

local catalog  = require('modules/custom/lua/augment_catalog')
local sage     = require('modules/custom/lua/augment_sage_catalog')
local affinity = require('modules/custom/lua/augment_affinity_catalog')
local wh       = require('modules/custom/lua/weekly_hunts')

local MAX_CATALYST_COUNT = 5
local GIL_COST           = 10000
local CRIT_TOKEN_ID      = 15194
local CRIT_TOKEN_LEGACY  = 29000
local EXDATA_VALUE_MAX   = 31

local LOCK_MASK_BYTE = 13
local SIG_HEAD_BYTE  = 12
local INSCRIBABLE    = 0x20
local LAST_RECIPE_COUNT_VAR = 'Augment_LastRecipe_Count'
local LAST_RECIPE_ID_VAR    = 'Augment_LastRecipe_Id_'
local LAST_RECIPE_QTY_VAR   = 'Augment_LastRecipe_Qty_'

local NON_AUGMENTABLE = {
    [18987]=true,[19007]=true,[19076]=true,[19096]=true,
    [19628]=true,[19726]=true,[19835]=true,[19964]=true,
    [21262]=true,[21263]=true,[21268]=true,[22141]=true,
}

cmdprops.exec = function(player, args)
    if not args or args:match('^%s*$') then
        player:printToPlayer(
            'Usage: !augment <gear_item_id> <catalyst_id>[:<qty>] ...',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local parts = {}
    for p in args:gmatch('%S+') do table.insert(parts, p) end

    if #parts < 2 then
        player:printToPlayer(
            'Usage: !augment <gear_item_id> <catalyst_id>[:<qty>] ...',
            xi.msg.channel.SYSTEM_3)
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
        player:printToPlayer('Only weapons and armor can be augmented.', xi.msg.channel.SYSTEM_3)
        return
    end

    for slot = 0, 4 do
        local existing = gear:getAugment(slot)
        if existing and existing[1] ~= 0 then
            player:printToPlayer(
                'That item is already augmented. Use the Arcane Augmenter so crystalized lines are preserved safely.',
                xi.msg.channel.SYSTEM_3)
            return
        end
    end

    if NON_AUGMENTABLE[gearId] then
        player:printToPlayer('That weapon cannot be augmented (fixed-stat Mythic/Relic weapon).', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Parse catalyst list
    local catalystOrder  = {}
    local catalystCounts = {}
    local totalCatalysts = 0

    for i = 2, #parts do
        local raw          = parts[i]
        local catStr, qStr = raw:match('^(%d+):?(%d*)$')
        local catId        = tonumber(catStr)
        local qty          = tonumber(qStr)
        if not qty or qty < 1 then qty = 1 end

        if not catId then
            player:printToPlayer('Invalid catalyst: ' .. raw, xi.msg.channel.SYSTEM_3)
            return
        end
        if not catalog[catId] then
            player:printToPlayer('Unknown catalyst ID ' .. catId .. ' (not in augment catalog).', xi.msg.channel.SYSTEM_3)
            return
        end
        if not catalystCounts[catId] then
            catalystCounts[catId] = 0
            table.insert(catalystOrder, catId)
        end
        catalystCounts[catId] = catalystCounts[catId] + qty
        totalCatalysts         = totalCatalysts + qty
    end

    if totalCatalysts > MAX_CATALYST_COUNT then
        player:printToPlayer(
            string.format('Max %d catalysts per trade (you specified %d).', MAX_CATALYST_COUNT, totalCatalysts),
            xi.msg.channel.SYSTEM_3)
        return
    end

    local function inventoryQuantity(itemId)
        local total = 0
        for _, item in ipairs(player:findItems(itemId, 0) or {}) do
            total = total + (item:getQuantity() or 0)
        end
        return total
    end

    -- Verify player holds all catalysts in main inventory.
    for _, catId in ipairs(catalystOrder) do
        local need = catalystCounts[catId]
        local have = inventoryQuantity(catId)
        if have < need then
            local def = catalog[catId]
            player:printToPlayer(
                string.format('Need %dx %s (have %d).', need, def and def.label or ('item '..catId), have),
                xi.msg.channel.SYSTEM_3)
            return
        end
    end

    if player:getGil() < GIL_COST then
        player:printToPlayer(
            string.format('Need %d gil (you have %d).', GIL_COST, player:getGil()),
            xi.msg.channel.SYSTEM_3)
        return
    end

    if not xi.augmentTiers or not xi.augmentTiers.tierOf then
        player:printToPlayer('The Augment Tier service is unavailable. Use the Arcane Augmenter.', xi.msg.channel.SYSTEM_3)
        return
    end

    local tier  = xi.augmentTiers.tierOf(player)
    local slice = xi.augmentTiers.slices[tier]
    if tier < 1 or not slice then
        player:printToPlayer('Augmenting is locked until you unlock Augment Tier 1.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Content-tier gates (Sage rank affects floor/crit, not catalyst access).
    local rank = player:getCharVar('Augment_Mastery') or 0
    for _, catId in ipairs(catalystOrder) do
        local def  = catalog[catId]
        local need = def and (def.tier or 0) or 0
        if need > tier then
            player:printToPlayer(
                string.format('[%s] requires Augment Tier %d. Your tier: %d.',
                    def.label, need, tier),
                xi.msg.channel.SYSTEM_3)
            return
        end
        if (def.tierValue or def.flatValue) and catalystCounts[catId] > 1 then
            player:printToPlayer(
                string.format('[%s] is single-line; use one catalyst.', def.label),
                xi.msg.channel.SYSTEM_3)
            return
        end
    end

    -- Roll once per trade; affinity rolls each individual slot twice.
    local critPct       = sage.critChance[rank + 1]  or 0.0
    local critTokenItem = player:findItem(CRIT_TOKEN_ID, 0) or player:findItem(CRIT_TOKEN_LEGACY, 0)
    local usedCritToken = critTokenItem ~= nil
    local isCrit        = usedCritToken or (math.random() < critPct)
    local rollFloor     = math.min(slice.min + rank, slice.max)
    local crystalPct    = (xi.augmentTiers.crystalChance and xi.augmentTiers.crystalChance[rank]) or 0
    local canCrystalize = bit.band(gear:getFlag(), INSCRIBABLE) == 0

    -- Build augment slots
    local exAugsBySlot = {}
    local labelSummary = {}
    local crystalNews  = {}
    local newMask      = 0

    for _, catId in ipairs(catalystOrder) do
        local def   = catalog[catId]
        local count = catalystCounts[catId]
        local base  = def.base or 0
        local mult  = (def.mult and def.mult > 1) and def.mult or 1
        local disp  = (def.disp and def.disp > 1) and def.disp or 1

        local boostCap      = def.maxBoost and math.min(EXDATA_VALUE_MAX, def.maxBoost) or EXDATA_VALUE_MAX
        local hasAffinity   = def.cat and affinity.hasAffinity(player, def.cat) or false
        local rolls         = {}
        local slotMax
        for _ = 1, count do
            local roll
            if def.tierValue or def.flatValue then
                local target = def.flatValue or (def.tierValue * tier)
                local final  = def.flatValue or (def.tierValue * #xi.augmentTiers.slices)
                roll    = target - base
                slotMax = final - base
            else
                local raw = math.random(rollFloor, slice.max)
                if hasAffinity then
                    raw = math.max(raw, math.random(rollFloor, slice.max))
                end
                if isCrit then
                    raw = slice.max
                end
                roll    = xi.augmentTiers.scaleRoll(raw, boostCap, tier)
                slotMax = xi.augmentTiers.scaleRoll(slice.max, boostCap, tier)
            end

            rolls[#rolls + 1] = roll
            exAugsBySlot[#exAugsBySlot + 1] = { id = def.augId, value = roll }
            local slotIndex0 = #exAugsBySlot - 1
            local canLockRoll = slotMax > 0 or def.flatValue ~= nil
            if canCrystalize and canLockRoll and roll == slotMax and math.random() < crystalPct then
                newMask = bit.bor(newMask, bit.lshift(1, slotIndex0))
                crystalNews[#crystalNews + 1] = def.label
            end
        end

        local total = 0
        for _, roll in ipairs(rolls) do
            total = total + math.floor((base + roll) * mult / disp + 0.5)
        end
        local valStr     = count > 1
            and string.format('->%d total (%d slots)', total, count)
            or  string.format('->%d', total)
        local boostStr   = boostCap > 0
            and string.format(' [T%d boost %s/%d]', tier, table.concat(rolls, ','), boostCap) or ''
        table.insert(labelSummary, string.format('%s %s%s', def.label, valStr, boostStr))
    end

    local function takeFromInventory(itemId, quantity)
        local remaining = quantity
        local plan = {}
        for _, item in ipairs(player:findItems(itemId, 0) or {}) do
            plan[#plan + 1] = { slot = item:getSlotID(), qty = item:getQuantity() }
        end
        for _, entry in ipairs(plan) do
            if remaining <= 0 then break end
            local take = math.min(entry.qty, remaining)
            if take > 0 and player:delItemAt(itemId, take, 0, entry.slot) then
                remaining = remaining - take
            end
        end
        return quantity - remaining
    end

    -- Consume the exact base gear, then catalysts from main-inventory stacks.
    if not player:delItemAt(gearId, 1, 0, gear:getSlotID()) then
        player:printToPlayer('The selected gear moved; augmentation cancelled.', xi.msg.channel.SYSTEM_3)
        return
    end
    local consumed = {}
    for _, catId in ipairs(catalystOrder) do
        local qty = catalystCounts[catId]
        local removed = takeFromInventory(catId, qty)
        if removed ~= qty then
            player:addItem({ id = gearId, quantity = 1 })
            for _, row in ipairs(consumed) do
                player:addItem({ id = row.id, quantity = row.qty })
            end
            if removed > 0 then
                player:addItem({ id = catId, quantity = removed })
            end
            player:printToPlayer('Catalyst consumption failed; consumed items were returned.', xi.msg.channel.SYSTEM_3)
            return
        end
        consumed[#consumed + 1] = { id = catId, qty = qty }
    end

    -- Add augmented gear
    local augmented = player:addItem({
        id     = gearId,
        exdata = {
            augmentKind    = xi.augment.kind.HAS_AUGMENTS,
            augmentSubKind = xi.augment.subKind.STANDARD,
            augments       = exAugsBySlot,
        },
    })

    if not augmented then
        -- Restore everything on engine failure
        player:addItem({ id=gearId, quantity=1 })
        for _, catId in ipairs(catalystOrder) do
            player:addItem({ id=catId, quantity=catalystCounts[catId] })
        end
        player:printToPlayer('Augmentation failed - items returned, no gil charged.', xi.msg.channel.SYSTEM_3)
        return
    end

    if newMask ~= 0 then
        local ok, err = pcall(function()
            augmented:setExDataRaw({ [SIG_HEAD_BYTE] = 0, [LOCK_MASK_BYTE] = newMask })
        end)
        if not ok then
            print(string.format('[augment] lock-mask stamp failed for %s item %d: %s',
                player:getName(), gearId, tostring(err)))
        end
    end

    -- Charge gil and consume crit token
    player:delGil(GIL_COST)
    if usedCritToken then
        player:delItemAt(critTokenItem:getID(), 1, 0, critTokenItem:getSlotID())
        player:printToPlayer("Maat's Cap consumed to force a perfect roll.", xi.msg.channel.SYSTEM_3)
    end

    -- Increment augment counter + fire hooks
    local prev = player:getCharVar('Augment_Count') or 0
    player:setCharVar('Augment_Count', prev + 1)
    player:setCharVar(LAST_RECIPE_COUNT_VAR, #catalystOrder)
    for i = 1, MAX_CATALYST_COUNT do
        local catId = catalystOrder[i]
        player:setCharVar(LAST_RECIPE_ID_VAR .. i, catId or 0)
        player:setCharVar(LAST_RECIPE_QTY_VAR .. i, catId and catalystCounts[catId] or 0)
    end
    local achOk, achErr = pcall(function()
        require('modules/custom/lua/achievements').onAugmentTrade(player)
    end)
    if not achOk then
        print(string.format('[augment] achievement hook failed for %s: %s',
            player:getName(), tostring(achErr)))
    end
    local huntOk, huntErr = pcall(function()
        wh.fire(player, 'augment_done', { isCrit=isCrit })
    end)
    if not huntOk then
        print(string.format('[augment] weekly-hunt hook failed for %s: %s',
            player:getName(), tostring(huntErr)))
    end

    -- Success feedback (intercepted by AugmentTrade addon)
    if isCrit then
        player:printToPlayer('** Critical augment! ** Every catalyst rolled its tier maximum!', xi.msg.channel.SYSTEM_3)
    end
    for _, label in ipairs(crystalNews) do
        player:printToPlayer(string.format('%s CRYSTALIZED: [%s]', xi.icon.STAR_LARGE, label),
            xi.msg.channel.SYSTEM_3)
    end
    player:printToPlayer(
        string.format('[AUGDONE]Applied: [%s] (-10,000 gil)', table.concat(labelSummary, '] [')),
        xi.msg.channel.SYSTEM_3)
end

return cmdprops
