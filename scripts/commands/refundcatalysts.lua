-----------------------------------
-- !refundcatalysts [confirm]
--
-- Scans the cursor-targeted player's inventory (all containers) for
-- catalyst items that have been removed from the augment system and
-- reimburses them with gil.
--
-- Without "confirm": dry-run — reports what would be refunded, no
--   changes made.
-- With "confirm": removes the catalyst items and adds the gil.
--
-- Usage:
--   !refundcatalysts           (dry-run on cursor target)
--   !refundcatalysts confirm   (live run on cursor target)
--
-- To add future banned catalysts: add a row to BANNED_CATALYSTS below.
-- refund = gil given per item in the stack.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

-- ── Banned catalyst table ─────────────────────────────────────────────
-- Each entry: item id, display name, gil refunded per quantity.
-- Adjust refund amounts freely; they are only used when "confirm" runs.
local BANNED_CATALYSTS =
{
    { id = 1628, name = 'Buffalo Hide',       refund = 50000 },
    { id = 1640, name = 'Bugard Skin',        refund = 50000 },
    { id = 1680, name = 'H.Q. Bugard Skin',   refund = 50000 },
    { id = 1816, name = 'Wyrm Horn',          refund = 50000 },
    { id = 2121, name = 'Ovinnik Hide',       refund = 50000 },
    { id = 2123, name = 'Catoblepas Hide',    refund = 50000 },
}

-- Build a quick-lookup set: itemId -> catalog entry
local BANNED_SET = {}
for _, entry in ipairs(BANNED_CATALYSTS) do
    BANNED_SET[entry.id] = entry
end

-- All containers a player can hold items in.
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
}

local CHANNEL = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, arg)
    local targ = player:getCursorTarget()
    if targ == nil or targ:getObjType() ~= xi.objType.PC then
        player:printToPlayer('[RefundCatalysts] Target a player first.', CHANNEL)
        return
    end

    local commit = (arg ~= nil and string.lower(arg) == 'confirm')

    -- ── Scan all containers ───────────────────────────────────────────
    local hits      = {}
    local totalGil  = 0

    for _, c in ipairs(CONTAINERS) do
        local size = targ:getContainerSize(c.id)
        for slot = 1, size do
            local item = targ:getStorageItem(c.id, slot, 255)
            if item ~= nil then
                local entry = BANNED_SET[item:getID()]
                if entry then
                    local qty    = item:getQuantity()
                    local refund = entry.refund * qty
                    hits[#hits + 1] =
                    {
                        container = c.id,
                        locName   = c.name,
                        slot      = slot,
                        itemId    = entry.id,
                        name      = entry.name,
                        qty       = qty,
                        refund    = refund,
                    }
                    totalGil = totalGil + refund
                end
            end
        end
    end

    -- ── Report ────────────────────────────────────────────────────────
    if #hits == 0 then
        player:printToPlayer(
            string.format('[RefundCatalysts] %s has no banned catalysts.', targ:getName()),
            CHANNEL)
        return
    end

    local mode = commit and '[LIVE]' or '[DRY-RUN]'
    player:printToPlayer(
        string.format('[RefundCatalysts] %s %s — %d stack(s) found, %d gil total:',
            mode, targ:getName(), #hits, totalGil),
        CHANNEL)

    for _, h in ipairs(hits) do
        player:printToPlayer(
            string.format('  %s x%d  (%s slot %d)  → %d gil%s',
                h.name, h.qty, h.locName, h.slot, h.refund,
                commit and '  [removed + paid]' or ''),
            CHANNEL)
    end

    if not commit then
        player:printToPlayer(
            '[RefundCatalysts] Dry-run only. Run with "confirm" to apply.',
            CHANNEL)
        return
    end

    -- ── Apply — delete items then pay gil ─────────────────────────────
    -- Delete items first (collect then delete so iteration stays safe).
    for _, h in ipairs(hits) do
        targ:delItemAt(h.itemId, h.qty, h.container, h.slot)
    end

    targ:addGil(totalGil)

    -- Notify the target player as well.
    targ:printToPlayer(
        string.format('[Augment Refund] %d banned catalyst(s) removed from your inventory. %d gil reimbursed.',
            #hits, totalGil),
        CHANNEL)

    player:printToPlayer(
        string.format('[RefundCatalysts] Done. %d gil paid to %s.', totalGil, targ:getName()),
        CHANNEL)
end

return commandObj
