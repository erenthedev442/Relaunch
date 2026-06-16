-----------------------------------
-- ID: 26344
-- Artemis's Quiver
-- When used, you will obtain one stack of Artemis's Arrows
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.itemUtils.itemBoxOnItemCheck(target)
end

itemObject.onItemUse = function(target)
    npcUtil.giveItem(target, { { 21298, 99 } }) -- artemiss_arrow
end

return itemObject
