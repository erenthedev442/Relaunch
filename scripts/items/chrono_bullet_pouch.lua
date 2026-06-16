-----------------------------------
-- ID: 26350
-- Chrono Bullet Pouch
-- When used, you will obtain one stack of Chrono Bullets
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { xi.item.CHRONO_BULLET, 99 } })
end

return itemObject
