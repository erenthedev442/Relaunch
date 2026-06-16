-----------------------------------
-- ID: 26343
-- Yoichi's Quiver
-- When used, you will obtain one stack of Yoichi's Arrows
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { xi.item.YOICHIS_ARROW, 99 } })
end

return itemObject
