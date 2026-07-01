-----------------------------------
-- !refundcatalysts [confirm]
--
-- Scans the cursor-targeted player's full inventory (all bags + wardrobes)
-- for two categories of reimbursement:
--
--   1. UNUSED CATALYSTS: banned catalyst items still sitting in bags/wardrobes.
--      Item is deleted on confirm; 100,000 gil refunded per item.
--
--   2. GEAR AUGMENTS: equipment with augment slots whose augId is NOT present
--      in the live augment_catalog.lua (orphaned / removed augments).
--      On confirm the slot is ZEROED via setExDataRaw (persisted; stat stays
--      active in-memory until player relogs). 100,000 gil refunded per slot.
--
-- Without "confirm": dry-run — reports what would change, nothing modified.
-- With "confirm":    deletes catalyst items, zeros orphan aug slots, pays gil.
--
-- augId byte offsets in AugmentStandard exdata (pragma pack 1, m_extra overlay):
--   byte 0: AugmentKind   byte 1: AugmentSubKind
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
    permission = 0,
    parameters = 's',
}

-- ── Build valid augId set from the live catalog ───────────────────────────
-- Any augId NOT in this set is an orphan (removed or never catalogued).
local catalog = require('modules/custom/lua/augment_catalog')
local VALID_AUG_IDS = {}
for _, def in pairs(catalog) do
    if type(def) == 'table' and def.augId then
        VALID_AUG_IDS[def.augId] = true
    end
end

-- ── Banned catalyst items (hardcoded — removed from the shop) ────────────
-- These are specific item IDs that were used as catalysts and then pulled.
-- 100,000 gil refunded per item (the shop price).
local BANNED_CATALYSTS =
{
    { id = 1628, name = 'Buffalo Hide'      },
    { id = 1640, name = 'Bugard Skin'       },
    { id = 1680, name = 'H.Q. Bugard Skin'  },
    { id = 1816, name = 'Wyrm Horn'         },
    { id = 2121, name = 'Ovinnik Hide'      },
    { id = 2123, name = 'Catoblepas Hide'   },
    { id = 2499, name = 'Regurgitated Wing' },
    { id = 1274, name = 'Southern Pearl'    },
    { id = 889,  name = 'Beetle Shell'      },
    { id = 893,  name = 'Giant Femur'       },
    { id = 896,  name = 'Scorpion Shell'    },
    { id = 908,  name = 'Adamantoise Shell' },
    { id = 924,  name = 'Vial of Fiend Blood'    },
    { id = 930,  name = 'Vial of Beastman Blood' },
}
local CATALYST_REFUND = 100000

local CATALYST_SET = {}
for _, entry in ipairs(BANNED_CATALYSTS) do
    CATALYST_SET[entry.id] = entry
end

local AUG_SLOT_REFUND = 100000

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

-- Zero augment slot s (0-4) directly in the packed AugmentStandard exdata.
-- exdata<T>() is reinterpret_cast on m_extra, so setExDataRaw hits the struct.
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

                -- Category 1: unused banned catalyst item
                local catEntry = CATALYST_SET[item:getID()]
                if catEntry then
                    local qty    = item:getQuantity()
                    local refund = CATALYST_REFUND * qty
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

                -- Category 2: equipment with orphan augment slots
                elseif item:isType(xi.itemType.WEAPON) or item:isType(xi.itemType.ARMOR) then
                    local augSlotIndices = {}
                    local augDescs       = {}
                    local slotGil        = 0
                    for augSlot = 0, 4 do
                        local a     = item:getAugment(augSlot)
                        local augId = a[1]
                        if augId ~= 0 and not VALID_AUG_IDS[augId] then
                            augSlotIndices[#augSlotIndices + 1] = augSlot
                            augDescs[#augDescs + 1] = string.format('slot%d:#%d', augSlot, augId)
                            slotGil = slotGil + AUG_SLOT_REFUND
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
        player:printToPlayer('  -- Unused Catalysts (deleted + 100k/item) --', CHANNEL)
        for _, h in ipairs(catalystHits) do
            player:printToPlayer(
                string.format('  %s x%d  (%s #%d)  → %d gil%s',
                    h.name, h.qty, h.locName, h.slot, h.refund,
                    commit and '  [deleted]' or ''),
                CHANNEL)
        end
    end

    if #gearHits > 0 then
        player:printToPlayer('  -- Orphan Gear Augments (slot zeroed + 100k/slot, relog for effect) --', CHANNEL)
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
    for _, h in ipairs(catalystHits) do
        targ:delItemAt(h.itemId, h.qty, h.container, h.slot)
    end

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

    targ:addGil(totalGil)

    targ:printToPlayer(
        string.format('[Augment Refund] %d catalyst(s) deleted, %d orphan augment slot(s) removed. %d gil reimbursed. Relog for gear stats to update.',
            #catalystHits, augCount, totalGil),
        CHANNEL)

    player:printToPlayer(
        string.format('[RefundCatalysts] Done. %d gil paid to %s.', totalGil, targ:getName()),
        CHANNEL)
end

return commandObj
