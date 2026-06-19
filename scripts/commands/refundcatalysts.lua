-----------------------------------
-- !refundcatalysts [confirm]
--
-- Scans the cursor-targeted player's full inventory (all bags + wardrobes)
-- for two categories of reimbursement from the augment-catalog removal:
--
--   1. UNUSED CATALYSTS: banned catalyst items still sitting in bags/wardrobes.
--      Refunds 50,000 gil per catalyst item.
--
--   2. GEAR AUGMENTS: equipment that has one of the banned augment IDs applied
--      to it (the player spent 10,000 gil per application).
--      Refunds 10,000 gil per banned augment slot found on the gear.
--      The augment itself stays on the item — only the gil is reimbursed.
--
-- Without "confirm": dry-run — reports what would be refunded, no changes.
-- With "confirm": removes unused catalyst items, adds the total gil.
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
-- Unused catalyst stacks are removed on confirm; 50,000 gil refunded per item.
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
-- 10,000 gil refunded per slot on gear that carries one of these IDs.
-- The augment itself is NOT removed (the stat stays on the item).
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

commandObj.onTrigger = function(player, arg)
    local targ = player:getCursorTarget()
    if targ == nil or targ:getObjType() ~= xi.objType.PC then
        player:printToPlayer('[RefundCatalysts] Target a player first.', CHANNEL)
        return
    end

    local commit = (arg ~= nil and string.lower(arg) == 'confirm')

    -- ── Scan all containers ───────────────────────────────────────────────
    local catalystHits = {}   -- unused catalyst items to remove
    local gearHits     = {}   -- gear pieces with banned augment slots
    local totalGil     = 0

    for _, c in ipairs(CONTAINERS) do
        local size = targ:getContainerSize(c.id)
        for slot = 1, size do
            local item = targ:getStorageItem(c.id, slot, 255)
            if item ~= nil then

                -- Category 1: unused catalyst item in inventory
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
                    local bannedSlots  = {}
                    local slotGil      = 0
                    for augSlot = 0, 4 do
                        local a      = item:getAugment(augSlot)
                        local augId  = a[1]
                        local augName = BANNED_AUG_NAMES[augId]
                        if augName then
                            bannedSlots[#bannedSlots + 1] = string.format('slot%d:%s(#%d)', augSlot, augName, augId)
                            slotGil = slotGil + GIL_PER_AUG_SLOT
                        end
                    end
                    if #bannedSlots > 0 then
                        gearHits[#gearHits + 1] =
                        {
                            container  = c.id,
                            locName    = c.name,
                            slot       = slot,
                            itemId     = item:getID(),
                            name       = item:getName(),
                            augDesc    = table.concat(bannedSlots, ', '),
                            slotCount  = #bannedSlots,
                            refund     = slotGil,
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
        player:printToPlayer('  -- Unused Catalysts (item removed + 100k/each) --', CHANNEL)
        for _, h in ipairs(catalystHits) do
            player:printToPlayer(
                string.format('  %s x%d  (%s #%d)  → %d gil%s',
                    h.name, h.qty, h.locName, h.slot, h.refund,
                    commit and '  [removed]' or ''),
                CHANNEL)
        end
    end

    if #gearHits > 0 then
        player:printToPlayer(
            string.format('  -- Gear Augments (augment stays, 10k/slot × %d) --',
                #gearHits),
            CHANNEL)
        for _, h in ipairs(gearHits) do
            player:printToPlayer(
                string.format('  %s  (%s #%d)  %s  → %d gil',
                    h.name, h.locName, h.slot, h.augDesc, h.refund),
                CHANNEL)
        end
    end

    if not commit then
        player:printToPlayer(
            '[RefundCatalysts] Dry-run only. Run with "confirm" to apply.',
            CHANNEL)
        return
    end

    -- ── Apply — remove catalysts, then pay total gil ───────────────────────
    for _, h in ipairs(catalystHits) do
        targ:delItemAt(h.itemId, h.qty, h.container, h.slot)
    end

    targ:addGil(totalGil)

    local catCount = #catalystHits
    local augCount = 0
    for _, h in ipairs(gearHits) do augCount = augCount + h.slotCount end

    targ:printToPlayer(
        string.format('[Augment Refund] %d catalyst item(s) removed, %d banned augment slot(s) on gear found. %d gil reimbursed.',
            catCount, augCount, totalGil),
        CHANNEL)

    player:printToPlayer(
        string.format('[RefundCatalysts] Done. %d gil paid to %s.', totalGil, targ:getName()),
        CHANNEL)
end

return commandObj
