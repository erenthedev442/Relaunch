-----------------------------------
-- func: reroll
-- desc: Gamble-reroll the augment magnitudes on an EQUIPPED item.
--
--   !reroll <slot>          -> preview: shows current lines, cost, odds
--   !reroll <slot> confirm  -> commit the reroll (charges Infamy)
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
-- Cost: Infamy (scales by tier). Purely Infamy -- no gil, no catalyst.
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

-- Retired custom augments remain on grandfathered equipment until the next
-- wipe/scour, but must never be rerolled through the uncatalogued fallback.
local RETIRED_AUGMENTS =
{
    [368] = 'Phalanx Received',
}

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

-- Infamy cost per reroll, indexed by Augment Tier (1-5). PURELY INFAMY now --
-- no gil, no catalyst (owner request 2026-07-06): rerolling high-tier augments
-- is gated entirely behind farming Infamy. Tune to your Infamy economy.
local INFAMY_CV      = 'Infamy'
local INFAMY_BY_TIER = { 50, 100, 200, 350, 500 }

-- CRYSTALIZED AUGMENTS (mirror Augment_Moogle.lua). The lock bitmask lives in
-- exdata byte 13 (byte 12 stays 0 for a blank-decoding signature). Only masks
-- 0x00 and 0x1F are valid: a complete five-line perfect result gets one
-- Augment Sage-rank roll to lock the whole item.
local LOCK_MASK_BYTE = 13
local SIG_HEAD_BYTE  = 12
local INSCRIBABLE    = 0x20   -- ItemFlag::INSCRIBABLE (mask can't persist there)
local CRYSTAL_CHANCE = { [0] = 0.00, [1] = 0.05, [2] = 0.15, [3] = 0.30, [4] = 0.45, [5] = 0.50 }

-- Read the lock bitmask + crystalize-eligibility off an item. Inscribable gear
-- can't hold a persistent mask (its signature bytes are re-encoded on load), so
-- crystalize is disabled there.
local function crystalState(item)
    local canCrystalize = true
    if item.getFlag then
        local ok, flags = pcall(function() return item:getFlag() end)
        if ok and flags and bit.band(flags, INSCRIBABLE) ~= 0 then
            canCrystalize = false
        end
    end
    local mask = 0
    if canCrystalize and item.getExDataRaw then
        local ok, raw = pcall(function() return item:getExDataRaw() end)
        if ok and raw then
            mask = bit.band(raw[LOCK_MASK_BYTE] or 0, 0x1F)
        end
    end
    return mask, canCrystalize
end

-- augId -> def reverse map (the catalog is keyed by catalyst itemId).
local byAug = {}
for catId, def in pairs(catalog) do
    if type(def) == 'table' and def.augId and byAug[def.augId] == nil then
        byAug[def.augId] =
        {
            catId    = catId,
            cat      = def.cat,
            label    = def.label or ('#' .. tostring(def.augId)),
            base     = def.base or 0,
            maxBoost = def.maxBoost,
            tierValue = def.tierValue,
            flatValue = def.flatValue,
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

    -- Collect occupied augment slots (each rolls independently). Crystalized
    -- slots (mask bit set) are flagged so they're preserved, not re-rolled.
    local lockMask, canCrystalize = crystalState(item)
    local originalLockMask = lockMask
    local clearedPartialMask = lockMask ~= 0 and lockMask ~= 0x1F
    if clearedPartialMask then
        lockMask = 0
    end
    local lines = {}
    local rerollable = 0
    for augSlot = 0, 4 do
        local a = item:getAugment(augSlot)
        if a[1] ~= 0 then
            local locked  = bit.band(lockMask, bit.lshift(1, augSlot)) ~= 0
            local retired = RETIRED_AUGMENTS[a[1]] ~= nil
            lines[#lines + 1] =
            {
                augSlot = augSlot,
                augId   = a[1],
                oldVal  = a[2],
                def     = byAug[a[1]],
                locked  = locked,
                retired = retired,
            }
            if not locked and not retired then rerollable = rerollable + 1 end
        end
    end
    if #lines == 0 then
        player:printToPlayer('[Reroll] That item has no augments to reroll.', CHANNEL)
        return
    end
    if rerollable == 0 then
        player:printToPlayer('[Reroll] This item has no rerollable augments. Retired and crystalized lines are preserved.', CHANNEL)
        return
    end

    local tier = playerTier(player)
    if tier < 1 then
        player:printToPlayer('[Reroll] You have not unlocked augmenting yet (Augment Tier 0).', CHANNEL)
        return
    end

    local rank       = player:getCharVar('Augment_Mastery') or 0
    local slice      = TIER_SLICES[tier] or TIER_SLICES[1]
    local rollFloor  = math.min(slice.min + rank, slice.max)
    local infamyCost = INFAMY_BY_TIER[tier] or INFAMY_BY_TIER[#INFAMY_BY_TIER]
    local haveInfamy = player:getCharVar(INFAMY_CV) or 0

    -- PREVIEW (anything other than an explicit "confirm").
    if tostring(confirmArg or ''):lower() ~= 'confirm' then
        player:printToPlayer(string.format('[Reroll] %s  (Tier %d band %d-%d, floor %d, crit %d%%)',
            item:getName(), tier, slice.min, slice.max, rollFloor, math.floor(critChance(rank) * 100)), CHANNEL)
        for _, ln in ipairs(lines) do
            local lbl = RETIRED_AUGMENTS[ln.augId] or (ln.def and ln.def.label) or ('#' .. tostring(ln.augId))
            if ln.locked then
                player:printToPlayer(string.format('  %s : %d  ->  CRYSTALIZED (locked, kept)', lbl, ln.oldVal), CHANNEL)
            elseif ln.retired then
                player:printToPlayer(string.format('  %s : %d  ->  RETIRED (kept, cannot reroll)', lbl, ln.oldVal), CHANNEL)
            elseif ln.def and (ln.def.tierValue or ln.def.flatValue) then
                local target = ln.def.flatValue or (ln.def.tierValue * tier)
                player:printToPlayer(string.format('  %s : %d  ->  tier-fixed at +%d (Augment Tier %d)', lbl, ln.oldVal, target, tier), CHANNEL)
            else
                player:printToPlayer(string.format('  %s : %d  ->  will roll %d-%d', lbl, ln.oldVal, rollFloor, slice.max), CHANNEL)
            end
        end
        if clearedPartialMask then
            player:printToPlayer(
                'Legacy partial crystalization will be cleared on confirmation; current values remain the preview baseline.',
                CHANNEL)
        end
        if canCrystalize and (CRYSTAL_CHANCE[rank] or 0) > 0 then
            player:printToPlayer(string.format('A complete five-line perfect result crystalizes as one item at %d%% (Sage rank %d).', math.floor((CRYSTAL_CHANCE[rank] or 0) * 100), rank), CHANNEL)
        end
        player:printToPlayer(string.format('Cost: %d Infamy (you have %d). Rank-floor protected (never below %d).', infamyCost, haveInfamy, rollFloor), CHANNEL)
        player:printToPlayer(string.format('Type  !reroll %s confirm  to gamble.', tostring(slotArg)), CHANNEL)
        return
    end

    -- CONFIRM: validate cost (purely Infamy).
    if haveInfamy < infamyCost then
        player:printToPlayer(string.format('[Reroll] You need %d Infamy (you have %d).', infamyCost, haveInfamy), CHANNEL)
        return
    end

    -- Crit is rolled once and applies to every non-locked line this reroll.
    local isCrit     = math.random() < critChance(rank)
    local crystalPct = canCrystalize and (CRYSTAL_CHANCE[rank] or 0) or 0

    -- Roll + write each line. Crystalization is evaluated once after all five
    -- lines are known, so this command can only persist mask 0x00 or 0x1F.
    local summary     = {}
    local newMask     = 0
    local allPerfect  = true
    for _, ln in ipairs(lines) do
        if ln.locked or ln.retired then
            local label = RETIRED_AUGMENTS[ln.augId] or (ln.def and ln.def.label) or ('#' .. tostring(ln.augId))
            summary[#summary + 1] = { lbl = label, old = ln.oldVal, new = ln.oldVal, locked = ln.locked, retired = ln.retired }
            if ln.retired then
                allPerfect = false
            end
        else
            local hasAff  = (ln.def and ln.def.cat and affinity.hasAffinity(player, ln.def.cat)) or false
            local cap     = (ln.def and ln.def.maxBoost) and math.min(EXDATA_VALUE_MAX, ln.def.maxBoost) or EXDATA_VALUE_MAX
            -- SCALE maxBoost-capped rolls into [0, cap] like the Moogle does
            -- (Augment_Moogle.lua 2026-06-30 revamp) instead of hard-clamping:
            -- a hard clamp saturates every tier band above the cap, so all
            -- tiers reroll to the SAME value on low-ceiling stats.
            local function scaleRoll(raw)
                if xi.augmentTiers and xi.augmentTiers.scaleRoll then
                    return xi.augmentTiers.scaleRoll(raw, cap, tier, rank)
                end
                local scaled = math.floor(raw * cap / EXDATA_VALUE_MAX + 0.5)
                if (not xi.augmentTiers or not xi.augmentTiers.trueMaxAllowed or
                    not xi.augmentTiers.trueMaxAllowed(tier, rank)) and cap > 0
                then
                    local soft = xi.augmentTiers and xi.augmentTiers.softCeiling and
                        xi.augmentTiers.softCeiling(cap) or math.max(0, cap - 1)
                    scaled = math.min(scaled, soft)
                end
                return math.max(0, scaled)
            end
            local slotMax = scaleRoll(slice.max)

            local r
            if ln.def and (ln.def.tierValue or ln.def.flatValue) then
                -- Tier-fixed / flat augments reroll deterministically, matching
                -- the Moogle's encoding and crystalize rules.
                local tvBase = ln.def.base or 0
                local target = ln.def.flatValue or
                    (xi.augmentTiers.tierFixedValue and
                        xi.augmentTiers.tierFixedValue(ln.def.tierValue, tier, rank) or
                        (ln.def.tierValue * tier))
                r       = target - tvBase
                slotMax = r
            else
                r = math.random(rollFloor, slice.max)
                if hasAff then
                    r = math.max(r, math.random(rollFloor, slice.max))
                end
                if isCrit then
                    r = slice.max
                end
                r = scaleRoll(r)
            end

            -- Pack: Augment { Id:11 | Value:5 } -> word = id + value*2048.
            local word = ln.augId + r * 2048
            local b    = 2 + ln.augSlot * 2
            item:setExDataRaw({ [b] = word % 256, [b + 1] = math.floor(word / 256) })

            local canLockRoll = slotMax > 0 or (ln.def and ln.def.flatValue ~= nil)
            if not canLockRoll or r ~= slotMax then
                allPerfect = false
            end

            summary[#summary + 1] = { lbl = (ln.def and ln.def.label) or ('#' .. tostring(ln.augId)), old = ln.oldVal, new = r }
        end
    end

    if canCrystalize and #lines == 5 and allPerfect and math.random() < crystalPct then
        newMask = 0x1F
    end

    -- Persist the normalized all-or-nothing mask (byte 12 stays blank).
    if newMask ~= originalLockMask then
        item:setExDataRaw({ [SIG_HEAD_BYTE] = 0, [LOCK_MASK_BYTE] = newMask })
    end

    -- Charge (purely Infamy).
    player:setCharVar(INFAMY_CV, haveInfamy - infamyCost)

    -- Force a fresh mod application: drop the item to inventory so re-equipping
    -- re-reads the patched exdata (there is no in-place mod-refresh binding).
    pcall(function() player:unequipItem(slot) end)

    -- Report.
    player:printToPlayer(string.format('[Reroll]%s %s reforged for %d Infamy:',
        isCrit and ' *CRITICAL!*' or '', item:getName(), infamyCost), CHANNEL)
    for _, s in ipairs(summary) do
        if s.retired then
            player:printToPlayer(string.format('  %s : %d   (retired, kept)', s.lbl, s.old), CHANNEL)
        elseif s.locked then
            player:printToPlayer(string.format('  %s : %d   (crystalized, kept)', s.lbl, s.old), CHANNEL)
        else
            local arrow = (s.new > s.old) and '^ up' or ((s.new < s.old) and 'v down' or '= same')
            player:printToPlayer(string.format('  %s : %d -> %d   (%s)', s.lbl, s.old, s.new, arrow), CHANNEL)
        end
    end
    if clearedPartialMask then
        player:printToPlayer('  Legacy partial crystalization was cleared.', CHANNEL)
    end
    if newMask == 0x1F then
        player:printToPlayer('  *** ALL FIVE PERFECT LINES CRYSTALIZED -- ITEM LOCKED! ***', CHANNEL)
    end
    player:printToPlayer('Re-equip the item to apply the new augments.', CHANNEL)
end

return commandObj
