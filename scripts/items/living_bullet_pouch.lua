-----------------------------------
-- ID: 26348
-- Living Bullet Pouch
-- When used, you will obtain one stack of Living Bullets
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { xi.item.LIVING_BULLET, 99 } })
end

return itemObject
