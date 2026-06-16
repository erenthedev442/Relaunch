-----------------------------------
-- ID: 5994
-- Scroll of Aria of Passion
-- Teaches the song Aria of Passion. (BRD 99)
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return target:canLearnSpell(xi.magic.spell.ARIA_OF_PASSION)
end

itemObject.onItemUse = function(target)
    target:addSpell(xi.magic.spell.ARIA_OF_PASSION)
end

return itemObject
