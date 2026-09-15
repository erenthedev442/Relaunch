-----------------------------------
-- consume_upgrade_item.lua
--
-- Upgrade / reforge / REMA forges must remove the previous tier (base, +1,
-- +2, 119 II, ...) even when that piece is still equipped or sitting in a
-- wardrobe. player:delItem() only searches one bag, and UpdateItem refuses
-- busy Equipped items, so the forge used to grant the next tier and leave
-- the old one on the player.
--
-- Callers MUST abort the grant if one() returns false.
-----------------------------------
local bags = require('modules/custom/lua/hl_seal_currency')

local M = {}

local function unequipOwned(player, itemId)
    for slot = 0, (xi.MAX_SLOTID or 15) do
        if player:getEquipID(slot) == itemId then
            player:unequipItem(slot)
        end
    end
end

function M.one(player, itemId)
    return M.qty(player, itemId, 1)
end

function M.qty(player, itemId, amount)
    if not player or not itemId or itemId <= 0 or not amount or amount <= 0 then
        return false
    end
    unequipOwned(player, itemId)
    return bags.take(player, itemId, amount)
end

return M
