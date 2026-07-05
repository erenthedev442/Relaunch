-----------------------------------
-- func: reroll
-- desc: Gamble-reroll the augment magnitudes on an EQUIPPED item.
--
--   !reroll <slot>          -> preview: shows current lines, cost, odds
--   !reroll <slot> confirm  -> commit the reroll (charges gil + 1 catalyst)
--
-- Keeps the item's existing augment TYPES and re-rolls each line's magnitude
-- over the player's current tier band, RANK-FLOOR PROTECTED:
--   band  = TIER_SLICES[playerTier]           (your Augment Tier's 5-bit slice)
--   floor = min(band.min + Augment_Mastery, band.max)
--   roll  = random(floor .. band.max)         (per line)
--   affinity match -> roll twice, keep the better   (Sage affinity)
--   crit (sage.critChance by rank) -> band.max = PERFECT roll (whole reroll)
-- The new roll REPLACES the old, so it can go up or down -- but never below
-- your mastery floor. No power creep: capped at the tier-band ceiling, exactly
-- like the Augment Moogle.
--
-- Cost: gil (scales by tier) + 1 catalyst matching one of the item's augments.
--
-- Write path: exdata is patched in place via setExDataRaw (there is no Lua
-- setAugment binding), matching the AugmentStandard layout:
--   struct Augment { uint16 Id:11; uint16 Value:5; }  -> word = id + value*2048
--   Augments[5] start at exdata offset 2 (after the 2-byte AugmentKind).
-- After patching we unequipItem(slot) so the client/server re-applies the
-- fresh mods when the player re-equips (see scripts/commands/delnegdmg.lua).
-----------------------------------
local catalog  = require('modules/custom/lua/augment_catalog')
local affinity = require('modules/custom/lua/augment_affinity_catalog')
local sage     = require('modules/custom/lua/augment_sage_catalog')

local CHANNEL          = xi.msg.channel.SYSTEM_3
local EXDATA_VALUE_MAX = 31

-- Tier bands (mirror Augment_Moogle.lua TIER_SLICES). Kept local so the
-- command works even before the Moogle module has published xi.augmentTiers.
local TIER_SLICES =
{
    { min =  0, max =  5 },   -- T1
    { min =  6, max = 11 },   -- T2
    { min = 12, max = 17 },   -- T3
    { min = 18, max = 24 },   -- T4
    { min = 25, max = 31 },   -- T5
}

-- Gil cost per reroll, indexed by Augment Tier (1-5).
local GIL_BY_TIER = { 25000, 50000, 100000, 175000, 250000 }

-- augId -> def reverse map (the catalog is keyed by catalyst itemId).
local byAug = {}
for catId, def in pairs(catalog) do
    if type(def) == 'table' and def.augId and byAug[def.augId] == nil then
        byAug[def.augId] =
        {
            catId    = catId,
            cat      = def.cat,
            label    = def.label or ('#' .. tostring(def.augId)),
            maxBoost = def.maxBoost,
        }
    end
end

-- Equipment slot names -> equip slot index (0-15).
local SLOTS =
{
    main = 0, sub = 1, ranged = 2, range = 2, ammo = 3,
    head = 4, body = 5, hands = 6, legs = 7, feet = 8,
    neck = 9, waist = 10, ear1 = 11, ear2 = 12,
    ring1 = 13, ring2 = 14, back = 15,
}

local function playerTier(player)
    if xi.augmentTiers and xi.augmentTiers.tierOf then
        return xi.augmentTiers.tierOf(player)
    end
    return 0
end

local function critChance(rank)
    return (sage.critChance and sage.critChance[rank + 1]) or 0
end

local commandObj = {}
commandObj.cmdprops = { permission = 0, parameters = 'ss' }

commandObj.onTrigger = function(player, slotArg, confirmArg)
    -- Resolve the equip slot.
    local slot
    if slotArg ~= nil then
        slot = SLOTS[tostring(slotArg):lower()] or tonumber(slotArg)
    end
    if slot == nil or slot < 0 or slot > 15 then
        player:printToPlayer('Usage: !reroll <slot> [confirm]', CHANNEL)
        player:printToPlayer('  slot: main sub ranged ammo head body hands legs feet neck waist ear1 ear2 ring1 ring2 back', CHANNEL)
        return
    end

    local item = player:getEquippedItem(slot)
    if item == nil then
        player:printToPlayer('[Reroll] Nothing is equipped in that slot.', CHANNEL)
        return
    end

    -- Collect occupied augment slots (each rolls independently).
    local lines = {}
    for augSlot = 0, 4 do
        local a = item:getAugment(augSlot)
        if a[1] ~= 0 then
            lines[#lines + 1] = { augSlot = augSlot, augId = a[1], oldVal = a[2], def = byAug[a[1]] }
        end
    end
    if #lines == 0 then
        player:printToPlayer('[Reroll] That item has no augments to reroll.', CHANNEL)
        return
    end

    local tier = playerTier(player)
    if tier < 1 then
        player:printToPlayer('[Reroll] You have not unlocked augmenting yet (Augment Tier 0).', CHANNEL)
        return
    end

    local rank     = player:getCharVar('Augment_Mastery') or 0
    local slice    = TIER_SLICES[tier] or TIER_SLICES[1]
    local rollFloor = math.min(slice.min + rank, slice.max)
    local gilCost  = GIL_BY_TIER[tier] or GIL_BY_TIER[#GIL_BY_TIER]

    -- Find one catalyst the player holds that matches one of the item's lines.
    local payCatId, payCatName
    for _, ln in ipairs(lines) do
        if ln.def and ln.def.catId and player:getItemCount(ln.def.catId) > 0 then
            payCatId   = ln.def.catId
            payCatName = ln.def.label
            break
        end
    end

    -- PREVIEW (anything other than an explicit "confirm").
    if tostring(confirmArg or ''):lower() ~= 'confirm' then
        player:printToPlayer(string.format('[Reroll] %s  (Tier %d band %d-%d, floor %d, crit %d%%)',
            item:getName(), tier, slice.min, slice.max, rollFloor, math.floor(critChance(rank) * 100)), CHANNEL)
        for _, ln in ipairs(lines) do
            local lbl = ln.def and ln.def.label or ('#' .. tostring(ln.augId))
            player:printToPlayer(string.format('  %s : %d  ->  will roll %d-%d', lbl, ln.oldVal, rollFloor, slice.max), CHANNEL)
        end
        player:printToPlayer(string.format('Cost: %d gil + 1 catalyst. Rank-floor protected (never below %d).', gilCost, rollFloor), CHANNEL)
        if payCatId then
            player:printToPlayer(string.format('Consumes 1x %s.  Type  !reroll %s confirm  to gamble.', payCatName, tostring(slotArg)), CHANNEL)
        else
            player:printToPlayer('You hold no catalyst matching this item -- reroll is blocked.', CHANNEL)
        end
        return
    end

    -- CONFIRM: validate cost.
    if payCatId == nil then
        player:printToPlayer('[Reroll] You need a catalyst matching one of this item\'s augments.', CHANNEL)
        return
    end
    if player:getGil() < gilCost then
        player:printToPlayer(string.format('[Reroll] You need %d gil (you have %d).', gilCost, player:getGil()), CHANNEL)
        return
    end

    -- Crit is rolled once and applies to every line this reroll.
    local isCrit = math.random() < critChance(rank)

    -- Roll + write each line.
    local summary = {}
    for _, ln in ipairs(lines) do
        local hasAff = (ln.def and ln.def.cat and affinity.hasAffinity(player, ln.def.cat)) or false
        local cap    = (ln.def and ln.def.maxBoost) and math.min(EXDATA_VALUE_MAX, ln.def.maxBoost) or EXDATA_VALUE_MAX

        local r = math.random(rollFloor, slice.max)
        if hasAff then
            r = math.max(r, math.random(rollFloor, slice.max))
        end
        if isCrit then
            r = slice.max
        end
        r = math.min(r, cap)

        -- Pack: Augment { Id:11 | Value:5 } -> word = id + value*2048.
        local word = ln.augId + r * 2048
        local b    = 2 + ln.augSlot * 2
        item:setExDataRaw({ [b] = word % 256, [b + 1] = math.floor(word / 256) })

        summary[#summary + 1] = { lbl = (ln.def and ln.def.label) or ('#' .. tostring(ln.augId)), old = ln.oldVal, new = r }
    end

    -- Charge.
    player:delGil(gilCost)
    player:delItem(payCatId, 1)

    -- Force a fresh mod application: drop the item to inventory so re-equipping
    -- re-reads the patched exdata (there is no in-place mod-refresh binding).
    pcall(function() player:unequipItem(slot) end)

    -- Report.
    player:printToPlayer(string.format('[Reroll]%s %s reforged for %d gil + 1x %s:',
        isCrit and ' *CRITICAL!*' or '', item:getName(), gilCost, payCatName), CHANNEL)
    for _, s in ipairs(summary) do
        local arrow = (s.new > s.old) and '^ up' or ((s.new < s.old) and 'v down' or '= same')
        player:printToPlayer(string.format('  %s : %d -> %d   (%s)', s.lbl, s.old, s.new, arrow), CHANNEL)
    end
    player:printToPlayer('Re-equip the item to apply the new augments.', CHANNEL)
end

return commandObj
