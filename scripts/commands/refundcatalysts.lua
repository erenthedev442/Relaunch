-----------------------------------
-- !refundcatalysts [confirm]
--
-- Scans the cursor-targeted player's full inventory (all bags + wardrobes)
-- for two categories of reimbursement from the augment-catalog removal:
--
--   1. UNUSED CATALYSTS: banned catalyst items still sitting in bags/wardrobes.
--      Item is removed on confirm; 100,000 gil refunded per item.
--
--   2. GEAR AUGMENTS: equipment that has one of the banned augment IDs baked
--      into an augment slot (player paid 10,000 gil per application).
--      On confirm the banned slot(s) are ZEROED out via setExDataRaw (writes
--      directly to the packed exdata bytes, persisted with setDirty); the stat
--      stays active in-memory until the player relogs, then it's gone.
--      10,000 gil refunded per zeroed augment slot.
--
-- Without "confirm": dry-run — reports what would change, no changes made.
-- With "confirm":  removes catalyst items, zeros banned aug slots, pays gil.
--
-- Augment slot byte offsets in AugmentStandard exdata (pragma pack 1):
--   byte 0: AugmentKind, byte 1: AugmentSubKind
--   slot s (0-4): bytes (2 + s*2) and (3 + s*2)
--
-- Usage:
--   !refundcatalysts           (dry-run on cursor target)
--   !refundcatalysts confirm   (live run on cursor target)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

-- ── Banned catalyst items ─────────────────────────────────────────────────
-- Unused catalyst stacks are deleted on confirm; 100,000 gil per item.
local BANNED_CATALYSTS =
{
    { id = 1628, name = 'Buffalo Hide',     refund = 100000 },
    { id = 1640, name = 'Bugard Skin',      refund = 100000 },
    { id = 1680, name = 'H.Q. Bugard Skin', refund = 100000 },
    { id = 1816, name = 'Wyrm Horn',        refund = 100000 },
    { id = 2121, name = 'Ovinnik Hide',     refund = 100000 },
    { id = 2123, name = 'Catoblepas Hide',  refund = 100000 },
}

local CATALYST_SET = {}
for _, entry in ipairs(BANNED_CATALYSTS) do
    CATALYST_SET[entry.id] = entry
end

-- ── Banned augment IDs applied to gear ───────────────────────────────────
-- The six STR+X combos removed from the catalog.
-- 10,000 gil refunded per slot; the slot is zeroed via setExDataRaw on confirm.
local BANNED_AUG_NAMES =
{
    [550] = 'STR+DEX',
    [551] = 'STR+VIT',
    [552] = 'STR+AGI',
    [557] = 'STR+CHR',
    [558] = 'STR+INT',
    [559] = 'STR+MND',
}
local GIL_PER_AUG_SLOT = 10000

-- ── All containers (bags + wardrobes) ────────────────────────────────────
local CONTAINERS =
{
    { id = xi.inv.INVENTORY,  name = 'Inventory'   },
    { id = xi.inv.MOGSAFE,    name = 'Mog Safe'    },
    { id = xi.inv.MOGSAFE2,   name = 'Mog Safe 2'  },
    { id = xi.inv.STORAGE,    name = 'Storage'     },
    { id = xi.inv.MOGLOCKER,  name = 'Mog Locker'  },
    { id = xi.inv.MOGSATCHEL, name = 'Mog Satchel' },
    { id = xi.inv.MOGSACK,    name = 'Mog Sack'    },
    { id = xi.inv.MOGCASE,    name = 'Mog Case'    },
    { id = xi.inv.WARDROBE,   name = 'Wardrobe'    },
    { id = xi.inv.WARDROBE2,  name = 'Wardrobe 2'  },
    { id = xi.inv.WARDROBE3,  name = 'Wardrobe 3'  },
    { id = xi.inv.WARDROBE4,  name = 'Wardrobe 4'  },
    { id = xi.inv.WARDROBE5,  name = 'Wardrobe 5'  },
    { id = xi.inv.WARDROBE6,  name = 'Wardrobe 6'  },
    { id = xi.inv.WARDROBE7,  name = 'Wardrobe 7'  },
    { id = xi.inv.WARDROBE8,  name = 'Wardrobe 8'  },
}

local CHANNEL = xi.msg.channel.SYSTEM_3

-- Zero augment slot `s` (0-4) in an item's packed AugmentStandard exdata.
-- The struct is reinterpret_cast onto m_extra, so setExDataRaw writes the
-- C++ struct directly. setDirty(true) is called by setExDataRaw automatically.
local function zeroAugSlot(item, augSlot)
    local b = 2 + augSlot * 2
    item:setExDataRaw({ [b] = 0, [b + 1] = 0 })
end

