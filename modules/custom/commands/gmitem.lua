-----------------------------------
-- !gmitem <add|remove> <player> <itemId> <amount> <reason>
-- Audited, unaugmented item restoration for GM1 support.
-----------------------------------
local support = require('modules/custom/lua/gm_support')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'b',
}

local function usage(gm)
    gm:printToPlayer(
        'Usage: !gmitem <add|remove> <player> <itemId> <amount 1-99> <reason>',
        support.channel)
end

commandObj.onTrigger = function(gm, args)
    args = support.arguments(args, 'gmitem')
    local action, name, itemText, amountText, reason =
        (args or ''):match('^%s*(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.+)$')
    local itemId = tonumber(itemText)
    local amount = tonumber(amountText)

    if (action ~= 'add' and action ~= 'remove') or
        not itemId or itemId < 1 or
        not amount or amount < 1 or amount > 99 then
        usage(gm)
        return
    end
    if action == 'remove' and amount ~= 1 then
        gm:printToPlayer('[GM Item] Removal is one item at a time for safety.', support.channel)
        return
    end

    reason = support.requireReason(gm, reason)
    local target = support.resolvePlayer(gm, name)
    if not reason or not target then
        return
    end

    if action == 'add' then
        if target:getFreeSlotsCount() == 0 then
            gm:printToPlayer('[GM Item] Target has no free inventory slots.', support.channel)
            return
        end

        if not target:addItem(itemId, amount) then
            gm:printToPlayer('[GM Item] The item could not be added; check the ID, stack size and inventory.', support.channel)
            return
        end

        target:printToPlayer(string.format(
            '[GM Support] Restored item %d x%d. Reason: %s', itemId, amount, reason), support.channel)
        support.confirm(gm, target, string.format('added item %d x%d', itemId, amount), reason)
        return
    end

    for container = xi.inv.INVENTORY, xi.inv.WARDROBE8 do
        if target:hasItem(itemId, container) then
            if target:delItem(itemId, amount, container) then
                target:printToPlayer(string.format(
                    '[GM Support] Removed item %d x%d. Reason: %s', itemId, amount, reason), support.channel)
                support.confirm(gm, target, string.format('removed item %d x%d', itemId, amount), reason)
                return
            end
        end
    end

    gm:printToPlayer(string.format('[GM Item] %s does not have item %d.', target:getName(), itemId), support.channel)
end

return commandObj
