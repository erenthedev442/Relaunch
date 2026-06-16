-----------------------------------
-- ID: 6270
-- Eminent Bolt Quiver
-- When used, you will obtain one stack of Eminent Bolts
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { 21316, 99 } }) -- eminent_bolt
end

return itemObject
