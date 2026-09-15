-----------------------------------
-- ID: 18981, 19001, 19070, 19090, 19622, 19720, 19829, 19958, 21246, 21247, 21266, 22139
-- Item: Gastraphetes
--
-- Quelling Bolts are issued only by Quelling Bolt Quiver (26346), granted
-- with the 119 III crossbow. The weapon itself is not an ammo enchantment.
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.msg.basic.ITEM_UNABLE_TO_USE
end

itemObject.onItemUse = function(target)
end

return itemObject