commandObj.onTrigger = function(player, arg)
    local targ = player:getCursorTarget()
    if targ == nil or targ:getObjType() ~= xi.objType.PC then
        player:printToPlayer('[RefundCatalysts] Target a player first.', CHANNEL)
        return
    end

    local commit = (arg ~= nil and string.lower(arg) == 'confirm')

    -- ── Scan all containers ───────────────────────────────────────────────
    local catalystHits = {}
    local gearHits     = {}
    local totalGil     = 0

    for _, c in ipairs(CONTAINERS) do
        local size = targ:getContainerSize(c.id)
        for slot = 1, size do
            local item = targ:getStorageItem(c.id, slot, 255)
            if item ~= nil then

                -- Category 1: unused catalyst item
                local catEntry = CATALYST_SET[item:getID()]
                if catEntry then
                    local qty    = item:getQuantity()
                    local refund = catEntry.refund * qty
                    catalystHits[#catalystHits + 1] =
                    {
                        container = c.id,
                        locName   = c.name,
                        slot      = slot,
                        itemId    = catEntry.id,
                        name      = catEntry.name,
                        qty       = qty,
                        refund    = refund,
                    }
                    totalGil = totalGil + refund

                -- Category 2: equipment with banned augment slots
                elseif item:isType(xi.itemType.WEAPON) or item:isType(xi.itemType.ARMOR) then
                    local augSlotIndices = {}
                    local augDescs       = {}
                    local slotGil        = 0
                    for augSlot = 0, 4 do
                        local a       = item:getAugment(augSlot)
                        local augName = BANNED_AUG_NAMES[a[1]]
                        if augName then
                            augSlotIndices[#augSlotIndices + 1] = augSlot
                            augDescs[#augDescs + 1] = string.format('slot%d:%s(#%d)', augSlot, augName, a[1])
                            slotGil = slotGil + GIL_PER_AUG_SLOT
                        end
                    end
                    if #augSlotIndices > 0 then
                        gearHits[#gearHits + 1] =
                        {
                            container      = c.id,
                            locName        = c.name,
                            slot           = slot,
                            itemId         = item:getID(),
                            name           = item:getName(),
                            augSlotIndices = augSlotIndices,
                            augDesc        = table.concat(augDescs, ', '),
                            slotCount      = #augSlotIndices,
                            refund         = slotGil,
                        }
                        totalGil = totalGil + slotGil
                    end
                end

            end
        end
    end

    -- ── Report ────────────────────────────────────────────────────────────
    if #catalystHits == 0 and #gearHits == 0 then
        player:printToPlayer(
            string.format('[RefundCatalysts] %s — nothing to refund.', targ:getName()),
            CHANNEL)
        return
    end

    local mode = commit and '[LIVE]' or '[DRY-RUN]'
    player:printToPlayer(
        string.format('[RefundCatalysts] %s %s — %d catalyst stack(s), %d gear piece(s) — %d gil total:',
            mode, targ:getName(), #catalystHits, #gearHits, totalGil),
        CHANNEL)

    if #catalystHits > 0 then
        player:printToPlayer('  -- Unused Catalysts (item deleted + 100k/each) --', CHANNEL)
        for _, h in ipairs(catalystHits) do
            player:printToPlayer(
                string.format('  %s x%d  (%s #%d)  → %d gil%s',
                    h.name, h.qty, h.locName, h.slot, h.refund,
                    commit and '  [deleted]' or ''),
                CHANNEL)
        end
    end

    if #gearHits > 0 then
        player:printToPlayer('  -- Gear Augments (slot ZEROED in exdata + 10k/slot, relog to see effect) --', CHANNEL)
        for _, h in ipairs(gearHits) do
            player:printToPlayer(
                string.format('  %s  (%s #%d)  %s  → %d gil%s',
                    h.name, h.locName, h.slot, h.augDesc, h.refund,
                    commit and '  [zeroed]' or ''),
                CHANNEL)
        end
    end

    if not commit then
        player:printToPlayer(
            '[RefundCatalysts] Dry-run only. Run with "confirm" to apply.',
            CHANNEL)
        return
    end

    -- ── Apply ─────────────────────────────────────────────────────────────
    -- 1. Delete unused catalyst stacks.
    for _, h in ipairs(catalystHits) do
        targ:delItemAt(h.itemId, h.qty, h.container, h.slot)
    end

    -- 2. Zero banned augment slots in gear (re-fetch item for write access).
    local augCount = 0
    for _, h in ipairs(gearHits) do
        local item = targ:getStorageItem(h.container, h.slot, 255)
        if item ~= nil then
            for _, augSlot in ipairs(h.augSlotIndices) do
                zeroAugSlot(item, augSlot)
                augCount = augCount + 1
            end
        end
    end

    -- 3. Pay total gil.
    targ:addGil(totalGil)

    targ:printToPlayer(
        string.format('[Augment Refund] %d catalyst(s) deleted, %d banned augment slot(s) removed from gear. %d gil reimbursed. Relog for gear stats to update.',
            #catalystHits, augCount, totalGil),
        CHANNEL)

    player:printToPlayer(
        string.format('[RefundCatalysts] Done. %d gil paid to %s.', totalGil, targ:getName()),
        CHANNEL)
end

return commandObj
