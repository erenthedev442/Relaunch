-----------------------------------
-- func: augstats
-- desc: Shows the true augment contributions on your equipped gear.
--
-- WHY THIS EXISTS:
--   The FFXI client's item examine window displays augment values using its
--   own retail lookup table, which maps the packet augment ID to a fixed
--   display string. Legendary uses custom augment IDs whose values in the
--   client's retail table do not match the server's stat definitions — so
--   the window shows nonsense (often a large negative number) for any item
--   augmented through the Augment Moogle, especially after Augment Sage
--   multipliers push the per-slot value above what the 5-bit exdata field
--   can store cleanly.
--
--   The actual stat bonus IS applied correctly — only the display is wrong.
--   This command reads the augment slot data directly from the server and
--   computes the true per-slot and total values.
--
-- FORMULA (mirrors item_equipment.cpp:479):
--   Each augment slot contributes:
--     effective_per_slot = (base + exdata_boost) * (mult > 1 ? mult : 1)
--   where base + mult are the EFFECTIVE live values (from augment_catalog.lua,
--   reconciled from sql/augments.sql + zz_augment_rebalance.sql) and
--   exdata_boost is the 5-bit Augment Sage boost stored in the item's exdata
--   (0-31, capped at 31 per slot by the hardware field width).
--   Multiple catalyst slots of the same augment type stack independently.
--
-- USAGE: 
--   !augstats
-----------------------------------
local catalog = require('modules/custom/lua/augment_catalog')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

-- Build reverse map once at module load: augId -> { label, base }
-- augment_catalog keys on catalyst item ID; we need the inverse.
-- base is stored as a positive magnitude in the catalog even for
-- stats like Delay that reduce (the label carries the '-' sign).
local augById = {}
for _, def in pairs(catalog) do
    if def.augId and augById[def.augId] == nil then
        augById[def.augId] =
        {
            label = def.label,
            base  = math.abs(def.base or 0),
            mult  = def.mult or 1,
            disp  = def.disp or 1,
        }
    end
end

local SLOT_NAMES =
{
    [0]  = 'Main',  [1]  = 'Sub',   [2]  = 'Ranged', [3]  = 'Ammo',
    [4]  = 'Head',  [5]  = 'Body',  [6]  = 'Hands',  [7]  = 'Legs',
    [8]  = 'Feet',  [9]  = 'Neck',  [10] = 'Waist',  [11] = 'Ear1',
    [12] = 'Ear2',  [13] = 'Ring1', [14] = 'Ring2',  [15] = 'Back',
}

commandObj.onTrigger = function(player)
    player:printToPlayer(
        string.format('=== Augment Stats — %s ===', player:getName()),
        xi.msg.channel.SYSTEM_3)

    -- Augment Tier header (2026-06-30 tier revamp). xi.augmentTiers is
    -- published by the Augment Moogle module at boot; guard in case the
    -- module is disabled.
    if xi.augmentTiers then
        local tier  = xi.augmentTiers.tierOf(player)
        local slice = xi.augmentTiers.slices[tier]
        local nxt   = xi.augmentTiers.nextUnlock(tier)
        player:printToPlayer(string.format(
            '  Augment Tier: %d/5  (rolls %d-%d of 31)%s',
            tier, slice.min, slice.max,
            nxt and ('  |  next: ' .. nxt) or '  |  MAX'),
            xi.msg.channel.SYSTEM_3)
    end

    local anyFound = false

    for equipSlot = 0, 15 do
        local item = player:getEquippedItem(equipSlot)
        if item ~= nil then
            -- Collect augment slots 0-4 for this item.
            -- Group by augId: same catalyst type in multiple slots appends its
            -- own rolled value (the 2026-06-30 tier revamp rolls PER SLOT, so
            -- stacked slots usually carry DIFFERENT values).
            local augGroups = {}   -- augId -> { label, base, mult, disp, vals = {..} }
            local augOrder  = {}   -- insertion order for stable printing

            for augSlot = 0, 4 do
                local aug    = item:getAugment(augSlot)
                local augId  = aug[1]
                local augVal = aug[2]

                if augId ~= 0 then
                    if augGroups[augId] == nil then
                        local def = augById[augId]
                        augGroups[augId] =
                        {
                            label = def and def.label or string.format('[AugID %d]', augId),
                            base  = def and def.base  or 0,
                            mult  = def and def.mult  or 1,
                            disp  = def and def.disp  or 1,
                            vals  = { augVal },
                        }
                        table.insert(augOrder, augId)
                    else
                        table.insert(augGroups[augId].vals, augVal)
                    end
                end
            end

            if #augOrder > 0 then
                anyFound = true

                -- Print item header
                player:printToPlayer(
                    string.format('  [%s] %s:',
                        SLOT_NAMES[equipSlot] or tostring(equipSlot),
                        item:getName()),
                    xi.msg.channel.SYSTEM_3)

                -- Print one line per distinct augment type
                for _, augId in ipairs(augOrder) do
                    local g = augGroups[augId]
                    -- Mirror the engine (item_equipment.cpp:479), then divide by the
                    -- display scale so stored-xN mods (damage taken /100, ...) read as
                    -- the meaningful number:
                    --   per_slot = (base + roll) * (mult>1 ? mult : 1) / disp
                    -- (negative-stat augments show magnitude; label carries sign context)
                    local m = (g.mult and g.mult > 1) and g.mult or 1
                    local d = (g.disp and g.disp > 1) and g.disp or 1

                    local parts, rollParts, total = {}, {}, 0
                    for _, v in ipairs(g.vals) do
                        local perSlot = math.floor((g.base + v) * m / d + 0.5)
                        total = total + perSlot
                        table.insert(parts, tostring(perSlot))
                        table.insert(rollParts, tostring(v))
                    end

                    local line
                    if #g.vals > 1 then
                        line = string.format(
                            '    %s  ->  %s = %d total  (rolls %s)',
                            g.label, table.concat(parts, '+'), total,
                            table.concat(rollParts, ','))
                    elseif g.vals[1] > 0 then
                        line = string.format(
                            '    %s  ->  %d  (roll %d/31)',
                            g.label, total, g.vals[1])
                    else
                        line = string.format('    %s  ->  %d', g.label, total)
                    end

                    player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
                end
            end
        end
    end

    if not anyFound then
        player:printToPlayer('  (no augmented equipment found)', xi.msg.channel.SYSTEM_3)
    end

    player:printToPlayer(
        '  [!] Item examine window shows garbled values for sage-boosted augments — the numbers above are accurate.',
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '  [!] For reduction stats (Delay, PDT, MDT) the number is the reduction magnitude.',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
