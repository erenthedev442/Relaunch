-- !augment <gear_item_id> <catalyst_id>[:<qty>] ... [maat]
-- Apply augments to a gear piece in inventory. Server-enforced: must be
-- within 6 yalms of the live Arcane Augment and have talked to / traded
-- him in the last 3 minutes (see augment_trade_guard.lua). The addon UI
-- is not trusted.
-- Catalysts are spent from the Arcane Augmenter bank (same store as the NPC),
-- not from the player's inventory. Gear and Maat's Cap still come from bag 0.
--
-- Used by the AugmentTrade Windower addon (tools/windower/augment_trade/).
-- The addon sends: !augment <gear_id> <cat_id>:<qty> [<cat_id>:<qty> ...] [maat]

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local catalog  = require('modules/custom/lua/augment_catalog')
local sage     = require('modules/custom/lua/augment_sage_catalog')
local affinity = require('modules/custom/lua/augment_affinity_catalog')
local bank     = require('modules/custom/lua/augment_catalyst_bank')
local wh       = require('modules/custom/lua/weekly_hunts')

-- Live Abdhaljs Arcane Augment (dynamic NPC). Name lookup misses him
-- because insertDynamicEntity stores DE_Augment_Moogle.
local AUGMENT_NPC_ID = 16959491
local AUGMENT_ZONE   = 44
local AUGMENT_RANGE  = 6
local AUGMENT_POS    = { x = 571.6949, y = -0.5056, z = 544.0399 }

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
            return 'Talk to the Arcane Augment first, then Trade while standing next to him.'
        end
        return nil
    end
    return nil
end

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

local function takeMaatCap(player, token)
    if not token then
        token = player:findItem(CRIT_TOKEN_ID, 0) or player:findItem(CRIT_TOKEN_LEGACY, 0)
    end
    if not token then
        return false, nil
    end
    local tokenId = token:getID()
    if player:delItemAt(tokenId, 1, 0, token:getSlotID()) then
        return true, tokenId
    end
    token = player:findItem(CRIT_TOKEN_ID, 0) or player:findItem(CRIT_TOKEN_LEGACY, 0)
    if token and player:delItemAt(token:getID(), 1, 0, token:getSlotID()) then
        return true, token:getID()
    end
    return false, nil
end

local NON_AUGMENTABLE = {
    [18987]=true,[19007]=true,[19076]=true,[19096]=true,
    [19628]=true,[19726]=true,[19835]=true,[19964]=true,
    [21262]=true,[21263]=true,[21268]=true,[22141]=true,
}

