-----------------------------------
-- ID: 26346
-- Quelling Bolt Quiver
-- When used, you will obtain one stack of Quelling Bolts
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { xi.item.QUELLING_BOLT, 99 } })
end

return itemObject
