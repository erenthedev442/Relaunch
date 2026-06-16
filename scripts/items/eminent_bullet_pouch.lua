-----------------------------------
-- ID: 6271
-- Eminent Bullet Pouch
-- When used, you will obtain one stack of Eminent Bullets
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { 21331, 99 } }) -- eminent_bullet
end

return itemObject