commandObj.onTrigger = function(player, args)
    if not args or args:match('^%s*$') then
        player:printToPlayer(
            'Usage: !augment <gear_item_id> <catalyst_id>[:<qty>] ... [maat]',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local parts = {}
    for p in args:gmatch('%S+') do table.insert(parts, p) end
    local requestedMaat = #parts > 0 and parts[#parts]:lower() == 'maat'
    if requestedMaat then
        table.remove(parts)
    end

    if #parts < 2 then
        player:printToPlayer(
            'Usage: !augment <gear_item_id> <catalyst_id>[:<qty>] ... [maat]',
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
        local qty          = 1
        if qStr and qStr ~= '' then
            qty = tonumber(qStr)
        end

        if not catId or not qty or qty ~= math.floor(qty) or qty < 1 or qty > MAX_CATALYST_COUNT then
            player:printToPlayer('Invalid catalyst: ' .. raw, xi.msg.channel.SYSTEM_3)
            return
        end
        local def = catalog[catId]
        if not def or not def.augId then
            player:printToPlayer('Unknown catalyst ID ' .. catId .. ' (not in augment catalog).', xi.msg.channel.SYSTEM_3)
            return
        end
        if not catalystCounts[catId] then
            catalystCounts[catId] = 0
            table.insert(catalystOrder, catId)
        end
        catalystCounts[catId] = catalystCounts[catId] + qty
        totalCatalysts         = totalCatalysts + qty
        if totalCatalysts > MAX_CATALYST_COUNT then
            player:printToPlayer(
                string.format('Max %d catalysts per trade (you specified %d).', MAX_CATALYST_COUNT, totalCatalysts),
                xi.msg.channel.SYSTEM_3)
            return
        end
    end

    if totalCatalysts < 1 then
        player:printToPlayer('You must specify at least one catalyst.', xi.msg.channel.SYSTEM_3)
        return
    end
    if requestedMaat and totalCatalysts ~= MAX_CATALYST_COUNT then
        player:printToPlayer(
            "Maat's Cap requires exactly five catalyst slots.",
            xi.msg.channel.SYSTEM_3)
        return
    end

    local function bankQty(balances, itemId)
        return tonumber(balances[itemId] or balances[tostring(itemId)]) or 0
    end

    local bankRequests = {}
    for _, catId in ipairs(catalystOrder) do
        bankRequests[#bankRequests + 1] = { id = catId, qty = catalystCounts[catId] }
    end

    -- Catalysts live on the Arcane Augmenter, not in the player bag.
    local balances = bank.balances(player)
    for _, req in ipairs(bankRequests) do
        local have = bankQty(balances, req.id)
        if have < req.qty then
            local def = catalog[req.id]
            player:printToPlayer(
                string.format('Need %dx %s stored at the Arcane Augmenter (have %d).',
                    req.qty, def and def.label or ('item '..req.id), have),
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
    local critPct       = sage.critChance[rank + 1] or 0.0
    local critTokenItem = requestedMaat and
        (player:findItem(CRIT_TOKEN_ID, 0) or player:findItem(CRIT_TOKEN_LEGACY, 0)) or nil
    local isCrit        = requestedMaat or (math.random() < critPct)
    local rollFloor     = math.min(slice.min + rank, slice.max)
    local crystalPct    = (xi.augmentTiers.crystalChance and xi.augmentTiers.crystalChance[rank]) or 0
    local canCrystalize = bit.band(gear:getFlag(), INSCRIBABLE) == 0
    if requestedMaat and not critTokenItem then
        player:printToPlayer("You do not have Maat's Cap.", xi.msg.channel.SYSTEM_3)
        return
    end
    if requestedMaat and not canCrystalize then
        player:printToPlayer(
            "Maat's Cap cannot crystalize inscribable gear.",
            xi.msg.channel.SYSTEM_3)
        return
    end

    -- Build augment slots
    local exAugsBySlot = {}
    local labelSummary = {}
    local newMask      = 0
    local allPerfect   = true

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
                local target = def.flatValue or xi.augmentTiers.tierFixedValue(def.tierValue, tier, rank)
                roll    = target - base
                slotMax = roll
            else
                local raw = math.random(rollFloor, slice.max)
                if hasAffinity then
                    raw = math.max(raw, math.random(rollFloor, slice.max))
                end
                if isCrit then
                    raw = slice.max
                end
                roll    = xi.augmentTiers.scaleRoll(raw, boostCap, tier, rank)
                slotMax = xi.augmentTiers.scaleRoll(slice.max, boostCap, tier, rank)
            end

            rolls[#rolls + 1] = roll
            exAugsBySlot[#exAugsBySlot + 1] = { id = def.augId, value = roll }
            local canLockRoll = slotMax > 0 or def.flatValue ~= nil
            if not canLockRoll or roll ~= slotMax then
                allPerfect = false
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

    if #exAugsBySlot ~= totalCatalysts then
        player:printToPlayer('Augmentation cancelled: catalyst slot count mismatch.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- One roll governs the whole item. Never create a partial lock mask.
    -- Maat crystalize is armed only after the cap is actually taken below.
    if
        not requestedMaat and
        canCrystalize and
        #exAugsBySlot == MAX_CATALYST_COUNT and
        allPerfect and
        math.random() < crystalPct
    then
        newMask = 0x1F
    end

    local signature = readSignature(gear)
    local extra =
    {
        exdata =
        {
            augmentKind    = xi.augment.kind.HAS_AUGMENTS,
            augmentSubKind = xi.augment.subKind.STANDARD,
            augments       = exAugsBySlot,
        },
    }

    -- Charge gil first so a later failure can refund it. Materials are
    -- taken next; bank.consume is a single DB transaction.
    if not player:delGil(GIL_COST) then
        player:printToPlayer(
            string.format('Need %d gil (you have %d).', GIL_COST, player:getGil()),
            xi.msg.channel.SYSTEM_3)
        return
    end

    if not player:delItemAt(gearId, 1, 0, gear:getSlotID()) then
        player:addGil(GIL_COST)
        player:printToPlayer('The selected gear moved; augmentation cancelled.', xi.msg.channel.SYSTEM_3)
        return
    end

    local tookMaat = false
    local maatId   = nil
    if requestedMaat then
        tookMaat, maatId = takeMaatCap(player, critTokenItem)
        if not tookMaat then
            addHeldGear(player, gearId, signature)
            player:addGil(GIL_COST)
            player:printToPlayer("Maat's Cap moved; augmentation cancelled and gear returned.", xi.msg.channel.SYSTEM_3)
            return
        end
        newMask = 0x1F
    end

    if not bank.consume(player, bankRequests) then
        addHeldGear(player, gearId, signature)
        if tookMaat and maatId then
            player:addItem({ id = maatId, quantity = 1 })
        end
        player:addGil(GIL_COST)
        player:printToPlayer('Stored catalyst consumption failed; items were returned.', xi.msg.channel.SYSTEM_3)
        return
    end

    local augmented = addHeldGear(player, gearId, signature, extra)
    if not augmented then
        addHeldGear(player, gearId, signature)
        bank.refund(player, bankRequests)
        if tookMaat and maatId then
            player:addItem({ id = maatId, quantity = 1 })
        end
        player:addGil(GIL_COST)
        player:printToPlayer('Augmentation failed - items returned, no gil charged.', xi.msg.channel.SYSTEM_3)
        return
    end

    local lockStamped = true
    if newMask ~= 0 then
        local ok, err = pcall(function()
            augmented:setExDataRaw({ [SIG_HEAD_BYTE] = 0, [LOCK_MASK_BYTE] = newMask })
        end)
        lockStamped = ok
        if not ok then
            print(string.format('[augment] lock-mask stamp failed for %s item %d: %s',
                player:getName(), gearId, tostring(err)))
            if tookMaat and maatId then
                player:addItem({ id = maatId, quantity = 1 })
                tookMaat = false
            end
        end
    end

    if tookMaat then
        player:printToPlayer(
            "Maat's Cap consumed: all five perfect augment slots are crystalized.",
            xi.msg.channel.SYSTEM_3)
    elseif requestedMaat then
        player:printToPlayer(
            "The crystalization stamp failed, so Maat's Cap was not consumed.",
            xi.msg.channel.SYSTEM_3)
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
    if newMask == 0x1F and lockStamped then
        player:printToPlayer(
            string.format('%s CRYSTALIZED: all five perfect augment slots are locked.', xi.icon.STAR_LARGE),
            xi.msg.channel.SYSTEM_3)
    end
    player:printToPlayer(
        string.format('[AUGDONE]Applied: [%s] (-10,000 gil)', table.concat(labelSummary, '] [')),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
