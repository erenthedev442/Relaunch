-----------------------------------
-- ID: 26347
-- Eradicating Bullet Pouch
-- When used, you will obtain one stack of Eradicating Bullets
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { xi.item.ERADICATING_BULLET, 99 } })
end

return itemObject
