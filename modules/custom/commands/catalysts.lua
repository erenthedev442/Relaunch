-----------------------------------
-- func: catalysts
-- desc: Lists the augment catalysts you have banked at the Arcane Augmenter
--       (hub). Catalyst drops are auto-banked at the NPC and never enter your
--       inventory; this shows what and how many you currently have stored.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local bank = require('modules/custom/lua/augment_catalyst_bank')

commandObj.onTrigger = function(player)
    local S = xi.msg.channel.SYSTEM_3
    local balances = bank.balances(player)

    -- Collect non-zero balances and sort by name for a stable, readable list.
    local rows, total = {}, 0
    for itemId, qty in pairs(balances) do
        qty = tonumber(qty) or 0
        if qty > 0 then
            rows[#rows + 1] = { name = bank.itemName(itemId), qty = qty }
            total = total + qty
        end
    end
    table.sort(rows, function(a, b) return a.name:lower() < b.name:lower() end)

    if #rows == 0 then
        player:printToPlayer('[Augment Bank] You have no catalysts banked at the Arcane Augmenter.', S)
        return
    end

    player:printToPlayer(string.format(
        '[Augment Bank] %d catalyst type(s) stored at the Arcane Augmenter:', #rows), S)
    for _, r in ipairs(rows) do
        player:printToPlayer(string.format('  %-30s x%d', r.name, r.qty), S)
    end
    player:printToPlayer(string.format('  Total catalysts stored: %d', total), S)
end

return commandObj
