-----------------------------------
-- ID: 26345
-- Chrono Quiver
-- When used, you will obtain one stack of Chrono Arrows
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { xi.item.CHRONO_ARROW, 99 } })
end

return itemObject
