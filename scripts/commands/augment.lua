-- !augment <gear_item_id> <catalyst_id>[:<qty>] ...
-- Bypass the Augment Moogle — apply augments to a gear piece in inventory.
-- Replicates the full moogle trade logic: rank gates, mastery/affinity/crit
-- boosts, 10k gil cost, Augment_Count increment, achievement + weekly hunt hooks.
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

local RANK_NAMES = { 'Unranked', 'Initiate', 'Adept', 'Magus', 'Sage', 'Archon' }

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

    if player:getItemCount(gearId) < 1 then
        player:printToPlayer('You do not have that gear piece in your inventory.', xi.msg.channel.SYSTEM_3)
        return
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

    -- Verify player holds all catalysts
    for _, catId in ipairs(catalystOrder) do
        local need = catalystCounts[catId]
        local have = player:getItemCount(catId)
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

    if player:getFreeSlotsCount() == 0 then
        player:printToPlayer('Inventory full! Free a slot first.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Rank gates
    local rank = player:getCharVar('Augment_Mastery') or 0
    for _, catId in ipairs(catalystOrder) do
        local def  = catalog[catId]
        local need = def and (def.tier or 0) or 0
        if need > rank then
            local needName = RANK_NAMES[need + 1] or ('rank ' .. need)
            local haveName = RANK_NAMES[rank + 1] or ('rank ' .. rank)
            player:printToPlayer(
                string.format('[%s] requires Sage rank %d (%s). Your rank: %d (%s).',
                    def.label, need, needName, rank, haveName),
                xi.msg.channel.SYSTEM_3)
            return
        end
    end

    -- Crit roll (mirrors moogle exactly)
    local masteryMult   = sage.masteryMult[rank + 1] or 1.0
    local critPct       = sage.critChance[rank + 1]  or 0.0
    local usedCritToken = player:getItemCount(CRIT_TOKEN_ID) > 0 or player:getItemCount(CRIT_TOKEN_LEGACY) > 0
    local isCrit        = usedCritToken or (math.random() < critPct)
    local critMult      = isCrit and 2.0 or 1.0

    -- Build augment slots
    local exAugsBySlot = {}
    local labelSummary = {}

    for _, catId in ipairs(catalystOrder) do
        local def   = catalog[catId]
        local count = catalystCounts[catId]
        local base  = def.base or 0
        local mult  = (def.mult and def.mult > 1) and def.mult or 1
        local disp  = (def.disp and def.disp > 1) and def.disp or 1

        local affMult   = (def.cat and affinity.hasAffinity(player, def.cat))
            and affinity.affinityMult or 1.0
        local totalMult = masteryMult * affMult * critMult

        local maxTotalMult  = (sage.masteryMult[#sage.masteryMult] or 2.0)
                                * (affinity.affinityMult or 1.5) * 2.0
        local progress      = (maxTotalMult > 1) and ((totalMult - 1) / (maxTotalMult - 1)) or 0
        local rawExdata     = math.floor(progress * EXDATA_VALUE_MAX + 0.5)
        local boostCap      = def.maxBoost and math.min(EXDATA_VALUE_MAX, def.maxBoost) or EXDATA_VALUE_MAX
        local perSlotExdata = math.min(math.max(rawExdata, 0), boostCap)

        for _ = 1, count do
            table.insert(exAugsBySlot, { id=def.augId, value=perSlotExdata })
        end

        local perSlotVal = math.floor((base + perSlotExdata) * mult / disp + 0.5)
        local valStr     = count > 1
            and string.format('->%d/slot x%d=%d', perSlotVal, count, perSlotVal * count)
            or  string.format('->%d', perSlotVal)
        local boostStr   = boostCap > 0
            and string.format(' [boost %d/%d]', perSlotExdata, boostCap) or ''
        table.insert(labelSummary, string.format('%s %s%s', def.label, valStr, boostStr))
    end

    -- Consume gear + catalysts
    player:delItem(gearId, 1)
    for _, catId in ipairs(catalystOrder) do
        player:delItem(catId, catalystCounts[catId])
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

    -- Charge gil and consume crit token
    player:delGil(GIL_COST)
    if usedCritToken then
        local token = player:getItemCount(CRIT_TOKEN_ID) > 0 and CRIT_TOKEN_ID or CRIT_TOKEN_LEGACY
        player:delItem(token, 1)
        player:printToPlayer("Maat's Cap consumed by the augment's power.", xi.msg.channel.SYSTEM_3)
    end

    -- Increment augment counter + fire hooks
    local prev = player:getCharVar('Augment_Count') or 0
    player:setCharVar('Augment_Count', prev + 1)
    local ach = require('modules/custom/lua/achievements')
    ach.onAugmentTrade(player)
    wh.fire(player, 'augment_done', { isCrit=isCrit })

    -- Success feedback (intercepted by AugmentTrade addon)
    if isCrit then
        player:printToPlayer('** Critical augment! ** Catalyst potency doubled!', xi.msg.channel.SYSTEM_3)
    end
    player:printToPlayer(
        string.format('[AUGDONE]Applied: [%s] (-10,000 gil)', table.concat(labelSummary, '] [')),
        xi.msg.channel.SYSTEM_3)
end

return cmdprops
