-----------------------------------
-- ID: 26349
-- Devastating Bullet Pouch
-- When used, you will obtain one stack of Devastating Bullets
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { xi.item.DEVASTATING_BULLET, 99 } })
end

return itemObject
