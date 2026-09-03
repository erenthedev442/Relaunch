-----------------------------------
-- ID: 18348, 18349, 18650, 18664, 18678, 19759, 19852, 21210, 21211, 22115
-- Item: Yoichinoyumi
--
-- Yoichi Arrows are issued only by Yoichi's Quiver (26343), granted with
-- the final 119 III bow. The bow itself is not an ammo enchantment.
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.msg.basic.ITEM_UNABLE_TO_USE
end

itemObject.onItemUse = function(target)
end

return itemObject
